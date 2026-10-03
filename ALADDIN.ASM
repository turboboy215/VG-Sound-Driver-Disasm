;Aladdin (GB) audio disassembly
;Original audio & code by Mark Cooksey
;Disassembly by Will Trowbridge

include "HARDWARE.INC"

def AudioROM equ $4000
def AudioRAM equ $DD00
def WaveRAM equ $FF30

SECTION "Audio", ROMX[AudioROM], BANK[$1]

	jp Init

	jp GetSFXMacro

	jp LoadSong

	jp PlaySongSFX

	jp PlaySong

	jp PlaySFXC1

	jp ClearChVol

	jp MusicOn

	jp CheckVolR1

	jp CheckVolR2

	jp ClearAudio

	jp SetTempo

	jp LoadSFX


SetTempo:
	ld [Tempo], a
	ret


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
	jr z, CheckVolRet

	;If the volume is set to lowest
	cp %00010000
	jr z, CheckVolRet

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


;Stop the volume check routine
CheckVolRet:
	ret


;Clear all audio
ClearAudio:
	xor a
	ldh [rNR51], a
	ld [MasterPan], a
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


	;If at full volume
	and %00000111
	cp %00000111
	jr z, CheckVolL2
;Check the volume of the right speaker again - if it is not full, then set to max
CheckVolR2:
	ldh a, [rNR50]

	;Increase volume
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


;Get SFX from number
LoadSFX:
	add a
	add a
	ld hl, SFXTab
	add l
	ld l, a
	jr nc, GetSFX

	inc h


;Get first channel macro value
GetSFX:
	ld a, [hl]
	;$FF = Skip
	cp $FF
	jr z, .GetSFXP2

	call PlaySFXFromMacro


;Get second channel macro value
.GetSFXP2
	inc hl
	ld a, [hl]
	;$FF = Skip
	cp $FF
	jr z, .GetSFXP3

	call PlaySFXFromMacro


;Get third channel macro value
.GetSFXP3
	inc hl
	ld a, [hl]
	;$FF = Skip
	cp $FF
	jr z, .GetSFXP4

	call PlaySFXFromMacro


;Get fourth channel macro value
.GetSFXP4
	inc hl
	ld a, [hl]
	;$FF = Skip
	cp $FF
	jr z, .ExitSFX

	call PlaySFXFromMacro


;If no channels used, then return
.ExitSFX
	ret


PlaySFXFromMacro:
	push hl
	call GetSFXMacro
	pop hl
	ret


;Clear RAM and copy waveform
Init:

	;Disable audio
	ld a, 0
	ldh [rNR52], a
	nop
	ldh [rNR52], a
	
	;Clear RAM values
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
	
	;Set default tempo
	ld a, 255
	ld [Tempo], a

	;Set timer/beat counter
	ld a, 1
	ld [BeatCounter], a
	
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

	call ChannelInit
	ret


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
	;Add to the song table
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
	ld a, 255
	ld [Tempo], a
	ld a, 1
	ld [BeatCounter], a


ChannelInit:
	;Turn on channels
	ld a, %10001111
	ldh [rNR52], a
	nop
	nop
	ldh [rNR52], a
	
	;Initialize CH1 sweep
	ld a, %00001000
	ldh [rNR10], a
	
	;Set panning and master volume
	ld a, %11111111
	ldh [rNR51], a
	ld [MasterPan], a
	ld a, %01110111
	ldh [rNR50], a
	
	;Turn on CH3 DAC
	ld a, %10000000
	ldh [rNR30], a
	
	;Clear all channels' volume
	xor a
	ldh [rNR12], a
	ldh [rNR22], a
	ldh [rNR32], a
	ldh [rNR42], a
	
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


PlaySong:
	;Check to see if the song is currently playing
	ld a, [PlayFlag]
	and a
	ret z

	;Get the current song tempo and number of beats
	ld a, [Tempo]
	ld b, a
	ld a, [BeatCounter]
	add b
	ld [BeatCounter], a
	;Don't update if no overflow
	ret nc


StartC1:
	;Set current channel number (0)
	xor a
	ld [CurChan], a
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
	and %00000001
	;If not, then skip to channel 2
	jp z, StartC2

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
	ld hl, C1PlayFlag
	ld de, rNR13
	call SetPerLo
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
	;Check delay for pitch modulation sequence
	ld a, [C1ModSeqDelay]
	and a
	;If value is 0, then skip
	jr z, StartC2

.C1ProcessModSeq
	;Otherwise, decrement
	dec a
	ld [C1ModSeqDelay], a
	and a
	;If delay has not yet finished, then return
	jr nz, StartC2

	;Load sequence pointer from RAM
	ld a, [C1ModSeq]
	ld c, a
	ld a, [C1ModSeq+1]
	ld b, a
	ld a, [bc]
	;If reached loop point (FF)...
	cp $FF
	jr z, .C1ProcessModLoop

	;Otherwise, store the next value as new delay in RAM
	ld [C1ModSeqDelay], a
	inc bc
	;Next byte = note frequency change
	ld a, [bc]
	;Add to current note
	ld e, a
	ld a, [CurNoteC1]
	add e
	push af
	;Get the high frequency byte and add it
	ld de, FreqsHi
	add e
	ld e, a
	jr nc, .C1ProcessModSeq2

	inc d

.C1ProcessModSeq2
	ld a, [de]
	ld [C1Freq], a
	pop af
	;Now get the low frequency byte and add it
	ld de, FreqsLo
	add e
	ld e, a
	jr nc, .C1ProcessModSeq3

	inc d

.C1ProcessModSeq3
	ld a, [de]
	ld [C1Freq+1], a
	;Advance to the next part of the sequence
	inc bc
	;Store the updated pointer in RAM
	ld a, c
	ld [C1ModSeq], a
	ld a, b
	ld [C1ModSeq+1], a
	jp StartC2


;Go to pitch modulation sequence loop
.C1ProcessModLoop
	;Reset the delay to 1
	ld a, 1
	ld [C1ModSeqDelay], a
	;Go to the position in the following pointer (2 bytes)
	inc bc
	ld a, [bc]
	ld [C1ModSeq], a
	inc bc
	ld a, [bc]
	ld [C1ModSeq+1], a


StartC2:
	;Set current channel number (1)
	ld a, 1
	ld [CurChan], a
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
	jp z, StartC3
	

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
	ld hl, C2PlayFlag
	ld de, rNR23
	call SetPerLo
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
	;Check delay for pitch modulation sequence
	ld a, [C2ModSeqDelay]
	and a
	;If value is 0, then skip
	jr z, StartC3

.C2ProcessModSeq
	;Otherwise, decrement
	dec a
	ld [C2ModSeqDelay], a
	and a
	;If delay has not yet finished, then return
	jr nz, StartC3

	;Load sequence pointer from RAM
	ld a, [C2ModSeq]
	ld c, a
	ld a, [C2ModSeq+1]
	ld b, a
	ld a, [bc]
	cp $FF
	jr z, .C2ProcessModLoop

	;Otherwise, store the next value as new delay in RAM
	ld [C2ModSeqDelay], a
	inc bc
	;Next byte = note frequency change
	ld a, [bc]
	;Add to current note
	ld e, a
	ld a, [CurNoteC2]
	add e
	push af
	;Get the high frequency byte and add it
	ld de, FreqsHi
	add e
	ld e, a
	jr nc, .C2ProcessModSeq2

	inc d

.C2ProcessModSeq2
	ld a, [de]
	ld [C2Freq], a
	pop af
	;Now get the low frequency byte and add it
	ld de, FreqsLo
	add e
	ld e, a
	jr nc, .C2ProcessModSeq3

	inc d

.C2ProcessModSeq3
	ld a, [de]
	ld [C2Freq+1], a
	;Advance to the next part of the sequence
	inc bc
	;Store the updated pointer in RAM
	ld a, c
	ld [C2ModSeq], a
	ld a, b
	ld [C2ModSeq+1], a
	jp StartC3


;Go to pitch modulation sequence loop
.C2ProcessModLoop
	;Reset the delay to 1
	ld a, 1
	ld [C2ModSeqDelay], a
	;Go to the position in the following pointer (2 bytes)
	inc bc
	ld a, [bc]
	ld [C2ModSeq], a
	inc bc
	ld a, [bc]
	ld [C2ModSeq+1], a


StartC3:
	;Set current channel number (2)
	ld a, 2
	ld [CurChan], a
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
	;If not, then skip to channel 4
	jr z, StartC4

	;Get instrument parameter bytes
	;Set period
	ld hl, C3PlayFlag
	ld de, rNR33
	call SetPerLo
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


StartC4:
	;Set current channel number (3)
	ld a, 3
	ld [CurChan], a
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
	;If not, then set period and return
	jr z, .C4SetPeriod

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
	;Now process the vibrato envelope
	call C4CheckVibSeqDelay

.C4SetPeriod
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
	ld a, 0
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
	push hl
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
	cp $7E
	;If not, then keep going
	jr nz, ProcessVibSeq

	;Stop the vibrato sequence
	pop hl
	ret


ProcessVibSeq:
	;Is it a loop command?
	cp $7D
	;If so, then keep checking
	jr z, ProcessVibLoop

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
	pop hl
	ret


ProcessVibLoop:
	;Get the next 2 bytes (pointer) and jump to position
	inc bc
	ld a, [bc]
	push af
	inc bc
	ld a, [bc]
	ld b, a
	pop af
	ld c, a
	pop hl
	;Reset the delay to 1
	ld a, 1
	ld [hl], a
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
	ld d, a
	
	;Save the current note value
	push af
	ld a, [CurChan]
CheckC1:
	;Is the channel 1?
	cp 0
	;If not, then skip to channel 2
	jr nz, CheckC2

	;Otherwise, then save current Ch1 note
	ld a, d
	ld [CurNoteC1], a


CheckC2:
	;Is the channel 2?
	cp 1
	;If not, then skip to the next part
	jr nz, GetFreq

	ld a, d
	ld [CurNoteC2], a


;Get the current frequency
GetFreq:
	pop af
	;First get the high byte from table
	ld de, FreqsHi
	add e
	ld e, a
	jp nc, .GetFreq2

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
	;Mask out the higher 4 bits to get the note length index
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


;Now get the instrument from the first bit of byte 1 and higher 4 bits of byte 2
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
	;Instrument byte 10 = Pitch modulation sequence delay
	ld a, [bc]
	ld [hl], a
	inc bc
	inc hl
	;Instrument byte 11-12 = Pitch modulation sequence pointer
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


CheckPerTrigger:
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
	ld [C4Freq+1], a
	ld [de], a
	;Then do the rest
	jr CheckPerTrigger


C4CheckVibSeqDelay:
	;If value is 0, then return
	ld a, [C4VibSeqDelay]
	and a
	ret z

	;Otherwise, decrement
	dec a
	ld [C4VibSeqDelay], a
	and a
	ret nz

	;Load noise vibrato pointer from RAM
	ld a, [C4VibSeq]
	ld l, a
	ld a, [C4VibSeq+1]
	ld h, a
	ld a, [hl]
	;If reached loop point (FF)...
	cp $FF
	;Then return
	ret z

	;Otherwise, set the current noise frequency from sequence
	ld [CurNoise], a
	inc hl
	ld a, [hl]
	ld [C4VibSeqDelay], a
	inc hl
	;Store the new delay and updated pointer in RAM
	ld a, l
	ld [C4VibSeq], a
	ld a, h
	ld [C4VibSeq+1], a
	ret


VCMDTable:
	dw EventTie 		;$60
	dw EventStop 		;$61
	dw EventJump 		;$62
	dw EventNoise		;$63
	dw EventMacro 		;$64
	dw EventMacroRet	;$65
	dw EventCondFlag	;$66
	dw EventGlobalPan	;$67
	dw EventNoteLens	;$68
	dw EventTempo		;$69
	dw EventC1Pan		;$6A
	dw EventC2Pan		;$6B
	dw EventC3Pan		;$6C
	dw EventC4Pan		;$6D


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
	;If 0, then set flag and get the times in macro
	jr z, .EventMacro4

	;Otherwise, skip
	inc bc
	jr .EventMacro5

.EventMacro4
	;Set the macro flag
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
	jp GotoRestart

EventMacroRet:
;Return from the current macro
	inc bc
	;Set channel length flag to 1
	pop hl
	ld de, -2
	add hl, de
	ld a, 1
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
	jr z, EventMacroRetEnd

	;Otherwise, subtract 1 and jump to macro start
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


EventMacroRetEnd:
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
	jp GotoRestart


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
	jp GotoRestart


EventGlobalPan:
;Set global panning
;Parameters: xx (X = Value, see NR51 usage)
	inc bc
	ld a, [bc]
	ldh [rNR51], a
	ld [MasterPan], a


;Reset the note by setting the channel length to 1
ResetNote:
	;Set channel note length to 1
	inc bc
	pop hl
	ld de, -2
	add hl, de
	ld a, 1
	ld [hl+], a
	;Update the channel pointer
	call UpdatePtr
	jr GotoRestart


EventC1Pan:
;Set channel 1 panning
;Parameters: xx (X = Value, only channel 1 bits are used)
	inc bc
	;Get current panning (NR51) value and mask out channel 1 bits
	ld a, [MasterPan]
	and %11101110
	ld h, a
	;Mask in parameter values
	ld a, [bc]
	or h
	;Store new value into RAM and register
	ld [MasterPan], a
	ldh [rNR51], a
	jr ResetNote


EventC2Pan:
;Set channel 2 panning
;Parameters: xx (X = Value, only channel 2 bits are used)
	inc bc
	;Get current panning (NR51) value and mask out channel 2 bits
	ld a, [MasterPan]
	and %11011101
	ld h, a
	;Mask in parameter values
	ld a, [bc]
	or h
	;Store new value into RAM and register	
	ld [MasterPan], a
	ldh [rNR51], a
	jr ResetNote


EventC3Pan:
;Set channel 3 panning
;Parameters: xx (X = Value, only channel 3 bits are used)
	inc bc
	;Get current panning (NR51) value and mask out channel 3 bits
	ld a, [MasterPan]
	and %10111011
	ld h, a
	;Mask in parameter values
	ld a, [bc]
	or h
	;Store new value into RAM and register
	ld [MasterPan], a
	ldh [rNR51], a
	jr ResetNote


EventC4Pan:
;Set channel 4 panning
;Parameters: xx (X = Value, only channel 4 bits are used)
	inc bc
	;Get current panning (NR51) value and mask out channel 4 bits
	ld a, [MasterPan]
	and %01110111
	ld h, a
	;Mask in parameter values
	ld a, [bc]
	or h
	;Store new value into RAM and register
	ld [MasterPan], a
	ldh [rNR51], a
	jr ResetNote


EventNoteLens:
;Set note lengths from the following pointer (for all channels)
;Parameters: xx xx (X = Pointer)
	inc bc
	ld a, [bc]
	ld [NoteLens], a
	inc bc
	ld a, [bc]
	ld [NoteLens+1], a
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


EventTempo:
;Set the tempo
;Parameters: x (X = Value)
	inc bc
	ld a, [bc]
	ld [Tempo], a
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

GetSFXMacro:
	;Get SFX macro pointer from table
	ld hl, SFXMacroTab
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
	;Enable all channels
	ld a, %10001111
	ldh [rNR52], a
	ldh [rNR52], a
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
	;Set panning
	ld a, [MasterPan]
	ld d, a
	ld a, %00010001
	or d
	ld [MasterSFXPan], a
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
	;Set panning
	ld a, [MasterPan]
	ld d, a
	ld a, %00100010
	or d
	ld [MasterSFXPan], a
	;Enable SFX playback with flag
	ld a, [C2PlayFlag]
	and %11111110
	ld [C2PlayFlag], a
	;Enable SFX playback with flag
	ld a, c
	ld [C2SFXPos], a
	ld a, b
	ld [C2SFXPos+1], a
	;Set SFX channel delay
	ld a, 2
	ld [C2SFXDelay], a
	jr PlaySFXC1


