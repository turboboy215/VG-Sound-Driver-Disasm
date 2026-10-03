;R-Type audio disassembly
;Original audio & code by David Whittaker
;Disassembly by Will Trowbridge

include "HARDWARE.INC"

def AudioROM equ $4000
def AudioRAM equ $D000

;Audio data equates
def tempo equ $F4
def loop equ $F5
def env equ $F6
def vib equ $F7
def rest equ $F8
def tie equ $F9
def duty equ $FA
def tpglobal equ $FB
def tp equ $FC
def sweep equ $FD
def end equ $FE
def exit equ $FF

def endvib equ $80

;Lengths
def len1 equ $60
def len2 equ $61
def len3 equ $62
def len4 equ $63
def len5 equ $64
def len6 equ $65
def len7 equ $66
def len8 equ $67
def len9 equ $68
def len10 equ $69
def len11 equ $6A
def len12 equ $6B
def len13 equ $6C
def len14 equ $6D
def len15 equ $6E
def len16 equ $6F
def len17 equ $70
def len18 equ $71
def len19 equ $72
def len20 equ $73
def len21 equ $74
def len22 equ $75
def len23 equ $76
def len24 equ $77
def len25 equ $78
def len26 equ $79
def len27 equ $7A
def len28 equ $7B
def len29 equ $7C
def len30 equ $7D
def len31 equ $7E
def len32 equ $7F

SECTION "Audio", ROMX[$4000], BANK[$1]

	jp LoadSong


	jp PlaySong


Init:
	jp InitRoutine


	jp SetNRVals


	jp LoadSFXC1


	jp LoadSFXC2


	jp LoadSFXC4


LoadSong:
	;Start initializing song
	push af
	call Init
	pop af
	inc a
	ld b, a
	xor a

;Keep adding to song pointer until reaching number
AdvanceSongPtr:
	dec b
	jr z, ClearChVar

	;Song header = 9 bytes
	add 9
	jr AdvanceSongPtr

;Clear variables for each channel
ClearChVar:
	ld c, a
	ld b, $40
	xor a
	ld hl, C1Pos

;Loop the process until complete
.ClearProc
	ld [hl+], a
	dec b
	jr nz, .ClearProc

GetPtrs:
	;Add to the song table to get the song pointer
	ld hl, SongTab
	add hl, bc
	;Get tempo
	ld a, [hl+]
	ld [Tempo], a
	ld [Tempo+1], a
	;Get channel 1 pattern start position
	ld a, [hl+]
	ld [C1Start], a
	ld e, a
	ld a, [hl+]
	ld [C1Start+1], a
	;Get channel 1 current phrase pointer
	ld d, a
	ld a, [de]
	ld [C1Pos], a
	inc de
	ld a, [de]
	ld [C1Pos+1], a
	;Get channel 2 pattern start position
	ld a, [hl+]
	ld [C2Start], a
	ld e, a
	ld a, [hl+]
	ld [C2Start+1], a
	;Get channel 2 current phrase pointer
	ld d, a
	ld a, [de]
	ld [C2Pos], a
	inc de
	ld a, [de]
	ld [C2Pos+1], a
	;Get channel 3 pattern start position
	ld a, [hl+]
	ld [C3Start], a
	ld e, a
	ld a, [hl+]
	ld [C3Start+1], a
	;Get channel 3 current phrase pointer
	ld d, a
	ld a, [de]
	ld [C3Pos], a
	inc de
	ld a, [de]
	ld [C3Pos+1], a
	;Get channel 4 pattern start position
	ld a, [hl+]
	ld [C4Start], a
	ld e, a
	ld a, [hl+]
	ld [C4Start+1], a
	;Get channel 4 current phrase pointer
	ld d, a
	ld a, [de]
	ld [C4Pos], a
	inc de
	ld a, [de]
	ld [C4Pos+1], a
	;Set default note delays (1)
	ld a, 1
	ld [C1Delay], a
	ld [C2Delay], a
	ld [C3Delay], a
	ld [C4Delay], a
	;Set channel pattern positions (2)
	inc a
	ld [C1PatPos], a
	ld [C2PatPos], a
	ld [C3PatPos], a
	ld [C4PatPos], a
	;Clear global transpose (0)
	xor a
	ld [GlobalTrans], a
	;Set beat counter and play flags (255)
	dec a
	ld [BeatCounter], a
	ld [SongPlayFlag], a
	ld [PlayFlag], a
	ret


;Set audio register values from RAM
SetNRVals:
	;Check if music is playing
	ld a, [SongPlayFlag]
	and a
	;If not, then return
	jr z, .SetNRValsRet

	;Then check if any audio is playing
	ld a, [PlayFlag]
	and a
	;If not, then return
	jr nz, .SetNRValsRet

	;If music is playing, then set values
	ld a, [NR11Val]
	ldh [rNR11], a
	ld a, [NR12Val]
	ldh [rNR12], a
	ld a, [NR13Val]
	ldh [rNR13], a
	ld a, [NR14Val]
	set 7, a
	ldh [rNR14], a
	ld a, [NR21Val]
	ldh [rNR21], a
	ld a, [NR22Val]
	ldh [rNR22], a
	ld a, [NR23Val]
	ldh [rNR23], a
	ld a, [NR24Val]
	set 7, a
	ldh [rNR24], a
	ld a, [NR30Val]
	ldh [rNR30], a
	ld a, [NR32Val]
	ldh [rNR32], a
	ld a, [NR33Val]
	ldh [rNR33], a
	ld a, [NR34Val]
	set 7, a
	ldh [rNR34], a
	ld a, [NR42Val]
	ldh [rNR42], a
	ld a, [NR43Val]
	ldh [rNR43], a
	ld a, %10000000
	ldh [rNR44], a
	ld [PlayFlag], a

.SetNRValsRet
	ret


InitRoutine:
	;Clear variables
	xor a
	ld [PlayFlag], a
	ld [C1TrigFlag], a
	ld [C2TrigFlag], a
	ld [C4TrigFlag], a
	;Clear channel envelopes
	ldh [rNR12], a
	ldh [rNR22], a
	ldh [rNR32], a
	ldh [rNR42], a
	;Set master volume
	ld a, %01110111
	ldh [rNR50], a
	;Set panning
	ld a, %11111111
	ldh [rNR51], a
	;Enable audio
	ld a, %10000000
	ldh [rNR52], a
	ret


PlaySong:
	;Push all the registers on the stack
	push af
	push bc
	push de
	push hl
	call CheckSongPlay
	call PlaySFX
	ld a, [PlayFlag]
	and a
	jp z, ExitAudio

C1FreqSet:
	;Check for flag to enable trigger
	ld a, [C1TrigFlag]
	and a
	jr nz, C2FreqSet

	;Check for sweep
	ld a, [C1Sweep]
	and a
	jr nz, C2FreqSet

	;If channel trigger or sweep is not set, then set frequency
	ld a, [NR13Val]
	ldh [rNR13], a
	ld a, [NR14Val]
	ldh [rNR14], a

C2FreqSet:
	;Check for flag to enable trigger
	ld a, [C2TrigFlag]
	and a
	jr nz, C3FreqSet

	;If channel trigger is not set, then set frequency
	ld a, [NR23Val]
	ldh [rNR23], a
	ld a, [NR24Val]
	ldh [rNR24], a

C3FreqSet:
	;Set frequency
	ld a, [NR33Val]
	ldh [rNR33], a
	ld a, [NR34Val]
	ldh [rNR34], a

;Pop all the stored registers from the stack
ExitAudio:
	pop hl
	pop de
	pop bc
	pop af
	ret


;Check to see if the song is playing
CheckSongPlay:
	ld a, [PlayFlag]
	and a
	jr nz, UpdateSong

	ret


;Get the current tempo and update the timer
UpdateSong:
	ld a, [Tempo]
	ld hl, BeatCounter
	;Add tempo value to beat counter
	add [hl]
	ld [hl], a
	;If no overflow, do not update the channels but process envelopes and vibrato
	jr nc, ProcEnvVibrato

	;Otherwise, update the 4 channels
	call PlaySongC1
	call PlaySongC2
	call PlaySongC3
	call PlaySongC4

ProcEnvVibrato:
	call C1ProcVibrato
	call C2ProcVibrato
	call C3ProcEnvLen
	jp C4ProcVibrato


	ret


PlaySongC1:
	;Decrement channel 1 delay
	ld hl, C1Delay
	dec [hl]
	;If not done playing, then return
	ret nz

	;Update channel 1 position
	ld a, [C1Pos]
	ld l, a
	ld a, [C1Pos+1]
	ld h, a
	xor a
	ld [C1Sweep], a

;Get the next byte
.C1GetNextByte
	ld a, [hl+]
	;Is bit 7 set?
	bit 7, a
	;Then it must be a VCMD...
	jr nz, .C1GetVCMD

	;Else, if 60 or greater, then it is a note length
	cp $60
	;If not, then it is a note
	jr c, .C1GetNote

;Calculate the note length
.C1GetNoteLen
	add $A1
	ld [C1Len], a
	jr .C1GetNextByte

.C1GetNote
	;Add both transpose values to note
	push hl
	ld hl, GlobalTrans
	add [hl]
	ld hl, C1Trans
	add [hl]
	add a
	ld c, a
	;Get note frequency from table
	ld b, 0
	ld hl, FreqTab
	add hl, bc
	ld a, [hl+]
	ld [NR13Val], a
	ld [C1Freq], a
	ld a, [hl]
	pop hl
	ld [NR14Val], a
	ld [C1Freq+1], a
	;Check for flag to enable trigger
	ld a, [C1TrigFlag]
	and a
	;If not set, then is rest/tie
	jr nz, .C1UpdatePos

	;Otherwise, play new note
	ld a, [C1Sweep]
	ldh [rNR10], a
	ld a, [NR11Val]
	ldh [rNR11], a
	ld a, [NR12Val]
	ldh [rNR12], a
	ld a, [NR13Val]
	ldh [rNR13], a
	ld a, [NR14Val]
	set 7, a
	ldh [rNR14], a

.C1UpdatePos
	ld a, l
	ld [C1Pos], a
	ld a, h
	ld [C1Pos+1], a
	ld a, [C1Len]
	ld [C1Delay], a
	ret


.C1GetVCMD
	ld b, $00
	
.C1EventExit
;FF = End of phrase
	;Is this the command?
	cp $FF
	;If not, then check for next command
	jr nz, .C1EventEnv

	;Increase the current position
	ld a, [C1PatPos]
	ld c, a
	ld a, [C1Start]
	add c
	ld l, a
	ld a, [C1PatPos+1]
	ld c, a
	ld a, [C1Start+1]
	adc c
	ld h, a
	;Advance the pointer
	ld a, [C1PatPos]
	add 2
	ld [C1PatPos], a
	ld a, [C1PatPos+1]
	adc b
	ld [C1PatPos+1], a
	;Load the pointer from the parameters
	ld a, [hl+]
	or [hl]
	jr nz, .C1EventExit2

	;If pointer = 0, then restart pattern
	ld a, [C1Start]
	ld l, a
	ld a, [C1Start+1]
	ld h, a
	ld a, 2
	ld [C1PatPos], a
	ld a, b
	ld [C1PatPos+1], a
	inc hl

;Otherwise, go to the pointer
.C1EventExit2
	ld a, [hl-]
	ld c, a
	ld l, [hl]
	ld h, c
	jp .C1GetNextByte


.C1EventEnv
;F6 = Set channel envelope (NR12)
;Parameters: xx (X = Value)
	;Is this the command?
	cp $F6
	;If not, then check for next command
	jr nz, .C1EventVibrato

	ld a, [hl+]
	ld [NR12Val], a
	jp .C1GetNextByte


.C1EventVibrato
;F7 = Set channel vibrato effect
;Parameters: xx (Index value to table)
	;Is this the command?
	cp $F7
	;If not, then check for next command
	jr nz, .C1EventDuty

	ld a, [hl+]
	ld [C1Vibrato], a
	ld a, b
	ld [C1VibPos], a
	jp .C1GetNextByte


.C1EventDuty
;FA = Set channel duty cycle and count (NR11)
;Parameters: xx (X = Value)
	;Is this the command?
	cp $FA
	;If not, then check for next command
	jr nz, .C1EventRest

	;Load the parameter into RAM
	ld a, [hl+]
	ld [NR11Val], a
	jp .C1GetNextByte


.C1EventRest
;F8 = Key off the channel for the current note duration
;Parameters: xx (X = Value)
	;Is this the command?
	cp $F8
	;If not, then check for next command
	jr nz, .C1EventTie

	jp .C1UpdatePos


.C1EventTie
;F9 = Delay the next note for the current note duration
	;Is this the command?
	cp $F9
	;If not, then check for next command
	jr nz, .C1EventSweep

	jp .C1UpdatePos


.C1EventSweep
;FD = Trigger a sweep/pitch slide for the set amount
	;Is this the command?
	cp $FD
	;If not, then check for next command
	jr nz, .C1EventGlobalTranspose

	;Load the parameter into RAM
	ld a, [hl+]
	ld [Sweep], a
	ld [C1Sweep], a
	jp .C1GetNextByte


