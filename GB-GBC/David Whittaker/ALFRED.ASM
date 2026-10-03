;Alfred Chicken audio disassembly
;Original audio & code by David Whittaker
;Disassembly by Will Trowbridge

include "HARDWARE.INC"

def AudioROM equ $4100
def AudioRAM equ $DF00
def WaveRAM equ $FF30
def SongCnt equ $09
def SFXCnt equ $4B

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

SECTION "Audio", ROMX[AudioROM], BANK[$1]

	jp LoadSong


	jp PlaySong


Init:
	jp InitRoutine


	jp SetNRVals


	jp LoadSFXC1


	jp LoadSFXC2


	jp LoadSFXC4


LoadSong:
	;Check if song number is less than total
	cp SongCnt
	;Return if song number is too high
	ret nc

	;Otherwise, start initializing song
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
	;Initialize CH3 waveform
	ld hl, Waveform
	ld de, WaveRAM
	ld b, $10

.CopyWave
	ld a, [hl+]
	ld [de], a
	inc de
	dec b
	jr nz, .CopyWave

	jr Init2

Waveform:
	db $00, $00, $00, $00, $00, $00, $FF, $FF, $00, $00, $00, $00, $00, $00, $FF, $FF

Init2:
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


;Disable music
MusicOff:
	xor a
	ld [PlayFlag], a
	;Clear channel envelopes
	ldh [rNR12], a
	ldh [rNR22], a
	ldh [rNR32], a
	ldh [rNR42], a
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
	jp C3ProcEnv


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
	push hl
	;Add both transpose values to note
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
	ld b, 0
	
.C1EventExit
;FF = End of phrase
	;Is this the command?
	cp exit
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

	;Load the parameter value into RAM
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

	;Load the parameter into RAM
	ld a, [hl+]
	ld [C1Vibrato], a
	;Reset vibrato sequence position
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
	jp MusicOff


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
	;If not set, then is rest/tie
	jr nz, .C2UpdatePos

	;Otherwise, play new note
	ld a, [NR21Val]
	ldh [rNR21], a
	ld a, [NR22Val]
	ldh [rNR22], a
	ld a, [NR23Val]
	ldh [rNR23], a
	ld a, [NR24Val]
	set 7, a
	ldh [rNR24], a

.C2UpdatePos
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
	ld a, $02
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
	cp $f8
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

	;Load the parameter into RAM
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
	;If not, then check for next command
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
	jp MusicOff


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
	jr nz, .C3EventEnv2

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
.C3EventEnv2
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
	jp MusicOff


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
C3ProcEnv:
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
	jp MusicOff


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

LoadSFXC1:
	;If SFX number is larger than total, set to maximum
	cp SFXCnt
	jr c, .LoadSFXC1_2

	ld a, SFXCnt

.LoadSFXC1_2
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

.C1CopySFX
	ld a, [hl+]
	ld [de], a
	inc de
	dec c
	jr nz, .C1CopySFX

.C1InitSFX
	;Get SFX timer and length
	ld a, [C1SFXSpeed]
	ld [C1SFXTimer], a
	ld a, [C1SFXSlideCnt]
	ld [C1SFXSlidesLeft], a
	;Reset sweep
	xor a
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
	;If SFX number is larger than total, set to maximum
	cp SFXCnt
	jr c, .LoadSFXC2_2

	ld a, SFXCnt

.LoadSFXC2_2
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
	;If SFX number is larger than total, set to maximum
	cp SFXCnt
	jr c, .LoadSFXC4_2

	ld a, SFXCnt

.LoadSFXC4_2
	;Get pointer to current sound effect from table
	add a
	ld c, a
	;Clear trigger
	xor a
	ld b, a
	ld [C4TrigFlag], a
	ld hl, SFXTab
	add hl, bc
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	;Copy SFX values into RAM
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
	and %01111111
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


PlaySFXC1:
	ld a, [C1TrigFlag]
	and a
	;If trigger flag is not set, then play SFX
	jr nz, .PlaySFXC1_2

	ret


;Get sound effect duration
.PlaySFXC1_2
	ld a, [C1SFXLen]
	;If not 0, then go to next section
	and a
	jr nz, .C1SFXProc

	;Else, if "loop" flag is not 0, then go to next section
	ld a, [C1SFXSlideLoop]
	and a
	jr nz, .C1SFXProc

	;If play flag is 0, then turn channel 1 SFX off
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

.C1SFXNoRNG:
	;Process frequency value without RNG
	ld a, [C1SFXFreqVal]
	ld [C1SFXNR13Val], a
	ldh [rNR13], a
	ld a, [C1SFXFreqVal+1]
	and %00000111
	ld [C1SFXNR14Val], a
	ldh [rNR14], a

.C1SFXCheckTimer:
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


.C1SFXIncPitch:
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
	jr nz, .C2SFXProc

	;Else, if "loop" flag is not 0, then go to next section
	ld a, [C2SFXSlideLoop]
	and a
	jr nz, .C2SFXProc

	;If play flag is 0, then turn channel 2 SFX off
	xor a
	ldh [rNR22], a
	ld [C2TrigFlag], a
	ret


.C2SFXProc
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
	;If SFX speed is 0, then go to next section
	ld a, [C2SFXSpeed]
	and a
	jr z, .C2SFXCheckSign

	;Return if SFX is not done playing
	ld hl, C2SFXTimer
	dec [hl]
	jr nz, .C2SFXRet

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
	;If trigger flag is not set, then play SFX
	jr nz, .PlaySFXC4

	ret


.PlaySFXC4
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
	and %01111111
	ld [C4SFXNR43Val], a
	ldh [rNR43], a
	jr .C4SFXCheckTimer

.C4SFXNoRNG
	;Process frequency value without RNG
	ld a, [C4SFXFreqVal]
	and %01111111
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
	and %01111111
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

;SFX format:
;xx yy zz zz aa aa bb cc dd ee ff gg hh
;x = Total length
;y = Number of times to slide pitch (before reset)
;z = Initial frequency
;a = Amount to slide pitch
;b = NRx1 value
;c = RNG flag (0 = no RNG, other = RNG)
;d = Sign value (0 = no pitch change, positive = pitch up, negative = pitch down)
;e = Total duration to slide pitch
;f = NRx2 value
;g = Toggle endless pitch slide loop (0 = no loop, other = loop)
;h = Speed

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
	dw SFX1B
	dw SFX1C
	dw SFX1D
	dw SFX1E
	dw SFX1F
	dw SFX20
	dw SFX21
	dw SFX22
	dw SFX23
	dw SFX24
	dw SFX25
	dw SFX26
	dw SFX27
	dw SFX28
	dw SFX29
	dw SFX2A
	dw SFX2B
	dw SFX2C
	dw SFX2D
	dw SFX2E
	dw SFX2F
	dw SFX30
	dw SFX31
	dw SFX32
	dw SFX33
	dw SFX34
	dw SFX35
	dw SFX36
	dw SFX37
	dw SFX38
	dw SFX39
	dw SFX3A
	dw SFX3B
	dw SFX3C
	dw SFX3D
	dw SFX3E
	dw SFX3F
	dw SFX40
	dw SFX41
	dw SFX42
	dw SFX43
	dw SFX44
	dw SFX45
	dw SFX46
	dw SFX47
	dw SFX48
	dw SFX49
	dw SFX4A
	dw SFX4B
	