InitSFXC3:
	;Set panning
	ld a, [MasterPan]
	ld d, a
	ld a, %01000100
	or d
	ld [MasterSFXPan], a
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
	;Set panning
	ld a, [MasterPan]
	ld d, a
	ld a, %10001000
	or d
	ld [MasterSFXPan], a
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

	;Otherwise, then play SFX
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


;Return from SFX routine
PlaySFXRet:
	ret


CheckSFX:
	;Set the panning for SFX
	ld a, [MasterSFXPan]
	ldh [rNR51], a
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

	;Is it a jump command (FE)?
	cp $FE
	jr z, SFXEventJump

	;Otherwise...
	;Byte 1 = Delay
	ld [hl], a
	;Byte 2 = NRx1 (Channel length/duty)
	inc bc
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


SFXUpdatePtr:
;Update the pointer
	dec hl
	ld [hl], b
	dec hl
	ld [hl], c
	ret


SFXEventStop:
;Stop the macro
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
	;Restore the original panning
	ld a, [MasterPan]
	ldh [rNR51], a
	ret


SFXEventJump:
	;Load the loop position from the following 2 bytes as the position
	inc bc
	ld a, [bc]
	ld e, a
	inc bc
	ld a, [bc]
	ld b, a
	ld c, e
	;Reset SFX channel play flag to 1
	ld a, 1
	ld [hl], a
	jr SFXUpdatePtr


Waveform:
	db $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $00, $00, $00, $00, $00, $00, $00, $00

;Song data pointers: CH1, CH2, CH3, CH4, and note length values
SongTab:
.PrinceAli
	dw PrinceAliA, PrinceAliB, PrinceAliC, PrinceAliD, LenTab1
.NeNaw
	dw NeNawA, NeNawB, NeNawC, NeNawD, LenTab1
.DoNotUse
	dw DoNotUseA, DoNotUseB, DoNotUseC, DoNotUseD, LenTab1
.OneJump
	dw OneJumpA, OneJumpB, OneJumpC, OneJumpD, LenTab3
.NewWorld
	dw NewWorldA, NewWorldB, NewWorldC, NewWorldD, LenTab1
.LevComplete
	dw LevCompleteA, LevCompleteB, LevCompleteC, LevCompleteD, LenTab1
.Empty
	dw EmptyA, EmptyB, EmptyC, EmptyD, LenTab2

;Note lengths
LenTab1:
	db 3, 4, 6, 9, 12, 18, 24, 36, 48, 72, 96, 144, 192, 8, 16, 32
	
LenTab2:
	db 4, 6, 8, 12, 16, 24, 32, 48, 64, 96, 128, 192, 252, 5, 10, 20
	
LenTab3:
	db 1, 2, 3, 4, 6, 9, 12, 18, 24, 36, 48, 72, 96, 4, 8, 16
	
InsTab:
	dw InsRest
	dw InsBassDrum
	dw InsSnareDrum
	dw InsHiHatC
	dw InsHiHatP
	dw InsHiHatO
	dw InsBuzz
	dw InsTomTom
	dw InsClink
	dw InsBoing
	dw InsPlink
	dw InsBell1
	dw InsBell2
	dw InsPiano
	dw InsBell3
	dw InsBrass
	dw InsBassShort
	dw InsBassMed
	dw InsBassLong
	dw InsArp7
	dw InsArp12
	dw InsArp16
	dw InsDoNotUse16
	dw InsDoNotUse17
	dw InsDoNotUse18
	dw InsBassVShort
	dw InsPing
	dw InsDull
	dw InsSlideUp
	dw InsBlip
	dw InsBlipQuiet

InsRest:
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
InsBassDrum:
	;Period ctrl
	db $C0
	;Duty
	db $BD
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq00
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq00
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
InsSnareDrum:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq01
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq01
	;Pitch mod seq delay
	db 0
	;Pitch mod ptr
	dw 0
InsHiHatC:
	;Period ctrl
	db $C0
	;Duty
	db $BB
	;Initial vol/env
	db $41
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq02
	;Pitch mod seq delay
	db 0
	;Pitch mod ptr
	dw 0
InsHiHatP:
	;Period ctrl
	db $C0
	;Duty
	db $B2
	;Initial vol/env
	db $61
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq02
	;Pitch mod seq delay
	db 0
	;Pitch mod seq ptr
	dw 0
InsHiHatO:
	;Period ctrl
	db $80
	;Duty
	db $00
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq02
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq03
	;Pitch mod seq delay
	db 0
	;Pitch mod seq ptr
	dw 0
InsBuzz:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq03
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq04
	;Pitch mod seq delay
	db 0
	;Pitch mod seq ptr
	dw 0
InsTomTom:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq04
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod seq delay
	db 1
	;Pitch mod seq ptr
	dw ModSeq00
InsClink:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq05
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod seq delay
	db 0
	;Pitch mod seq ptr
	dw 0
InsBoing:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq06
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod seq delay
	db 1
	;Pitch mod seq ptr
	dw ModSeq01
InsPlink:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $A1
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq06
	;Pitch mod seq delay
	db 0
	;Pitch mod seq ptr
	dw 0
InsBell1:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $A5
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db $01
	;Vib seq ptr
	dw VibSeq06
	;Pitch mod seq delay
	db 0
	;Pitch mod seq ptr
	dw 0
InsBell2:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq07
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq06
	;Pitch mod seq delay
	db 0
	;Pitch mod seq ptr
	dw 0
InsPiano:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $62
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq06
	;Pitch mod seq delay
	db 0
	;Pitch mod seq ptr
	dw 0
InsBell3:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $66
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq06
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
InsBrass:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $00
	;Env seq delay
	db $01
	;Env seq ptr
	dw EnvSeq08
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq07
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
InsBassShort:
	;Period ctrl
	db $C0
	;Duty
	db $00
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq09
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod seq delay
	db 0
	;Pitch mod seq ptr
	dw 0
InsBassMed:
	;Period ctrl
	db $C0
	;Duty
	db $00
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq0A
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod seq delay
	db 0
	;Pitch mod seq ptr
	dw 0
InsBassLong:
	;Period ctrl
	db $80
	;Duty
	db $00
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq0B
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod seq delay
	db 0
	;Pitch mod seq ptr
	dw 0
InsArp7:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $64
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod seq delay
	db 1
	;Pitch mod seq ptr
	dw ModSeq02
InsArp12:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $64
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod seq delay
	db 1
	;Pitch mod seq ptr
	dw ModSeq03
InsArp16:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $64
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod seq delay
	db $01
	;Pitch mod seq ptr
	dw ModSeq04
InsDoNotUse16:
InsDoNotUse17:
InsDoNotUse18:
InsBassVShort:
	;Period ctrl
	db $C0
	;Duty
	db $3C
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq0C
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod seq delay
	db 0
	;Pitch mod seq ptr
	dw 0
InsPing:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq0D
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq07
	;Pitch mod seq delay
	db 1
	;Pitch mod seq ptr
	dw ModSeq05
InsDull:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq0E
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq08
	;Pitch mod seq delay
	db 0
	;Pitch mod seq ptr
	dw 0
InsSlideUp:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq0F
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod seq delay
	db 1
	;Pitch mod seq ptr
	dw ModSeq06
InsBlip:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq10
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq09
	;Pitch mod seq delay
	db 0
	;Pitch mod seq ptr
	dw 0
InsBlipQuiet:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq11
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq09
	;Pitch mod seq delay
	db 0
	;Pitch mod seq ptr
	dw 0
	
EnvSeq00:
	db $F0, 1
	db $00, 1
	db $80, 1
	db $00, 1
	db $FF
EnvSeq01:
	db $60, 3
	db $20, 2
	db $10, 2
	db $00, 1
	db $FF
EnvSeq02:
	db $60, 1
	db $50, 1
	db $30, 3
	db $20, 4
	db $10, 4
	db $00, 1
	db $FF
EnvSeq03:
	db $A0, 1
	db $50, 1
	db $A0, 1
	db $50, 1
	db $A0, 1
	db $50, 1
	db $A0, 1
	db $50, 1
	db $00, 1
	db $FF
EnvSeq04:
	db $F0, 2
	db $80, 2
	db $60, 2
	db $30, 1
	db $20, 2
	db $10, 2
	db $00, 1
	db $FF
EnvSeq05:
	db $80, 1
	db $40, 1
	db $00, 2
	db $10, 1
	db $00, 1
	db $FF
EnvSeq06:
	db $A0, 1
	db $50, 1
	db $40, 1
	db $30, 1
	db $20, 1
	db $00, 1
	db $FF
EnvSeq07:
	db $A0, 1
	db $90, 1
	db $80, 2
	db $70, 4
	db $60, 8
	db $50, 16
	db $40, 20
	db $30, 30
	db $20, 40
	db $10, 40
	db $00, 1
	db $FF
EnvSeq08:
	db $60, 1
	db $50, 1
	db $40, 4
	db $30, 24
	db $20, 50
	db $10, 80
	db $00, 1
	db $FF
EnvSeq09:
	db $20, 4
	db $40, 6
	db $60, 8
	db $00, 1
	db $FF
EnvSeq0A:
	db $20, 3
	db $40, 5
	db $60, 50
	db $00, 1
	db $FF
EnvSeq0B:
	db $20, 5
	db $40, 200
	db $60, 160
	db $00, 1
	db $FF
EnvSeq0C:
	db $20, 1
	db $60, 1
	db $00, 1
	db $FF
EnvSeq0D:
	db $60, 2
	db $40, 1
	db $20, 200
	db $20, 200
	db $10, 200
	db $00, 1
	db $FF
EnvSeq0E:
	db $40, 1
	db $30, 2
	db $20, 2
	db $10, 2
	db $00, 1
	db $FF
EnvSeq0F:
	db $70, 200
	db $60, 200
	db $50, 200
	db $00, 1
	db $FF
EnvSeq10:
	db $90, 1
	db $40, 2
	db $20, 2
	db $00, 1
	db $FF
EnvSeq11:
	db $50, 1
	db $20, 1
	db $10, 1
	db $00, 1
	db $FF
	
VibSeq00:
	db $60, 200
	db $7E
VibSeq01:
	db 34, 1
	db 100, 2
	db 34, 2
	db 55, 1
	db 34, 1
	db 55, 1
	db 34, 1
	db 34, 1
	db 55, 1
	db 34, 1
	db 55, 1
	db 34, 1
	db 55, 1
	db 34, 1
	db 55, 1
	db 34, 16
	db $7E
VibSeq02:	
	db 18, 200
	db $7E
VibSeq03:
	db 34, 1
	db 16, 200
	db $7E
VibSeq04:
	db 2, 1
	db -2, 1
	db 2, 1
	db -2, 1
	db 2, 1
	db -2, 1
	db 2, 1
	db -2, 1
	db $7D
	dw VibSeq04
VibSeq05:
	db 0, 2
	db -1, 1
	db -2, 1
	db -3, 1
	db -4, 1
	db -5, 1
	db -6, 1
	db -7, 1
	db -8, 1
	db -9, 1
	db -10, 1
	db -11, 1
	db -12, 1
	db -13, 1
	db -14, 1
	db -15, 1
	db -16, 1
	db -17, 1
	db -20, 1
	db -25, 1
	db $7E
VibSeq06:
	db 2, 3
	db -2, 3
	db -2, 3
	db 2, 3
	db 2, 3
	db -2, 3
	db -2, 3
	db 2, 3
	db $7D
	dw VibSeq06
VibSeq07:
	db 0, 4
	db 2, 1
	db -2, 1
	db -2, 1
	db 2, 1
	db 2, 1
	db -2, 1
	db -2, 1
	db 2, 1
	db $7E
VibSeq08:
	db -3, 253
	db $7E
VibSeq09:
	db 34, 1
	db 34, 2
	db 55, 100
	db $7E
	
ModSeq00:
	db 1, -1
	db 1, -2
	db 1, -3
	db 1, -4
	db 1, -5
	db 1, -6
	db 1, -7
	db 1, -8
	db 1, -9
	db 1, -10
	db 1, -11
	db 1, -12
	db 1, -13
	db 200, -13
	db $FF
	dw ModSeq00
ModSeq01:
	db 2, 0
	db 1, 1
	db 1, 2
	db 1, 3
	db 200, 3
	db $FF
	dw ModSeq01
ModSeq02:
	db 1, 0
	db 1, 4
	db 1, 7
	db 1, 0
	db 1, 4
	db 1, 7
	db $FF
	dw ModSeq02
ModSeq03:
	db 1, 4
	db 1, 7
	db 1, 12
	db 1, 4
	db 1, 7
	db 1, 12
	db $FF
	dw ModSeq03
ModSeq04:
	db 1, 7
	db 1, 12
	db 1, 16
	db 1, 7
	db 1, 12
	db 1, 16
	db $FF
	dw ModSeq04
ModSeq05:
	db 1, 12
	db 200, 0
	db 200, 0
	db 200, 0
	db $FF
	dw ModSeq05
ModSeq06:
	db 1, 0
	db 1, 1
	db 1, 2
	db 1, 3
	db 1, 4
	db 1, 5
	db 1, 6
	db 1, 7
	db 1, 8
	db 1, 9
	db 1, 10
	db 1, 11
	db 1, 12
	db 1, 13
	db 1, 14
	db 1, 15
	db 1, 16
	db 1, 17
	db 1, 18
	db 1, 19
	db 1, 20
	db 1, 21
	db 1, 22
	db 1, 23
	db 1, 24
	db 1, 25
	db 1, 26
	db 1, 27
	db 1, 28
	db 1, 29
	db 1, 30
	db 1, 31
	db 1, 32
	db 1, 33
	db 1, 34
	db 1, 35
	db 1, 36
	db 1, 37
	db 1, 38
	db 1, 39
	db 1, 40
	db 1, 41
	db 1, 42
	db 1, 43
	db 1, 44
	db 1, 45
	db 1, 46
	db 1, 47
	db 1, 48
	db $FF
	dw ModSeq06

PrinceAliA:
	db $67, %11111111
	db $69, 210
	db $64, $00, -21, 1
	db $64, $04, -21, 1
	db $66, 1
	db $62
	dw PrinceAliA
PrinceAliB:
	db $64, $01, -21, 1
	db $64, $05, -21, 1
	db $62
	dw PrinceAliB
PrinceAliC:
	db $64, $02, -9, 1
	db $64, $06, -9, 1
	db $62
	dw PrinceAliC
PrinceAliD:
	db $64, $03, 0, 24
	db $62
	dw PrinceAliD
	
SongMacro00:
	db $40, $E6
	db $3E, $E2
	db $40, $E2
	db $3E, $E4
	db $3C, $E5
	db $3B, $E4
	db $3C, $E2
	db $3B, $E4
	db $39, $E4
	db $34, $F8
	db $24, $04
	db $33, $E4
	db $34, $E4
	db $39, $E6
	db $37, $E2
	db $39, $E2
	db $37, $E4
	db $35, $E5
	db $34, $E4
	db $35, $E2
	db $34, $E4
	db $32, $F9
	db $24, $04
	db $35, $E4
	db $35, $E4
	db $35, $E4
	db $34, $E2
	db $35, $E2
	db $34, $E4
	db $30, $F7
	db $39, $E4
	db $39, $E4
	db $39, $E4
	db $37, $E2
	db $39, $E2
	db $37, $E4
	db $35, $F7
	db $3C, $E4
	db $3C, $E6
	db $3B, $E4
	db $39, $E4
	db $3C, $E6
	db $3A, $E4
	db $3B, $E4
	db $40, $F9
	db $34, $E4
	db $34, $E4
	db $40, $E6
	db $3E, $E2
	db $40, $E2
	db $3E, $E4
	db $3C, $E5
	db $3B, $E4
	db $3C, $E2
	db $3B, $E4
	db $39, $E4
	db $34, $F8
	db $24, $04
	db $33, $E4
	db $34, $E4
	db $39, $E6
	db $37, $E2
	db $39, $E2
	db $37, $E4
	db $35, $E5
	db $34, $E4
	db $35, $E2
	db $34, $E4
	db $32, $F9
	db $24, $04
	db $35, $E4
	db $35, $E4
	db $35, $E4
	db $34, $E2
	db $35, $E2
	db $34, $E4
	db $30, $F7
	db $39, $E4
	db $39, $E4
	db $39, $E4
	db $37, $E2
	db $39, $E2
	db $37, $E4
	db $35, $F7
	db $3B, $E4
	db $3C, $E6
	db $3B, $E4
	db $39, $E4
	db $40, $E4
	db $34, $E6
	db $3C, $E4
	db $39, $FA
	db $65