.C1EventGlobalTranspose
;FB = Transpose all channels (in addition to per-channel transpose)
;Parameters: xx (X = Value)
	;Is this the command?
	cp $FB
	;If not, then check for next command
	jr nz, .C1EventLocalTranspose

	;Load the parameter into RAM
	ld a, [hl+]
	ld [GlobalTrans], a
	jp .C1GetNextByte


.C1EventLocalTranspose
;FC = Transpose the current channel (in addition to global transpose)
;Parameters: xx (X = Value)
	;Is this the command?
	cp $FC
	;If not, then check for next command
	jr nz, .C1EventLoop

	;Load the parameter into RAM
	ld a, [hl+]
	ld [C1Trans], a
	jp .C1GetNextByte


.C1EventLoop
;F5 = Set the channel restart position and end of phrase
;Parameters: xx xx (X = Pointer)
	;Is this the command?
	cp $F5
	;If not, then check for next command
	jr nz, .C1EventEnd

	;Get position from pointer
	ld a, [hl+]
	ld c, a
	ld [C1Start], a
	ld a, [hl]
	ld l, c
	ld h, a
	ld [C1Start+1], a
	;Go to the start of the pattern
	ld a, 2
	ld [C1PatPos], a
	ld a, b
	ld [C1PatPos+1], a
	ld a, [hl+]
	ld c, a
	ld h, [hl]
	ld l, c
	jp .C1GetNextByte


.C1EventEnd
;FE = Stop the channel
	;Is this the command?
	cp $FE
	;If not, then check for next command
	jr nz, .C1EventTempo

	;Disable music
	ld a, b
	ld [SongPlayFlag], a
	pop hl
	jp Init


.C1EventTempo
;F4 = Set the tempo
;Parameters: xx (X = Value)
	;Is this the command?
	cp $F4
	;If not, then go to infinite loop
	jr nz, .C1InfLoop

	;Load the parameter into RAM
	ld a, [hl+]
	ld [Tempo], a
	ld [Tempo+1], a
	jp .C1GetNextByte


;Infinite loop
.C1InfLoop
	jr .C1InfLoop

;Process channel 1 vibrato
C1ProcVibrato:
	;Get vibrato value from table using index value
	ld a, [C1Vibrato]
	add a
	ld c, a
	ld b, 0
	ld hl, VibTab
	add hl, bc
	ld a, [hl+]
	ld c, a
	ld h, [hl]
	ld l, c
	push hl
	pop de
	;Load value from current position in vibrato sequence
	ld a, [C1VibPos]
	ld c, a
	add hl, bc
	;Is value 80?
	ld a, [hl]
	cp $80
	jr nz, .C1ProcVibratoUpdate

	;If 80, then reset
	xor a
	ld [C1VibPos], a
	ld a, [de]

;Otherwise, update vibrato
.C1ProcVibratoUpdate
	ld hl, C1VibPos
	inc [hl]
	ld c, a
	;Add to current frequency
	ld a, [C1Freq]
	add c
	ld [NR13Val], a
	ret


PlaySongC2:
	;Decrement channel 2 delay
	ld hl, C2Delay
	dec [hl]
	;If not done playing, then return
	ret nz

	;Update channel 2 position
	ld a, [C2Pos]
	ld l, a
	ld a, [C2Pos+1]
	ld h, a

;Get the next byte
.C2GetNextByte
	ld a, [hl+]
	;Is bit 7 set?
	bit 7, a
	;Then it must be a VCMD...
	jr nz, .C2GetVCMD

	;Else, if 60 or greater, then it is a note length
	cp $60
	;If not, then it is a note
	jr c, .C2GetNote

;Calculate the note length
.C2GetNoteLen
	add $A1
	ld [C2Len], a
	jr .C2GetNextByte

.C2GetNote
	;Add both transpose values to note
	push hl
	ld hl, GlobalTrans
	add [hl]
	ld hl, C2Trans
	add [hl]
	add a
	ld c, a
	;Get note frequency from table
	ld b, 0
	ld hl, FreqTab
	add hl, bc
	ld a, [hl+]
	ld [NR23Val], a
	ld [C2Freq], a
	ld a, [hl]
	pop hl
	ld [NR24Val], a
	ld [C2Freq+1], a
	;Check for flag to enable trigger
	ld a, [C2TrigFlag]
	and a
	jr nz, .C2UpdatePos

	ld a, [NR21Val]
	ldh [rNR21], a
	ld a, [NR22Val]
	ldh [rNR22], a
	ld a, [NR23Val]
	ldh [rNR23], a
	ld a, [NR24Val]
	set 7, a
	ldh [rNR24], a

.C2UpdatePos:
	ld a, l
	ld [C2Pos], a
	ld a, h
	ld [C2Pos+1], a
	ld a, [C2Len]
	ld [C2Delay], a
	ret


.C2GetVCMD
	ld b, 0

.C2EventExit
;FF = End of phrase
	;Is this the command?
	cp $FF
	;If not, then check for next command
	jr nz, .C2EventEnv

	;Increase the current position
	ld a, [C2PatPos]
	ld c, a
	ld a, [C2Start]
	add c
	ld l, a
	ld a, [C2PatPos+1]
	ld c, a
	ld a, [C2Start+1]
	adc c
	ld h, a
	;Advance the pointer
	ld a, [C2PatPos]
	add 2
	ld [C2PatPos], a
	ld a, [C2PatPos+1]
	adc b
	ld [C2PatPos+1], a
	;Load the pointer from the parameters
	ld a, [hl+]
	or [hl]
	jr nz, .C2EventExit2

	ld a, [C2Start]
	ld l, a
	ld a, [C2Start+1]
	ld h, a
	ld a, 2
	ld [C2PatPos], a
	ld a, b
	ld [C2PatPos+1], a
	inc hl

;Otherwise, go to the pointer
.C2EventExit2
	ld a, [hl-]
	ld c, a
	ld l, [hl]
	ld h, c
	jp .C2GetNextByte


.C2EventEnv
;F6 = Set channel envelope (NR22)
;Parameters: xx (X = Value)
	;Is this the command?
	cp $F6
	;If not, then check for next command
	jr nz, .C2EventVibrato

	;Load the parameter value into RAM
	ld a, [hl+]
	ld [NR22Val], a
	jp .C2GetNextByte


.C2EventVibrato
;F7 = Set channel vibrato effect
;Parameters: xx (Index value to table)
	;Is this the command?
	cp $F7
	;If not, then check for next command
	jr nz, .C2EventDuty

	;Load the parameter into RAM
	ld a, [hl+]
	ld [C2Vibrato], a
	;Reset vibrato sequence position
	ld a, b
	ld [C2VibPos], a
	jp .C2GetNextByte


.C2EventDuty
;FA = Set channel duty cycle and count (NR21)
;Parameters: xx (X = Value)
	;Is this the command?
	cp $FA
	;If not, then check for next command
	jr nz, .C2EventRest

	;Load the parameter into RAM
	ld a, [hl+]
	ld [NR21Val], a
	jp .C2GetNextByte


.C2EventRest
;F8 = Key off the channel for the current note duration
;Parameters: xx (X = Value)
	;Is this the command?
	cp $F8
	;If not, then check for next command
	jr nz, .C2EventTie

	jp .C2UpdatePos


.C2EventTie
;F9 = Delay the next note for the current note duration
	;Is this the command?
	cp $F9
	;If not, then check for next command
	jr nz, .C2EventGlobalTranspose

	jp .C2UpdatePos


.C2EventGlobalTranspose
;FB = Transpose all channels (in addition to per-channel transpose)
;Parameters: xx (X = Value)
	;Is this the command?
	cp $FB
	;If not, then check for next command
	jr nz, .C2EventLocalTranspose

	ld a, [hl+]
	ld [GlobalTrans], a
	jp .C2GetNextByte


.C2EventLocalTranspose
;FC = Transpose the current channel (in addition to global transpose)
;Parameters: xx (X = Value)
	;Is this the command?
	cp $FC
	;If not, then check for next command
	jr nz, .C2EventLoop

	;Load the parameter into RAM
	ld a, [hl+]
	ld [C2Trans], a
	jp .C2GetNextByte


.C2EventLoop
;F5 = Set the channel restart position and end of phrase
;Parameters: xx xx (X = Pointer)
	;Is this the command?
	cp $F5
	jr nz, .C2EventEnd

	;Get position from pointer
	ld a, [hl+]
	ld c, a
	ld [C2Start], a
	ld a, [hl]
	ld l, c
	ld h, a
	ld [C2Start+1], a
	;Go to the start of the pattern
	ld a, 2
	ld [C2PatPos], a
	ld a, b
	ld [C2PatPos+1], a
	ld a, [hl+]
	ld c, a
	ld h, [hl]
	ld l, c
	jp .C2GetNextByte


.C2EventEnd
;FE = Stop the channel
	;Is this the command?
	cp $FE
	;If not, then check for next command
	jr nz, .C2EventTempo

	;Disable music
	ld a, b
	ld [SongPlayFlag], a
	pop hl
	jp Init


.C2EventTempo
;F4 = Set the tempo
;Parameters: xx (X = Value)
	;Is this the command?
	cp $F4
	;If not, then go to infinite loop
	jr nz, .C2InfLoop

	;Load the parameter into RAM
	ld a, [hl+]
	ld [Tempo], a
	ld [Tempo+1], a
	jp .C2GetNextByte


;Infinite loop
.C2InfLoop
	jr .C2InfLoop

;Process channel 2 vibrato
C2ProcVibrato:
	;Get vibrato value from table using index value
	ld a, [C2Vibrato]
	add a
	ld c, a
	ld b, 0
	ld hl, VibTab
	add hl, bc
	ld a, [hl+]
	ld c, a
	ld h, [hl]
	ld l, c
	push hl
	pop de
	;Load value from current position in vibrato sequence
	ld a, [C2VibPos]
	ld c, a
	add hl, bc
	;Is value 80?
	ld a, [hl]
	cp $80
	jr nz, .C2ProcVibratoUpdate

	;If 80, then reset
	xor a
	ld [C2VibPos], a
	ld a, [de]

;Otherwise, update vibrato
.C2ProcVibratoUpdate
	ld hl, C2VibPos
	inc [hl]
	ld c, a
	;Add to current frequency
	ld a, [C2Freq]
	add c
	ld [NR23Val], a
	ret


PlaySongC3:
	;Decrement channel 3 delay
	ld hl, C3Delay
	dec [hl]
	;If not done playing, then return
	ret nz

	;Update channel 3 position
	ld a, [C3Pos]
	ld l, a
	ld a, [C3Pos+1]
	ld h, a

;Get the next byte
.C3GetNextByte
	ld a, [hl+]
	;Is bit 7 set?
	bit 7, a
	;Then it must be a VCMD...
	jr nz, .C3GetVCMD

	;If 60 or greater, then it is a note length
	cp $60
	;If not, then it is a note
	jr c, .C3GetNote

;Calculate the note length
.C3GetNoteLen
	add $A1
	ld [C3Len], a
	jr .C3GetNextByte

.C3GetNote
	;Add both transpose values to note
	push hl
	ld hl, GlobalTrans
	add [hl]
	ld hl, C3Trans
	add [hl]
	add a
	ld c, a
	;Get note frequency from table
	ld b, 0
	ld hl, FreqTab
	add hl, bc
	ld a, [hl+]
	ld [NR33Val], a
	ld [C3Freq], a
	ld a, [hl]
	pop hl
	ld [NR34Val], a
	ld [C3Freq+1], a
	;Play new note
	ld a, [NR32Val]
	ldh [rNR32], a
	ld a, %10000000
	ldh [rNR30], a
	ld a, [NR33Val]
	ldh [rNR33], a
	ld a, [NR34Val]
	set 7, a
	ldh [rNR34], a
	ld a, [C3EnvLen]
	ld [C3EnvDelay], a

.C3UpdatePos
	ld a, l
	ld [C3Pos], a
	ld a, h
	ld [C3Pos+1], a
	ld a, [C3Len]
	ld [C3Delay], a
	ret


.C3GetVCMD
	ld b, 0
	
.C3EventExit
;FF = End of phrase
	;Is this the command?	
	cp $FF
	;If not, then check for next command
	jr nz, .C3EventEnv

	;Increase the current position
	ld a, [C3PatPos]
	ld c, a
	ld a, [C3Start]
	add c
	ld l, a
	ld a, [C3PatPos+1]
	ld c, a
	ld a, [C3Start+1]
	adc c
	ld h, a
	;Advance the pointer
	ld a, [C3PatPos]
	add 2
	ld [C3PatPos], a
	ld a, [C3PatPos+1]
	adc b
	ld [C3PatPos+1], a
	;Load the pointer from the parameters
	ld a, [hl+]
	or [hl]
	jr nz, .C3EventExit2

	;If pointer = 0, then restart pattern
	ld a, [C3Start]
	ld l, a
	ld a, [C3Start+1]
	ld h, a
	ld a, 2
	ld [C3PatPos], a
	ld a, b
	ld [C3PatPos+1], a
	inc hl