SFX00:
	db 30		;Length
	db 5		;Num slides before reset
	dw $0480	;Freq
	dw 64		;Amount
	db $80		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 255		;Slide dur
	db $F2		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX01:
	db 255		;Length
	db 255		;Num slides before reset
	dw $0600	;Freq
	dw 4		;Amount
	db $00		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 0		;Slide dur
	db $3F		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX02:
	db 255		;Length
	db 255		;Num slides before reset
	dw $07F0	;Freq
	dw 1		;Amount
	db $80		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 0		;Slide dur
	db $2F		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX03:
	db 30		;Length
	db 3		;Num slides before reset
	dw $0080	;Freq
	dw 6		;Amount
	db $00		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $E2		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX04:
	db 60		;Length
	db 3		;Num slides before reset
	dw $0776	;Freq
	dw 2		;Amount
	db $00		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 99		;Slide dur
	db $F4		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX05:
	db 30		;Length
	db 3		;Num slides before reset
	dw $0080	;Freq
	dw 6		;Amount
	db $00		;NRx1
	db 255		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $E2		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX06:
	db 60		;Length
	db 3		;Num slides before reset
	dw $0080	;Freq
	dw 6		;Amount
	db $00		;NRx1
	db 255		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $F4		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX07:
	db 8		;Length
	db 99		;Num slides before reset
	dw $0300	;Freq
	dw 16		;Amount
	db $80		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 99		;Slide dur
	db $83		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX08:
	db 120		;Length
	db 255		;Num slides before reset
	dw $04FF	;Freq
	dw 1		;Amount
	db $00		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $F7		;NRx2
	db 0		;Loop
	db 2		;Speed
SFX09:
	db 60		;Length
	db 99		;Num slides before reset
	dw $02FF	;Freq
	dw 1		;Amount
	db $00		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $F7		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX0A:
	db 10		;Length
	db 6		;Num slides before reset
	dw $0040	;Freq
	dw 1		;Amount
	db $00		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 0		;Slide dur
	db $C1		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX0B:
	db 2		;Length
	db 99		;Num slides before reset
	dw $0204	;Freq
	dw 0		;Amount
	db $00		;NRx1
	db 0		;RNG
	db 0		;Sign
	db 0		;Slide dur
	db $81		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX0C:
	db 10		;Length
	db 5		;Num slides before reset
	dw $0043	;Freq
	dw 1		;Amount
	db $00		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 0		;Slide dur
	db $C1		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX0D:
	db 20		;Length
	db 2		;Num slides before reset
	dw $0710	;Freq
	dw 1		;Amount
	db $80		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $09		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX0E:
	db 20		;Length
	db 2		;Num slides before reset
	dw $0700	;Freq
	dw 1		;Amount
	db $80		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $09		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX0F:
	db 15		;Length
	db 8		;Num slides before reset
	dw $07D6	;Freq
	dw 1		;Amount
	db $40		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $F1		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX10:
	db 5		;Length
	db 2		;Num slides before reset
	dw $03DF	;Freq
	dw 16		;Amount
	db $00		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $29		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX11:
	db 17		;Length
	db 6		;Num slides before reset
	dw $0500	;Freq
	dw 64		;Amount
	db $00		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $F2		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX12:
	db 31		;Length
	db 5		;Num slides before reset
	dw $0500	;Freq
	dw 32		;Amount
	db $40		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $F2		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX13:
	db 32		;Length
	db 2		;Num slides before reset
	dw $0780	;Freq
	dw 32		;Amount
	db $80		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 99		;Slide dur
	db $09		;NRx2
	db 0		;Loop
	db 2		;Speed
SFX14:
	db 5		;Length
	db 4		;Num slides before reset
	dw $0003	;Freq
	dw 128		;Amount
	db $00		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 99		;Slide dur
	db $29		;NRx2
	db 0		;Loop
	db 2		;Speed
SFX15:
	db 255		;Length
	db 4		;Num slides before reset
	dw $0003	;Freq
	dw 128		;Amount
	db $00		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 99		;Slide dur
	db $09		;NRx2
	db 255		;Loop
	db 2		;Speed
SFX16:
	db 15		;Length
	db 10		;Num slides before reset
	dw $06E0	;Freq
	dw 16		;Amount
	db $80		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 99		;Slide dur
	db $82		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX17:
	db 15		;Length
	db 6		;Num slides before reset
	dw $0776	;Freq
	dw 16		;Amount
	db $40		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 99		;Slide dur
	db $82		;NRx2
	db 0		;Loop
	db 2		;Speed
SFX18:
	db 15		;Length
	db 9		;Num slides before reset
	dw $0680	;Freq
	dw 96		;Amount
	db $40		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 0		;Slide dur
	db $82		;NRx2
	db 0		;Loop
	db 3		;Speed
SFX19:
	db 45		;Length
	db 14		;Num slides before reset
	dw $0700	;Freq
	dw 64		;Amount
	db $80		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 1		;Slide dur
	db $F4		;NRx2
	db 0		;Loop
	db 5		;Speed
SFX1A:
	db 90		;Length
	db 20		;Num slides before reset
	dw $07E0	;Freq
	dw 16		;Amount
	db $80		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $F6		;NRx2
	db 0		;Loop
	db 4		;Speed
SFX1B:
	db 45		;Length
	db 15		;Num slides before reset
	dw $0600	;Freq
	dw 13		;Amount
	db $40		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 1		;Slide dur
	db $C4		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX1C:
	db 45		;Length
	db 15		;Num slides before reset
	dw $0600	;Freq
	dw 48		;Amount
	db $00		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 1		;Slide dur
	db $C7		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX1D:
	db 99		;Length
	db 12		;Num slides before reset
	dw $07D6	;Freq
	dw 1		;Amount
	db $80		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 255		;Slide dur
	db $19		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX1E:
	db 25		;Length
	db 4		;Num slides before reset
	dw $0142	;Freq
	dw 2		;Amount
	db $00		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 99		;Slide dur
	db $F2		;NRx2
	db 0		;Loop
	db 2		;Speed
SFX1F:
	db 14		;Length
	db 3		;Num slides before reset
	dw $0380	;Freq
	dw 288		;Amount
	db $40		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 255		;Slide dur
	db $F1		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX20:
	db 255		;Length
	db 7		;Num slides before reset
	dw $03B0	;Freq
	dw 12		;Amount
	db $00		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $19		;NRx2
	db 255		;Loop
	db 0		;Speed
SFX21:
	db 20		;Length
	db 12		;Num slides before reset
	dw $0760	;Freq
	dw 160		;Amount
	db $40		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 0		;Slide dur
	db $C2		;NRx2
	db 0		;Loop
	db 4		;Speed
SFX22:
	db 8		;Length
	db 10		;Num slides before reset
	dw $06C0	;Freq
	dw 19		;Amount
	db $80		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 99		;Slide dur
	db $19		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX23:
	db 25		;Length
	db 20		;Num slides before reset
	dw $0700	;Freq
	dw 1		;Amount
	db $00		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 0		;Slide dur
	db $F2		;NRx2
	db 0		;Loop
	db 2		;Speed
SFX24:
	db 12		;Length
	db 4		;Num slides before reset
	dw $07A8	;Freq
	dw 1		;Amount
	db $00		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $19		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX25:
	db 8		;Length
	db 99		;Num slides before reset
	dw $01A7	;Freq
	dw 0		;Amount
	db $00		;NRx1
	db 0		;RNG
	db 0		;Sign
	db 0		;Slide dur
	db $19		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX26:
	db 20		;Length
	db 2		;Num slides before reset
	dw $01A1	;Freq
	dw 2		;Amount
	db $00		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $19		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX27:
	db 20		;Length
	db 99		;Num slides before reset
	dw $02FF	;Freq
	dw 20		;Amount
	db $00		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 99		;Slide dur
	db $F2		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX28:
	db 25		;Length
	db 4		;Num slides before reset
	dw $0720	;Freq
	dw 4		;Amount
	db $80		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 99		;Slide dur
	db $F2		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX29:
	db 9		;Length
	db 4		;Num slides before reset
	dw $07D4	;Freq
	dw 8		;Amount
	db $80		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 99		;Slide dur
	db $E1		;NRx2
	db 0		;Loop
	db 2		;Speed