SongMacro01:
	db $24, $04
	db $30, $D4
	db $24, $04
	db $2F, $D4
	db $24, $04
	db $30, $D4
	db $24, $04
	db $30, $D4
	db $24, $04
	db $30, $D4
	db $24, $04
	db $30, $D4
	db $24, $04
	db $30, $D4
	db $24, $04
	db $30, $D4
	db $24, $04
	db $31, $D4
	db $24, $04
	db $31, $D4
	db $24, $04
	db $31, $D4
	db $24, $04
	db $31, $D4
	db $24, $04
	db $2D, $D4
	db $24, $04
	db $2D, $D4
	db $24, $04
	db $2D, $D4
	db $24, $04
	db $2D, $D4
	db $24, $04
	db $2C, $D4
	db $24, $04
	db $2C, $D4
	db $24, $04
	db $30, $D4
	db $24, $04
	db $30, $D4
	db $24, $04
	db $2E, $D4
	db $24, $04
	db $2E, $D4
	db $24, $04
	db $2D, $D4
	db $24, $04
	db $2D, $D4
	db $24, $04
	db $2D, $D4
	db $24, $04
	db $2D, $D4
	db $24, $04
	db $2D, $D4
	db $24, $04
	db $2D, $D4
	db $24, $04
	db $2F, $D4
	db $24, $04
	db $2F, $D4
	db $24, $04
	db $2F, $D4
	db $24, $04
	db $2F, $D4
	db $24, $04
	db $30, $D4
	db $24, $04
	db $2F, $D4
	db $24, $04
	db $30, $D4
	db $24, $04
	db $2F, $D4
	db $24, $04
	db $30, $D4
	db $24, $04
	db $30, $D4
	db $24, $04
	db $30, $D4
	db $24, $04
	db $30, $D4
	db $24, $04
	db $31, $D4
	db $24, $04
	db $31, $D4
	db $24, $04
	db $31, $D4
	db $24, $04
	db $31, $D4
	db $24, $04
	db $32, $D4
	db $24, $04
	db $32, $D4
	db $24, $04
	db $32, $D4
	db $24, $04
	db $32, $D4
	db $24, $04
	db $2C, $D4
	db $24, $04
	db $2C, $D4
	db $24, $04
	db $30, $D4
	db $24, $04
	db $30, $D4
	db $24, $04
	db $2E, $D4
	db $24, $04
	db $2E, $D4
	db $24, $04
	db $2D, $D4
	db $24, $04
	db $2D, $D4
	db $24, $04
	db $2D, $D4
	db $24, $04
	db $2D, $D4
	db $24, $04
	db $2F, $D4
	db $24, $04
	db $2F, $D4
	db $24, $04
	db $30, $D4
	db $24, $04
	db $30, $D4
	db $24, $04
	db $30, $D4
	db $24, $04
	db $30, $D4
	db $65
SongMacro02:
	db $A1, $14
	db $AD, $14
	db $9C, $14
	db $AC, $14
	db $A1, $14
	db $AD, $14
	db $9C, $14
	db $AD, $14
	db $A1, $14
	db $AD, $14
	db $9C, $14
	db $AD, $14
	db $A1, $14
	db $AD, $14
	db $9C, $14
	db $AD, $14
	db $A1, $14
	db $AB, $14
	db $9C, $14
	db $AB, $14
	db $A1, $14
	db $AB, $14
	db $9C, $14
	db $AB, $14
	db $9A, $14
	db $A9, $14
	db $95, $14
	db $A9, $14
	db $9A, $14
	db $A9, $14
	db $9A, $14
	db $A9, $14
	db $9C, $14
	db $A8, $14
	db $9C, $14
	db $A8, $14
	db $A1, $14
	db $AD, $14
	db $9C, $14
	db $AD, $14
	db $98, $14
	db $AB, $14
	db $98, $14
	db $AB, $14
	db $9D, $14
	db $A9, $14
	db $9D, $14
	db $A9, $14
	db $9A, $14
	db $A9, $14
	db $95, $14
	db $A9, $14
	db $9A, $14
	db $A9, $14
	db $9A, $14
	db $A9, $14
	db $9C, $14
	db $AC, $14
	db $97, $14
	db $AC, $14
	db $9C, $14
	db $AC, $14
	db $9C, $14
	db $AC, $14
	db $A1, $14
	db $AD, $14
	db $9C, $14
	db $AC, $14
	db $A1, $14
	db $AD, $14
	db $9C, $14
	db $AC, $14
	db $A1, $14
	db $AD, $14
	db $9C, $14
	db $AD, $14
	db $A1, $14
	db $AD, $14
	db $9C, $14
	db $AD, $14
	db $A1, $14
	db $AB, $14
	db $9C, $14
	db $AB, $14
	db $A1, $14
	db $AB, $14
	db $9C, $14
	db $AB, $14
	db $9A, $14
	db $A9, $14
	db $95, $14
	db $A9, $14
	db $9A, $14
	db $A9, $14
	db $9A, $14
	db $A9, $14
	db $9C, $14
	db $A8, $14
	db $9C, $14
	db $A8, $14
	db $A1, $14
	db $AD, $14
	db $A1, $14
	db $AD, $14
	db $98, $14
	db $AB, $14
	db $98, $14
	db $AB, $14
	db $9D, $14
	db $A9, $14
	db $9D, $14
	db $A9, $14
	db $9A, $14
	db $A9, $14
	db $9A, $14
	db $A9, $14
	db $9C, $14
	db $AC, $14
	db $9C, $14
	db $AC, $14
	db $A1, $14
	db $AD, $14
	db $9C, $14
	db $AD, $14
	db $A1, $14
	db $AD, $14
	db $A1, $14
	db $AD, $14
	db $65
SongMacro03:
	db $18, $12
 	db $1E, $32
 	db $1A, $22
 	db $1E, $32
 	db $18, $12
 	db $1E, $32
 	db $1A, $22
 	db $1E, $32
 	db $18, $12
 	db $1E, $32
 	db $1A, $22
 	db $1E, $32
 	db $18, $12
 	db $1E, $32
 	db $1A, $22
 	db $1E, $32
 	db $18, $12
 	db $1E, $32
 	db $1A, $22
 	db $1E, $32
 	db $18, $12
 	db $1E, $32
 	db $1A, $22
 	db $1E, $32
 	db $18, $12
 	db $1E, $32
 	db $9A, $D2
 	db $9A, $D2
 	db $18, $12
 	db $1E, $32
 	db $1A, $22
 	db $1E, $32
 	db $18, $12
 	db $1E, $32
 	db $1A, $22
 	db $1E, $32
 	db $18, $12
 	db $1E, $32
 	db $1A, $22
 	db $1E, $32
 	db $18, $12
 	db $1E, $32
 	db $1A, $22
 	db $1E, $32
 	db $18, $12
 	db $1E, $32
 	db $1A, $22
 	db $1E, $32
 	db $18, $12
 	db $1E, $32
 	db $1A, $22
 	db $1E, $32
 	db $18, $12
 	db $1E, $32
 	db $1A, $22
 	db $1E, $32
 	db $18, $12
 	db $1E, $32
 	db $9A, $D2
 	db $9A, $D2
 	db $18, $12
 	db $1E, $32
 	db $1A, $22
 	db $1E, $32
 	db $65
SongMacro04:
	db $3B, $E6
	db $39, $E4
	db $38, $E4
	db $39, $E6
	db $3B, $E4
	db $39, $E4
	db $39, $E4
	db $34, $F8
	db $24, $04
	db $38, $E4
	db $39, $E4
	db $3B, $E6
	db $39, $E4
	db $38, $E4
	db $39, $E4
	db $3B, $E6
	db $39, $E4
	db $3C, $F9
	db $38, $E4
	db $39, $E4
	db $3B, $E6
	db $39, $E4
	db $38, $E4
	db $39, $E4
	db $3B, $E6
	db $39, $E4
	db $39, $E4
	db $34, $F9
	db $39, $E4
	db $39, $E4
	db $35, $D2
	db $35, $D2
	db $35, $D4
	db $39, $D4
	db $39, $D4
	db $39, $D2
	db $39, $D2
	db $39, $D4
	db $35, $D4
	db $3B, $D4
	db $3B, $E4
	db $3A, $E4
	db $3B, $E4
	db $40, $E6
	db $34, $E4
	db $34, $E4
	db $65
SongMacro05:
	db $24, $04
	db $2D, $D4
	db $24, $04
	db $2D, $D4
	db $24, $04
	db $2D, $D4
	db $24, $04
	db $2D, $D4
	db $24, $04
	db $30, $D4
	db $24, $04
	db $30, $D4
	db $24, $04
	db $30, $D4
	db $24, $04
	db $30, $D4
	db $24, $04
	db $2D, $D4
	db $24, $04
	db $2D, $D4
	db $24, $04
	db $2D, $D4
	db $24, $04
	db $2D, $D4
	db $24, $04
	db $30, $D4
	db $24, $04
	db $30, $D4
	db $24, $04
	db $30, $D4
	db $24, $04
	db $30, $D4
	db $24, $04
	db $2D, $D4
	db $24, $04
	db $2D, $D4
	db $24, $04
	db $2D, $D4
	db $24, $04
	db $2D, $D4
	db $24, $04
	db $30, $D4
	db $24, $04
	db $30, $D4
	db $24, $04
	db $30, $D4
	db $24, $04
	db $30, $D4
	db $24, $04
	db $30, $D2
	db $30, $D2
	db $30, $D4
	db $24, $06
	db $30, $D2
	db $30, $D2
	db $30, $D4
	db $30, $D4
	db $24, $04
	db $2F, $D4
	db $24, $04
	db $2F, $D4
	db $24, $04
	db $2F, $D4
	db $24, $04
	db $2F, $D4
	db $65
SongMacro06:
	db $9A, $14
	db $A9, $14
	db $95, $14
	db $A9, $14
	db $9A, $14
	db $A9, $14
	db $9A, $14
	db $A9, $14
	db $A1, $14
	db $AD, $14
	db $9C, $14
	db $AD, $14
	db $A1, $14
	db $AD, $14
	db $A1, $14
	db $AD, $14
	db $9A, $14
	db $A9, $14
	db $95, $14
	db $A9, $14
	db $9A, $14
	db $A9, $14
	db $9A, $14
	db $A9, $14
	db $A1, $14
	db $AD, $14
	db $9C, $14
	db $AD, $14
	db $A1, $14
	db $AD, $14
	db $A1, $14
	db $AD, $14
	db $9A, $14
	db $A9, $14
	db $95, $14
	db $A9, $14
	db $9A, $14
	db $A9, $14
	db $9A, $14
	db $A9, $14
	db $A1, $14
	db $AD, $14
	db $9C, $14
	db $AD, $14
	db $A1, $14
	db $AD, $14
	db $9C, $14
	db $AD, $14
	db $9D, $14
	db $AD, $12
	db $AD, $12
	db $AD, $14
	db $9D, $14
	db $9D, $14
	db $AD, $12
	db $AD, $12
	db $AD, $14
	db $9D, $14
	db $A3, $14
	db $B3, $14
	db $9E, $14
	db $B3, $14
	db $9C, $14
	db $AC, $14
	db $9C, $14
	db $AC, $14
	db $65
	
NeNawA:
	db $67, %11111111
	db $69, 255
	db $64, $07, -21, 1
	db $64, $08, -21, 1
	db $66, 1
	db $62
	dw NeNawA
NeNawB:
	db $64, $09, -21, 1
	db $64, $0A, -21, 1
	db $62
	dw NeNawB
NeNawC:
	db $64, $0B, -9, 1
	db $62
	dw NeNawC
NeNawD:
	db $64, $0C, 0, 3
	db $64, $0E, 0, 8
	db $64, $0C, 0, 2
	db $64, $0D, 0, 1
	db $64, $0C, 0, 3
	db $64, $0E, 0, 8
	db $64, $0C, 0, 2
	db $64, $0D, 0, 1
	db $62
	dw NeNawD
	
SongMacro07:
	db $45, $F8
	db $24, $08
	db $39, $F8
	db $24, $08
	db $45, $F8
	db $24, $08
	db $39, $F8
	db $24, $08
	db $40, $F4
	db $3E, $F4
	db $3C, $F4
	db $3E, $F2
	db $24, $05
	db $3C, $F2
	db $3E, $F2
	db $40, $F7
	db $39, $F4
	db $3C, $F4
	db $3E, $F4
	db $40, $F6
	db $3C, $F4
	db $3B, $F4
	db $39, $F3
	db $38, $F0
	db $37, $F0
	db $36, $F0
	db $35, $F7
	db $24, $02
	db $39, $F4
	db $3C, $F4
	db $3E, $F4
	db $40, $F2
	db $41, $F2
	db $3E, $F2
	db $24, $05
	db $3E, $F2
	db $40, $F2
	db $3C, $F4
	db $3C, $F2
	db $3E, $F2
	db $3B, $F4
	db $3C, $F2
	db $3E, $F2
	db $40, $F4
	db $3E, $F4
	db $3C, $F4
	db $3E, $F2
	db $24, $05
	db $3C, $F2
	db $3E, $F2
	db $40, $F7
	db $39, $F4
	db $3C, $F4
	db $3E, $F4
	db $40, $F6
	db $3C, $F4
	db $3B, $F4
	db $39, $F3
	db $38, $F0
	db $37, $F0
	db $36, $F0
	db $35, $F7
	db $24, $02
	db $39, $F4
	db $3C, $F4
	db $3E, $F4
	db $40, $F2
	db $41, $F2
	db $3E, $F2
	db $24, $05
	db $3E, $F2
	db $40, $F2
	db $3C, $F4
	db $3C, $F2
	db $3E, $F2
	db $3B, $F2
	db $39, $F2
	db $3B, $F2
	db $3C, $F2
	db $3E, $F8
	db $3B, $F6
	db $3C, $F4
	db $3E, $F4
	db $3C, $F6
	db $3B, $F6
	db $39, $F6
	db $3B, $F4
	db $3C, $F4
	db $3B, $F7
	db $39, $F4
	db $38, $F6
	db $39, $F4
	db $3B, $F4
	db $39, $F6
	db $3B, $F6
	db $3C, $F6
	db $3E, $F4
	db $40, $F4
	db $41, $F7
	db $40, $F4
	db $3E, $F6
	db $40, $F4
	db $41, $F4
	db $40, $F6
	db $3C, $F6
	db $39, $F6
	db $35, $F6
	db $33, $FA
	db $34, $F8
	db $24, $04
	db $35, $F2
	db $37, $F2
	db $39, $F2
	db $3B, $F2
	db $3C, $F2
	db $3E, $F2
	db $40, $F4
	db $34, $F4
	db $3E, $F4
	db $34, $F4
	db $3C, $F8
	db $39, $F7
	db $34, $F8
	db $33, $FA
	db $34, $F8
	db $24, $04
	db $37, $F2
	db $34, $F2
	db $35, $F2
	db $37, $F2
	db $39, $F2
	db $3B, $F2
	db $3C, $F2
	db $3E, $F2
	db $40, $F4
	db $41, $F4
	db $3E, $F4
	db $3C, $F4
	db $38, $F6
	db $40, $F6
	db $3C, $F7
	db $39, $F8
	db $3E, $FA
	db $3B, $F8
	db $24, $04
	db $34, $F2
	db $35, $F2
	db $36, $F2
	db $38, $F2
	db $39, $F2
	db $3B, $F2
	db $3C, $F2
	db $3E, $F2
	db $3C, $F7
	db $3B, $F6
	db $3C, $F4
	db $39, $FA
	db $24, $06
	db $3C, $F7
	db $3B, $F4
	db $24, $04
	db $3C, $F4
	db $39, $FA
	db $24, $06
	db $3B, $F7
	db $39, $F6
	db $3B, $F4
	db $38, $FA
	db $24, $04
	db $3C, $F6
	db $24, $05
	db $39, $F2
	db $3B, $F2
	db $3C, $F2
	db $3E, $F5
	db $24, $04
	db $3B, $F2
	db $3C, $F2
	db $3E, $F2
	db $3C, $F6
	db $3B, $F6
	db $39, $F6
	db $34, $F6
	db $3C, $F7
	db $3B, $F6
	db $3C, $F4
	db $39, $FA
	db $24, $06
	db $3C, $F7
	db $3B, $F6
	db $3C, $F4
	db $39, $FA
	db $24, $06
	db $3B, $F7
	db $39, $F6
	db $3B, $F4
	db $38, $FA
	db $24, $04
	db $3C, $F7
	db $24, $02
	db $39, $F2
	db $3B, $F2
	db $3C, $F2
	db $3E, $F5
	db $24, $04
	db $3B, $F2
	db $3C, $F2
	db $3E, $F2
	db $3C, $F6
	db $3B, $F6
	db $39, $F6
	db $40, $F4
	db $40, $F1
	db $42, $F1
	db $44, $F1
	db $65
