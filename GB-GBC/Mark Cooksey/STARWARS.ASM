;Star Wars audio disassembly
;Original audio & code by Mark Cooksey
;Disassembly by Will Trowbridge
include "HARDWARE.INC"

def AudioROM equ $61FF
def AudioRAM equ $DF68
def WaveRAM equ $FF30

SECTION "Audio", ROMX[AudioROM], BANK[$1]

	jp Init


	jp GetSFX


	jp LoadSong


	jp PlaySongSFX


	jp PlaySong


	jp PlaySFXC1


	jp ClearChVol


	jp MusicOn


	jp CheckVolR1


	jp CheckVolR2


	jp ClearAudio

PlaySongSFX:
	call PlaySong
	call PlaySFXC1
	ret


;Check the volume of the right speaker - if it is too low, then mute
CheckVolR1:
	ldh a, [rNR50]
	;If at full volume
	and %00000111
	jr z, CheckVolL1

	;If the volume is set to lowest
	cp %00000001
	jr z, CheckVolL1

	;...Then decrease volume to 0
	sub 1
	;Keep the value of R speaker
	ld b, a


;Now, check the volume of the left speaker
CheckVolL1:
	ldh a, [rNR50]
	;If at full volume
	and %01110000
	jr z, ClearAudio

	cp %00010000
	jr z, ClearAudio

	;...Then decrease volume to 0 (shift to lower 4 bits and back)
	srl a
	srl a
	srl a
	srl a
	dec a
	sla a
	sla a
	sla a
	sla a
	
	;Clear all volume bits
	or b
	or %10001000
	ldh [rNR50], a
	ret


;Clear panning
ClearAudio:
	ld a, 0
	ldh [rNR51], a
	ldh [rNR50], a
	ld [PlayFlag], a
	ret


;Clear each channel's volume
ClearChVol:
	ld a, 0
	ldh [rNR12], a
	ldh [rNR22], a
	ldh [rNR32], a
	ldh [rNR42], a
	ld [PlayFlag], a
	ret


;Turn music on
MusicOn:
	ld a, $FF
	ld [PlayFlag], a
	ret


;Check the volume of the right speaker again - if it is not full, then set to max
CheckVolR2:
	;Set volume and panning
	ld a, $FF
	ldh [rNR51], a
	ldh a, [rNR50]
	;If at full volume
	and %00000111
	cp %00000111
	jr z, CheckVolL2

	add 1
	ld b, a


;Check the volume of the left speaker again
CheckVolL2:
	ldh a, [rNR50]
	;If at full volume
	and %01110000
	srl a
	srl a
	srl a
	srl a
	cp %00000111
	ret z

	;...Then increase volume by 1
	add 1
	sla a
	sla a
	sla a
	sla a
	
	;Set all volume bits
	or b
	or %10001000
	ldh [rNR50], a
	ret


FreqsLo:
	db LOW($009D), LOW($0107), LOW($016B), LOW($01CA), LOW($0223), LOW($0278), LOW($02C7), LOW($0312), LOW($0359), LOW($039C), LOW($03DB), LOW($0417)
	db LOW($044F), LOW($0484), LOW($04B6), LOW($04E5), LOW($0512), LOW($053C), LOW($0564), LOW($0589), LOW($05AD), LOW($05CE), LOW($05EE), LOW($060C)
	db LOW($0628), LOW($0642), LOW($065B), LOW($0673), LOW($0689), LOW($069E), LOW($06B2), LOW($06C5), LOW($06D7), LOW($06E7), LOW($06F7), LOW($0706)
	db LOW($0714), LOW($0721), LOW($072E), LOW($073A), LOW($0745), LOW($074F), LOW($0759), LOW($0763), LOW($076C), LOW($0774), LOW($077C), LOW($0783)
	db LOW($078A), LOW($0791), LOW($0797), LOW($079D), LOW($07A3), LOW($07A8), LOW($07AD), LOW($07B1), LOW($07B6), LOW($07BA), LOW($07BE), LOW($07C2)
	db LOW($07C5), LOW($07C9), LOW($07CC), LOW($07CF), LOW($07D2), LOW($07D4), LOW($07D7), LOW($07D9), LOW($07DB), LOW($07DD), LOW($07DF), LOW($07E1)
	db LOW($07E3), LOW($07E5), LOW($07E6), LOW($07E8), LOW($07E9), LOW($07EA), LOW($07EC), LOW($07ED), LOW($07EE), LOW($07EF), LOW($07F0), LOW($07F1)
	db LOW($07F2), LOW($07F3), LOW($07F3), LOW($07F4), LOW($07F5), LOW($07F5), LOW($07F7), LOW($07F7), LOW($07F8), LOW($07F8), LOW($07FA), LOW($07FA)

FreqsHi:
	db HIGH($009D), HIGH($0107), HIGH($016B), HIGH($01CA), HIGH($0223), HIGH($0278), HIGH($02C7), HIGH($0312), HIGH($0359), HIGH($039C), HIGH($03DB), HIGH($0417)
	db HIGH($044F), HIGH($0484), HIGH($04B6), HIGH($04E5), HIGH($0512), HIGH($053C), HIGH($0564), HIGH($0589), HIGH($05AD), HIGH($05CE), HIGH($05EE), HIGH($060C)
	db HIGH($0628), HIGH($0642), HIGH($065B), HIGH($0673), HIGH($0689), HIGH($069E), HIGH($06B2), HIGH($06C5), HIGH($06D7), HIGH($06E7), HIGH($06F7), HIGH($0706)
	db HIGH($0714), HIGH($0721), HIGH($072E), HIGH($073A), HIGH($0745), HIGH($074F), HIGH($0759), HIGH($0763), HIGH($076C), HIGH($0774), HIGH($077C), HIGH($0783)
	db HIGH($078A), HIGH($0791), HIGH($0797), HIGH($079D), HIGH($07A3), HIGH($07A8), HIGH($07AD), HIGH($07B1), HIGH($07B6), HIGH($07BA), HIGH($07BE), HIGH($07C2)
	db HIGH($07C5), HIGH($07C9), HIGH($07CC), HIGH($07CF), HIGH($07D2), HIGH($07D4), HIGH($07D7), HIGH($07D9), HIGH($07DB), HIGH($07DD), HIGH($07DF), HIGH($07E1)
	db HIGH($07E3), HIGH($07E5), HIGH($07E6), HIGH($07E8), HIGH($07E9), HIGH($07EA), HIGH($07EC), HIGH($07ED), HIGH($07EE), HIGH($07EF), HIGH($07F0), HIGH($07F1)
	db HIGH($07F2), HIGH($07F3), HIGH($07F3), HIGH($07F4), HIGH($07F5), HIGH($07F5), HIGH($07F7), HIGH($07F7), HIGH($07F8), HIGH($07F8), HIGH($07FA), HIGH($07FA)

SongTab:
.Title
	dw TitleA, TitleB, TitleC, TitleD, LenTab4
.Landspeeder
	dw LandspeederA, LandspeederB, LandspeederC, LandspeederD, LenTab3
.Cave
	dw CaveA, CaveB, CaveC, CaveD, LenTab3
.MosEisley
	dw MosEisleyA, MosEisleyB, MosEisleyC, MosEisleyD, LenTab4
.Cantina
	dw CantinaA, CantinaB, CantinaC, CantinaD, LenTab4
.DoNotUse1
	dw DoNotUse1A, DoNotUse1B, DoNotUse1C, DoNotUse1D, LenTab4
.DoNotUse2
	dw DoNotUse2A, DoNotUse2B, DoNotUse2C, DoNotUse2D, LenTab4
.XWing
	dw XWingA, XWingB, XWingC, XWingD, LenTab2
.EndGame
	dw EndGameA, EndGameB, EndGameC, EndGameD, LenTab4

;Load song
LoadSong:
;Get song number from A
	ld l, a
	ld h, $00
	
	;Get song address
	;x10 bytes = Song entry length
	add hl, hl
	ld d, h
	ld e, l
	add hl, hl
	add hl, hl
	add hl, de
	ld de, SongTab
	add hl, de
	
	;Load starting positions and note length pointers into RAM
	ld a, [hl+]
	ld [C1Pos], a
	ld a, [hl+]
	ld [C1Pos+1], a
	ld a, [hl+]
	ld [C2Pos], a
	ld a, [hl+]
	ld [C2Pos+1], a
	ld a, [hl+]
	ld [C3Pos], a
	ld a, [hl+]
	ld [C3Pos+1], a
	ld a, [hl+]
	ld [C4Pos], a
	ld a, [hl+]
	ld [C4Pos+1], a
	ld a, [hl+]
	ld [NoteLens], a
	ld a, [hl+]
	ld [NoteLens+1], a
	;Set default note lengths
	ld a, 1
	ld [C1Len], a
	ld [C2Len], a
	ld a, 2
	ld [C3Len], a
	ld [C4Len], a
	;Enable play flags
	ld a, 3
	ld [C1PlayFlag], a
	ld [C2PlayFlag], a
	ld [C3PlayFlag], a
	ld [C4PlayFlag], a
	ld [PlayFlag], a
	;Set channel 1 sweep
	ld a, %00001000
	ldh [rNR10], a
	;Set panning and master volume
	ld a, %11111111
	ldh [rNR51], a
	ld a, %01110111
	ldh [rNR50], a
	;Turn on channels
	ld a, %10001111
	ldh [rNR52], a
	ld a, %10000000
	;Turn on CH3 DAC
	ldh [rNR30], a
	
	;Clear all channels' volume
	ld a, 0
	ld [C1Env], a
	ld [C2Env], a
	ld [C3Env], a
	ld [C4Env], a
	
	;Disable macro transpose
	ld [C1MacroTrans], a
	ld [C2MacroTrans], a
	ld [C3MacroTrans], a
	ld [C4MacroTrans], a
	
	;Clear macro flag
	ld [C1InMacro], a
	ld [C2InMacro], a
	ld [C3InMacro], a
	ld [C4InMacro], a
	ret


;Note lengths
LenTab1:
	db 2, 3, 4, 6, 8, 12, 16, 24, 32, 48, 64, 96, 128, 192, 254, 9
LenTab2:
	db 3, 4, 6, 9, 12, 18, 24, 36, 48, 72, 96, 144, 192, 8, 16, 32
LenTab3:
	db 5, 7, 10, 15, 20, 30, 40, 60, 80, 120, 160, 240, 13, 14, 25, 6
LenTab4:
	db 4, 6, 8, 12, 16, 24, 32, 48, 64, 96, 128, 192, 5, 6, 10, 11
LenTab5:
	db 6, 9, 12, 18, 24, 36, 48, 72, 96, 144, 192, 255, 33, 8, 16, 32
LenTab6:
	db 7, 10, 15, 20, 30, 45, 60, 90, 120, 180, 240, 8, 10, 10, 10, 13

PlaySong:
StartC1:
	;Check to see if the song is currently playing
	ld a, [PlayFlag]
	and a
	ret z
	;Save current code position for restart
	ld hl, CurRestartPos
	ld de, StartC1
	ld [hl], e
	inc hl
	ld [hl], d
	;Load current channel macro transpose
	ld a, [C1MacroTrans]
	ld [CurTrans], a
	ld hl, C1PlayFlag
	ld de, rNR11
	call GetNextByte
	;Check if the current channel is active
	ld a, [C1PlayFlag]
	and %0000001
	;If not, then skip to channel 2
	jr z, StartC2

	;Get instrument parameter bytes
	;Process the channel envelope from sequence
	ld hl, C1EnvSeqDelay
	ld de, C1EnvSeq
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	ld de, rNR12

	call CheckEnvSeqDelay
	ld de, C1EnvSeq
	ld a, c
	ld [de], a
	ld a, b
	inc de
	ld [de], a
	;Process the channel vibrato from sequence
	ld hl, C1VibSeqDelay
	ld de, C1VibSeq
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	;Get the low of the frequency
	ld de, C1Freq+1
	call CheckVibSeqDelay
	ld de, C1VibSeq
	;Store updated vibrato sequence pos. in RAM
	ld a, c
	ld [de], a
	ld a, b
	inc de
	ld [de], a
	ld hl, C1PlayFlag
	ld de, rNR13
	call SetPerLo


