"""SFX half of the Super Mario Bros. Deluxe sound driver (bank $1F).

Same design as Link's Awakening DX bank $1F (effects are code; init and per-frame tables per
request slot; shared register-image / pitch helpers), with the slots reassigned:
  wSfx1Request ($DE60): ch1 effects $42-$78, plus $80-$A6: stop / silence / play a note on ch1
  wSfx2Request ($DE70): ch2 effects $01-$04, $24-$3D        (LA: ch3 wave effects)
  wSfx4Request ($DE78): ch4 effects $3E-$48; some also use ch3
Effect numbers are global: each table has an entry for every number below its last effect, and
the numbers that belong to another slot point at a dummy entry."""
import sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'LADX')); sys.path.insert(0, os.path.join(HERE, '..', 'tools'))
from gbdis import Region
import ladx_sfx as LS
from smbdx_music import RAM as MUSIC_RAM

RAM = dict(MUSIC_RAM)
for a, n in list(RAM.items()):
    RAM[a] = n.replace('wSfx3', 'wSfx2') if a in (0xde70, 0xde71, 0xde92, 0xde96, 0xdea2, 0xdec8) else n
RAM.update({a - 0xd300 + 0xde00: n for a, n in LS.SFX_RAM.items() if 0xd300 <= a < 0xd400})
RAM.update({0xde70: 'wSfx2Request', 0xde71: 'wSfx2Playing', 0xde92: 'wSfx2Timer', 0xde96: 'wSfx2Step',
            0xdec8: 'wSfx2Priority', 0xdebe: 'wSfx2Counter', 0xdec4: 'wSfx2Pitch', 0xdec5: 'wSfx2Pitch+1',
            0xdec2: 'wSfxPitchB', 0xdec3: 'wSfxPitchB+1', 0xdee7: 'wReloadWave', 0xdecd: 'wSfx2Paused'})

NAMES = {
 0x4009: 'Sfx_Init', 0x400c: 'Sfx_Init.clear', 0x401f: 'Sfx_Init.regs', 0x4026: 'Sfx_Init.copy', 0x402e: 'Sfx_Init.done',
 0x4033: 'Sfx_InitRegs', 0x4060: 'Sfx_Update', 0x4100: 'SfxNoteTable',
 0x4192: 'SetRegsSkip0_Ch1', 0x419b: 'SetRegsSkip0_Ch2', 0x41a4: 'SetRegsSkip0_Ch3_Unused', 0x41ad: 'SetRegsSkip0_Ch4_Unused',
 0x41b6: 'SetRegsSkip0_Copy', 0x41bb: 'SetRegsSkip0_Copy.next',
 0x41c2: 'Sfx1_InitTable', 0x42b2: 'Sfx1_PlayTable',
 0x43a2: 'Sfx1_Update', 0x43db: 'Sfx1_Update.priority1', 0x43f3: 'Sfx1_Update.start', 0x43f9: 'Sfx1_Update.playing', 0x4400: 'Sfx1_Update.dispatch',
 0x440a: 'Sfx1_StartPriority2', 0x440e: 'Sfx1_StartVar_Unused', 0x4413: 'Sfx1_StartPriority', 0x4415: 'Sfx1_StartPriority.store',
 0x4418: 'Sfx1_Start', 0x443b: 'Sfx1_StopSilent', 0x4445: 'Sfx1_StopWithRegs', 0x444b: 'Sfx1_Stop', 0x446b: 'Sfx1_StopRegs',
 0x4471: 'Sfx1_WritePeriod', 0x447b: 'Sfx2_WritePeriod', 0x4485: 'Sfx1_Refuse',
 0x448c: 'Sfx2_Update', 0x44a1: 'Sfx2_Update.checkPriority', 0x44bd: 'Sfx2_Update.priority2', 0x44ca: 'Sfx2_Update.priority1',
 0x44da: 'Sfx2_Update.check24', 0x44ed: 'Sfx2_Update.start', 0x44f3: 'Sfx2_Update.playing', 0x44fa: 'Sfx2_Update.dispatch',
 0x4509: 'Sfx2_InitTable', 0x4583: 'Sfx2_PlayTable', 0x45fd: 'CopyWave', 0x4600: 'CopyWave.loop', 0x460a: 'LoadWave',
 0x4610: 'Sfx2_Refuse', 0x4617: 'Sfx4_InitTable', 0x46a7: 'Sfx4_PlayTable',
 0x4737: 'Sfx4_Update', 0x4755: 'Sfx4_Update.start', 0x4761: 'Sfx4_Update.playing', 0x4768: 'Sfx4_Update.dispatch',
 0x4772: 'Sfx4_StartPriority_Unused', 0x4777: 'Sfx4_Start', 0x6259: 'Unused_6259', 0x478f: 'Sfx4_StopWithRegs', 0x4795: 'Sfx4_Stop', 0x47ae: 'Sfx4_StopRegs', 0x47b3: 'Sfx4_WritePeriod_Unused',
 0x47bd: 'Sfx4_Refuse', 0x47c4: 'Sfx2_StartPriority2', 0x47c8: 'Sfx2_StartPriority3', 0x47cc: 'Sfx2_StartPriority4',
 0x47d0: 'Sfx2_StartPriority', 0x47d2: 'Sfx2_StartPriority.store', 0x47d5: 'Sfx2_Start', 0x47f5: 'Sfx2_StopWithRegs', 0x47fb: 'Sfx2_Stop',
 0x480e: 'Sfx2_StopRegs', 0x4813: 'Sfx4Wave_StartPriority', 0x4818: 'Sfx4Wave_Start', 0x481e: 'Sfx4Wave_Take',
 0x4833: 'Sfx4Wave_StopRegs', 0x4839: 'Sfx4Wave_Stop',
 0x67f1: 'Sfx1_Note', 0x681f: 'Sfx1_Note.silence', 0x682d: 'Sfx1_Note.stop', 0x6830: 'Sfx1_Note.done',
 0x6838: 'GetPointer', 0x6845: 'Sfx_DecTimer', 0x6849: 'Sfx_IncStep',
 0x684d: 'SetRegs_Ch1', 0x6856: 'SetRegs_Ch2', 0x685f: 'SetRegs_Ch3', 0x6868: 'SetRegs_Ch4', 0x6871: 'SetRegs_Copy',
 0x687a: 'Sfx1_DecCounter', 0x6880: 'SfxB_DecCounter', 0x6886: 'Sfx2_DecCounter', 0x688c: 'Sfx4_DecCounter', 0x6892: 'Sfx_DecCounter',
 0x6897: 'Sfx1_LoadPitch', 0x689d: 'Sfx2_LoadPitch', 0x68a1: 'Sfx_LoadPitch', 0x68b0: 'SfxB_LoadPitch',
 0x68c1: 'Sfx1_AddPitch', 0x68cb: 'Sfx2_AddPitch', 0x68d5: 'Sfx_AddPitch', 0x68f1: 'SfxB_AddPitch',
 0x68fb: 'Sound_Stop',
}
SHARED = {a for a in NAMES if a >= 0x6838 or 0x4192 <= a < 0x41c2 or 0x440a <= a < 0x448c or 0x45fd <= a < 0x4617
          or 0x4777 <= a < 0x4845 or a in (0x43a2, 0x448c, 0x4737, 0x67f1)}