;Otherwise, go to the pointer
.C3EventExit2
	ld a, [hl-]
	ld c, a
	ld l, [hl]
	ld h, c
	jp .C3GetNextByte


.C3EventEnv
;F6 = Set channel envelope (NR32)
;Parameters: xx yy (X = NR32 value, Y = Length)
;(For other channels, only X is used)
	;Is this the command?
	cp $F6
	;If not, then check for next command
	jr nz, .C3EventVibrato

	;Load the parameter values into RAM
	ld a, [hl+]
	ld [NR32Val], a
	ld a, [hl+]
	ld [C3EnvLen], a
	jp .C3GetNextByte


.C3EventVibrato
;F7 = Set channel vibrato effect
;Parameters: xx (Index value to table)
	;Is this the command?
	cp $F7
	jr nz, .C3EventRest

	;Load the parameter into RAM
	ld a, [hl+]
	ld [C3Vibrato], a
	;Reset vibrato sequence position
	ld a, b
	ld [C3VibPos], a
	jp .C3GetNextByte


.C3EventRest
;F8 = Key off the channel for the current note duration
;Parameters: xx (Value)
	;Is this the command?
	cp $F8
	;If not, then check for next command
	jr nz, .C3EventTie

	;Key off channel
	xor a
	ld [C3EnvDelay], a
	ldh [rNR32], a
	jp .C3UpdatePos


.C3EventTie
;F9 = Delay the next note for the current note duration
	;Is this the command?
	cp $F9
	;If not, then check for next command
	jr nz, .C3EventGlobalTranspose

	jp .C3UpdatePos


.C3EventGlobalTranspose
;FB = Transpose all channels (in addition to per-channel transpose)
;Parameters: xx (X = Value)
	;Is this the command?
	cp $FB
	;If not, then check for next command
	jr nz, .C3EventLocalTranspose

	;Load the parameter into RAM
	ld a, [hl+]
	ld [GlobalTrans], a
	jp .C3GetNextByte


.C3EventLocalTranspose
;FC = Transpose the current channel (in addition to global transpose)
;Parameters: xx (X = Value)
	;Is this the command?
	cp $FC
	;If not, then check for next command
	jr nz, .C3EventLoop

	;Load the parameter into RAM
	ld a, [hl+]
	ld [C3Trans], a
	jp .C3GetNextByte


.C3EventLoop
;F5 = Set the channel restart position and end of phrase
;Parameters: xx xx (X = Pointer)
	;Is this the command?
	cp $F5
	;If not, then check for next command
	jr nz, .C3EventEnd

	;Get position from pointer
	ld a, [hl+]
	ld c, a
	ld [C3Start], a
	ld a, [hl]
	ld l, c
	ld h, a
	ld [C3Start+1], a
	;Go to the start of the pattern
	ld a, 2
	ld [C3PatPos], a
	ld a, b
	ld [C3PatPos+1], a
	ld a, [hl+]
	ld c, a
	ld h, [hl]
	ld l, c
	jp .C3GetNextByte


.C3EventEnd
;FE = Stop the channel
	;Is this the command?
	cp $FE
	;If not, then check for next command
	jr nz, .C3EventTempo

	;Disable music
	ld a, b
	ld [SongPlayFlag], a
	pop hl
	jp Init


.C3EventTempo
;F4 = Set the tempo
;Parameters: xx (X = Value)
	;Is this the command?
	cp $F4
	;If not, then go to infinite loop
	jr nz, .C3InfLoop

	;Load the parameter into RAM
	ld a, [hl+]
	ld [Tempo], a
	ld [Tempo+1], a
	jp .C3GetNextByte


;Infinite loop
.C3InfLoop
	jr .C3InfLoop

;Process channel 3 envelope length
C3ProcEnvLen:
	;Check if delay is at 0
	ld a, [C3EnvDelay]
	and a
	;If so, skip to vibrato
	jr z, C3ProcVibrato

	;Otherwise, decrease value
	dec a
	ld [C3EnvDelay], a
	;If still not done, skip to vibrato
	jr nz, C3ProcVibrato

	;If now 0, then set output volume to 0
	xor a
	ldh [rNR32], a

;Process channel 3 vibrato
C3ProcVibrato:
	;Get vibrato value from table using index value
	ld a, [C3Vibrato]
	add a
	ld c, a
	ld b, 0
	ld hl, VibTab
	add hl, bc
	ld a, [hl+]
	ld c, a
	ld h, [hl]
	ld l, c
	push hl
	pop de
	;Load value from current position in vibrato sequence
	ld a, [C3VibPos]
	ld c, a
	add hl, bc
	;Is value 80?
	ld a, [hl]
	cp $80
	jr nz, .C3ProcVibratoUpdate

	;If 80, then reset
	xor a
	ld [C3VibPos], a
	ld a, [de]

;Otherwise, update vibrato
.C3ProcVibratoUpdate
	ld hl, C3VibPos
	inc [hl]
	ld c, a
	;Add to current frequency
	ld a, [C3Freq]
	add c
	ld [NR33Val], a
	ret


PlaySongC4:
	;Decrement channel 4 delay
	ld hl, C4Delay
	dec [hl]
	;If not done playing, then return
	ret nz

	;Update channel 4 position
	ld a, [C4Pos]
	ld l, a
	ld a, [C4Pos+1]
	ld h, a

;Get the next byte
.C4GetNextByte
	ld a, [hl+]
	;Is bit 7 set?
	bit 7, a
	;Then it must be a VCMD...
	jr nz, .C4GetVCMD

	;If 60 or greater, then it is a note length
	cp $60
	;If not, then it is a note
	jr c, .C4GetNote

;Calculate the note length
.C4GetNoteLen
	add $A1
	ld [C4Len], a
	jr .C4GetNextByte

.C4GetNote
	ld [NR43Val], a
	ld a, [C4TrigFlag]
	;Check for flag to enable trigger
	and a
	;If not set, then is rest/tie
	jr nz, .C4UpdatePos

	;Otherwise, play new note
	ld a, [NR42Val]
	ldh [rNR42], a
	ld a, [NR43Val]
	and %01110111
	ldh [rNR43], a
	ld a, %10000000
	ldh [rNR44], a

.C4UpdatePos
	ld a, l
	ld [C4Pos], a
	ld a, h
	ld [C4Pos+1], a
	ld a, [C4Len]
	ld [C4Delay], a
	ret


.C4GetVCMD
	ld b, 0
	
.C4EventExit
;FF = End of phrase
	;Is this the command?
	cp $FF
	;If not, then check for next command
	jr nz, .C4EventEnv

	;Increase the current position
	ld a, [C4PatPos]
	ld c, a
	ld a, [C4Start]
	add c
	ld l, a
	ld a, [C4PatPos+1]
	ld c, a
	ld a, [C4Start+1]
	adc c
	ld h, a
	;Advance the pointer
	ld a, [C4PatPos]
	add 2
	ld [C4PatPos], a
	ld a, [C4PatPos+1]
	adc b
	ld [C4PatPos+1], a
	;Load the pointer from the parameters
	ld a, [hl+]
	or [hl]
	jr nz, .C4EventExit2

	;If pointer = 0, then restart pattern
	ld a, [C4Start]
	ld l, a
	ld a, [C4Start+1]
	ld h, a
	ld a, 2
	ld [C4PatPos], a
	ld a, b
	ld [C4PatPos+1], a
	inc hl

;Otherwise, go to the pointer
.C4EventExit2
	ld a, [hl-]
	ld c, a
	ld l, [hl]
	ld h, c
	jp .C4GetNextByte


.C4EventEnv
;F6 = Set channel envelope (NR42)
;Parameters: xx (Value)
	;Is this the command?
	cp $F6
	;If not, then check for next command
	jr nz, .C4EventRest

	;Load the parameter value into RAM
	ld a, [hl+]
	ld [NR42Val], a
	jp .C4GetNextByte


.C4EventRest
;F8 = Key off the channel for the current note duration
;Parameters: xx (Value)
	;Is this the command?
	cp $F8
	;If not, then check for next command
	jr nz, .C4EventTie

	jp .C4UpdatePos


.C4EventTie
;F9 = Delay the next note for the current note duration
	;Is this the command?
	cp $F9
	;If not, then check for next command
	jr nz, .C4EventLoop

	jp .C4UpdatePos


.C4EventLoop
;F5 = Set the channel restart position and end of phrase
;Parameters: xx xx (X = Pointer)
	;Is this the command?
	cp $F5
	;If not, then check for next command
	jr nz, .C4EventEnd

	ld a, [hl+]
	ld c, a
	ld [C4Start], a
	ld a, [hl]
	ld l, c
	ld h, a
	ld [C4Start+1], a
	;Go to the start of the pattern
	ld a, 2
	ld [C4PatPos], a
	ld a, b
	ld [C4PatPos+1], a
	ld a, [hl+]
	ld c, a
	ld h, [hl]
	ld l, c
	jp .C4GetNextByte


.C4EventEnd
;FE = Stop the channel
	;Is this the command?
	cp $FE
	;If not, then check for next command
	jr nz, .C4EventTempo

	;Disable music
	ld a, b
	ld [SongPlayFlag], a
	pop hl
	jp Init


.C4EventTempo
;F4 = Set the tempo
;Parameters: xx (X = Value)
	;Is this the command?
	cp $F4
	;If not, then go to infinite loop
	jr nz, .C4InfLoop

	;Load the parameter into RAM
	ld a, [hl+]
	ld [Tempo], a
	ld [Tempo+1], a
	jp .C4GetNextByte


;Infinite loop
.C4InfLoop
	jr .C4InfLoop
	

;No vibrato for CH4, so return
C4ProcVibrato:
	ret


LoadSFXC1:
	;Get pointer to current sound effect from table
	add a
	ld c, a
	;Clear trigger
	xor a
	ld b, a
	ld [C1TrigFlag], a
	ld hl, SFXTab
	add hl, bc
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	;Copy SFX values into RAM
	ld c, 13
	ld de, C1SFXLen

.C1CopySFX:
	ld a, [hl+]
	ld [de], a
	inc de
	dec c
	jr nz, .C1CopySFX

.C1InitSFX:
	;Get SFX timer and length
	ld a, [C1SFXSpeed]
	ld [C1SFXTimer], a
	ld a, [C1SFXSlideCnt]
	ld [C1SFXSlidesLeft], a
	;Reset sweep
	xor a
	;Set other NR1x values
	ldh [rNR10], a
	ld a, [C1SFXNR11Val]
	ldh [rNR11], a
	ld a, [C1SFXNR12Val]
	ldh [rNR12], a
	ld a, [C1SFXFreqVal]
	ld [C1SFXNR13Val], a
	ldh [rNR13], a
	ld a, [C1SFXFreqVal+1]
	and %00000111
	ld [C1SFXNR14Val], a
	set 7, a
	ldh [rNR14], a
	ld [C1TrigFlag], a
	ret


LoadSFXC2:
	;Get pointer to current sound effect from table
	add a
	ld c, a
	;Clear trigger
	xor a
	ld b, a
	ld [C2TrigFlag], a
	ld hl, SFXTab
	add hl, bc
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	;Copy SFX values into RAM
	ld c, 13
	ld de, C2SFXLen

.C2CopySFX
	ld a, [hl+]
	ld [de], a
	inc de
	dec c
	jr nz, .C2CopySFX

.C2InitSFX
	;Get SFX timer and length
	ld a, [C2SFXSpeed]
	ld [C2SFXTimer], a
	ld a, [C2SFXSlideCnt]
	ld [C2SFXSlidesLeft], a
	;Set NR2x values
	ld a, [C2SFXNR21Val]
	ldh [rNR21], a
	ld a, [C2SFXNR22Val]
	ldh [rNR22], a
	ld a, [C2SFXFreqVal]
	ld [C2SFXNR23Val], a
	ldh [rNR23], a
	ld a, [C2SFXFreqVal+1]
	and %00000111
	ld [C2SFXNR24Val], a
	set 7, a
	ldh [rNR24], a
	ld [C2TrigFlag], a
	ret


LoadSFXC4:
	add a
	ld c, a
	xor a
	ld b, a
	ld [C4TrigFlag], a
	ld hl, SFXTab
	add hl, bc
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ld c, 13
	ld de, C4SFXLen

.C4CopySFX
	ld a, [hl+]
	ld [de], a
	inc de
	dec c
	jr nz, .C4CopySFX

.C4InitSFX
	;Get SFX timer and length
	ld a, [C4SFXSpeed]
	ld [C4SFXTimer], a
	ld a, [C4SFXSlideCnt]
	ld [C4SFXSlidesLeft], a
	;Set NR4x values
	ld a, [C4SFXNR42Val]
	ldh [rNR42], a
	ld a, [C4SFXFreqVal]
	and %01110111
	ld [C4SFXNR43Val], a
	ldh [rNR43], a
	ld a, %10000000
	ldh [rNR44], a
	ld [C4TrigFlag], a
	ret


PlaySFX:
	;First generate a random number, then play sound effects
	call GetRNG
	call PlaySFXC1
	call PlaySFXC2
	jp PlaySFXC4


	ret


