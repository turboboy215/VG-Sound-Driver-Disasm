# Kid Niki (J) - generator configuration
from paths import ROMS; ROMFILE=ROMS['kn']
GAME='kn'; P='KN'; EXPORT=False; BANK=1
RAM={0xc800:'wSfxTracks',0xc80e:'wSfxReq',0xc80f:'wMusPan',0xc81e:'wMusReq',0xc81f:'wSfxPan',
     0xc840:'wMusTracks',0xc890:'wCurTrack',0xc891:'wCurSet',0xc810:'wSfxTracks+$10',0xc820:'wSfxTracks+$20',
     0xc830:'wSfxTracks+$30'}
CODE_NAMES={
 0x7a00:'KN_ChanOwner',0x7a18:'KN_ChanOwner.music',0x7a34:'KN_ChanOwner.none',
 0x7a36:'KN_Ch1Out',0x7a47:'KN_Ch2Out',0x7a50:'KN_ChOutTail',0x7a68:'KN_Ch3Out',0x7a8c:'KN_Ch4Out',
 0x7a9f:'KN_LoadRequest',0x7ab8:'KN_LoadRequest.track',0x7ad2:'KN_LoadRequest.done',
 0x7ad3:'KN_NextTrack',0x7ad8:'KN_TrackStep',0x7af0:'KN_ReadByte',0x7b0b:'KN_Cmd89_Hold',0x7b0d:'KN_StoreNote',
 0x7b23:'KN_SetSpeed',0x7b50:'KN_Cmd8F_SfxPan',0x7b58:'KN_Cmd8A_MusPan',0x7b60:'KN_Cmd8E_NR50',
 0x7b67:'KN_Cmd8C_Wave',0x7b82:'KN_Copy4',0x7b8f:'KN_Cmd88_NRx4',0x7b97:'KN_Cmd80_NRx1',0x7b9f:'KN_Cmd81_NR10',
 0x7ba7:'KN_Cmd82_Transpose',0x7baf:'KN_Cmd83_NRx2',0x7bb4:'KN_StoreArg',0x7bbd:'KN_Cmd84_Skip',
 0x7bc2:'KN_Cmd85_Call',0x7bdb:'KN_Cmd86_Return',0x7bf2:'KN_Cmd86_Return.endSet',0x7c0f:'KN_Cmd86_Return.endMusic',
 0x7c22:'KN_Cmd87_Stop',0x7c2b:'KN_Cmd87_Stop.ret',0x7c2c:'KN_Cmd8B_Jump',
 0x7e50:'KN_SndUpdate',0x7e9b:'KN_UpdatePan',0x7eb0:'KN_UpdatePan.write',
 0x130e:'KN_SndReset',0x1334:'KN_SndReset.clear',0x1376:'KN_SetNR50Wait',0x137c:'KN_Delay256',0x137d:'KN_Delay256.loop',
}
DATA_NAMES={0x7b30:'KN_CmdTable',0x7d00:'KN_SoundTable',0x7e00:'KN_WaveTable',0x7f00:'KN_PeriodTable'}
C={}
def c(a,t,b=1): C[(b,a)]=t
# ROM0
c(0x130e,'fade NR50 out in 7 busy-wait steps',0); c(0x1331,'clear the driver RAM $C800-$C8FF',0)
c(0x133b,'CH1/CH2/CH4 envelope 0 (NR12, NR22, NR42)',0); c(0x1343,'CH3 level 0',0); c(0x1346,'retrigger CH1, CH2, CH4 (silences them)',0)
c(0x134e,'fade NR50 back in',0); c(0x1376,'NR50 = a, then wait 127 loop iterations',0); c(0x137c,'wait 255 loop iterations',0)
# bank 1
c(0x7a00,'set-0 (SFX) track b: active?'); c(0x7a07,'not on the row it was read -> nobody writes'); c(0x7a0d,'note byte'); c(0x7a12,'hold -> nobody writes')
c(0x7a17,'SFX owns the channel'); c(0x7a18,'SFX track off: try the music track (b += $40)'); c(0x7a33,'music owns the channel')
c(0x7a34,'drop our return address: the caller returns'); c(0x7a3c,'NR10 = TRK_NR10'); c(0x7a4b,'from TRK_NRX1')
c(0x7a50,'NRx1 = TRK_NRX1'); c(0x7a53,'NRx2 = TRK_NRX2'); c(0x7a56,'(TRK_NOTE + TRK_TRANSP) * 2, 8-bit'); c(0x7a5b,'KN_PeriodTable page')
c(0x7a5f,'NRx3 = period low'); c(0x7a63,'| TRK_NRX4'); c(0x7a64,'| trigger'); c(0x7a68,'CH3 DAC on (every update, written or not)')
c(0x7a76,'NR31 = TRK_NRX1'); c(0x7a79,'NR32 = TRK_NRX2 (level)'); c(0x7a87,'trigger + length enable, TRK_NRX4 ignored')
c(0x7a90,'from TRK_NRX2'); c(0x7a96,'NR42 = TRK_NRX2'); c(0x7a99,'NR43 = TRK_NOTE (the noise byte)'); c(0x7a9d,'NR44 = trigger')
c(0x7a9f,'request id'); c(0x7aaa,'mark the request taken'); c(0x7aad,'id * 8 (8-bit: ids >= 32 wrap)'); c(0x7ab4,'KN_SoundTable page')
c(0x7ab8,'TRK_SPEED = 1 (track on)'); c(0x7abd,'TRK_TICK = 0'); c(0x7abf,'TRK_PTR = stream'); c(0x7ac7,'TRK_INCALL = 0')
c(0x7ad3,'next track (+$10)'); c(0x7ae1,'off'); c(0x7ae4,'TRK_TICK += 1'); c(0x7ae6,'== TRK_SPEED?'); c(0x7aea,'TRK_TICK = 0, read a row')
c(0x7af2,'$00-$7F: note'); c(0x7af7,'$90-$FF: speed'); c(0x7afc,'$80-$8F: command'); c(0x7b0b,'$89: hold, stored like a note')
c(0x7b0d,'TRK_NOTE'); c(0x7b1f,'TRK_PTR = next byte'); c(0x7b23,'TRK_SPEED = byte - $90')
c(0x7b67,'CH3 DAC off'); c(0x7b6b,'KN_WaveTable page, the argument is the offset'); c(0x7bc2,'TRK_RET'); c(0x7bd5,'TRK_INCALL = 1')
c(0x7bdb,'TRK_INCALL'); c(0x7be9,'clear it, back to TRK_RET'); c(0x7bf2,'not in a call: end the whole set')
c(0x7bf4,'which set?'); c(0x7c09,'wSfxReq = 0'); c(0x7c1c,'wMusReq = 0'); c(0x7c22,'TRK_SPEED = 0 (this track only)')
c(0x7e50,'SFX request'); c(0x7e59,'music request'); c(0x7e62,'wCurSet = 0 (SFX)'); c(0x7e67,'track $00 (a = 0)'); c(0x7e73,'wCurSet = 1 (music)')
c(0x7e9b,'sum of the SFX TRK_SPEED bytes'); c(0x7ead,'any SFX on: add wSfxPan'); c(0x7eb4,'NR51 = wMusPan | (SFX ? wSfxPan : 0)')
COMMENTS=C
BLOCKS={0:{},1:{}}
def blk(a,lines,b=1): BLOCKS[b][a]=['']+['; '+l if l else ';' for l in lines]
blk(0x130e,['KN_SndReset: fade out, clear all driver RAM, silence the channels, fade in.','Called by the game (6 call sites); busy-waits 14 x 127 loop iterations.'],0)
blk(0x7a00,['KN_ChanOwner: called with b = channel offset ($00/$10/$20/$30), h = $C8.','Returns to the caller (b = owning track) only when that track read a new row this','update and it is not a hold; otherwise pops the caller and returns to the update.','The SFX track wins whenever it is on, even between its rows.'])
blk(0x7a36,['Channel output: write the owning track to the registers (once per row).'])
blk(0x7a9f,['KN_LoadRequest: hl = request byte, bc = first track of the set.','0 / $FF: nothing. Otherwise $FF is stored and four tracks start from KN_SoundTable.'])
blk(0x7ad3,['KN_NextTrack / KN_TrackStep: count a tick on track wCurTrack and read a row when','TRK_TICK reaches TRK_SPEED: commands are run until a note ($00-$7F) or a hold ($89).'])
blk(0x7b30,['KN_CmdTable: commands $80-$8F (low nibble)'])
blk(0x7b50,['Command handlers. bc = stream pointer (after the command byte).'])
blk(0x7d00,['KN_SoundTable: 32 ids x 4 stream pointers (CH1, CH2, CH3, CH4).','Ids 1, 2, $0D-$1F are SFX (wSfxReq); 3-$0C are songs (wMusReq); id 0 = all channels end at once.'])
blk(0x7e00,['KN_WaveTable: CH3 waves, $8C xx copies 16 bytes from KN_WaveTable + xx'])
blk(0x7e50,['KN_SndUpdate: the driver entry, called once per VBlank by the game (ROM0 $01AC,','after rst $08 selected bank 1).'])
blk(0x7e9b,['KN_UpdatePan: NR51.'])
blk(0x7f00,['KN_PeriodTable: 72 periods, C2 ... B7 (index = note + transpose)'])
OPERAND={(1,0x7a5b):'HIGH(KN_PeriodTable)',(1,0x7a80):'HIGH(KN_PeriodTable)',(1,0x7ab4):'HIGH(KN_SoundTable)',(1,0x7b6b):'HIGH(KN_WaveTable)',
 (1,0x7a36):'HIGH(wSfxTracks)',(1,0x7adc):'HIGH(wSfxTracks)',(1,0x7b14):'HIGH(wSfxTracks)',(1,0x7b1d):'HIGH(wSfxTracks)',
 (1,0x7b2a):'HIGH(wSfxTracks)',(1,0x7bb5):'HIGH(wSfxTracks)',(1,0x7bc8):'HIGH(wSfxTracks)',(1,0x7be1):'HIGH(wSfxTracks)',(1,0x7c26):'HIGH(wSfxTracks)'}
