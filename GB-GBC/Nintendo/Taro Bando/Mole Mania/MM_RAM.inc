; Mole Mania sound driver RAM (WRAM0) and game variables it uses

IF !DEF(MM_RAM_INC)
DEF MM_RAM_INC EQU 1

; game variables
DEF wSystemFlags       EQU $C0A0 ; game: bit 7 = Super Game Boy detected
DEF wGameD23B          EQU $D23B ; game variable tested by the driver
DEF wSoundBankSel      EQU $D243 ; game: 0/1/2 = sound bank $07/$0B/$1A
DEF wGameSongReq       EQU $D244
DEF wGameCmdReq        EQU $D245
DEF wGameSfxStop       EQU $D246

; driver variables
RSSET $DC00
DEF wSongRequest       RB 1 ; song id from the game (copied from $D244); 0 = none
DEF wCommandRequest    RB 1 ; bit 0 stop, bit 1 pause (save state), bit 2 resume (copied from $D245)
DEF wSfxStopMask       RB 1 ; bits 0-3: stop the SFX on ch1-ch4 (copied from $D246)
DEF wSfxRequestBits    RB 11 ; 88 request bits: byte n bit b = SFX n*8+b+1 (set directly by the game)
DEF wUnusedDC0E        RB 1
DEF wQuietMode         RB 1 ; nonzero: envelopes / ch3 levels are halved (set by the game)
DEF wCurSong           RB 1 ; playing song id, 0 = none
DEF wStepIndex         RB 1 ; position in the step list
DEF wTempo             RB 1 ; length-table index (TEMPO)
DEF wWave              RB 1 ; music wave id (WAVE)
DEF wFramePtr          RB 2 ; current frame pointer, big-endian (hi = 0: lo = loop count)
DEF wSongPtr           RB 2 ; step list pointer, big-endian
DEF wCh3Level          RB 1 ; ch3 output level 0-3 (CH3LVL)
DEF wSfxCh3Level       RB 1 ; ch3 level for SFX (SFX_CH3LVL)
DEF wNoiseNR43         RB 1 ; music noise NR43
DEF wSfxNoiseNR43      RB 1 ; SFX noise NR43
DEF wUnusedDC1C        RB 2
DEF wSgbSkipCounter    RB 1 ; SGB tempo correction: counts 0-42, one music frame skipped per 43
DEF wPaused            RB 1
DEF wSfxPtr            RB 2 ; temp: SFX data pointer, big-endian
DEF wCommand           RB 1 ; command number from wCommandRequest (1 stop, 2 pause, 3 resume)
DEF wNR51              RB 1 ; NR51 shadow
DEF wStopFlag          RB 1
DEF wSfxWave           RB 1 ; SFX wave id
DEF wTemp              RB 2 ; scratch
; per-channel arrays, 4 bytes (ch1, ch2, ch3, ch4)
DEF wFreqHi            RB 4 ; note period (hi)
DEF wFreqLo            RB 4 ; note period (lo)
DEF wDuty              RB 4 ; duty 0-3
DEF wOutFreqHi         RB 4 ; period written to the channel (hi)
DEF wOutFreqLo         RB 4 ; period written to the channel (lo)
DEF wFreqOffsetHi      RB 4 ; extra period offset (never written)
DEF wFreqOffsetLo      RB 4 ; extra period offset (never written)
DEF wDutySeqPos        RB 4
DEF wDutySeqLen        RB 4
DEF wDutySeqTimer      RB 4
DEF wNoteFrames        RB 4 ; frames since the last trigger (1-255)
DEF wVibDelay          RB 4
DEF wVibRate           RB 4
DEF wVibDepth          RB 4
DEF wPortaDelay        RB 4
DEF wPortaNote         RB 4
DEF wDutySeq           RB 4
DEF wGate              RB 4 ; gate fraction x4
DEF wScoop             RB 4 ; SCOOP xy
DEF wGateFrames        RB 4
DEF wLenCounter        RB 4
DEF wLength            RB 4
DEF wEnvSeq            RB 4
DEF wCh3Decay          RB 4 ; used on ch3 only
DEF wPan               RB 4 ; 0 centre, 1 right, 2 left
DEF wTranspose         RB 4
DEF wPortaFrames       RB 4
DEF wRelFrames         RB 4
DEF wRelEnv            RB 4
DEF wPatPos            RB 4 ; offset in the pattern
DEF wEnv               RB 4 ; NRx2 value
DEF wDutyDirty         RB 4
DEF wTrigger           RB 4
DEF wChActive          RB 4
DEF wEnvSeqPos         RB 4
DEF wEnvSeqLen         RB 4
DEF wEnvSeqTimer       RB 4
DEF wRelTimer          RB 4
DEF wTieFlag           RB 4
DEF wVibState          RB 4 ; 0 off, 1 delay, 2-4 phases
DEF wVibTimer          RB 4
DEF wSfxRequest        RB 4 ; SFX id waiting to start, per channel
DEF wSfxId             RB 4 ; SFX playing on the channel
DEF wSfxTimer          RB 4
DEF wSfxPos            RB 4
DEF wSfxTrigger        RB 4
DEF wSfxFreqHi         RB 4
DEF wSfxFreqLo         RB 4
DEF wSfxEnv            RB 4
DEF wSfxDuty           RB 4
DEF wSfxSweep          RB 4 ; signed period delta per frame
DEF wSfxPan            RB 4
DEF wSfxKeepPan        RB 4 ; never set
DEF wSfxLegato         RB 4
ASSERT _RS == $DD00

; pause save area
DEF wSaveSongVars      EQU $DB10 ; 9 bytes, pause: copy of $DC10-$DC18
DEF wSaveChannelVars   EQU $DB28 ; 164 bytes, pause: copy of $DC28-$DCCB

ENDC
