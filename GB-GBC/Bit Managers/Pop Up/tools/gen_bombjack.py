"""Generate BombJack_SoundDriver.asm (byte-exact).  usage: gen_bombjack.py <rom> <out.asm>"""
import sys
sys.path.insert(0, __file__.rsplit('/', 1)[0])
from asmgen import Gen
import bombjack_data as D
from notes import NOTE_MACRO, note_text, hx

rom = open(sys.argv[1], 'rb').read()
g = Gen(rom)
w16 = D.w16

g.header = r'''; =====================================================================
; Bomb Jack (U) - Game Boy, Infogrames 1992
; Sound driver by Alberto Jose Gonzalez (Bit Managers): "AJG driver", version 2
;
; Rebuilds byte-exact with RGBDS 0.9.1:
;   rgbasm -Wall -o bombjack.o BombJack_SoundDriver.asm
;   rgblink -t -o bombjack.gb bombjack.o
;   python tools/cmp_ranges.py bombjack.gb "Bomb Jack (U).gb" <ranges listed in the doc>
; (-t: 32 KB ROM without MBC, so $4000-$7FFF is plain ROM.)
;
; Documentation: BombJack_SoundDriver.md / AJG_SoundEngine_Family.md
; =====================================================================
'''

cmd_macros = []
for b, (name, kinds) in sorted(D.CMDS.items()):
    if kinds is None:
        continue
    body = ['\tdb $%02X' % b]
    for i, k in enumerate(kinds):
        body.append(('\tdb \\%d' if k == 'b' else '\tdw \\%d') % (i + 1))
    cmd_macros.append(f'MACRO {name}\n' + '\n'.join(body) + '\nENDM')

g.macros = NOTE_MACRO + r'''
; ---- stream commands (patterns, SFX streams and instrument macros) ----
MACRO LEN       ; note length in ticks, 1-57
	db $C6 + \1
ENDM
MACRO VOL       ; start volume of following notes, 0-15 (software envelope mode)
	db $A7 + \1
ENDM
MACRO VOLENV    ; start volume + envelope: atk (lo=count hi=step), dec (lo=count hi=step), rates (hi=atk lo=dec)
	db $B7 + \1, \2, \3, \4
ENDM
MACRO INSTR     ; instrument 0-25 from the current song's instrument table
	db $7E + \1
ENDM
MACRO ARP       ; arpeggio 0-14 from the current song's arpeggio table
	db $98 + \1
ENDM
MACRO DRUMS     ; DRUMS 0 = off, DRUMS tempo, pattern
	db $6B, \1
	IF _NARG > 1
		dw \2
	ENDC
ENDM
MACRO HWENV     ; HWENV env | HWENV env, 0 | HWENV env, ticks, env2  (hardware envelope mode)
	db $72, \1
	IF _NARG > 1
		db \2
	ENDC
	IF _NARG > 2
		db \3
	ENDC
ENDM
MACRO RELEASE   ; RELEASE 0 = off | RELEASE ticks_left, env
	db $77, \1
	IF _NARG > 1
		db \2
	ENDC
ENDM
''' + '\n'.join(cmd_macros) + r'''
; ---- order lists ----
MACRO ORDER_LOOP  ; end of an order list: 0, then the order position to continue from
	dw 0, \1
ENDM
; ---- arpeggio tables ----
DEF ARP_LOOP EQU $68   ; restart the table
DEF ARP_HOLD EQU $FF   ; stay on the previous entry
; ---- drum patterns (one step per drum tick) ----
DEF DRUM_LOOP EQU $FF
'''

g.sections = [
    ('RST00_MemCopy', 0x0000, 0x0003, 'rst $00: jp MemCopy (game code, used by SndInit)'),
    ('RST18_AddHLA', 0x0018, 0x001E, 'rst $18: hl += a'),
    ('RST20_CopyByte', 0x0020, 0x0027, 'rst $20: [de++] = [hl++], bc-- (flags/af kept)'),
    ('VBlankSndHook', 0x0316, 0x0319, 'Game VBlank handler: calls SndUpdate every frame'),
    ('MemCopy', 0x1470, 0x1479, 'Game MemCopy: copy bc bytes hl -> de'),
    ('SoundDriver', 0x54EE, 0x7A01, ''),
]

H = [w16(rom, 0x5697 + 2 * i) for i in range(30)]
g.entries = [0x0000, 0x0018, 0x0020, 0x0316, 0x1470,
             0x54EE, 0x5A02, 0x5B0E, 0x5BE2, 0x5E69, 0x60F2, 0x60F5, 0x60F8, 0x60FB, 0x743E,
             0x56D3, 0x56D8] + H
g.analyse()

for pg, nm in ((0xC400, 'wCh1'), (0xC500, 'wCh2'), (0xC600, 'wCh3'), (0xC700, 'wSfx')):
    g.symbols[pg] = nm
