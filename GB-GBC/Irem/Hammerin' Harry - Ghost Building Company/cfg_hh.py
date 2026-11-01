# Hammerin' Harry - Ghost Building Company (U) - generator configuration
from paths import ROMS; ROMFILE=ROMS['hh']
GAME='hh'; P='HH'; EXPORT=False; BANK=1
RAM={0xde00:'wSfxTracks',0xde0f:'wSfxReq',0xde1f:'wMusReq',0xde2f:'wMusPan',0xde3f:'wSfxPan',0xde40:'wMusTracks',
     0xde4f:'wPanMask',0xde5f:'wSndFrame',0xde6f:'wSfxEndFrame',0xde90:'wCurTrack',0xde91:'wCurSet',0xdea0:'wVib',
     0xdec0:'wEnv',0xdf00:'wCallStack',0xdffd:'wSlowMo',0xdffe:'wSlowMoOn',0xdfff:'wSndBusy',
     0xffd1:'hSfxReq',0xffd2:'hSfxPrio',0xffd3:'hMusReq',0xffd4:'hCurMusic',0xffd6:'hPCMPtr',0xffd7:'hPCMPtr+1',
     0xfff5:'hTimerVec',0xfff6:'hTimerVec+1',0xff8a:'hROMBank',0xff8e:'hPCMCount',0xff8f:'hPCMCount+1',0xff90:'hPCMRun',0xff91:'hPCMLast'}
def _derive():
    import sys; sys.path.insert(0,__import__('os').path.join(__import__('os').path.dirname(__import__('os').path.dirname(__import__('os').path.abspath(__file__))),'tools'))
    from sm83 import ROM,trace
    R=ROM(ROMFILE)
    code,_,_=trace(R,1,CODE_ENTRIES[1],noreturn=(0x28,))
    for a,(n,m,val,op) in code.items():
        if n==3 and val is not None and 0xde00<=val<0xe000 and val not in RAM:
            if val<0xde40: RAM[val]='wSfxTracks+$%02X'%(val-0xde00)
            elif val<0xde80: RAM[val]='wMusTracks+$%02X'%(val-0xde40)
            elif 0xdea0<=val<0xdec0: RAM[val]='wVib+$%02X'%(val-0xdea0)
            elif 0xdec0<=val<0xdf00: RAM[val]='wEnv+$%02X'%(val-0xdec0)
CMDT=0x426e
CODE_ENTRIES={1:[0x4000,0x4358,0x4335,0x433c,0x4343,0x434a,0x42fc,0x435d,0x4380,0x43ec,0x432e,0x424a,0x429e,0x43f5,0x4303,0x42a5,0x42dc,0x4290,0x4297,
                 0x447c,0x4496,0x446b,0x449f,0x46c5,0x46e4,0x4703,0x4711,0x4723,0x472d,0x4737,0x473d],
              0:[0x0b9f,0x2350,0x23e7,0x261a]}