SFX2A:
	db 9		;Length
	db 9		;Num slides before reset
	dw $07EF	;Freq
	dw 1		;Amount
	db $40		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $C3		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX2B:
	db 9		;Length
	db 99		;Num slides before reset
	dw $07E0	;Freq
	dw 1		;Amount
	db $00		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 0		;Slide dur
	db $C3		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX2C:
	db 9		;Length
	db 9		;Num slides before reset
	dw $07D8	;Freq
	dw 1		;Amount
	db $40		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $C3		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX2D:
	db 9		;Length
	db 9		;Num slides before reset
	dw $07D0	;Freq
	dw 1		;Amount
	db $40		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $C3		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX2E:
	db 20		;Length
	db 6		;Num slides before reset
	dw $0041	;Freq
	dw 1		;Amount
	db $00		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 0		;Slide dur
	db $F2		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX2F:
	db 30		;Length
	db 3		;Num slides before reset
	dw $0080	;Freq
	dw 6		;Amount
	db $00		;NRx1
	db 255		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $F2		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX30:
	db 9		;Length
	db 9		;Num slides before reset
	dw $07D3	;Freq
	dw 1		;Amount
	db $40		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 99		;Slide dur
	db $E1		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX31:
	db 22		;Length
	db 99		;Num slides before reset
	dw $07D2	;Freq
	dw 1		;Amount
	db $40		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $19		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX32:
	db 12		;Length
	db 99		;Num slides before reset
	dw $07B0	;Freq
	dw 1		;Amount
	db $40		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 99		;Slide dur
	db $39		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX33:
	db 15		;Length
	db 2		;Num slides before reset
	dw $0320	;Freq
	dw 84		;Amount
	db $40		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 99		;Slide dur
	db $E2		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX34:
	db 35		;Length
	db 15		;Num slides before reset
	dw $0380	;Freq
	dw 22		;Amount
	db $00		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 0		;Slide dur
	db $F4		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX35:
	db 30		;Length
	db 99		;Num slides before reset
	dw $0127	;Freq
	dw 0		;Amount
	db $00		;NRx1
	db 255		;RNG
	db 0		;Sign
	db 0		;Slide dur
	db $19		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX36:
	db 30		;Length
	db 99		;Num slides before reset
	dw $07C0	;Freq
	dw 2		;Amount
	db $80		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $C4		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX37:
	db 12		;Length
	db 3		;Num slides before reset
	dw $0080	;Freq
	dw 6		;Amount
	db $80		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $19		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX38:
	db 20		;Length
	db 17		;Num slides before reset
	dw $0680	;Freq
	dw 24		;Amount
	db $00		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 1		;Slide dur
	db $F4		;NRx2
	db 0		;Loop
	db 3		;Speed
SFX39:
	db 9		;Length
	db 3		;Num slides before reset
	dw $0080	;Freq
	dw 6		;Amount
	db $80		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $F1		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX3A:
	db 25		;Length
	db 9		;Num slides before reset
	dw $05F6	;Freq
	dw 1		;Amount
	db $80		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 99		;Slide dur
	db $F2		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX3B:
	db 5		;Length
	db 2		;Num slides before reset
	dw $0080	;Freq
	dw 6		;Amount
	db $80		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $E1		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX3C:
	db 15		;Length
	db 4		;Num slides before reset
	dw $0146	;Freq
	dw 2		;Amount
	db $00		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $F2		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX3D:
	db 25		;Length
	db 2		;Num slides before reset
	dw $0055	;Freq
	dw 20		;Amount
	db $80		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $F2		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX3E:
	db 15		;Length
	db 4		;Num slides before reset
	dw $0142	;Freq
	dw 2		;Amount
	db $00		;NRx1
	db 255		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $E2		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX3F:
	db 15		;Length
	db 4		;Num slides before reset
	dw $0142	;Freq
	dw 2		;Amount
	db $00		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $F1		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX40:
	db 25		;Length
	db 4		;Num slides before reset
	dw $0146	;Freq
	dw 2		;Amount
	db $00		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $F2		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX41:
	db 25		;Length
	db 99		;Num slides before reset
	dw $07C0	;Freq
	dw 3		;Amount
	db $80		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $1B		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX42:
	db 24		;Length
	db 99		;Num slides before reset
	dw $06D0	;Freq
	dw 5		;Amount
	db $80		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 99		;Slide dur
	db $19		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX43:
	db 9		;Length
	db 99		;Num slides before reset
	dw $0380	;Freq
	dw 72		;Amount
	db $80		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 0		;Slide dur
	db $39		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX44:
	db 15		;Length
	db 2		;Num slides before reset
	dw $014E	;Freq
	dw 16		;Amount
	db $00		;NRx1
	db 0		;RNG
	db 0		;Sign
	db 0		;Slide dur
	db $F1		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX45:
	db 25		;Length
	db 4		;Num slides before reset
	dw $01A6	;Freq
	dw 2		;Amount
	db $00		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $3A		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX46:
	db 255		;Length
	db 4		;Num slides before reset
	dw $02FF	;Freq
	dw 8		;Amount
	db $40		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 99		;Slide dur
	db $1A		;NRx2
	db 255		;Loop
	db 0		;Speed
SFX47:
	db 9		;Length
	db 3		;Num slides before reset
	dw $013C	;Freq
	dw 2		;Amount
	db $00		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 99		;Slide dur
	db $39		;NRx2
	db 0		;Loop
	db 3		;Speed
SFX48:
	db 30		;Length
	db 18		;Num slides before reset
	dw $0710	;Freq
	dw 20		;Amount
	db $80		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 0		;Slide dur
	db $E4		;NRx2
	db 0		;Loop
	db 6		;Speed
SFX49:
	db 12		;Length
	db 3		;Num slides before reset
	dw $020F	;Freq
	dw 1		;Amount
	db $40		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 99		;Slide dur
	db $39		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX4A:
	db 11		;Length
	db 99		;Num slides before reset
	dw $07B0	;Freq
	dw 3		;Amount
	db $80		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 99		;Slide dur
	db $09		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX4B:
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

	
FreqTabAlt:
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
	dw Vib08

Vib00:
	db 0
	db endvib
Vib01:
	db 0, 1, 2, 1, 0, -1, -2, -1
	db endvib
Vib02:
	db 0, 2, 4, 2, 0, -2, -4, -2
	db endvib
Vib03:
	db 0, 3, 6, 3, 0, -3, -6, -3
	db endvib
Vib04:
	db 0, 4, 8, 4, 0, -4, -8, -4
	db endvib
Vib05:
	db 0, 8, 16, 8, 0, -8, -16, -8
	db endvib
Vib06:
	db 0, 16, 32, 16, 0, -16, -32, -16
	db endvib
Vib07:
	db 0, 32, 64, 32, 0, -32, -64, -32
	db endvib
Vib08:
	db 0, 63, 126, 63, 0, -63, -126, -63
	db endvib

SongTab:
.Title
	db 42
	dw TitleA, TitleB, TitleC, TitleD
.Start
	db 42
	dw StartA, StartB, StartC, StartD
.GameOver
	db 37
	dw GameOverA, GameOverB, GameOverC, GameOverD
.InGame1
	db 32
	dw InGame1A, InGame1B, InGame1C, InGame1D
.InGame2
	db 41
	dw InGame2A, InGame2B, InGame2C, InGame2D
.Radio
	db 33
	dw RadioA, RadioB, RadioC, RadioD
.Meka
	db 62
	dw MekaA, MekaB, MekaC, MekaD
.EndGame
	db 64
	dw EndGameA, EndGameB, EndGameC, EndGameD
.Peckles
	db 39
	dw PecklesA, PecklesB, PecklesC, PecklesD
	
SongEmpty:
	dw EmptyPhrase
	dw 0
	
TitleB:
	dw TitlePhrase06
TitleBLoop:
	dw TitlePhrase07
	dw TitlePhrase08
	dw TitlePhrase07
	dw TitlePhrase09
	dw TitlePhrase10
	dw TitlePhrase07
	dw TitlePhrase08
	dw TitlePhrase07
	dw TitlePhrase09
	dw 0
