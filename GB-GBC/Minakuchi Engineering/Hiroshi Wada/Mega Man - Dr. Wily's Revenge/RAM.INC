def AudioROM equ $4000
def AudioRAM equ $D935
def WaveRAM equ $FF30
def MasterSlotSpeedRAM equ AudioRAM+$44
def Slot1SpeedRAM equ MasterSlotSpeedRAM+$03
def Slot2SpeedRAM equ Slot1SpeedRAM+$03
def Slot3SpeedRAM equ Slot2SpeedRAM+$03
def Slot4SpeedRAM equ Slot3SpeedRAM+$03
def Slot5SpeedRAM equ Slot4SpeedRAM+$03
def Slot6SpeedRAM equ Slot5SpeedRAM+$03
def Slot7SpeedRAM equ Slot6SpeedRAM+$03
def Slot8SpeedRAM equ Slot7SpeedRAM+$03
def SFX1RAM equ AudioRAM+$AC
def SFX2RAM equ SFX1RAM+$59
def SFX3RAM equ SFX2RAM+$59
def SFX4RAM equ SFX3RAM+$59
def Mus1RAM equ SFX4RAM+$59
def Mus2RAM equ Mus1RAM+$59
def Mus3RAM equ Mus2RAM+$59
def Mus4RAM equ Mus3RAM+$59

def CondFlag1 equ $C131
def CondFlag2 equ CondFlag1+$01

def UnkCC4A equ $CC4A

def SFX1	equ 0
def SFX2	equ 1
def SFX3	equ 2
def SFX4	equ 3
def Mus1	equ 4
def Mus2	equ 5
def Mus3	equ 6
def Mus4	equ 7

SECTION "Audio RAM", WRAMX[AudioRAM+$05]
CurSoundSlot: ds 1
CurTempoChan: ds 2
SoundSlots: ds 4
SoundPriorities: ds 4
CurTrackIndex: ds 1
CurTrackRAM: ds 2
ChanSlotVals: ds 8
ChanPlayVals: ds 8
TrackPanVals: ds 8
TrackTrigVals: ds 8
Ch1IDRAM: ds 4
Ch2IDRAM: ds 4
Ch3IDRAM: ds 4
Ch4IDRAM: ds 4
ChanPanVal: ds 1
UnkD979: ds 1

SECTION "MasterSlotSpeedRAM", WRAMX[MasterSlotSpeedRAM]
MasterSlotPlay: ds 1
MasterSlotTempo: ds 1
MasterSlotBeatCounter: ds 1
SECTION "Slot1SpeedRAM", WRAMX[Slot1SpeedRAM]
Slot1Play: ds 1
Slot1Tempo: ds 1
Slot1BeatCounter: ds 1
SECTION "Slot2SpeedRAM", WRAMX[Slot2SpeedRAM]
Slot2Play: ds 1
Slot2Tempo: ds 1
Slot2BeatCounter: ds 1
SECTION "Slot3SpeedRAM", WRAMX[Slot3SpeedRAM]
Slot3Play: ds 1
Slot3Tempo: ds 1
Slot3BeatCounter: ds 1
SECTION "Slot4SpeedRAM", WRAMX[Slot4SpeedRAM]
Slot4Play: ds 1
Slot4Tempo: ds 1
Slot4BeatCounter: ds 1

SECTION "Audio RAM2", WRAMX[AudioRAM+$57]

;$D98C
CurTrackCh: ds 1
UnkRAM1: ds 27
;$D9A8
CurRNG: ds 1
UnkRAM2: ds 52
;$D9DD
UnkD9DD: ds 1