CMDS={0x80:('nrx1','b'),0x81:('nr10','b'),0x82:('transpose','b'),0x83:('nrx2','b'),0x84:('skip84','b'),0x85:('sndcall','w'),
 0x86:('sndret',''),0x87:('sndstop',''),0x88:('nrx4','b'),0x8a:('muspan','b'),0x8b:('sndjump','w'),0x8c:('wave','b'),
 0x8d:('skip8d','b'),0x8e:('nr50','b'),0x8f:('sfxpan','b')}
SPEEDBASE=0x90; NPERIODS=72
HEADER=['; Kid Niki (J) - Irem sound driver (bank 1) and its ROM0 reset routine',
 '; Disassembly rebuilt byte-exact with RGBDS 0.9.1 (see KidNiki_SoundDriver.md).','; Generated by tools/gen_asm.py kn.','']
CODE_ENTRIES={1:[0x7e50]+[0x7b97,0x7b9f,0x7ba7,0x7baf,0x7bbd,0x7bc2,0x7bdb,0x7c22,0x7b8f,0x7b0b,0x7b58,0x7c2c,0x7b67,0x7bbd,0x7b60,0x7b50],0:[0x130e,0x137c]}
def soundtab(g,w):
    for i,ps in enumerate(w.idtab):
        a=0x7d00+8*i; g.emit_label(1,a)
        g.emit('%-36s; %04x  id $%02X'%('    dw '+', '.join(g.ref(1,p) for p in ps),a,i))