TitleC:
	dw TitlePhrase01
TitleCLoop:
	dw TitlePhrase02
	dw TitlePhrase03
	dw TitlePhrase02
	dw TitlePhrase04
	dw TitlePhrase05
	dw TitlePhrase02
	dw TitlePhrase03
	dw TitlePhrase02
	dw TitlePhrase04
	dw 0
TitleA:
	dw TitlePhrase11
TitleALoop:
	dw TitlePhrase12
	dw TitlePhrase13
	dw TitlePhrase12
	dw TitlePhrase14
	dw TitlePhrase15
	dw TransposeUp1Phrase
	dw TitlePhrase12
	dw TitlePhrase13
	dw TitlePhrase12
	dw TitlePhrase14
	dw Transpose0Phrase
	dw 0
TitleD:
	dw TitlePhrase16
TitleDLoop:
	dw TitlePhrase17
	dw 0
	
TitlePhrase01:
	db env, $20, 16
	db vib, $04
	db len4
	db $00
	db $02
	db $00
	db loop
	dw TitleCLoop
TitlePhrase02:
	db len4
	db $05
	db $00
	db $05
	db $00
	db $00
	db $07
	db len2
	db $07
	db $06
	db $05
	db $04
	db len4
	db $00
	db $07
	db $00
	db $08
	db $07
	db $00
	db len2
	db $00
	db $02
	db $03
	db $04
	db len4
	db $05
	db $00
	db $05
	db $00
	db $00
	db $07
	db len2
	db $07
	db $06
	db $05
	db $04
	db exit
TitlePhrase03:
	db len4
	db $00
	db $04
	db $00
	db $02
	db $00
	db $00
	db len2
	db $00
	db $02
	db $03
	db $04
	db exit
TitlePhrase04:
	db len4
	db $00
	db $04
	db $00
	db $07
	db $05
	db $00
	db $05
	db $09
	db exit
TitlePhrase05:
	db env, $20, 64
	db len8
	db $00
	db $02
	db $04
	db $00
	db env, $20, 16
	db exit
TitlePhrase06:
	db env, $F2
	db duty, $00
	db vib, $02
	db len4
	db $1C
	db $1D
	db env, $F4
	db $1F
	db loop
	dw TitleBLoop
TitlePhrase07:
	db vib, $02
	db len1
	db rest
	db env, $F1
	db duty, $C0
	db len2
	db $1D
	db $1C
	db $1D
	db $18
	db tie
	db $16
	db $15
	db tie
	db len3
	db $13
	db len2
	db env, $E1
	db duty, $00
	db $20
	db $2C
	db $20
	db $2C
	db $20
	db $2C
	db len1
	db tie
	db env, $F2
	db duty, $C0
	db len2
	db $1C
	db $1A
	db $18
	db $1C
	db tie
	db $1A
	db $18
	db tie
	db len3
	db $1C
	db len4
	db env, $E2
	db duty, $00
	db $2F
	db $30
	db $31
	db $60
	db rest
	db env, $F1
	db duty, $C0
	db len2
	db $21
	db $1D
	db $1C
	db $1D
	db tie
	db $16
	db $15
	db tie
	db len3
	db $13
	db len2
	db env, $E1
	db duty, $00
	db $20
	db $2C
	db $20
	db $2C
	db $20
	db $2C
	db len1
	db tie
	db env, $F2
	db duty, $C0
	db exit
TitlePhrase08:
	db len2
	db $1C
	db $1A
	db $18
	db $1C
	db tie
	db $1A
	db $17
	db tie
	db len3
	db $18
	db len4
	db env, $E2
	db duty, $00
	db $2E
	db $2D
	db $2B
	db exit
TitlePhrase09:
	db len2
	db $1C
	db $1A
	db $18
	db $1C
	db tie
	db $1B
	db $1C
	db tie
	db len3
	db $1D
	db vib, $00
	db len1
	db $18
	db $1A
	db $1B
	db $1C
	db env, $F1
	db $1D
	db rest
	db $60
	db $1D
	db $1D
	db $63
	db $1D
	db exit
TitlePhrase10:
	db vib, $03
	db duty, $00
	db env, $8C
	db len8
	db $13
	db $16
	db $18
	db $1C
	db exit
TitlePhrase11:
	db env, $F2
	db duty, $00
	db vib, $02
	db len4
	db $18
	db $1A
	db env, $F4
	db $1C
	db loop
	dw TitleALoop
TitlePhrase12:
	db vib, $03
	db env, $F1
	db duty, $C0
	db len2
	db $1D
	db $1C
	db $1D
	db $18
	db tie
	db $16
	db $15
	db tie
	db len4
	db $13
	db env, $E1
	db duty, $00
	db len2
	db $1F
	db $2B
	db $1F
	db $2B
	db $1F
	db $2B
	db env, $F2
	db duty, $C0
	db len2
	db $1C
	db $1A
	db $18
	db $1C
	db tie
	db $1A
	db $18
	db tie
	db len4
	db $1C
	db env, $E2
	db duty, $00
	db $2E
	db $2F
	db $30
	db env, $F1
	db duty, $C0
	db len2
	db $21
	db $1D
	db $1C
	db $1D
	db tie
	db $16
	db $15
	db tie
	db len4
	db $13
	db env, $E1
	db duty, $00
	db len2
	db $1F
	db $2B
	db $1F
	db $2B
	db $1F
	db $2B
	db env, $F2
	db duty, $C0
	db exit
TitlePhrase13:
	db len2
	db $1C
	db $1A
	db $18
	db $1C
	db tie
	db $1A
	db $17
	db tie
	db len4
	db $18
	db env, $E2
	db duty, $00
	db $30
	db $30
	db $30
	db exit
TitlePhrase14:
	db len2
	db $1C
	db $1A
	db $18
	db $1C
	db tie
	db $1B
	db $1C
	db tie
	db len4
	db $1D
	db len1
	db $18
	db $1A
	db $1B
	db $1C
	db env, $F1
	db $1D
	db rest
	db len1
	db $1D
	db $1D
	db len4
	db $1D
	db exit
TitlePhrase15:
	db duty, $00
	db env, $8C
	db len8
	db $18
	db $1A
	db $1C
	db $1F
	db exit
TitlePhrase16:
	db len4
	db env, $A2
	db $05
	db $05
	db $05
	db len2
	db loop
	dw TitleDLoop
TitlePhrase17:
	db env, $81
	db $07
	db env, $A1
	db $27
	db exit

StartA:
	dw StartPhrase01
	dw 0
StartC:
	dw StartPhrase02
	dw StartPhrase02
	dw StartPhrase02
	dw StartPhrase03
	dw 0
StartB:
	dw StartPhrase04
	dw 0
StartD:
GameOverD:
	dw StartPhrase05
	dw 0
	
StartPhrase01:
	db vib, $02
	db duty, $00
	db env, $C1
	db len1
	db $09
	db $11
	db $15
	db $0C
	db $11
	db $15
	db $09
	db $11
	db $15
	db $0C
	db $11
	db $15
	db $0C
	db $15
	db $18
	db $11
	db $15
	db $18
	db $0C
	db $15
	db $18
	db $11
	db $15
	db $18
	db len2
	db $1D
	db end
StartPhrase02:
	db vib, $03
	db env, $20, 10
	db len2
	db $05
	db env, $20, 5
	db len1
	db $05
	db env, $20, 10
	db len2
	db $05
	db env, $20, 5
	db len1
	db $05
	db env, $20, 10
	db len2
	db $05
	db env, $20, 5
	db len1
	db $05
	db env, $20, 10
	db len2
	db $05
	db env, $20, 5
	db len1
	db $05
	db env, $20, 10
	db len2
	db $05
	db env, $20, 5
	db len1
	db $05
	db env, $20, 10
	db len2
	db $00
	db env, $20, 5
	db len1
	db $00
	db env, $20, 10
	db len2
	db $09
	db env, $20, 5
	db len1
	db $09
	db env, $20, 10
	db len2
	db $0C
	db env, $20, 5
	db len1
	db $0C
	db exit