SECTION "SFX1RAM", WRAMX[SFX1RAM]
SFX1Start: ds 2				;$00
SFX1CurPos: ds 2			;$02
SFX1Chan: ds 1				;$04
SFX1Trans: ds 1				;$05
SFX1RNG: ds 1				;$06
SFX1Waveform: ds 1			;$07
SFX1Env: ds 1				;$08
SFX1EnvRest: ds 1			;$09
SFX1Dur: ds 1				;$0A
SFX1DurLeft: ds 1			;$0B
SFX1Delay: ds 1				;$0C
SFX1EnvSeq: ds 1			;$0D
SFX1EnvSeqSpeed: ds 1		;$0E
SFX1EnvSeqSpeed1Left: ds 1	;$0F
SFX1EnvSeqIndex: ds 1		;$10
SFX1EnvSeqPtr: ds 2			;$11
SFX1Unk13: ds 1				;$13
SFX1EnvSweepPace: ds 1		;$14
SFX1VibSeq: ds 1			;$15
SFX1VibSpeed: ds 1			;$16
SFX1VibSpeedLeft: ds 1		;$17
SFX1VibDelay: ds 1			;$18
SFX1VibDelayLeft: ds 1		;$19
SFX1VibSeqPtr: ds 2			;$1A
SFX1AutoLen: ds 1			;$1C
SFX1AutoLenAmt: ds 1		;$1D
SFX1MacroRet: ds 2			;$1E
SFX1Unk20: ds 1				;$20
SFX1Slur: ds 1				;$21
SFX1RepeatBNum: ds 1		;$22
SFX1RepeatAPos: ds 16		;$23
SFX1RepeatANum: ds 8		;$33
SFX1RepeatDPos: ds 16		;$3B
SFX1RepeatDNum: ds 8		;$4B
SFX1NR10: ds 1				;$53
SFX1NR11: ds 1				;$54
SFX1NR12: ds 1				;$55
SFX1NR13: ds 1				;$56
SFX1NR14: ds 1				;$57

SECTION "SFX2RAM", WRAMX[SFX2RAM]
SFX2Start: ds 2				;$00
SFX2CurPos: ds 2			;$02
SFX2Chan: ds 1				;$04
SFX2Trans: ds 1				;$05
SFX2RNG: ds 1				;$06
SFX2Waveform: ds 1			;$07
SFX2Env: ds 1				;$08
SFX2EnvRest: ds 1			;$09
SFX2Dur: ds 1				;$0A
SFX2DurLeft: ds 1			;$0B
SFX2Delay: ds 1				;$0C
SFX2EnvSeq: ds 1			;$0D
SFX2EnvSeqSpeed: ds 1		;$0E
SFX2EnvSeqSpeed1Left: ds 1	;$0F
SFX2EnvSeqIndex: ds 1		;$10
SFX2EnvSeqPtr: ds 2			;$11
SFX2Unk13: ds 1				;$13
SFX2EnvSweepPace: ds 1		;$14
SFX2VibSeq: ds 1			;$15
SFX2VibSpeed: ds 1			;$16
SFX2VibSpeedLeft: ds 1		;$17
SFX2VibDelay: ds 1			;$18
SFX2VibDelayLeft: ds 1		;$19
SFX2VibSeqPtr: ds 2			;$1A
SFX2AutoLen: ds 1			;$1C
SFX2AutoLenAmt: ds 1		;$1D
SFX2MacroRet: ds 2			;$1E
SFX2Unk20: ds 1				;$20
SFX2Slur: ds 1				;$21
SFX2RepeatBNum: ds 1		;$22
SFX2RepeatABPos: ds 16		;$23
SFX2RepeatANum: ds 8		;$33
SFX2RepeatDPos: ds 16		;$3B
SFX2RepeatDNum: ds 8		;$4B
SFX2NR20: ds 1				;$53
SFX2NR21: ds 1				;$54
SFX2NR22: ds 1				;$55
SFX2NR23: ds 1				;$56
SFX2NR24: ds 1				;$57