_derive()
CODE_NAMES={
 0x4000:'HH_SndUpdateJP',0x4011:'HH_ChanOwner',0x4026:'HH_ChanOwner.music',0x4029:'HH_MusOwner',0x403b:'HH_OwnerNone',
 0x403d:'HH_Ch1Out',0x406d:'HH_Ch1Shadow',0x407e:'HH_Ch1MusicOwns',0x409b:'HH_Ch2Out',0x40c8:'HH_Ch2Shadow',0x40d9:'HH_Ch2MusicOwns',
 0x40f6:'HH_PulseTail',0x4118:'HH_ShadowPeriod',0x4131:'HH_Ch3Out',0x4173:'HH_Ch3Out.music',0x4182:'HH_Ch4Out',0x41b1:'HH_Ch4Shadow',0x41c3:'HH_Ch4MusicOwns',
 0x41d5:'HH_LoadRequest',0x41f6:'HH_LoadRequest.table',0x4201:'HH_LoadRequest.track',
 0x421a:'HH_NextTrack',0x421f:'HH_TrackStep',0x4231:'HH_ReadByte',0x424a:'HH_Cmd89_Hold',0x424c:'HH_StoreNote',0x4262:'HH_SetSpeed',
 0x4290:'HH_Cmd8F_SfxPan',0x4297:'HH_Cmd90_PanMask',0x429e:'HH_Cmd8A_MusPan',0x42a5:'HH_Cmd8D_Env',0x42b8:'HH_Cmd8D_Env.flags',
 0x42dc:'HH_Cmd8E_Vib',0x42f2:'HH_Cmd8E_Vib.flags',0x42fc:'HH_Cmd84_NR50',0x4303:'HH_Cmd8C_Wave',0x4321:'HH_Copy4',
 0x432e:'HH_Cmd88_NRx4',0x4335:'HH_Cmd80_NRx1',0x433c:'HH_Cmd81_NR10',0x4343:'HH_Cmd82_Transpose',0x434a:'HH_Cmd83_NRx2',0x434f:'HH_StoreArg',
 0x4358:'HH_UnusedSkipArg',0x435d:'HH_Cmd85_Call',0x4380:'HH_Cmd86_Return',0x439d:'HH_Cmd86_Return.end',0x43cd:'HH_Cmd86_Return.sfxDone',
 0x43ce:'HH_Cmd86_Return.music',0x43eb:'HH_Cmd86_Return.musDone',0x43ec:'HH_Cmd87_Stop',0x43f5:'HH_Cmd8B_Jump',
 0x43ff:'HH_EnvTick',0x4402:'HH_EnvTick.block',0x440f:'HH_EnvTick.on',0x4438:'HH_EnvTick.advance',0x4440:'HH_EnvTick.countUp',
 0x4441:'HH_EnvTick.next',0x4442:'HH_EnvTick.nextBlock',0x444c:'HH_EnvTick.waiting',
 0x4453:'HH_EnvApply',0x446b:'HH_EnvCh3',0x447c:'HH_EnvCh1',0x4486:'HH_EnvCh1.common',0x4496:'HH_EnvCh2',0x449f:'HH_EnvCh4',
 0x44b6:'HH_VibTick',0x44b9:'HH_VibTick.block',0x44da:'HH_VibTick.advance',0x44e3:'HH_VibTick.store',0x44eb:'HH_VibTick.skip',0x44f5:'HH_VibApply',
 0x461f:'HH_SndUpdate',0x467c:'HH_UpdatePan',0x468e:'HH_UpdatePan.write',0x469b:'HH_TrackCleanup',0x46a3:'HH_TrackCleanupJump',
 0x46c5:'HH_CleanSfx1',0x46d7:'HH_CleanSfx1.env',0x46e4:'HH_CleanSfx2',0x46f6:'HH_CleanSfx2.env',0x4703:'HH_CleanSfx3',0x4711:'HH_CleanSfx4',
 0x4723:'HH_CleanMus1',0x472d:'HH_CleanMus2',0x4737:'HH_CleanMus3',0x473d:'HH_CleanMus4',
 0x4743:'HH_SilenceSfxChans',0x474f:'HH_SilenceSfxChans.ch2',0x4758:'HH_SilenceSfxChans.ch3',0x4761:'HH_SilenceSfxChans.ch4',0x476a:'HH_SilenceSfxChans.done',
 0x476d:'HH_SilenceCh1',0x478c:'HH_SilenceCh2',0x47a8:'HH_SilenceCh3',0x47c0:'HH_SilenceCh4',0x47d2:'HH_SilenceRegs',0x47de:'HH_ResetTrackRegs',0x47e7:'HH_ResetTrackRegs.tail',
 # ROM0
 0x0b9f:'HH_SndVBlank',0x0bc1:'HH_SndVBlank.takeSfx',0x0bc9:'HH_SndVBlank.music',0x0bd1:'HH_SndVBlank.clear',0x0be9:'HH_SndVBlank.curMusic',
 0x0bf8:'HH_SndVBlank.slowLoop',0x0bfd:'HH_SndVBlank.update',
 0x2350:'HH_ScriptPlayPCM',0x2362:'HH_ScriptPlayPCM.decode',0x2382:'HH_ScriptPlayPCM.waitSilence',0x238f:'HH_PCMStart',0x23ae:'HH_PCMStart.wave',
 0x23dd:'HH_PCMStart.wait',0x23e7:'HH_PCMTimerISR',0x2414:'HH_PCMTimerISR.end',
 0x261a:'HH_PCMDecode',0x2627:'HH_PCMDecode.flag',0x262f:'HH_PCMDecode.bits3a',0x2637:'HH_PCMDecode.rl3a',0x2647:'HH_PCMDecode.bits3b',
 0x264f:'HH_PCMDecode.rl3b',0x265f:'HH_PCMDecode.bits4',0x2667:'HH_PCMDecode.rl4',0x2671:'HH_PCMDecode.raw',0x2678:'HH_PCMDecode.bits3c',
 0x2680:'HH_PCMDecode.rl3c',0x2687:'HH_PCMDecode.ret',0x2689:'HH_PCMDecode.newLast',0x268d:'HH_PCMDecode.repeat',
}
DATA_NAMES={0x4003:'HH_Version',0x426e:'HH_CmdTable',0x446c:'HH_EnvApplyTable',0x450f:'HH_WaveTable',0x460f:'HH_VibPerField',0x4617:'HH_VibNRx3',
 0x46b5:'HH_CleanupTable',0x47f2:'HH_PeriodTable',0x489a:'HH_VibTables',0x498a:'HH_VibIndex',0x4994:'HH_EnvTables',0x4a0c:'HH_EnvPresets',
 0x4a1b:'HH_EnvIndex',0x4a2b:'HH_SoundTable',0x0c05:'HH_SfxPriority',0x0000:None}
