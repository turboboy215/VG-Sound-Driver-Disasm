"""Generate PopUp_SoundDriver.asm (byte-exact).  usage: gen_popup.py <rom> <out.asm>"""
import sys
sys.path.insert(0, __file__.rsplit('/', 1)[0])
from asmgen import Gen
import popup_data as P
from notes import NOTE_MACRO, note_text, hx

rom = open(sys.argv[1], 'rb').read()
g = Gen(rom)
w16 = P.w16

g.header = r'''; =====================================================================
; Pop Up (U) [!] - Game Boy, Infogrames 1991
; Sound driver by Alberto Jose Gonzalez (Bit Managers): "AJG driver", version 1
;
; Rebuilds byte-exact with RGBDS 0.9.1:
;   rgbasm -Wall -o popup.o PopUp_SoundDriver.asm
;   rgblink -t -o popup.gb popup.o
;   python tools/cmp_ranges.py popup.gb "Pop Up (U) [!].gb" <ranges listed in the doc>
; (-t: 32 KB ROM without MBC, so $4000-$7FFF is plain ROM.)
;
; Documentation: PopUp_SoundDriver.md / AJG_SoundEngine_Family.md
; =====================================================================
'''

cmd_macros = []
for b, (name, kinds) in sorted(P.CMDS.items()):
    body = ['\tdb $%02X' % b]
    for i, k in enumerate(kinds):
        body.append(('\tdb \\%d' if k == 'b' else '\tdw \\%d') % (i + 1))
    cmd_macros.append(f'MACRO {name}\n' + '\n'.join(body) + '\nENDM')

g.macros = NOTE_MACRO + r'''
; ---- stream commands (patterns, SFX streams and instrument macros) ----
MACRO LEN       ; note length in ticks, 1-33
	db $DE + \1
ENDM
MACRO VOL       ; start volume of following notes, 0-15
	db $BF + \1
ENDM
MACRO VOLENV    ; start volume + envelope: atk (lo=count hi=step), dec (lo=count hi=step), rates (hi=atk lo=dec)
	db $CF + \1, \2, \3, \4
ENDM
MACRO INSTR     ; run instrument macro 0-25
	db $80 + \1
ENDM
MACRO ARP       ; arpeggio table 0-14
	db $B0 + \1
ENDM
MACRO PLAY_SFX  ; start sound id 0-21, then wait one note length
	db $9A + \1
ENDM
''' + '\n'.join(cmd_macros) + r'''
; ---- order lists ----
MACRO ORDER_LOOP  ; end of an order list: 0, then the order position to continue from
	dw 0, \1
ENDM
; ---- arpeggio tables ----
DEF ARP_LOOP EQU $73   ; restart the table
DEF ARP_HOLD EQU $FF   ; stay on the previous entry
'''

g.sections = [
    ('RST08_ReadPtr', 0x0008, 0x000C, 'rst $08: hl = [hl] (game code, used by the driver)'),
    ('RST10_JumpHL', 0x0010, 0x0011, 'rst $10: jp hl'),
    ('RST20_CopyByte', 0x0020, 0x0027, 'rst $20: [de++] = [hl++], bc-- (flags/af kept)'),
    ('RST28_SwapHLDE', 0x0028, 0x002D, 'rst $28: swap hl and de'),
    ('TimerVector', 0x0050, 0x0053, 'Timer interrupt vector'),
    ('GameSndInit', 0x06FE, 0x0760, '''Game code (part of the boot routine at $06B3): zeroes $C100-$C4FF, sets the
per-channel register indices and NR51/mask bits, copies the CH1 page to the
SFX page, fills wave RAM, sets duty, NR50/NR52, clears FF10-FF23, NR30 on.
The driver itself never writes fields $06/$08/$0A/$1F/$20.'''),
    ('VBlankSndHook', 0x1610, 0x161B, 'Game VBlank handler: runs SndUpdate while wSndOn != 0 (the call at $1610 is HRAM OAM DMA)'),
    ('CallBC', 0x4903, 0x4905, 'Game helper used as "call bc": push bc / ret'),
    ('SoundDriver', 0x50A0, 0x605A, ''),
]

H = [w16(rom, 0x54BF + 2 * i) for i in range(32)]
R = [w16(rom, 0x58E2 + 2 * i) for i in range(13)]
g.entries = [0x0008, 0x0010, 0x0020, 0x0028, 0x0050, 0x06FE, 0x1610, 0x4903,
             0x50BC, 0x50E4, 0x5135, 0x51D2, 0x59A6, 0x5E43, 0x511F] + H + R
# stop tracing into game code that is outside our ranges
g.analyse()

# ------------------------------------------------------------------ symbols
for pg, nm in ((0xC100, 'wCh1'), (0xC200, 'wCh2'), (0xC300, 'wCh3'), (0xC400, 'wSfx')):
    g.symbols[pg] = nm