PlaySFXC1:
	ld a, [C1TrigFlag]
	and a
	;If trigger flag is not set, then play SFX
	jr nz, .PlaySFXC1_2

	ret


.PlaySFXC1_2
	;Get sound effect duration
	ld a, [C1SFXLen]
	and a
	;If not 0, then go to next section
	jr nz, .C1SFXProc

	;Else, if "loop" flag is not 0, then go to next section
	ld a, [C1SFXSlideLoop]
	and a
	jr nz, .C1SFXProc

	;If play flag is 0, then turn channel 1 SFX off
	ld a, [PlayFlag]
	and a
	jr z, .C1SFXOff

	;Otherwise, get current NR1x values and write to registers
	ld a, [NR11Val]
	ldh [rNR11], a
	ld a, [NR12Val]
	ldh [rNR12], a
	ld a, [NR13Val]
	ldh [rNR13], a
	ld a, [NR14Val]
	set 7, a
	ldh [rNR14], a
	xor a
	ld [C1TrigFlag], a
	ret


;Turn off channel 1
.C1SFXOff
	xor a
	ldh [rNR12], a
	ld [C1TrigFlag], a
	ret


.C1SFXProc
	;Decrement SFX length
	ld hl, C1SFXLen
	dec [hl]
	;Check number of SFX pitch slides left
	ld a, [C1SFXSlidesLeft]
	and a
	;If not 0, then process next slide
	jr nz, .C1SFXCheckTimer

	;Otherwise, check if "loop" flag is set
	ld a, [C1SFXSlideLoop]
	and a
	jr nz, .C1SFXCheckSlideLen

	;Finally, check if slide is still in process
	ld a, [C1SFXSlideLen]
	and a
	jr nz, .C1SFXCheckSlideLen

	;If all values 0, then return
	ret


.C1SFXCheckSlideLen
	;Get remaining length of slide
	ld hl, C1SFXSlideLen
	dec [hl]
	;Reset pitch slide with count
	ld a, [C1SFXSlideCnt]
	ld [C1SFXSlidesLeft], a
	;Check for RNG flag
	ld a, [C1SFXRNG]
	and a
	;If 0, then skip
	jr z, .C1SFXNoRNG

.C1SFXAddRNG
	;Otherwise, add RNG to frequency
	ld hl, RNG
	ld a, [C1SFXFreqVal]
	add [hl]
	ld [C1SFXNR13Val], a
	ldh [rNR13], a
	ld a, [C1SFXFreqVal+1]
	add [hl]
	and %00000111
	ld [C1SFXNR14Val], a
	ldh [rNR14], a
	jr .C1SFXCheckTimer

.C1SFXNoRNG
	;Process frequency value without RNG
	ld a, [C1SFXFreqVal]
	ld [C1SFXNR13Val], a
	ldh [rNR13], a
	ld a, [C1SFXFreqVal+1]
	and %00000111
	ld [C1SFXNR14Val], a
	ldh [rNR14], a

.C1SFXCheckTimer
	;Decrement amount of pitch slides left
	ld hl, C1SFXSlidesLeft
	dec [hl]
	;If SFX speed is 0, then go to next section
	ld a, [C1SFXSpeed]
	and a
	jr z, .C1SFXCheckSign

	;Return if SFX is not done playing
	ld hl, C1SFXTimer
	dec [hl]
	jr nz, .C1SFXRet

	;Else, reset timer and continue
	ld [C1SFXTimer], a

.C1SFXCheckSign
	;Check "sign" value for pitch slide
	ld a, [C1SFXSign]
	;If 0, then no change
	and a
	jr z, .C1SFXRet

	;If positive, then increase pitch
	bit 7, a
	jr z, .C1SFXIncPitch

.C1SFXDecPitch
	;Else, if negative, then decrease pitch
	ld a, [C1SFXNR13Val]
	ld hl, C1SFXSlideAmt
	sub [hl]
	ld [C1SFXNR13Val], a
	ldh [rNR13], a
	ld a, [C1SFXNR14Val]
	inc hl
	sbc [hl]
	and %00000111
	ld [C1SFXNR14Val], a
	ldh [rNR14], a
	ret


.C1SFXIncPitch
	ld a, [C1SFXNR13Val]
	ld hl, C1SFXSlideAmt
	add [hl]
	ld [C1SFXNR13Val], a
	ldh [rNR13], a
	ld a, [C1SFXNR14Val]
	inc hl
	adc [hl]
	and %00000111
	ld [C1SFXNR14Val], a
	ldh [rNR14], a

.C1SFXRet
	ret


PlaySFXC2:
	ld a, [C2TrigFlag]
	and a
	;If trigger flag is not set, then play SFX
	jr nz, .PlaySFXC2_2

	ret


.PlaySFXC2_2
	;Get sound effect duration
	ld a, [C2SFXLen]
	;If not 0, then go to next section
	and a
	jr nz, .SFXC2Proc

	;Else, if "loop" flag is not 0, then go to next section
	ld a, [C2SFXSlideLoop]
	and a
	jr nz, .SFXC2Proc

	;If play flag is 0, then turn channel 2 SFX off
	ld a, [PlayFlag]
	and a
	jr z, .C2SFXOff

	;Otherwise, get current NR2x values and write to registers
	ld a, [NR21Val]
	ldh [rNR21], a
	ld a, [NR22Val]
	ldh [rNR22], a
	ld a, [NR23Val]
	ldh [rNR23], a
	ld a, [NR24Val]
	set 7, a
	ldh [rNR24], a
	xor a
	ld [C2TrigFlag], a
	ret


;Turn off channel 2
.C2SFXOff
	xor a
	ldh [rNR22], a
	ld [C2TrigFlag], a
	ret


.SFXC2Proc
	;Decrement SFX length
	ld hl, C2SFXLen
	dec [hl]
	;Check number of SFX pitch slides left
	ld a, [C2SFXSlidesLeft]
	and a
	;If not 0, then process next slide
	jr nz, .C2SFXCheckTimer

	;Otherwise, check if "loop" flag is set
	ld a, [C2SFXSlideLoop]
	and a
	jr nz, .C2SFXCheckSlideLen

	;Finally, check if slide is still in process
	ld a, [C2SFXSlideLen]
	and a
	jr nz, .C2SFXCheckSlideLen

	;If all values 0, then return
	ret


.C2SFXCheckSlideLen
	;Get remaining length of slide
	ld hl, C2SFXSlideLen
	dec [hl]
	;Reset pitch slide with count
	ld a, [C2SFXSlideCnt]
	ld [C2SFXSlidesLeft], a
	;Check for RNG flag
	ld a, [C2SFXRNG]
	and a
	;If 0, then skip
	jr z, .C2SFXNoRNG

.C2SFXAddRNG
	;Otherwise, add RNG to frequency
	ld hl, RNG
	ld a, [C2SFXFreqVal]
	add [hl]
	ld [C2SFXNR23Val], a
	ldh [rNR23], a
	ld a, [C2SFXFreqVal+1]
	add [hl]
	and %00000111
	ld [C2SFXNR24Val], a
	ldh [rNR24], a
	jr .C2SFXCheckTimer

.C2SFXNoRNG
	;Process frequency value without RNG
	ld a, [C2SFXFreqVal]
	ld [C2SFXNR23Val], a
	ldh [rNR23], a
	ld a, [C2SFXFreqVal+1]
	and %00000111
	ld [C2SFXNR24Val], a
	ldh [rNR24], a

.C2SFXCheckTimer
	;Decrement amount of pitch slides left
	ld hl, C2SFXSlidesLeft
	dec [hl]
	ld a, [C2SFXSpeed]
	and a
	jr z, .C2SFXCheckSign

	;Return if SFX is not done playing
	ld hl, C2SFXTimer
	dec [hl]
	jr nz, .C2SFXRet

	;Else, reset timer and continue
	ld [C2SFXTimer], a

.C2SFXCheckSign
	;Check "sign" value for pitch slide
	ld a, [C2SFXSign]
	;If 0, then no change
	and a
	jr z, .C2SFXRet

	;If positive, then increase pitch
	bit 7, a
	jr z, .C2SFXIncPitch

.C2SFXDecPitch
	;Else, if negative, then decrease pitch
	ld a, [C2SFXNR23Val]
	ld hl, C2SFXSlideAmt
	sub [hl]
	ld [C2SFXNR23Val], a
	ldh [rNR23], a
	ld a, [C2SFXNR24Val]
	inc hl
	sbc [hl]
	and %00000111
	ld [C2SFXNR24Val], a
	ldh [rNR24], a
	ret


.C2SFXIncPitch
	ld a, [C2SFXNR23Val]
	ld hl, C2SFXSlideAmt
	add [hl]
	ld [C2SFXNR23Val], a
	ldh [rNR23], a
	ld a, [C2SFXNR24Val]
	inc hl
	adc [hl]
	and %00000111
	ld [C2SFXNR24Val], a
	ldh [rNR24], a

.C2SFXRet
	ret


PlaySFXC4:
	ld a, [C4TrigFlag]
	and a
	jr nz, .PlaySFXC4_2

	ret


.PlaySFXC4_2
	;Get sound effect duration
	ld a, [C4SFXLen]
	;If not 0, then go to next section
	and a
	jr nz, .C4SFXProc

	;Else, if "loop" flag is not 0, then go to next section
	ld a, [C4SFXSlideLoop]
	and a
	jr nz, .C4SFXProc

	;If play flag is 0, then turn channel 1 SFX off
	ld a, [PlayFlag]
	and a
	jr z, .C4SFXOff

	;Otherwise, get current NR4x values and write to registers
	ld a, [NR42Val]
	ldh [rNR42], a
	ld a, [NR43Val]
	ldh [rNR43], a
	ld a, %10000000
	ldh [rNR44], a
	xor a
	ld [C4TrigFlag], a
	ret


;Turn off channel 4
.C4SFXOff
	xor a
	ldh [rNR42], a
	ld [C4TrigFlag], a
	ret


.C4SFXProc
	;Decrement SFX length
	ld hl, C4SFXLen
	dec [hl]
	;Check number of SFX pitch slides left
	ld a, [C4SFXSlidesLeft]
	and a
	;If not 0, then process next slide
	jr nz, .C4SFXCheckTimer

	;Otherwise, check if "loop" flag is set
	ld a, [C4SFXSlideLoop]
	and a
	jr nz, .C4SFXCheckSlideLen

	;Finally, check if slide is still in process
	ld a, [C4SFXSlideLen]
	and a
	jr nz, .C4SFXCheckSlideLen

	;If all values 0, then return
	ret


.C4SFXCheckSlideLen
	;Get remaining length of slide
	ld hl, C4SFXSlideLen
	dec [hl]
	;Reset pitch slide with count
	ld a, [C4SFXSlideCnt]
	ld [C4SFXSlidesLeft], a
	;Check for RNG flag
	ld a, [C4SFXRNG]
	and a
	;If 0, then skip
	jr z, .C4SFXNoRNG

.C4SFXAddRNG
	;Otherwise, add RNG to frequency
	ld hl, RNG
	ld a, [C4SFXFreqVal]
	add [hl]
	and %01110111
	ld [C4SFXNR43Val], a
	ldh [rNR43], a
	jr .C4SFXCheckTimer

.C4SFXNoRNG
	;Process frequency value without RNG
	ld a, [C4SFXFreqVal]
	and %01110111
	ld [C4SFXNR43Val], a
	ldh [rNR43], a

.C4SFXCheckTimer
	;Decrement amount of pitch slides left
	ld hl, C4SFXSlidesLeft
	dec [hl]
	;If SFX speed is 0, then go to next section
	ld a, [C4SFXSpeed]
	and a
	jr z, .C4SFXCheckSign

	;Return if SFX is not done playing
	ld hl, C4SFXTimer
	dec [hl]
	jr nz, .C4SFXRet

	;Else, reset timer and continue
	ld [C4SFXTimer], a

.C4SFXCheckSign
	;Check "sign" value for pitch slide
	ld a, [C4SFXSign]
	;If 0, then no change
	and a
	jr z, .C4SFXRet

	;If positive, then increase pitch
	bit 7, a
	jr z, .C4SFXIncPitch

.C4SFXDecPitch
	;Else, if negative, then decrease pitch
	ld a, [C4SFXNR43Val]
	ld hl, C4SFXSlideAmt
	sub [hl]
	and %01110111
	ld [C4SFXNR43Val], a
	ldh [rNR43], a
	ret


.C4SFXIncPitch
	ld a, [C4SFXNR43Val]
	ld hl, C4SFXSlideAmt
	add [hl]
	and %01110111
	ld [C4SFXNR43Val], a
	ldh [rNR43], a

.C4SFXRet
	ret


;Randomly generate a number for SFX
GetRNG:
	ld a, [RNG]
	and $48
	adc $38
	sla a
	sla a
	ld hl, RNG+3
	rl [hl]
	dec hl
	rl [hl]
	dec hl
	rl [hl]
	dec hl
	rl [hl]
	ld a, [hl]
	ret