del DATA_NAMES[0]
STREAM_NAMES={0x4c53:'HH_EmptyEnd',0x4c54:'HH_EmptyStop'}
C={}
def c(a,t,b=1): C[(b,a)]=t
# ROM0 glue
c(0x0b9f,'no sound update while a PCM sample plays',0); c(0x0ba3,'re-entry guard',0); c(0x0bad,'SFX request from the game',0)
c(0x0bb2,'hl = HH_SfxPriority + id (rst $08: hl += a)',0); c(0x0bb6,'an SFX already requested/playing?',0)
c(0x0bbc,'yes: refused if the new value is higher (lower value = more important)',0); c(0x0bc1,'hSfxPrio = priority of the new SFX',0); c(0x0bc6,'pass the id to the driver',0)
c(0x0bc9,'music request: passed on without a test',0); c(0x0bd1,'both requests consumed',0); c(0x0bd6,'bank 1',0)
c(0x0bdd,'hCurMusic = the music id (not 0 or $FF)',0); c(0x0be9,'slow motion: wait 4096 loop iterations before the update',0)
c(0x0bfd,'the driver',0)
c(0x2350,'script opcode $1A: count (negative word), then the bitstream',0); c(0x235d,'c = 1: read a byte on the first bit',0)
c(0x235f,'samples go to WRAM $C300 up',0); c(0x2366,'nibble v -> NR50 byte v*$11',0); c(0x237a,'$FF terminator',0)
c(0x237c,'SFX 1 and music 1: silence everything',0); c(0x2382,'wait until the driver took both and music 1 ended',0)
c(0x238d,'hPCMPtr = $C300',0); c(0x2395,'timer vector = HH_PCMTimerISR',0); c(0x239d,'wSfxReq = wMusReq = 1: once the sample is over the driver loads the silent id 1 in both sets',0)
c(0x23a5,'APU off, wave RAM = $FF, APU on',0); c(0x23b6,'duty 50 %, CH3 on',0); c(0x23bc,'NR50 = 0, no sweep, periods 0',0)
c(0x23c7,'NR51 = $FF, NR12/NR22 = $FF, NR31 = $FF',0); c(0x23d0,'CH3 level 100 %, NR41 = $20, NR42 = $20',0)
c(0x23d8,'enable the timer interrupt (TMA $C2, 4194304/16/62 = 4228 Hz)',0); c(0x23dd,'wait for the end of the sample',0)
c(0x23e2,'NR50 = $77',0); c(0x23e7,'timer interrupt: one sample',0); c(0x23f8,'NR50 = sample',0); c(0x23fa,'NR43 = $D0 (slowest noise clock)',0)
c(0x23fe,'retrigger all four channels (keeps their outputs at a constant level)',0); c(0x2414,'end: APU off and on, timer vector 0, NR50 = $77',0)
c(0x261a,'raw run pending?',0); c(0x2622,'next byte, 8 bits',0); c(0x2627,'flag bit 1: repeat hPCMLast',0)
c(0x263e,'3-bit value different from hPCMLast: output it',0); c(0x2656,'escape + value different: it becomes hPCMLast',0)
c(0x266e,'escape + escape: 4-bit n, a raw run of 12 + n values',0); c(0x2671,'count down the run, output a raw 3-bit value',0)
# bank 1
c(0x4011,'SFX track b on?'); c(0x4018,'not on its row: nobody writes'); c(0x401c,'TRK_NOTE'); c(0x4021,'hold: nobody writes'); c(0x4026,'SFX off: music track')
c(0x403b,'drop the caller'); c(0x4041,'NR10 = TRK_NR10'); c(0x404c,'which set owns CH1?'); c(0x4050,'SFX: its vib/env run, the music ones are suspended')
c(0x4062,'restart the SFX envelope and vibrato'); c(0x406d,'music CH1 envelope on: keep its period/NRx4 copies current even under an SFX')
c(0x407e,'music: its vib/env run, the SFX ones are suspended')
c(0x40f6,'NRx1 = TRK_NRX1'); c(0x40f9,'NRx2 = TRK_NRX2'); c(0x40fc,'(TRK_NOTE + TRK_TRANSP) * 2, 8-bit'); c(0x410c,'TRK_PERLO = period low')
c(0x410e,'NRx3'); c(0x4110,'period high | TRK_NRX4 | trigger'); c(0x4116,'TRK_LASTNRX4 = NRx4 written')
c(0x4134,'CH3 DAC off and on'); c(0x415b,'period high | trigger | length, TRK_NRX4 ignored')
c(0x418b,'NR41 = TRK_NRX1'); c(0x418e,'NR42 = TRK_NRX2'); c(0x4191,'NR43 = TRK_NOTE'); c(0x4196,'NR44 = TRK_NRX4 | trigger')
c(0x41d5,'request id'); c(0x41db,'taken'); c(0x41df,'music set?'); c(0x41e3,'SFX: clear the frame stamps and free the SFX channels')
c(0x41f6,'HH_SoundTable + id * 8 (16-bit)'); c(0x4201,'TRK_SPEED = 1'); c(0x4205,'TRK_TICK = 0'); c(0x4208,'TRK_PTR'); c(0x4210,'TRK_DEPTH = 0')
c(0x421a,'next track'); c(0x4227,'off'); c(0x4228,'TRK_TICK += 1'); c(0x422a,'== TRK_SPEED?'); c(0x422c,'TRK_TICK = 0, read a row')
c(0x4233,'$00-$7F note'); c(0x4237,'$91-$FF speed'); c(0x423b,'$80-$90 command'); c(0x4262,'TRK_SPEED = byte - $91')
c(0x42a5,'wEnv + track / 2'); c(0x42b4,'flags = (arg ? $80 : 0) | 1 (suspended until the next note)'); c(0x42c2,'preset = HH_EnvPresets[arg & 15]')
c(0x42cb,'rate = preset & 15'); c(0x42cc,'wait = step = 0'); c(0x42d4,'table = preset >> 4'); c(0x42d8,'arg & 15 (never read)')
c(0x42dc,'wVib + track / 4'); c(0x42f4,'flags = (arg ? $80 : 0) | 1'); c(0x42f8,'table = arg & 15 (the step is kept)')
c(0x4303,'CH3 DAC off'); c(0x4308,'HH_WaveTable + arg'); c(0x435d,'TRK_DEPTH += 1'); c(0x436a,'wCallStack + track + 2 * old depth')
c(0x4378,'push the return address'); c(0x4380,'TRK_DEPTH'); c(0x438c,'pop'); c(0x439d,'depth 0: this track ends')
c(0x43a4,'SFX track: give the channel back to the music'); c(0x43af,'wSfxEndFrame + track = wSndFrame'); c(0x43bb,'all SFX tracks off?')
c(0x43ca,'wSfxReq = 0'); c(0x43e8,'wMusReq = 0'); c(0x43ec,'TRK_SPEED = 0, no clean-up')
c(0x43ff,'eight envelope blocks of 8 bytes'); c(0x4402,'bit 7: on'); c(0x440f,'b = flags, c = rate'); c(0x4413,'wait counter running?')
c(0x4419,'bit 0: suspended (the other set owns the channel)'); c(0x4424,'HH_EnvIndex[table] = table * 8'); c(0x442d,'+ step')
c(0x4430,'NRx2 value, 0 = none'); c(0x4439,'step 7 is the last (re-applied every update)'); c(0x443e,'step += 1, wait = 1')
c(0x444c,'wait == rate: back to 0 (next update steps)'); c(0x4453,'c = low byte of the step field: block k'); c(0x4467,'a = k * 16 = track')
c(0x447c,'NR10 = TRK_NR10'); c(0x4486,'NRx1 = TRK_NRX1'); c(0x4489,'NRx2 = envelope value'); c(0x448f,'NRx3 = TRK_PERLO'); c(0x4493,'NRx4 = TRK_LASTNRX4 (retrigger)')
c(0x44a6,'NR41'); c(0x44a9,'NR42 = envelope value'); c(0x44ad,'NR43 = TRK_NOTE'); c(0x44b3,'NR44 = TRK_LASTNRX4')
c(0x44b6,'seven vibrato blocks of 4 bytes (the last track has none)'); c(0x44c8,'HH_VibIndex[table] = table * 24'); c(0x44d3,'+ step')
c(0x44d6,'signed delta'); c(0x44db,'step += 1; 24 -> 12 (steps 12-23 loop)'); c(0x44f5,'k = (c - $A1) / 4')
c(0x4504,'TRK_PERLO + delta (no carry into the high bits)'); c(0x450d,'NRx3 (block 3 writes NR33)')
c(0x461f,'wSndFrame += 1'); c(0x4623,'SFX request'); c(0x462c,'music request'); c(0x4635,'wCurSet = 0'); c(0x4645,'wCurSet = 1')
c(0x4676,'software envelopes'); c(0x4679,'vibratos')
c(0x467c,'TRK_SPEED of SFX ch1+ch2+ch3 (add) | ch4 (or)'); c(0x468b,'any SFX on: + wSfxPan'); c(0x4693,'NR51 = (wMusPan & wPanMask) | SFX pan')
c(0x46a3,'jump on the track number'); c(0x46c5,'SFX CH1 ended: its blocks off'); c(0x46ce,'music CH1 vibrato/envelope resumed')
c(0x4723,'music CH1 ended: its blocks off')
c(0x4743,'called when an SFX request is loaded: every channel an SFX still holds'); c(0x476d,'music blocks suspended, SFX blocks off')
c(0x477f,'track fields 7-E'); c(0x4784,'NR10 = 8, NR11 = $3F, NR12 = 8, NR13 = 0, NR14 = $C0')
c(0x47b2,'TRK_NRX1 = $FF, TRK_NRX2 = 0'); c(0x47bc,'CH3 DAC off')
COMMENTS=C
BLOCKS={0:{},1:{},0xe:{}}
def blk(a,lines,b=1): BLOCKS[b][a]=['']+['; '+l if l else ';' for l in lines]
blk(0x0b9f,['HH_SndVBlank: the game\'s sound entry, jumped to at the end of the VBlank handler (ROM0 $00CC).',
 'Passes the game\'s requests (hSfxReq with a priority test, hMusReq) to the driver and runs it in bank 1.'],0)