g.symbols.update({
    0xC107: 'wCh1FreqLo', 0xC109: 'wCh1FreqHi', 0xC10B: 'wCh1Vol',
    0xC339: 'wSfxLockedVol', 0xC402: 'wSfxPtr', 0xC430: 'wSfxId',
    0xFFC2: 'hSavedIE', 0xFFCD: 'hLCDOff', 0xFFDF: 'hSfxLock',
    0xFFE0: 'hShNR12', 0xFFE1: 'hShNR22', 0xFFE2: 'hShNR32', 0xFFE5: 'hShNR14',
    0xFFE6: 'hShNR24', 0xFFE7: 'hShNR34', 0xFFE8: 'hInInstr', 0xFFE9: 'hTranspose',
    0xFFEC: 'hReg6', 0xFFED: 'hMask', 0xFFEE: 'hMaskSaved', 0xFFEF: 'hSfxAtten',
    0xFFF0: 'hMusAtten', 0xFFF1: 'hShNR51', 0xFFF2: 'hShNR11', 0xFFF3: 'hShNR21',
    0xFFF4: 'hCh1NoteFlag', 0xFFF5: 'hSndOn',
})
g.consts[0x191D] = 'MemCopy'
g.consts[0x1E1C] = 'X1E1C'

L = {
    0x0008: 'Rst08_ReadPtr', 0x0010: 'Rst10_JumpHL', 0x0020: 'Rst20_CopyByte', 0x0028: 'Rst28_SwapHLDE',
    0x0050: 'TimerVec', 0x06FE: 'GameSndInit', 0x1610: 'VBlankSndHook', 0x4903: 'CallBC',
    0x50A0: 'OrphanTable_50A0',
    0x50B6: 'PlaySound_Locked', 0x50BC: 'PlaySoundChecked', 0x50D1: 'PlaySoundLock',
    0x50E4: 'PlaySound', 0x50EE: 'PlaySound_', 0x50FD: 'PlaySound_Start', 0x510D: 'StartSfxStream',
    0x511F: 'TimerISR', 0x5135: 'SndUpdate', 0x5169: 'OutputChannel', 0x519A: 'Output_Atten',
    0x51D2: 'StopAll', 0x5205: 'ResetChannelMask', 0x5208: 'ResetChannel', 0x5232: 'WriteReg67',
    0x5243: 'ChannelTick', 0x5299: 'ReadStream', 0x5310: 'SplitNibbles', 0x531E: 'ArpRestart',
    0x5327: 'StreamCommand', 0x535C: 'Cmd_Len', 0x5364: 'Cmd_Vol', 0x536C: 'Cmd_VolEnv',
    0x538D: 'Cmd_Arp', 0x53A9: 'CheckRelease', 0x53BD: 'Cmd_End', 0x53BE: 'StopSfx',
    0x53CB: 'Cmd_GlideOff', 0x53D0: 'Cmd_BendOff', 0x53D5: 'Cmd_MaskA', 0x53F3: 'Cmd_MaskB',
    0x53FB: 'Cmd_MaskAB', 0x5405: 'Cmd_Rest', 0x5419: 'Cmd_Wait', 0x5425: 'GetMask',
    0x542E: 'Cmd_Glide', 0x5434: 'DoGlide', 0x5440: 'DoArp', 0x546B: 'SetNoteFreq',
    0x54BF: 'CmdTable', 0x54FF: 'Cmd_Duty50', 0x5501: 'SetDuty', 0x5515: 'Cmd_Duty75',
    0x5519: 'Cmd_Duty12', 0x551D: 'Cmd_PanC', 0x5520: 'SetPan', 0x554E: 'Cmd_PanR',
    0x5553: 'Cmd_PanL', 0x5558: 'Cmd_Instrument', 0x5589: 'InstrLoop', 0x559B: 'InstrCommand',
    0x55C4: 'InstrDone', 0x55CB: 'Orphan_55CB', 0x55CD: 'Cmd_NoteOff', 0x55EF: 'NoteOffVolTable',
    0x560C: 'Orphan_560C', 0x5612: 'Cmd_Length', 0x5618: 'Cmd_Atten', 0x561E: 'Cmd_Transpose',
    0x5623: 'Cmd_PlaySfx', 0x5633: 'Cmd_Vibrato', 0x5643: 'Cmd_Release', 0x5659: 'Cmd_ArpOff',
    0x5665: 'Cmd_Slide', 0x5671: 'Cmd_Bend', 0x5683: 'Cmd_ChorusOn', 0x5688: 'Cmd_ChorusOff',
    0x568D: 'Cmd_VibratoOff', 0x5692: 'DoBend', 0x569A: 'DoSlide', 0x569F: 'SlideStep',
    0x56D1: 'DoVibrato', 0x5725: 'ApplyVolTable', 0x5751: 'DoEnvelope', 0x57AD: 'PeriodTable',
    0x584F: 'StartMusicCh1', 0x5854: 'StartMusicCh2', 0x5859: 'StartMusicCh3', 0x585B: 'StartMusicCh',
    0x5876: 'Cmd_OrderJump', 0x587C: 'Cmd_Next', 0x5894: 'Next_OrderEnd', 0x589C: 'NoiseHitInstr',
    0x58AB: 'Cmd_NoiseHit1', 0x58BE: 'Cmd_NoiseHit2', 0x58CB: 'WriteReg', 0x58E2: 'RegHandlerTable',
    0x58FE: 'Reg_NR13', 0x5902: 'Reg_NR14', 0x5913: 'Reg_NR23', 0x5917: 'Reg_NR24',
    0x5928: 'Reg_NR33', 0x592C: 'Reg_NR34', 0x593D: 'Reg_None', 0x593E: 'Reg_NR12',
    0x5955: 'Reg_NR22', 0x596C: 'Reg_NR32', 0x5988: 'Ch3VolTable', 0x5998: 'Reg_None2',
    0x5999: 'DisableInts', 0x59A1: 'RestoreInts', 0x59A6: 'PlayTitleMusic', 0x5E43: 'PlaySong2',
    0x5EC4: 'InstrTable', 0x5FAE: 'ArpTable', 0x5FD5: 'SfxTable',
}
g.labels.update(L)