StartC2:
	;Save current code position for restart	
	ld hl, CurRestartPos
	ld de, StartC2
	ld [hl], e
	inc hl
	ld [hl], d
	;Load current channel macro transpose
	ld a, [C2MacroTrans]
	ld [CurTrans], a
	ld hl, C2PlayFlag
	ld de, rNR21
	call GetNextByte
	;Check if the current channel is active
	ld a, [C2PlayFlag]
	and %00000001
	;If not, then skip to channel 3
	jr z, StartC3

	;Get instrument parameter bytes
	;Process the channel envelope from sequence
	ld hl, C2EnvSeqDelay
	ld de, C2EnvSeq
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	ld de, rNR22
	
	call CheckEnvSeqDelay
	ld de, C2EnvSeq
	ld a, c
	ld [de], a
	ld a, b
	inc de
	ld [de], a
	;Process the channel vibrato from sequence
	ld hl, C2VibSeqDelay
	ld de, C2VibSeq
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	;Get the low of the frequency
	ld de, C2Freq+1
	call CheckVibSeqDelay
	ld de, C2VibSeq
	;Store updated vibrato sequence pos. in RAM
	ld a, c
	ld [de], a
	ld a, b
	inc de
	ld [de], a
	ld hl, C2PlayFlag
	ld de, rNR23
	call SetPerLo


StartC3:
	;Save current code position for restart
	ld hl, CurRestartPos
	ld de, StartC3
	ld [hl], e
	inc hl
	ld [hl], d
	;Load current channel macro transpose
	ld a, [C3MacroTrans]
	ld [CurTrans], a
	ld hl, C3PlayFlag
	ld de, rNR31
	call GetNextByte
	;Check if the current channel is active
	ld a, [C3PlayFlag]
	and %00000001
	;If not, then skip to channel 2
	jr z, StartC4

	;Get instrument parameter bytes
	;Process the channel envelope from sequence
	ld hl, C3EnvSeqDelay
	ld de, C3EnvSeq
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	ld de, rNR32
	
	call CheckEnvSeqDelay
	ld de, C3EnvSeq
	ld a, c
	ld [de], a
	ld a, b
	inc de
	ld [de], a
	;Process the channel vibrato from sequence
	ld hl, C3VibSeqDelay
	ld de, C3VibSeq
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	;Get the low of the frequency
	ld de, C3Freq+1
	call CheckVibSeqDelay
	ld de, C3VibSeq
	;Store updated vibrato sequence pos. in RAM
	ld a, c
	ld [de], a
	ld a, b
	inc de
	ld [de], a
	ld hl, C3PlayFlag
	ld de, rNR33
	call SetPerLo


StartC4:
	;Save current code position for restart
	ld hl, CurRestartPos
	ld de, StartC4
	ld [hl], e
	inc hl
	ld [hl], d
	;Load current channel macro transpose
	ld a, [C4MacroTrans]
	ld [CurTrans], a
	ld hl, C4PlayFlag
	ld de, rNR41
	call GetNextByte
	;Check if the current channel is active
	ld a, [C4PlayFlag]
	and %00000001
	;If not, then return
	jr z, .RetC4

	;Get instrument parameter bytes
	;Process the channel envelope from sequence
	ld hl, C4EnvSeqDelay
	ld de, C4EnvSeq
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	ld de, rNR42
	
	call CheckEnvSeqDelay
	ld de, C4EnvSeq
	ld a, c
	ld [de], a
	ld a, b
	inc de
	ld [de], a


.RetC4
;Set period and return
	ld hl, C4PlayFlag
	ld de, rNR43
	call SetPerLo
	ret


CheckEnvSeqDelay:
;Check if envelope sequence is enabled
	ld a, [hl]
	and a
	ret z

	;Otherwise, decrement
	dec [hl]
	;If delay has not yet finished, then return
	ret nz

	;Otherwise, check if reached end of pattern (value FF)
	ld a, [bc]
	cp $FF
	;If not, then keep going
	jr nz, ProcessEnvSeq

	;Otherwise, then disable envelope sequence
	ld a, $00
	ld [hl], a
	ret


ProcessEnvSeq:
	;Write the volume to the register
	ld [de], a
	;Get next byte
	inc bc
	ld a, [bc]
	;Set delay for next envelope value
	ld [hl], a
	;Now go to frequency...
	ld a, l
	sub 6
	ld l, a
	jr nc, .ProcessEnvSeq2

	dec h

.ProcessEnvSeq2
	;and reset the trigger
	ld a, [hl]
	or $80
	ld [hl], a
	;Then store the current duty into RAM
	ld a, l
	add 4
	ld l, a
	jr nc, .ProcessEnvSeq3

	inc h

.ProcessEnvSeq3
	ld a, [de]
	ld [hl], a
	;Go to next byte in sequence
	inc bc
	ret


CheckVibSeqDelay:
	;If value is 0, then return
	ld a, [hl]
	and a
	ret z

	;If delay is more than 1, then return (wait)
	dec [hl]
	ret nz

	;Load delay into RAM
	inc bc
	ld a, [bc]
	ld [hl], a
	dec bc
	;Load current frequency from RAM
	ld a, [de]
	ld l, a
	dec de
	ld a, [de]
	ld h, a
	;Now get vibrato value
	ld a, [bc]
	;Is it a stop command?
	cp $FF
	;Stop the vibrato sequence if so
	ret z

	;Is it negative?
	cp $7F
	;If so, then subtract from frequency
	jr nc, .SubVibFreq

;Otherwise, add to frequency
.AddVibFreq
	add l
	ld l, a
	jr nc, .ProcessVibSeq2

	inc h

.ProcessVibSeq2
	jr .ProcessVibSeq3

.SubVibFreq
	add l
	ld l, a
	jr c, .ProcessVibSeq3

	dec h

.ProcessVibSeq3
	;Load the new frequency into RAM
	ld a, h
	ld [de], a
	inc de
	ld a, l
	ld [de], a
	
	;Go to the next entry and return
	inc bc
	inc bc
	ret


GetNextByte:
	;Check to see if the current channel is 1-3
	ld a, [hl]
	and %00000010
	;Return if it is 4
	ret z

	;Otherwise, then go to channel note length
	inc hl
	dec [hl]
	;Return if still playing note
	ret nz

	;Otherwise, then get next command
	inc hl
	ld c, [hl]
	inc hl
	ld b, [hl]
	ld a, [bc]
	
	;Load the current command value into RAM
	ld [CurCmd], a
	;Mask out the highest bit
	and %01111111
	
	;Is it a note?
	cp $5F
	;If not, then it must be a command
	jp nc, GetVCMD

	;Save current audio register value
	push de
	
	;Get the current transpose
	ld de, CurTrans
	ld a, [de]
	ld d, a
	;And get the current byte
	ld a, [bc]
	;Mask out the highest bit
	and %01111111
	;Add the transpose
	add d


;Get the current frequency
GetFreq:
	;First get the high byte from table
	ld de, FreqsHi
	add e
	ld e, a
	jr nc, .GetFreq2

	inc d

.GetFreq2
	ld a, [de]
	;Load that value into RAM
	inc hl
	ld [hl], a
	;Get current transpose value
	ld de, CurTrans
	ld a, [de]
	ld d, a
	;And get current note again
	ld a, [bc]
	;Mask out the highest bit
	and %01111111
	;Add the transpose
	add d
	;Now get the low byte from table
	ld de, FreqsLo
	add e
	ld e, a
	jr nc, .GetFreq3

	inc d

.GetFreq3
	ld a, [de]
	inc hl
	ld [hl], a


;Now get the note length from the next byte
GetLen:
	inc bc
	ld a, [bc]
	;Mask out the upper 4 bits to get the note length index
	and %00001111
	push hl
	;Get the address of the current note length
	ld hl, NoteLens+1
	ld d, [hl]
	dec hl
	ld e, [hl]
	pop hl
	add e
	ld e, a
	jr nc, .GetLen2

	inc d

.GetLen2
	ld a, [de]
	;Store the current note length value in RAM
	ld de, -4
	add hl, de
	ld [hl], a


;Now get the instrument from the first bit of byte 1 and lower 4 bits of byte 2
GetInst:
	;Get the first note byte again
	ld a, [CurCmd]
	;If bit is set, then add 32 to total (instrument is +16)
	and %10000000
	srl a
	srl a
	ld d, a
	;Now get the second byte again
	ld a, [bc]
	;Mask out the lower 4 bits to get the instrument number
	and %11110000
	;Shift right to calculate the instrument offset (12 x instrument number)
	srl a
	srl a
	srl a
	;Add the extra 32 bytes if present
	add d
	
	;Get the current instrument offset in table
	push hl
	ld hl, InsTab
	add l
	ld l, a
	jr nc, .GetInst2

	inc h

.GetInst2
	;Load the current instrument address into RAM
	ld e, [hl]
	inc hl
	ld d, [hl]
	pop hl
	
	;Update the position and load it into RAM
	inc bc
	inc hl
	ld [hl], c
	inc hl
	ld [hl], b
	ld b, d
	ld c, e
	pop de
	inc hl
	;Instrument byte 1 - Period control
	ld a, [bc]
	or [hl]
	ld [hl], a
	inc hl
	inc hl
	inc hl
	;Instrument byte 2 - Duty
	inc bc
	ld a, [bc]
	ld [hl], a
	;Instrument byte 3 - Initial volume/envelope
	inc bc
	inc de
	inc hl
	ld a, [bc]
	ld [hl], a
	inc hl
	inc hl
	inc bc
	;Instrument byte 4 - Volume/envelope sequence delay
	ld a, [bc]
	ld [hl], a
	inc hl
	inc bc
	;Instrument byte 5-6 = Volume/envelope sequence pointer
	ld a, [bc]
	ld [hl], a
	inc hl
	inc bc
	ld a, [bc]
	ld [hl], a
	inc hl
	inc bc
	;Instrument byte 7 = Vibrato sequence delay
	ld a, [bc]
	ld [hl], a
	inc hl
	inc bc
	;Instrument byte 8-9 = Vibrato sequence pointer
	ld a, [bc]
	ld [hl], a
	inc hl
	inc bc
	ld a, [bc]
	ld [hl], a
	inc bc
	inc hl
	;Instrument byte 10 = Pitch modulation sequence delay (NYI)
	ld a, [bc]
	ld [hl], a
	inc bc
	inc hl
	;Instrument byte 11-12 = Pitch modulation sequence pointer (NYI)
	ld a, [bc]
	ld [hl], a
	inc bc
	inc hl
	ld a, [bc]
	ld [hl], a
	ret


;Set frequency/period (low)
SetPerLo:
	;Check if channel is active
	ld a, [hl]
	and %00000001
	;Return if not active
	ret z

	;Get second byte of frequency (period low)
	ld bc, 5
	add hl, bc
	ld a, e
	;Go to another method if channel 4
	cp LOW(rNR43)
	jp z, SetC4Freq

	;Otherwise, load the period low into register NRx3
	ld a, [hl]
	ld [de], a


SetPerTrigger:
	;Now check the period high
	dec hl
	inc de
	;Save the period address and RAM location
	push de
	push hl
	;If trigger is set, then don't set the duty and envelope
	ld a, [hl]
	and %10000000
	jr z, SetPerHi

	;Set duty from RAM value
	ld bc, 3
	add hl, bc
	dec de
	dec de
	dec de
	ld a, [hl]
	ld [de], a
	;Set envelope from RAM value
	inc hl
	inc de
	ld a, [hl]
	ld [de], a


SetPerHi:
;Set period (high)
	;Load the period low (with trigger) value from RAM
	pop hl
	pop de
	ld a, [hl]
	ld [de], a
	
	;Clear the trigger in RAM
	and %01111111
	ld [hl], a
	ret


SetC4Freq:
	;Load the current noise frequency from RAM variable into Ch4 RAM and NR43
	ld a, [CurNoise]
	ld [de], a
	jr SetPerTrigger


VCMDTable:
	dw EventTie			;$60
	dw EventStop		;$61
	dw EventJump		;$62
	dw EventNoise		;$63
	dw EventMacro		;$64
	dw EventMacroRet	;$65
	dw EventCondFlag	;$66
	dw EventGlobalPan	;$67


GetVCMD:
;Get the current voice command (VCMD)
	sub $60
	add a
	push hl
	;Increment the channel note length/delay
	dec hl
	dec hl
	inc [hl]
	;Get the pointer to the VCMD
	ld hl, VCMDTable+1
	add l
	ld l, a
	jr nc, .GetVCMD2

	inc h

.GetVCMD2
	ld a, [hl]
	dec hl
	ld l, [hl]
	ld h, a
	;Go to VCMD pointer
	jp hl