blk(0x0c05,['HH_SfxPriority: one byte per id (81 bytes; ids $45-$50 are padding).','A new SFX is refused while the current one has a higher priority; $FE/$FF = music-only ids.'],0)
blk(0x2350,['HH_ScriptPlayPCM: opcode $1A of the game\'s script interpreter (table $221F, ROM0 $2344).','de = script pointer. Decodes the bitstream into NR50 bytes at $C300, silences the driver, then plays.'],0)
blk(0x23e7,['HH_PCMTimerISR: reached through the timer vector hTimerVec ($0050).'],0)
blk(0x261a,['HH_PCMDecode: returns the next 3-bit level in a. b = bit buffer, c = bits left, de = stream.',
 '  1          -> hPCMLast','  0 v        -> v (v != hPCMLast)','  0 L v      -> v, hPCMLast = v (L = hPCMLast, v != L)',
 '  0 L L n4 v -> v, then 11 + n raw 3-bit values'],0)
blk(0x4000,['Bank 1 starts with a jump to the update and the driver version string.'])
blk(0x4011,['HH_ChanOwner: b = channel offset, h = $DE. Returns (b = owning track) only when that','track read a new row this update and it is not a hold; else returns from the caller.',
 'HH_MusOwner (a = music track): the same test for the music track alone.'])