SFXTab:
	dw SFX00
	dw SFX01
	dw SFX02
	dw SFX03
	dw SFX04
	dw SFX05
	dw SFX06
	dw SFX07
	dw SFX08
	dw SFX09
	dw SFX0A
	dw SFX0B
	dw SFX0C
	dw SFX0D
	dw SFX0E
	dw SFX0F
	dw SFX10
	dw SFX11
	dw SFX12
	dw SFX13
	dw SFX14
	dw SFX15
	dw SFX16
	dw SFX17
	dw SFX18
	dw SFX19
	dw SFX1A
	
SFX00:
	db 10		;Length
	db 99		;Num slides before reset
	dw $0740	;Freq
	dw 40		;Amount
	db $40		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $F1		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX01:
	db 12		;Length
	db 4		;Num slides before reset
	dw $07D7	;Freq
	dw 17		;Amount
	db $80		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $F1		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX02:
	db 15		;Length
	db 3		;Num slides before reset
	dw $0076	;Freq
	dw 126		;Amount
	db $00		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $F2		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX03:
	db 30		;Length
	db 99		;Num slides before reset
	dw $00C0	;Freq
	dw 1		;Amount
	db $80		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 99		;Slide dur
	db $F4		;NRx2
	db 0		;Loop
	db 3		;Speed
SFX04:
	db 30		;Length
	db 99		;Num slides before reset
	dw $0500	;Freq
	dw 64		;Amount
	db $00		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 99		;Slide dur
	db $F3		;NRx2
	db 0		;Loop
	db 3		;Speed
SFX05:
	db 2		;Length
	db 255		;Num slides before reset
	dw $07CC	;Freq
	dw 1		;Amount
	db $00		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 99		;Slide dur
	db $F1		;NRx2
	db 0		;Loop
	db 2		;Speed
SFX06:
	db 50		;Length
	db 3		;Num slides before reset
	dw $0088	;Freq
	dw 6		;Amount
	db $80		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $F3		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX07:
	db 100		;Length
	db 3		;Num slides before reset
	dw $0088	;Freq
	dw 6		;Amount
	db $80		;NRx1
	db 255		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $F7		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX08:
	db 59		;Length
	db 15		;Num slides before reset
	dw $06B0	;Freq
	dw 64		;Amount
	db $40		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 99		;Slide dur
	db $F7		;NRx2
	db 0		;Loop
	db 4		;Speed
SFX09:
	db 9		;Length
	db 2		;Num slides before reset
	dw $008F	;Freq
	dw 20		;Amount
	db $80		;NRx1
	db 255		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $F1		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX0A:
	db 10		;Length
	db 7		;Num slides before reset
	dw $07C8	;Freq
	dw 4		;Amount
	db $80		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 99		;Slide dur
	db $F2		;NRx2
	db 0		;Loop
	db 2		;Speed
SFX0B:
	db 19		;Length
	db 255		;Num slides before reset
	dw $0014	;Freq
	dw 7		;Amount
	db $C0		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 10		;Slide dur
	db $F2		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX0C:
	db 15		;Length
	db 99		;Num slides before reset
	dw $0680	;Freq
	dw 36		;Amount
	db $80		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $F1		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX0D:
	db 15		;Length
	db 99		;Num slides before reset
	dw $0780	;Freq
	dw 100		;Amount
	db $00		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $F2		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX0E:
	db 27		;Length
	db 7		;Num slides before reset
	dw $0777	;Freq
	dw 17		;Amount
	db $80		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $F2		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX0F:
	db 28		;Length
	db 99		;Num slides before reset
	dw $0777	;Freq
	dw 16		;Amount
	db $80		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 99		;Slide dur
	db $1A		;NRx2
	db 0		;Loop
	db 4		;Speed
SFX10:
	db 45		;Length
	db 2		;Num slides before reset
	dw $03DF	;Freq
	dw 16		;Amount
	db $80		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $F3		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX11:
	db 7		;Length
	db 2		;Num slides before reset
	dw $0778	;Freq
	dw 2		;Amount
	db $80		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 99		;Slide dur
	db $F1		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX12:
	db 15		;Length
	db 3		;Num slides before reset
	dw $00C0	;Freq
	dw 1		;Amount
	db $80		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $F3		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX13:
	db 30		;Length
	db 10		;Num slides before reset
	dw $04FF	;Freq
	dw 512		;Amount
	db $80		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 0		;Slide dur
	db $F2		;NRx2
	db 0		;Loop
	db 10		;Speed
SFX14:
	db 80		;Length
	db 3		;Num slides before reset
	dw $0000	;Freq
	dw 2		;Amount
	db $00		;NRx1
	db 255		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $F7		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX15:
	db 3		;Length
	db 5		;Num slides before reset
	dw $0004	;Freq
	dw 0		;Amount
	db $00		;NRx1
	db 0		;RNG
	db 0		;Sign
	db 99		;Slide dur
	db $F7		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX16:
	db 20		;Length
	db 3		;Num slides before reset
	dw $0300	;Freq
	dw 65		;Amount
	db $00		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 99		;Slide dur
	db $09		;NRx2
	db 255		;Loop
	db 0		;Speed
SFX17:
	db 20		;Length
	db 5		;Num slides before reset
	dw $0182	;Freq
	dw 41		;Amount
	db $80		;NRx1
	db 255		;RNG
	db -1		;Sign
	db 255		;Slide dur
	db $F7		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX18:
	db 3		;Length
	db 5		;Num slides before reset
	dw $0003	;Freq
	dw 0		;Amount
	db $00		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 99		;Slide dur
	db $F7		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX19:
	db 30		;Length
	db 5		;Num slides before reset
	dw $0182	;Freq
	dw 41		;Amount
	db $00		;NRx1
	db 255		;RNG
	db -1		;Sign
	db 255		;Slide dur
	db $F2		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX1A:
	db 1		;Length
	db 0		;Num slides before reset
	dw $0000	;Freq
	dw 0		;Amount
	db $00		;NRx1
	db 0		;RNG
	db 0		;Sign
	db 0		;Slide dur
	db $00		;NRx2
	db 0		;Loop
	db 0		;Speed


FreqTab:
	dw $002C
	dw $009D
	dw $0107
	dw $016B
	dw $01CA
	dw $0223
	dw $0277
	dw $02C7
	dw $0312
	dw $0358
	dw $039B
	dw $03DA
	dw $0416
	dw $044E
	dw $0483
	dw $04B5
	dw $04E5
	dw $0511
	dw $053C
	dw $0563
	dw $0589
	dw $05AC
	dw $05CE
	dw $05ED
	dw $060B
	dw $0627
	dw $0642
	dw $065B
	dw $0672
	dw $0689
	dw $069E
	dw $06B2
	dw $06C4
	dw $06D6
	dw $06E7
	dw $06F7
	dw $0706
	dw $0714
	dw $0721
	dw $072D
	dw $0739
	dw $0744
	dw $074F
	dw $0759
	dw $0762
	dw $076B
	dw $0773
	dw $077B
	dw $0783
	dw $078A
	dw $0790
	dw $0797
	dw $079D
	dw $07A2
	dw $07A7
	dw $07AC
	dw $07B1
	dw $07B6
	dw $07BA
	dw $07BE
	dw $07C1
	dw $07C5
	dw $07C8
	dw $07CB
	dw $07CE
	dw $07D1
	dw $07D4
	dw $07D6
	dw $07D9
	dw $07DA
	dw $07DD
	dw $07DF
	dw $07E1
	dw $07E2
	dw $07E4
	dw $07E6
	dw $07E7
	dw $07E9
	dw $07EA
	dw $07EB
	dw $07EC
	dw $07ED
	dw $07EE
	dw $07EF
	dw $07F0
	dw $07F1
	dw $07F2
	dw $07F3
	dw $07F4

VibTab:
	dw Vib00
	dw Vib01
	dw Vib02
	dw Vib03
	dw Vib04
	dw Vib05
	dw Vib06
	dw Vib07
	
Vib00:
	db 0
	db endvib
Vib01:
	db 0, 1, 2, 1, 0, -1, -2, -1
	db endvib
Vib02:
	db 0, 2, 0, -2
	db endvib
Vib03:
	db 0, 1, 0, -1
	db endvib
Vib04:
	db 0, 1, 1, 0, 0, -1, -1, 0
	db endvib
Vib05:
	db 0, 2, 4, 2, 0, -2, -4, -2
	db endvib
Vib06:
	db 0, 4, 0, -4
	db endvib
Vib07:
	db 0, 4, 8, 4, 0, -4, -8, -4
	db endvib

SongTab:
.InGame1
	db 56
	dw InGame1A, InGame1B, InGame1C, InGame1D
.Boss
	db 42
	dw BossA, BossB, BossC, BossD
.Title
	db 33
	dw TitleA, TitleB, TitleC, TitleD
.Credit
	db 96
	dw CreditA, CreditB, CreditC, CreditD
.Victory
	db 33
	dw VictoryA, VictoryB, VictoryC, VictoryD
.EndGame
	db 23
	dw EndGameA, EndGameB, EndGameC, EndGameD
.InGame2
	db 45
	dw InGame2A, InGame2B, InGame2C, InGame2D
.InGame1Restart
	db 36
	dw InGame1ALoop, InGame1BLoop, InGame1CLoop, InGame1D

InGame1A:
	dw InGame1Phrase01
InGame1ALoop:
	dw InGame1Phrase02
	dw 0
InGame1C:
	dw InGame1Phrase03
InGame1CLoop:
	dw InGame1Phrase04
	dw 0
InGame1B:
	dw InGame1Phrase05
InGame1BLoop:
	dw InGame1Phrase06
	dw 0
InGame1D:
	dw EmptyPhrase1
	dw 0

InGame1Phrase01:
	db duty, $40
	db vib, $05
	db env, $0F
	db len32
	db $21
	db env, $F7
	db len1
	db $02
	db $05
	db $09
	db $05
	db $09
	db $0E
	db $09
	db $0E
	db $11
	db $0E
	db $11
	db $15
	db $11
	db $15
	db $1A
	db $15
	db $1A
	db $1D
	db $1A
	db $1D
	db $21
	db $1D
	db $21
	db $26
	db tempo, 36
	db len1
	db $15
	db len5
	db $17
	db len6
	db $18
	db len4
	db $1A
	db len8
	db $F9
	db len4
	db $1A
	db $18
	db len6
	db $1A
	db $1D
	db len4
	db $1F
	db len8
	db $F9
	db len4
	db $1F
	db $1D
	db env, $F1
	db len1
	db $18
	db $18
	db tie
	db $18
	db $18
	db tie
	db $18
	db $18
	db tie
	db $18
	db $18
	db tie
	db $18
	db $18
	db $18
	db $18
	db $1A
	db $1A
	db tie
	db $1A
	db $1A
	db tie
	db $1A
	db $1A
	db tie
	db $1A
	db $1A
	db tie
	db $1A
	db $1A
	db $1A
	db $1A
	db loop
	dw InGame1ALoop
InGame1Phrase02:	
	db env, $F1
	db vib, $03
	db len1
	db $21
	db $21
	db tie
	db $1F
	db tie
	db $1F
	db $21
	db tie
	db tie
	db $21
	db tie
	db $21
	db $24
	db $24
	db $21
	db $1F
	db $21
	db $21
	db tie
	db $1F
	db tie
	db $1F
	db $21
	db tie
	db tie
	db $21
	db tie
	db $21
	db $24
	db $24
	db $21
	db $1F
	db $1F
	db $1F
	db tie
	db $1E
	db tie
	db $1E
	db $1F
	db tie
	db tie
	db $1F
	db tie
	db $1F
	db $23
	db $23
	db $1F
	db $1F
	db $1F
	db $1F
	db tie
	db $1E
	db tie
	db $1E
	db $1F
	db tie
	db tie
	db $1F
	db tie
	db $1F
	db $23
	db $23
	db $1F
	db $1F
	db $21
	db $21
	db tie
	db $1F
	db tie
	db $1F
	db $21
	db tie
	db tie
	db $21
	db tie
	db $21
	db $24
	db $24
	db $21
	db $1F
	db $21
	db $21
	db tie
	db $1F
	db tie
	db $1F
	db $21
	db tie
	db tie
	db $21
	db $24
	db $24
	db $25
	db $25
	db $26
	db $26
	db $1D
	db $1D
	db tie
	db $1C
	db tie
	db $1C
	db $1D
	db tie
	db tie
	db $1D
	db tie
	db $1D
	db $21
	db $21
	db $1D
	db $1D
	db $1F
	db $1F
	db tie
	db $1E
	db tie
	db $1E
	db $1F
	db tie
	db tie
	db $1F
	db tie
	db $1F
	db $23
	db $23
	db $1F
	db $1F
	db env, $F2
	db $28
	db $26
	db $24
	db $23
	db $26
	db $24
	db $23
	db $21
	db $24
	db $23
	db $21
	db $1F
	db $1D
	db $1C
	db $1D
	db $1F
	db $28
	db $26
	db $24
	db $23
	db $26
	db $24
	db $23
	db $21
	db $24
	db $23
	db $21
	db $1F
	db $1D
	db $1C
	db $1D
	db $1F
	db env, $F1
	db $21
	db $21
	db tie
	db $1F
	db tie
	db $1F
	db $21
	db tie
	db tie
	db $21
	db tie
	db $21
	db $24
	db $24
	db $21
	db $1F
	db $1F
	db $1F
	db tie
	db $1E
	db tie
	db $1E
	db $1F
	db tie
	db tie
	db $1F
	db tie
	db $1F
	db $23
	db $23
	db $1F
	db $1F
	db $1D
	db $1D
	db tie
	db $1C
	db tie
	db $1C
	db $1D
	db tie
	db tie
	db $1D
	db tie
	db $1D
	db $21
	db $21
	db $1D
	db $1D
	db env, $F2
	db $1C
	db $20
	db $23
	db $1C
	db $20
	db $23
	db $1C
	db $20
	db $23
	db $1C
	db $20
	db $23
	db $1C
	db $20
	db $23
	db $1C
	db $24
	db $29
	db $2D
	db $23
	db $28
	db $2B
	db $21
	db $26
	db $29
	db $1F
	db $24
	db $28
	db $23
	db $26
	db $24
	db $28
	db $24
	db $29
	db $2D
	db $23
	db $28
	db $2B
	db $21
	db $26
	db $29
	db $1F
	db $24
	db $28
	db $23
	db $26
	db $24
	db $28
	db env, $F1
	db $2B
	db $2B
	db tie
	db $29
	db $29
	db tie
	db $28
	db $28
	db tie
	db $29
	db $29
	db tie
	db $2B
	db $2B
	db $29
	db $29
	db $26
	db $26
	db rest
	db $26
	db $26
	db rest
	db $26
	db $26
	db rest
	db $26
	db $26
	db rest
	db len4
	db env, $F2
	db $26
	db exit