COMMENTS = {
 0x4000: 'Entry points: init, stop, update.',
 0x4009: 'Clear $DE00-$DEFF, switch the APU on and write the register list Sfx_InitRegs\n(count, first register, values; 0 ends it).',
 0x4060: 'Called once per frame after the music bank: the three effect slots, then clear the\nrequests.',
 0x4100: 'copy of the music note table; the ch1 "note" requests read it from entry 25 on',
 0x4192: 'Like SetRegs_ChN, but a zero byte leaves its register alone.',
 0x43a2: 'Requests $80 and above: Sfx1_Note. Effects $42-$78; the others are dropped. While a\npriority effect plays only some effects get through: priority 1 lets $4D, $4E and\n$53-$5E (except $57) through; priority 2 lets $4D, $4E, $56 and $5B-$5E through.',
 0x440e: 'unreferenced',
 0x4418: 'Start a ch1 effect: hl = NR10-NR14 + frames. Takes ch1 from the music.',
 0x448c: 'Effects $01-$04 and $24-$3D. $01-$04 always start; the others depend on the priority of\nthe playing effect (1: $25, $2B-$2E; 2: $2C-$2E; 3, 4: $2D, $2E). Effect $24 is refused\nwhile effect $38-$3C plays. Nothing runs while wSfx2Paused is set.',
 0x4737: 'Effects $3E-$48; while a priority effect plays only $45 gets through.',
 0x47d5: 'Start a ch2 effect: hl = NR21-NR24 + frames. Takes ch2 from the music.',
 0x4818: 'Start a slot-4 effect on ch3: hl = NR30-NR34 + frames.',
 0x4839: 'End a slot-4 ch3 effect and tell the music to reload its wave.',
 0x67f1: 'Requests $80-$A6 on ch1: $80 ends the ch1 effect, $81 silences ch1, $82-$A6 play a note\n(NR10 = 8, NR11 = $80, NR12 = $D2, period = SfxNoteTable entry 25 + request - $82).',
 0x6838: 'hl = table, a = 1-based index: hl = table[a-1]',
 0x6845: 'de = timer: decrement (Z when it reaches 0). bc = step: increment, a = new step.',
 0x684d: 'Write a register image (b bytes from NRx0/NRx1) and store the following byte as the\nslot\'s timer.',
 0x687a: 'Count down an effect\'s private counter; Z at 0. Some of these helpers are unreferenced\nhere (they come from LA).',
 0x68c1: 'Add a big-endian offset (table[step-1]) to the effect\'s period and write NRx3/NRx4.',
 0x68fb: 'Stop everything: music, effects, panning; mute.',
}