EventTie:
;Delay the next note by length, increasing note length
;Parameters: -x (- = unused, x = length)
	;Get the note lengths pointer
	ld hl, NoteLens+1
	ld a, [hl]
	dec hl
	ld l, [hl]
	ld h, a
	;Get the note length from the next byte
	inc bc
	ld a, [bc]
	;Mask out the upper 4 bits to get the length index
	and %00001111
	;Add it to get the pointer to the pointer to the length
	add l
	ld l, a
	jr .EventTie2

	inc h

.EventTie2
	;Get the note length from the pointer
	ld a, [hl]
	pop hl
	;Add the length to the current note length
	ld de, -2
	add hl, de
	ld [hl], a
	;Update the pointer
	inc bc
	inc hl
	jp UpdatePtr


EventStop:
	;Stop the channel
	pop hl
	;Set the channel play flag to 0
	ld bc, -3
	add hl, bc
	ld a, 0
	ld [hl], a
	ret


EventJump:
;Jump to the following pointer (used for looping)
;Parameters: xx xx (x = Pointer)
	;Set the channel note length to 1
	pop hl
	ld de, -2
	add hl, de
	ld a, 1
	ld [hl+], a
	;Get the pointer from the next 2 values and load into RAM
	inc bc
	ld a, [bc]
	ld [hl+], a
	inc bc
	ld a, [bc]
	ld [hl], a
	jp GotoRestart


EventNoise:
;Change the noise frequency value (NR43)
;Parameters: xx (X = Value)
	pop hl
	;Get next noise parameter and load it into RAM
	inc bc
	ld a, [bc]
	ld [CurNoise], a
	;Set channel note length to 1
	ld de, -2
	add hl, de
	ld a, 1
	;Update pointer
	ld [hl+], a
	inc bc
	call UpdatePtr
	jp GotoRestart


EventMacro:
;Go to a macro (subroutine) with transpose for specified number of times
;Parameters: xx yy zz (X = Macro number, Y = Transpose, Z = Number of times)
;(Note: 1 level only)
	;Set channel length to 1
	pop hl
	ld de, -2
	add hl, de
	ld a, 1
	ld [hl+], a
	;Then get macro number from parameter byte
	inc bc
	ld a, [bc]
	;Multiply by 2
	sla a
	;Add to macro table
	ld de, SongMacroTab
	add e
	ld e, a
	jr nc, .EventMacro2

	inc d

.EventMacro2
	ld a, [de]
	;Load the macro position in RAM
	ld [hl+], a
	inc de
	ld a, [de]
	ld [hl+], a
	;Now get the macro transpose value and load it into RAM
	ld d, h
	ld e, l
	ld a, $10
	add e
	ld e, a
	jr nc, .EventMacro3

	inc d

.EventMacro3
	inc bc
	ld a, [bc]
	ld [de], a
	inc de
	;Now check the macro flag in RAM
	ld a, [de]
	and a
	;If 0, then get the times in macro
	jr z, .EventMacro4

	;Otherwise, skip
	inc bc
	jr .EventMacro5

.EventMacro4
	ld a, 1
	ld [de], a
	;Now get the number of times in macro and load into RAM (times left)
	dec de
	dec de
	inc bc
	ld a, [bc]
	;Subtract 1 to get actual number
	sub 1
	ld [de], a
	inc de
	inc de

.EventMacro5
	;Now store the address to return from the macro into RAM
	inc bc
	inc de
	ld a, c
	ld [de], a
	inc de
	ld a, b
	ld [de], a
	jr GotoRestart

EventMacroRet:
;Return from the current macro
	inc bc
	;Set channel length flag to 1
	pop hl
	ld de, -2
	add hl, de
	ld a, $01
	ld [hl+], a
	;Now check for macro times left
	ld d, h
	ld e, l
	ld a, $11
	add e
	ld e, a
	jr nc, .EventMacroRet2

	inc d

.EventMacroRet2
	ld a, [de]
	;If 0, then return from the macro
	and a
	jr z, .EventMacroRetEnd

	sub 1
	ld [de], a
	inc de
	inc de
	inc de
	;Update the position in RAM (use macro return and subtract 4 to get start position)
	ld a, [de]
	sub 4
	ld [hl+], a
	inc de
	ld a, [de]
	jr nc, .EventMacroRet3

	sub 1

.EventMacroRet3
	;Jump to the macro start position
	ld [hl], a
	jp GotoRestart


.EventMacroRetEnd
	;Reset macro transpose to 0
	inc de
	ld a, 0
	;And macro flag to 0
	ld [de], a
	inc de
	ld [de], a
	;Set position to return from macro (from RAM)
	inc de
	ld a, [de]
	ld [hl+], a
	inc de
	ld a, [de]
	ld [hl], a
	;Go to start code
	jr GotoRestart


EventCondFlag:
;Set a conditional flag (not used by the driver)
;Parameters: xx (X = Value)
	inc bc
	ld a, [bc]
	ld [LoopFlag], a
	;Set channel note length to 1
	pop hl
	ld de, -2
	add hl, de
	ld a, 1
	ld [hl+], a
	;Update the channel pointer
	inc bc
	call UpdatePtr
	jr GotoRestart


EventGlobalPan:
;Set global panning
;Parameters: xx (X = Value, see NR51 usage)
	inc bc
	ld a, [bc]
	ldh [rNR51], a

;Reset the note by setting the channel length to 1
ResetNote:
	;Set channel note length to 1
	inc bc
	pop hl
	ld de, -2
	add hl, de
	ld a, 1
	ld [hl+], a
	call UpdatePtr
	jr GotoRestart


UpdatePtr:
;Store the updated pointer in RAM
	ld [hl], c
	inc hl
	ld [hl], b
	ret


GotoRestart:
	;Load the current channel's restart pointer
	pop hl
	ld de, CurRestartPos
	ld a, [de]
	ld l, a
	inc de
	ld a, [de]
	ld h, a
	;Now to jump to the code position
	jp hl


InsTab:
	dw Rest
	dw Square1
	dw Square2
	dw Square3
	dw Square4
	dw Square5
	dw Square6
	dw Square7
	dw Square8
	dw Square9
	dw Sweep
	dw Pizz1
	dw Pizz2
	dw Pizz3
	dw Wave1
	dw Wave2
	dw Wave3
	dw Wave4
	dw Square10
	
Rest:
	;Period ctrl
	db $80
	;Duty
	db $00
	;Initial vol/env
	db $02
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
Square1:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $A7
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
Square2:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $77
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
Square3:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $57
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
Square4:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $A4
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
Square5:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $74
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
Square6:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $55
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
Square7:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $A0
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq04
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
Square8:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $70
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq05
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
Square9:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $50
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq06
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
Sweep:
	;Period ctrl
	db $C0
	;Duty
	db $80
	;Initial vol/env
	db $2A
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
Pizz1:
	;Period ctrl
	db $C0
	;Duty
	db $BA
	;Initial vol/env
	db $51
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw VibSeq
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
Pizz2:
	;Period ctrl
	db $C0
	;Duty
	db $BC
	;Initial vol/env
	db $A1
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw VibSeq
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
Pizz3:
	;Period ctrl
	db $C0
	;Duty
	db $B4
	;Initial vol/env
	db $71
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw VibSeq
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
Wave1:
	;Period ctrl
	db $C0
	;Duty
	db $02
	;Initial vol/env
	db $20
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq00
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
Wave2:
	;Period ctrl
	db $C0
	;Duty
	db $02
	;Initial vol/env
	db $20
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq01
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
Wave3:
	;Period ctrl
	db $C0
	;Duty
	db $02
	;Initial vol/env
	db $20
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq02
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
Wave4:
	;Period ctrl
	db $C0
	;Duty
	db $02
	;Initial vol/env
	db $20
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq03
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
Square10:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $34
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
	
VibSeq:
	db 0, 10
	db 2, 3
	db -2, 3
	db -2, 3
	db 2, 3
	db 2, 3
	db -2, 3
	db -2, 3
	db 2, 3
	db 2, 3
	db -2, 3
	db -2, 2
	db 2, 3
	db 2, 3
	db -2, 3
	db -2, 2
	db 2, 3
	db 2, 3
	db -2, 3
	db -2, 2
	db 2, 3
	db 2, 3
	db -2, 3
	db -2, 2
	db 2, 3
	db 2, 3
	db -2, 3
	db -2, 2
	db 2, 3
	db 2, 3
	db -2, 3
	db -2, 2
	db 2, 3
	db 2, 3
	db -2, 3
	db -2, 2
	db 2, 3
	db 2, 3
	db -2, 3
	db -2, 2
	db 2, 3
	db 2, 3
	db -2, 3
	db -2, 2
	db 2, 3
	db 3, 3
	db -3, 3
	db -3, 2
	db 2, 3
	db 3, 3
	db -3, 3
	db -3, 2
	db 2, 3
	db $FF
	
EnvSeq00:
	db $40, 10
	db $60, 20
	db $00, 1
	db $FF
EnvSeq01:
	db $40, 40
	db $60, 80
	db $00, 1
	db $FF
EnvSeq02:
	db $20, 1
	db $40, 12
	db $60, 16
	db $00, 1
	db $FF
EnvSeq03:
	db $20, 1
	db $40, 6
	db $60, 8
	db $00, 1
	db $FF
EnvSeq04:
	db $A0, 2
	db $90, 3
	db $80, 5
	db $70, 10
	db $60, 15
	db $50, 20
	db $40, 25
	db $30, 25
	db $20, 30
	db $10, 30
	db $00, 1
	db $FF
EnvSeq05:
	db $70, 2
	db $60, 8
	db $50, 15
	db $40, 25
	db $30, 30
	db $20, 40
	db $10, 40
	db $00, 1
	db $FF
EnvSeq06:
	db $50, 5
	db $40, 10
	db $30, 40
	db $20, 50
	db $10, 60
	db $00, 1
	db $FF

TitleA:
	db $64, $00, 0, 1
	db $1F, $5F
	db $1F, $5E
	db $1F, $5F
.TitleALoop
	db $64, $04, 0, 1
	db $1F, $54
	db $1F, $54
	db $64, $08, 0, 1
	db $64, $04, 0, 1
	db $1F, $5F
	db $1F, $5E
	db $1F, $5F
	db $64, $04, 0, 1
	db $00, $05
	db $1D, $52
	db $64, $0C, 0, 1
	db $24, $88
	db $2B, $88
	db $29, $5F
	db $28, $5E
	db $26, $5F
	db $30, $89
	db $30, $88
	db $2F, $88
	db $64, $10, -12, 1
	db $1F, $89
	db $1F, $86
	db $2B, $86
	db $2A, $84
	db $28, $84
	db $26, $89
	db $25, $84
	db $26, $84
	db $28, $86
	db $2A, $84
	db $2B, $84
	db $2A, $8A
	db $64, $10, -24, 1
	db $17, $8A
	db $24, $56
	db $24, $56
	db $00, $0F
	db $00, $0E
	db $24, $5F
	db $24, $5F
	db $24, $5E
	db $24, $5F
	db $24, $56
	db $24, $56
	db $24, $56
	db $1F, $5F
	db $1F, $5E
	db $1F, $5F
	db $66, $01
	db $62
	dw .TitleALoop
TitleB:
	db $64, $01, 0, 1
	db $17, $6F
	db $17, $6E
	db $17, $6F
.TitleBLoop
	db $64, $05, 0, 1
	db $1A, $64
	db $1A, $64
	db $64, $09, 0, 1
	db $64, $05, 0, 1
	db $17, $6F
	db $17, $6E
	db $17, $6F
	db $64, $05, 0, 1
	db $00, $05
	db $1A, $62
	db $64, $0D
	db $00, $01
	db $1C, $98
	db $28, $98
	db $26, $6F
	db $24, $6E
	db $23, $6F
	db $28, $99
	db $27, $98
	db $26, $98
	db $64, $11, 0, 4
	db $64, $12, 0, 4
	db $64, $11, 0, 4
	db $64, $12, 0, 4
	db $64, $11, 1, 4
	db $64, $13, 0, 4
	db $64, $14, 0, 4
	db $64, $15, 0, 2
	db $64, $13, 1, 2
	db $64, $16, 0, 4
	db $64, $11, -5, 2
	db $64, $11, 12, 4
	db $64, $12, 12, 4
	db $64, $11, 12, 4
	db $64, $12, 12, 4
	db $64, $11, 13, 4
	db $64, $13, 12, 4
	db $64, $14, 12, 4
	db $64, $15, 12, 2
	db $64, $13, 1, 2
	db $1C, $66
	db $1C, $66
	db $00, $0F
	db $00, $0E
	db $1C, $6F
	db $1C, $6F
	db $1C, $6E
	db $1C, $6F
	db $1C, $66
	db $1C, $66
	db $1C, $66
	db $1A, $6F
	db $1A, $6E
	db $1A, $6F
	db $62
	dw .TitleBLoop