InGame1Phrase03:
	db env, $40, 255
	db vib, $03
	db len32
	db $09
	db len1
	db env, $20, 8
	db $02
	db $05
	db $09
	db $05
	db $09
	db $0E
	db $09
	db $0E
	db $11
	db $0E
	db $11
	db $15
	db $11
	db $15
	db $1A
	db $15
	db $1A
	db $1D
	db $1A
	db $1D
	db $21
	db $1D
	db $21
	db $26
	db env, $20, 6
	db $02
	db $09
	db $0E
	db $02
	db $09
	db $0E
	db $05
	db $0C
	db $11
	db $05
	db $0C
	db $11
	db $07
	db $0E
	db $13
	db $07
	db $0E
	db $13
	db $07
	db $0E
	db $13
	db $07
	db $0E
	db $13
	db $07
	db $0E
	db $13
	db $07
	db $05
	db $0C
	db $11
	db $05
	db $02
	db $09
	db $0E
	db $02
	db $09
	db $0E
	db $05
	db $0C
	db $11
	db $05
	db $0C
	db $11
	db $07
	db $0E
	db $13
	db $07
	db $0E
	db $13
	db $07
	db $0E
	db $13
	db $07
	db $0E
	db $13
	db $07
	db $0E
	db $13
	db $07
	db $05
	db $0C
	db $11
	db $05
	db env, $20, 7
	db $05
	db $0C
	db $11
	db $05
	db $0C
	db $11
	db $05
	db $0C
	db $11
	db $05
	db $0C
	db $11
	db $05
	db $11
	db $05
	db $11
	db $07
	db $0E
	db $13
	db $07
	db $0E
	db $13
	db $07
	db $0E
	db $13
	db $07
	db $0E
	db $13
	db $07
	db $13
	db $07
	db $13
	db env, $20, 6
	db loop
	dw InGame1CLoop
InGame1Phrase04:
	db env, $20, 6
	db vib, $03
	db len1
	db $07
	db $09
	db $09
	db $09
	db $09
	db $09
	db $09
	db $09
	db $09
	db $09
	db $09
	db $09
	db $09
	db $15
	db $09
	db $15
	db $07
	db $09
	db $09
	db $09
	db $09
	db $09
	db $09
	db $09
	db $09
	db $09
	db $09
	db $09
	db $09
	db $15
	db $09
	db $15
	db $05
	db $07
	db $07
	db $07
	db $07
	db $07
	db $07
	db $07
	db $07
	db $07
	db $07
	db $07
	db $07
	db $13
	db $07
	db $13
	db $05
	db $07
	db $07
	db $07
	db $07
	db $07
	db $07
	db $07
	db $07
	db $07
	db $07
	db $07
	db $07
	db $13
	db $07
	db $13
	db $07
	db $09
	db $09
	db $09
	db $09
	db $09
	db $09
	db $09
	db $09
	db $09
	db $09
	db $09
	db $09
	db $15
	db $09
	db $15
	db $07
	db $09
	db $09
	db $09
	db $09
	db $09
	db $09
	db $09
	db $09
	db $09
	db len3
	db $02
	db len2
	db $02
	db len1
	db $04
	db $04
	db $05
	db $05
	db $05
	db $05
	db $05
	db $05
	db $05
	db $05
	db $05
	db $09
	db $09
	db $07
	db $07
	db $05
	db $05
	db $05
	db $07
	db $07
	db $07
	db $07
	db $07
	db $07
	db $07
	db $07
	db $07
	db $0B
	db $0B
	db $09
	db $09
	db $07
	db $07
	db rest
	db $09
	db rest
	db $07
	db rest
	db $07
	db $09
	db rest
	db $10
	db $0F
	db $0E
	db $0C
	db $0E
	db len3
	db $0C
	db len1
	db rest
	db $09
	db rest
	db $07
	db rest
	db $07
	db $09
	db rest
	db $10
	db $0F
	db $0E
	db $0C
	db $0E
	db len3
	db $0C
	db len1
	db $07
	db $09
	db $09
	db $09
	db $09
	db $09
	db $09
	db $09
	db $09
	db $09
	db $09
	db $09
	db $09
	db $15
	db $09
	db $15
	db $05
	db $07
	db $07
	db $07
	db $07
	db $07
	db $07
	db $07
	db $07
	db $07
	db $07
	db $07
	db $07
	db $13
	db $07
	db $13
	db $04
	db $05
	db $05
	db $05
	db $05
	db $05
	db $05
	db $05
	db $05
	db $05
	db $09
	db $09
	db $07
	db $07
	db $05
	db $05
	db $04
	db $04
	db rest
	db $04
	db $04
	db rest
	db $04
	db $04
	db rest
	db $04
	db $04
	db rest
	db $04
	db $04
	db rest
	db $04
	db $05
	db $05
	db $05
	db $04
	db $04
	db $04
	db $02
	db $02
	db $02
	db $00
	db $00
	db $00
	db $0B
	db $0B
	db $0C
	db $0C
	db $05
	db $05
	db $05
	db $04
	db $04
	db $04
	db $02
	db $02
	db $02
	db $00
	db $00
	db $00
	db $0B
	db $0B
	db $0C
	db $0C
	db $02
	db $02
	db $1A
	db $02
	db $02
	db $1A
	db $02
	db $02
	db $1A
	db $02
	db $02
	db $1A
	db $0E
	db $0E
	db $0E
	db $0E
	db $04
	db $04
	db rest
	db $04
	db $04
	db rest
	db $04
	db $04
	db rest
	db $04
	db $04
	db rest
	db len4
	db $04
	db len1
	db exit
InGame1Phrase05:
	db duty, $C0
	db vib, $05
	db env, $0F
	db len32
	db $1C
	db env, $F7
	db len1
	db $0E
	db $11
	db $15
	db $11
	db $15
	db $1A
	db $15
	db $1A
	db $1D
	db $1A
	db $1D
	db $21
	db $1D
	db $21
	db $26
	db $21
	db $26
	db $29
	db $26
	db $29
	db $2D
	db $29
	db $2D
	db $32
	db len6
	db $1A
	db $1D
	db len1
	db $1F
	db $21
	db len2
	db $1F
	db len8
	db tie
	db len4
	db $1F
	db $1D
	db vib, $01
	db len1
	db $24
	db len5
	db $26
	db len6
	db $29
	db len4
	db $32
	db len8
	db tie
	db len4
	db $1A
	db $18
	db duty, $00
	db env, $F1
	db len1
	db $29
	db $29
	db tie
	db $28
	db $28
	db tie
	db $26
	db $26
	db tie
	db $24
	db $24
	db tie
	db len2
	db $23
	db $24
	db len1
	db $2B
	db $2B
	db tie
	db $29
	db $29
	db tie
	db $28
	db $28
	db tie
	db $26
	db $26
	db tie
	db len2
	db $24
	db $26
	db loop
	dw InGame1BLoop
InGame1Phrase06:
	db vib, $02
	db duty, $80
	db env, $F2
	db len1
	db rest
	db len4
	db $2D
	db len3
	db $2B
	db len4
	db $2D
	db len1
	db $1C
	db $1D
	db $1F
	db $21
	db len1
	db tie
	db len4
	db $2D
	db len3
	db $2B
	db len4
	db $2D
	db len1
	db $1C
	db $1D
	db $1F
	db $21
	db len1
	db tie
	db len4
	db $2B
	db len3
	db $2A
	db len4
	db $2B
	db len1
	db $1A
	db $1C
	db $1E
	db $1F
	db len1
	db tie
	db len4
	db $2B
	db len3
	db $2A
	db len4
	db $2B
	db len1
	db $1A
	db $1C
	db $1E
	db $1F
	db len1
	db rest
	db len4
	db $2D
	db len3
	db $2B
	db len4
	db $2D
	db len1
	db $1C
	db $1D
	db $1F
	db $21
	db len1
	db tie
	db len4
	db $2D
	db len3
	db $2B
	db len2
	db $2D
	db $1A
	db len1
	db tie
	db $1B
	db tie
	db $1C
	db duty, $C0
	db env, $F7
	db len9
	db $1D
	db len1
	db $21
	db $22
	db $23
	db len4
	db $24
	db vib, $01
	db len12
	db $2B
	db len1
	db $2B
	db $2D
	db $2E
	db $2F
	db duty, $80
	db env, $F2
	db rest
	db $2D
	db tie
	db $2B
	db tie
	db $2B
	db len6
	db $2D
	db len1
	db $2A
	db len3
	db $28
	db len1
	db rest
	db $2D
	db tie
	db $2B
	db tie
	db $2B
	db len6
	db $2D
	db len1
	db $2A
	db len3
	db $28
	db vib, $02
	db len1
	db rest
	db len4
	db $2D
	db len3
	db $2B
	db len4
	db $2D
	db len1
	db $1C
	db $1D
	db $1F
	db $21
	db len1
	db tie
	db len4
	db $2B
	db len3
	db $2A
	db len4
	db $2B
	db len1
	db $1A
	db $1C
	db $1E
	db $1F
	db len1
	db tie
	db len4
	db $29
	db $62
	db $28
	db len4
	db $29
	db len1
	db $18
	db $1A
	db $1C
	db $1D
	db duty, $C0
	db env, $F7
	db vib, $01
	db len3
	db $28
	db $2A
	db $2F
	db $32
	db len4
	db $34
	db len1
	db vib, $02
	db duty, $80
	db env, $F1
	db $29
	db $29
	db rest
	db $28
	db $28
	db rest
	db $26
	db $26
	db rest
	db $24
	db $24
	db rest
	db len2
	db $23
	db $24
	db len1
	db $29
	db $29
	db rest
	db $28
	db $28
	db rest
	db $26
	db $26
	db rest
	db $24
	db $24
	db rest
	db len2
	db $23
	db $24
	db env, $F7
	db len12
	db $26
	db env, $F2
	db len1
	db $29
	db $2B
	db $2D
	db $2F
	db env, $F1
	db $2B
	db $2B
	db rest
	db $2B
	db $2B
	db rest
	db $2B
	db $2B
	db rest
	db $2B
	db $2B
	db rest
	db env, $F2
	db len4
	db $28
	db exit

BossA:
	dw BossPhrase01
BossALoop:
	dw BossPhrase02
	dw 0
BossC:
	dw BossPhrase03
BossCLoop:
	dw BossPhrase04
	dw 0
BossB:
	dw BossPhrase05
BossBLoop:
	dw BossPhrase06
	dw 0
BossD:
	dw EmptyPhrase1
	dw 0

BossPhrase01:
	db duty, $40
	db vib, $03
	db env, $F7
	db len1
	db $09
	db $0C
	db $0E
	db $0C
	db $0E
	db $10
	db $0E
	db $10
	db $13
	db $10
	db $13
	db $15
	db $13
	db $15
	db $18
	db $15
	db $18
	db $1A
	db $18
	db $1A
	db $1C
	db $1A
	db $1C
	db $1F
	db $1C
	db $1F
	db $21
	db $1F
	db $21
	db $24
	db $1F
	db $21
	db $24
	db $21
	db $24
	db $26
	db len12
	db $28
	db loop
	dw BossALoop