SongMacro09:
	db $24, $0A
	db $24, $0A
	db $24, $0A
	db $24, $0A
	db $24, $0A
	db $24, $0A
	db $24, $0A
	db $24, $0A
	db $24, $0A
	db $24, $0A
	db $24, $0A
	db $24, $0A
	db $3B, $F8
	db $38, $F6
	db $39, $F4
	db $3B, $F4
	db $39, $F6
	db $38, $F6
	db $34, $F6
	db $38, $F4
	db $39, $F4
	db $38, $F7
	db $35, $F4
	db $34, $F6
	db $36, $F4
	db $38, $F4
	db $34, $F6
	db $37, $F6
	db $39, $F6
	db $3B, $F4
	db $3C, $F4
	db $3E, $F7
	db $3C, $F4
	db $3B, $F6
	db $3C, $F4
	db $3E, $F4
	db $3C, $F6
	db $39, $F6
	db $35, $F6
	db $32, $F6
	db $30, $FA
	db $2F, $FA
	db $24, $0A
	db $24, $0A
	db $24, $0A
	db $24, $0A
	db $24, $0A
	db $24, $0A
	db $24, $0A
	db $24, $0A
	db $39, $F7
	db $38, $F6
	db $35, $F4
	db $34, $F8
	db $2D, $F6
	db $30, $F6
	db $34, $F6
	db $39, $F7
	db $37, $F6
	db $34, $F4
	db $35, $F8
	db $2D, $F6
	db $30, $F6
	db $33, $F6
	db $38, $F7
	db $35, $F6
	db $35, $F4
	db $34, $F8
	db $2C, $F6
	db $2F, $F6
	db $32, $F6
	db $30, $F4
	db $30, $F4
	db $30, $F4
	db $30, $F4
	db $2F, $F4
	db $2F, $F4
	db $2F, $F4
	db $2F, $F4
	db $2D, $F2
	db $24, $05
	db $28, $F2
	db $29, $F2
	db $2A, $F2
	db $2C, $F2
	db $2D, $F2
	db $24, $05
	db $2F, $F6
	db $39, $F7
	db $38, $F6
	db $35, $F4
	db $34, $F8
	db $2D, $F6
	db $30, $F6
	db $34, $F6
	db $39, $F7
	db $37, $F6
	db $34, $F4
	db $35, $F8
	db $2D, $F6
	db $30, $F6
	db $33, $F6
	db $38, $F7
	db $35, $F6
	db $35, $F4
	db $34, $F8
	db $2C, $F6
	db $2F, $F6
	db $32, $F6
	db $30, $F4
	db $30, $F4
	db $30, $F4
	db $30, $F4
	db $2F, $F4
	db $2F, $F4
	db $2F, $F4
	db $2F, $F4
	db $2D, $F2
	db $24, $05
	db $28, $F2
	db $29, $F2
	db $2A, $F2
	db $2C, $F2
	db $2D, $F2
	db $24, $05
	db $2F, $F6
	db $65
SongMacro0B:
	db $A1, $28
	db $24, $08
	db $95, $28
	db $24, $08
	db $A1, $28
	db $24, $08
	db $95, $28
	db $24, $08
	db $A1, $24
	db $24, $06
	db $9C, $26
	db $98, $24
	db $A1, $24
	db $24, $06
	db $9C, $26
	db $98, $24
	db $A1, $24
	db $A3, $22
	db $A1, $22
	db $9F, $24
	db $A1, $22
	db $9F, $22
	db $9D, $24
	db $24, $06
	db $98, $26
	db $95, $24
	db $9D, $24
	db $24, $06
	db $9C, $26
	db $A0, $24
	db $A3, $24
	db $A4, $22
	db $A6, $22
	db $A4, $24
	db $A3, $22
	db $A4, $22
	db $A1, $24
	db $24, $06
	db $9C, $26
	db $98, $24
	db $A1, $24
	db $24, $06
	db $9C, $26
	db $98, $24
	db $A1, $24
	db $A3, $22
	db $A1, $22
	db $9F, $24
	db $A1, $22
	db $9F, $22
	db $9D, $24
	db $24, $06
	db $98, $26
	db $95, $24
	db $9D, $24
	db $24, $06
	db $9C, $26
	db $A0, $24
	db $A3, $24
	db $A4, $22
	db $A6, $22
	db $A4, $24
	db $A3, $22
	db $A4, $22
	db $9D, $28
	db $9C, $26
	db $9E, $24
	db $A0, $24
	db $A1, $26
	db $A3, $26
	db $A4, $24
	db $A1, $24
	db $A0, $24
	db $9D, $24
	db $9C, $27
	db $9E, $24
	db $A0, $26
	db $A1, $24
	db $A3, $24
	db $A1, $26
	db $9F, $26
	db $9D, $26
	db $9C, $26
	db $9A, $28
	db $9C, $26
	db $9E, $24
	db $A0, $24
	db $A1, $26
	db $9F, $26
	db $9D, $26
	db $9C, $26
	db $9B, $27
	db $97, $24
	db $9B, $24
	db $9B, $26
	db $97, $24
	db $9C, $27
	db $97, $24
	db $9C, $24
	db $9C, $24
	db $9C, $24
	db $9C, $24
	db $A1, $24
	db $24, $06
	db $A1, $24
	db $9C, $24
	db $98, $24
	db $A1, $24
	db $24, $06
	db $A1, $24
	db $9C, $24
	db $98, $24
	db $A1, $26
	db $9F, $26
	db $9D, $24
	db $24, $06
	db $9D, $24
	db $98, $24
	db $95, $24
	db $9D, $24
	db $24, $06
	db $9C, $24
	db $97, $24
	db $94, $24
	db $9C, $26
	db $A0, $26
	db $9C, $24
	db $24, $06
	db $9C, $24
	db $97, $24
	db $94, $24
	db $9C, $24
	db $98, $24
	db $95, $24
	db $A1, $24
	db $9C, $24
	db $98, $24
	db $A1, $24
	db $9F, $24
	db $9D, $24
	db $9C, $24
	db $9A, $24
	db $24, $06
	db $A1, $24
	db $9D, $24
	db $9A, $24
	db $A1, $24
	db $9D, $24
	db $9C, $24
	db $A3, $24
	db $A0, $24
	db $9C, $24
	db $A4, $26
	db $A3, $26
	db $A1, $27
	db $9C, $26
	db $9C, $24
	db $A1, $29
	db $A1, $26
	db $9F, $26
	db $9D, $27
	db $98, $26
	db $98, $24
	db $9D, $29
	db $A1, $26
	db $9D, $26
	db $9C, $27
	db $97, $26
	db $97, $24
	db $9C, $29
	db $9E, $26
	db $A0, $26
	db $A1, $27
	db $A1, $24
	db $9C, $27
	db $9C, $24
	db $A1, $26
	db $9C, $26
	db $9E, $26
	db $A0, $26
	db $A1, $27
	db $A1, $24
	db $9C, $27
	db $9C, $24
	db $A1, $27
	db $A1, $24
	db $A1, $24
	db $A1, $24
	db $9F, $24
	db $9F, $24
	db $9D, $27
	db $9D, $24
	db $98, $27
	db $98, $24
	db $9D, $27
	db $9D, $24
	db $A1, $24
	db $A1, $24
	db $9D, $24
	db $9D, $24
	db $9C, $27
	db $9C, $24
	db $97, $27
	db $97, $24
	db $9C, $27
	db $9C, $24
	db $9E, $24
	db $9E, $24
	db $A0, $24
	db $A0, $24
	db $A1, $26
	db $A1, $26
	db $9C, $26
	db $9C, $26
	db $A1, $26
	db $9C, $26
	db $9E, $26
	db $A0, $26
	db $65
SongMacro0C:
	db $AD, $E4
	db $AD, $E2
	db $AD, $E2
	db $A8, $E4
	db $A8, $E4
	db $AD, $E4
	db $AD, $E4
	db $A8, $E2
	db $A8, $E2
	db $A8, $E4
	db $AD, $E4
	db $AD, $E2
	db $AD, $E2
	db $A8, $E4
	db $A8, $E4
	db $AD, $E4
	db $AD, $E4
	db $A8, $E2
	db $A8, $E2
	db $A8, $E4
	db $A9, $E4
	db $A9, $E2
	db $A9, $E2
	db $AD, $E4
	db $AD, $E4
	db $B0, $E4
	db $B0, $E4
	db $AD, $E2
	db $AD, $E2
	db $A9, $E4
	db $A8, $E4
	db $A8, $E2
	db $A8, $E2
	db $AC, $E4
	db $AC, $E4
	db $AF, $E4
	db $AF, $E4
	db $A8, $E2
	db $A8, $E2
	db $A8, $E4
	db $65
SongMacro0D:
	db $B9, $E4
	db $B9, $E4
	db $B9, $E4
	db $B4, $E6
	db $B4, $E2
	db $B4, $E2
	db $B9, $E4
	db $B4, $E2
	db $B4, $E2
	db $B0, $E4
	db $B0, $E2
	db $B0, $E2
	db $B4, $E4
	db $B4, $E2
	db $B4, $E2
	db $B9, $E4
	db $B9, $E2
	db $B9, $E2
	db $BC, $E4
	db $BC, $E2
	db $BC, $E2
	db $B5, $E4
	db $B5, $E4
	db $B5, $E4
	db $B0, $E6
	db $B0, $E2
	db $B0, $E2
	db $B5, $E4
	db $B0, $E2
	db $B0, $E2
	db $AD, $E4
	db $AD, $E2
	db $AD, $E2
	db $B0, $E4
	db $B0, $E2
	db $B0, $E2
	db $B3, $E4
	db $B3, $E2
	db $B3, $E2
	db $B5, $E4
	db $B5, $E2
	db $B5, $E2
	db $B4, $E4
	db $B4, $E4
	db $B4, $E4
	db $AF, $E6
	db $AF, $E2
	db $AF, $E2
	db $B4, $E4
	db $AF, $E2
	db $AF, $E2
	db $AA, $E4
	db $AA, $E2
	db $AA, $E2
	db $AF, $E4
	db $AF, $E2
	db $AF, $E2
	db $B4, $E4
	db $B4, $E2
	db $B4, $E2
	db $BB, $E4
	db $BB, $E2
	db $BB, $E2
	db $B9, $E2
	db $B9, $E2
	db $B9, $E6
	db $B9, $E2
	db $B9, $E2
	db $B4, $E2
	db $B4, $E2
	db $B4, $E6
	db $B4, $E2
	db $B4, $E2
	db $AD, $E4
	db $AD, $E2
	db $AD, $E2
	db $A8, $E4
	db $A8, $E2
	db $A8, $E2
	db $AD, $E4
	db $AD, $E2
	db $AD, $E2
	db $A8, $E4
	db $A8, $E2
	db $A8, $E2
	db $AD, $E4
	db $AD, $E4
	db $2A, $54
	db $AD, $E4
	db $A8, $E6
	db $2A, $54
	db $A8, $E4
	db $AD, $E6
	db $2A, $54
	db $A8, $E6
	db $A8, $E4
	db $2A, $54
	db $A8, $E4
	db $A9, $E4
	db $A9, $E4
	db $2A, $54
	db $A9, $E4
	db $A4, $E6
	db $2A, $54
	db $A4, $E4
	db $A9, $E6
	db $2A, $54
	db $A4, $E6
	db $A4, $E4
	db $2A, $54
	db $A9, $E4
	db $A8, $E4
	db $A8, $E4
	db $2A, $54
	db $A8, $E4
	db $A3, $E6
	db $2A, $54
	db $A3, $E4
	db $A8, $E6
	db $2A, $54
	db $A3, $E6
	db $A3, $E4
	db $2A, $54
	db $A8, $E4
	db $AD, $E4
	db $AD, $E2
	db $AD, $E2
	db $2A, $54
	db $AD, $E2
	db $AD, $E2
	db $A8, $E6
	db $2A, $54
	db $A8, $E2
	db $A8, $E2
	db $AD, $E4
	db $AD, $E2
	db $AD, $E2
	db $2A, $54
	db $A8, $E4
	db $2A, $54
	db $AD, $E2
	db $AD, $E2
	db $2A, $54
	db $A8, $E4
	db $65
SongMacro0E:
	db $24, $0A
	db $65