blk(0x403d,['Channel output, once per row of the owning track. The ownership also decides which set\'s','envelope/vibrato blocks run (bit 0 of their flags = suspended).'])
blk(0x41d5,['HH_LoadRequest: hl = request byte, bc = first track of the set (c bit 6 = music).'])
blk(0x421a,['HH_NextTrack / HH_TrackStep: tick track wCurTrack, read a row when TRK_TICK reaches TRK_SPEED.'])
blk(0x426e,['HH_CmdTable: commands $80-$90'])
blk(0x4290,['Command handlers. bc = stream pointer after the command byte.'])
blk(0x43ff,['HH_EnvTick: software volume envelopes. Block (8 bytes): flags, rate, wait, step, table, arg.',
 'Every rate + 1 updates the step advances (0-7) and NRx2 = HH_EnvTables[table * 8 + step] is written','with a retrigger (0 = no write). Step 7 stays and is written again every update.'])
blk(0x4453,['HH_EnvApply: b = NRx2 value, c = low byte of the block\'s step field.'])
blk(0x44b6,['HH_VibTick: pitch tables. Block (4 bytes): flags, table, step, unused. Every update','NRx3 = TRK_PERLO + HH_VibTables[table * 24 + step]; steps 0-11 once, then 12-23 loop.'])
blk(0x450f,['HH_WaveTable: 16 CH3 waves, $8C xx copies HH_WaveTable + xx'])
blk(0x460f,['HH_VibPerField / HH_VibNRx3: per vibrato block, the TRK_PERLO field and the NRx3 register'])
blk(0x461f,['HH_SndUpdate: once per VBlank (through HH_SndVBlank).'])
blk(0x467c,['HH_UpdatePan: NR51.'])
blk(0x469b,['HH_TrackCleanup: a track ended with $86 (wCurTrack): reset its blocks, resume the other set\'s.'])
blk(0x4743,['HH_SilenceSfxChans: before a new SFX loads, every channel the old SFX holds is reset.'])
blk(0x47f2,['HH_PeriodTable: 84 periods, C2 ... B8'])
blk(0x489a,['HH_VibTables: 10 tables x 24 signed deltas for the period low byte'])
blk(0x4994,['HH_EnvTables: 15 tables x 8 NRx2 values (0 = no write)'])
blk(0x4a0c,['HH_EnvPresets: $8D x -> preset[x & 15] = table << 4 | rate (the 16th entry is HH_EnvIndex\'s 0)'])
blk(0x4a2b,['HH_SoundTable: 69 ids x 4 stream pointers (CH1, CH2, CH3, CH4).','$01-$11 songs (hMusReq), $12-$44 SFX (hSfxReq), id 0 = everything ends at once.'])
BLOCKS[6]={}
_t=0xde
OPERAND={}
for _a in (0x4011,0x4223,0x4253,0x425c,0x4269,0x42ad,0x42e8,0x4350,0x4363,0x43ab,0x43b5,0x43f0,0x4502,0x447f,0x449b,0x44a4):
    OPERAND[(1,_a)]='HIGH(wSfxTracks)'