TitleC:
	db $64, $02, 0, 1
	db $07, $E6
.TitleCLoop
	db $64, $06, 0, 1
	db $00, $06
	db $64, $0A, 0, 1
	db $64, $06, 0, 1
	db $07, $E6
	db $64, $06, 0, 1
	db $00, $05
	db $16, $E2
	db $64, $0E, 0, 1
	db $0C, $F8
	db $0C, $E6
	db $0C, $EF
	db $0C, $EE
	db $0C, $EF
	db $0C, $E6
	db $0A, $F9
	db $08, $F8
	db $07, $F8
	db $64, $17, 0, 1
	db $0B, $FA
	db $10, $FA
	db $10, $FA
	db $0B, $FA
	db $64, $17
	db $00, $01
	db $13, $FA
	db $0C, $E6
	db $0C, $E6
	db $00, $0F
	db $00, $0E
	db $0C, $EF
	db $0C, $EF
	db $0C, $EE
	db $0C, $EF
	db $0C, $E6
	db $0C, $E6
	db $0C, $E6
	db $07, $EF
	db $07, $EE
	db $07, $EF
	db $62
	dw .TitleCLoop
TitleD:
	db $67, %11111111
	db $63, $25
	db $64, $03, 0, 1
	db $09, $BF
	db $09, $BE
	db $09, $BF
.TitleDLoop
	db $64, $07, 0, 1
	db $09, $BF
	db $09, $BE
	db $09, $BF
	db $64, $0B, 0, 6
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B4
	db $00, $04
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B4
	db $00, $04
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $BF
	db $09, $BE
	db $09, $BF
	db $64, $07, 0, 1
	db $09, $BF
	db $09, $BE
	db $09, $BF
	db $64, $07, 0, 1
	db $00, $06
	db $64, $0F, 0, 2
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B2
	db $00, $04
	db $09, $BF
	db $09, $BE
	db $09, $BF
	db $09, $B2
	db $00, $0A
	db $64, $0F, 0, 2
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B2
	db $00, $04
	db $09, $BF
	db $09, $BE
	db $09, $BF
	db $09, $B2
	db $00, $0A
	db $09, $B6
	db $09, $BF
	db $09, $BE
	db $09, $BF
	db $09, $B6
	db $09, $BF
	db $09, $BE
	db $09, $BF
	db $09, $B6
	db $09, $B6
	db $09, $B6
	db $09, $BF
	db $09, $BE
	db $09, $BF
	db $09, $B6
	db $09, $BF
	db $09, $BE
	db $09, $BF
	db $09, $B6
	db $09, $BF
	db $09, $BE
	db $09, $BF
	db $64, $18, 0, 20
	db $64, $18, 0, 15
	db $63, $25
	db $1C, $B6
	db $1C, $B6
	db $00, $0F
	db $00, $0E
	db $1C, $BF
	db $1C, $BF
	db $1C, $BE
	db $1C, $BF
	db $1C, $B6
	db $1C, $B6
	db $1C, $B6
	db $1C, $BF
	db $1C, $BE
	db $1C, $BF
	db $62
	dw .TitleDLoop

SongMacro00:
	db $1F, $26
	db $24, $5F
	db $1F, $5E
	db $29, $5F
	db $2B, $5F
	db $29, $5E
	db $24, $5F
	db $24, $5F
	db $1F, $5E
	db $29, $5F
	db $2B, $5F
	db $29, $5E
	db $24, $5F
	db $24, $5F
	db $1F, $5E
	db $29, $5F
	db $2B, $5F
	db $29, $5E
	db $24, $5F
	db $24, $5F
	db $1F, $5E
	db $29, $5F
	db $1F, $5F
	db $1F, $5E
	db $1F, $5F
SongMacro04:
	db $24, $88
	db $2B, $88
	db $29, $5F
	db $28, $5E
	db $26, $5F
	db $30, $88
	db $2B, $86
	db $29, $5F
	db $28, $5E
	db $26, $5F
	db $30, $88
	db $2B, $86
	db $29, $5F
	db $28, $5E
	db $29, $5F
	db $26, $88
	db $65
SongMacro08:
	db $21, $87
	db $21, $84
	db $29, $84
	db $28, $84
	db $26, $84
	db $24, $54
	db $24, $84
	db $26, $82
	db $28, $82
	db $26, $84
	db $21, $84
	db $23, $86
	db $1F, $54
	db $1F, $54
	db $21, $87
	db $21, $84
	db $29, $84
	db $28, $84
	db $26, $84
	db $24, $54
	db $2B, $86
	db $26, $88
	db $1F, $54
	db $1F, $54
	db $21, $87
	db $21, $84
	db $29, $84
	db $28, $84
	db $26, $84
	db $24, $54
	db $24, $84
	db $26, $82
	db $28, $82
	db $26, $84
	db $21, $84
	db $23, $86
	db $2B, $55
	db $2B, $52
	db $30, $84
	db $2E, $84
	db $2C, $85
	db $2B, $82
	db $29, $84
	db $27, $84
	db $26, $84
	db $24, $84
	db $2B, $26
	db $2B, $5F
	db $2B, $5E
	db $2B, $5F
	db $2B, $26
	db $1F, $5F
	db $1F, $5E
	db $1F, $5F
	db $65
SongMacro0C:
	db $1D, $78
	db $1A, $46
	db $00, $05
	db $1D, $42
	db $1D, $78
	db $1A, $46
	db $00, $05
	db $20, $42
	db $20, $78
	db $00, $05
	db $1F, $4F
	db $20, $4E
	db $1F, $4F
	db $1D, $42
	db $1A, $79
	db $00, $05
	db $1D, $42
	db $1D, $78
	db $1A, $46
	db $00, $05
	db $1D, $42
	db $1D, $78
	db $1A, $46
	db $00, $05
	db $20, $42
	db $20, $78
	db $00, $05
	db $1F, $4F
	db $20, $4E
	db $1F, $4F
	db $1D, $42
	db $1A, $78
	db $00, $06
	db $1F, $4F
	db $1F, $4E
	db $1F, $4F
	db $65
SongMacro10:
	db $23, $76
	db $2C, $76
	db $2C, $7A
	db $00, $06
	db $2C, $76
	db $2D, $76
	db $2D, $74
	db $2C, $74
	db $2A, $7A
	db $00, $06
	db $23, $76
	db $23, $76
	db $2C, $76
	db $2C, $7A
	db $00, $06
	db $2F, $76
	db $30, $76
	db $30, $74
	db $2F, $74
	db $2D, $7A
	db $00, $06
	db $24, $76
	db $24, $77
	db $30, $74
	db $30, $7A
	db $00, $06
	db $30, $75
	db $2F, $40
	db $24, $40
	db $33, $76
	db $00, $0F
	db $31, $7E
	db $30, $7F
	db $2E, $7A
	db $00, $06
	db $2E, $76
	db $31, $76
	db $00, $0F
	db $30, $7E
	db $2E, $7F
	db $2C, $79
	db $2B, $74
	db $2C, $74
	db $2E, $76
	db $00, $0F
	db $2C, $7E
	db $2E, $7F
	db $30, $7A
	db $65
SongMacro01:
	db $1A, $36
	db $1F, $98
	db $1F, $98
	db $1F, $99
	db $29, $6F
	db $24, $6E
	db $1F, $6F
SongMacro05:
	db $1C, $98
	db $28, $98
	db $26, $6F
	db $24, $6E
	db $23, $6F
	db $28, $99
	db $26, $6F
	db $24, $6E
	db $23, $6F
	db $28, $99
	db $26, $6F
	db $25, $6E
	db $26, $6F
	db $23, $98
	db $65
SongMacro09:
	db $1D, $98
	db $21, $94
	db $1F, $94
	db $1D, $94
	db $1C, $64
	db $1C, $94
	db $1D, $62
	db $1F, $62
	db $1D, $94
	db $1A, $94
	db $1F, $96
	db $17, $64
	db $17, $64
	db $1D, $98
	db $21, $94
	db $1F, $94
	db $1D, $94
	db $1C, $94
	db $22, $36
	db $23, $98
	db $17, $64
	db $17, $64
	db $1D, $98
	db $21, $94
	db $1F, $94
	db $1D, $94
	db $1C, $64
	db $1C, $94
	db $1D, $62
	db $1F, $62
	db $1D, $94
	db $1A, $94
	db $1F, $96
	db $23, $64
	db $23, $64
	db $27, $94
	db $26, $94
	db $24, $95
	db $22, $92
	db $20, $94
	db $1F, $94
	db $1D, $94
	db $1B, $94
	db $23, $36
	db $23, $3F
	db $23, $3E
	db $23, $3F
	db $23, $36
	db $17, $3F
	db $17, $3E
	db $17, $3F
	db $65
SongMacro0D:
	db $1A, $88
	db $17, $56
	db $00, $05
	db $1A, $52
	db $1A, $88
	db $17, $56
	db $00, $05
	db $18, $52
	db $18, $88
	db $00, $05
	db $17, $5F
	db $18, $5E
	db $17, $5F
	db $15, $52
	db $13, $89
	db $00, $05
	db $1A, $52
	db $1A, $88
	db $17, $56
	db $00, $05
	db $1A, $52
	db $1A, $88
	db $17, $56
	db $00, $05
	db $18, $52
	db $18, $88
	db $00, $05
	db $17, $5F
	db $18, $5E
	db $17, $5F
	db $15, $52
	db $13, $88
	db $00, $06
	db $17, $5F
	db $17, $5E
	db $17, $5F
	db $65
SongMacro11:
	db $10, $64
	db $14, $64
	db $17, $64
	db $14, $64
	db $65
SongMacro12:
	db $10, $64
	db $15, $64
	db $18, $64
	db $15, $64
	db $65
SongMacro13:
	db $0D, $64
	db $12, $64
	db $16, $64
	db $12, $64
	db $65
SongMacro14:
	db $10, $64
	db $14, $64
	db $19, $64
	db $14, $64
	db $65
SongMacro15:
	db $10, $64
	db $13, $64
	db $18, $64
	db $13, $64
	db $65
SongMacro16:
	db $10, $64
	db $13, $64
	db $17, $64
	db $10, $64
	db $65
SongMacro02:
	db $13, $EF
	db $13, $EE
	db $13, $EF
	db $13, $F8
	db $13, $F8
	db $13, $F9
	db $07, $F6
SongMacro06:
	db $0C, $F8
	db $0C, $F6
	db $0C, $FF
	db $0C, $FE
	db $0C, $FF
	db $0C, $E6
	db $0C, $F8
	db $0C, $E6
	db $0C, $E6
	db $0C, $F8
	db $0C, $E6
	db $16, $EF
	db $15, $EE
	db $16, $EF
	db $13, $F8
	db $65
SongMacro0A:
	db $11, $F6
	db $11, $F6
	db $11, $F6
	db $11, $F6
 	db $13, $F6
 	db $13, $F6
 	db $13, $F6
 	db $13, $F6
 	db $11, $F6
 	db $11, $F6
 	db $11, $F6
 	db $11, $F6
 	db $0F, $F6
 	db $13, $F9
 	db $11, $F6
 	db $11, $F6
 	db $11, $F6
 	db $11, $F6
 	db $13, $F6
 	db $13, $F6
 	db $13, $F6
 	db $13, $F6
 	db $14, $E4
 	db $13, $E4
 	db $11, $E5
 	db $0F, $E2
 	db $0E, $E4
 	db $0C, $E4
 	db $0A, $E4
 	db $08, $E4
 	db $13, $E6
 	db $13, $EF
 	db $13, $EE
 	db $13, $EF
 	db $13, $E6
 	db $07, $EF
 	db $07, $EE
 	db $07, $EF
	db $65
SongMacro0E:
	db $16, $F8
	db $13, $E6
	db $00, $05
	db $16, $E2
	db $16, $F8
	db $13, $E6
	db $00, $05
	db $14, $E2
	db $14, $F8
	db $00, $05
	db $13, $EF
	db $14, $EE
	db $13, $EF
	db $11, $E2
	db $0E, $F8
	db $00, $06
	db $00, $05
	db $07, $E2
	db $16, $F8
	db $13, $E6
	db $00, $05
	db $16, $E2
	db $16, $F8
	db $13, $E6
	db $00, $05
	db $14, $E2
	db $14, $F8
	db $00, $05
	db $13, $EF
	db $14, $EE
	db $13, $EF
	db $11, $E2
	db $0E, $F8
	db $00, $06
	db $07, $E6
	db $65