# ------------------------------------------------------------------ data
wk = P.Walker(rom).run()
boundaries = set(g.code)
for a, (n, kind, payload) in wk.items.items():
    boundaries.add(a)


def ev_render(m, args, raw):
    def r(ref):
        if m == 'NOTE':
            return [note_text(args[0])]
        if m == 'VOLENV':
            return ['VOLENV %d, %s, %s, %s' % (args[0], hx(args[1]), hx(args[2]), hx(args[3]))]
        if m in ('LEN', 'VOL', 'INSTR', 'ARP', 'PLAY_SFX'):
            return ['%s %d' % (m, args[0])]
        name, kinds = P.CMDS[raw]
        parts = []
        for k, v in zip(kinds, args):
            parts.append(hx(v) if k == 'b' else ref(v))
        return [name + (' ' + ', '.join(parts) if parts else '')]
    return r


for a, (n, kind, payload) in wk.items.items():
    if kind == 'ev':
        m, args, ctx = payload
        g.items[a] = (n, ev_render(m, args, rom[a]))
    elif kind == 'ord':
        g.items[a] = (2, (lambda p: lambda ref: ['dw ' + ref(p)])(payload))
    elif kind == 'ordend':
        g.items[a] = (4, (lambda p: lambda ref: ['ORDER_LOOP ' + ref(p)])(payload))
    elif kind == 'ptr':
        g.items[a] = (2, (lambda p: lambda ref: ['dw ' + ref(p)])(payload))
    elif kind == 'arp':
        g.items[a] = (1, (lambda b: lambda ref: ['db ' + ('ARP_LOOP' if b == 0x73 else 'ARP_HOLD' if b == 0xFF else hx(b))])(payload))

# unreferenced pattern found between song data
for a, nm in wk.refs.items():
    g.labels.setdefault(a, nm)

# tables in the driver (dw)
def dw_table(start, count):
    for i in range(count):
        a = start + 2 * i
        g.items[a] = (2, (lambda p: lambda ref: ['dw ' + ref(p)])(w16(rom, a)))
dw_table(0x54BF, 32)
dw_table(0x58E2, 14)
for i in range(81):
    a = 0x57AD + 2 * i
    g.items[a] = (2, (lambda v: lambda ref: ['dw $%04X' % v])(w16(rom, a)))

# orphan pattern $5DB1-$5DD6 (not referenced by any order list)
orph = P.Walker(rom)
orph.items = dict(wk.items)
orph.stream(0x5DB1, 'pat', 'Pat_5DB1_unused')
for a, (n, kind, payload) in orph.items.items():
    if a not in wk.items:
        m, args, ctx = payload
        g.items[a] = (n, ev_render(m, args, rom[a]))
g.labels[0x5DB1] = 'Pat_5DB1_unused'

# drop labels that are not on a boundary (refs become Label+n)
occupied = {}
for a, n in g.code.items():
    occupied[a] = n
for a, (n, _) in g.items.items():
    occupied[a] = n
inner = set()
for a, n in occupied.items():
    for i in range(1, n):
        inner.add(a + i)
for a in list(g.labels):
    if a in inner:
        del g.labels[a]

# ------------------------------------------------------------------ comments
exec(open(__file__.rsplit('/', 1)[0] + '/comments_popup.py').read())

bad = g.check_overlaps()
if bad:
    print('OVERLAPS', bad[:10])
open(sys.argv[2], 'w').write(g.emit())
print('ok', len(g.code), 'code bytes-starts,', len(g.items), 'items')
