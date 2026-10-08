# Star Wars Episode I: Racer sound RAM ($CAF0-$CC40) and the game variables it reads
S=[  # addr, name, size, comment
(0xCAF0,'wDebugLY',1,'LY at the start of the update (written, never read)'),
(0xCAF1,'wUnusedCAF1',1,''),(0xCAF2,'wUnusedCAF2',1,'cleared only'),(0xCAF3,'wUnusedCAF3',1,'cleared only'),
(0xCAF4,'wUnusedCAF4',1,''),(0xCAF5,'wUnusedCAF5',1,'cleared only'),(0xCAF6,'wUnusedCAF6',1,'cleared only'),
(0xCAF7,'wSoundKill',1,'game: stop everything (keeps SFX 7)'),
(0xCAF8,'wSoundKilled',1,''),
(0xCAF9,'wSoundPause',1,'game: pause (music halted, SFX keep running)'),
(0xCAFA,'wPauseLatch',1,''),
(0xCAFB,'wSoundEnable',1,'game option: 0 = sound off (APU powered down)'),
(0xCAFC,'wApuOnLatch',1,''),(0xCAFD,'wApuOffLatch',1,''),
(0xCAFE,'wUnusedCAFE',1,'cleared only'),
(0xCAFF,'wMusicFlags',1,'bits 0-3: channels the music has triggered; bit 4: start request'),
(0xCB00,'wReadPtr',2,'music read pointer (shared by the four channels)'),
(0xCB02,'wMusicPtr',8,'channel stream pointers, ch1-ch4'),
(0xCB0A,'wSong',1,'song number (set by the game before Music_Request)'),
(0xCB0B,'wSongLengthTable',2,''),
(0xCB0D,'wUnusedCB0D',4,'cleared only'),
(0xCB11,'wLength',4,'note length in frames'),
(0xCB15,'wLenCounter',4,''),
(0xCB19,'wVolume',4,'0-15'),
(0xCB1D,'wOctave',4,'semitone base'),
(0xCB21,'wEnvelope',4,'NRx2'),
(0xCB25,'wUnusedCB25',4,'set to 6, never read'),
(0xCB29,'wGate',4,'silent frames at the end of each note'),
(0xCB2D,'wGateCounter',4,''),
(0xCB31,'wLoopStack',64,'F2/F3 loop slots, 16 bytes per channel; F4 counters at +0, +4, +8, +12'),
(0xCB71,'wFadeTimer',1,''),(0xCB72,'wFadeStep',1,''),(0xCB73,'wFadeActive',1,''),(0xCB74,'wFadeSpeed',1,'game: frames per step / 4 - 1'),
(0xCB75,'wPitchEnvValue',1,''),(0xCB76,'wPitchEnvPtr',2,'one table for all channels'),
(0xCB78,'wPitchEnvOn',4,''),(0xCB7C,'wPitchEnvPos',1,''),(0xCB7D,'wPitchEnvDelay',1,''),(0xCB7E,'wPitchEnvUp',1,''),
(0xCB7F,'wDrumPhase',1,'2 = first hit next'),
(0xCB80,'wSfxChannels',1,'bits 0-4: SFX tracks playing (ch1-ch4, rumble); bit 5: engine noise on ch4'),
(0xCB81,'wSfxNewChannels',1,''),
(0xCB82,'wSfxChain',1,'SFX to start when this one ends (1 = none)'),
(0xCB83,'wSfxMaskTemp',1,''),
(0xCB84,'wSfxStarting',1,''),
(0xCB85,'wSfxRepeatCount',1,''),
(0xCB86,'wSfxReadPtr',2,''),
(0xCB88,'wSfxPtr',10,'5 track pointers'),
(0xCB92,'wSfxRequest',1,'game: SFX number for Sfx_Request'),
(0xCB93,'wSfxLengthTable',2,''),
(0xCB95,'wUnusedCB95',5,'cleared only'),
(0xCB9A,'wSfxLength',5,''),(0xCB9F,'wSfxTimer',5,''),(0xCBA4,'wSfxVolume',5,''),(0xCBA9,'wSfxOctave',5,''),(0xCBAE,'wSfxEnvelope',5,''),
(0xCBB3,'wSfxQueue',8,'requests waiting for the next update, 0-terminated'),
(0xCBBB,'wSfxPriority',5,''),(0xCBC0,'wSfxOwner',5,'SFX number playing on each track'),
(0xCBC5,'wNoiseHold',1,'set by SFX $23, cleared by $22'),
(0xCBC6,'wQueue24',1,'set by SFX $0C: start SFX $24 at the next SFX end'),
(0xCBC7,'wSavedNR51',1,''),
(0xCBC8,'wEngineSfx',1,'$1A or $1B, by engine volume'),
(0xCBC9,'wUnusedCBC9',1,'cleared only'),
(0xCBCA,'wSfx10ThisFrame',1,''),
(0xCBCB,'wEngineOn',1,'game: engine sounds on'),
(0xCBCC,'wUnusedCBCC',2,'cleared only'),
(0xCBCE,'wRivalPosB',2,''),(0xCBD0,'wUnusedCBD0',2,'cleared only'),(0xCBD2,'wPlayerPosB',2,''),
(0xCBD4,'wRivalVolume',1,'NR22 value'),(0xCBD5,'wDistA',2,''),(0xCBD7,'wDistB',2,''),
(0xCBD9,'wRivalDoppler',1,'$80 +- position difference / 4: pitch offset for the rival engine'),
(0xCBDA,'wRivalTimer',1,''),(0xCBDB,'wPlayerTimer',1,''),(0xCBDC,'wPlayerPitch',1,''),(0xCBDD,'wRivalPitch',1,''),
(0xCBDE,'wPlayerPitchDecay',1,''),(0xCBDF,'wRivalPitchDecay',1,''),
(0xCBE0,'wNoiseTimer',1,''),(0xCBE1,'wRivalRate',1,''),(0xCBE2,'wPlayerRate',1,''),(0xCBE3,'wNoiseRate',1,''),
(0xCBE4,'wNoiseMax',1,''),(0xCBE5,'wNoiseMin',1,''),(0xCBE6,'wNoiseShift',1,'NR43 low bits'),
(0xCBE7,'wUnusedCBE7',3,'set to 4, never read'),(0xCBEA,'wUnusedCBEA',1,'cleared only'),
(0xCBEB,'wRumblePattern',1,''),(0xCBEC,'wRumbleTimer',1,''),(0xCBED,'wRumbleOn',1,''),
(0xCBEE,'wUnusedCBEE',2,'cleared only'),
(0xCBF0,'wSfxWatch',1,''),(0xCBF1,'wSfxWatch12',1,''),(0xCBF2,'wSfxWatch1F',1,''),
(0xCBF3,'wVoiceRequest',1,'game: play the voice sample'),
(0xCBF4,'wUnusedCBF4',2,''),
(0xCBF6,'wSavedIE',1,''),(0xCBF7,'wSavedIF',1,''),
(0xCBF8,'wSavedNR',8,'NR10 NR11 NR12 NR21 NR22 NR32 NR42 NR43'),
(0xCC00,'wPeriodLo',4,''),(0xCC04,'wPeriodHi',4,''),
(0xCC08,'wUnusedCC08',1,''),(0xCC09,'wNoteEnv',1,''),(0xCC0A,'wSfxPeriodLo',1,''),
(0xCC0B,'wUnusedCC0B',3,''),(0xCC0E,'wTempPeriodHi',1,''),(0xCC0F,'wUnusedCC0F',4,''),(0xCC13,'wSfxNoteEnv',1,''),
(0xCC14,'wUnusedCC14',5,''),
(0xCC19,'wSfxPlaying',40,'per SFX number: nonzero while it plays'),
]
GAME={0xC209:'wRamBankReg',0xD47E:'wRacer0Flags',0xD483:'wRacer0PosA',0xD486:'wRacer0PosB',0xD49D:'wRacer0Speed',
      0xD57E:'wRacer1Flags',0xD583:'wRacer1PosA',0xD586:'wRacer1PosB',0xD59D:'wRacer1Speed',0xD72E:'wGameMode'}
ROM0={0x0696:'Rumble_On',0x06AE:'Rumble_Off',0x233A:'ApproxDistance'}
def build():
    m={}
    for a,n,sz,c in S:
        for i in range(sz): m[a+i]=n if i==0 else f'{n}+{i}'
    for a,n in GAME.items(): m[a]=n; m[a+1]=n+'+1'
    return m
def inc():
    o=['; Star Wars Episode I: Racer sound driver RAM and the game variables it reads','',
       'IF !DEF(SWR_RAM_INC)','DEF SWR_RAM_INC EQU 1','','; home bank routines it calls']
    for a,n in ROM0.items(): o.append(f'DEF {n:<18} EQU ${a:04X}')
    o+=['','; game variables (racer structs at $D400 / $D500)']
    for a,n in sorted(GAME.items()): o.append(f'DEF {n:<18} EQU ${a:04X}')
    o+=['','RSSET $CAF0']
    for a,n,sz,c in S: o.append(f'DEF {n:<18} RB {sz}'+(f' ; {c}' if c else ''))
    o+=['ASSERT _RS == $CC41','','ENDC','']
    return '\n'.join(o)