StartPhrase03:
	db len3
	db $11
	db end
StartPhrase04:
	db vib, $02
	db duty, $00
	db env, $E1
	db len1
	db $0C
	db $15
	db $18
	db $11
	db $15
	db $1D
	db $0C
	db $15
	db $18
	db $11
	db $15
	db $1D
	db $11
	db $18
	db $1D
	db $15
	db $18
	db $21
	db $11
	db $18
	db $1D
	db $15
	db $18
	db $20
	db len2
	db $21
	db end
StartPhrase05:
	db len2
	db env, $71
	db $07
	db len1
	db env, $71
	db $01
	db len2
	db env, $71
	db $05
	db len1
	db env, $71
	db $01
	db len2
	db env, $71
	db $07
	db len1
	db env, $71
	db $01
	db len2
	db env, $83
	db $05
	db len1
	db env, $71
	db $01
	db len2
	db env, $71
	db $07
	db len1
	db env, $71
	db $01
	db len2
	db env, $71
	db $05
	db len1
	db env, $71
	db $01
	db len2
	db env, $71
	db $07
	db len4
	db env, $A3
	db $05
	db exit
	
GameOverA:
	dw GameOverPhrase03
	dw 0
GameOverC:
	dw GameOverPhrase01
	dw GameOverPhrase01
	dw GameOverPhrase01
	dw GameOverPhrase02
	dw 0
GameOverB:
	dw GameOverPhrase04
	dw 0
	
GameOverPhrase01:
	db vib, $03
	db env, $20, 10
	db len2
	db $04
	db env, $20, 5
	db len1
	db $04
	db env, $20, 10
	db len2
	db $04
	db env, $20, 5
	db len1
	db $04
	db env, $20, 10
	db len2
	db $04
	db env, $20, 5
	db len1
	db $04
	db env, $20, 10
	db len2
	db $04
	db env, $20, 5
	db len1
	db $04
	db env, $20, 10
	db len2
	db $04
	db env, $20, 5
	db len1
	db $04
	db env, $20, 10
	db len2
	db $03
	db env, $20, 5
	db len1
	db $03
	db env, $20, 10
	db len2
	db $02
	db env, $20, 5
	db len1
	db $02
	db env, $20, 10
	db len2
	db $00
	db env, $20, 5
	db len1
	db $00
	db exit
GameOverPhrase02:
	db len3
	db $05
	db end
GameOverPhrase03:
	db len1
	db rest
GameOverPhrase04:
	db vib, $04
	db duty, $00
	db env, $E1
	db len1
	db $16
	db $13
	db $10
	db $16
	db $13
	db $10
	db $16
	db $13
	db $10
	db $16
	db $13
	db $10
	db $13
	db $10
	db $0C
	db $10
	db $0C
	db $0A
	db $0C
	db $0A
	db $07
	db $0A
	db $07
	db $04
	db len2
	db $09
	db end
	
InGame1A:
	dw InGame1Phrase01
	dw 0
InGame1C:
	dw InGame1Phrase02
	dw 0
InGame1B:
	dw InGame1Phrase03
	dw InGame1Phrase04
	dw InGame1Phrase07
	dw InGame1Phrase08
	dw TransposeUp1Phrase
	dw InGame1Phrase07
	dw InGame1Phrase08
	dw TransposeUp2Phrase
	dw InGame1Phrase05
	dw InGame1Phrase06
	dw InGame1Phrase07
	dw InGame1Phrase08
	dw Transpose0Phrase
	dw InGame1Phrase05
	dw TransposeUp1Phrase
	dw InGame1Phrase06
	dw TransposeUp2Phrase
	dw InGame1Phrase03
	dw InGame1Phrase04
	dw Transpose0Phrase
	dw 0
InGame1D:	
	dw InGame1Phrase09
	dw 0
	
InGame1Phrase01:
	db len1
	db rest
	db loop
	dw InGame1B
InGame1Phrase02:
	db env, $40, 16
	db vib, $04
	db len4
	db $05
	db $00
	db $05
	db $00
	db $00
	db $07
	db len2
	db $00
	db $02
	db $04
	db $05
	db len4
	db $07
	db $00
	db $07
	db $00
	db $05
	db $00
	db $05
	db len2
	db $0B
	db $0C
	db len4
	db $05
	db $00
	db $05
	db $00
	db $00
	db $07
	db len1
	db $00
	db $0C
	db $02
	db $0E
	db $04
	db $10
	db $05
	db $11
	db len4
	db $07
	db $00
	db $07
	db $00
	db $05
	db $00
	db $05
	db len1
	db vib, $02
	db $0B
	db $17
	db $0C
	db $18
	db exit	
InGame1Phrase03:
	db env, $74
	db duty, $C0
	db vib, $02
InGame1Phrase04:
	db len2
	db $1D
	db len4
	db $21
	db len1
	db $20
	db $21
	db len2
	db $1D
	db len4
	db $21
	db len1
	db $20
	db $21
	db len2
	db $1C
	db len4
	db $1F
	db len1
	db $1E
	db $1F
	db len2
	db $18
	db $1F
	db $1C
	db $1A
	db len2
	db $18
	db len4
	db $1C
	db len1
	db $1B
	db $1C
	db len2
	db $18
	db len4
	db $1F
	db len1
	db $1E
	db $1F
	db len2
	db $1D
	db len4
	db $21
	db len1
	db $20
	db $21
	db len2
	db $1D
	db $21
	db $20
	db $21
	db duty, $00
	db exit
InGame1Phrase05:
	db duty, $C0
InGame1Phrase06:
	db env, $72
	db vib, $05
	db len2
	db rest
	db len4
	db $0C
	db $0C
	db $09
	db $11
	db $0C
	db $0C
	db $07
	db $10
	db $0C
	db $0C
	db $13
	db $10
	db $0C
	db $0C
	db $15
	db $11
	db env, $62
	db vib, $04
	db $18
	db $18
	db $15
	db $1D
	db $18
	db $18
	db $13
	db $1C
	db $18
	db $18
	db $1F
	db $1C
	db $18
	db $18
	db $15
	db len2
	db $11
	db duty, $00
	db exit	
InGame1Phrase07:
	db env, $54
	db duty, $80
	db vib, $04
InGame1Phrase08:
	db len1
	db $11
	db $1D
	db len2
	db $15
	db $21
	db len1
	db $20
	db $21
	db $11
	db $1D
	db len2
	db $15
	db $21
	db len1
	db $20
	db $21
	db $10
	db $1C
	db len2
	db $13
	db $1F
	db len1
	db $1E
	db $1F
	db $0C
	db $18
	db $13
	db $1F
	db $10
	db $1C
	db $0E
	db $1A
	db $0C
	db $18
	db len2
	db $10
	db $1C
	db len1
	db $1B
	db $1C
	db $0C
	db $18
	db len2
	db $13
	db $1F
	db len1
	db $1E
	db $1F
	db $11
	db $1D
	db len2
	db $15
	db $21
	db len1
	db $20
	db $21
	db $11
	db $1D
	db $15
	db $21
	db $14
	db $20
	db $15
	db $21
	db duty, $00
	db exit
InGame1Phrase09:
	db len2
	db env, $41
	db $07
	db env, $42
	db $05
	db exit
	
InGame2A:
	dw InGame2Phrase01
	dw 0
InGame2C:
	dw InGame2Phrase02
	dw InGame2Phrase03
	dw InGame2Phrase02
	dw InGame2Phrase04
	dw 0
