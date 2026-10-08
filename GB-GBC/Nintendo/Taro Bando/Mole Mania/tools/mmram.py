# Mole Mania sound RAM map ($DC00-$DCFF, save area $DB10-$DBCB)
SCALARS=[
(0xDC00,'wSongRequest',1,'song id from the game (copied from $D244); 0 = none'),
(0xDC01,'wCommandRequest',1,'bit 0 stop, bit 1 pause (save state), bit 2 resume (copied from $D245)'),
(0xDC02,'wSfxStopMask',1,'bits 0-3: stop the SFX on ch1-ch4 (copied from $D246)'),
(0xDC03,'wSfxRequestBits',11,'88 request bits: byte n bit b = SFX n*8+b+1 (set directly by the game)'),
(0xDC0E,'wUnusedDC0E',1,''),
(0xDC0F,'wQuietMode',1,'nonzero: envelopes / ch3 levels are halved (set by the game)'),
(0xDC10,'wCurSong',1,'playing song id, 0 = none'),
(0xDC11,'wStepIndex',1,'position in the step list'),
(0xDC12,'wTempo',1,'length-table index (TEMPO)'),
(0xDC13,'wWave',1,'music wave id (WAVE)'),
(0xDC14,'wFramePtr',2,'current frame pointer, big-endian (hi = 0: lo = loop count)'),
(0xDC16,'wSongPtr',2,'step list pointer, big-endian'),
(0xDC18,'wCh3Level',1,'ch3 output level 0-3 (CH3LVL)'),
(0xDC19,'wSfxCh3Level',1,'ch3 level for SFX (SFX_CH3LVL)'),
(0xDC1A,'wNoiseNR43',1,'music noise NR43'),
(0xDC1B,'wSfxNoiseNR43',1,'SFX noise NR43'),
(0xDC1C,'wUnusedDC1C',2,''),
(0xDC1E,'wSgbSkipCounter',1,'SGB tempo correction: counts 0-42, one music frame skipped per 43'),
(0xDC1F,'wPaused',1,''),
(0xDC20,'wSfxPtr',2,'temp: SFX data pointer, big-endian'),
(0xDC22,'wCommand',1,'command number from wCommandRequest (1 stop, 2 pause, 3 resume)'),
(0xDC23,'wNR51',1,'NR51 shadow'),
(0xDC24,'wStopFlag',1,''),
(0xDC25,'wSfxWave',1,'SFX wave id'),
(0xDC26,'wTemp',2,'scratch'),
]
ARRAYS=[  # 4 bytes each (ch1..ch4)
(0xDC28,'wFreqHi','note period (hi)'),(0xDC2C,'wFreqLo','note period (lo)'),(0xDC30,'wDuty','duty 0-3'),
(0xDC34,'wOutFreqHi','period written to the channel (hi)'),(0xDC38,'wOutFreqLo','period written to the channel (lo)'),
(0xDC3C,'wFreqOffsetHi','extra period offset (never written)'),(0xDC40,'wFreqOffsetLo','extra period offset (never written)'),
(0xDC44,'wDutySeqPos',''),(0xDC48,'wDutySeqLen',''),(0xDC4C,'wDutySeqTimer',''),
(0xDC50,'wNoteFrames','frames since the last trigger (1-255)'),(0xDC54,'wVibDelay',''),(0xDC58,'wVibRate',''),(0xDC5C,'wVibDepth',''),
(0xDC60,'wPortaDelay',''),(0xDC64,'wPortaNote',''),(0xDC68,'wDutySeq',''),(0xDC6C,'wGate','gate fraction x4'),
(0xDC70,'wScoop','SCOOP xy'),(0xDC74,'wGateFrames',''),(0xDC78,'wLenCounter',''),(0xDC7C,'wLength',''),
(0xDC80,'wEnvSeq',''),(0xDC84,'wCh3Decay','used on ch3 only'),(0xDC88,'wPan','0 centre, 1 right, 2 left'),(0xDC8C,'wTranspose',''),
(0xDC90,'wPortaFrames',''),(0xDC94,'wRelFrames',''),(0xDC98,'wRelEnv',''),(0xDC9C,'wPatPos','offset in the pattern'),
(0xDCA0,'wEnv','NRx2 value'),(0xDCA4,'wDutyDirty',''),(0xDCA8,'wTrigger',''),(0xDCAC,'wChActive',''),
(0xDCB0,'wEnvSeqPos',''),(0xDCB4,'wEnvSeqLen',''),(0xDCB8,'wEnvSeqTimer',''),(0xDCBC,'wRelTimer',''),
(0xDCC0,'wTieFlag',''),(0xDCC4,'wVibState','0 off, 1 delay, 2-4 phases'),(0xDCC8,'wVibTimer',''),
(0xDCCC,'wSfxRequest','SFX id waiting to start, per channel'),(0xDCD0,'wSfxId','SFX playing on the channel'),(0xDCD4,'wSfxTimer',''),
(0xDCD8,'wSfxPos',''),(0xDCDC,'wSfxTrigger',''),(0xDCE0,'wSfxFreqHi',''),(0xDCE4,'wSfxFreqLo',''),
(0xDCE8,'wSfxEnv',''),(0xDCEC,'wSfxDuty',''),(0xDCF0,'wSfxSweep','signed period delta per frame'),(0xDCF4,'wSfxPan',''),
(0xDCF8,'wSfxKeepPan','never set'),(0xDCFC,'wSfxLegato',''),
]
EXTRA=[(0xDB10,'wSaveSongVars',9,'pause: copy of $DC10-$DC18'),(0xDB28,'wSaveChannelVars',0xA4,'pause: copy of $DC28-$DCCB')]
GAME={0xC0A0:('wSystemFlags','game: bit 7 = Super Game Boy detected'),0xD23B:('wGameD23B','game variable tested by the driver'),
      0xD243:('wSoundBankSel','game: 0/1/2 = sound bank $07/$0B/$1A'),0xD244:('wGameSongReq',''),0xD245:('wGameCmdReq',''),0xD246:('wGameSfxStop','')}
def build():
    m={}
    for a,n,sz,c in SCALARS:
        for i in range(sz): m[a+i]=n if i==0 else f'{n}+{i}'
    for a,n,c in ARRAYS:
        for i in range(4): m[a+i]=n if i==0 else f'{n}+{i}'
    for a,n,sz,c in EXTRA:
        for i in range(sz): m[a+i]=n if i==0 else f'{n}+{i}'
    for a,(n,c) in GAME.items(): m[a]=n
    return m
def inc():
    o=['; Mole Mania sound driver RAM (WRAM0) and game variables it uses','',
       'IF !DEF(MM_RAM_INC)','DEF MM_RAM_INC EQU 1','','; game variables']
    for a,(n,c) in sorted(GAME.items()): o.append(f'DEF {n:<18} EQU ${a:04X}'+(f' ; {c}' if c else ''))
    o+=['','; driver variables','RSSET $DC00']
    for a,n,sz,c in SCALARS: o.append(f'DEF {n:<18} RB {sz}'+(f' ; {c}' if c else ''))
    o.append('; per-channel arrays, 4 bytes (ch1, ch2, ch3, ch4)')
    for a,n,c in ARRAYS: o.append(f'DEF {n:<18} RB 4'+(f' ; {c}' if c else ''))
    o+=['ASSERT _RS == $DD00','','; pause save area']
    for a,n,sz,c in EXTRA: o.append(f'DEF {n:<18} EQU ${a:04X} ; {sz} bytes, {c}')
    o+=['','ENDC','']
    return '\n'.join(o)