for _a in (0x4371,0x4395): OPERAND[(1,_a)]='HIGH(wCallStack)'
OPERAND[(1,0x450b)]='$ff'
OPERAND[(0,0x2395)]='LOW(HH_PCMTimerISR)'; OPERAND[(0,0x2399)]='HIGH(HH_PCMTimerISR)'
CMDS={0x80:('nrx1','b'),0x81:('nr10','b'),0x82:('transpose','b'),0x83:('nrx2','b'),0x84:('nr50','b'),0x85:('sndcall','w'),
 0x86:('sndret',''),0x87:('sndstop',''),0x88:('nrx4','b'),0x8a:('muspan','b'),0x8b:('sndjump','w'),0x8c:('wave','b'),
 0x8d:('envelope','b'),0x8e:('vibrato','b'),0x8f:('sfxpan','b'),0x90:('panmask','b')}
SPEEDBASE=0x91; NPERIODS=84
HEADER=['; Hammerin\' Harry - Ghost Building Company (U) - Irem sound driver "Ver 6.04" (bank 1),',
 '; its ROM0 glue, the PCM player/decoder and the five PCM opcodes (banks $6 and $E).',
 '; Rebuilt byte-exact with RGBDS 0.9.1 (see HammerinHarry_SoundDriver.md). Generated by tools/gen_asm.py hh.','']