SongMacro17:
	db $10, $FA
	db $10, $F9
	db $0B, $F6
	db $10, $FA
	db $10, $F9
	db $0B, $F6
	db $10, $FA
	db $10, $F9
	db $0B, $F6
	db $11, $FA
	db $11, $FA
	db $11, $FA
	db $11, $FA
	db $12, $FA
	db $12, $FA
	db $0C, $FA
	db $0C, $FA
	db $0C, $FA
	db $65
SongMacro03:
	db $09, $B2
	db $09, $B2
	db $09, $B2
	db $09, $B2
	db $09, $B6
	db $00, $08
	db $00, $04
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B6
	db $00, $08
	db $09, $BF
	db $09, $BE
	db $09, $BF
SongMacro07:
	db $09, $B6
	db $09, $BF
	db $09, $BE
	db $09, $BF
	db $09, $B6
	db $09, $BF
	db $09, $BE
	db $09, $BF
	db $09, $B6
	db $09, $B6
	db $09, $B6
	db $09, $BF
	db $09, $BE
	db $09, $BF
	db $09, $B6
	db $09, $B6
	db $09, $BF
	db $09, $BE
	db $09, $BF
	db $09, $B6
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B6
	db $09, $B6
	db $65
SongMacro0B:
	db $09, $B4
	db $09, $B2
	db $09, $B2
	db $09, $B4
	db $09, $B2
	db $09, $B2
	db $09, $B4
	db $09, $B2
	db $09, $B2
	db $09, $B2
	db $09, $B2
	db $09, $B2
	db $09, $B2
	db $65
SongMacro0F:
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B0
	db $09, $B8
	db $65
SongMacro18:
	db $63, $21
	db $09, $B4
	db $09, $B4
	db $09, $C4
	db $09, $B4
	db $09, $B4
	db $09, $B4
	db $09, $C4
	db $09, $B4
	db $65
	
LandspeederA:
	db $67, %11111111
	db $64, $19, 0, 2
	db $64, $1D, 0, 1
	db $66, 1
	db $62
	dw LandspeederA
	db $61
LandspeederB:
	db $64, $1A, 0, 2
	db $64, $1E, 0, 1
	db $62
	dw LandspeederB
	db $61
LandspeederC:
	db $64, $1B, 0, 4
	db $64, $1F, 0, 1
	db $64, $1F, 2, 1
	db $64, $1F, 0, 1
	db $13, $E2
	db $13, $E2
	db $13, $E2
	db $13, $E2
	db $13, $E2
	db $13, $E2
	db $14, $E2
	db $14, $E2
	db $14, $E2
	db $14, $E2
	db $14, $E2
	db $14, $E2
	db $62
	dw LandspeederC
	db $61
LandspeederD:
	db $63, $21
	db $64, $1C, 0, 12
	db $62
	dw LandspeederD
	db $61
SongMacro19:
	db $00, $05
	db $21, $55
	db $1F, $54
	db $21, $56
	db $24, $55
	db $21, $54
	db $20, $57
	db $00, $02
	db $00, $05
	db $21, $55
	db $1F, $54
	db $21, $56
	db $1A, $52
	db $21, $52
	db $26, $52
	db $29, $54
	db $28, $27
	db $00, $02
	db $65
SongMacro1D:
	db $00, $06
	db $18, $52
	db $1D, $52
	db $20, $54
	db $1F, $54
	db $00, $04
	db $00, $06
	db $1A, $52
	db $1F, $52
	db $22, $54
	db $21, $54
	db $00, $04
	db $00, $06
	db $18, $52
	db $1D, $52
	db $20, $54
	db $1F, $54
	db $00, $04
	db $1A, $52
	db $1F, $52
	db $22, $54
	db $21, $52
	db $1F, $52
	db $1B, $52
	db $1D, $52
	db $20, $54
	db $22, $52
	db $23, $52
	db $65
SongMacro1A:
	db $00, $05
	db $18, $65
	db $17, $64
	db $18, $66
	db $21, $65
	db $1D, $64
	db $1C, $67
	db $00, $02
	db $00, $05
	db $18, $65
	db $17, $64
	db $18, $66
	db $15, $62
	db $1D, $62
	db $21, $62
	db $26, $64
	db $23, $37
	db $00, $02
	db $65
SongMacro1E:
	db $00, $06
 	db $14, $62
 	db $18, $62
 	db $18, $64
 	db $18, $64
 	db $00, $04
 	db $00, $06
 	db $16, $62
 	db $1A, $62
 	db $1A, $64
 	db $1A, $64
 	db $00, $04
 	db $00, $06
 	db $14, $62
 	db $18, $62
 	db $18, $64
 	db $18, $64
 	db $00, $04
 	db $16, $62
 	db $1A, $62
 	db $1F, $64
 	db $1A, $64
 	db $17, $62
 	db $19, $62
 	db $1D, $64
 	db $1F, $62
 	db $20, $62
	db $65
SongMacro1B:
	db $15, $E4
	db $15, $E2
	db $15, $E2
	db $13, $E2
	db $12, $E2
	db $11, $E4
	db $11, $E2
	db $11, $E2
	db $10, $E2
	db $0F, $E2
	db $0E, $E4
	db $0E, $E2
	db $0E, $E2
	db $0E, $E2
	db $0F, $E2
	db $10, $E4
	db $10, $E2
	db $10, $E2
	db $12, $E2
	db $14, $E2
	db $65
SongMacro1F:
	db $11, $E2
	db $11, $E2
	db $11, $E2
	db $11, $E2
	db $11, $E2
	db $11, $E2
	db $11, $E2
	db $11, $E2
	db $11, $E2
	db $11, $E4
	db $11, $E2
	db $65
SongMacro1C:	
	db $09, $B2
	db $09, $B2
	db $09, $B2
	db $09, $C2
	db $09, $B2
	db $09, $B2
	db $09, $B2
	db $09, $B2
	db $09, $B2
	db $09, $C2
	db $09, $B2
	db $09, $B2
	db $65
SongMacro20:
	db $00, $0A
	db $65
	
CaveA:
	db $67, %11111111
	db $64, $21, 0, 1
	db $66, 1
	db $62
	dw CaveA
	db $61
CaveB:
	db $64, $22, 0, 1
	db $62
	dw CaveB
	db $61
CaveC:
	db $64, $23, 0, 1
	db $62
	dw CaveC
	db $61
CaveD:
	db $63, $21
	db $64, $24, 0, 1
	db $62
	dw CaveD
	db $61
SongMacro21:
	db $00, $0A
	db $00, $0A
	db $00, $0A
	db $00, $0A
	db $00, $0A
	db $00, $0A
	db $00, $0A
	db $00, $0A
	db $2F, $55
	db $28, $55
	db $2D, $55
	db $26, $55
	db $2B, $55
	db $22, $55
	db $00, $09
	db $00, $04
	db $00, $0A
	db $00, $0A
	db $00, $0A
	db $00, $0A
	db $00, $0A
	db $00, $0A
	db $65
SongMacro22:
	db $00, $0A
	db $00, $0A
	db $00, $0A
	db $00, $0A
	db $00, $0A
	db $00, $0A
	db $00, $0A
	db $00, $0A
	db $00, $02
	db $2F, $65
	db $28, $65
	db $2D, $65
	db $26, $65
	db $2B, $65
	db $22, $64
	db $00, $09
	db $00, $04
	db $00, $07
	db $3B, $C0
	db $39, $C0
	db $37, $C0
	db $34, $C0
	db $00, $04
	db $34, $C0
	db $32, $C0
	db $30, $C0
	db $2E, $C0
	db $00, $06
	db $00, $0A
	db $00, $0A
	db $00, $0A
	db $00, $0A
	db $00, $0A
	db $65
SongMacro23:
	db $10, $E4
	db $00, $04
	db $00, $08
	db $00, $04
	db $10, $E2
	db $10, $E2
	db $10, $E4
	db $00, $07
	db $16, $E4
	db $15, $E4
	db $00, $06
	db $10, $E4
	db $00, $09
	db $10, $E2
	db $10, $E2
	db $10, $E4
	db $00, $05
	db $00, $06
	db $10, $E2
	db $13, $E2
	db $15, $E2
	db $16, $E2
	db $17, $E2
	db $15, $E2
	db $0E, $E2
	db $10, $E4
	db $00, $09
	db $10, $E2
	db $10, $E2
	db $10, $E4
	db $00, $07
	db $16, $E2
	db $13, $E2
	db $15, $E2
	db $13, $E2
	db $00, $06
	db $10, $E4
	db $00, $04
	db $00, $08
	db $00, $04
	db $10, $E2
	db $10, $E2
	db $10, $E4
	db $00, $05
	db $00, $06
	db $10, $E2
	db $13, $E2
	db $15, $E2
	db $16, $E2
	db $17, $E2
	db $15, $E2
	db $0E, $E2
	db $65
SongMacro24:
	db $09, $B4
	db $09, $B2
	db $09, $B2
	db $09, $B4
	db $09, $B2
	db $09, $B2
	db $09, $B4
	db $09, $B2
	db $09, $B2
	db $09, $D4
	db $09, $B2
	db $09, $B2
	db $09, $B4
	db $09, $B2
	db $09, $B2
	db $09, $B4
	db $09, $B2
	db $09, $B2
	db $09, $B4
	db $09, $B2
	db $09, $B2
	db $09, $D4
	db $09, $B2
	db $09, $B2
	db $09, $B4
	db $09, $B2
	db $09, $B2
	db $09, $B4
	db $09, $B2
	db $09, $B2
	db $09, $B4
	db $09, $B2
	db $09, $B2
	db $09, $B4
	db $09, $D2
	db $09, $D2
	db $09, $D4
	db $09, $B2
	db $09, $B2
	db $09, $B4
	db $09, $B2
	db $09, $B2
	db $09, $B4
	db $09, $B2
	db $09, $B2
	db $09, $B4
	db $09, $B2
	db $09, $B2
	db $09, $B4
	db $09, $B2
	db $09, $B2
	db $09, $B4
	db $09, $B2
	db $09, $B2
	db $09, $B4
	db $09, $B2
	db $09, $B2
	db $09, $D4
	db $09, $B2
	db $09, $B2
	db $09, $B4
	db $09, $B2
	db $09, $B2
	db $09, $B4
	db $09, $B2
	db $09, $B2
	db $09, $B4
	db $09, $B2
	db $09, $B2
	db $09, $D4
	db $09, $B2
	db $09, $B2
	db $09, $B4
	db $09, $B2
	db $09, $B2
	db $09, $B4
	db $09, $B2
	db $09, $B2
	db $09, $B4
	db $09, $D2
	db $09, $D2
	db $09, $D4
	db $09, $B2
	db $09, $B2
	db $09, $B4
	db $09, $B2
	db $09, $B2
	db $09, $B4
	db $09, $B2
	db $09, $B2
	db $09, $B4
	db $09, $B2
	db $09, $B2
	db $09, $B4
	db $09, $B2
	db $09, $B2
	db $65
	
MosEisleyA:
	db $67, %11111111
	db $64, $25, 0, 1
	db $66, 1
	db $62
	dw MosEisleyA
MosEisleyB:
	db $64, $26, 0, 1
	db $62
	dw MosEisleyB
MosEisleyC:
	db $64, $27, 0, 4
	db $64, $27, 5, 2
	db $64, $27, 0, 2
	db $64, $29, 0, 2
	db $64, $27, 0, 2
	db $64, $29, 0, 2
	db $64, $27, 0, 2
	db $62
	dw MosEisleyC
MosEisleyD:
	db $63, $21
	db $64, $28, 0, 1
	db $62
	dw MosEisleyD