SongMacro08:
	db $45, $F4
	db $24, $07
	db $24, $08
	db $24, $0A
	db $24, $0A
	db $24, $0A
	db $40, $F4
	db $3E, $F4
	db $3C, $F4
	db $3E, $F2
	db $24, $05
	db $3C, $F2
	db $3E, $F2
	db $40, $F7
	db $39, $F4
	db $3C, $F4
	db $3E, $F4
	db $40, $F6
	db $3C, $F4
	db $3B, $F4
	db $39, $F3
	db $38, $F0
	db $37, $F0
	db $36, $F0
	db $35, $F7
	db $24, $02
	db $39, $F4
	db $3C, $F4
	db $3E, $F4
	db $40, $F2
	db $41, $F2
	db $3E, $F2
	db $24, $05
	db $3E, $F2
	db $40, $F2
	db $3C, $F4
	db $3C, $F2
	db $3E, $F2
	db $3B, $F4
	db $3C, $F2
	db $3E, $F2
	db $40, $F4
	db $3E, $F4
	db $3C, $F4
	db $3E, $F2
	db $24, $05
	db $3C, $F2
	db $3E, $F2
	db $40, $F7
	db $39, $F4
	db $3C, $F4
	db $3E, $F4
	db $40, $F6
	db $3C, $F4
	db $3B, $F4
	db $39, $F3
	db $38, $F0
	db $37, $F0
	db $36, $F0
	db $35, $F7
	db $24, $02
	db $39, $F4
	db $3C, $F4
	db $3E, $F4
	db $40, $F2
	db $41, $F2
	db $3E, $F2
	db $24, $05
	db $3E, $F2
	db $40, $F2
	db $3C, $F4
	db $3C, $F2
	db $3E, $F2
	db $3B, $F4
	db $3C, $F4
	db $3E, $F8
	db $3B, $F6
	db $3C, $F4
	db $3E, $F4
	db $3C, $F6
	db $3B, $F6
	db $39, $F6
	db $3B, $F4
	db $3C, $F4
	db $3B, $F7
	db $39, $F4
	db $38, $F6
	db $39, $F4
	db $3B, $F4
	db $39, $F6
	db $3B, $F6
	db $3C, $F6
	db $3E, $F4
	db $40, $F4
	db $41, $F7
	db $40, $F4
	db $3E, $F6
	db $40, $F4
	db $41, $F4
	db $40, $F6
	db $3C, $F6
	db $39, $F6
	db $35, $F6
	db $33, $FA
	db $34, $F8
	db $24, $04
	db $35, $F2
	db $37, $F2
	db $39, $F2
	db $3B, $F2
	db $3C, $F2
	db $3E, $F2
	db $40, $F4
	db $34, $F4
	db $3E, $F4
	db $34, $F4
	db $3C, $F8
	db $39, $F7
	db $34, $F8
	db $33, $FA
	db $34, $F8
	db $24, $04
	db $38, $F2
	db $34, $F2
	db $36, $F2
	db $38, $F2
	db $39, $F2
	db $3B, $F2
	db $3C, $F2
	db $3E, $F2
	db $40, $F4
	db $41, $F4
	db $3E, $F4
	db $3C, $F4
	db $38, $F6
	db $40, $F6
	db $3C, $F7
	db $39, $F8
	db $3E, $FA
	db $3B, $F8
	db $24, $04
	db $34, $F2
	db $35, $F2
	db $36, $F2
	db $38, $F2
	db $39, $F2
	db $3B, $F2
	db $3C, $F2
	db $3E, $F2
	db $3C, $F7
	db $3B, $F6
	db $3C, $F4
	db $39, $FA
	db $24, $06
	db $3C, $F7
	db $3B, $F6
	db $3C, $F4
	db $39, $FA
	db $24, $06
	db $3B, $F7
	db $39, $F4
	db $24, $04
	db $3B, $F4
	db $38, $FA
	db $24, $04
	db $3C, $F6
	db $24, $05
	db $39, $F2
	db $3B, $F2
	db $3C, $F2
	db $3E, $F5
	db $24, $04
	db $3B, $F2
	db $3C, $F2
	db $3E, $F2
	db $3C, $F6
	db $3B, $F6
	db $39, $F6
	db $34, $F6
	db $3C, $F7
	db $3B, $F6
	db $3C, $F4
	db $39, $FA
	db $24, $06
	db $3C, $F7
	db $3B, $F6
	db $3C, $F4
	db $39, $FA
	db $24, $06
	db $3B, $F7
	db $39, $F6
	db $3B, $F4
	db $38, $FA
	db $24, $04
	db $3C, $F6
	db $24, $05
	db $39, $F2
	db $3B, $F2
	db $3C, $F2
	db $3E, $F5
	db $24, $04
	db $3B, $F2
	db $3C, $F2
	db $3E, $F2
	db $3C, $F6
	db $3B, $F6
	db $39, $F6
	db $34, $F6
	db $65
SongMacro0A:
	db $24, $0A
	db $24, $0A
	db $24, $0A
	db $24, $0A
	db $45, $F4
	db $44, $F4
	db $40, $F4
	db $44, $F2
	db $24, $05
	db $40, $F2
	db $44, $F2
	db $45, $F7
	db $40, $F4
	db $45, $F4
	db $47, $F4
	db $48, $F6
	db $45, $F4
	db $44, $F4
	db $41, $F2
	db $24, $00
	db $40, $F0
	db $3F, $F0
	db $3E, $F0
	db $3C, $F7
	db $24, $02
	db $41, $F4
	db $45, $F4
	db $47, $F4
	db $48, $F2
	db $4A, $F2
	db $47, $F2
	db $24, $05
	db $47, $F2
	db $48, $F2
	db $45, $F2
	db $24, $02
	db $45, $F2
	db $47, $F2
	db $44, $F2
	db $24, $02
	db $45, $F2
	db $47, $F2
	db $45, $F4
	db $44, $F4
	db $40, $F4
	db $44, $F2
	db $24, $05
	db $40, $F2
	db $44, $F2
	db $45, $F7
	db $40, $F4
	db $45, $F4
	db $47, $F4
	db $48, $F6
	db $45, $F4
	db $44, $F4
	db $41, $F2
	db $24, $00
	db $40, $F0
	db $3F, $F0
	db $3E, $F0
	db $3C, $F7
	db $24, $02
	db $41, $F4
	db $45, $F4
	db $47, $F4
	db $48, $F2
	db $4A, $F2
	db $47, $F2
	db $24, $05
	db $47, $F2
	db $48, $F2
	db $45, $F2
	db $24, $02
	db $45, $F2
	db $47, $F2
	db $44, $F4
	db $40, $F4
	db $3B, $F8
	db $38, $F6
	db $39, $F4
	db $3B, $F4
	db $39, $F6
	db $38, $F6
	db $34, $F6
	db $38, $F4
	db $39, $F4
	db $38, $F7
	db $35, $F4
	db $34, $F6
	db $36, $F4
	db $38, $F4
	db $34, $F6
	db $37, $F6
	db $39, $F6
	db $3B, $F4
	db $3C, $F4
	db $3E, $F7
	db $3C, $F4
	db $3B, $F6
	db $3C, $F4
	db $3E, $F4
	db $3C, $F6
	db $39, $F6
	db $35, $F6
	db $32, $F6
	db $30, $FA
	db $2F, $FA
	db $30, $F4
	db $34, $F4
	db $39, $F4
	db $34, $F4
	db $38, $F4
	db $39, $F2
	db $24, $05
	db $34, $F2
	db $32, $F2
	db $30, $F4
	db $34, $F4
	db $39, $F4
	db $3B, $F4
	db $3C, $F6
	db $39, $F4
	db $3B, $F4
	db $39, $F2
	db $38, $F2
	db $39, $F2
	db $3B, $F2
	db $3C, $F2
	db $3B, $F2
	db $3C, $F2
	db $3E, $F2
	db $3F, $F2
	db $3E, $F2
	db $3C, $F2
	db $3B, $F2
	db $39, $F2
	db $3B, $F2
	db $3C, $F2
	db $3E, $F2
	db $3B, $F6
	db $38, $F6
	db $34, $F8
	db $3B, $F4
	db $3C, $F4
	db $39, $F4
	db $35, $F4
	db $34, $F4
	db $35, $F4
	db $38, $F4
	db $3B, $F4
	db $39, $F2
	db $38, $F2
	db $39, $F2
	db $3B, $F2
	db $3C, $F2
	db $3B, $F2
	db $3C, $F2
	db $3E, $F2
	db $40, $F4
	db $3C, $F4
	db $43, $F4
	db $42, $F4
	db $41, $F9
	db $24, $04
	db $40, $F6
	db $3E, $F2
	db $3C, $F2
	db $3B, $F2
	db $39, $F2
	db $37, $F2
	db $35, $F2
	db $34, $F8
	db $39, $F7
	db $38, $F4
	db $24, $04
	db $35, $F4
	db $34, $F8
	db $2D, $F6
	db $30, $F6
	db $34, $F6
	db $39, $F7
	db $37, $F4
	db $24, $04
	db $34, $F4
	db $35, $F8
	db $2D, $F6
	db $30, $F6
	db $33, $F6
	db $38, $F7
	db $35, $F4
	db $24, $04
	db $35, $F4
	db $34, $F8
	db $2C, $F6
	db $2F, $F6
	db $32, $F6
	db $30, $F4
	db $30, $F4
	db $30, $F4
	db $30, $F4
	db $2F, $F4
	db $2F, $F4
	db $2F, $F4
	db $2F, $F4
	db $2D, $F2
	db $24, $05
	db $28, $F2
	db $29, $F2
	db $2A, $F2
	db $2C, $F2
	db $2D, $F2
	db $24, $05
	db $2F, $F6
	db $39, $F7
	db $38, $F4
	db $24, $04
	db $35, $F4
	db $34, $F8
	db $2D, $F6
	db $30, $F6
	db $34, $F6
	db $39, $F7
	db $37, $F4
	db $24, $04
	db $34, $F4
	db $35, $F8
	db $2D, $F6
	db $30, $F6
	db $33, $F6
	db $38, $F7
	db $35, $F6
	db $35, $F4
	db $34, $F8
	db $2C, $F6
	db $2F, $F6
	db $32, $F6
	db $30, $F4
	db $30, $F4
	db $30, $F4
	db $30, $F4
	db $2F, $F4
	db $2F, $F4
	db $2F, $F4
	db $2F, $F4
	db $2D, $F2
	db $24, $05
	db $28, $F2
	db $29, $F2
	db $2A, $F2
	db $2C, $F2
	db $2D, $F4
	db $24, $04
	db $2F, $F6
	db $65
	
DoNotUseA:
	db $67, %11111111
	db $69, 255
	db $24, $00
	db $61
	db $64, $0F, -17, 1
	db $64, $10, -5, 1
	db $66, 1
	db $62
	dw DoNotUseA
DoNotUseB:
	db $24, $00
	db $61
	db $64, $11, -41, 1
	db $64, $11, -41, 4
	db $64, $12, -41, 1
	db $64, $11, -41, 3
	db $62
	dw DoNotUseB
DoNotUseC:
	db $24, $00
	db $61
	db $64, $13, -17, 1
	db $64, $14, -5, 3
	db $64, $15, -5, 1
	db $64, $14, -5, 3
	db $62
	dw DoNotUseC
DoNotUseD:
	db $24, $00
	db $61
	db $64, $16, 0, 1
	db $64, $17, 0, 16
	db $62
	dw DoNotUseD
SongMacro0F:
	db $65
SongMacro10:
SongMacro11:
SongMacro12:
SongMacro13:
SongMacro14:
SongMacro15:
SongMacro16:
SongMacro17:

OneJumpA:
	db $67, $FF
	db $69, $D2
	db $64, $18, -24, 1
	db $64, $1B, -24, 1
.OneJumpALoop
	db $69, $BE
	db $64, $1F, -24, 1
	db $69, $D2
	db $64, $23, -24, 1
	db $64, $1B, -23, 1
	db $69, $BE
	db $64, $1F, -23, 1
	db $69, $D2
	db $64, $1B, -24, 1
	db $66, $01
	db $62
	dw .OneJumpALoop
OneJumpB:
	db $64, $19, -24, 1
	db $64, $1C, -24, 1
.OneJumpBLoop
	db $64, $20, -24, 1
	db $64, $24, -24, 1
	db $64, $1C, -23, 1
;
	db $64, $20, -23, 1
	db $64, $1D, -24, 1
	db $62
	dw .OneJumpBLoop
OneJumpC:
	db $64, $1A, -12, $01
	db $64, $1D, -12, $01
.OneJumpCLoop
	db $64, $21, -12, $01
	db $64, $25, -12, $01
	db $64, $1D, -11, $01
	db $64, $21, -11, $01
	db $64, $1D, -12, $01
	db $62
	dw .OneJumpCLoop
OneJumpD:
	db $64, $0E, 0, 20
	db $64, $1E, 0, 8
.OneJumpDLoop
	db $64, $22, 0, 1
	db $64, $26, 0, 1
	db $64, $1E, 0, 8
	db $64, $22, 0, 1
	db $64, $1E, 0, 8
	db $62
	dw .OneJumpDLoop

SongMacro18:
	db $24, $0A
	db $24, $0A
	db $24, $0A
	db $24, $0A
	db $2F, $C6
	db $30, $C4
	db $2F, $C4
	db $30, $C6
	db $33, $C6
	db $34, $C6
	db $33, $C6
	db $30, $C6
	db $33, $C6
	db $2F, $C7
	db $2F, $CB
	db $24, $04
	db $2F, $C6
	db $30, $C4
	db $2F, $C4
	db $30, $C6
	db $33, $C6
	db $34, $C6
	db $33, $C6
	db $30, $C6
	db $33, $C6
	db $2F, $CC
	db $32, $C6
	db $33, $C4
	db $32, $C4
	db $33, $C6
	db $36, $C6
	db $37, $C6
	db $36, $C6
	db $33, $C6
	db $36, $C6
	db $32, $C7
	db $32, $CB
	db $24, $04
	db $36, $C4
	db $24, $04
	db $24, $08
	db $34, $C6
	db $33, $C4
	db $24, $04
	db $24, $08
	db $30, $C6
	db $2F, $C4
	db $24, $04
	db $24, $08
	db $34, $C6
	db $33, $C4
	db $24, $06
	db $47, $F6
	db $24, $07
	db $65
SongMacro19:
	db $28, $F6
	db $2F, $F4
	db $2F, $F4
	db $28, $F6
	db $2F, $F4
	db $2F, $F4
	db $28, $F6
	db $2F, $F6
	db $30, $F6
	db $2F, $F6
	db $28, $F6
	db $2F, $F4
	db $2F, $F4
	db $28, $F6
	db $2F, $F4
	db $2F, $F4
	db $28, $F6
	db $2F, $F6
	db $30, $F6
	db $2F, $F6
	db $28, $F6
	db $2F, $F4
	db $2F, $F4
	db $28, $F6
	db $2F, $F4
	db $2F, $F4
	db $28, $F6
	db $2F, $F6
	db $30, $F6
	db $2F, $F6
	db $28, $F6
	db $2F, $F4
	db $2F, $F4
	db $28, $F6
	db $2F, $F4
	db $2F, $F4
	db $43, $F4
	db $42, $F4
	db $41, $F4
	db $40, $F4
	db $3F, $F4
	db $3E, $F4
	db $3D, $F4
	db $3C, $F4
	db $3B, $F4
	db $24, $04
	db $2F, $F4
	db $2F, $F4
	db $28, $F6
	db $2F, $F4
	db $2F, $F4
	db $28, $F6
	db $2F, $F6
	db $30, $F6
	db $2F, $F6
	db $43, $F4
	db $42, $F4
	db $41, $F4
	db $40, $F4
	db $3F, $F4
	db $3E, $F4
	db $3D, $F4
	db $3C, $F4
	db $3B, $F4
	db $3A, $F4
	db $39, $F4
	db $38, $F4
	db $37, $F4
	db $36, $F4
	db $34, $F4
	db $33, $F4
	db $32, $F6
	db $32, $F4
	db $32, $F4
	db $2B, $F6
	db $32, $F4
	db $32, $F4
	db $2B, $F6
	db $32, $F6
	db $33, $F6
	db $32, $F6
	db $2B, $F6
	db $32, $F4
	db $32, $F4
	db $2B, $F6
	db $32, $F4
	db $32, $F4
	db $43, $F6
	db $42, $F6
	db $41, $F6
	db $40, $F6
	db $3F, $F4
	db $24, $07
	db $24, $08
	db $24, $09
	db $34, $F6
	db $33, $F4
	db $24, $07
	db $24, $06
	db $43, $F6
	db $42, $F4
	db $24, $07
	db $3B, $F4
	db $2F, $F4
	db $2F, $F6
	db $65