EQUS=['; track fields (16 bytes per track)',
 'DEF TRK_SPEED  EQU $0 ; ticks per row (0 = off)','DEF TRK_TICK   EQU $1','DEF TRK_PTR    EQU $2 ; word','DEF TRK_DEPTH  EQU $6 ; call depth',
 'DEF TRK_NR10   EQU $7','DEF TRK_NRX1   EQU $8','DEF TRK_NRX2   EQU $9','DEF TRK_NOTE   EQU $A','DEF TRK_TRANSP EQU $B',
 'DEF TRK_PERLO  EQU $C ; period low byte last written','DEF TRK_NRX4   EQU $D ; ORed into NRx4','DEF TRK_LASTNRX4 EQU $E']
def soundtab(g,w):
    for i,ps in enumerate(w.idtab):
        a=0x4a2b+8*i; g.emit_label(1,a)
        g.emit('%-48s; %04x  id $%02X'%('    dw '+', '.join(g.ref(1,p) for p in ps),a,i))
def waves(g,w):
    for k in range(16): g.emit_db(1,0x450f+16*k,0x451f+16*k)
def vibt(g,w):
    for k in range(10): g.emit_db(1,0x489a+24*k,0x489a+24*k+12); g.emit_db(1,0x489a+24*k+12,0x489a+24*k+24)
def envt(g,w):
    for k in range(15): g.emit_db(1,0x4994+8*k,0x499c+8*k)