SECTION "SFX3RAM", WRAMX[SFX3RAM]
SFX3Start: ds 2				;$00
SFX3CurPos: ds 2			;$02
SFX3Chan: ds 1				;$04
SFX3Trans: ds 1				;$05
SFX3RNG: ds 1				;$06
SFX3Waveform: ds 1			;$07
SFX3Env: ds 1				;$08
SFX3EnvRest: ds 1			;$09
SFX3Dur: ds 1				;$0A
SFX3DurLeft: ds 1			;$0B
SFX3Delay: ds 1				;$0C
SFX3EnvSeq: ds 1			;$0D
SFX3EnvSeqSpeed: ds 1		;$0E
SFX3EnvSeqSpeed1Left: ds 1	;$0F
SFX3EnvSeqIndex: ds 1		;$10
SFX3EnvSeqPtr: ds 2			;$11
SFX3Unk13: ds 1				;$13
SFX3EnvSweepPace: ds 1		;$14
SFX3VibSeq: ds 1			;$15
SFX3VibSpeed: ds 1			;$16
SFX3VibSpeedLeft: ds 1		;$17
SFX3VibDelay: ds 1			;$18
SFX3VibDelayLeft: ds 1		;$19
SFX3VibSeqPtr: ds 2			;$1A
SFX3AutoLen: ds 1			;$1C
SFX3AutoLenAmt: ds 1		;$1D
SFX3MacroRet: ds 2			;$1E
SFX3Unk20: ds 1				;$20
SFX3Slur: ds 1				;$21
SFX3RepeatBNum: ds 1		;$22
SFX3RepeatABPos: ds 16		;$23
SFX3RepeatANum: ds 8		;$33
SFX3RepeatDPos: ds 16		;$3B
SFX3RepeatDNum: ds 8		;$4B
SFX3NR30: ds 1				;$53
SFX3NR31: ds 1				;$54
SFX3NR32: ds 1				;$55
SFX3NR33: ds 1				;$56
SFX3NR34: ds 1				;$57

SECTION "SFX4RAM", WRAMX[SFX4RAM]
SFX4Start: ds 2				;$00
SFX4CurPos: ds 2			;$02
SFX4Chan: ds 1				;$04
SFX4Trans: ds 1				;$05
SFX4RNG: ds 1				;$06
SFX4Waveform: ds 1			;$07
SFX4Env: ds 1				;$08
SFX4EnvRest: ds 1			;$09
SFX4Dur: ds 1				;$0A
SFX4DurLeft: ds 1			;$0B
SFX4Delay: ds 1				;$0C
SFX4EnvSeq: ds 1			;$0D
SFX4EnvSeqSpeed: ds 1		;$0E
SFX4EnvSeqSpeed1Left: ds 1	;$0F
SFX4EnvSeqIndex: ds 1		;$10
SFX4EnvSeqPtr: ds 2			;$11
SFX4Unk13: ds 1				;$13
SFX4EnvSweepPace: ds 1		;$14
SFX4VibSeq: ds 1			;$15
SFX4VibSpeed: ds 1			;$16
SFX4VibSpeedLeft: ds 1		;$17
SFX4VibDelay: ds 1			;$18
SFX4VibDelayLeft: ds 1		;$19
SFX4VibSeqPtr: ds 2			;$1A
SFX4AutoLen: ds 1			;$1C
SFX4AutoLenAmt: ds 1		;$1D
SFX4MacroRet: ds 2			;$1E
SFX4Unk20: ds 1				;$20
SFX4Slur: ds 1				;$21
SFX4RepeatBNum: ds 1		;$22
SFX4RepeatABPos: ds 16		;$23
SFX4RepeatANum: ds 8		;$33
SFX4RepeatDPos: ds 16		;$3B
SFX4RepeatDNum: ds 8		;$4B
SFX4NR40: ds 1				;$53
SFX4NR41: ds 1				;$54
SFX4NR42: ds 1				;$55
SFX4NR43: ds 1				;$56
SFX4NR44: ds 1				;$57