SongMacro25:
	db $26, $8A
	db $00, $02
	db $26, $52
	db $24, $52
	db $26, $52
	db $24, $52
	db $21, $52
	db $1F, $52
	db $21, $52
	db $1F, $52
	db $1D, $52
	db $1F, $52
	db $1A, $52
	db $1C, $52
	db $1D, $52
	db $1C, $52
	db $18, $52
	db $1A, $88
	db $00, $08
	db $00, $0A
	db $2B, $87
	db $29, $52
	db $26, $52
	db $29, $87
	db $00, $02
	db $26, $52
	db $2B, $52
	db $2D, $52
	db $2B, $52
	db $29, $52
	db $2B, $52
	db $2D, $52
	db $2E, $52
	db $2D, $52
	db $2E, $52
	db $32, $52
	db $30, $52
	db $2E, $52
	db $2D, $52
	db $2E, $52
	db $2D, $52
	db $29, $52
	db $26, $88
	db $00, $08
	db $00, $0A
	db $22, $54
	db $26, $56
	db $26, $52
	db $29, $52
	db $28, $54
	db $24, $56
	db $26, $52
	db $28, $52
	db $29, $54
	db $22, $56
	db $24, $52
	db $26, $52
	db $28, $54
	db $24, $54
	db $28, $52
	db $29, $52
	db $28, $52
	db $24, $52
	db $26, $88
	db $00, $08
	db $00, $0A
	db $22, $54
	db $26, $56
	db $26, $52
	db $29, $52
	db $28, $54
	db $24, $56
	db $26, $52
	db $28, $52
	db $29, $54
	db $22, $56
	db $24, $52
	db $26, $52
	db $28, $54
	db $24, $54
	db $28, $52
	db $29, $52
	db $2B, $52
	db $30, $52
	db $32, $88
	db $00, $08
	db $00, $0A
	db $65
SongMacro26:
	db $00, $0A
	db $00, $0A
	db $2D, $D4
	db $32, $D4
	db $2D, $D4
	db $32, $D4
	db $2D, $D4
	db $32, $D2
	db $2D, $D4
	db $32, $D2
	db $2D, $D4
	db $2D, $D2
	db $2C, $D2
	db $2D, $D2
	db $2B, $D4
	db $2A, $D2
	db $2B, $D2
	db $2A, $D2
	db $29, $D5
	db $26, $D6
	db $00, $02
	db $65
SongMacro27:
	db $0E, $E4
	db $0E, $E2
	db $0E, $E2
	db $0E, $E4
	db $0E, $E2
	db $0E, $E2
	db $0E, $E4
	db $0E, $E2
	db $0E, $E2
	db $0C, $E2
	db $09, $E2
	db $0C, $E2
	db $0D, $E2
	db $65
SongMacro29:
	db $0A, $E4
	db $0A, $E2
	db $0A, $E2
	db $0A, $E4
	db $0A, $E2
	db $0A, $E2
	db $0C, $E4
	db $0C, $E2
	db $0C, $E2
	db $0C, $E4
	db $0C, $E2
	db $0C, $E2
	db $65
SongMacro28:
	db $09, $B2
	db $09, $B2
	db $09, $B2
	db $09, $B2
	db $09, $C2
	db $09, $B2
	db $09, $B2
	db $09, $B2
	db $09, $B2
	db $09, $B2
	db $09, $B2
	db $09, $B2
	db $09, $C2
	db $09, $B2
	db $09, $B2
	db $09, $B2
	db $65

CantinaA:
	db $67, %11111111
	db $64, $2A, -12, 1
	db $66, 1
	db $62
	dw CantinaA
CantinaB:
	db $64, $2B, -12, 1
	db $62
	dw CantinaB
CantinaC:
	db $64, $2C, 0, 1
	db $62
	dw CantinaC
CantinaD:
	db $63, $21
	db $64, $2D, 0, 3
	db $62
	dw CantinaD
SongMacro2A:
	db $2D, $54
	db $32, $54
	db $2D, $54
	db $32, $54
	db $2D, $54
	db $32, $52
	db $2D, $54
	db $32, $52
	db $2D, $54
	db $2D, $52
	db $2C, $52
	db $2D, $52
	db $2B, $54
	db $2A, $52
	db $2B, $52
	db $2A, $52
	db $29, $55
	db $26, $56
	db $00, $02
	db $2D, $54
	db $32, $54
	db $2D, $54
	db $32, $54
	db $2D, $54
	db $32, $52
	db $2D, $54
	db $32, $52
	db $2D, $54
	db $2B, $54
	db $2B, $52
	db $2B, $54
	db $29, $52
	db $2B, $54
	db $30, $54
	db $2E, $52
	db $2D, $55
	db $2B, $54
	db $2D, $54
	db $32, $54
	db $2D, $54
	db $32, $54
	db $2D, $54
	db $32, $52
	db $2D, $54
	db $32, $52
	db $2D, $54
	db $30, $54
	db $30, $52
	db $30, $54
	db $2E, $52
	db $2D, $52
	db $2B, $52
	db $29, $55
	db $26, $56
	db $00, $02
	db $26, $54
	db $27, $52
	db $28, $52
	db $29, $54
	db $2A, $52
	db $2B, $52
	db $2D, $54
	db $2E, $52
	db $2F, $52
	db $30, $56
	db $33, $54
	db $32, $54
	db $2C, $52
	db $2D, $55
	db $29, $58
	db $00, $02
	db $39, $64
	db $35, $62
	db $39, $64
	db $00, $04
	db $00, $02
	db $39, $64
	db $35, $62
	db $39, $64
	db $00, $04
	db $00, $02
	db $39, $64
	db $35, $62
	db $38, $64
	db $39, $64
	db $35, $65
	db $32, $65
	db $00, $04
	db $00, $02
	db $39, $64
	db $35, $62
	db $39, $64
	db $00, $04
	db $00, $02
	db $39, $64
	db $35, $62
	db $39, $64
	db $00, $04
	db $00, $02
	db $39, $64
	db $35, $62
	db $38, $64
	db $39, $64
	db $37, $65
	db $30, $65
	db $00, $04
	db $00, $02
	db $39, $64
	db $35, $62
	db $39, $64
	db $00, $04
	db $00, $02
	db $39, $64
	db $35, $62
	db $39, $64
	db $00, $04
	db $00, $02
	db $39, $64
	db $35, $62
	db $38, $64
	db $39, $64
	db $35, $65
	db $32, $65
	db $00, $04
	db $2E, $62
	db $32, $62
	db $35, $64
	db $2F, $62
	db $32, $62
	db $35, $64
	db $38, $64
	db $39, $62
	db $36, $66
	db $00, $02
	db $32, $62
	db $37, $62
	db $3A, $62
	db $3E, $62
	db $38, $62
	db $39, $65
	db $35, $98
	db $65
SongMacro2B:
	db $29, $64
	db $2D, $64
	db $29, $64
	db $2D, $64
	db $29, $64
	db $2D, $62
	db $29, $64
	db $2D, $62
	db $29, $64
	db $29, $62
	db $28, $62
	db $29, $62
	db $28, $64
	db $26, $62
	db $28, $62
	db $26, $62
	db $26, $65
	db $21, $66
	db $00, $02
	db $29, $64
	db $2D, $64
	db $29, $64
	db $2D, $64
	db $29, $64
	db $2D, $62
	db $29, $64
	db $2D, $62
	db $29, $64
	db $28, $64
	db $28, $62
	db $28, $64
	db $26, $62
	db $28, $64
	db $2B, $64
	db $2B, $62
	db $28, $65
	db $28, $64
	db $29, $64
	db $2D, $64
	db $29, $64
	db $2D, $64
	db $29, $64
	db $2D, $62
	db $29, $64
	db $2D, $62
	db $29, $64
	db $2B, $64
	db $2B, $62
	db $2B, $64
	db $2B, $62
	db $29, $62
	db $28, $62
	db $26, $65
	db $21, $66
	db $00, $02
	db $22, $64
	db $23, $62
	db $24, $62
	db $26, $64
	db $27, $62
	db $28, $62
	db $29, $64
	db $2A, $62
	db $2B, $62
	db $2D, $66
	db $2B, $64
	db $2B, $64
	db $24, $62
	db $24, $65
	db $21, $68
	db $00, $02
	db $35, $64
	db $32, $62
	db $35, $64
	db $00, $04
	db $00, $02
	db $35, $64
	db $32, $62
	db $35, $64
	db $00, $04
	db $00, $02
	db $35, $64
	db $32, $62
	db $34, $64
	db $35, $64
	db $32, $65
	db $2D, $65
	db $00, $04
	db $00, $02
	db $35, $64
	db $32, $62
	db $35, $64
	db $00, $04
	db $00, $02
	db $35, $64
	db $32, $62
	db $35, $64
	db $00, $04
	db $00, $02
	db $35, $64
	db $32, $62
	db $34, $64
	db $35, $64
	db $34, $65
	db $2B, $65
	db $00, $04
	db $00, $02
	db $35, $64
	db $32, $62
	db $35, $64
	db $00, $04
	db $00, $02
	db $35, $64
	db $32, $62
	db $35, $64
	db $00, $04
	db $00, $02
	db $35, $64
	db $32, $62
	db $34, $64
	db $35, $64
	db $32, $65
	db $2D, $65
	db $00, $04
	db $29, $96
	db $26, $96
	db $24, $96
	db $21, $96
	db $2E, $62
	db $32, $62
	db $37, $62
	db $3A, $62
	db $35, $62
	db $35, $65
	db $2D, $98
	db $65
SongMacro2C:
	db $0E, $E6
	db $09, $E6
	db $0E, $E6
	db $09, $E6
	db $0E, $E6
	db $0C, $E6
	db $0E, $E6
	db $09, $E6
	db $0E, $E6
	db $09, $E6
	db $0E, $E6
	db $09, $E6
	db $0C, $E6
	db $07, $E6
	db $0C, $E6
	db $07, $E6
	db $0E, $E6
	db $09, $E6
	db $0E, $E6
	db $09, $E6
	db $0C, $E6
	db $07, $E6
	db $0E, $E6
	db $09, $E6
	db $16, $E6
	db $13, $E6
	db $11, $E6
	db $1A, $E6
	db $13, $E6
	db $18, $E6
	db $11, $E6
	db $00, $06
	db $1A, $E6
	db $15, $E6
	db $1A, $E6
	db $15, $E6
	db $1A, $E6
	db $15, $E6
	db $1A, $E6
	db $15, $E6
	db $1A, $E6
	db $15, $E6
	db $1A, $E6
	db $15, $E6
	db $1A, $E6
	db $15, $E6
	db $1A, $E6
	db $15, $E6
	db $1A, $E6
	db $15, $E6
	db $1A, $E6
	db $15, $E6
	db $1A, $E6
	db $15, $E6
	db $1A, $E6
	db $15, $E6
	db $16, $E6
	db $13, $E6
	db $11, $E6
	db $1A, $E6
	db $13, $E6
	db $18, $E6
	db $11, $E6
	db $00, $06
	db $65
SongMacro2D:
	db $09, $B4
	db $09, $B2
	db $09, $B2
	db $09, $C4
	db $09, $B2
	db $09, $B2
	db $09, $B4
	db $09, $B2
	db $09, $B2
	db $09, $C4
	db $09, $B2
	db $09, $B2
	db $65
	
DoNotUse1A:
DoNotUse1B:
DoNotUse1C:
DoNotUse1D:
SongMacro2E:
	db $2C, $86
	db $2C, $87
	db $2A, $84
	db $2C, $84
	db $2F, $84
	
DoNotUse2A:
DoNotUse2B:
DoNotUse2C:
DoNotUse2D:

SongMacro2F:
SongMacro30:
SongMacro31:
SongMacro32:
SongMacro33:
SongMacro34:
SongMacro35:
SongMacro36:
SongMacro37:
SongMacro38:
SongMacro39:
SongMacro3A:
SongMacro3B:
SongMacro3C:
SongMacro3D:
SongMacro3E:
SongMacro3F:

XWingA:
	db $67, %11111111
	db $64, $40, 0, 2
	db $64, $44, 0, 2
	db $66, 1
	db $62
	dw XWingA
XWingB:
	db $64, $41, 0, 8
	db $00, $0A
	db $00, $0A
	db $64, $45, 0, 1
	db $00, $0A
	db $00, $0A
	db $64, $45, 1, 1
	db $00, $0A
	db $00, $0A
	db $64, $45, 0, 1
	db $00, $0A
	db $00, $0A
	db $64, $45, 1, 1
	db $62
	dw XWingB
XWingC:
	db $64, $42, 0, 8
	db $64, $46, 0, 3
	db $64, $46, 2, 3
	db $64, $46, 0, 3
	db $64, $46, 2, 3
	db $62
	dw XWingC
XWingD:
	db $63, $21
	db $64, $43, $00, $02
	db $64, $47, $00, $0C
	db $62
	dw XWingA
SongMacro40:
	db $22, $86
	db $22, $87
	db $22, $87
	db $22, $88
	db $26, $54
	db $29, $87
	db $2C, $54
	db $29, $54
	db $25, $86
	db $22, $86
	db $20, $54
	db $22, $54
	db $2E, $54
	db $29, $54
	db $25, $86
	db $22, $86
	db $20, $54
	db $22, $54
	db $65