PCM=[(0x6,0x4000,0x4779,'HH_PCM_06_4000',['one opcode, then $12 (return); called through script E:4DF8 (from E:766C, 09:69C4, 0D:55AD)']),
 (0xe,0x402e,0x4396,'HH_PCM_0E_402E',['script E:4023: TMA = $D9 (6721 Hz) first when hFFA4 = $0C, else 4228 Hz;','the script sets TMA back to $C2 right after it']),
 (0xe,0x4413,0x468f,'HH_PCM_0E_4413',['three back-to-back opcodes forming one clip, script E:43B3','(it fades NR50 out with $02 $24 xx steps first)']),
 (0xe,0x468f,0x48c6,'HH_PCM_0E_468F',[]),(0xe,0x48c6,0x4df7,'HH_PCM_0E_48C6',[])]
def pcm_one(lo):
    def f(g,w):
        for bank,a,e,name,cm in PCM:
            if a!=lo and not (lo==0x4413 and a in (0x468f,0x48c6)): continue
            g.lab(bank,a,name)
            if cm: g.emit(''); [g.emit('; '+x) for x in cm]
            cnt=0x10000-g.R.w(bank,a+1)
            g.emit_label(bank,a)
            g.emit('    db $1A%s; %04x  script opcode: play PCM'%(' '*26,a))
            g.emit('    dw -%d%s; %04x  %d samples = %.3f s at 4228 Hz'%(cnt,' '*(27-len(str(cnt))),a+1,cnt,cnt/4228.13))
            g.emit_db(bank,a+3,e)
    return f
LAYOUT=[('section','HH sound VBlank glue',0,0x0b9f),('code',0,0x0b9f,0x0c05),('db',0,0x0c05,0x0c56),
 ('section','HH PCM player',0,0x2350),('code',0,0x2350,0x2423),('section','HH PCM decoder',0,0x261a),('code',0,0x261a,0x2690),
 ('section','HH sound driver',1,0x4000),('code',1,0x4000,0x4003),('text',1,0x4003,0x4011),('code',1,0x4011,0x426e),
 ('dw',1,0x426e,0x4290,{'labels':True,'per':4,'cmts':['$80-$83','$84-$87','$88-$8B','$8C-$8F','$90']}),('code',1,0x4290,0x446c),
 ('dw',1,0x446c,0x447c,{'labels':True,'per':4,'cmts':['blocks 0-3 (SFX CH1-CH4)','blocks 4-7 (music CH1-CH4)']}),('code',1,0x447c,0x450f),
 ('custom',1,0x450f,0x460f,waves),('db',1,0x460f,0x4617),('db',1,0x4617,0x461f),('code',1,0x461f,0x46b5),
 ('dw',1,0x46b5,0x46c5,{'labels':True,'per':4,'cmts':['SFX CH1-CH4','music CH1-CH4']}),('code',1,0x46c5,0x47f2),
 ('dw',1,0x47f2,0x489a,{'per':12}),('custom',1,0x489a,0x498a,vibt),('db',1,0x498a,0x4994),('custom',1,0x4994,0x4a0c,envt),
 ('db',1,0x4a0c,0x4a1b),('db',1,0x4a1b,0x4a2b),('custom',1,0x4a2b,0x4c53,soundtab),('streams',1,0x4c53,0x7fbf),('db',1,0x7fbf,0x8000),
 ('section','HH PCM 06:4000',0x6,0x4000),('custom',0x6,0x4000,0x4779,pcm_one(0x4000)),
 ('section','HH PCM 0E:402E',0xe,0x402e),('custom',0xe,0x402e,0x4396,pcm_one(0x402e)),
 ('section','HH PCM 0E:4413',0xe,0x4413),('custom',0xe,0x4413,0x4df7,pcm_one(0x4413))]
ORPHAN_RANGES=[(0x4c53,0x7fbf)]