g.symbols.update({
    0xC001: 'wGameC001', 0xC318: 'wShFreqHi', 0xC319: 'wShFreqHi2', 0xC31A: 'wShFreqHi3',
    0xC31B: 'wShNR32', 0xC31C: 'wInInstr', 0xC31D: 'wTranspose', 0xC31E: 'wShNR51',
    0xC31F: 'wInstrTable', 0xC320: 'wInstrTableHi', 0xC321: 'wArpTable', 0xC322: 'wArpTableHi',
    0xC323: 'wMusicWave', 0xC324: 'wMusicWaveHi', 0xC325: 'wFadePtr', 0xC326: 'wFadePtrHi',
    0xC327: 'wDrumPatHi', 0xC328: 'wDrumPatLo', 0xC329: 'wDrumPos', 0xC32A: 'wDrumsOn',
    0xC32B: 'wDrumTempo', 0xC32C: 'wDrumTimer', 0xC32D: 'wNoiseNR43Hi', 0xC32E: 'wNoiseNR43Lo',
    0xC32F: 'wNoiseNR42Hi', 0xC330: 'wNoiseNR42Lo', 0xC331: 'wNoisePos', 0xC332: 'wNoiseOn',
    0xC335: 'wFadePos', 0xC336: 'wFadeTimer', 0xC337: 'wFadeSpeed', 0xC338: 'wFadeOn',
    0xC402: 'wCh1Ptr', 0xC510: 'wCh2On', 0xC610: 'wCh3On', 0xC702: 'wSfxPtr', 0xC710: 'wSfxId',
    0xFF82: 'hGameFF82', 0xFF99: 'hGameFF99', 0xFFC0: 'hGameFFC0',
})

L = {
    0x0000: 'Rst00_MemCopy', 0x0018: 'Rst18_AddHLA', 0x0020: 'Rst20_CopyByte',
    0x0316: 'VBlankSndHook', 0x1470: 'MemCopy',
    0x54EE: 'SndUpdate', 0x5517: 'DrumTick', 0x5521: 'ChannelTick', 0x5544: 'ReadStream',
    0x5589: 'SplitNibbles', 0x5597: 'StreamCommand', 0x55C1: 'CallBC', 0x55C3: 'Cmd_Len',
    0x55CB: 'Cmd_VolEnv', 0x55F6: 'Cmd_Vol', 0x55FE: 'Cmd_Arp', 0x5620: 'Cmd_Instrument',
    0x5658: 'InstrLoop', 0x5667: 'InstrCommand', 0x568F: 'InstrDone', 0x5697: 'CmdTable',
    0x56D3: 'Unused_ChorusOn', 0x56D8: 'Unused_ChorusOff', 0x56DD: 'PatReturn',
    0x56EA: 'Cmd_PatCall', 0x56F3: 'Cmd_PatGoto', 0x5700: 'Cmd_ArpOff', 0x5705: 'CheckRelease',
    0x5739: 'Cmd_Release', 0x574F: 'Cmd_ChTranspose', 0x5755: 'Cmd_Glide', 0x575B: 'DoGlide',
    0x5767: 'Cmd_Wait2', 0x5769: 'Cmd_Vibrato', 0x5785: 'DoVibrato', 0x57CD: 'Cmd_Wait',
    0x57DA: 'Cmd_Rest', 0x57F0: 'StopAll', 0x581B: 'Cmd_End', 0x5827: 'ResetChannel',
    0x5876: 'Cmd_Transpose', 0x587C: 'Cmd_OrderJump', 0x5888: 'Cmd_Next', 0x58A6: 'Next_OrderEnd',
    0x58AE: 'Cmd_Length', 0x58BA: 'Cmd_Drums', 0x58DB: 'DrumStep', 0x5920: 'DrumLoop',
    0x5927: 'NoiseSeqTick', 0x5968: 'NoiseSeq1_NR43', 0x5970: 'NoiseSeq1_NR42',
    0x5977: 'NoiseSeq2_NR43', 0x597F: 'NoiseSeq2_NR42', 0x5986: 'NoiseSeq3_NR43',
    0x5989: 'NoiseSeq3_NR42', 0x598B: 'Orphan_598B',
    0x5992: 'Drum1_NoiseSeq1', 0x59AA: 'Cmd_NoiseSeq2', 0x59C8: 'Cmd_NoiseSeq3',
    0x59E0: 'Drum4', 0x59EB: 'Drum5', 0x59F6: 'Drum6', 0x5A02: 'Cmd_NoiseHit7', 0x5A13: 'NoiseTrigger',
    0x5A1A: 'Cmd_PanC', 0x5A1F: 'Cmd_PanR', 0x5A24: 'Cmd_PanL', 0x5A27: 'SetPan',
    0x5A58: 'Cmd_Duty50', 0x5A5C: 'Cmd_Duty75', 0x5A60: 'Cmd_Duty12', 0x5A62: 'SetDuty',
    0x5A74: 'Cmd_HwEnv', 0x5A95: 'HwEnvNoteOn', 0x5AA8: 'Cmd_AutoPan', 0x5AB3: 'DoAutoPan',
    0x5ADD: 'Cmd_AutoDuty', 0x5AE8: 'DoAutoDuty', 0x5B0E: 'StartFade', 0x5B27: 'FadeEnd',
    0x5B2C: 'DoFade', 0x5B4A: 'FadeStep', 0x5B75: 'FadeOutTable', 0x5B7E: 'Cmd_Wave',
    0x5B97: 'LoadWave', 0x5BB8: 'RestoreMusicWave', 0x5BE2: 'SndInit', 0x5C21: 'ClearChannelRest',
    0x5C29: 'PeriodTable', 0x5CCB: 'DoArp', 0x5CEE: 'SetNoteFreq', 0x5D19: 'DoEnvelope',
    0x5D85: 'StartMusicCh1', 0x5D89: 'StartMusicCh2', 0x5D8D: 'StartMusicCh3', 0x5D8F: 'StartMusicCh',
    0x5DA5: 'OutputAll', 0x5DB9: 'OutputChannel', 0x5E19: 'WriteVolume', 0x5E3F: 'WriteCh3Vol',
    0x5E59: 'Ch3VolTable', 0x5E69: 'PlaySfx', 0x5EDA: 'PlaySfx_Done', 0x5F2F: 'StereoNR50Table',
    0x5F3F: 'SfxTable_m2', 0x6069: 'ChInit1', 0x6075: 'ChInit2', 0x6081: 'ChInit3',
    0x608D: 'SetSongTables', 0x60F2: 'JpPlaySong4', 0x60F5: 'JpPlaySong3', 0x60F8: 'JpPlaySong2',
    0x60FB: 'PlaySong1', 0x642E: 'PlaySong2', 0x64E6: 'PlaySong3', 0x6584: 'PlaySong4',
    0x743E: 'PlaySong5',
}
g.labels.update(L)