SongMacro44:
	db $28, $56
	db $25, $55
	db $28, $52
	db $28, $56
	db $25, $56
	db $2B, $56
	db $2A, $54
	db $2B, $52
	db $2A, $52
	db $28, $54
	db $25, $57
	db $00, $0A
	db $2A, $56
	db $27, $55
	db $2A, $52
	db $2A, $56
	db $27, $56
	db $2D, $56
	db $2C, $54
	db $2D, $52
	db $2C, $52
	db $2A, $54
	db $27, $57
	db $00, $0A
	db $65
SongMacro41:
	db $00, $0A
	db $65
SongMacro45:
	db $31, $C2
	db $32, $C2
	db $33, $C2
	db $34, $C2
	db $35, $C2
	db $36, $C2
	db $37, $C2
	db $38, $C2
	db $39, $C2
	db $38, $C2
	db $37, $C2
	db $36, $C2
	db $35, $C2
	db $34, $C2
	db $33, $C2
	db $32, $C2
	db $65
SongMacro42:
	db $8A, $14
	db $8A, $14
	db $8A, $14
	db $8A, $14
	db $8A, $14
	db $8A, $14
	db $8A, $14
	db $8A, $14
	db $65
SongMacro46:
	db $97, $12
	db $00, $05
	db $97, $12
	db $00, $05
	db $00, $05
	db $97, $12
	db $97, $12
	db $97, $12
	db $97, $12
	db $97, $12
	db $65
SongMacro43:
	db $09, $B4
	db $09, $B4
	db $09, $B4
	db $09, $B4
	db $09, $B4
	db $09, $B4
	db $09, $B4
	db $09, $B4
	db $09, $B4
	db $09, $B4
	db $09, $B4
	db $09, $B4
	db $09, $B4
	db $09, $B4
	db $09, $B4
	db $09, $B2
	db $09, $B2
	db $09, $B4
	db $09, $B4
	db $09, $B4
	db $09, $B4
	db $09, $B4
	db $09, $B4
	db $09, $B4
	db $09, $B4
	db $09, $B4
	db $09, $B4
	db $09, $B4
	db $09, $B4
	db $09, $B4
	db $09, $B4
	db $09, $B4
	db $09, $B4
	db $65
SongMacro47:
	db $09, $B6
	db $09, $B6
	db $00, $05
	db $09, $B2
	db $09, $B2
	db $09, $B2
	db $09, $B2
	db $09, $B2
	db $65

EndGameA:
	db $67, %11111111
	db $64, $48, 0, 1
	db $00, $02
	db $66, 1
	db $61
EndGameB:
	db $64, $49, 0, 1
	db $00, $02
	db $61
EndGameC:
	db $64, $4A, 0, 1
	db $00, $02
	db $61
EndGameD:
	db $61
SongMacro48:
	db $24, $86
	db $29, $88
	db $2B, $87
	db $2C, $82
	db $2E, $82
	db $2C, $89
	db $24, $86
	db $29, $87
	db $2B, $84
	db $2C, $87
	db $29, $82
	db $30, $82
	db $2E, $89
	db $24, $86
	db $29, $87
	db $2B, $84
	db $2C, $87
	db $29, $82
	db $2C, $82
	db $35, $89
	db $00, $04
	db $33, $82
	db $31, $82
	db $30, $87
	db $2C, $82
	db $29, $82
	db $24, $86
	db $24, $86
	db $29, $89
	db $24, $86
	db $29, $88
	db $2B, $87
	db $2C, $82
	db $2E, $82
	db $2C, $89
	db $24, $86
	db $29, $87
	db $2B, $84
	db $2C, $87
	db $29, $82
	db $30, $82
	db $2E, $89
	db $24, $86
	db $29, $87
	db $2B, $84
	db $2C, $87
	db $29, $82
	db $2C, $82
	db $35, $89
	db $00, $04
	db $33, $82
	db $31, $82
	db $30, $87
	db $2C, $82
	db $29, $82
	db $24, $86
	db $24, $86
	db $29, $88
	db $2D, $88
	db $30, $88
	db $35, $88
	db $29, $88
	db $65
SongMacro49:
	db $00, $06
	db $20, $98
	db $24, $98
	db $29, $99
	db $20, $96
	db $20, $97
	db $22, $94
	db $24, $97
	db $20, $92
	db $2C, $92
	db $26, $99
	db $20, $96
	db $20, $97
	db $22, $94
	db $24, $97
	db $24, $92
	db $29, $92
	db $2C, $99
	db $00, $04
	db $30, $92
	db $2C, $92
	db $2C, $97
	db $29, $92
	db $24, $92
	db $1F, $96
	db $1F, $96
	db $24, $99
	db $20, $96
	db $20, $98
	db $24, $98
	db $29, $99
	db $20, $96
	db $20, $97
	db $22, $94
	db $24, $97
	db $20, $92
	db $2C, $92
	db $26, $99
	db $20, $96
	db $20, $97
	db $22, $94
	db $24, $97
	db $24, $92
	db $29, $92
	db $20, $99
	db $00, $04
	db $30, $92
	db $20, $92
	db $2C, $97
	db $29, $92
	db $24, $92
	db $1F, $96
	db $1F, $96
	db $24, $98
	db $29, $98
	db $2D, $98
	db $30, $98
	db $21, $98
	db $65
SongMacro4A:
	db $0C, $E6
	db $11, $E6
	db $11, $E6
	db $11, $E6
	db $11, $EF
	db $11, $EE
	db $11, $EF
	db $11, $E6
	db $11, $E6
	db $11, $E6
	db $0C, $EF
	db $0C, $EE
	db $0C, $EF
	db $11, $E6
	db $11, $E6
	db $11, $E6
	db $11, $EF
	db $11, $EE
	db $11, $EF
	db $16, $E6
	db $16, $EF
	db $16, $EE
	db $16, $EF
	db $16, $E6
	db $16, $E6
	db $11, $E6
	db $11, $E6
	db $11, $E6
	db $11, $EF
	db $11, $EE
	db $11, $EF
	db $0D, $E6
	db $0D, $E6
	db $0D, $E6
	db $0D, $E6
	db $11, $E6
	db $11, $E6
	db $0C, $E6
	db $0C, $EF
	db $0C, $EE
	db $0C, $EF
	db $11, $E6
	db $11, $E6
	db $11, $E6
	db $11, $E6
	db $11, $E6
	db $11, $E6
	db $11, $E6
	db $11, $EF
	db $11, $EE
	db $11, $EF
	db $11, $E6
	db $11, $E6
	db $11, $E6
	db $0C, $E6
	db $11, $E6
	db $11, $E6
	db $11, $E6
	db $11, $EF
	db $11, $EE
	db $11, $EF
	db $16, $E6
	db $16, $E6
	db $16, $E6
	db $16, $EF
	db $16, $EE
	db $16, $EF
	db $11, $E6
	db $11, $E6
	db $11, $E6
	db $11, $E4
	db $0F, $E4
	db $0D, $E6
	db $0D, $E6
	db $0D, $E6
	db $0D, $E6
	db $11, $E6
	db $11, $E6
	db $11, $E6
	db $11, $E6
	db $11, $E6
	db $11, $E6
	db $11, $E6
	db $11, $E6
	db $11, $E8
	db $11, $E8
	db $11, $E8
	db $65
SongMacro4B:
	db $00, $0A
	db $65
SongMacroTab:
	dw SongMacro00
	dw SongMacro01
	dw SongMacro02
	dw SongMacro03
	dw SongMacro04
	dw SongMacro05
	dw SongMacro06
	dw SongMacro07
	dw SongMacro08
	dw SongMacro09
	dw SongMacro0A
	dw SongMacro0B
	dw SongMacro0C
	dw SongMacro0D
	dw SongMacro0E
	dw SongMacro0F
	dw SongMacro10
	dw SongMacro11
	dw SongMacro12
	dw SongMacro13
	dw SongMacro14
	dw SongMacro15
	dw SongMacro16
	dw SongMacro17
	dw SongMacro18
	dw SongMacro19
	dw SongMacro1A
	dw SongMacro1B
	dw SongMacro1C
	dw SongMacro1D
	dw SongMacro1E
	dw SongMacro1F
	dw SongMacro20
	dw SongMacro21
	dw SongMacro22
	dw SongMacro23
	dw SongMacro24
	dw SongMacro25
	dw SongMacro26
	dw SongMacro27
	dw SongMacro28
	dw SongMacro29
	dw SongMacro2A
	dw SongMacro2B
	dw SongMacro2C
	dw SongMacro2D
	dw SongMacro2E
	dw SongMacro2F
	dw SongMacro30
	dw SongMacro31
	dw SongMacro32
	dw SongMacro33
	dw SongMacro34
	dw SongMacro35
	dw SongMacro36
	dw SongMacro37
	dw SongMacro38
	dw SongMacro39
	dw SongMacro3A
	dw SongMacro3B
	dw SongMacro3C
	dw SongMacro3D
	dw SongMacro3E
	dw SongMacro3F
	dw SongMacro40
	dw SongMacro41
	dw SongMacro42
	dw SongMacro43
	dw SongMacro44
	dw SongMacro45
	dw SongMacro46
	dw SongMacro47
	dw SongMacro48
	dw SongMacro49
	dw SongMacro4A
	dw SongMacro4B

Init:
	;Clear RAM values
	ld a, 0
	ld [C1SFXPos], a
	ld [C1SFXPos+1], a
	ld [C2SFXPos], a
	ld [C2SFXPos+1], a
	ld [C3SFXPos], a
	ld [C3SFXPos+1], a
	ld [C4SFXPos], a
	ld [C4SFXPos+1], a
	ld [C1PlayFlag], a
	ld [C2PlayFlag], a
	ld [C3PlayFlag], a
	ld [C4PlayFlag], a
	
	;Set volume and panning
	ld a, %11111111
	ldh [rNR51], a
	ldh [rNR50], a
	
	;Clear volume for all channels
	ld a, $00
	ldh [rNR12], a
	ldh [rNR22], a
	ldh [rNR32], a
	ldh [rNR42], a
	ldh [rNR43], a
	
	
	;Copy the waveform into wave RAM
	ld de, WaveRAM
	ld hl, Waveform
	ld b, $10

.CopyWave
	ld a, [hl]
	ld [de], a
	inc hl
	inc de
	dec b
	jr nz, .CopyWave

	ret


GetSFX:
	;Get SFX macro pointer from table
	ld hl, SFXTab
	sla a
	add l
	ld l, a
	jr nc, InitSFX

	inc h

InitSFX:
	;Go to SFX pointer
	ld a, [hl]
	ld c, a
	inc hl
	ld a, [hl]
	ld b, a
	;Check the channel number
	ld a, [bc]
	inc bc
	
	;Is it channel 2?
	cp 1
	jr z, InitSFXC2

	;Is it channel 3?
	cp 2
	jr z, InitSFXC3

	;Is it channel 4?
	cp 3
	jr z, InitSFXC4

	;Otherwise, it is channel 1
InitSFXC1:
	;Enable SFX playback with flag
	ld a, [C1PlayFlag]
	and %11111110
	ld [C1PlayFlag], a
	;Go to SFX position from RAM
	ld a, c
	ld [C1SFXPos], a
	ld a, b
	ld [C1SFXPos+1], a
	;Set SFX channel delay
	ld a, 2
	ld [C1SFXDelay], a
	jr PlaySFXC1

InitSFXC2:
	;Enable SFX playback with flag
	ld a, [C2PlayFlag]
	and %11111110
	ld [C2PlayFlag], a
	;Go to SFX position from RAM
	ld a, c
	ld [C2SFXPos], a
	ld a, b
	ld [C2SFXPos+1], a
	;Set SFX channel delay
	ld a, 2
	ld [C2SFXDelay], a
	jr PlaySFXC1

InitSFXC3:
	;Enable SFX playback with flag
	ld a, [C3PlayFlag]
	and %11111110
	ld [C3PlayFlag], a
	;Go to SFX position from RAM
	ld a, c
	ld [C3SFXPos], a
	ld a, b
	ld [C3SFXPos+1], a
	;Set SFX channel delay
	ld a, 2
	ld [C3SFXDelay], a
	jr PlaySFXC1

InitSFXC4:
	;Enable SFX playback with flag
	ld a, [C4PlayFlag]
	and %11111110
	ld [C4PlayFlag], a
	;Go to SFX position from RAM
	ld a, c
	ld [C4SFXPos], a
	ld a, b
	ld [C4SFXPos+1], a
	;Set SFX channel delay
	ld a, 2
	ld [C4SFXDelay], a