InGame2B:
	dw InGame2Phrase05
	dw InGame2Phrase06
	dw InGame2Phrase05
	dw InGame2Phrase07
	dw TransposeUp1Phrase
	dw InGame2Phrase08
	dw InGame2Phrase09
	dw InGame2Phrase08
	dw InGame2Phrase10
	dw InGame2Phrase11
	dw Transpose0Phrase
	dw InGame2Phrase11
	dw TransposeUp2Phrase
	dw InGame2Phrase08
	dw InGame2Phrase09
	dw InGame2Phrase08
	dw InGame2Phrase10
	dw InGame2Phrase11
	dw TransposeUp3Phrase
	dw InGame2Phrase11
	dw TransposeUp2Phrase
	dw InGame2Phrase08
	dw InGame2Phrase09
	dw InGame2Phrase08
	dw InGame2Phrase10
	dw TransposeUp1Phrase
	dw InGame2Phrase11
	dw TransposeUp2Phrase
	dw InGame2Phrase11
	dw Transpose0Phrase
	dw 0
InGame2D:
	dw InGame2Phrase12
	dw 0
	
InGame2Phrase01:
	db len1
	db rest
	db loop
	dw InGame2B
InGame2Phrase02:
	db env, $40, 16
	db vib, $04
	db len4
	db $05
	db $00
	db $05
	db $00
	db $00
	db $07
	db len2
	db $07
	db $06
	db $05
	db $04
	db len4
	db $00
	db $07
	db $00
	db $08
	db $07
	db $00
	db len2
	db $00
	db $02
	db $03
	db $04
	db len4
	db $05
	db $00
	db $05
	db $00
	db $00
	db $07
	db len2
	db $07
	db $06
	db $05
	db $04
	db exit
InGame2Phrase03:
	db len4
	db $00
	db $04
	db $00
	db $02
	db $00
	db $00
	db len2
	db $00
	db $02
	db $03
	db $04
	db exit
InGame2Phrase04:
	db len4
	db $00
	db $04
	db $00
	db $07
	db $05
	db $00
	db $05
	db $09
	db exit
InGame2Phrase05:
	db vib, $03
	db env, $72
	db duty, $C0
	db len2
	db $1D
	db $1C
	db $1D
	db $18
	db tie
	db $16
	db $15
	db tie
	db len4
	db $13
	db vib, $02
	db duty, $00
	db len2
	db $1F
	db $2B
	db $1F
	db $2B
	db $1F
	db $2B
	db vib, $03
	db duty, $C0
	db $1C
	db $1A
	db $18
	db $1C
	db tie
	db $1A
	db $18
	db tie
	db len4
	db $1C
	db vib, $02
	db duty, $00
	db $22
	db $23
	db $24
	db vib, $03
	db duty, $C0
	db len2
	db $21
	db $1D
	db $1C
	db $1D
	db tie
	db $16
	db $15
	db tie
	db len4
	db $13
	db vib, $02
	db duty, $00
	db len2
	db $1F
	db $2B
	db $1F
	db $2B
	db $1F
	db $2B
	db duty, $C0
	db exit
InGame2Phrase06:
	db vib, $03
	db len2
	db $1C
	db $1A
	db $18
	db $1C
	db tie
	db $1A
	db $17
	db tie
	db len4
	db $18
	db vib, $02
	db duty, $00
	db $30
	db $2F
	db $2E
	db exit
InGame2Phrase07:
	db len2
	db $1C
	db $1A
	db $18
	db $1C
	db tie
	db $1B
	db $1C
	db tie
	db len4
	db $1D
	db len1
	db $18
	db $1A
	db $1B
	db $1C
	db $1D
	db rest
	db $1D
	db $1D
	db len4
	db $1D
	db exit
InGame2Phrase08:
	db env, $54
	db duty, $80
	db vib, $04
	db len1
	db $1D
	db $11
	db $1C
	db $10
	db $1D
	db $11
	db $18
	db $0C
	db tie
	db tie
	db $16
	db $0A
	db $15
	db $09
	db tie
	db tie
	db len2
	db $13
	db $07
	db vib, $02
	db duty, $00
	db len1
	db $1F
	db $13
	db $2B
	db $13
	db $1F
	db $13
	db $2B
	db $13
	db $1F
	db $13
	db $2B
	db $13
	db duty, $80
	db vib, $04
	db $1C
	db $10
	db $1A
	db $0E
	db $18
	db $0C
	db $1C
	db $10
	db tie
	db tie
	db $1A
	db $0E
	db $18
	db $0C
	db tie
	db tie
	db len2
	db $1C
	db $10
	db vib, $02
	db duty, $00
	db $22
	db $16
	db $23
	db $17
	db $24
	db $18
	db vib, $04
	db duty, $80
	db vib, $04
	db len1
	db $21
	db $15
	db $1D
	db $11
	db $1C
	db $10
	db $1D
	db $11
	db tie
	db tie
	db $16
	db $0A
	db $15
	db $09
	db tie
	db tie
	db len2
	db $13
	db $07
	db vib, $02
	db duty, $00
	db len1
	db $1F
	db $13
	db $2B
	db $13
	db $1F
	db $13
	db $2B
	db $13
	db $1F
	db $13
	db $2B
	db $13
	db duty, $80
	db vib, $04
	db exit
InGame2Phrase09:
	db len1
	db $1C
	db $10
	db $1A
	db $0E
	db $18
	db $0C
	db $1C
	db $10
	db tie
	db tie
	db $1A
	db $0E
	db $17
	db $0B
	db tie
	db tie
	db len2
	db $18
	db $0C
	db vib, $02
	db duty, $00
	db $30
	db $24
	db $2F
	db $23
	db $2E
	db $22
	db exit
InGame2Phrase10:
	db len1
	db $1C
	db $10
	db $1A
	db $0E
	db $18
	db $0C
	db $1C
	db $10
	db tie
	db tie
	db $1B
	db $0F
	db $1C
	db $10
	db tie
	db tie
	db len2
	db $1D
	db $11
	db len1
	db $18
	db $16
	db $15
	db $13
	db $11
	db rest
	db $11
	db $11
	db len2
	db $11
	db $05
	db exit
InGame2Phrase11:
	db env, $72
	db duty, $00
	db vib, $03
	db len2
	db $11
	db $13
	db $15
	db $16
	db tie
	db $15
	db $11
	db tie
	db len4
	db $13
	db len2
	db $1F
	db $2B
	db $1F
	db $2B
	db $1F
	db $2B
	db $18
	db $1A
	db $1C
	db $1D
	db tie
	db $1C
	db $16
	db tie
	db $18
	db $1C
	db $1D
	db $1F
	db tie
	db $1C
	db $18
	db tie
	db env, $54
	db duty, $80
	db vib, $02
	db tp, 12
	db len1
	db $11
	db $05
	db $13
	db $07
	db $15
	db $09
	db $16
	db $0A
	db tie
	db tie
	db $15
	db $09
	db $11
	db $05
	db tie
	db tie
	db len2
	db $13
	db $07
	db tp, 0
	db duty, $00
	db vib, $02
	db len1
	db $1F
	db $13
	db $2B
	db $13
	db $1F
	db $13
	db $2B
	db $13
	db $1F
	db $13
	db $2B
	db $13
	db env, $82
	db vib, $03
	db duty, $C0
	db $18
	db $0C
	db $1A
	db $0E
	db $1C
	db $10
	db $1D
	db $11
	db tie
	db tie
	db $1C
	db $10
	db $16
	db $0A
	db tie
	db tie
	db $18
	db $0C
	db $1C
	db $10
	db $1D
	db $11
	db $1F
	db $13
	db tie
	db tie
	db $1C
	db $10
	db $18
	db $0C
	db tie
	db tie
	db exit
InGame2Phrase12:
	db len2
	db env, $41
	db $07
	db env, $51
	db $27
	db exit
	
RadioB:
	dw RadioPhrase01
	dw 0
RadioC:
	dw RadioPhrase02
	dw 0