wk = D.Walker(rom).run()
# orphans
wk.stream(0x78BA, 'pat', 'Pat_78BA_unused', (0x7930, 0x79E2))
wk.drum(0x7435)
wk.refs[0x7435] = 'Drums_7435_unused'


def ev_render(m, args, raw):
    def r(ref):
        if m == 'NOTE':
            return [note_text(args[0])]
        if m == 'VOLENV':
            return ['VOLENV %d, %s, %s, %s' % (args[0], hx(args[1]), hx(args[2]), hx(args[3]))]
        if m in ('LEN', 'VOL', 'INSTR', 'ARP'):
            return ['%s %d' % (m, args[0])]
        kinds = D.CMDS[raw][1]
        if kinds is None:
            kinds = 'bw' if raw == 0x6B else 'bbb'
        parts = []
        for k, v in zip(kinds, args):
            parts.append(hx(v) if k == 'b' else ref(v))
        return [m + (' ' + ', '.join(parts) if parts else '')]
    return r


for a, (n, kind, payload) in wk.items.items():
    if kind == 'ev':
        m, args, ctx = payload
        g.items[a] = (n, ev_render(m, args, rom[a]))
    elif kind in ('ord', 'ptr'):
        g.items[a] = (2, (lambda p: lambda ref: ['dw ' + ref(p)])(payload))
    elif kind == 'ordend':
        g.items[a] = (4, (lambda p: lambda ref: ['ORDER_LOOP ' + ref(p)])(payload))
    elif kind == 'arp':
        g.items[a] = (1, (lambda b: lambda ref: ['db ' + ('ARP_LOOP' if b == 0x68 else 'ARP_HOLD' if b == 0xFF else hx(b))])(payload))
    elif kind == 'drum':
        g.items[a] = (1, (lambda b: lambda ref: ['db ' + ('DRUM_LOOP' if b == 0xFF else hx(b))])(payload))
    elif kind == 'wave':
        g.items[a] = (16, (lambda a: lambda ref: ['db ' + ', '.join(hx(x) for x in rom[a:a + 8]),
                                                   'db ' + ', '.join(hx(x) for x in rom[a + 8:a + 16])])(a))
for a, nm in wk.refs.items():
    g.labels.setdefault(a, nm)


def dw_table(start, count):
    for i in range(count):
        a = start + 2 * i
        g.items[a] = (2, (lambda p: lambda ref: ['dw ' + ref(p)])(w16(rom, a)))


dw_table(0x5697, 30)
for i in range(81):
    a = 0x5C29 + 2 * i
    g.items[a] = (2, (lambda v: lambda ref: ['dw $%04X' % v])(w16(rom, a)))

# drop labels inside items/instructions
occupied = dict(g.code)
for a, (n, _) in g.items.items():
    occupied[a] = n
inner = set()
for a, n in occupied.items():
    for i in range(1, n):
        inner.add(a + i)
for a in list(g.labels):
    if a in inner:
        del g.labels[a]

exec(open(__file__.rsplit('/', 1)[0] + '/comments_bombjack.py').read())

bad = g.check_overlaps()
if bad:
    print('OVERLAPS', bad[:10])
open(sys.argv[2], 'w').write(g.emit())
print('ok', len(g.code), 'instructions,', len(g.items), 'items')
