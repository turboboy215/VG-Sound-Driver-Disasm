; Star Wars Episode I: Racer sound driver RAM and the game variables it reads

IF !DEF(SWR_RAM_INC)
DEF SWR_RAM_INC EQU 1

; home bank routines it calls
DEF Rumble_On          EQU $0696
DEF Rumble_Off         EQU $06AE
DEF ApproxDistance     EQU $233A

; game variables (racer structs at $D400 / $D500)
DEF wRamBankReg        EQU $C209
DEF wRacer0Flags       EQU $D47E
DEF wRacer0PosA        EQU $D483
DEF wRacer0PosB        EQU $D486
DEF wRacer0Speed       EQU $D49D
DEF wRacer1Flags       EQU $D57E
DEF wRacer1PosA        EQU $D583
DEF wRacer1PosB        EQU $D586
DEF wRacer1Speed       EQU $D59D
DEF wGameMode          EQU $D72E

RSSET $CAF0
DEF wDebugLY           RB 1 ; LY at the start of the update (written, never read)
DEF wUnusedCAF1        RB 1
DEF wUnusedCAF2        RB 1 ; cleared only
DEF wUnusedCAF3        RB 1 ; cleared only
DEF wUnusedCAF4        RB 1
DEF wUnusedCAF5        RB 1 ; cleared only
DEF wUnusedCAF6        RB 1 ; cleared only
DEF wSoundKill         RB 1 ; game: stop everything (keeps SFX 7)
DEF wSoundKilled       RB 1
DEF wSoundPause        RB 1 ; game: pause (music halted, SFX keep running)
DEF wPauseLatch        RB 1
DEF wSoundEnable       RB 1 ; game option: 0 = sound off (APU powered down)
DEF wApuOnLatch        RB 1
DEF wApuOffLatch       RB 1
DEF wUnusedCAFE        RB 1 ; cleared only
DEF wMusicFlags        RB 1 ; bits 0-3: channels the music has triggered; bit 4: start request
DEF wReadPtr           RB 2 ; music read pointer (shared by the four channels)
DEF wMusicPtr          RB 8 ; channel stream pointers, ch1-ch4
DEF wSong              RB 1 ; song number (set by the game before Music_Request)
DEF wSongLengthTable   RB 2
DEF wUnusedCB0D        RB 4 ; cleared only
DEF wLength            RB 4 ; note length in frames
DEF wLenCounter        RB 4
DEF wVolume            RB 4 ; 0-15
DEF wOctave            RB 4 ; semitone base
DEF wEnvelope          RB 4 ; NRx2
DEF wUnusedCB25        RB 4 ; set to 6, never read
DEF wGate              RB 4 ; silent frames at the end of each note
DEF wGateCounter       RB 4
DEF wLoopStack         RB 64 ; F2/F3 loop slots, 16 bytes per channel; F4 counters at +0, +4, +8, +12
DEF wFadeTimer         RB 1
DEF wFadeStep          RB 1
DEF wFadeActive        RB 1
DEF wFadeSpeed         RB 1 ; game: frames per step / 4 - 1
DEF wPitchEnvValue     RB 1
DEF wPitchEnvPtr       RB 2 ; one table for all channels
DEF wPitchEnvOn        RB 4
DEF wPitchEnvPos       RB 1
DEF wPitchEnvDelay     RB 1
DEF wPitchEnvUp        RB 1
DEF wDrumPhase         RB 1 ; 2 = first hit next
DEF wSfxChannels       RB 1 ; bits 0-4: SFX tracks playing (ch1-ch4, rumble); bit 5: engine noise on ch4
DEF wSfxNewChannels    RB 1
DEF wSfxChain          RB 1 ; SFX to start when this one ends (1 = none)
DEF wSfxMaskTemp       RB 1
DEF wSfxStarting       RB 1
DEF wSfxRepeatCount    RB 1
DEF wSfxReadPtr        RB 2
DEF wSfxPtr            RB 10 ; 5 track pointers
DEF wSfxRequest        RB 1 ; game: SFX number for Sfx_Request
DEF wSfxLengthTable    RB 2
DEF wUnusedCB95        RB 5 ; cleared only
DEF wSfxLength         RB 5
DEF wSfxTimer          RB 5
DEF wSfxVolume         RB 5
DEF wSfxOctave         RB 5
DEF wSfxEnvelope       RB 5
DEF wSfxQueue          RB 8 ; requests waiting for the next update, 0-terminated
DEF wSfxPriority       RB 5
DEF wSfxOwner          RB 5 ; SFX number playing on each track
DEF wNoiseHold         RB 1 ; set by SFX $23, cleared by $22
DEF wQueue24           RB 1 ; set by SFX $0C: start SFX $24 at the next SFX end
DEF wSavedNR51         RB 1
DEF wEngineSfx         RB 1 ; $1A or $1B, by engine volume
DEF wUnusedCBC9        RB 1 ; cleared only
DEF wSfx10ThisFrame    RB 1
DEF wEngineOn          RB 1 ; game: engine sounds on
DEF wUnusedCBCC        RB 2 ; cleared only
DEF wRivalPosB         RB 2
DEF wUnusedCBD0        RB 2 ; cleared only
DEF wPlayerPosB        RB 2
DEF wRivalVolume       RB 1 ; NR22 value
DEF wDistA             RB 2
DEF wDistB             RB 2
DEF wRivalDoppler      RB 1 ; $80 +- position difference / 4: pitch offset for the rival engine
DEF wRivalTimer        RB 1
DEF wPlayerTimer       RB 1
DEF wPlayerPitch       RB 1
DEF wRivalPitch        RB 1
DEF wPlayerPitchDecay  RB 1
DEF wRivalPitchDecay   RB 1
DEF wNoiseTimer        RB 1
DEF wRivalRate         RB 1
DEF wPlayerRate        RB 1
DEF wNoiseRate         RB 1
DEF wNoiseMax          RB 1
DEF wNoiseMin          RB 1
DEF wNoiseShift        RB 1 ; NR43 low bits
DEF wUnusedCBE7        RB 3 ; set to 4, never read
DEF wUnusedCBEA        RB 1 ; cleared only
DEF wRumblePattern     RB 1
DEF wRumbleTimer       RB 1
DEF wRumbleOn          RB 1
DEF wUnusedCBEE        RB 2 ; cleared only
DEF wSfxWatch          RB 1
DEF wSfxWatch12        RB 1
DEF wSfxWatch1F        RB 1
DEF wVoiceRequest      RB 1 ; game: play the voice sample
DEF wUnusedCBF4        RB 2
DEF wSavedIE           RB 1
DEF wSavedIF           RB 1
DEF wSavedNR           RB 8 ; NR10 NR11 NR12 NR21 NR22 NR32 NR42 NR43
DEF wPeriodLo          RB 4
DEF wPeriodHi          RB 4
DEF wUnusedCC08        RB 1
DEF wNoteEnv           RB 1
DEF wSfxPeriodLo       RB 1
DEF wUnusedCC0B        RB 3
DEF wTempPeriodHi      RB 1
DEF wUnusedCC0F        RB 4
DEF wSfxNoteEnv        RB 1
DEF wUnusedCC14        RB 5
DEF wSfxPlaying        RB 40 ; per SFX number: nonzero while it plays
ASSERT _RS == $CC41

ENDC