BossPhrase02:
	db env, $0A
	db len4
	db $34
	db $34
	db $33
	db $33
	db $34
	db $34
	db $33
	db $33
	db $34
	db $34
	db $33
	db $33
	db $34
	db $34
	db $33
	db $33
	db len1
	db env, $F1
	db duty, $00
	db tp, -12
	db $2D
	db $2C
	db $2D
	db $2C
	db $2C
	db $2B
	db $2C
	db $2B
	db $2B
	db $2A
	db $2B
	db $2A
	db $2A
	db $29
	db $2A
	db $29
	db $2B
	db $2A
	db $2B
	db $2A
	db $2A
	db $29
	db $2A
	db $29
	db $29
	db $28
	db $29
	db $28
	db $28
	db $27
	db $28
	db $27
	db $28
	db $28
	db $28
	db $28
	db $29
	db $29
	db $29
	db $29
	db $2A
	db $2A
	db $2A
	db $2A
	db $2B
	db $2B
	db $2B
	db $2B
	db $2C
	db $2C
	db $2C
	db $2C
	db $2D
	db $2D
	db $2D
	db $2D
	db $2E
	db $2E
	db $2E
	db $2E
	db $2F
	db $2F
	db $2F
	db $2F
	db duty, $40
	db tp, 0
	db exit
BossPhrase03:
	db env, $20, 255
	db vib, $03
	db len1
	db $09
	db $0C
	db $0E
	db $0C
	db $0E
	db $10
	db $0E
	db $10
	db $13
	db $10
	db $13
	db $15
	db $13
	db $15
	db $18
	db $15
	db $18
	db $1A
	db $18
	db $1A
	db $1C
	db $1A
	db $1C
	db $1F
	db $1C
	db $1F
	db $21
	db $1F
	db $21
	db $24
	db $1F
	db $21
	db $24
	db $21
	db $24
	db $26
	db len12
	db $28
	db loop
	dw BossCLoop
BossPhrase04:	
	db env, $20, 8
	db len2
	db $09
	db $09
	db $09
	db $09
	db $08
	db $08
	db $08
	db $08
	db $09
	db $09
	db $09
	db $09
	db $08
	db $08
	db $08
	db $08
	db $09
	db $09
	db $09
	db $09
	db $08
	db $08
	db $08
	db $08
	db $09
	db $09
	db $09
	db $09
	db $08
	db $08
	db $08
	db $08
	db $09
	db $09
	db $09
	db $09
	db $06
	db $06
	db $06
	db $06
	db $07
	db $07
	db $07
	db $07
	db $04
	db $04
	db $04
	db $04
	db len1
	db env, $20, 6
	db $09
	db $09
	db $09
	db $09
	db $0A
	db $0A
	db $0A
	db $0A
	db $0B
	db $0B
	db $0B
	db $0B
	db $0C
	db $0C
	db $0C
	db $0C
	db $0D
	db $0D
	db $0D
	db $0D
	db $0E
	db $0E
	db $0E
	db $0E
	db $0F
	db $0F
	db $0F
	db $0F
	db $10
	db $10
	db $10
	db $10
	db exit
BossPhrase05:
	db duty, $C0
	db vib, $01
	db env, $F7
	db len1
	db tp, 12
	db $09
	db $0C
	db $0E
	db $0C
	db $0E
	db $10
	db $0E
	db $10
	db $13
	db $10
	db $13
	db $15
	db $13
	db $15
	db $18
	db $15
	db $18
	db $1A
	db $18
	db $1A
	db $1C
	db $1A
	db $1C
	db $1F
	db $1C
	db $1F
	db $21
	db $1F
	db $21
	db $24
	db $1F
	db $21
	db $24
	db $21
	db $24
	db $26
	db len12
	db $28
	db tp, 0
	db loop
	dw BossBLoop
BossPhrase06:
	db env, $F3
	db vib, $01
	db len3
	db $21
	db $20
	db len2
	db $21
	db len3
	db $24
	db $23
	db len2
	db $1F
	db len3
	db $21
	db $20
	db len2
	db $21
	db len3
	db $1A
	db $1B
	db len2
	db $1C
	db len3
	db $21
	db $20
	db len2
	db $21
	db len3
	db $24
	db $23
	db len2
	db $1F
	db len3
	db $21
	db $20
	db len2
	db $21
	db len3
	db $1A
	db $1B
	db len2
	db $1C
	db len3
	db $21
	db $20
	db len2
	db $1F
	db env, $F4
	db len8
	db $1E
	db env, $F2
	db len3
	db $1F
	db $1E
	db len2
	db $1D
	db env, $F4
	db len8
	db $1C
	db env, $F3
	db len3
	db $1A
	db $1B
	db len2
	db $1C
	db len3
	db $1D
	db $1E
	db len2
	db $1F
	db len3
	db $20
	db $21
	db len2
	db $23
	db len3
	db $24
	db $25
	db len2
	db $26
	db exit

TitleA:
	dw TitlePhrase01
	dw 0
TitleC:
	dw TitlePhrase02
	dw 0
TitleB:
	dw TitlePhrase03
	dw 0
TitleD:
	dw EmptyPhrase1
	dw 0

TitlePhrase01:
	db duty, $40
	db vib, $07
	db env, $E7
	db len16
	db $0B
	db $0A
	db exit
TitlePhrase02:
	db env, $20, 48
	db vib, $07
	db len8
	db $04
	db $04
	db $03
	db $03
	db exit
TitlePhrase03:
	db duty, $C0
	db vib, $01
	db env, $F2
	db len2
	db $28
	db $27
	db $28
	db $27
	db $28
	db $27
	db $28
	db $2A
	db $28
	db $27
	db $28
	db $27
	db $28
	db $27
	db $23
	db $24
	db exit
	
CreditA:
	dw CreditPhrase01
	dw 0
CreditC:
	dw EmptyPhrase2
	dw 0
CreditB:
	dw CreditPhrase02
	dw 0
CreditD:
	dw EmptyPhrase1
	dw 0

CreditPhrase01:
	db duty, $80
	db vib, $01
	db env, $E2
	db len2
	db $48
	db $3C
	db $36
	db $30
	db $2A
	db $24
	db $1E
	db $18
	db $12
	db $0C
	db $06
	db $00
	db end
CreditPhrase02:
	db duty, $80
	db vib, $01
	db env, $F2
	db len1
	db rest
	db len2
	db $45
	db $39
	db $33
	db $2D
	db $27
	db $21
	db $1B
	db $15
	db $0F
	db $09
	db len8
	db $03
	db exit

VictoryA:
	dw VictoryPhrase01
	dw 0
VictoryC:
	dw VictoryPhrase02
	dw 0
VictoryB:
	dw VictoryPhrase03
	dw 0
VictoryD:
	dw EmptyPhrase1
	dw 0

VictoryPhrase01:
	db duty, $40
	db vib, $03
	db env, $D4
	db len4
	db $29
	db $28
	db $26
	db $24
	db $2B
	db $29
	db $28
	db $26
	db len2
	db $2D
	db $2C
	db $2A
	db $28
	db $26
	db $25
	db $26
	db $28
	db env, $F7
	db len32
	db $34
	db exit
VictoryPhrase02:
	db env, $20, 28
	db vib, $05
	db len4
	db $05
	db $00
	db $05
	db $00
	db $07
	db $02
	db $07
	db $02
	db env, $20, 14
	db len2
	db $09
	db $04
	db $09
	db $04
	db $09
	db $04
	db $09
	db $04
	db env, $20, 255
	db len12
	db $09
	db end
VictoryPhrase03:
	db duty, $C0
	db vib, $05
	db env, $F5
	db len6
	db $11
	db len2
	db $15
	db $18
	db len4
	db $16
	db len2
	db $15
	db len6
	db $13
	db len2
	db $17
	db $1A
	db len4
	db $18
	db len2
	db $17
	db vib, $01
	db len6
	db $15
	db len2
	db $19
	db $1C
	db len4
	db $21
	db len2
	db $23
	db env, $F7
	db len32
	db $25
	db exit

EndGameA:
	dw EndGamePhrase01
	dw 0
EndGameC:
	dw EndGamePhrase02
	dw 0
EndGameB:
	dw EndGamePhrase03
	dw 0
EndGameD:
	dw EmptyPhrase1
	dw 0

EndGamePhrase01:
	db duty, $40
	db vib, $01
	db env, $1E
	db len16
	db $23
	db $28
	db $23
	db $2D
	db len4
	db env, $00
	db $00
	db env, $F6
	db $23
	db rest
	db $2F
	db rest
	db $28
	db rest
	db $2D
	db rest
	db $23
	db rest
	db $2F
	db rest
	db $28
	db rest
	db $2D
	db vib, $03
	db env, $F2
	db len1
	db $21
	db $21
	db $24
	db $24
	db $21
	db $21
	db $1D
	db $1D
	db $24
	db $24
	db $28
	db $28
	db $24
	db $24
	db $21
	db $21
	db $23
	db $23
	db $2B
	db $2B
	db $26
	db $26
	db $23
	db $23
	db $23
	db $23
	db $26
	db $26
	db $23
	db $23
	db $1F
	db $1F
	db $21
	db $21
	db $29
	db $29
	db $24
	db $24
	db $21
	db $21
	db $23
	db $23
	db $29
	db $29
	db $26
	db $26
	db $23
	db $23
	db env, $F7
	db vib, $01
	db len4
	db $28
	db $24
	db $23
	db $1F
	db len12
	db $23
	db end
EndGamePhrase02:
	db vib, $05
	db env, $20, 80
	db len8
	db $00
	db env, $20, 28
	db len3
	db $0B
	db $09
	db len2
	db $07
	db env, $20, 80
	db len8
	db $05
	db env, $20, 28
	db len3
	db $10
	db $0E
	db len2
	db $0C
	db env, $20, 80
	db len8
	db $00
	db env, $20, 28
	db len3
	db $0B
	db $09
	db len2
	db $07
	db env, $20, 80
	db len8
	db $05
	db env, $20, 28
	db len3
	db $10
	db $0E
	db len2
	db $00
	db env, $20, 18
	db len2
	db $0C
	db $0C
	db $0C
	db vib, $03
	db len1
	db $24
	db $2B
	db vib, $05
	db len2
	db $0C
	db $0C
	db $0C
	db vib, $03
	db len1
	db $23
	db $2B
	db vib, $05
	db len2
	db $05
	db $05
	db $05
	db vib, $03
	db len1
	db $1D
	db $24
	db vib, $05
	db len2
	db $05
	db $05
	db $05
	db vib, $03
	db len1
	db $1D
	db $24
	db vib, $05
	db len2
	db $0C
	db $0C
	db $0C
	db vib, $03
	db len1
	db $24
	db $2B
	db vib, $05
	db len2
	db $0C
	db $0C
	db $0C
	db vib, $03
	db len1
	db $23
	db $2B
	db vib, $05
	db len2
	db $05
	db $05
	db $05
	db vib, $03
	db len1
	db $1D
	db $24
	db vib, $05
	db len2
	db $05
	db $05
	db $05
	db vib, $03
	db len1
	db $1D
	db $24
	db vib, $05
	db env, $20, 16
	db len2
	db $05
	db $05
	db $05
	db $05
	db env, $20, 32
	db len3
	db $10
	db $0C
	db len2
	db $09
	db env, $20, 16
	db len2
	db $04
	db $04
	db $04
	db $04
	db env, $20, 32
	db len3
	db $0E
	db $0B
	db len2
	db $07
	db env, $20, 16
	db len2
	db $02
	db $02
	db $02
	db $02
	db env, $20, 32
	db len3
	db $0C
	db $09
	db len2
	db $05
	db env, $20, 40
	db len4
	db $00
	db $0B
	db $07
	db $04
	db len10
	db env, $60, 255
	db $00
	db end
EndGamePhrase03:
	db duty, $80
	db env, $73
	db $60
	db $3B
	db $3B
	db $37
	db $37
	db $34
	db $34
	db $30
	db $30
	db $3B
	db $3B
	db $37
	db $37
	db $34
	db $34
	db $30
	db $30
	db $3C
	db $3C
	db $39
	db $39
	db $34
	db $34
	db $30
	db $30
	db $3C
	db $3C
	db $39
	db $39
	db $34
	db $34
	db $30
	db $30
	db $3B
	db $3B
	db $37
	db $37
	db $34
	db $34
	db $30
	db $30
	db $3B
	db $3B
	db $37
	db $37
	db $34
	db $34
	db $30
	db $30
	db $3C
	db $3C
	db $39
	db $39
	db $34
	db $34
	db $30
	db $30
	db $3C
	db $3C
	db $39
	db $39
	db $34
	db $34
	db $30
	db $30
	db duty, $C0
	db env, $1A
	db vib, $05
	db len8
	db $1C
	db $1F
	db $18
	db tie
	db $1C
	db $1F
	db vib, $01
	db $24
	db tie
	db $29
	db $2D
	db $28
	db $2B
	db $26
	db $29
	db vib, $05
	db len4
	db $23
	db $1F
	db $1C
	db $18
	db len12
	db env, $F7
	db $0C
	db end

InGame2A:
	dw InGame2Phrase01
	dw 0
InGame2C:
	dw InGame2Phrase02
	dw 0
InGame2B:
	dw InGame2Phrase03
	dw 0