RadioA:
	dw RadioPhrase03
	dw RadioPhrase03
	dw RadioPhrase04
	dw TransposeUp1Phrase
	dw RadioPhrase03
	dw RadioPhrase03
	dw Transpose0Phrase
	dw 0
RadioD:
	dw RadioPhrase05
	dw 0
	
RadioPhrase01:
	db env, $81
	db duty, $00
	db vib, $03
	db len1
	db $14
	db $18
	db $1B
	db $18
	db $14
	db $18
	db $1B
	db $27
	db $13
	db $16
	db $1B
	db $16
	db $13
	db $16
	db $1B
	db $27
	db $13
	db $16
	db $1B
	db $16
	db $13
	db $16
	db $1B
	db $27
	db $14
	db $18
	db $1B
	db $18
	db $14
	db $18
	db $1B
	db $27
	db exit
RadioPhrase02:
	db env, $40, 16
	db vib, $03
	db len4
	db $08
	db $08
	db env, $40, 8
	db len2
	db $0A
	db $0A
	db env, $40, 16
	db len4
	db $0A
	db len4
	db $03
	db $03
	db env, $40, 8
	db len2
	db $08
	db $08
	db env, $40, 16
	db $08
	db $03
	db len4
	db $08
	db $08
	db env, $40, 8
	db len2
	db $0A
	db $0A
	db env, $40, 16
	db len4
	db $0A
	db len4
	db $0F
	db $0F
	db env, $40, 8
	db len2
	db $0C
	db $0C
	db env, $40, 16
	db $0C
	db $0F
	db exit
RadioPhrase03:
	db env, $92
	db duty, $00
	db vib, $02
	db len2
	db $14
	db len1
	db $14
	db $16
	db len2
	db $18
	db len1
	db $16
	db $14
	db len2
	db $16
	db len1
	db $16
	db $14
	db len3
	db $13
	db len1
	db $0F
	db len2
	db $13
	db len1
	db $13
	db $14
	db len2
	db $16
	db len1
	db $14
	db $13
	db len2
	db $14
	db len1
	db $14
	db $16
	db len4
	db $18
	db len2
	db $14
	db len1
	db $14
	db $16
	db len2
	db $18
	db len1
	db $16
	db $14
	db len2
	db $16
	db len1
	db $16
	db $16
	db len4
	db $1B
	db len2
	db $1F
	db len1
	db $1F
	db $20
	db len2
	db $22
	db len1
	db $20
	db $1F
	db len2
	db $20
	db len1
	db $20
	db $1B
	db len4
	db $18
	db exit
RadioPhrase04:
	db len32
	db rest
	db rest
	db exit
RadioPhrase05:	
	db len2
	db env, $42
	db $07
	db env, $72
	db $27
	db exit
	
MekaB:
	dw MekaPhrase02
	dw 0
MekaC:	
	dw MekaPhrase01
	dw 0
MekaA:
	dw MekaPhrase03
	dw 0
MekaD:
	dw MekaPhrase04
	dw 0
	
MekaPhrase01:
	db env, $40, 14
	db vib, $04
	db len6
	db $02
	db $02
	db $02
	db $02
	db len4
	db $04
	db $05
	db len6
	db $02
	db $02
	db $02
	db $02
	db len4
	db $05
	db $04
	db len6
	db $02
	db $02
	db $02
	db $02
	db len4
	db $04
	db $05
	db len6
	db $02
	db $02
	db $02
	db $02
	db len4
	db $05
	db $07
	db vib, $05
	db len6
	db $02
	db $02
	db $02
	db $02
	db len4
	db $04
	db $05
	db len6
	db $02
	db $02
	db $02
	db $02
	db len4
	db $05
	db $04
	db len6
	db $02
	db $02
	db $02
	db $02
	db len4
	db $04
	db $05
	db len6
	db $02
	db $02
	db $02
	db $02
	db len4
	db $05
	db $07
	db exit
MekaPhrase02:
	db len1
	db rest
	db loop
	dw MekaA
MekaPhrase03:
	db duty, $00
	db env, $72
	db vib, $05
	db len6
	db $0E
	db $0E
	db $0E
	db $0E
	db len4
	db $10
	db $11
	db len6
	db $0E
	db $0E
	db $0E
	db $0E
	db len4
	db $10
	db $11
	db len6
	db $0E
	db $0E
	db $0E
	db $0E
	db len4
	db $10
	db $11
	db len6
	db $0E
	db $0E
	db $0E
	db $0E
	db len4
	db $10
	db $11
	db vib, $04
	db len6
	db $15
	db $15
	db $15
	db $15
	db len4
	db $17
	db $18
	db len6
	db $15
	db $15
	db $15
	db $15
	db len4
	db $17
	db $18
	db len6
	db $15
	db $15
	db $15
	db $15
	db len4
	db $17
	db $18
	db len6
	db $15
	db $15
	db $15
	db $15
	db len4
	db $17
	db $18
	db duty, $40
	db vib, $04
	db env, $65
	db len10
	db $1A
	db env, $37
	db $1A
	db len12
	db env, $27
	db $1A
	db vib, $03
	db env, $65
	db len10
	db $26
	db env, $37
	db $26
	db len12
	db env, $27
	db $26
	db duty, $00
	db vib, $04
	db env, $65
	db len10
	db $1A
	db env, $37
	db $1A
	db len12
	db env, $27
	db $1A
	db vib, $03
	db env, $65
	db len10
	db $21
	db env, $37
	db $21
	db len12
	db env, $27
	db $21
	db vib, $08
	db env, $77
	db duty, $80
	db len24
	db $21
	db len4
	db $23
	db $24
	db len24
	db $21
	db len4
	db $23
	db $24
	db len24
	db $21
	db len4
	db $23
	db $24
	db len24
	db $21
	db len4
	db $23
	db $24
	db len32
	db rest
	db rest
	db rest
	db rest
	db env, $77
	db duty, $00
	db len24
	db $21
	db len4
	db $23
	db $24
	db len24
	db $21
	db len4
	db $23
	db $24
	db len24
	db $21
	db len4
	db $23
	db $24
	db len24
	db $21
	db len4
	db $23
	db $24
	db exit
MekaPhrase04:
	db len2
	db env, $61
	db $07
	db env, $41
	db $01
	db $01
	db $01
	db env, $62
	db $27
	db env, $41
	db $01
	db $01
	db env, $51
	db $07
	db env, $41
	db $01
	db $01
	db env, $52
	db $07
	db env, $41
	db $01
	db env, $62
	db $27
	db env, $41
	db $01
	db $01
	db $01
	db exit

EndGameA:
	dw EndGamePhrase03
	dw EndGamePhrase02
	dw 0
EndGameC:
	dw EndGamePhrase01
	dw 0
EndGameB:
	dw EndGamePhrase04
	dw EndGamePhrase06
	dw EndGamePhrase05
	dw EndGamePhrase06
	dw 0
EndGameD:
	dw EndGamePhrase07
	dw 0
	
EndGamePhrase01:
	db vib, $03
	db env, $20
	db $0C
	db len4
	db $03
	db $03
	db $0A
	db len2
	db $03
	db len4
	db $0A
	db $03
	db len2
	db $03
	db $0A
	db $03
	db $0A
	db $0F
	db len4
	db $07
	db $07
	db $0E
	db len2
	db $07
	db len4
	db $0E
	db $07
	db len2
	db $07
	db $0E
	db $07
	db $0E
	db $0F
	db len4
	db $08
	db $08
	db $0F
	db len2
	db $08
	db len4
	db $0F
	db $08
	db len2
	db $08
	db $0F
	db $08
	db $0F
	db $11
	db len4
	db $0A
	db $0A
	db $0F
	db len2
	db $0A
	db len4
	db $0E
	db $0A
	db len2
	db $0A
	db $0E
	db $0A
	db $0E
	db $0A
	db exit