;Play the current sound effect, starting with channel 1 if present
PlaySFXC1:
	ld hl, C1PlayFlag
	ld a, l
	ld [CurSFX], a
	ld a, h
	ld [CurSFX+1], a
	ld hl, C1SFXPos
	ld c, [hl]
	inc hl
	ld b, [hl]
	ld a, b
	or c
	;If not present (0 value), then go to next channel
	jr z, PlaySFXC2

	ld de, rNR11
	call CheckSFX

PlaySFXC2:
	ld hl, C2PlayFlag
	ld a, l
	ld [CurSFX], a
	ld a, h
	ld [CurSFX+1], a
	ld hl, C2SFXPos
	ld c, [hl]
	inc hl
	ld b, [hl]
	ld a, b
	or c
	;If not present (0 value), then go to next channel
	jr z, PlaySFXC3

	ld de, rNR21
	call CheckSFX

PlaySFXC3:
	ld hl, C3PlayFlag
	ld a, l
	ld [CurSFX], a
	ld a, h
	ld [CurSFX+1], a
	ld hl, C3SFXPos
	ld c, [hl]
	inc hl
	ld b, [hl]
	ld a, b
	or c
	;If not present (0 value), then go to next channel
	jr z, PlaySFXC4

	ld de, rNR31
	call CheckSFX

PlaySFXC4:
	ld hl, C4PlayFlag
	ld a, l
	ld [CurSFX], a
	ld a, h
	ld [CurSFX+1], a
	ld hl, C4SFXPos
	ld c, [hl]
	inc hl
	ld b, [hl]
	ld a, b
	or c
	;If not present (0 value), then return
	jr z, PlaySFXRet

	ld de, rNR41
	call CheckSFX

PlaySFXRet:
	ret


CheckSFX:
	;Check if channel is ready
	inc hl
	dec [hl]
	;If so, then continue
	jr z, GetNextSFXCMD

	;Otherwise, return
	ret


GetNextSFXCMD:
	;Get the next SFX command
	ld a, [bc]
	;Is it a stop command (FF)?
	cp $FF
	jr z, SFXEventStop

	;Otherwise...
	;Byte 1 = Delay
	ld [hl], a
	inc bc
	;Byte 2 = NRx1 (Channel length/duty)
	ld a, [bc]
	ld [de], a
	;Byte 3 = NRx2 (Volume/envelope)
	inc bc
	inc de
	ld a, [bc]
	ld [de], a
	;Byte 4 = NRx4 (Period high/control)
	inc bc
	inc de
	inc de
	ld a, [bc]
	ld [de], a
	;Byte 5 = NRx3 (Period low)
	inc bc
	dec de
	ld a, [bc]
	ld [de], a
	inc bc
	
	;Update the pointer
	dec hl
	ld [hl], b
	dec hl
	ld [hl], c
	ret


SFXEventStop:
	;Reset the pointer
	ld a, 0
	dec hl
	ld [hl], a
	dec hl
	ld [hl], a
	;Get the current channel's play flag
	ld hl, CurSFX
	ld c, [hl]
	inc hl
	ld b, [hl]
	;Reset it to 3 (music)
	ld a, [bc]
	or %00000001
	ld [bc], a
	ret

SFXTab:
	dw Shot1
	dw Explosion1
	dw Pickup1
	dw Select
	dw Shot2
	dw Pickup2
	dw Lightsaber
	dw BuzzA
	dw BuzzB
	dw Explosion2
	dw Shot3
	dw Explosion3
	dw Shot4
	dw Explosion4
	dw Shot5
	dw Shot6

Shot1:
	db 1
	db 1, $80, $F0, $87, $B1
	db 1, $80, $F0, $87, $A3
	db 1, $80, $F0, $87, $8A
	db 1, $80, $F0, $87, $63
	db 1, $80, $F0, $87, $45
	db 1, $80, $F0, $87, $14
	db 10, $00, $00, $00, $00
	db 1, $80, $F0, $84, $4F
	db 1, $80, $F0, $04, $4F
	db $FF
Explosion1:
	db 3
	db 13, $00, $F0, $80, $54
	db 15, $00, $F0, $80, $52
	db 13, $00, $F0, $80, $54
	db 1, $00, $00, $00, $00
	db $FF
Pickup1:
	db 1
	db 2, $80, $F0, $86, $28
	db 2, $80, $F0, $85, $89
	db 2, $80, $F0, $86, $28
	db 2, $80, $F0, $86, $89
	db 2, $80, $F0, $86, $C5
	db 2, $80, $F0, $87, $14
	db 2, $80, $F0, $87, $8A
	db 1, $00, $00, $00, $00
	db $FF
Select:
	db 1
	db 2, $3D, $F0, $C7, $14
	db 2, $3D, $F0, $C7, $45
	db 2, $3D, $F0, $C7, $63
	db 2, $3D, $F0, $C7, $8A
	db 1, $00, $00, $00, $00
	db $FF
Shot2:
	db 1
	db 1, $3C, $F1, $C7, $74
	db 1, $3C, $F1, $C7, $4F
	db 1, $3C, $F1, $C7, $83
	db 1, $3C, $F1, $C7, $63
	db 1, $3C, $F1, $C7, $8A
	db 1, $3C, $F1, $C7, $7C
	db 1, $3C, $F1, $C7, $63
	db 1, $3C, $F1, $C7, $3A
	db 1, $3C, $F1, $C7, $45
	db 1, $3C, $F1, $C7, $14
	db 1, $00, $00, $00, $00
	db $FF
Pickup2:
	db 1
	db 3, $B7, $F1, $C7, $14
	db 3, $B7, $F1, $C7, $3A
	db 3, $B7, $F1, $C7, $59
	db 3, $B7, $F1, $C7, $63
	db 3, $B7, $F1, $C7, $8A
	db 3, $B7, $F1, $C7, $A3
	db 1, $00, $00, $00, $00
	db $FF
Lightsaber:
	db 1
	db 1, $3D, $F0, $C7, $63
	db 1, $3D, $F0, $C7, $6C
	db 1, $3D, $F0, $C7, $74
	db 1, $3D, $F0, $C7, $7C
	db 1, $3D, $F0, $C7, $83
	db 1, $3D, $F0, $C7, $8A
	db 1, $3D, $F0, $C7, $83
	db 1, $3D, $F0, $C7, $74
	db 1, $3D, $F0, $C7, $63
	db 1, $3D, $F0, $C7, $4F
	db 1, $3D, $F0, $C7, $45
	db 1, $3D, $F0, $C7, $2E
	db 1, $3D, $F0, $C7, $14
	db 1, $3D, $F0, $C7, $06
	db 1, $3D, $F0, $C6, $E7
	db 1, $3D, $F0, $C6, $C5
	db 1, $00, $00, $00, $00
	db $FF
BuzzA:
	db 0
	db 40, $80, $5F, $80, $9D
	db 1, $00, $00, $00, $00
	db $FF
BuzzB:
	db 1
	db 40, $80, $5F, $80, $A1
	db 1, $00, $00, $00, $00
	db $FF
Explosion2:
	db 3
	db 50, $00, $00, $00, $00
	db 40, $00, $F3, $80, $56
	db 1, $00, $00, $00, $00
	db $FF
Shot3:
	db 1
	db 1, $3E, $F0, $C7, $14
	db 1, $3E, $F0, $C7, $21
	db 1, $3E, $F0, $C7, $21
	db 1, $3E, $F0, $C7, $21
	db 1, $3E, $F0, $C7, $21
	db 1, $3E, $F0, $C7, $21
	db 1, $3E, $F0, $C7, $21
	db 1, $3E, $F0, $C7, $2E
	db 1, $3E, $F0, $C7, $3A
	db 1, $3E, $F0, $C7, $45
	db 1, $3E, $F0, $C7, $4F
	db 1, $3E, $F0, $C7, $59
	db 1, $3E, $F0, $C7, $63
	db 1, $3E, $F0, $C7, $6C
	db 1, $3E, $F0, $C7, $74
	db 1, $3E, $F0, $C7, $7C
	db 1, $3E, $F0, $C7, $83
	db 1, $3E, $F0, $C7, $8A
	db 1, $3E, $F0, $C7, $91
	db 1, $3E, $F0, $C7, $97
	db 40, $00, $36, $87, $9D
	db 1, $00, $00, $00, $00
	db $FF
Explosion3:
	db 3
	db 40, $00, $C5, $80, $47
	db 1, $00, $00, $00, $00
	db $FF
Shot4:
	db 1
	db 1, $3E, $F0, $C7, $8A
	db 1, $3E, $F0, $C7, $83
	db 1, $3E, $F0, $C7, $7C
	db 1, $3E, $F0, $C7, $74
	db 1, $3E, $F0, $C7, $6C
	db 1, $3E, $F0, $C7, $63
	db 1, $3E, $F0, $C7, $59
	db 1, $3E, $F0, $C7, $4F
	db 1, $3E, $F0, $C7, $45
	db 1, $3E, $F0, $C7, $3A
	db 1, $3E, $F0, $C7, $2E
	db 1, $3E, $F0, $C7, $21
	db 1, $00, $00, $00, $00
	db $FF
Explosion4:
	db 3
	db 20, $00, $C3, $80, $47
	db 1, $00, $00, $00, $00
	db $FF
Shot5:
	db 3
	db 20, $00, $F1, $80, $53
	db 1, $00, $00, $00, $00
	db $FF
Shot6:
	db 3
	db 40, $00, $F4, $80, $57
	db 1, $00, $00, $00, $00
	db $FF

Waveform:
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $00, $00, $00, $00
	
SECTION "Audio RAM", WRAMX[AudioRAM]
C1PlayFlag: ds 1
C1Len: ds 1
C1Pos: ds 2
C1Freq: ds 2
Unk06: ds 1
C1Duty: ds 1
C1Env: ds 1
Unk09: ds 1
C1EnvSeqDelay: ds 1
C1EnvSeq: ds 2
C1VibSeqDelay: ds 1
C1VibSeq: ds 2
C1ModSeqDelay: ds 1
C1ModSeq: ds 2
C1MacroTimesLeft: ds 1
C1MacroTrans: ds 1
C1InMacro: ds 1
C1MacroRet: ds 2
C2PlayFlag: ds 1
C2Len: ds 1
C2Pos: ds 2
C2Freq: ds 2
Unk1E: ds 1
C2Duty: ds 1
C2Env: ds 1
Unk21: ds 1
C2EnvSeqDelay: ds 1
C2EnvSeq: ds 2
C2VibSeqDelay: ds 1
C2VibSeq: ds 2
C2ModSeqDelay: ds 1
C2ModSeq: ds 2
C2MacroTimesLeft: ds 1
C2MacroTrans: ds 1
C2InMacro: ds 1
C2MacroRet: ds 2
C3PlayFlag: ds 1
C3Len: ds 1
C3Pos: ds 2
C3Freq: ds 2
Unk36: ds 1
C3Duty: ds 1
C3Env: ds 1
Unk39: ds 1
C3EnvSeqDelay: ds 1
C3EnvSeq: ds 2
C3VibSeqDelay: ds 1
C3VibSeq: ds 2
C3ModDelay: ds 1
C3Mod: ds 2
C3MacroTimesLeft: ds 1
C3MacroTrans: ds 1
C3InMacro: ds 1
C3MacroRet: ds 2
C4PlayFlag: ds 1
C4Len: ds 1
C4Pos: ds 2
C4Freq: ds 2
Unk4E: ds 1
C4Duty: ds 1
C4Env: ds 1
Unk51: ds 1
C4EnvSeqDelay: ds 1
C4EnvSeq: ds 2
C4VibSeqDelay: ds 1
C4VibSeq: ds 2
C4ModSeqDelay: ds 1
C4ModSeq: ds 2
C4MacroTimesLeft: ds 1
C4MacroTrans: ds 1
C4InMacro: ds 1
C4MacroRet: ds 2
NoteLens: ds 2
CurRestartPos: ds 2
CurNoise: ds 1
CurTrans: ds 1
CurCmd: ds 1
LoopFlag: ds 1
C1SFXPos: ds 2
C1SFXDelay: ds 1
C2SFXPos: ds 2
C2SFXDelay: ds 1
C3SFXPos: ds 2
C3SFXDelay: ds 1
C4SFXPos: ds 2
C4SFXDelay: ds 1
CurSFX: ds 2
PlayFlag: ds 1