def waves(g,w):
    for k in range(5): g.emit_db(1,0x7e00+16*k,0x7e10+16*k)
LAYOUT=[('section','KN sound reset',0,0x130e),('code',0,0x130e,0x1381),
 ('section','KN sound data',1,0x6600),('streams',1,0x6600,0x74f4),('fill',1,0x74f4,0x7a00),
 ('code',1,0x7a00,0x7b30),('dw',1,0x7b30,0x7b50,{'labels':True,'per':4,'cmts':['$80-$83','$84-$87','$88-$8B','$8C-$8F']}),
 ('code',1,0x7b50,0x7c36),('fill',1,0x7c36,0x7d00),('custom',1,0x7d00,0x7e00,soundtab),('custom',1,0x7e00,0x7e50,waves),
 ('code',1,0x7e50,0x7eb8),('fill',1,0x7eb8,0x7f00),('dw',1,0x7f00,0x7f90,{'per':12}),('fill',1,0x7f90,0x8000)]
EQUS=['; track fields (16 bytes per track: SFX tracks at wSfxTracks, music at wMusTracks)',
 'DEF TRK_SPEED  EQU $0 ; ticks per row (0 = track off)','DEF TRK_TICK   EQU $1','DEF TRK_PTR    EQU $2 ; word',
 'DEF TRK_RET    EQU $4 ; word, $85 return address','DEF TRK_INCALL EQU $6','DEF TRK_NR10   EQU $7','DEF TRK_NRX1   EQU $8',
 'DEF TRK_NRX2   EQU $9','DEF TRK_NOTE   EQU $A','DEF TRK_TRANSP EQU $B','DEF TRK_NRX4   EQU $C']