EndGamePhrase02:
	db env, $C7
	db tp, 12
	db vib, $02
	db len12
	db $16
	db len4
	db $13
	db $16
	db len8
	db $1A
	db len4
	db $16
	db len12
	db tie
	db len4
	db $13
	db $16
	db len8
	db $13
	db len4
	db $13
	db len4
	db tie
	db len16
	db $0F
	db len8
	db $13
	db len4
	db $13
	db len4
	db tie
	db len16
	db $11
	db len12
	db $1A
	db len12
	db $16
	db len4
	db $13
	db $16
	db len8
	db $1A
	db len4
	db $16
	db len12
	db tie
	db len4
	db $13
	db $16
	db len8
	db $1B
	db len4
	db $20
	db len4
	db tie
	db len16
	db $0F
	db len8
	db $13
	db len4
	db $13
	db len4
	db tie
	db len16
	db $11
	db len12
	db $1A
	db tp, 0
	db exit
EndGamePhrase03:
	db len1
	db rest
EndGamePhrase04:
	db env, $C7
	db duty, $00
	db vib, $04
EndGamePhrase05:
	db len12
	db $13
	db len4
	db $11
	db $13
	db len8
	db $16
	db len4
	db $13
	db len12
	db tie
	db len4
	db $11
	db $13
	db len8
	db $11
	db len4
	db $0F
	db len4
	db tie
	db len16
	db $0C
	db len8
	db $0F
	db len4
	db $0F
	db len4
	db tie
	db len16
	db $0E
	db len12
	db $16
	db len12
	db $13
	db len4
	db $11
	db $13
	db len8
	db $16
	db len4
	db $13
	db len12
	db tie
	db len4
	db $11
	db $13
	db len8
	db $11
	db len4
	db $0F
	db len4
	db tie
	db len16
	db $0C
	db len8
	db $0F
	db len4
	db $13
	db len4
	db tie
	db len16
	db $11
	db len11
	db $16
	db env, $F7
	db exit
EndGamePhrase06:	
	db len1
	db rest
	db exit
EndGamePhrase07:
	db len2
	db env, $81
	db $07
	db env, $81
	db $01
	db $01
	db $01
	db env, $E1
	db $05
	db env, $81
	db $01
	db $01
	db env, $A1
	db $07
	db env, $81
	db $01
	db $01
	db env, $A1
	db $07
	db env, $81
	db $01
	db env, $E1
	db $05
	db env, $81
	db $01
	db $01
	db $01
	db env, $81
	db $07
	db env, $81
	db $01
	db $01
	db $01
	db env, $E1
	db $05
	db env, $81
	db $01
	db $01
	db env, $A1
	db $07
	db env, $81
	db $01
	db env, $A1
	db $07
	db env, $81
	db $01
	db $01
	db env, $E1
	db $05
	db env, $81
	db $01
	db $01
	db $01
	db exit
	
PecklesA:
	dw PecklesPhrase01
	dw 0
PecklesC:	
	dw PecklesPhrase02
	dw 0
PecklesB:	
	dw PecklesPhrase03
	dw PecklesPhrase03
	dw PecklesPhrase04
	dw 0
PecklesD:
	dw PecklesPhrase05
	dw 0

PecklesPhrase01:	
	db vib, $02
	db duty, $00
	db env, $82
	db len1
	db $0E
	db $13
	db $17
	db $0E
	db $13
	db $17
	db $0E
	db $13
	db $17
	db $0E
	db $13
	db $17
	db $0E
	db $13
	db $16
	db $0E
	db $13
	db $16
	db $0E
	db $13
	db $16
	db $0E
	db $13
	db $16
	db $0E
	db $11
	db $15
	db $0E
	db $11
	db $15
	db $0E
	db $11
	db $15
	db $0E
	db $11
	db $15
	db $0E
	db $12
	db $15
	db $0E
	db $12
	db $15
	db $0E
	db $12
	db $15
	db $0E
	db $12
	db $15
	db exit
PecklesPhrase02:
	db vib, $03
	db env, $40, 10
	db len2
	db $07
	db env, $40, 5
	db len1
	db $07
	db env, $40, 10
	db len2
	db $07
	db env, $40, 5
	db len1
	db $07
	db env, $40, 10
	db len2
	db $07
	db env, $40, 5
	db len1
	db $07
	db env, $40, 10
	db len2
	db $13
	db env, $40, 5
	db len1
	db $13
	db env, $40, 10
	db len2
	db $07
	db env, $40, 5
	db len1
	db $07
	db env, $40, 10
	db len2
	db $07
	db env, $40, 5
	db len1
	db $07
	db env, $40, 10
	db len2
	db $07
	db env, $40, 5
	db len1
	db $07
	db env, $40, 10
	db len2
	db $13
	db env, $40, 5
	db len1
	db $13
	db env, $40, 10
	db len2
	db $02
	db env, $40, 5
	db len1
	db $02
	db env, $40, 10
	db len2
	db $02
	db env, $40, 5
	db len1
	db $02
	db env, $40, 10
	db len2
	db $02
	db env, $40, 5
	db len1
	db $02
	db env, $40, 10
	db len2
	db $0E
	db env, $40, 5
	db len1
	db $0E
	db env, $40, 10
	db len2
	db $02
	db env, $40, 5
	db len1
	db $02
	db env, $40, 10
	db len2
	db $02
	db env, $40, 5
	db len1
	db $02
	db env, $40, 10
	db len2
	db $02
	db env, $40, 5
	db len1
	db $02
	db env, $40, 10
	db len2
	db $0E
	db env, $40, 5
	db len1
	db $0E
	db exit
PecklesPhrase03:
	db vib, $02
	db duty, $00
	db env, $82
	db len1
	db $13
	db $17
	db $1A
	db $13
	db $17
	db $1A
	db $13
	db $17
	db $1A
	db $13
	db $17
	db $1A
	db $13
	db $16
	db $1A
	db $13
	db $16
	db $1A
	db $13
	db $16
	db $1A
	db $13
	db $16
	db $1A
	db $11
	db $15
	db $1A
	db $11
	db $15
	db $1A
	db $11
	db $15
	db $1A
	db $0E
	db $15
	db $1A
	db $12
	db $15
	db $1A
	db $12
	db $15
	db $1A
	db $12
	db $15
	db $1A
	db $12
	db $15
	db $1A
	db exit
PecklesPhrase04:
	db duty, $C0
	db env, $A3
	db vib, $02
	db len3
	db $13
	db $1A
	db $17
	db $1A
	db $13
	db $1A
	db $16
	db $1A
	db $11
	db $18
	db $15
	db $18
	db $12
	db $18
	db $15
	db $18
	db duty, $00
	db $13
	db $1A
	db $17
	db $1A
	db $13
	db $1A
	db $16
	db $1A
	db $11
	db $1A
	db $15
	db $1A
	db $12
	db $1A
	db $15
	db $1A
	db exit
	
PecklesPhrase05:
	db len2
	db env, $71
	db $07
	db len1
	db env, $41
	db $01
	db len2
	db env, $72
	db $05
	db len1
	db env, $71
	db $01
	db exit

Transpose0Phrase:
	db tpglobal, 0
	db exit
TransposeUp1Phrase:
	db tpglobal, 1
	db exit
TransposeUp2Phrase:
	db tpglobal, 2
	db exit
TransposeUp3Phrase:
	db tpglobal, 3
	db exit

EmptyPhrase:
	db len31
	db env, $00
	db $00
	db rest
	db loop
	dw SongEmpty

EndString:
	db "EndMusicFX."
	
SECTION "Audio RAM", WRAMX[AudioRAM]

PlayFlag:: ds 1
C1TrigFlag:: ds 1
C2TrigFlag:: ds 1
C4TrigFlag:: ds 1
Tempo:: ds 2
RNG:: ds 4
BeatCounter:: ds 1
GlobalTrans:: ds 1
SongPlayFlag:: ds 1
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