InGame2D:
	dw EmptyPhrase1
	dw 0

InGame2Phrase01:	
	db vib, $02
 	db duty, $80
 	db env, $83
 	db len1
 	db $23
 	db $22
 	db $21
 	db $20
 	db $1F
 	db $1E
 	db $1D
 	db $1C
 	db $1B
 	db $1A
 	db $19
 	db $18
 	db $17
 	db $16
 	db $15
 	db $14
 	db $23
 	db $22
 	db $21
 	db $20
 	db $1F
 	db $1E
 	db $1D
 	db $1C
 	db $1B
 	db $1A
 	db $19
 	db $18
 	db $17
 	db $16
 	db $15
 	db $14
 	db $23
 	db $22
 	db $21
 	db $20
 	db $1F
 	db $1E
 	db $1D
 	db $1C
 	db $1B
 	db $1A
 	db $19
 	db $18
 	db $17
 	db $16
 	db $15
 	db $14
 	db $23
 	db $22
 	db $21
 	db $20
 	db $1F
 	db $1E
 	db $1D
 	db $1C
 	db $1B
 	db $1A
 	db $19
 	db $18
 	db $17
 	db $16
 	db $15
 	db $14
 	db env, $C7
 	db len3
 	db $1F
 	db $21
 	db len2
 	db $22
 	db len3
 	db $23
 	db $22
 	db len2
 	db $1F
 	db duty, $40
 	db len1
 	db $2F
 	db $2E
 	db $2D
 	db $2B
 	db $2D
 	db $2B
 	db $2A
 	db $28
 	db $2A
 	db $28
 	db $27
 	db $24
 	db len4
 	db $23
 	db duty, $80
 	db env, $83
 	db len1
 	db $23
 	db $22
 	db $21
 	db $20
 	db $1F
 	db $1E
 	db $1D
 	db $1C
 	db $1B
 	db $1A
 	db $19
 	db $18
 	db $17
 	db $16
 	db $15
 	db $14
 	db $23
 	db $22
 	db $21
 	db $20
 	db $1F
 	db $1E
 	db $1D
 	db $1C
 	db $1B
 	db $1A
 	db $19
 	db $18
 	db $17
 	db $16
 	db $15
 	db $14
 	db $23
 	db $22
 	db $21
 	db $20
 	db $1F
 	db $1E
 	db $1D
 	db $1C
 	db $1B
 	db $1A
 	db $19
 	db $18
 	db $17
 	db $16
 	db $15
 	db $14
 	db $23
 	db $22
 	db $21
 	db $20
 	db $1F
 	db $1E
 	db $1D
 	db $1C
 	db $1B
 	db $1A
 	db $19
 	db $18
 	db $17
 	db $16
 	db $15
 	db $14
 	db $23
 	db $22
 	db $21
 	db $20
 	db $1F
 	db $1E
 	db $1D
 	db $1C
 	db $1B
 	db $1A
 	db $19
 	db $18
 	db $17
 	db $16
 	db $15
 	db $14
 	db $23
 	db $22
 	db $21
 	db $20
 	db $1F
 	db $1E
 	db $1D
 	db $1C
 	db $1B
 	db $1A
 	db $19
 	db $18
 	db $17
 	db $16
 	db $15
 	db $14
 	db $23
 	db $22
 	db $21
 	db $20
 	db $1F
 	db $1E
 	db $1D
 	db $1C
 	db $1B
 	db $1A
 	db $19
 	db $18
 	db $17
 	db $16
 	db $15
 	db $14
 	db $23
 	db $22
 	db $21
 	db $20
 	db $1F
 	db $1E
 	db $1D
 	db $1C
 	db $1B
 	db $1A
 	db $19
 	db $18
 	db $17
 	db $16
 	db $15
 	db $14
 	db $23
 	db $22
 	db $21
 	db $20
 	db $1F
 	db $1E
 	db $1D
 	db $1C
 	db $1B
 	db $1A
 	db $19
 	db $18
 	db $17
 	db $16
 	db $15
 	db $14
 	db $23
 	db $22
 	db $21
 	db $20
 	db $1F
 	db $1E
 	db $1D
 	db $1C
 	db $1B
 	db $1A
 	db $19
 	db $18
 	db $17
 	db $16
 	db $15
 	db $14
 	db $23
 	db $22
 	db $21
 	db $20
 	db $1F
 	db $1E
 	db $1D
 	db $1C
 	db $1B
 	db $1A
 	db $19
 	db $18
 	db $17
 	db $16
 	db $15
 	db $14
 	db $23
 	db $22
 	db $21
 	db $20
 	db $1F
 	db $1E
 	db $1D
 	db $1C
 	db $1B
 	db $1A
 	db $19
 	db $18
 	db $17
 	db $16
 	db $15
 	db $14
 	db $23
 	db $22
 	db $21
 	db $20
 	db $1F
 	db $1E
 	db $1D
 	db $1C
 	db $1B
 	db $1A
 	db $19
 	db $18
 	db $17
 	db $16
 	db $15
 	db $14
 	db $23
 	db $22
 	db $21
 	db $20
 	db $1F
 	db $1E
 	db $1D
 	db $1C
 	db $1B
 	db $1A
 	db $19
 	db $18
 	db $17
 	db $16
 	db $15
 	db $14
 	db vib, $03
 	db $23
 	db $24
 	db $25
 	db $26
 	db $27
 	db $28
 	db $29
 	db $2A
 	db $2B
 	db $2C
 	db $2D
 	db $2E
 	db $2F
 	db $30
 	db $31
 	db $32
 	db vib, $00
 	db $2F
 	db $30
 	db $31
 	db $32
 	db $33
 	db $34
 	db $35
 	db $36
 	db $37
 	db $38
 	db $39
 	db $3A
 	db $3B
 	db $3C
 	db $3D
 	db $3E
	db exit
InGame2Phrase02:
	db env, $20, 9
	db vib, $02
	db len2
	db $04
	db len6
	db $04
	db len2
	db $04
	db len6
	db $04
	db len2
	db $04
	db len6
	db $04
	db len2
	db $04
	db len6
	db $04
	db len2
	db $04
	db len6
	db $04
	db len2
	db $04
	db len6
	db $04
	db len2
	db $04
	db len6
	db $04
	db len2
	db $04
	db len6
	db $04
	db len2
	db $0B
	db len6
	db $0B
	db len2
	db $0B
	db len6
	db $0B
	db len2
	db $0B
	db len6
	db $0B
	db len2
	db $0B
	db len6
	db $0B
	db len2
	db $04
	db len6
	db $04
	db len2
	db $04
	db len6
	db $04
	db len2
	db $04
	db len6
	db $04
	db len2
	db $04
	db len6
	db $04
	db len2
	db $04
	db len6
	db $04
	db len2
	db $04
	db len6
	db $04
	db len2
	db $04
	db len6
	db $04
	db len2
	db $04
	db len6
	db $04
	db len2
	db $02
	db len6
	db $02
	db len2
	db $02
	db len6
	db $02
	db len2
	db $01
	db len6
	db $01
	db len2
	db $01
	db len6
	db $01
	db len2
	db $0B
	db len6
	db $0B
	db len2
	db $0B
	db len6
	db $0B
	db len2
	db $0B
	db len6
	db $0B
	db len2
	db $0B
	db len6
	db $0B
	db len2
	db $04
	db len6
	db $04
	db len2
	db $04
	db len6
	db $04
	db len2
	db $02
	db len6
	db $02
	db len2
	db $02
	db len6
	db $02
	db len2
	db $04
	db len6
	db $04
	db len2
	db $04
	db len6
	db $04
	db len2
	db $04
	db len6
	db $04
	db len2
	db $04
	db len6
	db $04
	db len2
	db $04
	db len6
	db $04
	db len2
	db $04
	db len6
	db $04
	db len2
	db $02
	db len6
	db $02
	db len2
	db $02
	db len6
	db $02
	db len2
	db $0B
	db len6
	db $0B
	db len2
	db $0B
	db len6
	db $0B
	db len2
	db $0B
	db len6
	db $0B
	db len2
	db $0B
	db len6
	db $0B
	db exit
InGame2Phrase03:
	db duty, $C0
	db env, $F7
	db vib, $05
	db len8
	db rest
	db len1
	db $28
	db $26
	db len22
	db $23
	db len8
	db tie
	db len1
	db $23
	db $22
	db len22
	db $1F
	db env, $F3
	db len3
	db $18
	db $1A
	db len2
	db $1B
	db len3
	db $1C
	db $1B
	db len2
	db $1A
	db env, $F7
	db len16
	db $17
	db $28
	db len14
	db $27
	db len2
	db $24
	db len32
	db $23
	db len16
	db $26
	db len12
	db $25
	db len2
	db $23
	db $21
	db len32
	db $23
	db len16
	db $1F
	db len14
	db $21
	db len2
	db $1E
	db len32
	db $1C
	db len16
	db $23
	db len12
	db $26
	db len2
	db $23
	db $21
	db len32
	db $23
	db exit

EmptyPhrase1:
	db len32
	db env, $00
	db $00
	db exit
EmptyPhrase2:
	db len32
	db env, $00
	db $00
	db $00
	db exit
	
SECTION "Audio RAM", WRAMX[AudioRAM]

PlayFlag: ds 1
C1TrigFlag: ds 1
C2TrigFlag: ds 1
C4TrigFlag: ds 1
Tempo: ds 2
RNG: ds 4
BeatCounter: ds 1
GlobalTrans: ds 1
SongPlayFlag: ds 2
C1Pos: ds 2
C1Start: ds 2
C1PatPos: ds 2
C1Trans: ds 1
C1Len: ds 1
C1Delay: ds 1
C1Sweep: ds 1
C1VibPos: ds 1
C1Vibrato: ds 1
C1Freq: ds 2
C1EnvLen: ds 1
C1EnvDelay: ds 1
C2Pos: ds 2
C2Start: ds 2
C2PatPos: ds 2
C2Trans: ds 1
C2Len: ds 1
C2Delay: ds 1
C2Sweep: ds 1
C2VibPos: ds 1
C2Vibrato: ds 1
C2Freq: ds 2
C2EnvLen: ds 1
C2EnvDelay: ds 1
C3Pos: ds 2
C3Start: ds 2
C3PatPos: ds 2
C3Trans: ds 1
C3Len: ds 1
C3Delay: ds 1
C3Sweep: ds 1
C3VibPos: ds 1
C3Vibrato: ds 1
C3Freq: ds 2
C3EnvLen: ds 1
C3EnvDelay: ds 1
C4Pos: ds 2
C4Start: ds 2
C4PatPos: ds 2
C4Trans: ds 1
C4Len: ds 1
C4Delay: ds 1
C4Sweep: ds 1
C4VibPos: ds 1
C4Vibrato: ds 1
C4Freq: ds 2
C4EnvLen: ds 1
C4EnvDelay: ds 1
Sweep: ds 1
NR11Val: ds 1
NR12Val: ds 1
NR13Val: ds 1
NR14Val: ds 1
NR21Val: ds 1
NR22Val: ds 1
NR23Val: ds 1
NR24Val: ds 1
NR30Val: ds 1
NR31Val: ds 1
NR32Val: ds 1
NR33Val: ds 1
NR34Val: ds 1
NR41Val: ds 1
NR42Val: ds 1
NR43Val: ds 1
NR44Val: ds 1
C1SFXLen: ds 1
C1SFXSlideCnt: ds 1
C1SFXFreqVal: ds 2
C1SFXSlideAmt: ds 2
C1SFXNR11Val: ds 1
C1SFXRNG: ds 1
C1SFXSign: ds 1
C1SFXSlideLen: ds 1
C1SFXNR12Val: ds 1
C1SFXSlideLoop: ds 1
C1SFXSpeed: ds 1
C1SFXNR13Val: ds 1
C1SFXNR14Val: ds 1
C1SFXSlidesLeft: ds 1
C1SFXTimer: ds 1
C2SFXLen: ds 1
C2SFXSlideCnt: ds 1
C2SFXFreqVal: ds 2
C2SFXSlideAmt: ds 2
C2SFXNR21Val: ds 1
C2SFXRNG: ds 1
C2SFXSign: ds 1
C2SFXSlideLen: ds 1
C2SFXNR22Val: ds 1
C2SFXSlideLoop: ds 1
C2SFXSpeed: ds 1
C2SFXNR23Val: ds 1
C2SFXNR24Val: ds 1
C2SFXSlidesLeft: ds 1
C2SFXTimer: ds 1
C4SFXLen: ds 1
C4SFXSlideCnt: ds 1
C4SFXFreqVal: ds 2
C4SFXSlideAmt: ds 2
C4SFXNR41Val: ds 1
C4SFXRNG: ds 1
C4SFXSign: ds 1
C4SFXSlideLen: ds 1
C4SFXNR42Val: ds 1
C4SFXSlideLoop: ds 1
C4SFXSpeed: ds 1
C4SFXNR43Val: ds 1
C4SFXNR44Val: ds 1
C4SFXSlidesLeft: ds 1
C4SFXTimer: ds 1