SECTION "Mus1RAM", WRAMX[Mus1RAM]
Mus1Start: ds 2				;$00
Mus1CurPos: ds 2			;$02
Mus1Chan: ds 1				;$04
Mus1Trans: ds 1				;$05
Mus1RNG: ds 1				;$06
Mus1Waveform: ds 1			;$07
Mus1Env: ds 1				;$08
Mus1EnvRest: ds 1			;$09
Mus1Dur: ds 1				;$0A
Mus1DurLeft: ds 1			;$0B
Mus1Delay: ds 1				;$0C
Mus1EnvSeq: ds 1			;$0D
Mus1EnvSeqSpeed: ds 1		;$0E
Mus1EnvSeqSpeed1Left: ds 1	;$0F
Mus1EnvSeqIndex: ds 1		;$10
Mus1EnvSeqPtr: ds 2			;$11
Mus1Unk13: ds 1				;$13
Mus1EnvSweepPace: ds 1		;$14
Mus1VibSeq: ds 1			;$15
Mus1VibSpeed: ds 1			;$16
Mus1VibSpeedLeft: ds 1		;$17
Mus1VibDelay: ds 1			;$18
Mus1VibDelayLeft: ds 1		;$19
Mus1VibSeqPtr: ds 2			;$1A
Mus1AutoLen: ds 1			;$1C
Mus1AutoLenAmt: ds 1		;$1D
Mus1MacroRet: ds 2			;$1E
Mus1Unk20: ds 1				;$20
Mus1Slur: ds 1				;$21
Mus1RepeatBNum: ds 1		;$22
Mus1RepeatABPos: ds 16		;$23
Mus1RepeatANum: ds 8		;$33
Mus1RepeatDPos: ds 16		;$3B
Mus1RepeatDNum: ds 8		;$4B
Mus1NR10: ds 1				;$53
Mus1NR11: ds 1				;$54
Mus1NR12: ds 1				;$55
Mus1NR13: ds 1				;$56
Mus1NR14: ds 1				;$57

SECTION "Mus2RAM", WRAMX[Mus2RAM]
Mus2Start: ds 2				;$00
Mus2CurPos: ds 2			;$02
Mus2Chan: ds 1				;$04
Mus2Trans: ds 1				;$05
Mus2RNG: ds 1				;$06
Mus2Waveform: ds 1			;$07
Mus2Env: ds 1				;$08
Mus2EnvRest: ds 1			;$09
Mus2Dur: ds 1				;$0A
Mus2DurLeft: ds 1			;$0B
Mus2Delay: ds 1				;$0C
Mus2EnvSeq: ds 1			;$0D
Mus2EnvSeqSpeed: ds 1		;$0E
Mus2EnvSeqSpeed1Left: ds 1	;$0F
Mus2EnvSeqIndex: ds 1		;$10
Mus2EnvSeqPtr: ds 2			;$11
Mus2Unk13: ds 1				;$13
Mus2EnvSweepPace: ds 1		;$14
Mus2VibSeq: ds 1			;$15
Mus2VibSpeed: ds 1			;$16
Mus2VibSpeedLeft: ds 1		;$17
Mus2VibDelay: ds 1			;$18
Mus2VibDelayLeft: ds 1		;$19
Mus2VibSeqPtr: ds 2			;$1A
Mus2AutoLen: ds 1			;$1C
Mus2AutoLenAmt: ds 1		;$1D
Mus2MacroRet: ds 2			;$1E
Mus2Unk20: ds 1				;$20
Mus2Slur: ds 1				;$21
Mus2RepeatBNum: ds 1		;$22
Mus2RepeatABPos: ds 16		;$23
Mus2RepeatANum: ds 8		;$33
Mus2RepeatDPos: ds 16		;$3B
Mus2RepeatDNum: ds 8		;$4B
Mus2NR20: ds 1				;$53
Mus2NR21: ds 1				;$54
Mus2NR22: ds 1				;$55
Mus2NR23: ds 1				;$56
Mus2NR24: ds 1				;$57