SongMacro1A:
	db $9C, $06
	db $A3, $04
	db $A3, $04
	db $9C, $06
	db $A3, $04
	db $A3, $04
	db $9C, $06
	db $A3, $06
	db $A4, $06
	db $A3, $06
	db $9C, $06
	db $A3, $04
	db $A3, $04
	db $9C, $06
	db $A3, $04
	db $A3, $04
	db $9C, $06
	db $A3, $06
	db $A4, $06
	db $A3, $06
	db $9C, $06
	db $A3, $04
	db $A3, $04
	db $9C, $06
	db $A3, $04
	db $A3, $04
	db $9C, $06
	db $A3, $06
	db $A4, $06
	db $A3, $06
	db $9C, $06
	db $A3, $04
	db $A3, $04
	db $9C, $06
	db $A3, $04
	db $A3, $04
	db $9C, $06
	db $A3, $06
	db $A4, $06
	db $A3, $06
	db $9C, $06
	db $A3, $04
	db $A3, $04
	db $9C, $06
	db $A3, $04
	db $A3, $04
	db $9C, $06
	db $A3, $06
	db $A4, $06
	db $A3, $06
	db $9C, $06
	db $A3, $04
	db $A3, $04
	db $9C, $06
	db $A3, $04
	db $A3, $04
	db $9C, $06
	db $A3, $06
	db $A4, $06
	db $A3, $06
	db $9F, $06
	db $A6, $04
	db $A6, $04
	db $9F, $06
	db $A6, $04
	db $A6, $04
	db $9F, $06
	db $A6, $06
	db $A7, $06
	db $A6, $06
	db $9F, $06
	db $A6, $04
	db $A6, $04
	db $9F, $06
	db $A6, $04
	db $A6, $04
	db $9F, $06
	db $A6, $06
	db $A7, $06
	db $A6, $06
	db $A3, $04
	db $24, $07
	db $24, $06
	db $A4, $06
	db $A3, $04
	db $24, $07
	db $24, $06
	db $A4, $06
	db $A3, $04
	db $24, $07
	db $24, $06
	db $A4, $06
	db $A3, $06
	db $24, $09
	db $65
SongMacro1B:
	db $37, $F6
	db $3B, $F6
	db $34, $F6
	db $24, $04
	db $2F, $F4
	db $37, $F4
	db $37, $F4
	db $37, $F4
	db $37, $F4
	db $24, $04
	db $36, $F7
	db $37, $F6
	db $3B, $F6
	db $34, $F6
	db $24, $04
	db $2F, $F4
	db $37, $F4
	db $37, $F4
	db $37, $F4
	db $37, $F8
	db $24, $04
	db $3B, $F6
	db $3E, $F6
	db $37, $F6
	db $24, $06
	db $3A, $F4
	db $3A, $F4
	db $3A, $F4
	db $3A, $F4
	db $3A, $F6
	db $39, $F4
	db $37, $F7
	db $24, $07
	db $2F, $F4
	db $3B, $F4
	db $24, $04
	db $3B, $F4
	db $2F, $F4
	db $2F, $F6
	db $35, $F4
	db $24, $04
	db $36, $F4
	db $24, $07
	db $3B, $F6
	db $34, $F6
	db $24, $04
	db $2F, $F4
	db $37, $F4
	db $37, $F4
	db $37, $F4
	db $37, $F4
	db $24, $04
	db $36, $F7
	db $24, $06
	db $3B, $F6
	db $34, $F6
	db $24, $04
	db $34, $F4
	db $37, $F4
	db $37, $F6
	db $37, $F7
	db $43, $F4
	db $24, $07
	db $3E, $F6
	db $37, $F6
	db $24, $06
	db $3A, $F4
	db $3A, $F4
	db $3A, $F4
	db $3A, $F4
	db $3A, $F4
	db $39, $F6
	db $37, $F6
	db $43, $F6
	db $40, $F4
	db $3E, $F2
	db $40, $F2
	db $3E, $F4
	db $3C, $F4
	db $3A, $F4
	db $3B, $F4
	db $3E, $F4
	db $3B, $F4
	db $3A, $F4
	db $39, $F4
	db $37, $F4
	db $34, $F4
	db $32, $F4
	db $65
SongMacro1C:
	db $34, $F6
	db $47, $F6
	db $40, $F6
	db $24, $06
	db $30, $F6
	db $24, $09
	db $34, $F6
	db $47, $F6
	db $40, $F6
	db $24, $06
	db $31, $F6
	db $24, $09
	db $32, $F6
	db $24, $09
	db $33, $F6
	db $24, $09
	db $24, $06
	db $2F, $F6
	db $30, $F6
	db $32, $F6
	db $33, $F6
	db $34, $F6
	db $35, $F6
	db $36, $F6
	db $2F, $FA
	db $2E, $F9
	db $2D, $F6
	db $2F, $FA
	db $31, $FA
	db $32, $FA
	db $31, $F9
	db $30, $F6
	db $2F, $F8
	db $30, $F8
	db $31, $F8
	db $32, $F8
	db $65
SongMacro1D:
	db $A8, $18
	db $A3, $18
	db $A4, $18
	db $A3, $18
	db $A8, $18
	db $A3, $18
	db $A1, $18
	db $A1, $18
	db $9A, $18
	db $9A, $18
	db $9B, $18
	db $9A, $18
	db $9F, $16
	db $9A, $16
	db $9C, $16
	db $9E, $16
	db $9F, $16
	db $A0, $16
	db $A2, $16
	db $A3, $16
	db $A8, $18
	db $A3, $18
	db $A4, $18
	db $A3, $18
	db $A8, $18
	db $A3, $18
	db $A1, $18
	db $A1, $18
	db $9A, $18
	db $9A, $18
	db $9B, $18
	db $9A, $18
	db $9F, $18
	db $A1, $18
	db $A2, $18
	db $A3, $18
	db $65
SongMacro1E:
	db $22, $56
	db $22, $5E
	db $22, $5D
	db $22, $56
	db $22, $5E
	db $22, $5D
	db $22, $56
	db $22, $5E
	db $22, $5D
	db $22, $56
	db $22, $5E
	db $22, $5D
	db $65
SongMacro1F:
	db $34, $F7
	db $32, $F7
	db $24, $06
	db $4C, $F7
	db $4A, $F7
	db $24, $06
	db $34, $F7
	db $32, $F7
	db $24, $06
	db $4C, $F7
	db $4A, $F7
	db $24, $06
	db $34, $F7
	db $32, $F7
	db $24, $06
	db $3B, $F7
	db $39, $F7
	db $24, $06
	db $3C, $F8
	db $3B, $FB
	db $34, $F8
	db $36, $F8
	db $39, $F8
	db $39, $F8
	db $36, $F8
	db $34, $F8
	db $33, $F8
	db $34, $F8
	db $34, $F4
	db $34, $F4
	db $34, $F4
	db $36, $F4
	db $37, $F6
	db $34, $F4
	db $34, $F4
	db $34, $F4
	db $36, $F4
	db $37, $F6
	db $3A, $F4
	db $24, $07
	db $34, $F4
	db $36, $F4
	db $36, $F4
	db $36, $F4
	db $38, $F6
	db $3A, $F5
	db $3B, $F7
	db $24, $02
	db $3B, $F2
	db $3F, $F2
	db $47, $F6
	db $24, $06
	db $65
SongMacro20:
	db $30, $F7
	db $30, $F7
	db $24, $06
	db $3B, $F7
	db $39, $F7
	db $24, $06
	db $2F, $F7
	db $2F, $F7
	db $24, $06
	db $39, $F7
	db $37, $F7
	db $24, $06
	db $30, $F8
	db $30, $F8
	db $37, $F8
	db $36, $F8
	db $39, $FA
	db $37, $FA
	db $3B, $F8
	db $39, $F8
	db $3C, $F8
	db $3B, $F8
	db $39, $F8
	db $37, $F8
	db $36, $F8
	db $37, $F8
	db $2E, $F4
	db $24, $07
	db $24, $06
	db $2E, $F4
	db $24, $04
	db $24, $08
	db $34, $F4
	db $24, $07
	db $2E, $F4
	db $24, $07
	db $24, $08
	db $36, $F6
	db $24, $09
	db $65
SongMacro21:
	db $A6, $17
	db $A6, $14
	db $24, $08
	db $A6, $17
	db $A6, $14
	db $24, $08
	db $A6, $17
	db $A6, $14
	db $24, $08
	db $A6, $17
	db $A6, $14
	db $24, $08
	db $9A, $1A
	db $9A, $1A
	db $9F, $1C
	db $9E, $1A
	db $97, $1A
	db $9C, $1A
	db $9A, $1A
	db $A4, $16
	db $24, $08
	db $98, $16
	db $24, $08
	db $A4, $16
	db $24, $06
	db $9E, $16
	db $24, $09
	db $97, $16
	db $24, $09
	db $65
SongMacro22:
	db $20, $46
	db $22, $57
	db $22, $57
	db $20, $47
	db $22, $57
	db $22, $56
	db $20, $47
	db $22, $57
	db $22, $56
	db $20, $47
	db $22, $57
	db $22, $56
	db $22, $5A
	db $22, $5A
	db $22, $5A
	db $22, $5A
	db $22, $58
	db $20, $48
	db $20, $48
	db $20, $46
	db $20, $46
	db $20, $48
	db $20, $46
	db $20, $46
	db $20, $48
	db $20, $48
	db $22, $56
	db $22, $58
	db $22, $56
	db $22, $58
	db $22, $56
	db $22, $56
	db $22, $58
	db $22, $56
	db $22, $56
	db $22, $58
	db $20, $48
	db $65
SongMacro23:
	db $3B, $F6
	db $3B, $F6
	db $3D, $F6
	db $3F, $F6
	db $40, $F6
	db $3F, $F6
	db $3D, $F6
	db $3F, $F6
	db $3B, $F7
	db $3B, $F8
	db $24, $04
	db $2E, $F7
	db $2D, $F8
	db $24, $07
	db $3B, $F6
	db $3D, $F6
	db $3F, $F6
	db $40, $F6
	db $3F, $F6
	db $3D, $F6
	db $3F, $F6
	db $3B, $F7
	db $2F, $F2
	db $2F, $F2
	db $3B, $F6
	db $24, $04
	db $2F, $F2
	db $2F, $F2
	db $3B, $F6
	db $24, $04
	db $2F, $F2
	db $2F, $F2
	db $3B, $F7
	db $24, $04
	db $2D, $F6
	db $2D, $F6
	db $2F, $F4
	db $2F, $F4
	db $31, $F6
	db $32, $F6
	db $31, $F6
	db $2F, $F6
	db $31, $F6
	db $2D, $F7
	db $2D, $FB
	db $24, $04
	db $3A, $F4
	db $3A, $F4
	db $3A, $F6
	db $3A, $F4
	db $3A, $F4
	db $3A, $F4
	db $3A, $F4
	db $3A, $F4
	db $3A, $F4
	db $3A, $F6
	db $3A, $F4
	db $3A, $F4
	db $3A, $F4
	db $3A, $F4
	db $3B, $F4
	db $3B, $F4
	db $3B, $F4
	db $3B, $F4
	db $3B, $F6
	db $3B, $F6
	db $3C, $FA
	db $65
SongMacro24:
	db $24, $0A
	db $24, $0A
	db $24, $0A
	db $28, $F7
	db $27, $F8
	db $24, $04
	db $24, $0A
	db $24, $0A
	db $31, $F8
	db $32, $F8
	db $33, $F8
	db $34, $F8
	db $39, $F6
	db $39, $F6
	db $3B, $F4
	db $3B, $F4
	db $3D, $F6
	db $3E, $F6
	db $3D, $F6
	db $3B, $F6
	db $3D, $F6
	db $39, $F7
	db $39, $FB
	db $24, $04
	db $36, $F4
	db $24, $07
	db $24, $06
	db $36, $F4
	db $24, $04
	db $24, $08
	db $36, $F8
	db $3B, $F4
	db $24, $07
	db $24, $06
	db $3B, $F6
	db $3A, $F6
	db $24, $09
	db $65
SongMacro25:
	db $A8, $18
	db $A3, $18
	db $A8, $18
	db $A3, $18
	db $A8, $18
	db $A3, $18
	db $A4, $17
	db $A3, $18
	db $24, $04
	db $A8, $18
	db $A3, $18
	db $A8, $18
	db $A3, $18
	db $A8, $18
	db $A3, $18
	db $A1, $18
	db $A3, $18
	db $A4, $18
	db $A5, $18
	db $A6, $18
	db $A1, $18
	db $A6, $18
	db $A1, $18
	db $A6, $18
	db $A1, $18
	db $9E, $16
	db $24, $08
	db $9E, $16
	db $24, $08
	db $9E, $16
	db $24, $06
	db $A3, $16
	db $24, $08
	db $A3, $16
	db $A4, $16
	db $24, $07
	db $A3, $14
	db $A4, $16
	db $65
SongMacro26:
	db $20, $46
	db $22, $5E
	db $20, $4D
	db $20, $46
	db $22, $5E
	db $20, $4D
	db $20, $46
	db $22, $5E
	db $20, $4D
	db $20, $46
	db $22, $5E
	db $20, $4D
	db $20, $46
	db $22, $5E
	db $20, $4D
	db $20, $46
	db $22, $5E
	db $20, $4D
	db $20, $46
	db $22, $5E
	db $20, $4D
	db $20, $46
	db $22, $5E
	db $20, $4D
	db $20, $46
	db $22, $5E
	db $20, $4D
	db $20, $46
	db $22, $5E
	db $20, $4D
	db $20, $46
	db $22, $5E
	db $20, $4D
	db $20, $46
	db $22, $56
	db $20, $46
	db $22, $5E
	db $20, $4D
	db $20, $46
	db $22, $5E
	db $20, $4D
	db $20, $46
	db $22, $5E
	db $20, $4D
	db $20, $46
	db $22, $5E
	db $20, $4D
	db $20, $46
	db $22, $5E
	db $20, $4D
	db $20, $46
	db $22, $5E
	db $20, $4D
	db $20, $46
	db $22, $5E
	db $20, $4D
	db $20, $46
	db $22, $5E
	db $22, $5D
	db $20, $46
	db $20, $4E
	db $22, $5D
	db $20, $4E
	db $20, $46
	db $22, $56
	db $22, $56
	db $20, $4D
	db $20, $46
	db $20, $46
	db $22, $56
	db $22, $5E
	db $22, $5D
	db $22, $56
	db $22, $5E
	db $20, $4D
	db $20, $46
	db $22, $5E
	db $22, $5D
	db $22, $56
	db $20, $46
	db $22, $56
	db $20, $4D
	db $20, $4E
	db $20, $4D
	db $22, $5E
	db $20, $4E
	db $20, $46
	db $22, $5D
	db $20, $4E
	db $22, $5D
	db $20, $4E
	db $22, $5D
	db $22, $56
	db $65

NewWorldA:
	db $67, %11111111
	db $69, 230
	db $64, $27, -29, 1
	db $64, $28, -29, 1
	db $64, $29, -29, 1
	db $66, 1
	db $62
	dw NewWorldA
NewWorldB:
	db $64, $2A, -29, 2
	db $64, $2B, -29, 2
	db $62
	dw NewWorldB
NewWorldC:
	db $64, $2C, -5, 2
	db $64, $2D, -5, 2
	db $62
	dw NewWorldC
NewWorldD:
	db $64, $2E, 0, 9
	db $62
	dw NewWorldD
	
SongMacro27:
	db $42, $C6
	db $40, $C4
	db $43, $C6
	db $42, $C4
	db $3E, $C6
	db $39, $CA
	db $42, $C6
	db $40, $C4
	db $43, $C6
	db $42, $C4
	db $3E, $C6
	db $42, $C8
	db $40, $C8
	db $40, $C6
	db $3F, $C4
	db $42, $C6
	db $40, $C4
	db $3D, $C6
	db $40, $C7
	db $3E, $C4
	db $3D, $C6
	db $3E, $C6
	db $3B, $C8
	db $3B, $C4
	db $3D, $C6
	db $3E, $C4
	db $39, $CA
	db $65