DUMMY = {0x4939, 0x493f, 0x5762, 0x5768, 0x475e, 0x475b}
TABLES = ((1, 0x41c2, 0x42b2, 120), (2, 0x4509, 0x4583, 61), (4, 0x4617, 0x46a7, 72))


def build(rom):
    r = Region(rom, 0x1f, 0x4000, 0x8000)
    r.ram = dict(RAM)
    r.trace([0x4000, 0x4003, 0x4006])
    tables = {}
    for ch, i, p, n in TABLES:
        tables[ch] = (r.jumptable(i, n), r.jumptable(p, n))
    r.code_range(0x687a, 0x68fb); r.code_range(0x4192, 0x41c2); r.code_range(0x440e, 0x4413); r.code_range(0x47b3, 0x47bd); r.code_range(0x4772, 0x4777); r.code_range(0x6259, 0x625a)
    for a, n in NAMES.items(): r.label(a, n)
    r.label(0x4939, 'Sfx1_Dummy_Init'); r.label(0x493f, 'Sfx1_Dummy_Play')
    r.label(0x5762, 'Sfx2_Dummy_Init'); r.label(0x5768, 'Sfx2_Dummy_Play')
    r.label(0x4951, 'Sfx1_Dummy_Data_4951'); r.label(0x4957, 'Sfx1_Dummy_Data_4957')
    r.label(0x577a, 'Sfx2_Dummy_Data_577A'); r.label(0x577f, 'Sfx2_Dummy_Data_577F')
    r.label(0x475e, 'Sfx4_Dummy_Init'); r.label(0x475b, 'Sfx4_Dummy_Play')
    return r, tables


F = LS.Cfg()
F.STEP6 = {0x684d, 0x685f, 0x440a, 0x4413, 0x4418, 0x4445, 0x4813, 0x4818, 0x4839, 0x4192, 0x41a4}
F.STEP5 = {0x6856, 0x6868, 0x4777, 0x478f, 0x47c4, 0x47c8, 0x47cc, 0x47d0, 0x47d5, 0x47f5, 0x419b, 0x41ad}
F.FMT3 = {0x4471, 0x447b, 0x47b3}
F.FMTBE = {0x68c1, 0x68cb, 0x68f1}
F.FMTWAVE = {0x45fd, 0x460a}
F.PITCH = {0x6897, 0x689d, 0x68b0}
F.GETPTR = 0x6838
F.SHARED = SHARED | DUMMY
F.NAMES, F.COMMENTS, F.DUMMY = NAMES, COMMENTS, DUMMY
F.sfx_id = lambda ch, i: i if ((ch == 1 and 0x42 <= i <= 0x78) or (ch == 2 and (i <= 4 or 0x24 <= i <= 0x3d))
                               or (ch == 4 and 0x3e <= i <= 0x48)) else None
F.build = build


def generate(rom):
    r, tables, entries, datarefs = LS.generate(rom, F)
    r.block(0x4033, 0x2d, lambda rr, a: ['\tdb $10, $30\t; wave RAM ($FF30): 16 bytes', '\tds 16, 0',
                                         '\tdb $05, LOW(rNR10), $08, $c0, $00, $00, $80',
                                         '\tdb $04, LOW(rNR21), $c0, $00, $00, $80',
                                         '\tdb $05, LOW(rNR30), $00, $00, $00, $00, $00',
                                         '\tdb $04, LOW(rNR41), $00, $00, $00, $80', '\tdb $00'])
    r.block(0x4100, 146, lambda rr, a: [f'\tdw ${rr.word(a+2*i):04x}' + (f'\t; ${0x82+i-25:02x}' if i >= 25 else '') for i in range(73)])
    for a in [x for x in r.labels if 0x4100 < x < 0x4192]: del r.labels[a]
    r.comments[0x4772] = 'unreferenced'; r.comments[0x6259] = 'unreferenced'
    if 0x5fd2 not in r.labels: r.label(0x5fd2, 'Unused_5FD2', 'unreferenced')
    LS.make_spans(r, datarefs, 0x4100, 0x68fb, F)
    return r, tables, entries, datarefs