SECTION "Mus3RAM", WRAMX[Mus3RAM]
Mus3Start: ds 2				;$00
Mus3CurPos: ds 2			;$02
Mus3Chan: ds 1				;$04
Mus3Trans: ds 1				;$05
Mus3RNG: ds 1				;$06
Mus3Waveform: ds 1			;$07
Mus3Env: ds 1				;$08
Mus3EnvRest: ds 1			;$09
Mus3Dur: ds 1				;$0A
Mus3DurLeft: ds 1			;$0B
Mus3Delay: ds 1				;$0C
Mus3EnvSeq: ds 1			;$0D
Mus3EnvSeqSpeed: ds 1		;$0E
Mus3EnvSeqSpeed1Left: ds 1	;$0F
Mus3EnvSeqIndex: ds 1		;$10
Mus3EnvSeqPtr: ds 2			;$11
Mus3Unk13: ds 1				;$13
Mus3EnvSweepPace: ds 1		;$14
Mus3VibSeq: ds 1			;$15
Mus3VibSpeed: ds 1			;$16
Mus3VibSpeedLeft: ds 1		;$17
Mus3VibDelay: ds 1			;$18
Mus3VibDelayLeft: ds 1		;$19
Mus3VibSeqPtr: ds 2			;$1A
Mus3AutoLen: ds 1			;$1C
Mus3AutoLenAmt: ds 1		;$1D
Mus3MacroRet: ds 2			;$1E
Mus3Unk20: ds 1				;$20
Mus3Slur: ds 1				;$21
Mus3RepeatBNum: ds 1		;$22
Mus3RepeatABPos: ds 16		;$23
Mus3RepeatANum: ds 8		;$33
Mus3RepeatDPos: ds 16		;$3B
Mus3RepeatDNum: ds 8		;$4B
Mus3NR30: ds 1				;$53
Mus3NR31: ds 1				;$54
Mus3NR32: ds 1				;$55
Mus3NR33: ds 1				;$56
Mus3NR34: ds 1				;$57

SECTION "Mus4RAM", WRAMX[Mus4RAM]
Mus4Start: ds 2				;$00
Mus4CurPos: ds 2			;$02
Mus4Chan: ds 1				;$04
Mus4Trans: ds 1				;$05
Mus4RNG: ds 1				;$06
Mus4F3: ds 1				;$07
Mus4Env: ds 1				;$08
Mus4EnvRest: ds 1			;$09
Mus4Dur: ds 1				;$0A
Mus4DurLeft: ds 1			;$0B
Mus4Delay: ds 1				;$0C
Mus4EnvSeq: ds 1			;$0D
Mus4EnvSeqSpeed: ds 1		;$0E
Mus4EnvSeqSpeed1Left: ds 1	;$0F
Mus4EnvSeqIndex: ds 1		;$10
Mus4EnvSeqPtr: ds 2			;$11
Mus4Unk13: ds 1				;$13
Mus4EnvSweepPace: ds 1		;$14
Mus4VibSeq: ds 1			;$15
Mus4VibSpeed: ds 1			;$16
Mus4VibSpeedLeft: ds 1		;$17
Mus4VibDelay: ds 1			;$18
Mus4VibDelayLeft: ds 1		;$19
Mus4VibSeqPtr: ds 2			;$1A
Mus4AutoLen: ds 1			;$1C
Mus4AutoLenAmt: ds 1		;$1D
Mus4MacroRet: ds 2			;$1E
Mus4Unk20: ds 1				;$20
Mus4Slur: ds 1				;$21
Mus4RepeatBNum: ds 1		;$22
Mus4RepeatABPos: ds 16		;$23
Mus4RepeatANum: ds 8		;$33
Mus4RepeatDPos: ds 16		;$3B
Mus4RepeatDNum: ds 8		;$4B
Mus4NR40: ds 1				;$53
Mus4NR41: ds 1				;$54
Mus4NR42: ds 1				;$55
Mus4NR43: ds 1				;$56
Mus4NR44: ds 1				;$57

SECTION "Audio RAM3", WRAMX[AudioRAM+$374]
CurEnvIndexTrack: ds 1
CurRAMTrack: ds 1
CurRepeatAmt: ds 1
CurEnv: ds 1
UnkRAM3: ds 6
CurPan: ds 1
CurChan: ds 1
PlayFlag: ds 1
CurPriority: ds 1
CurStartPtr: ds 2
CurSlot: ds 1
CurTrack: ds 1
CurParameter: ds 1