SongMacro28:
	db $42, $C6
	db $40, $C4
	db $43, $C6
	db $42, $C4
	db $3E, $C6
	db $39, $CA
	db $42, $C6
	db $40, $C4
	db $43, $C6
	db $42, $C4
	db $3E, $C6
	db $42, $C8
	db $40, $C8
	db $40, $C6
	db $3F, $C4
	db $42, $C6
	db $40, $C4
	db $3D, $C6
	db $40, $C6
	db $3E, $C6
	db $3D, $C6
	db $3E, $C6
	db $3B, $C6
	db $3D, $C4
	db $3E, $C6
	db $3B, $C7
	db $42, $C7
	db $42, $C4
	db $43, $C6
	db $47, $C6
	db $65
SongMacro2A:
	db $2A, $E4
	db $2D, $E4
	db $32, $E4
	db $2A, $E4
	db $2D, $E4
	db $32, $E4
	db $2A, $E4
	db $2D, $E4
	db $32, $E4
	db $2A, $E4
	db $2D, $E4
	db $32, $E4
	db $2A, $E4
	db $2D, $E4
	db $32, $E4
	db $2A, $E4
	db $2D, $E4
	db $32, $E4
	db $2A, $E4
	db $2D, $E4
	db $32, $E4
	db $2A, $E4
	db $2D, $E4
	db $32, $E4
	db $2B, $E4
	db $2F, $E4
	db $32, $E4
	db $2B, $E4
	db $28, $E4
	db $2D, $E4
	db $31, $E4
	db $2D, $E4
	db $28, $E4
	db $2B, $E4
	db $2F, $E4
	db $34, $E4
	db $2B, $E4
	db $2F, $E4
	db $34, $E4
	db $2B, $E4
	db $32, $E4
	db $2A, $E4
	db $2F, $E4
	db $32, $E4
	db $2A, $E4
	db $2F, $E4
	db $32, $E4
	db $2A, $E4
	db $2B, $E4
	db $2F, $E4
	db $32, $E4
	db $2B, $E4
	db $2F, $E4
	db $32, $E4
	db $2B, $E4
	db $2F, $E4
	db $28, $E4
	db $2D, $E4
	db $31, $E4
	db $28, $E4
	db $2D, $E4
	db $31, $E4
	db $28, $E4
	db $2D, $E4
	db $65
SongMacro2C:
	db $9A, $29
	db $24, $04
	db $95, $24
	db $9A, $29
	db $24, $04
	db $95, $24
	db $9A, $29
	db $24, $04
	db $9A, $24
	db $93, $28
	db $95, $28
	db $90, $29
	db $24, $04
	db $90, $24
	db $97, $29
	db $24, $04
	db $97, $24
	db $93, $29
	db $24, $04
	db $9A, $24
	db $95, $29
	db $99, $26
	db $65
SongMacro2E:
	db $1E, $34
	db $1E, $34
	db $1E, $34
	db $1E, $34
	db $1E, $34
	db $1E, $34
	db $1E, $34
	db $22, $54
	db $65
SongMacro29:
	db $45, $CA
	db $24, $07
	db $42, $C4
	db $43, $C6
	db $47, $C6
	db $45, $C6
	db $42, $C4
	db $43, $C6
	db $42, $C4
	db $40, $C6
	db $3E, $C8
	db $42, $C4
	db $43, $C6
	db $45, $C4
	db $49, $C6
	db $47, $C4
	db $45, $C8
	db $3E, $C4
	db $49, $C6
	db $4A, $C4
	db $45, $C8
	db $42, $C4
	db $42, $C6
	db $40, $C6
	db $3E, $C6
	db $42, $C6
	db $45, $C7
	db $42, $C4
	db $43, $C6
	db $47, $C6
	db $45, $CA
	db $24, $07
	db $42, $C4
	db $43, $C6
	db $47, $C6
	db $45, $C6
	db $42, $C4
	db $43, $C6
	db $42, $C4
	db $40, $C6
	db $42, $C8
	db $42, $C4
	db $43, $C6
	db $45, $C4
	db $49, $C6
	db $4A, $C6
	db $45, $C7
	db $3E, $C4
	db $49, $C6
	db $4A, $C4
	db $45, $C8
	db $42, $C4
	db $42, $C6
	db $40, $C6
	db $3E, $C6
	db $40, $C6
	db $43, $C6
	db $42, $C6
	db $3E, $C6
	db $40, $C6
	db $65
SongMacro2B:
	db $32, $E4
	db $2A, $E4
	db $2D, $E4
	db $32, $E4
	db $2A, $E4
	db $2D, $E4
	db $32, $E4
	db $2A, $E4
	db $2D, $E4
	db $32, $E4
	db $2A, $E4
	db $2D, $E4
	db $34, $E4
	db $2B, $E4
	db $2F, $E4
	db $34, $E4
	db $32, $E4
	db $2A, $E4
	db $2D, $E4
	db $32, $E4
	db $32, $E4
	db $2B, $E4
	db $2F, $E4
	db $32, $E4
	db $2A, $E4
	db $2F, $E4
	db $32, $E4
	db $2A, $E4
	db $2F, $E4
	db $32, $E4
	db $2A, $E4
	db $2F, $E4
	db $32, $E4
	db $2B, $E4
	db $2F, $E4
	db $32, $E4
	db $2A, $E4
	db $2D, $E4
	db $32, $E4
	db $2A, $E4
	db $2B, $E4
	db $2F, $E4
	db $32, $E4
	db $2B, $E4
	db $2A, $E4
	db $2D, $E4
	db $32, $E4
	db $2A, $E4
	db $28, $E4
	db $2B, $E4
	db $2F, $E4
	db $28, $E4
	db $2B, $E4
	db $2F, $E4
	db $28, $E4
	db $2B, $E4
	db $31, $E4
	db $28, $E4
	db $2D, $E4
	db $31, $E4
	db $28, $E4
	db $2D, $E4
	db $31, $E4
	db $28, $E4
	db $65
SongMacro2D:
	db $9A, $2A
	db $9A, $28
	db $9C, $28
	db $9E, $28
	db $9F, $28
	db $97, $2A
	db $9F, $28
	db $9E, $28
	db $9F, $28
	db $9E, $28
	db $9C, $2A
	db $95, $2A
	db $65
	
LevCompleteA:
	db $67, %11111111
	db $69, 220
	db $64, $2F, -12, 1
	db $66, 1
	db $61
LevCompleteB:
	db $64, $30, -24, 1
	db $61
LevCompleteC:
	db $64, $31, -12, 1
	db $61
LevCompleteD:
	db $61

SongMacro2F:
	db $2E, $B4
	db $2E, $B4
	db $35, $B6
	db $33, $B2
	db $35, $B2
	db $33, $B4
	db $31, $B5
	db $30, $B4
	db $31, $B2
	db $30, $B4
	db $2E, $B4
	db $30, $B2
	db $31, $B2
	db $33, $B2
	db $35, $B2
	db $37, $B2
	db $39, $B2
	db $3A, $B6
	db $24, $00
	db $65
SongMacro30:
	db $24, $07
	db $31, $A6
	db $31, $A6
	db $31, $A6
	db $30, $A6
	db $31, $A6
	db $30, $A6
	db $31, $A4
	db $31, $A6
	db $24, $00
	db $65
SongMacro31:
	db $24, $06
	db $A2, $14
	db $AE, $14
	db $9D, $14
	db $AE, $14
	db $A2, $14
	db $AE, $14
	db $9D, $14
	db $AD, $14
	db $A2, $14
	db $AE, $14
	db $9D, $14
	db $AD, $14
	db $A2, $14
	db $AE, $14
	db $AE, $16
	db $24, $00
	db $65
	
EmptyA:
EmptyB:
EmptyC:
EmptyD:
	db $24, $01
	db $61
	
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
	
SFXMacroTab:
	dw SFXMacro00
	dw SFXMacro01
	dw SFXMacro02
	dw SFXMacro03
	dw SFXMacro04
	dw SFXMacro05
	dw SFXMacro06
	dw SFXMacro07
	dw SFXMacro08
	dw SFXMacro09
	dw SFXMacro0A
	dw SFXMacro0B
	dw SFXMacro0C
	dw SFXMacro0D
	dw SFXMacro0E
	dw SFXMacro0F
	dw SFXMacro10
	dw SFXMacro11
	dw SFXMacro12
	dw SFXMacro13
	dw SFXMacro14
	dw SFXMacro15
	dw SFXMacro16
	dw SFXMacro17
	dw SFXMacro18
	dw SFXMacro19
	dw SFXMacro1A
	dw SFXMacro1B
	dw SFXMacro1C
	dw SFXMacro1D
	dw SFXMacro1E
	dw SFXMacro1F
	dw SFXMacro20
	dw SFXMacro21
	dw SFXMacro22
	dw SFXMacro23
	dw SFXMacro24
	dw SFXMacro25
	dw SFXMacro26
	dw SFXMacro27
	dw SFXMacro28
	dw SFXMacro29
	dw SFXMacro2A
	dw SFXMacro2B
	dw SFXMacro2C
	dw SFXMacro2D
	dw SFXMacro2E
	dw SFXMacro2F
	dw SFXMacro30
	dw SFXMacro31
	dw SFXMacro32
	dw SFXMacro33
	dw SFXMacro34
	dw SFXMacro35
	dw SFXMacro36
	dw SFXMacro37
	dw SFXMacro38
	dw SFXMacro39
	dw SFXMacro3A
	dw SFXMacro3B
	dw SFXMacro3C
	dw SFXMacro3D
	dw SFXMacro3E
	dw SFXMacro3F
	dw SFXMacro40
	dw SFXMacro41
	dw SFXMacro42
	dw SFXMacro43
	dw SFXMacro44
	dw SFXMacro45
	dw SFXMacro46
	
SFXTab:
.HighSword
	db $00, $FF, $FF, $FF
.LowSword
	db $01, $FF, $FF, $FF
.ObjectThrow
	db $02, $FF, $FF, $FF
.MenuSelect
	db $03, $FF, $FF, $FF
.Flagpole
	db $04, $05, $FF, $FF
.MenuChange
	db $06, $FF, $FF, $FF
.HeadBop
	db $07, $08, $FF, $FF
.DoNotUse07
	db $09, $FF, $FF, $FF
.CloudPoof
	db $0A, $FF, $FF, $FF
.AppleCollect
	db $0B, $FF, $FF, $FF
.AppleSlice
	db $0D, $FF, $FF, $FF
.GemCollect
	db $0F, $FF, $FF, $FF
.ScarabWow
	db $11, $12, $13, $FF
.DoNotUse0D
	db $14, $FF, $FF, $FF
.SwordSpinning
	db $15, $FF, $FF, $FF
.SwordChing
	db $16, $17, $FF, $FF
.AppleSplat
	db $18, $FF, $FF, $FF
.RopeLaunch
	db $19, $FF, $FF, $FF
.DoNotUse12
	db $1A, $FF, $FF, $FF
.DoNotUse13
	db $1B, $1C, $FF, $FF
.IagoSquawk
	db $1D, $1E, $FF, $FF
.Skeleton
	db $1F, $20, $FF, $FF
.ClayPot
	db $21, $FF, $FF, $FF
.DoNotUse17
	db $22, $23, $FF, $FF
.Splash
	db $24, $FF, $FF, $FF
.DoNotUse19
	db $25, $26, $FF, $FF
.Geyser
	db $27, $FF, $FF, $FF
.DoNotUse1B
	db $28, $FF, $FF, $FF
.CashRegister
	db $29, $2A, $2B, $FF
.Honk
	db $2C, $2D, $FF, $FF
.FireFromCoal
	db $2E, $FF, $FF, $FF
.WallSpikes
	db $2F, $FF, $FF, $FF
.DoNotUse20
	db $30, $31, $FF, $FF
.DoNotUse21
	db $32, $FF, $FF, $FF
.RockBounce
	db $33, $34, $35, $FF
.OuttaApples
	db $36, $FF, $FF, $FF
.Earthquake
	db $37, $FF, $FF, $FF
.DoNotUse25
	db $38, $FF, $FF, $FF
.WinABonus
	db $39, $FF, $FF, $FF
.DoNotUse27
	db $44, $FF, $FF, $FF
.DoNotUse28
	db $3A, $33, $34, $FF
.ExtraHealth
	db $3B, $FF, $FF, $FF
.ScarabPickup
	db $3C, $3D, $3E, $FF
.FlutePickup
	db $3F, $40, $FF, $FF
.ContinuePoint
	db $41, $42, $FF, $FF
.SilentLamb
	db $43, $44, $45, $46
	
SFXMacro00:
	db 3
	db 1, $00, $60, $80, $44
	db 1, $00, $A0, $80, $33
	db 1, $00, $C0, $80, $24
	db 1, $00, $F0, $80, $21
	db 1, $00, $C0, $80, $14
	db 1, $00, $80, $80, $04
	db 1, $00, $40, $80, $07
	db 2, $00, $30, $80, $21
	db 3, $00, $20, $80, $23
	db 4, $00, $10, $80, $32
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro01:
	db 3
	db 1, $00, $60, $80, $62
	db 1, $00, $A0, $80, $60
	db 1, $00, $C0, $80, $44
	db 1, $00, $F0, $80, $33
	db 1, $00, $C0, $80, $24
	db 1, $00, $80, $80, $22
	db 1, $00, $40, $80, $24
	db 2, $00, $30, $80, $33
	db 3, $00, $20, $80, $35
	db 4, $00, $10, $80, $43
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro02:
	db 3
	db 4, $00, $F0, $80, $33
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro03:
	db 1
	db 1, $00, $F0, $87, $45
	db 1, $40, $F0, $87, $45
	db 1, $80, $F0, $87, $45
	db 1, $C0, $F0, $87, $45
	db 1, $80, $F0, $87, $45
	db 1, $40, $F0, $87, $45
	db 1, $00, $F0, $87, $45
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro04:
	db 1
	db 2, $00, $F0, $84, $4F
	db 1, $40, $C0, $84, $5D
	db 1, $80, $B0, $84, $6B
	db 1, $C0, $A0, $84, $79
	db 1, $80, $90, $84, $87
	db 2, $40, $80, $84, $95
	db 2, $00, $70, $84, $A3
	db 2, $40, $60, $84, $B1
	db 2, $80, $50, $84, $BF
	db 4, $C0, $40, $84, $CD
	db 4, $80, $30, $84, $DB
	db 8, $40, $20, $84, $E9
	db 8, $00, $10, $84, $F7
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro05:
	db 0
	db 2, $40, $F0, $80, $9D
	db 1, $80, $C0, $80, $9D
	db 1, $C0, $B0, $80, $9D
	db 1, $80, $A0, $80, $9D
	db 1, $40, $90, $80, $9D
	db 2, $00, $80, $80, $9D
	db 2, $40, $70, $80, $9D
	db 2, $80, $60, $80, $9D
	db 2, $C0, $50, $80, $9D
	db 4, $80, $40, $80, $9D
	db 4, $40, $30, $80, $9D
	db 8, $00, $20, $80, $9D
	db 8, $40, $10, $80, $9D
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro06:
	db 1
	db 1, $00, $F0, $87, $83
	db 1, $40, $F0, $87, $83
	db 1, $80, $F0, $87, $83
	db 1, $C0, $F0, $87, $83
	db 1, $80, $F0, $87, $83
	db 1, $40, $F0, $87, $83
	db 1, $00, $F0, $87, $83
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro07:
	db 1
	db 1, $80, $F0, $80, $9D
	db 1, $80, $10, $80, $9D
	db 1, $80, $F0, $80, $9D
	db 1, $80, $A0, $86, $28
	db 1, $80, $70, $86, $89
	db 1, $80, $50, $86, $C5
	db 1, $80, $20, $87, $8A
	db 1, $80, $10, $87, $8A
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro08:
	db 3
	db 2, $00, $F1, $80, $44
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro09:
SFXMacro0A:
	db 3
	db 3, $00, $F0, $80, $46
	db 4, $00, $00, $00, $00
	db 70, $00, $F3, $80, $64
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro0B:
	db 1
	db 4, $80, $C1, $87, $C2
	db 1, $00, $00, $00, $00
	db 4, $80, $C1, $87, $AD
	db 1, $00, $00, $00, $00
	db 20, $80, $C1, $87, $C2
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro0C:
SFXMacro0D:
	db 1
	db 4, $80, $C1, $87, $C5
	db 1, $00, $00, $00, $00
	db 4, $80, $C1, $87, $B1
	db 1, $00, $00, $00, $00
	db 20, $80, $C1, $87, $C5
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro0E:
SFXMacro0F:
	db 1
	db 4, $80, $C1, $87, $C9
	db 1, $00, $00, $00, $00
	db 4, $80, $C1, $87, $B6
	db 1, $00, $00, $00, $00
	db 20, $80, $C1, $87, $C9
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro10:
SFXMacro11:
	db 0
	db 10, $80, $4A, $87, $8A
	db 1, $00, $00, $00, $00
	db 10, $80, $49, $87, $E3
	db 1, $00, $00, $00, $00
	db 30, $80, $4A, $87, $D9
	db 60, $80, $C3, $87, $D9
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro12:
	db 1
	db 2, $80, $40, $87, $14
	db 2, $80, $40, $87, $21
	db 2, $80, $40, $87, $2E
	db 2, $80, $40, $87, $3A
	db 2, $80, $40, $87, $45
	db 2, $80, $40, $87, $2E
	db 2, $80, $40, $87, $3A
	db 2, $80, $40, $87, $45
	db 2, $80, $40, $87, $4F
	db 2, $80, $40, $87, $59
	db 2, $80, $40, $87, $45
	db 2, $80, $40, $87, $4F
	db 2, $80, $40, $87, $59
	db 2, $80, $40, $87, $63
	db 2, $80, $40, $87, $6C
	db 2, $80, $40, $87, $59
	db 2, $80, $40, $87, $63
	db 2, $80, $40, $87, $6C
	db 2, $80, $40, $87, $74
	db 2, $80, $40, $87, $7C
	db 2, $80, $40, $87, $6C
	db 2, $80, $40, $87, $74
	db 2, $80, $40, $87, $7C
	db 2, $80, $40, $87, $83
	db 2, $80, $40, $87, $8A
	db 2, $80, $40, $87, $7C
	db 2, $80, $40, $87, $83
	db 2, $80, $40, $87, $8A
	db 2, $80, $40, $87, $91
	db 2, $80, $40, $87, $97
	db 2, $80, $40, $87, $8A
	db 2, $80, $40, $87, $91
	db 2, $80, $40, $87, $97
	db 2, $80, $40, $87, $97
	db 2, $80, $40, $87, $A3
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro13:
	db 3
	db 40, $00, $0B, $80, $64
	db 70, $00, $C3, $80, $64
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro14:
SFXMacro15:
	db 3
	db 1, $00, $10, $80, $33
	db 1, $00, $20, $00, $33
	db 1, $00, $40, $00, $33
	db 2, $00, $80, $00, $33
	db 3, $00, $F0, $00, $33
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro16:
	db 3
	db 10, $00, $F1, $80, $60
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro17:
	db 1
	db 2, $80, $F0, $87, $D7
	db 1, $00, $00, $00, $00
	db 10, $80, $A2, $87, $D7
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro18:
	db 3
	db 1, $00, $F0, $80, $33
	db 1, $00, $E0, $80, $44
	db 1, $00, $D0, $80, $34
	db 1, $00, $C0, $80, $45
	db 1, $00, $B0, $80, $35
	db 1, $00, $A0, $80, $46
	db 1, $00, $90, $80, $42
	db 1, $00, $80, $80, $47
	db 1, $00, $70, $80, $43
	db 1, $00, $60, $80, $60
	db 1, $00, $40, $80, $44
	db 1, $00, $20, $80, $61
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro19:
SFXMacro1A:
	db 3
	db 1, $00, $20, $80, $44
	db 1, $00, $80, $80, $44
	db 1, $00, $40, $80, $44
	db 1, $00, $C0, $80, $44
	db 1, $00, $60, $80, $44
	db 1, $00, $E0, $80, $44
	db 1, $00, $80, $80, $44
	db 10, $00, $F1, $80, $44
	db 1, $00, $20, $80, $44
	db 1, $00, $80, $80, $44
	db 1, $00, $40, $80, $44
	db 1, $00, $C0, $80, $44
	db 1, $00, $60, $80, $44
	db 1, $00, $E0, $80, $44
	db 1, $00, $80, $80, $44
	db 90, $00, $A7, $80, $44
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro1B:
SFXMacro1C:
SFXMacro1D:
	db 3
	db 2, $00, $F0, $80, $62
	db 1, $00, $00, $00, $00
	db 1, $00, $F0, $80, $21
	db 1, $00, $F0, $00, $22
	db 1, $00, $F0, $00, $23
	db 1, $00, $F0, $00, $24
	db 1, $00, $F0, $00, $32
	db 1, $00, $F0, $00, $33
	db 1, $00, $F0, $00, $34
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro1E:
	db 1
	db 1, $80, $40, $87, $C5
	db 1, $00, $00, $00, $00
	db 1, $80, $40, $87, $B1
	db 1, $80, $40, $87, $AD
	db 1, $80, $40, $87, $A8
	db 1, $80, $40, $87, $A3
	db 1, $80, $40, $87, $9D
	db 1, $80, $40, $87, $97
	db 1, $80, $40, $87, $91
	db 1, $80, $40, $87, $8A
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro1F:
	db 1
	db 10, $80, $F1, $83, $12
	db 4, $00, $00, $00, $00
	db 1, $80, $A0, $87, $8A
	db 2, $00, $00, $00, $00
	db 1, $80, $A0, $87, $97
	db 2, $00, $00, $00, $00
	db 1, $80, $A0, $87, $A3
	db 2, $00, $00, $00, $00
	db 1, $80, $A0, $87, $A8
	db 2, $00, $00, $00, $00
	db 1, $80, $A0, $87, $B1
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro20:
	db 3
	db 2, $00, $F0, $80, $62
	db 60, $00, $A5, $80, $62
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro21:
	db 3
	db 1, $3E, $F0, $C0, $60
	db 2, $3E, $00, $40, $00
	db 1, $3E, $F0, $C0, $44
	db 2, $3E, $00, $40, $00
	db 1, $3E, $F0, $C0, $34
	db 2, $3E, $00, $40, $00
	db 1, $3E, $F0, $C0, $14
	db 1, $3E, $00, $40, $00
	db $FF
SFXMacro22:
SFXMacro23:
SFXMacro24:
	db 3
	db 5, $00, $F1, $80, $60
	db 5, $00, $F1, $80, $44
	db 2, $00, $00, $00, $00
	db 2, $00, $F0, $80, $24
	db 10, $00, $80, $80, $32
	db 10, $00, $60, $80, $33
	db 10, $00, $40, $80, $34
	db 10, $00, $20, $80, $35
	db 20, $00, $10, $80, $42
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro25:
SFXMacro26:
SFXMacro27:
	db 3
	db 40, $00, $1C, $80, $34
	db 100, $00, $F0, $80, $34
	db 100, $00, $F7, $80, $34
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro28:
SFXMacro29:
	db 3
	db 2, $00, $F0, $80, $63
	db 2, $00, $F0, $80, $61
	db 2, $00, $F0, $80, $47
	db 2, $00, $F0, $80, $45
	db 2, $00, $F0, $80, $43
	db 2, $00, $F0, $80, $35
	db 2, $00, $F0, $80, $32
	db 2, $00, $F0, $80, $23
	db 2, $00, $F0, $80, $21
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro2A:
	db 0
	db 20, $00, $00, $00, $00
	db 2, $80, $80, $87, $6C
	db 39, $80, $47, $87, $6C
	db $01, $00, $00, $00, $00
	db $FF
SFXMacro2B:
	db 1
	db 20, $00, $00, $00, $00
	db 2, $80, $F0, $87, $DB
	db 39, $80, $A2, $87, $DB
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro2C:
	db 1
	db 5, $80, $F0, $86, $E7
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro2D:
	db 0
	db 5, $80, $C0, $86, $89
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro2E:
	db 3
	db 20, $00, $1A, $80, $63
	db 80, $00, $F5, $80, $63
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro2F:
	db 3
	db 2, $00, $F0, $80, $21
	db 2, $00, $70, $80, $23
	db 2, $00, $C0, $80, $32
	db 2, $00, $50, $80, $34
	db 2, $00, $B0, $80, $42
	db 2, $00, $40, $80, $44
	db 2, $00, $A0, $80, $46
	db 2, $00, $30, $80, $60
	db 2, $00, $90, $80, $62
	db 2, $00, $20, $80, $64
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro30:
SFXMacro31:
SFXMacro32:
SFXMacro33:
	db 0
	db 3, $80, $F0, $84, $4F
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro34:
	db 1
	db 3, $80, $F0, $84, $84
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro35:
	db 3
	db 1, $00, $F0, $80, $32
	db 2, $00, $C0, $80, $34
	db 2, $00, $B0, $80, $42
	db 2, $00, $A0, $80, $44
	db 2, $00, $90, $80, $46
	db 2, $00, $80, $80, $47
	db 3, $00, $70, $80, $60
	db 3, $00, $60, $80, $61
	db 4, $00, $50, $80, $62
	db 5, $00, $40, $80, $63
	db 6, $00, $30, $80, $63
	db 8, $00, $20, $80, $63
	db 8, $00, $10, $80, $63
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro36:
	db 3
	db 4, $3C, $F0, $C0, $44
	db 1, $3D, $00, $40, $00
	db $FF
SFXMacro37:
	db 3
	db 20, $00, $F5, $80, $63
	db 30, $00, $F6, $80, $63
	db 10, $00, $F7, $80, $63
	db 30, $00, $F6, $80, $63
	db 34, $00, $F5, $80, $63
	db 34, $00, $F6, $80, $63
	db 23, $00, $F5, $80, $63
	db 84, $00, $F7, $80, $63
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro38:
SFXMacro39:
	db 1
.SFXMacro39Loop
	db 8, $80, $A1, $87, $45
	db 4, $80, $A1, $87, $6C
	db 4, $80, $A1, $87, $74
	db 4, $80, $A1, $87, $83
	db 4, $80, $A1, $87, $91
	db 4, $80, $A1, $87, $9D
	db 12, $80, $A1, $87, $A3
	db 4, $80, $A1, $87, $9D
	db 4, $80, $A1, $87, $91
	db 4, $80, $A1, $87, $83
	db 4, $80, $A1, $87, $74
	db 4, $80, $A1, $87, $6C
	db 4, $80, $A1, $87, $59
	db $FE
	dw .SFXMacro39Loop
SFXMacro3A:
SFXMacro3B:
	db 1
	db 4, $80, $C1, $87, $06
	db 4, $80, $C1, $87, $3A
	db 4, $80, $C1, $87, $59
	db 4, $80, $C1, $87, $83
	db 4, $80, $C1, $87, $9D
	db 4, $80, $C1, $87, $AD
	db 4, $80, $C1, $87, $C2
	db 4, $80, $C1, $87, $CF
	db 24, $80, $C2, $87, $D7
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro3C:
	db 3
	db 30, $00, $1B, $80, $33
	db 110, $00, $F7, $80, $33
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro3D:
	db 0
SFXMacro3ELoop:
	db 3, $00, $F0, $87, $74
	db 8, $C0, $E0, $87, $06
	db 6, $80, $D0, $87, $C5
	db 9, $40, $C0, $86, $5B
	db 5, $80, $B0, $85, $12
	db 7, $C0, $A0, $87, $A8
	db 5, $80, $A0, $87, $ED
	db 3, $40, $A0, $87, $BA
	db 9, $00, $A0, $87, $06
	db 2, $40, $A0, $84, $4F
	db 3, $80, $A0, $87, $CC
	db 1, $C0, $90, $87, $45
	db 9, $00, $90, $86, $9E
	db 6, $80, $80, $87, $ED
	db 8, $C0, $70, $87, $74
	db 1, $40, $60, $87, $06
	db 4, $C0, $50, $86, $28
	db 9, $40, $40, $87, $2E
	db 11, $80, $30, $87, $45
	db 4, $40, $20, $87, $A8
	db 9, $00, $20, $87, $63
	db 2, $40, $10, $87, $DD
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro3E:
	db 1
	db 4, $00, $00, $00, $00
	db $FE
	dw SFXMacro3ELoop
SFXMacro3F:
	db 0
	db 8, $80, $F1, $86, $B2
	db 8, $80, $F1, $87, $06
	db 8, $80, $F1, $87, $3A
	db 8, $80, $F1, $87, $59
	db 8, $80, $F2, $87, $83
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro40:
	db 1
	db 8, $80, $F1, $86, $73
	db 8, $80, $F1, $86, $B2
	db 8, $80, $F1, $87, $06
	db 8, $80, $F1, $87, $3A
	db 8, $80, $F2, $87, $59
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro41:
	db 3
	db 2, $00, $F0, $80, $61
	db 2, $00, $A0, $80, $60
	db 2, $00, $80, $80, $47
	db 2, $00, $60, $80, $46
	db 2, $00, $F0, $80, $43
	db 2, $00, $A0, $80, $42
	db 2, $00, $80, $80, $35
	db 2, $00, $60, $80, $34
	db 2, $00, $F0, $80, $32
	db 2, $00, $A0, $80, $24
	db 2, $00, $80, $80, $23
	db 2, $00, $60, $80, $22
	db 2, $00, $F0, $80, $23
	db 2, $00, $A0, $80, $21
	db 2, $00, $80, $80, $14
	db 2, $00, $60, $80, $06
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro42:
	db 1
	db 1, $40, $C0, $87, $14
	db 1, $40, $C0, $87, $2E
	db 1, $40, $C0, $87, $45
	db 1, $40, $C0, $87, $4F
	db 1, $40, $C0, $87, $63
	db 1, $40, $C0, $87, $74
	db 1, $40, $C0, $87, $83
	db 1, $00, $00, $00, $00
	db 1, $40, $C0, $87, $4F
	db 1, $40, $C0, $87, $63
	db 1, $40, $C0, $87, $74
	db 1, $40, $C0, $87, $83
	db 1, $40, $C0, $87, $8A
	db 1, $40, $C0, $87, $97
	db 1, $40, $C0, $87, $A3
	db 1, $00, $00, $00, $00
	db 1, $40, $C0, $87, $83
	db 1, $40, $C0, $87, $8A
	db 1, $40, $C0, $87, $97
	db 1, $40, $C0, $87, $A3
	db 1, $40, $C0, $87, $A8
	db 1, $40, $C0, $87, $B1
	db 1, $40, $C0, $87, $BA
	db 1, $00, $00, $00, $00
	db 1, $40, $C0, $87, $A3
	db 1, $40, $C0, $87, $A8
	db 1, $40, $C0, $87, $B1
	db 1, $40, $C0, $87, $BA
	db 1, $40, $C0, $87, $C2
	db 1, $40, $C0, $87, $C5
	db 1, $40, $C0, $87, $CC
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro43:
	db 0
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro44:
	db 1
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro45:
	db 2
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro46:
	db 3
	db 1, $00, $00, $00, $00
	db $FF

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
C3ModSeqDelay: ds 1
C3ModSeq: ds 2
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
BeatCounter: ds 1
Tempo: ds 1
MasterPan: ds 1
MasterSFXPan: ds 1
CurChan: ds 1
CurNoteC1: ds 1
CurNoteC2: ds 1
CurNoteC3: ds 1
CurNoteC4: ds 1