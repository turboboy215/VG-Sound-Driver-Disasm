;The Lion King audio disassembly
;Original audio by Kevin Bateson
;Sound engine code by David Whittaker
;Disassembly by Will Trowbridge

include "HARDWARE.INC"

def AudioROM equ $4000
def AudioRAM equ $C700
def WaveRAM equ $FF30
def SongCnt equ $0E
def SFXCnt equ $2B

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
	
SFX00:
	db 30		;Length
	db 10		;Num slides before reset
	dw $072F	;Freq
	dw 24		;Amount
	db $C0		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 4		;Slide dur
	db $F6		;NRx2
	db 0		;Loop
	db 4		;Speed
SFX01:
	db 30		;Length
	db 10		;Num slides before reset
	dw $06CF	;Freq
	dw 28		;Amount
	db $80		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 4		;Slide dur
	db $F6		;NRx2
	db 0		;Loop
	db 4		;Speed
SFX02:
	db 42		;Length
	db 10		;Num slides before reset
	dw $07CF	;Freq
	dw 12		;Amount
	db $80		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 6		;Slide dur
	db $F6		;NRx2
	db 0		;Loop
	db 4		;Speed
SFX03:
	db 22		;Length
	db 10		;Num slides before reset
	dw $07EF	;Freq
	dw 16		;Amount
	db $80		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 6		;Slide dur
	db $A6		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX04:
	db 12		;Length
	db 8		;Num slides before reset
	dw $0208	;Freq
	dw 256		;Amount
	db $00		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 1		;Slide dur
	db $F4		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX05:
	db 26		;Length
	db 6		;Num slides before reset
	dw $07FF	;Freq
	dw 256		;Amount
	db $80		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 4		;Slide dur
	db $F4		;NRx2
	db 0		;Loop
	db 3		;Speed
SFX06:
	db 6		;Length
	db 6		;Num slides before reset
	dw $0748	;Freq
	dw 34		;Amount
	db $00		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 0		;Slide dur
	db $A4		;NRx2
	db 0		;Loop
	db 2		;Speed
SFX07:
	db 16		;Length
	db 16		;Num slides before reset
	dw $0170	;Freq
	dw 1		;Amount
	db $C0		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 4		;Slide dur
	db $F7		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX08:
	db 64		;Length
	db 64		;Num slides before reset
	dw $0710	;Freq
	dw 1026		;Amount
	db $00		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 0		;Slide dur
	db $C4		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX09:
	db 30		;Length
	db 23		;Num slides before reset
	dw $FF60	;Freq
	dw 17		;Amount
	db $00		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 0		;Slide dur
	db $E7		;NRx2
	db 0		;Loop
	db 12		;Speed
SFX0A:
	db 40		;Length
	db 26		;Num slides before reset
	dw $FFD2	;Freq
	dw 17		;Amount
	db $80		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 0		;Slide dur
	db $F7		;NRx2
	db 0		;Loop
	db 20		;Speed
SFX0B:
	db 60		;Length
	db 35		;Num slides before reset
	dw $FFD2	;Freq
	dw 17		;Amount
	db $80		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 0		;Slide dur
	db $F7		;NRx2
	db 0		;Loop
	db 24		;Speed
SFX0C:
	db 60		;Length
	db 34		;Num slides before reset
	dw $FFD3	;Freq
	dw 17		;Amount
	db $80		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 0		;Slide dur
	db $F7		;NRx2
	db 0		;Loop
	db 18		;Speed
SFX0D:
	db 90		;Length
	db 50		;Num slides before reset
	dw $FFD3	;Freq
	dw 17		;Amount
	db $80		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 0		;Slide dur
	db $F7		;NRx2
	db 0		;Loop
	db 23		;Speed
SFX0E:
	db 10		;Length
	db 8		;Num slides before reset
	dw $0308	;Freq
	dw 128		;Amount
	db $C0		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 0		;Slide dur
	db $F1		;NRx2
	db 0		;Loop
	db 1		;Speed
SFX0F:
	db 4		;Length
	db 30		;Num slides before reset
	dw $0140	;Freq
	dw 192		;Amount
	db $80		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 30		;Slide dur
	db $AF		;NRx2
	db 0		;Loop
	db 2		;Speed
SFX10:
	db 9		;Length
	db 30		;Num slides before reset
	dw $0140	;Freq
	dw 192		;Amount
	db $80		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 30		;Slide dur
	db $AF		;NRx2
	db 0		;Loop
	db 2		;Speed
SFX11:
	db 10		;Length
	db 16		;Num slides before reset
	dw $0400	;Freq
	dw 17		;Amount
	db $C0		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 4		;Slide dur
	db $A4		;NRx2
	db 0		;Loop
	db 2		;Speed
SFX12:
	db 56		;Length
	db 6		;Num slides before reset
	dw $0748	;Freq
	dw 110		;Amount
	db $C0		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 110		;Slide dur
	db $F4		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX13:
	db 56		;Length
	db 6		;Num slides before reset
	dw $07E8	;Freq
	dw 46		;Amount
	db $C0		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 100		;Slide dur
	db $F4		;NRx2
	db 0		;Loop
	db 2		;Speed
SFX14:
	db 60		;Length
	db 10		;Num slides before reset
	dw $07C0	;Freq
	dw 22		;Amount
	db $80		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 6		;Slide dur
	db $F6		;NRx2
	db 0		;Loop
	db 6		;Speed
SFX15:
	db 6		;Length
	db 2		;Num slides before reset
	dw $058F	;Freq
	dw 177		;Amount
	db $80		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 3		;Slide dur
	db $F7		;NRx2
	db 0		;Loop
	db 4		;Speed
SFX16:
	db 60		;Length
	db 12		;Num slides before reset
	dw $07B0	;Freq
	dw 22		;Amount
	db $80		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 0		;Slide dur
	db $B6		;NRx2
	db 0		;Loop
	db 6		;Speed
SFX17:
	db 20		;Length
	db 12		;Num slides before reset
	dw $0680	;Freq
	dw 384		;Amount
	db $80		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 0		;Slide dur
	db $C7		;NRx2
	db 0		;Loop
	db 6		;Speed
SFX18:
	db 26		;Length
	db 16		;Num slides before reset
	dw $05F3	;Freq
	dw 33		;Amount
	db $00		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 7		;Slide dur
	db $F2		;NRx2
	db 0		;Loop
	db 3		;Speed
SFX19:
	db 56		;Length
	db 36		;Num slides before reset
	dw $05F4	;Freq
	dw 33		;Amount
	db $00		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 7		;Slide dur
	db $F4		;NRx2
	db 0		;Loop
	db 3		;Speed
SFX1A:
	db 56		;Length
	db 16		;Num slides before reset
	dw $05F8	;Freq
	dw 17		;Amount
	db $C0		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 4		;Slide dur
	db $B4		;NRx2
	db 0		;Loop
	db 12		;Speed
SFX1B:
	db 50		;Length
	db 11		;Num slides before reset
	dw $0280	;Freq
	dw 46		;Amount
	db $00		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 0		;Slide dur
	db $F2		;NRx2
	db 0		;Loop
	db 1		;Speed
SFX1C:
	db 12		;Length
	db 9		;Num slides before reset
	dw $0706	;Freq
	dw 15		;Amount
	db $C0		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 0		;Slide dur
	db $A4		;NRx2
	db 0		;Loop
	db 2		;Speed
SFX1D:
	db 70		;Length
	db 56		;Num slides before reset
	dw $0688	;Freq
	dw 1070		;Amount
	db $C0		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 0		;Slide dur
	db $F4		;NRx2
	db 0		;Loop
	db 6		;Speed
SFX1E:
	db 64		;Length
	db 56		;Num slides before reset
	dw $0703	;Freq
	dw 17		;Amount
	db $C0		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 0		;Slide dur
	db $F4		;NRx2
	db 0		;Loop
	db 12		;Speed
SFX1F:
	db 80		;Length
	db 23		;Num slides before reset
	dw $0380	;Freq
	dw 160		;Amount
	db $80		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 3		;Slide dur
	db $F6		;NRx2
	db 0		;Loop
	db 7		;Speed
SFX20:
	db 80		;Length
	db 23		;Num slides before reset
	dw $0440	;Freq
	dw 128		;Amount
	db $80		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 3		;Slide dur
	db $F6		;NRx2
	db 0		;Loop
	db 6		;Speed
SFX21:
	db 80		;Length
	db 23		;Num slides before reset
	dw $04C0	;Freq
	dw 111		;Amount
	db $80		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 3		;Slide dur
	db $F6		;NRx2
	db 0		;Loop
	db 5		;Speed
SFX22:
	db 80		;Length
	db 23		;Num slides before reset
	dw $0500	;Freq
	dw 108		;Amount
	db $80		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 3		;Slide dur
	db $F6		;NRx2
	db 0		;Loop
	db 4		;Speed
SFX23:
	db 80		;Length
	db 23		;Num slides before reset
	dw $0540	;Freq
	dw 80		;Amount
	db $80		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 3		;Slide dur
	db $F6		;NRx2
	db 0		;Loop
	db 3		;Speed
SFX24:
	db 66		;Length
	db 2		;Num slides before reset
	dw $0710	;Freq
	dw 224		;Amount
	db $00		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 90		;Slide dur
	db $F3		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX25:
	db 60		;Length
	db 10		;Num slides before reset
	dw $0408	;Freq
	dw 46		;Amount
	db $00		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 6		;Slide dur
	db $F3		;NRx2
	db 0		;Loop
	db 2		;Speed
SFX26:
	db 26		;Length
	db 24		;Num slides before reset
	dw $0508	;Freq
	dw 46		;Amount
	db $00		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 0		;Slide dur
	db $F4		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX27:
	db 70		;Length
	db 7		;Num slides before reset
	dw $06C0	;Freq
	dw 26		;Amount
	db $C0		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 6		;Slide dur
	db $F4		;NRx2
	db 0		;Loop
	db 1		;Speed
SFX28:
	db 26		;Length
	db 22		;Num slides before reset
	dw $0364	;Freq
	dw 17		;Amount
	db $C0		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 4		;Slide dur
	db $A4		;NRx2
	db 0		;Loop
	db 4		;Speed
SFX29:
	db 16		;Length
	db 16		;Num slides before reset
	dw $06C8	;Freq
	dw 1030		;Amount
	db $40		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 0		;Slide dur
	db $A4		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX2A:
	db 52		;Length
	db 42		;Num slides before reset
	dw $0330	;Freq
	dw 17		;Amount
	db $C0		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 0		;Slide dur
	db $E4		;NRx2
	db 0		;Loop
	db 12		;Speed
SFX2B:
	db 64		;Length
	db 16		;Num slides before reset
	dw $0708	;Freq
	dw 14		;Amount
	db $00		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 3		;Slide dur
	db $F3		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX2C:
	db 16		;Length
	db 16		;Num slides before reset
	dw $0364	;Freq
	dw 17		;Amount
	db $C0		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 4		;Slide dur
	db $A3		;NRx2
	db 0		;Loop
	db 2		;Speed
SFX2D:
	db 42		;Length
	db 11		;Num slides before reset
	dw $0340	;Freq
	dw 17		;Amount
	db $C0		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 4		;Slide dur
	db $A3		;NRx2
	db 0		;Loop
	db 6		;Speed
SFX2E:
SFX2F:
SFX30:
SFX31:
	db 26		;Length
	db 10		;Num slides before reset
	dw $06EF	;Freq
	dw 24		;Amount
	db $80		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 4		;Slide dur
	db $F4		;NRx2
	db 0		;Loop
	db 0		;Speed
SFX32:
	db 23		;Length
	db 12		;Num slides before reset
	dw $073F	;Freq
	dw 72		;Amount
	db $80		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 4		;Slide dur
	db $F4		;NRx2
	db 0		;Loop
	db 8		;Speed
SFX33:
	db 64		;Length
	db 4		;Num slides before reset
	dw $0FFF	;Freq
	dw 2032		;Amount
	db $C0		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 255		;Slide dur
	db $87		;NRx2
	db 0		;Loop
	db 2		;Speed
SFX34:
	db 64		;Length
	db 6		;Num slides before reset
	dw $0FFF	;Freq
	dw 2024		;Amount
	db $C0		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 255		;Slide dur
	db $87		;NRx2
	db 0		;Loop
	db 3		;Speed
SFX35:
	db 64		;Length
	db 8		;Num slides before reset
	dw $0FFF	;Freq
	dw 2016		;Amount
	db $C0		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 255		;Slide dur
	db $87		;NRx2
	db 0		;Loop
	db 4		;Speed
SFX36:
	db 80		;Length
	db 26		;Num slides before reset
	dw $0364	;Freq
	dw 17		;Amount
	db $C0		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 4		;Slide dur
	db $A7		;NRx2
	db 0		;Loop
	db 7		;Speed
SFX37:
	db 64		;Length
	db 36		;Num slides before reset
	dw $0624	;Freq
	dw 1038		;Amount
	db $80		;NRx1
	db 0		;RNG
	db -1		;Sign
	db 0		;Slide dur
	db $F4		;NRx2
	db 0		;Loop
	db 2		;Speed
SFX38:
	db 55		;Length
	db 8		;Num slides before reset
	dw $060F	;Freq
	dw 129		;Amount
	db $00		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 7		;Slide dur
	db $F7		;NRx2
	db 0		;Loop
	db 3		;Speed
SFX39:
	db 90		;Length
	db 90		;Num slides before reset
	dw $07D0	;Freq
	dw 129		;Amount
	db $00		;NRx1
	db 0		;RNG
	db 1		;Sign
	db 1		;Slide dur
	db $F7		;NRx2
	db 0		;Loop
	db 12		;Speed


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
	
SongTab:
.CantWait
	db 42
	dw CantWaitA, CantWaitB, CantWaitC, CantWaitD
.HakunaMatata
	db 42
	dw HakunaMatataA, HakunaMatataB, HakunaMatataC, HakunaMatataD
.LoveTonight
	db 42
	dw LoveTonightA, LoveTonightB, LoveTonightC, LoveTonightD
.Circle
	db 42
	dw CircleA, CircleB, CircleC, CircleD
.BePrepared
	db 70
	dw BePreparedA, BePreparedB, BePreparedC, BePreparedD
.HooHah
	db 56
	dw HooHahA, HooHahB, HooHahC, HooHahD
.ThisLand
	db 42
	dw ThisLandA, ThisLandB, ThisLandC, ThisLandD
.Jingle
	db 42
	dw JingleA, JingleB, JingleC, JingleD
.ToDieFor
	db 32
	dw ToDieForA, ToDieForB, ToDieForC, ToDieForD
.Exile
	db 42
	dw ExileA, ExileB, ExileC, ExileD
.UnderTheStars
	db 42
	dw UnderTheStarsA, UnderTheStarsB, UnderTheStarsC, UnderTheStarsD
.BugToss
	db 42
	dw BugTossA, BugTossB, BugTossC, BugTossD
.DeathTag
	db 42
	dw DeathTagA, DeathTagB, DeathTagC, DeathTagD
.KingTag
	db 42
	dw KingTagA, KingTagB, KingTagC, KingTagD

CantWaitA:	
	dw Vibrato01Phrase
	dw TransposeUp3Phrase
	dw CantWaitPhrase01
CantWaitALoop:
	dw CantWaitPhrase02
	dw CantWaitPhrase02
	dw CantWaitPhrase03
	dw CantWaitPhrase03
	dw CantWaitPhrase04
	dw CantWaitPhrase05
	dw CantWaitPhrase04
	dw CantWaitPhrase05
	dw CantWaitPhrase06
	dw CantWaitPhrase07
	dw 0
CantWaitB:
	dw Vibrato03Phrase
	dw CantWaitPhrase08
CantWaitBLoop:
	dw CantWaitPhrase09
	dw CantWaitPhrase09
	dw CantWaitPhrase10
	dw CantWaitPhrase10
	dw CantWaitPhrase11
	dw CantWaitPhrase12
	dw CantWaitPhrase11
	dw CantWaitPhrase12
	dw CantWaitPhrase13
	dw CantWaitPhrase14
	dw 0
CantWaitC:
	dw Vibrato02Phrase
	dw TransposeChDownOctPhrase
	dw CantWaitPhrase15
CantWaitCLoop:
	dw CantWaitPhrase16
	dw CantWaitPhrase16
	dw CantWaitPhrase17
	dw CantWaitPhrase17
	dw CantWaitPhrase18
	dw CantWaitPhrase19
	dw CantWaitPhrase18
	dw CantWaitPhrase19
	dw CantWaitPhrase20
	dw CantWaitPhrase21
	dw 0
CantWaitD:
	dw CantWaitPhrase22
	dw CantWaitPhrase22
CantWaitDLoop:
	dw CantWaitPhrase22
	dw CantWaitPhrase22
	dw CantWaitPhrase22
	dw CantWaitPhrase22
	dw CantWaitPhrase22
	dw CantWaitPhrase22
	dw CantWaitPhrase22
	dw CantWaitPhrase22
	dw CantWaitPhrase22
	dw CantWaitPhrase22
	dw CantWaitPhrase22
	dw CantWaitPhrase22
	dw CantWaitPhrase22
	dw CantWaitPhrase22
	dw CantWaitPhrase22
	dw CantWaitPhrase22
	dw CantWaitPhrase22
	dw CantWaitPhrase23
	dw Rest8Phrase
	dw CantWaitPhrase22
	dw CantWaitPhrase24
	dw 0

HakunaMatataA:
	dw Vibrato01Phrase
	dw Transpose0Phrase
	dw HakunaMatataPhrase01
	dw HakunaMatataPhrase02
	dw HakunaMatataPhrase03
	dw HakunaMatataPhrase04
	dw HakunaMatataPhrase05
	dw HakunaMatataPhrase06
	dw HakunaMatataPhrase07
	dw HakunaMatataPhrase08
	dw HakunaMatataPhrase04
	dw HakunaMatataPhrase05
	dw 0
HakunaMatataB:
	dw Vibrato01Phrase
	dw HakunaMatataPhrase09
	dw HakunaMatataPhrase10
	dw HakunaMatataPhrase11
	dw HakunaMatataPhrase12
	dw HakunaMatataPhrase13
	dw HakunaMatataPhrase14
	dw HakunaMatataPhrase15
	dw HakunaMatataPhrase16
	dw HakunaMatataPhrase04
	dw HakunaMatataPhrase13
	dw 0
HakunaMatataC:
	dw Vibrato01Phrase
	dw HakunaMatataPhrase17
	dw HakunaMatataPhrase18
	dw HakunaMatataPhrase19
	dw HakunaMatataPhrase20
	dw HakunaMatataPhrase21
	dw HakunaMatataPhrase22
	dw HakunaMatataPhrase23
	dw HakunaMatataPhrase24
	dw HakunaMatataPhrase20
	dw HakunaMatataPhrase21
	dw 0
HakunaMatataD:
	dw HakunaMatataPhrase25
	dw 0

LoveTonightA:
	dw Vibrato02Phrase
	dw TransposeUp3Phrase
	dw LoveTonightPhrase01
	dw LoveTonightPhrase02
	dw LoveTonightPhrase03
	dw LoveTonightPhrase04
	dw LoveTonightPhrase05
	dw LoveTonightPhrase03
	dw LoveTonightPhrase04
	dw LoveTonightPhrase06
	dw 0
LoveTonightB:
	dw Vibrato02Phrase
	dw LoveTonightPhrase07
	dw LoveTonightPhrase08
	dw LoveTonightPhrase09
	dw LoveTonightPhrase10
	dw LoveTonightPhrase11
	dw LoveTonightPhrase09
	dw LoveTonightPhrase10
	dw LoveTonightPhrase12
	dw 0
LoveTonightC:
	dw Vibrato03Phrase
	dw LoveTonightPhrase13
	dw LoveTonightPhrase14
	dw LoveTonightPhrase15
	dw LoveTonightPhrase16
	dw LoveTonightPhrase17
	dw LoveTonightPhrase15
	dw LoveTonightPhrase16
	dw LoveTonightPhrase18
	dw 0
LoveTonightD:
	dw LoveTonightPhrase19
	dw 0

CircleA:
	dw Vibrato02Phrase
	dw Transpose0Phrase
	dw CirclePhrase01
	dw CirclePhrase02
	dw CirclePhrase03
	dw CirclePhrase02
	dw CirclePhrase03
	dw CirclePhrase04
	dw CirclePhrase05
	dw 0
CircleB:
	dw Vibrato02Phrase
	dw CirclePhrase06
	dw CirclePhrase07
	dw CirclePhrase08
	dw CirclePhrase07
	dw CirclePhrase08
	dw CirclePhrase09
	dw CirclePhrase10
	dw 0
CircleC:
	dw Vibrato02Phrase
	dw CirclePhrase11
	dw CirclePhrase12
	dw CirclePhrase13
	dw CirclePhrase14
	dw CirclePhrase12
	dw CirclePhrase13
	dw CirclePhrase15
	dw CirclePhrase16
	dw CirclePhrase17
	dw 0
CircleD:
	dw CirclePhrase18
	dw 0
	
BePreparedA:
	dw Vibrato02Phrase
	dw Transpose0Phrase
	dw BePreparedPhrase01
	dw TransposeUp5Phrase
	dw BePreparedPhrase01
	dw Transpose0Phrase
	dw BePreparedPhrase02
	dw BePreparedPhrase03
	dw BePreparedPhrase02
	dw BePreparedPhrase03
	dw BePreparedPhrase04
	dw BePreparedPhrase04
	dw BePreparedPhrase05
	dw BePreparedPhrase06
	dw BePreparedPhrase02
	dw BePreparedPhrase07
	dw BePreparedPhrase08
	dw BePreparedPhrase09
	dw BePreparedPhrase10
	dw BePreparedPhrase11
	dw BePreparedPhrase12
	dw BePreparedPhrase13
	dw 0	
BePreparedB:
	dw Vibrato02Phrase
	dw BePreparedPhrase14
	dw BePreparedPhrase14
	dw BePreparedPhrase15
	dw BePreparedPhrase16
	dw BePreparedPhrase15
	dw BePreparedPhrase16
	dw BePreparedPhrase17
	dw BePreparedPhrase17
	dw BePreparedPhrase18
	dw BePreparedPhrase19
	dw BePreparedPhrase15
	dw BePreparedPhrase20
	dw BePreparedPhrase21
	dw BePreparedPhrase22
	dw BePreparedPhrase23
	dw BePreparedPhrase24
	dw BePreparedPhrase25
	dw BePreparedPhrase26
	dw 0
BePreparedC:
	dw Vibrato02Phrase
	dw BePreparedPhrase27
	dw BePreparedPhrase28
	dw BePreparedPhrase29
	dw BePreparedPhrase30
	dw BePreparedPhrase31
	dw BePreparedPhrase32
	dw BePreparedPhrase33
	dw BePreparedPhrase34
	dw BePreparedPhrase35
	dw BePreparedPhrase36
	dw BePreparedPhrase37
	dw BePreparedPhrase38
	dw BePreparedPhrase39
	dw BePreparedPhrase40
	dw BePreparedPhrase41
	dw BePreparedPhrase42
	dw BePreparedPhrase43
	dw BePreparedPhrase44
	dw 0
BePreparedD:
	dw BePreparedPhrase45
	dw BePreparedPhrase45
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase47
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw BePreparedPhrase46
	dw 0

HooHahA:
	dw Vibrato02Phrase
	dw Transpose0Phrase
	dw HooHahPhrase01
	dw HooHahPhrase01
	dw HooHahPhrase01
	dw HooHahPhrase01
	dw HooHahPhrase02
	dw HooHahPhrase02
	dw HooHahPhrase02
	dw HooHahPhrase02
	dw 0
HooHahB:
	dw Vibrato02Phrase
	dw HooHahPhrase03
	dw HooHahPhrase03
	dw HooHahPhrase03
	dw HooHahPhrase03
	dw HooHahPhrase04
	dw HooHahPhrase04
	dw HooHahPhrase04
	dw HooHahPhrase04
	dw 0
HooHahC:
	dw Vibrato02Phrase
	dw Rest48Phrase
	dw Rest48Phrase
	dw HooHahPhrase05
	dw HooHahPhrase05
	dw HooHahPhrase05
	dw HooHahPhrase05
	dw 0
HooHahD:
	dw HooHahPhrase06
	dw 0

ThisLandA:
	dw Vibrato02Phrase
	dw Transpose0Phrase
	dw ThisLandPhrase01
	dw ThisLandPhrase02
	dw ThisLandPhrase03
	dw ThisLandPhrase04
	dw ThisLandPhrase05
	dw ThisLandPhrase06
	dw ThisLandPhrase07
	dw ThisLandPhrase08
	dw 0
ThisLandB:
	dw Vibrato02Phrase
	dw ThisLandPhrase09
	dw ThisLandPhrase10
	dw ThisLandPhrase11
	dw ThisLandPhrase12
	dw ThisLandPhrase13
	dw ThisLandPhrase14
	dw ThisLandPhrase15
	dw ThisLandPhrase16
	dw 0
ThisLandC:
	dw Vibrato02Phrase
	dw ThisLandPhrase17
	dw ThisLandPhrase18
	dw ThisLandPhrase19
	dw ThisLandPhrase20
	dw ThisLandPhrase21
	dw ThisLandPhrase22
	dw ThisLandPhrase23
	dw ThisLandPhrase24
	dw 0
ThisLandD:
	dw ThisLandPhrase25
	dw 0
	
JingleA:
	dw Vibrato02Phrase
	dw Transpose0Phrase
	dw JinglePhrase01
	dw 0
JingleB:
	dw Vibrato02Phrase
	dw JinglePhrase02
	dw 0
JingleC:
	dw Vibrato02Phrase
	dw JinglePhrase03
	dw 0
JingleD:
	dw JinglePhrase04
	dw 0
	
ToDieForA:
	dw Vibrato02Phrase
	dw Transpose0Phrase
	dw ToDieForPhrase01
	dw ToDieForPhrase02
	dw ToDieForPhrase03
	dw ToDieForPhrase04
	dw ToDieForPhrase05
	dw ToDieForPhrase06
	dw ToDieForPhrase07
	dw ToDieForPhrase08
	dw ToDieForPhrase09
	dw ToDieForPhrase10
	dw ToDieForPhrase11
	dw ToDieForPhrase05
	dw ToDieForPhrase12
	dw 0
ToDieForB:
	dw Vibrato02Phrase
	dw ToDieForPhrase13
	dw ToDieForPhrase14
	dw ToDieForPhrase15
	dw ToDieForPhrase16
	dw ToDieForPhrase17
	dw ToDieForPhrase18
	dw ToDieForPhrase19
	dw ToDieForPhrase20
	dw ToDieForPhrase21
	dw ToDieForPhrase22
	dw ToDieForPhrase23
	dw ToDieForPhrase17
	dw ToDieForPhrase24
	dw 0
ToDieForC:
	dw Vibrato02Phrase
	dw TransposeChDownOctPhrase
	dw ToDieForPhrase25
	dw ToDieForPhrase25
	dw ToDieForPhrase25
	dw ToDieForPhrase26
	dw ToDieForPhrase27
	dw ToDieForPhrase28
	dw ToDieForPhrase29
	dw ToDieForPhrase29
	dw ToDieForPhrase29
	dw ToDieForPhrase30
	dw ToDieForPhrase30
	dw ToDieForPhrase31
	dw ToDieForPhrase32
	dw 0
ToDieForD:
	dw ToDieForPhrase33
	dw ToDieForPhrase33
	dw ToDieForPhrase33
	dw ToDieForPhrase33
	dw ToDieForPhrase34
	dw ToDieForPhrase34
	dw ToDieForPhrase34
	dw ToDieForPhrase34
	dw ToDieForPhrase34
	dw ToDieForPhrase35
	dw ToDieForPhrase35
	dw ToDieForPhrase34
	dw ToDieForPhrase34
	dw 0

ExileA:
	dw Vibrato02Phrase
	dw Transpose0Phrase
	dw ExilePhrase01
	dw ExilePhrase02
	dw ExilePhrase03
	dw ExilePhrase04
	dw ExilePhrase05
	dw ExilePhrase06
	dw ExilePhrase07
	dw 0
ExileB:
	dw Vibrato02Phrase
	dw ExilePhrase08
	dw ExilePhrase09
	dw ExilePhrase10
	dw ExilePhrase11
	dw ExilePhrase12
	dw ExilePhrase13
	dw ExilePhrase14
	dw 0
ExileC:
	dw Vibrato02Phrase
	dw TransposeChDownOctPhrase
	dw ExilePhrase15
	dw ExilePhrase16
	dw ExilePhrase17
	dw ExilePhrase18
	dw ExilePhrase19
	dw ExilePhrase20
	dw ExilePhrase21
	dw 0
ExileD:
	dw ExilePhrase22
	dw 0
	
UnderTheStarsA:
	dw Vibrato02Phrase
	dw Transpose0Phrase
	dw UnderTheStarsPhrase01
	dw UnderTheStarsPhrase02
	dw UnderTheStarsPhrase03
	dw UnderTheStarsPhrase04
	dw UnderTheStarsPhrase05
	dw 0
UnderTheStarsB:
	dw Vibrato02Phrase
	dw UnderTheStarsPhrase06
	dw UnderTheStarsPhrase07
	dw UnderTheStarsPhrase08
	dw UnderTheStarsPhrase09
	dw UnderTheStarsPhrase10
	dw 0
UnderTheStarsC:
	dw Vibrato02Phrase
	dw TransposeChDownOctPhrase
	dw UnderTheStarsPhrase11
	dw UnderTheStarsPhrase12
	dw UnderTheStarsPhrase13
	dw UnderTheStarsPhrase14
	dw UnderTheStarsPhrase15
	dw 0
UnderTheStarsD:
	dw UnderTheStarsPhrase16
	dw 0

BugTossA:	
	dw Vibrato02Phrase
	dw Transpose0Phrase
	dw BugTossPhrase01
	dw BugTossPhrase02
	dw BugTossPhrase03
	dw BugTossPhrase04
	dw 0
BugTossB:
	dw Vibrato02Phrase
	dw BugTossPhrase05
	dw BugTossPhrase06
	dw BugTossPhrase07
	dw BugTossPhrase08
	dw 0
BugTossC:
	dw Vibrato02Phrase
	dw TransposeChDownOctPhrase
	dw BugTossPhrase09
	dw BugTossPhrase10
	dw BugTossPhrase11
	dw BugTossPhrase12
	dw 0
BugTossD:
	dw BugTossPhrase13
	dw 0

DeathTagA:
	dw Vibrato02Phrase
	dw Transpose0Phrase
	dw DeathTagPhrase01
	dw 0
DeathTagB:
	dw Vibrato02Phrase
	dw DeathTagPhrase02
	dw 0
DeathTagC:
	dw Vibrato02Phrase
	dw TransposeChDownOctPhrase
	dw DeathTagPhrase03
	dw 0
DeathTagD:
	dw DeathTagPhrase04
	dw 0

KingTagA:
	dw Vibrato02Phrase
	dw Transpose0Phrase
	dw KingTagPhrase01
	dw 0
KingTagB:
	dw Vibrato02Phrase
	dw KingTagPhrase02
	dw 0
KingTagC:
	dw Vibrato02Phrase
	dw TransposeChDownOctPhrase
	dw KingTagPhrase03
	dw 0
KingTagD:
	dw KingTagPhrase04
	dw 0

CantWaitPhrase01:
	db tempo, 55
	db len32
	db rest
	db rest
	db exit
CantWaitPhrase02:
	db duty, $80
	db env, $A7
	db len16
	db $19
	db len6
	db $17
	db len10
	db $14
	db len16
	db $19
	db len6
	db $1D
	db len10
	db $19
	db exit
CantWaitPhrase03:
	db env, $A7
	db len16
	db $19
	db len6
	db $17
	db len10
	db $14
	db len16
	db $19
	db len6
	db $1D
	db len10
	db $19
	db exit
CantWaitPhrase04:
	db env, $A2
	db len6
	db $12
	db len2
	db $12
	db len4
	db $12
	db len2
	db $12
	db len8
	db $12
	db len2
	db $12
	db len8
	db $12
	db len6
	db $12
	db len2
	db $12
	db len4
	db $12
	db len2
	db $12
	db len8
	db $12
	db len2
	db $12
	db len8
	db $12
	db exit
CantWaitPhrase05:
	db env, $A2
	db len6
	db $17
	db len2
	db $17
	db len4
	db $17
	db len2
	db $17
	db len8
	db $17
	db len2
	db $17
	db len8
	db $17
	db len6
	db $17
	db len2
	db $17
	db len4
	db $17
	db len2
	db $17
	db len8
	db $16
	db len2
	db $16
	db len8
	db $16
	db exit
CantWaitPhrase06:
	db env, $A4
	db len6
	db $0D
	db env, $A2
	db len2
	db $0D
	db len4
	db $0D
	db len2
	db $0D
	db len8
	db $0D
	db len2
	db $0D
	db len8
	db $0D
	db env, $A4
	db len6
	db $0D
	db env, $A2
	db len2
	db $0D
	db len4
	db $0D
	db len2
	db $0D
	db len8
	db $0D
	db tempo, 46
	db len2
	db $0D
	db exit
CantWaitPhrase07:
	db tempo, 55
	db len8
	db rest
	db env, $A4
	db len6
	db $12
	db env, $A2
	db len2
	db $12
	db len4
	db $12
	db len2
	db $12
	db len8
	db $0D
	db len2
	db $0D
	db len8
	db $0D
	db loop
	dw CantWaitALoop
	db exit
CantWaitPhrase08:
	db len32
	db rest
	db rest
	db exit
CantWaitPhrase09:
	db duty, $C0
	db env, $A7
	db len16
	db $1E
	db len6
	db $1B
	db len10
	db $19
	db len16
	db $1E
	db len6
	db $20
	db len10
	db $1D
	db exit
CantWaitPhrase10:	
	db duty, $80
	db env, $A7
	db len3
	db $12
	db len1
	db $16
	db len2
	db $19
	db env, $A2
	db len4
	db $1E
	db $1E
	db env, $A7
	db len2
	db $1E
	db len4
	db $1B
	db len2
	db $17
	db len10
	db $19
	db len3
	db $12
	db len1
	db $16
	db len2
	db $19
	db env, $A2
	db len4
	db $1E
	db $1E
	db env, $A7
	db len2
	db $1E
	db len4
	db $20
	db len2
	db $1D
	db len10
	db $19
	db exit
CantWaitPhrase11:
	db duty, $80
	db env, $A4
	db len6
	db $0D
	db $0F
	db env, $A3
	db len4
	db $12
	db env, $A7
	db len2
	db $16
	db len4
	db $14
	db len6
	db $12
	db env, $A3
	db len4
	db $0F
	db $12
	db $0F
	db env, $A7
	db len2
	db $12
	db len4
	db $14
	db len18
	db $12
	db exit
CantWaitPhrase12:	
	db duty, $80
	db env, $A7
	db len4
	db $0F
	db env, $A3
	db $12
	db env, $A7
	db $12
	db len2
	db $14
	db $12
	db env, $A2
	db $15
	db env, $A7
	db len4
	db $14
	db len8
	db $12
	db len2
	db $0F
	db env, $A3
	db len4
	db $12
	db env, $A7
	db $0F
	db env, $A2
	db len2
	db $12
	db env, $A7
	db len4
	db $0F
	db env, $A8
	db len18
	db $0D
	db exit
CantWaitPhrase13:
	db env, $A4
	db len6
	db $14
	db env, $A2
	db len2
	db $14
	db len4
	db $14
	db len2
	db $14
	db len8
	db $14
	db len2
	db $0D
	db len8
	db $0D
	db env, $A4
	db len6
	db $11
	db env, $A2
	db len2
	db $11
	db len4
	db $11
	db len2
	db $11
	db len8
	db $11
	db len2
	db $12
	db exit
CantWaitPhrase14:
	db len8
	db rest
	db env, $A4
	db len6
	db $15
	db env, $A2
	db len2
	db $15
	db len4
	db $15
	db len2
	db $15
	db len8
	db $14
	db len2
	db $14
	db len8
	db $14
	db loop
	dw CantWaitBLoop
	db exit
CantWaitPhrase15:
	db len32
	db rest
	db rest
	db exit
CantWaitPhrase16:
	db env, $20, 32
	db len3
	db $1E
	db len1
	db $22
	db len2
	db $25
	db $2A
	db env, $40, 32
	db $2A
	db env, $20, 32
	db $2A
	db env, $40, 32
	db $2A
	db env, $20, 32
	db $2A
	db len4
	db $27
	db len2
	db $23
	db len6
	db $25
	db env, $40, 32
	db len2
	db $25
	db env, $60, 32
	db $25
	db env, $20, 32
	db len3
	db $1E
	db len1
	db $22
	db len2
	db $25
	db $2A
	db env, $40, 32
	db $2A
	db env, $20, 32
	db $2A
	db env, $40, 32
	db $2A
	db env, $20, 32
	db $2A
	db len4
	db $2C
	db len2
	db $29
	db len6
	db $25
	db len2
	db $25
	db len1
	db $27
	db $2A
	db exit
CantWaitPhrase17:
	db env, $20, 128
	db len10
	db $12
	db env, $40, 128
	db $12
	db env, $60, 128
	db len9
	db $12
	db env, $20, 96
	db len1
	db $0D
	db $0F
	db $11
	db len6
	db $12
	db env, $40, 96
	db $12
	db env, $60, 96
	db len4
	db $12
	db env, $20, 96
	db len5
	db $19
	db env, $40, 96
	db $19
	db env, $60, 96
	db len3
	db $19
	db env, $20, 96
	db len1
	db $0D
	db $0F
	db $11
	db exit
CantWaitPhrase18:
	db env, $20, 96
	db len7
	db $12
	db env, $40, 96
	db $12
	db env, $60, 96
	db len8
	db $12
	db env, $20, 96
	db len3
	db $1B
	db env, $40, 96
	db len2
	db $1B
	db env, $60, 96
	db len1
	db $1B
	db env, $20, 96
	db len4
	db $19
	db len5
	db $12
	db env, $40, 96
	db $12
	db env, $60, 96
	db len6
	db $12
	db env, $20, 32
	db len2
	db $19
	db $1B
	db $1E
	db $1E
	db env, $40, 96
	db $1E
	db env, $20, 32
	db $19
	db $1B
	db $19
	db exit
CantWaitPhrase19:	
	db env, $20, 96
	db len6
	db $17
	db env, $40, 96
	db len5
	db $17
	db env, $60, 96
	db $17
	db env, $20, 32
	db len3
	db $20
	db env, $40, 96
	db len2
	db $20
	db env, $60, 96
	db len1
	db $20
	db env, $20, 32
	db len3
	db $1E
	db env, $40, 96
	db len2
	db $1E
	db env, $60, 96
	db $1E
	db env, $20, 96
	db len1
	db $1C
	db $1B
	db $19
	db len6
	db $17
	db env, $40, 96
	db len5
	db $17
	db env, $60, 96
	db $17
	db env, $20, 96
	db len4
	db $12
	db env, $40, 96
	db len2
	db $12
	db env, $20, 96
	db $12
	db env, $40, 96
	db $12
	db env, $60, 96
	db len1
	db $12
	db env, $20, 96
	db len2
	db $12
	db env, $40, 96
	db len1
	db $12
	db env, $60, 96
	db len2
	db $12
	db exit
CantWaitPhrase20:
	db env, $20, 96
	db len4
	db $20
	db env, $40, 96
	db len2
	db $20
	db env, $60, 96
	db $20
	db env, $20, 96
	db $20
	db env, $40, 96
	db $20
	db env, $20, 96
	db $1E
	db env, $40, 96
	db $1E
	db env, $20, 96
	db $20
	db env, $40, 96
	db $20
	db env, $20, 96
	db $1E
	db env, $40, 96
	db $1E
	db env, $20, 96
	db $23
	db $22
	db $1E
	db len10
	db $20
	db env, $40, 96
	db len4
	db $20
	db env, $60, 96
	db $20
	db env, $20, 96
	db len2
	db $19
	db env, $40, 96
	db $19
	db env, $60, 96
	db len4
	db $19
	db exit
CantWaitPhrase21:
	db env, $20, 96
	db len2
	db $1B
	db env, $40, 96
	db $1B
	db env, $20, 96
	db len2
	db $1E
	db env, $40, 96
	db $1E
	db env, $20, 96
	db len4
	db $21
	db env, $40, 96
	db len2
	db $21
	db env, $60, 96
	db $21
	db env, $20, 96
	db len3
	db $20
	db len2
	db $1E
	db env, $40, 96
	db len1
	db $1E
	db env, $20, 96
	db len3
	db $25
	db env, $40, 96
	db len2
	db $25
	db env, $60, 96
	db len1
	db $25
	db env, $20, 96
	db len2
	db $19
	db $19
	db $1B
	db len3
	db $1E
	db env, $40, 96
	db len1
	db $1E
	db env, $20, 96
	db len2
	db $1E
	db loop
	dw CantWaitCLoop
	db exit
CantWaitPhrase22:
	db len2
	db env, $62
	db $07
	db env, $61
	db $27
	db env, $41
	db $01
	db env, $62
	db $07
	db env, $41
	db $01
	db env, $41
	db $01
	db env, $62
	db $07
	db env, $41
	db $01
	db env, $41
	db $01
	db env, $62
	db $07
	db env, $62
	db $07
	db env, $41
	db $01
	db env, $62
	db $07
	db env, $61
	db $27
	db env, $41
	db $01
	db env, $41
	db $01
	db exit
CantWaitPhrase23:
	db len2
	db env, $62
	db $07
	db env, $61
	db $27
	db env, $41
	db $01
	db env, $62
	db $07
	db env, $41
	db $01
	db env, $41
	db $01
	db env, $62
	db $07
	db env, $41
	db $01
	db env, $41
	db $01
	db len6
	db rest
	db exit
CantWaitPhrase24:
	db loop
	dw CantWaitDLoop
	db exit

HakunaMatataPhrase01:
	db tempo, 48
	db duty, $40
	db env, $74
	db len4
	db $1A
	db env, $A6
	db len3
	db $11
	db len2
	db $15
	db len3
	db $18
	db len4
	db $1D
	db env, $A4
	db len6
	db $15
	db len3
	db $18
	db env, $A6
	db len1
	db $11
	db $15
	db $18
	db len2
	db $15
	db $18
	db $10
	db len1
	db $10
	db $13
	db env, $A2
	db len2
	db $18
	db env, $A3
	db len6
	db $10
	db env, $A4
	db len2
	db $15
	db $18
	db len6
	db $11
	db len4
	db $13
	db len1
	db $11
	db $13
	db len4
	db $15
	db exit
HakunaMatataPhrase02:	
	db duty, $40
	db env, $74
	db len4
	db $1A
	db env, $A6
	db len3
	db $11
	db len2
	db $15
	db len3
	db $18
	db len4
	db $1D
	db env, $A4
	db len6
	db $15
	db len3
	db $18
	db env, $A6
	db len1
	db $11
	db $15
	db $18
	db len2
	db $15
	db len4
	db $18
	db env, $A3
	db $18
	db $18
	db env, $A2
	db len2
	db $18
	db env, $A3
	db $18
	db len4
	db $18
	db $18
	db len2
	db $18
	db $16
	db $18
	db $16
	db $18
	db exit
HakunaMatataPhrase03:
	db duty, $40
	db env, $A3
	db len2
	db rest
	db len4
	db $18
	db $18
	db env, $A2
	db len2
	db $18
	db env, $A3
	db $18
	db len4
	db $18
	db $18
	db exit
HakunaMatataPhrase04:
	db duty, $40
	db env, $74
	db len2
	db $18
	db env, $A4
	db $18
	db env, $74
	db $18
	db env, $A4
	db $18
	db env, $74
	db $18
	db env, $A4
	db $16
	db len9
	db $15
	db env, $A7
	db len5
	db $11
	db len3
	db $10
	db $11
	db len2
	db $13
	db len3
	db $16
	db $18
	db len2
	db $16
	db exit
HakunaMatataPhrase05:
	db duty, $40
	db env, $A7
	db len4
	db $13
	db len2
	db $1D
	db len4
	db $1C
	db len2
	db $1F
	db $1F
	db $1F
	db exit
HakunaMatataPhrase06:
	db duty, $40
	db env, $A7
	db len2
	db rest
	db $10
	db $11
	db $13
	db len4
	db $18
	db $18
	db len2
	db $16
	db len14
	db $15
	db len4
	db $11
	db $15
	db $18
	db $15
	db exit
HakunaMatataPhrase07:
	db duty, $40
	db env, $A4
	db len10
	db $17
	db len2
	db $0E
	db $13
	db env, $A2
	db len10
	db $0E
	db len2
	db $0E
	db env, $74
	db len2
	db $15
	db env, $A2
	db len4
	db $0F
	db len2
	db $10
	db len14
	db $10
	db env, $A4
	db len4
	db $10
	db $10
	db len6
	db $0C
	db len2
	db $12
	db exit
HakunaMatataPhrase08:
	db duty, $40
	db env, $A7
	db len6
	db $12
	db env, $A5
	db len8
	db $15
	db env, $A4
	db len8
	db $15
	db exit
HakunaMatataPhrase09:
	db duty, $80
	db len2
	db rest
	db env, $73
	db len1
	db $16
	db $18
	db len2
	db $1A
	db env, $A4
	db $11
	db $1A
	db $18
	db $16
	db len4
	db $18
	db $15
	db env, $A7
	db len16
	db $11
	db len2
	db $10
	db $13
	db $18
	db $13
	db $71
	db $15
	db exit
HakunaMatataPhrase10:
	db duty, $80
	db len2
	db rest
	db env, $73
	db len1
	db $16
	db $18
	db len2
	db $1A
	db env, $A4
	db $11
	db $1A
	db $18
	db $16
	db len4
	db $18
	db $1D
	db env, $A7
	db len12
	db $15
	db env, $73
	db len4
	db $1C
	db $1C
	db env, $72
	db len2
	db $1C
	db env, $73
	db $1C
	db len4
	db $1C
	db $1C
	db len2
	db $1C
	db $1A
	db $1C
	db $1A
	db $1C
	db exit
HakunaMatataPhrase11:
	db duty, $80
	db len2
	db rest
	db env, $74
	db len4
	db $1C
	db $1C
	db env, $73
	db len2
	db $1C
	db env, $74
	db $1C
	db len4
	db $1C
	db $1C
	db exit
HakunaMatataPhrase12:
	db duty, $80
	db env, $74
	db len1
	db $1C
	db env, $A7
	db $1B
	db len3
	db $1C
	db len1
	db $1B
	db len2
	db $1C
	db $1C
	db $1A
	db len9
	db $18
	db env, $A4
	db len5
	db $15
	db env, $A7
	db len3
	db $13
	db $15
	db env, $A3
	db len2
	db $18
	db env, $A7
	db len3
	db $1A
	db $1B
	db len2
	db $1A
	db exit
HakunaMatataPhrase13:
	db duty, $80
	db env, $A7
	db len4
	db $18
	db len2
	db $21
	db len4
	db $1F
	db len2
	db $1A
	db $1C
	db $18
	db exit
HakunaMatataPhrase14:
	db duty, $80
	db len2
	db rest
	db env, $A7
	db $13
	db $15
	db len1
	db $18
	db $1B
	db len3
	db $1C
	db len1
	db $1B
	db len2
	db $1C
	db $1C
	db $1A
	db len14
	db $18
	db len4
	db $15
	db $18
	db $1C
	db $18
	db exit
HakunaMatataPhrase15:
	db duty, $80
	db env, $A4
	db len10
	db $1A
	db len2
	db $13
	db $17
	db env, $A3
	db len8
	db $13
	db env, $A4
	db len2
	db $10
	db $13
	db $10
	db $14
	db $10
	db $15
	db env, $A3
	db len14
	db $15
	db env, $A5
	db len4
	db $15
	db $13
	db len2
	db $10
	db $0E
	db $0C
	db $0E
	db exit
HakunaMatataPhrase16:
	db duty, $80
	db env, $A7
	db len6
	db $0E
	db len2
	db $1A
	db $1E
	db env, $A2
	db len4
	db $1F
	db env, $A4
	db len8
	db $21
	db exit
HakunaMatataPhrase17:
	db tp, -12
	db env, $20, 128
	db len9
	db $16
	db env, $40, 128
	db len2
	db $16
	db env, $60, 128
	db len1
	db $16
	db env, $20, 128
	db len4
	db $1B
	db len2
	db $1D
	db env, $40, 128
	db len4
	db $1D
	db env, $20, 128
	db len3
	db $1D
	db env, $40, 128
	db len2
	db $1D
	db env, $60, 128
	db len1
	db $1D
	db env, $20, 128
	db len4
	db $17
	db len2
	db $18
	db env, $60, 128
	db len4
	db $18
	db env, $20, 128
	db len3
	db $18
	db env, $40, 128
	db len2
	db $18
	db env, $60, 128
	db len1
	db $18
	db env, $20, 128
	db len4
	db $10
	db len2
	db $11
	db env, $60, 128
	db $63
	db $11
	db env, $20, 128
	db len3
	db $11
	db env, $40, 128
	db len2
	db $11
	db env, $60, 128
	db len1
	db $11
	db env, $20, 128
	db len4
	db $15
	db exit
HakunaMatataPhrase18:	
	db env, $20, 128
	db len9
	db $16
	db env, $40, 128
	db len2
	db $16
	db env, $60, 128
	db len1
	db $16
	db env, $20, 128
	db len4
	db $0F
	db len2
	db $11
	db env, $60, 128
	db len4
	db $11
	db env, $20, 128
	db len3
	db $11
	db env, $40, 128
	db len2
	db $11
	db env, $60, 128
	db len1
	db $11
	db env, $20, 128
	db len4
	db $17
	db len3
	db $18
	db env, $40, 128
	db len2
	db $18
	db env, $60, 128
	db len1
	db $18
	db env, $20, 128
	db len2
	db $18
	db len3
	db $13
	db env, $40, 128
	db len2
	db $13
	db env, $60, 128
	db len1
	db $13
	db env, $20, 128
	db len2
	db $13
	db len3
	db $18
	db env, $40, 128
	db len2
	db $18
	db env, $60, 128
	db len1
	db $18
	db env, $20, 128
	db len3
	db $18
	db env, $40, 128
	db len1
	db $18
	db env, $20, 128
	db len2
	db $18
	db len3
	db $13
	db env, $40, 128
	db len1
	db $13
	db exit
HakunaMatataPhrase19:
	db env, $20, 128
	db len3
	db $0C
	db env, $40, 128
	db len2
	db $0C
	db env, $60, 128
	db len1
	db $0C
	db env, $20, 128
	db len2
	db $0C
	db len3
	db $13
	db env, $40, 128
	db len2
	db $13
	db env, $60, 128
	db len1
	db $13
	db env, $20, 128
	db len2
	db $13
	db len3
	db $0C
	db env, $40, 128
	db len2
	db $0C
	db env, $60, 128
	db len1
	db $0C
	db exit
HakunaMatataPhrase20:
	db env, $00, 128
	db len10
	db rest
	db env, $20, 128
	db len2
	db $11
	db env, $60, 128
	db len4
	db $11
	db env, $20, 128
	db len3
	db $11
	db env, $40, 128
	db len2
	db $11
	db env, $60, 128
	db len1
	db $11
	db env, $20, 128
	db len4
	db $18
	db len2
	db $1D
	db env, $60, 128
	db len4
	db $11
	db env, $20, 128
	db len3
	db $1D
	db env, $40, 128
	db len2
	db $1D
	db env, $60, 128
	db len1
	db $1D
	db env, $20, 128
	db $63
	db $17
	db exit
HakunaMatataPhrase21:
	db env, $20, 128
	db len2
	db $18
	db env, $60, 128
	db len4
	db $18
	db env, $20, 128
	db len3
	db $18
	db env, $40, 128
	db len2
	db $18
	db env, $60, 128
	db len5
	db $18
	db exit
HakunaMatataPhrase22:
	db env, $20, 128
	db len2
	db $18
	db env, $60, 128
	db len14
	db $18
	db env, $20, 128
	db len3
	db $11
	db env, $40, 128
	db len2
	db $11
	db env, $60, 128
	db len1
	db $11
	db env, $20, 128
	db len4
	db $1D
	db len2
	db $18
	db $1A
	db $1D
	db len3
	db $1A
	db env, $40, 128
	db len1
	db $1A
	db $18
	db $17
	db $15
	db $13
	db env, $20, 128
	db len4
	db $11
	db $12
	db exit
HakunaMatataPhrase23:
	db env, $20, 128
	db len3
	db $13
	db env, $40, 128
	db len2
	db $13
	db env, $60, 128
	db len1
	db $13
	db env, $20, 128
	db len2
	db $13
	db len3
	db $15
	db env, $40, 128
	db len2
	db $15
	db env, $60, 128
	db len1
	db $15
	db env, $20, 128
	db len2
	db $15
	db len4
	db $17
	db env, $40, 128
	db len3
	db $17
	db env, $60, 128
	db len1
	db $17
	db env, $20, 128
	db len2
	db $13
	db env, $40, 128
	db len1
	db $13
	db env, $60, 128
	db $13
	db env, $20, 128
	db len2
	db $14
	db env, $40, 128
	db len1
	db $14
	db env, $60, 128
	db $14
	db env, $20, 128
	db len4
	db $15
	db env, $40, 128
	db len3
	db $15
	db env, $60, 128
	db len1
	db $15
	db env, $20, 128
	db len3
	db $15
	db env, $60, 128
	db len1
	db $15
	db env, $20, 128
	db len3
	db $13
	db env, $60, 128
	db len1
	db $13
	db env, $20, 128
	db len3
	db $10
	db env, $40, 128
	db len2
	db $10
	db env, $60, 128
	db len1
	db $10
	db env, $20, 128
	db len3
	db $0E
	db env, $40, 128
	db len2
	db $0E
	db env, $60, 128
	db len1
	db $0E
	db env, $20, 128
	db len2
	db $0C
	db $0E
	db exit
HakunaMatataPhrase24:
	db env, $20, 128
	db len2
	db $0E
	db env, $60, 128
	db len4
	db $0E
	db env, $20, 128
	db len3
	db $0E
	db env, $40, 128
	db len2
	db $0E
	db env, $60, 128
	db len5
	db $0E
	db env, $20, 128
	db len2
	db $0E
	db env, $60, 128
	db len4
	db $0E
	db exit
HakunaMatataPhrase25:
	db env, $41
	db len2
	db $27
	db env, $61
	db len1
	db $01
	db $01
	db env, $62
	db len2
	db $07
	db len4
	db $07
	db env, $61
	db len2
	db $01
	db env, $62
	db len2
	db $07
	db env, $61
	db len2
	db $01
	db exit
	
LoveTonightPhrase01:
	db tempo, 20
	db duty, $80
	db env, $A6
	db len4
	db $0C
	db $0C
	db $0C
	db len1
	db $13
	db $18
	db $1A
	db $1C
	db len4
	db $0C
	db $0C
	db $0C
	db len2
	db $13
	db $10
	db len4
	db $0C
	db $0C
	db $0C
	db $0C
	db len4
	db $18
	db $18
	db $1A
	db $1A
	db exit
LoveTonightPhrase02:
	db duty, $80
	db env, $A6
	db len4
	db $0C
	db $0C
	db $0C
	db len1
	db $13
	db $18
	db $1A
	db $1C
	db len4
	db $0C
	db $0C
	db $0C
	db len1
	db $1F
	db $1C
	db $18
	db $13
	db len4
	db $0C
	db $0C
	db $0C
	db $0C
	db len4
	db $18
	db $18
	db $1A
	db $1A
	db exit
LoveTonightPhrase03:
	db duty, $80
	db env, $77
	db len4
	db $0C
	db env, $A7
	db len2
	db $18
	db len6
	db $17
	db len2
	db $1C
	db len6
	db $18
	db len2
	db $13
	db len10
	db $11
	db len4
	db $10
	db len1
	db $10
	db env, $A6
	db len3
	db $13
	db $18
	db $18
	db env, $A7
	db len18
	db $17
	db exit
LoveTonightPhrase04:
	db duty, $80
	db env, $A6
	db len4
	db $0C
	db $0C
	db $0C
	db len1
	db $13
	db $18
	db $1A
	db $1C
	db len4
	db $18
	db $10
	db $11
	db $11
	db exit
LoveTonightPhrase05:
	db len4
	db $18
	db $18
	db $18
	db $18
	db $1A
	db $1A
	db $1A
	db $1A
	db exit
LoveTonightPhrase06:
	db duty, $80
	db len4
	db $18
	db $18
	db $18
	db $13
	db $13
	db $13
	db $13
	db $13
	db exit
LoveTonightPhrase07:
	db duty, $80
	db env, $A6
	db len4
	db $11
	db $11
	db $10
	db $0C
	db len4
	db $11
	db $11
	db $10
	db $0C
	db len4
	db $11
	db $11
	db $10
	db $10
	db len4
	db $1D
	db $1D
	db $21
	db $1F
	db exit
LoveTonightPhrase08:
	db duty, $80
	db env, $A6
	db len4
	db $11
	db $11
	db $10
	db $0C
	db len4
	db $11
	db $11
	db $10
	db $0C
	db len4
	db $11
	db $11
	db $10
	db $10
	db len4
	db $1D
	db $1D
	db $21
	db $1F
	db exit
LoveTonightPhrase09:
	db duty, $80
	db env, $77
	db len4
	db $10
	db env, $A7
	db len2
	db $1C
	db len6
	db $1A
	db len2
	db $1F
	db len6
	db $1C
	db len2
	db $18
	db len10
	db $15
	db len4
	db $13
	db len1
	db $13
	db env, $A6
	db len3
	db $18
	db $1D
	db $1C
	db env, $A7
	db len18
	db $1A
	db exit
LoveTonightPhrase10:
	db duty, $80
	db env, $A6
	db len4
	db $11
	db $11
	db $10
	db $0C
	db $1C
	db $13
	db $15
	db $15
	db exit
LoveTonightPhrase11:
	db len4
	db $1D
	db $1C
	db $1A
	db $1C
	db $21
	db $21
	db $1F
	db $1F
	db exit
LoveTonightPhrase12:
	db len4
	db $1D
	db $1C
	db $1A
	db $1C
	db $18
	db $18
	db $18
	db $18
	db exit
LoveTonightPhrase13:
	db tp, -12
	db env, $20, 128
	db len2
	db $15
	db len1
	db $17
	db len2
	db $18
	db env, $40, 128
	db len1
	db $18
	db env, $20, 128
	db len1
	db $1A
	db len2
	db $18
	db len3
	db $13
	db env, $40, 128
	db $13
	db env, $60, 128
	db len1
	db $13
	db env, $20, 128
	db len2
	db $15
	db len1
	db $17
	db len2
	db $18
	db env, $40, 128
	db len1
	db $18
	db env, $20, 128
	db len1
	db $1A
	db len3
	db $18
	db env, $40, 128
	db $18
	db env, $60, 128
	db $18
	db env, $20, 128
	db len2
	db $15
	db len1
	db $17
	db len2
	db $18
	db env, $40, 128
	db len1
	db $18
	db env, $20, 128
	db len1
	db $1A
	db len2
	db $18
	db $13
	db $1C
	db env, $40, 128
	db $1C
	db env, $60, 128
	db len1
	db $1C
	db env, $20, 128
	db len2
	db $1D
	db len1
	db $1C
	db len2
	db $1A
	db env, $40, 128
	db len1
	db $1A
	db env, $20, 128
	db len1
	db $1C
	db len3
	db $1A
	db env, $40, 128
	db $1A
	db env, $60, 128
	db $1A
	db exit
LoveTonightPhrase14:
	db env, $20, 128
	db len2
	db $15
	db len1
	db $17
	db len2
	db $18
	db env, $40, 128
	db len1
	db $18
	db env, $20, 128
	db len1
	db $1A
	db len2
	db $18
	db len3
	db $13
	db env, $40, 128
	db $13
	db env, $60, 128
	db len1
	db $13
	db env, $20, 128
	db len2
	db $15
	db len1
	db $17
	db len2
	db $18
	db env, $40, 128
	db len1
	db $18
	db env, $20, 128
	db len1
	db $1A
	db len3
	db $18
	db env, $40, 128
	db $18
	db env, $60, 128
	db $18
	db env, $20, 128
	db len1
	db $15
	db $17
	db len2
	db $18
	db env, $40, 128
	db len1
	db $18
	db env, $20, 128
	db len2
	db $13
	db $1F
	db $1C
	db $1A
	db $18
	db env, $40, 128
	db len1
	db $18
	db env, $20, 128
	db len2
	db $1D
	db len1
	db $1C
	db len2
	db $1A
	db env, $40, 128
	db len1
	db $1A
	db env, $20, 128
	db len1
	db $1C
	db len3
	db $1A
	db env, $40, 128
	db $1A
	db env, $60, 128
	db $1A
	db exit
LoveTonightPhrase15:
	db env, $20, 128
	db len2
	db $18
	db env, $40, 128
	db len1
	db $18
	db env, $60, 128
	db $18
	db env, $20, 128
	db len2
	db $18
	db env, $40, 128
	db len1
	db $18
	db env, $60, 128
	db $18
	db env, $20, 128
	db len2
	db $17
	db env, $40, 128
	db len1
	db $17
	db env, $60, 128
	db $17
	db env, $20, 128
	db len2
	db $13
	db env, $40, 128
	db len1
	db $13
	db env, $60, 128
	db $13
	db env, $20, 128
	db len2
	db $15
	db env, $40, 128
	db len1
	db $15
	db env, $60, 128
	db $15
	db env, $20, 128
	db len2
	db $15
	db env, $40, 128
	db len1
	db $15
	db env, $60, 128
	db $15
	db env, $20, 128
	db len2
	db $11
	db env, $40, 128
	db len1
	db $11
	db env, $60, 128
	db $11
	db env, $40, 128
	db len1
	db $1F
	db $1D
	db $18
	db $1A
	db env, $20, 128
	db len2
	db $1C
	db env, $40, 128
	db len1
	db $1C
	db env, $60, 128
	db $1C
	db env, $20, 128
	db len2
	db $18
	db env, $40, 128
	db len1
	db $18
	db env, $60, 128
	db $18
	db env, $20, 128
	db len2
	db $11
	db env, $40, 128
	db len1
	db $11
	db env, $60, 128
	db $11
	db env, $20, 128
	db len2
	db $12
	db env, $40, 128
	db len1
	db $12
	db env, $60, 128
	db $12
	db env, $20, 128
	db len2
	db $13
	db env, $40, 128
	db len1
	db $13
	db env, $60, 128
	db $13
	db env, $40, 128
	db len2
	db $13
	db env, $60, 128
	db $13
	db env, $40, 128
	db len2
	db $1F
	db env, $60, 128
	db $1F
	db env, $40, 128
	db len2
	db $1D
	db env, $60, 128
	db $1D
	db exit
LoveTonightPhrase16:
	db env, $40, 128
	db len3
	db $11
	db env, $60, 128
	db len1
	db $11
	db env, $20, 128
	db len2
	db $15
	db len1
	db $17
	db len2
	db $18
	db len3
	db $13
	db env, $40, 128
	db len1
	db $13
	db env, $60, 128
	db $13
	db env, $20, 128
	db len2
	db $13
	db len2
	db $1F
	db env, $40, 128
	db len1
	db $1F
	db env, $60, 128
	db $1F
	db env, $20, 128
	db len2
	db $1C
	db env, $40, 128
	db len1
	db $1C
	db env, $60, 128
	db $1C
	db env, $20, 128
	db len1
	db $18
	db env, $40, 128
	db $18
	db env, $20, 128
	db len3
	db $15
	db env, $40, 128
	db len2
	db $15
	db env, $60, 128
	db len1
	db $15
	db exit
LoveTonightPhrase17:
	db env, $20, 128
	db len2
	db $1D
	db env, $40, 128
	db len1
	db $1D
	db env, $60, 128
	db $1D
	db env, $20, 128
	db len2
	db $1C
	db env, $40, 128
	db len1
	db $1C
	db env, $60, 128
	db $1C
	db env, $20, 128
	db len2
	db $1A
	db env, $40, 128
	db len1
	db $1A
	db env, $60, 128
	db $1A
	db env, $20, 128
	db len2
	db $1C
	db len4
	db $1A
	db env, $40, 128
	db $1A
	db env, $60, 128
	db len10
	db $1A
	db exit
LoveTonightPhrase18:
	db env, $20, 128
	db len2
	db $1D
	db env, $40, 128
	db len1
	db $1D
	db env, $60, 128
	db $1D
	db env, $20, 128
	db len2
	db $1C
	db env, $40, 128
	db len1
	db $1C
	db env, $60, 128
	db $1C
	db env, $20, 128
	db len2
	db $1A
	db env, $40, 128
	db len1
	db $1A
	db env, $60, 128
	db $1A
	db env, $20, 128
	db len2
	db $18
	db len4
	db $18
	db env, $40, 128
	db $18
	db env, $60, 128
	db len10
	db $18
	db exit
LoveTonightPhrase19:
	db env, $81
	db len4
	db $27
	db env, $84
	db len4
	db $01
	db env, $81
	db len4
	db $27
	db env, $84
	db len4
	db $01
	db env, $81
	db len4
	db $27
	db env, $84
	db len4
	db $01
	db env, $81
	db len3
	db $27
	db len1
	db $27
	db env, $84
	db len4
	db $01
	db exit

CirclePhrase01:
	db tempo, 24
	db duty, $C0
	db env, $78
	db len16
	db $16
	db $16
	db $18
	db $1D
	db exit
CirclePhrase02:
	db duty, $C0
	db env, $88
	db len16
	db $16
	db $16
	db $15
	db $16
	db exit
CirclePhrase03:
	db duty, $C0
	db env, $88
	db $6F
	db $13
	db $14
	db $15
	db $11
	db exit
CirclePhrase04:
	db duty, $C0
	db env, $88
	db len16
	db $16
	db env, $87
	db $16
	db env, $88
	db len14
	db $16
	db len10
	db $16
	db env, $87
	db len8
	db $16
	db exit
CirclePhrase05:
	db duty, $C0
	db env, $88
	db len8
	db $11
	db env, $78
	db $11
	db env, $88
	db $11
	db env, $68
	db $11
	db exit
CirclePhrase06:
	db duty, $C0
	db env, $78
	db len16
	db $1D
	db $1F
	db $1F
	db $15
	db exit
CirclePhrase07:
	db duty, $C0
	db env, $88
	db len16
	db $1D
	db $1B
	db $1B
	db $1A
	db exit
CirclePhrase08:
	db duty, $C0
	db env, $88
	db len16
	db $16
	db $18
	db $18
	db $18
	db exit
CirclePhrase09:
	db duty, $C0
	db env, $88
	db len16
	db $1D
	db env, $87
	db $1D
	db env, $88
	db len14
	db $20
	db len10
	db $1F
	db env
	db $87, $67
	db $1F
	db exit
CirclePhrase10:
	db duty, $C0
	db env, $88
	db len3
	db $18
	db len5
	db $16
	db env, $78
	db len8
	db $16
	db env, $88
	db $16
	db env, $68
	db $16
	db exit
CirclePhrase11:
	db tp, -12
	db env, $00, 32
	db len2
	db rest
	db env, $40, 128
	db len1
	db $16
	db $16
	db $16
	db env, $60, 128
	db len2
	db $16
	db env, $40, 128
	db len1
	db $16
	db env, $60, 128
	db $16
	db env, $40, 128
	db $16
	db $16
	db $16
	db $16
	db env, $60, 128
	db len3
	db $16
	db len2
	db rest
	db env, $40, 128
	db len1
	db $16
	db $16
	db $16
	db env, $60, 128
	db len2
	db $16
	db env, $40, 128
	db len1
	db $16
	db env, $60, 128
	db $16
	db env, $40, 128
	db $16
	db $16
	db $16
	db $16
	db env, $60, 128
	db $16
	db env, $40, 128
	db $11
	db env, $60, 128
	db $11
	db len2
	db rest
	db env, $40, 128
	db len1
	db $16
	db $16
	db $16
	db env, $60, 128
	db $16
	db env, $40, 128
	db $16
	db $16
	db env, $60, 128
	db $16
	db env, $40, 128
	db $16
	db $16
	db $16
	db $16
	db env, $60, 128
	db len3
	db $16
	db len2
	db rest
	db env, $40, 128
	db len1
	db $16
	db $16
	db $16
	db env, $60, 128
	db $16
	db env, $40, 128
	db $16
	db $16
	db env, $60, 128
	db $16
	db env, $40, 128
	db $16
	db $16
	db $16
	db env, $20, 128
	db $1A
	db env, $40, 128
	db $1A
	db env, $20, 128
	db $1B
	db env, $40, 128
	db $1B
	db exit
CirclePhrase12:
	db env, $20, 128
	db len2
	db $1D
	db len3
	db $1D
	db env, $40, 128
	db len1
	db $1D
	db env, $20, 128
	db len3
	db $1D
	db env, $40, 128
	db len1
	db $1D
	db env, $20, 128
	db len2
	db $1F
	db len3
	db $1D
	db len1
	db $1B
	db len4
	db $1B
	db env, $40, 128
	db $1B
	db env, $60, 128
	db $1B
	db env, $20, 128
	db len2
	db $18
	db $1A
	db $1B
	db len3
	db $1B
	db env, $40, 128
	db len1
	db $1B
	db env, $20, 128
	db len3
	db $1B
	db env, $40, 128
	db len1
	db $1B
	db env, $20, 128
	db len3
	db $1F
	db env, $40, 128
	db len1
	db $1F
	db env, $20, 128
	db len1
	db $1D
	db len4
	db $1A
	db env, $40, 128
	db $1A
	db env, $60, 128
	db len7
	db $1A
	db env, $20, 128
	db len2
	db $1D
	db exit
CirclePhrase13:
	db env, $20, 128
	db len4
	db $22
	db env, $40, 128
	db $22
	db env, $60, 128
	db $22
	db env, $20, 128
	db len2
	db $1F
	db $21
	db $22
	db len4
	db $24
	db env, $40, 128
	db $24
	db env, $60, 128
	db len2
	db $24
	db env, $20, 128
	db len2
	db $20
	db $22
	db len3
	db $24
	db env, $40, 128
	db len2
	db $24
	db env, $60, 128
	db len1
	db $24
	db env, $20, 128
	db len2
	db $26
	db len3
	db $27
	db $26
	db len2
	db $24
	db len4
	db $24
	db exit
CirclePhrase14:
	db env, $40, 128
	db $24
	db env, $60, 128
	db $24
	db env, $20, 128
	db len2
	db $1A
	db $1B
	db exit
CirclePhrase15:
	db env, $40, 128
	db len2
	db $24
	db env, $20, 128
	db len2
	db $16
	db $1D
	db env, $40, 128
	db len1
	db $1D
	db env, $20, 128
	db len2
	db $1A
	db env, $40, 128
	db len1
	db $1A
	db env, $20, 128
	db len2
	db $1B
	db exit
CirclePhrase16:
	db env, $20, 128
	db len12
	db $1D
	db env, $40, 128
	db len4
	db $1D
	db env, $60, 128
	db $1D
	db env, $20, 128
	db len3
	db $1A
	db env, $40, 128
	db len1
	db $1A
	db env, $20, 128
	db len3
	db $1B
	db env, $40, 128
	db len1
	db $1B
	db env, $20, 128
	db len2
	db $1D
	db len14
	db $1B
	db env, $40, 128
	db len4
	db $1B
	db env, $60, 128
	db $1B
	db env, $20, 128
	db len3
	db $1B
	db env, $40, 128
	db len1
	db $1B
	db env, $20, 128
	db len3
	db $1D
	db env, $40, 128
	db len1
	db $1D
	db env, $20, 128
	db len3
	db $18
	db env, $40, 128
	db len1
	db $18
	db exit
CirclePhrase17:
	db env, $20, 128
	db len3
	db $18
	db len9
	db $16
	db env, $40, 128
	db len8
	db $16
	db env, $60, 128
	db len12
	db $16
	db exit
CirclePhrase18:
	db env, $81
	db len1
	db $27
	db env, $64
	db len2
	db $01
	db env, $81
	db len1
	db $27
	db $27
	db env, $61
	db $01
	db env, $64
	db $01
	db env, $81
	db $27
	db $27
	db env, $64
	db len2
	db $01
	db env, $81
	db len1
	db $27
	db $27
	db env, $61
	db $01
	db env, $64
	db $01
	db env, $61
	db $01
	db exit
	
BePreparedPhrase01:
	db duty, $00
	db env, $73
	db len2
	db $18
	db $15
	db $18
	db $15
	db $17
	db $15
	db $18
	db $15
	db $17
	db $15
	db $18
	db $15
	db $18
	db $15
	db $17
	db $15
	db len2
	db $18
	db $15
	db $18
	db $15
	db $17
	db $15
	db $18
	db $15
	db $17
	db $15
	db $18
	db $15
	db $18
	db $15
	db $17
	db $15
	db exit
BePreparedPhrase02:
	db duty, $00
	db env, $A7
	db len12
	db $10
	db len4
	db $12
	db len8
	db $15
	db len4
	db $18
	db $15
	db len20
	db $17
	db len4
	db $17
	db $18
	db $1A
	db exit
BePreparedPhrase03:
	db duty, $00
	db env, $A7
	db len12
	db $1C
	db len4
	db $10
	db len8
	db $14
	db $18
	db len12
	db $15
	db len4
	db $10
	db $15
	db $10
	db $10
	db $10
	db exit
BePreparedPhrase04:
	db duty, $80
	db env, $A4
	db len6
	db $18
	db env, $48
	db len26
	db $18
	db env, $A4
	db len6
	db $15
	db env, $48
	db $79
	db $15
	db exit
BePreparedPhrase05:
	db duty, $80
	db env, $A4
	db len6
	db $13
	db env, $48
	db len26
	db $13
	db env, $A4
	db len6
	db $15
	db env, $48
	db len26
	db $15
	db exit
BePreparedPhrase06:
	db duty, $80
	db env, $A4
	db len6
	db $13
	db env, $48
	db len26
	db $13
	db env, $A4
	db len6
	db $14
	db env, $48
	db len26
	db $14
	db exit
BePreparedPhrase07:
	db duty, $C0
	db env, $A4
	db len6
	db $18
	db env, $48
	db len10
	db $18
	db env, $A4
	db len6
	db $15
	db env, $48
	db len10
	db $15
	db env, $A4
	db len6
	db $18
	db env, $48
	db len26
	db $18
	db exit
BePreparedPhrase08:
	db duty, $C0
	db env, $A4
	db len6
	db $18
	db env, $48
	db len10
	db $18
	db env, $A4
	db len6
	db $18
	db env, $48
	db len10
	db $18
	db env, $A4
	db len6
	db $1A
	db env, $48
	db len6
	db $1A
	db env, $A4
	db len6
	db $17
	db env, $48
	db len14
	db $17
	db exit
BePreparedPhrase09:
	db duty, $C0
	db env, $A4
	db len6
	db $13
	db env, $48
	db len26
	db $13
	db env, $A4
	db len6
	db $18
	db env, $48
	db len6
	db $18
	db env, $A4
	db len6
	db $17
	db env, $48
	db len14
	db $17
	db exit
BePreparedPhrase10:
	db duty, $C0
	db env, $A4
	db len6
	db $13
	db env, $48
	db len26
	db $13
	db env, $A4
	db len6
	db $13
	db env, $48
	db len26
	db $13
	db exit
BePreparedPhrase11:
	db duty, $C0
	db env, $A4
	db len6
	db $10
	db env, $48
	db len26
	db $10
	db env, $A4
	db len6
	db $11
	db env, $48
	db len26
	db $11
	db exit
BePreparedPhrase12:
	db duty, $C0
	db env, $A4
	db len6
	db $11
	db env, $48
	db len26
	db $11
	db env
	db $A4
	db $65
	db $10
	db env
	db $48
	db $69
	db $10
	db env
	db $A7
	db $67
	db $1C
	db $1C
	db exit
BePreparedPhrase13:
	db duty, $C0
	db env, $A4
	db len6
	db $18
	db env, $48
	db len26
	db $18
	db env, $A4
	db len6
	db $1D
	db env, $48
	db len26
	db $1D
	db exit
BePreparedPhrase14:
	db duty, $00
	db len1
	db rest
	db env, $73
	db len2
	db $18
	db $15
	db $18
	db $15
	db $17
	db $15
	db $18
	db $15
	db $17
	db $15
	db $18
	db $15
	db $18
	db $15
	db $17
	db $15
	db len2
	db $18
	db $15
	db $18
	db $15
	db $17
	db $15
	db $18
	db $15
	db $17
	db $15
	db $18
	db $15
	db $18
	db $15
	db $17
	db len1
	db $15
	db exit
BePreparedPhrase15:
	db duty, $00
	db env, $A7
	db len12
	db $15
	db len4
	db $17
	db len8
	db $18
	db len4
	db $1C
	db $18
	db len20
	db $1A
	db len4
	db $1A
	db $1C
	db $1D
	db exit
BePreparedPhrase16:
	db duty, $00
	db env, $A7
	db len12
	db $14
	db len4
	db $14
	db len8
	db $17
	db $14
	db len12
	db $10
	db len4
	db $17
	db $18
	db $17
	db $15
	db $14
	db exit
BePreparedPhrase17:
	db duty, $80
	db env, $A4
	db len6
	db $1B
	db env, $48
	db len26
	db $1B
	db env, $A4
	db len6
	db $18
	db env, $48
	db len26
	db $18
	db exit
BePreparedPhrase18:
	db duty, $80
	db env, $A4
	db len6
	db $17
	db env, $48
	db len26
	db $17
	db env, $A4
	db len6
	db $18
	db env, $48
	db len26
	db $18
	db exit
BePreparedPhrase19:
	db duty, $80
	db env, $A4
	db len6
	db $17
	db env, $48
	db len26
	db $17
	db env, $A4
	db len6
	db $17
	db env, $48
	db len26
	db $17
	db exit
BePreparedPhrase20:
	db duty, $C0
	db env, $A4
	db len6
	db $1D
	db env, $48
	db len10
	db $1D
	db env, $A4
	db len6
	db $18
	db env, $48
	db len10
	db $18
	db env, $A4
	db len6
	db $1C
	db env, $48
	db len26
	db $1C
	db exit
BePreparedPhrase21:
	db duty, $C0
	db env, $A4
	db len6
	db $1F
	db env, $48
	db len10
	db $1F
	db env, $A4
	db len6
	db $1C
	db env, $48
	db len10
	db $1C
	db env, $A4
	db len6
	db $1D
	db env, $48
	db len6
	db $1D
	db env, $A4
	db len6
	db $1A
	db env, $48
	db len14
	db $1A
	db exit
BePreparedPhrase22:
	db duty, $C0
	db env, $A4
	db len6
	db $17
	db env, $48
	db len26
	db $17
	db env, $A4
	db len6
	db $1D
	db env, $48
	db len6
	db $1D
	db env, $A4
	db len6
	db $1A
	db env, $48
	db len14
	db $1A
	db exit
BePreparedPhrase23:
	db duty, $C0
	db env, $A4
	db len6
	db $18
	db env, $48
	db len26
	db $18
	db env, $A4
	db len6
	db $16
	db env, $48
	db len26
	db $16
	db exit
BePreparedPhrase24:
	db duty, $C0
	db env, $A4
	db len6
	db $15
	db env, $48
	db len26
	db $15
	db env, $A4
	db len6
	db $0E
	db env, $48
	db len26
	db $0E
	db exit
BePreparedPhrase25:
	db duty, $C0
	db env, $A4
	db len6
	db $15
	db env, $48
	db len26
	db $15
	db env, $A4
	db len6
	db $14
	db env, $48
	db len10
	db $14
	db env, $A7
	db len8
	db $20
	db $20
	db exit
BePreparedPhrase26:
	db duty, $C0
	db env, $A4
	db len6
	db $21
	db env, $48
	db len26
	db $21
	db env, $A4
	db len6
	db $24
	db env, $48
	db len26
	db $24
	db exit
BePreparedPhrase27:
	db tp, -12
	db env, $20, 128
	db len4
	db $15
	db env, $40, 128
	db $15
	db env, $60, 128
	db len20
	db $15
	db env, $20, 128
	db len3
	db $13
	db env, $40, 128
	db len1
	db $13
	db env, $20, 128
	db len4
	db $15
	db env, $40, 128
	db $15
	db env, $60, 128
	db len24
	db $15
	db exit
BePreparedPhrase28:
	db env, $20, 128
	db len4
	db $15
	db env, $40, 128
	db $15
	db env, $60, 128
	db len20
	db $15
	db env, $20, 128
	db len3
	db $13
	db env, $40, 128
	db len1
	db $13
	db env, $20, 128
	db len4
	db $15
	db env, $40, 128
	db $15
	db env, $60, 128
	db len20
	db $15
	db env, $20, 128
	db len3
	db $10
	db env, $40, 128
	db len1
	db $10
	db exit
BePreparedPhrase29:
	db env, $20, 128
	db len4
	db $15
	db env, $40, 128
	db len2
	db $15
	db env, $20, 128
	db len4
	db $15
	db env, $40, 128
	db len2
	db $15
	db env, $20, 128
	db len3
	db $17
	db env, $40, 128
	db len1
	db $17
	db env, $20, 128
	db len4
	db $18
	db env, $40, 128
	db len2
	db $18
	db env, $20, 128
	db len4
	db $17
	db env, $40, 128
	db len2
	db $17
	db env, $20, 128
	db len3
	db $15
	db env, $40, 128
	db len1
	db $15
	db env, $20, 128
	db len4
	db $18
	db env, $40, 128
	db len2
	db $18
	db env, $20, 128
	db len4
	db $15
	db env, $40, 128
	db $15
	db env, $60, 128
	db len14
	db $15
	db env, $20, 128
	db len3
	db $18
	db env, $40, 128
	db len1
	db $18
	db exit
BePreparedPhrase30:
	db env, $20, 128
	db len4
	db $17
	db env, $40, 128
	db len2
	db $17
	db env, $20, 128
	db len4
	db $17
	db env, $40, 128
	db len2
	db $17
	db env, $20, 128
	db len3
	db $18
	db env, $40, 128
	db len1
	db $18
	db env, $20, 128
	db len4
	db $1A
	db env, $40, 128
	db len2
	db $1A
	db env, $20, 128
	db len4
	db $18
	db env, $40, 128
	db len2
	db $18
	db env, $20, 128
	db len3
	db $17
	db env, $40, 128
	db len1
	db $17
	db env, $20, 128
	db len4
	db $18
	db env, $40, 128
	db len2
	db $18
	db env, $20, 128
	db len4
	db $15
	db env, $40, 128
	db $15
	db env, $60, 128
	db len14
	db $15
	db env, $20, 128
	db len3
	db $18
	db env, $40, 128
	db len1
	db $18
	db exit
BePreparedPhrase31:
	db env, $20, 128
	db len4
	db $15
	db env, $40, 128
	db len2
	db $15
	db env, $20, 128
	db len4
	db $15
	db env, $40, 128
	db len2
	db $15
	db env, $20, 128
	db len3
	db $17
	db env, $40, 128
	db len1
	db $17
	db env, $20, 128
	db len4
	db $18
	db env, $40, 128
	db len2
	db $18
	db env, $20, 128
	db len4
	db $1A
	db env, $40, 128
	db len2
	db $1A
	db env, $20, 128
	db len3
	db $1C
	db env, $40, 128
	db len1
	db $1C
	db env, $20, 128
	db len3
	db $1D
	db env, $40, 128
	db len1
	db $1D
	db env, $20, 128
	db len4
	db $1A
	db env, $40, 128
	db $1A
	db env, $60, 128
	db len16
	db $1A
	db env, $20, 128
	db len3
	db $1D
	db env, $40, 128
	db len1
	db $1D
	db exit
BePreparedPhrase32:
	db env, $20, 128
	db len4
	db $1C
	db env, $40, 128
	db len2
	db $1C
	db env, $20, 128
	db len4
	db $1A
	db env, $40, 128
	db len2
	db $1A
	db env, $20, 128
	db len3
	db $18
	db env, $40, 128
	db len1
	db $18
	db env, $20, 128
	db len4
	db $17
	db env, $40, 128
	db len2
	db $17
	db env, $20, 128
	db len4
	db $18
	db env, $40, 128
	db len2
	db $18
	db env, $20, 128
	db len3
	db $17
	db env, $40, 128
	db len1
	db $17
	db env, $20, 128
	db len4
	db $15
	db env, $40, 128
	db $15
	db env, $60, 128
	db len24
	db $15
	db exit
BePreparedPhrase33:
	db env, $20, 128
	db len4
	db $1B
	db env, $40, 128
	db len8
	db $1B
	db env, $20, 128
	db len4
	db $1B
	db env, $40, 128
	db $1B
	db env, $20, 128
	db len4
	db $1A
	db env, $40, 128
	db $1A
	db env, $20, 128
	db len3
	db $18
	db env, $40, 128
	db len1
	db $18
	db env, $20, 128
	db len3
	db $1B
	db env, $40, 128
	db len1
	db $1B
	db env, $20, 128
	db len4
	db $15
	db env, $40, 128
	db len20
	db $15
	db env, $20, 128
	db len3
	db $18
	db env, $40, 128
	db len1
	db $18
	db exit
BePreparedPhrase34:
	db env, $20, 128
	db len4
	db $1B
	db env, $40, 128
	db len8
	db $1B
	db env, $20, 128
	db len4
	db $1B
	db env, $40, 128
	db $1B
	db env, $20, 128
	db len4
	db $1A
	db env, $40, 128
	db $1A
	db env, $20, 128
	db len3
	db $18
	db env, $40, 128
	db len1
	db $18
	db env, $20, 128
	db len3
	db $1C
	db env, $40, 128
	db len5
	db $1C
	db env, $60, 128
	db len20
	db $1C
	db env, $20, 128
	db len1
	db $13
	db env, $40, 128
	db $13
	db env, $20, 128
	db len1
	db $15
	db env, $40, 128
	db $15
	db exit
BePreparedPhrase35:
	db env, $20, 128
	db len4
	db $17
	db env, $40, 128
	db len2
	db $17
	db env, $20, 128
	db len4
	db $17
	db env, $40, 128
	db len2
	db $17
	db env, $20, 128
	db len3
	db $18
	db env, $40, 128
	db len1
	db $18
	db env, $20, 128
	db len4
	db $1A
	db env, $40, 128
	db len2
	db $1A
	db env, $20, 128
	db len4
	db $18
	db env, $40, 128
	db len2
	db $18
	db env, $20, 128
	db len3
	db $17
	db env, $40, 128
	db len1
	db $17
	db env, $20, 128
	db len4
	db $18
	db env, $40, 128
	db len28
	db $18
	db exit
BePreparedPhrase36:
	db env, $20, 128
	db len6
	db $13
	db env, $40, 128
	db $13
	db env, $20, 128
	db len1
	db $13
	db env, $40, 128
	db $13
	db env, $20, 128
	db len1
	db $13
	db env, $40, 128
	db $13
	db env, $20, 128
	db len4
	db $13
	db env, $40, 128
	db $13
	db env, $20, 128
	db len4
	db $13
	db env, $40, 128
	db $13
	db env, $20, 128
	db len4
	db $14
	db env, $40, 128
	db len12
	db $14
	db env, $20, 128
	db len4
	db $10
	db env, $40, 128
	db $10
	db env, $20, 128
	db len3
	db $18
	db env, $40, 128
	db len1
	db $18
	db env, $20, 128
	db len3
	db $1A
	db env, $40, 128
	db len1
	db $1A
	db exit
BePreparedPhrase37:
	db env, $20, 128
	db len4
	db $1C
	db env, $40, 128
	db len2
	db $1C
	db env, $20, 128
	db len4
	db $18
	db env, $40, 128
	db len2
	db $18
	db env, $20, 128
	db len3
	db $1A
	db env, $40, 128
	db len1
	db $1A
	db env, $20, 128
	db len4
	db $1C
	db env, $40, 128
	db len2
	db $1C
	db env, $20, 128
	db len4
	db $1A
	db env, $40, 128
	db len2
	db $1A
	db env, $20, 128
	db len3
	db $18
	db env, $40, 128
	db len1
	db $18
	db env, $20, 128
	db len4
	db $1C
	db env, $40, 128
	db len2
	db $1C
	db env, $20, 128
	db len4
	db $1A
	db env, $40, 128
	db $1A
	db env, $60, 128
	db len14
	db $1A
	db env, $20, 128
	db len1
	db $1A
	db env, $40, 128
	db $1A
	db env, $20, 128
	db $1C
	db env, $40, 128
	db $1C
	db exit
BePreparedPhrase38:
	db env, $20, 128
	db len4
	db $1D
	db env, $40, 128
	db len2
	db $1D
	db env, $20, 128
	db len4
	db $1D
	db env, $40, 128
	db len2
	db $1D
	db env, $20, 128
	db len3
	db $1F
	db env, $40, 128
	db len1
	db $1F
	db env, $20, 128
	db len4
	db $21
	db env, $40, 128
	db len2
	db $21
	db env, $20, 128
	db len4
	db $18
	db env, $40, 128
	db len2
	db $18
	db env, $20, 128
	db len3
	db $1A
	db env, $40, 128
	db len1
	db $1A
	db env, $20, 128
	db len4
	db $1C
	db env, $40, 128
	db len24
	db $1C
	db env, $20, 128
	db len3
	db $1C
	db env, $40, 128
	db len1
	db $1C
	db exit
BePreparedPhrase39:
	db env, $20, 128
	db len3
	db $1F
	db env, $40, 128
	db len1
	db $1F
	db env, $20, 128
	db len3
	db $1F
	db env, $40, 128
	db len1
	db $1F
	db env, $20, 128
	db len3
	db $1F
	db env, $40, 128
	db len1
	db $1F
	db env, $20, 128
	db len2
	db $1F
	db env, $40, 128
	db len1
	db $1F
	db env, $60, 128
	db len5
	db $1F
	db env, $20, 128
	db len2
	db $1C
	db env, $40, 128
	db len1
	db $1C
	db env, $60, 128
	db len5
	db $1C
	db env, $20, 128
	db len3
	db $18
	db env, $40, 128
	db len1
	db $18
	db env, $20, 128
	db len3
	db $1D
	db env, $40, 128
	db len1
	db $1D
	db env, $20, 128
	db len3
	db $1D
	db env, $40, 128
	db len1
	db $1D
	db env, $20, 128
	db len3
	db $1D
	db env, $40, 128
	db len1
	db $1D
	db env, $20, 128
	db len4
	db $1A
	db env, $40, 128
	db $1A
	db env, $60, 128
	db len12
	db $1A
	db exit
BePreparedPhrase40:
	db env, $40, 128
	db len16
	db $13
	db env, $60, 128
	db len12
	db $13
	db env, $20, 128
	db len3
	db $1F
	db env, $40, 128
	db len1
	db $1F
	db env, $20, 128
	db len3
	db $1D
	db env, $40, 128
	db len1
	db $1D
	db env, $20, 128
	db len3
	db $1C
	db env, $40, 128
	db len1
	db $1C
	db env, $20, 128
	db len3
	db $1A
	db env, $40, 128
	db len1
	db $1A
	db env, $20, 128
	db len4
	db $17
	db env, $40, 128
	db len8
	db $17
	db env, $20, 128
	db len3
	db $1C
	db env, $40, 128
	db len1
	db $1C
	db env, $20, 128
	db len3
	db $1D
	db env, $40, 128
	db len1
	db $1D
	db exit
BePreparedPhrase41:
	db env, $20, 128
	db len4
	db $1F
	db env, $40, 128
	db len2
	db $1F
	db env, $20, 128
	db len4
	db $1C
	db env, $40, 128
	db len2
	db $1C
	db env, $20, 128
	db len3
	db $1D
	db env, $40, 128
	db len1
	db $1D
	db env, $20, 128
	db len4
	db $1F
	db env, $40, 128
	db len2
	db $1F
	db env, $20, 128
	db len4
	db $1C
	db env, $40, 128
	db len2
	db $1C
	db env, $20, 128
	db len3
	db $1D
	db env, $40, 128
	db len1
	db $1D
	db env, $20, 128
	db len4
	db $1F
	db env, $40, 128
	db len2
	db $1F
	db env, $20, 128
	db len4
	db $1C
	db env, $40, 128
	db len2
	db $1C
	db env, $20, 128
	db len3
	db $1D
	db env, $40, 128
	db len1
	db $1D
	db env, $20, 128
	db len4
	db $1F
	db env, $40, 128
	db len2
	db $1F
	db env, $20, 128
	db len4
	db $1C
	db env, $40, 128
	db len2
	db $1C
	db env, $20, 128
	db len3
	db $1D
	db env, $40, 128
	db len1
	db $1D
	db exit
BePreparedPhrase42:
	db env, $20, 128
	db len4
	db $1F
	db env, $40, 128
	db len2
	db $1F
	db env, $20, 128
	db len4
	db $1F
	db env, $40, 128
	db len2
	db $1F
	db env, $20, 128
	db len3
	db $1F
	db env, $40, 128
	db len1
	db $1F
	db env, $20, 128
	db len4
	db $1F
	db env, $40, 128
	db len2
	db $1F
	db env, $20, 128
	db len4
	db $1D
	db env, $40, 128
	db len2
	db $1D
	db env, $20, 128
	db len3
	db $1C
	db env, $40, 128
	db len1
	db $1C
	db env, $20, 128
	db len8
	db $1D
	db env, $40, 128
	db $1D
	db env, $60, 128
	db len12
	db $1D
	db env, $20, 128
	db len1
	db $1D
	db env, $40, 128
	db $1D
	db env, $20, 128
	db $1D
	db env, $40, 128
	db $1D
	db exit
BePreparedPhrase43:
	db env, $20, 128
	db len4
	db $1D
	db env, $40, 128
	db len2
	db $1D
	db env, $20, 128
	db len4
	db $1D
	db env, $40, 128
	db len2
	db $1D
	db env, $20, 128
	db len3
	db $1D
	db env, $40, 128
	db len1
	db $1D
	db env, $20, 128
	db len4
	db $1D
	db env, $40, 128
	db $1D
	db env, $20, 128
	db $1F
	db env, $40, 128
	db $1F
	db env, $20, 128
	db len8
	db $1C
	db env, $40, 128
	db $1C
	db env, $60, 128
	db $1C
	db env, $20, 128
	db len4
	db $10
	db env, $40, 128
	db $10
	db exit
BePreparedPhrase44:
	db env, $20, 128
	db len4
	db $15
	db env, $40, 128
	db $15
	db env, $60, 128
	db $15
	db env, $20, 128
	db $18
	db env, $40, 128
	db $18
	db env, $20, 128
	db len3
	db $15
	db env, $40, 128
	db len1
	db $15
	db env, $20, 128
	db len4
	db $1D
	db env, $40, 128
	db $1D
	db env, $60, 128
	db $1D
	db env, $20, 128
	db len3
	db $1D
	db env, $40, 128
	db len1
	db $1D
	db env, $20, 128
	db len3
	db $1D
	db env, $40, 128
	db len1
	db $1D
	db env, $20, 128
	db len3
	db $1D
	db env, $40, 128
	db len1
	db $1D
	db env, $20, 128
	db len3
	db $1C
	db env, $40, 128
	db len1
	db $1C
	db env, $20, 128
	db len3
	db $18
	db env, $40, 128
	db len1
	db $18
	db env, $20, 128
	db len3
	db $1A
	db env, $40, 128
	db len1
	db $1A
	db env, $20, 128
	db len3
	db $17
	db env, $40, 128
	db len1
	db $17
	db exit
BePreparedPhrase45:
	db env, $A7
	db len28
	db $01
	db env, $A1
	db len2
	db $01
	db $01
	db env, $A7
	db len32
	db $01
	db exit
BePreparedPhrase46:
	db env, $81
	db len2
	db $07
	db env, $A7
	db len4
	db $01
	db env, $81
	db len2
	db $07
	db $07
	db env, $A1
	db $01
	db env, $A7
	db $01
	db env, $A1
	db $01
	db exit
BePreparedPhrase47:
	db env, $81
	db len12
	db $07
	db env, $A7
	db len2
	db $01
	db env, $81
	db $07
	db $07
	db env, $A7
	db len4
	db $01
	db env, $81
	db len2
	db $07
	db $07
	db env, $A1
	db len6
	db $01
	db env, $81
	db len2
	db $07
	db env, $A7
	db len26
	db $01
	db len2
	db $01
	db env, $A1
	db $01
	db exit

HooHahPhrase01:
	db duty, $80
	db env, $62
	db len2
	db $06
	db rest
	db rest
	db $0B
	db rest
	db $0B
	db rest
	db rest
	db $06
	db rest
	db $06
	db rest
	db exit
HooHahPhrase02:
	db duty, $80
	db env, $62
	db len2
	db $06
	db rest
	db rest
	db env, $A3
	db len1
	db duty, $00
	db $17
	db duty, $40
	db $17
	db len4
	db duty, $80
	db $17
	db env, $62
	db len2
	db rest
	db rest
	db $06
	db rest
	db $06
	db rest
	db $06
	db rest
	db rest
	db env, $A3
	db len1
	db duty, $00
	db $19
	db duty, $40
	db $19
	db len4
	db duty, $80
	db $19
	db len1
	db duty, $00
	db $19
	db duty, $40
	db $19
	db len4
	db duty, $80
	db $19
	db env, $62
	db len2
	db rest
	db $06
	db rest
	db exit
HooHahPhrase03:
	db duty, $80
	db env, $62
	db len2
	db $06
	db env, $31
	db $12
	db $12
	db env, $62
	db $0B
	db env, $31
	db $17
	db env, $62
	db $0B
	db env, $31
	db $17
	db $17
	db env, $62
	db $06
	db env, $31
	db $12
	db env, $62
	db $06
	db env, $31
	db $12
	db exit
HooHahPhrase04:
	db duty, $80
	db env, $62
	db len2
	db $06
	db env, $31
	db $12
	db $12
	db env, $A3
	db len1
	db duty, $00
	db $1C
	db duty, $40
	db $1C
	db len4
	db duty, $80
	db $1C
	db env, $31
	db len2
	db $17
	db $17
	db env, $62
	db $06
	db env, $31
	db $12
	db env, $62
	db $06
	db env, $31
	db $12
	db env, $62
	db $06
	db env, $31
	db $12
	db $12
	db env, $A3
	db len1
	db duty, $00
	db $1E
	db duty, $40
	db $1E
	db len4
	db duty, $80
	db $1E
	db len1
	db duty, $00
	db $1E
	db duty, $40
	db $1E
	db len4
	db duty, $80
	db $1E
	db env, $31
	db len2
	db $12
	db env, $62
	db $06
	db env, $31
	db $12
	db exit
HooHahPhrase05:
	db len4
	db rest
	db env, $60, 128
	db len1
	db $19
	db env, $40, 128
	db $17
	db env, $20, 128
	db $10
	db env, $40, 128
	db $10
	db env, $60, 128
	db len2
	db $10
	db env, $00, 128
	db len18
	db $10
	db env, $60, 128
	db len1
	db $0C
	db env, $40, 128
	db $10
	db env, $20, 128
	db $12
	db env, $40, 128
	db $12
	db env, $60, 128
	db len2
	db $12
	db env, $00, 128
	db len1
	db $12
	db env, $40, 128
	db $10
	db env, $20, 128
	db $12
	db env, $40, 128
	db $12
	db env, $60, 128
	db len2
	db $12
	db env, $00, 128
	db len8
	db $12
	db exit
HooHahPhrase06:
	db env, $62
	db len2
	db $07
	db env, $C1
	db $01
	db env, $81
	db $27
	db env, $62
	db $07
	db env, $C1
	db $01
	db env, $62
	db $07
	db env, $C1
	db $01
	db env, $81
	db $27
	db env, $62
	db $07
	db env, $C1
	db $01
	db env, $62
	db $07
	db env, $C1
	db $01
	db exit

ThisLandPhrase01:
	db tempo, 30
	db duty, $C0
	db env, $A7
	db len6
	db $18
	db env, $58
	db len6
	db $18
	db env, $A7
	db len4
	db $1A
	db len6
	db $1C
	db env, $58
	db len6
	db $1C
	db env, $A7
	db len4
	db $1A
	db len6
	db $18
	db env, $58
	db len10
	db $18
	db env, $A7
	db len6
	db $15
	db env, $58
	db len10
	db $15
	db exit
ThisLandPhrase02:
	db duty, $C0
	db env, $A7
	db len6
	db $18
	db env, $58
	db len10
	db $18
	db env, $A7
	db len6
	db $15
	db env, $58
	db len10
	db $15
	db env, $A7
	db len6
	db $18
	db env, $58
	db len10
	db $18
	db env, $A7
	db len8
	db $15
	db $17
	db exit
ThisLandPhrase03:
	db duty, $80
	db env, $A7
	db len6
	db $1A
	db env, $58
	db len10
	db $1A
	db env, $A7
	db len6
	db $17
	db env, $58
	db len10
	db $17
	db env, $A7
	db len6
	db $1A
	db env, $58
	db len10
	db $1A
	db env, $A7
	db len6
	db $17
	db env, $58
	db len10
	db $17
	db exit
ThisLandPhrase04:
	db duty, $C0
	db env, $A7
	db len6
	db $13
	db env, $58
	db len10
	db $13
	db env, $A7
	db len6
	db $13
	db env, $58
	db len10
	db $13
	db env, $A7
	db len6
	db $13
	db env, $58
	db len10
	db $13
	db env, $A7
	db len6
	db $0E
	db env, $58
	db len10
	db $0E
	db exit
ThisLandPhrase05:
	db duty, $C0
	db env, $A7
	db len6
	db $13
	db env, $58
	db len10
	db $13
	db env, $A7
	db len8
	db $18
	db $18
	db env, $A7
	db len6
	db $17
	db env, $58
	db len10
	db $17
	db env, $A7
	db len8
	db $0F
	db $17
	db exit
ThisLandPhrase06:
	db duty, $C0
	db env, $A7
	db len6
	db $10
	db env, $58
	db len10
	db $10
	db env, $A7
	db len6
	db $10
	db env, $58
	db len10
	db $10
	db env, $A7
	db len8
	db $18
	db $18
	db len6
	db $17
	db env, $58
	db len10
	db $17
	db exit
ThisLandPhrase07:
	db duty, $C0
	db env, $A7
	db len6
	db $10
	db env, $58
	db len10
	db $10
	db env, $A7
	db len6
	db $10
	db env, $58
	db len10
	db $10
	db env, $A7
	db len8
	db $0F
	db $17
	db len6
	db $17
	db env, $58
	db len10
	db $17
	db exit
ThisLandPhrase08:
	db duty, $C0
	db env, $A7
	db len6
	db $13
	db env, $58
	db len10
	db $13
	db env, $A7
	db len6
	db $17
	db $15
	db env, $58
	db len4
	db $15
	db env, $A7
	db len6
	db $0E
	db env, $58
	db len26
	db $0E
	db exit
ThisLandPhrase09:
	db duty, $C0
	db env, $A7
	db len6
	db $1C
	db env, $58
	db len4
	db $18
	db env, $73
	db len2
	db $13
	db env, $A7
	db $1D
	db env, $73
	db $1A
	db env, $A7
	db len6
	db $1F
	db env, $58
	db len6
	db $1F
	db env, $A7
	db len4
	db $1D
	db len6
	db $1C
	db env, $58
	db len10
	db $1C
	db env, $A7
	db len6
	db $18
	db env, $58
	db len10
	db $18
	db exit
ThisLandPhrase10:
	db duty, $C0
	db env, $A7
	db len6
	db $1C
	db env, $58
	db len10
	db $1C
	db env, $A7
	db len6
	db $18
	db env, $58
	db len10
	db $18
	db env, $A7
	db len6
	db $1D
	db env, $58
	db len10
	db $1D
	db env, $A7
	db len8
	db $1A
	db $1A
	db exit
ThisLandPhrase11:
	db duty, $80
	db env, $A7
	db len6
	db $1E
	db env, $58
	db len10
	db $1E
	db env, $A7
	db len6
	db $1A
	db env, $58
	db len10
	db $1A
	db env, $A7
	db len6
	db $1E
	db env, $58
	db len10
	db $1E
	db env, $A7
	db len6
	db $1A
	db env, $58
	db len10
	db $1A
	db exit
ThisLandPhrase12:
	db duty, $C0
	db env, $A7
	db len6
	db $17
	db env, $58
	db len10
	db $17
	db env, $A7
	db len6
	db $1C
	db env, $58
	db len10
	db $1C
	db env, $A7
	db len6
	db $17
	db env, $58
	db len10
	db $17
	db env, $A7
	db len6
	db $12
	db env, $58
	db len10
	db $12
	db exit
ThisLandPhrase13:
	db duty, $C0
	db env, $A7
	db len6
	db $17
	db env, $58
	db len10
	db $17
	db env, $A7
	db len8
	db $1C
	db $1A
	db len6
	db $1A
	db env, $58
	db len10
	db $1A
	db env, $A7
	db len8
	db $17
	db $12
	db exit
ThisLandPhrase14:
	db duty, $C0
	db env, $A7
	db len6
	db $13
	db env, $58
	db len10
	db $13
	db env, $A7
	db len6
	db $13
	db env, $58
	db len10
	db $13
	db env, $A7
	db len8
	db $1C
	db $1A
	db len6
	db $1A
	db env, $58
	db len10
	db $1A
	db exit
ThisLandPhrase15:
	db duty, $C0
	db env, $A7
	db len6
	db $13
	db env, $58
	db len10
	db $13
	db env, $A7
	db len6
	db $13
	db env, $58
	db len10
	db $13
	db env, $A7
	db len8
	db $17
	db $1B
	db len6
	db $1C
	db env, $58
	db len10
	db $1C
	db exit
ThisLandPhrase16:
	db duty, $C0
	db env, $A7
	db len6
	db $17
	db env, $58
	db len10
	db $17
	db env, $A7
	db len6
	db $13
	db $13
	db env, $58
	db len4
	db $13
	db env, $A7
	db len6
	db $13
	db env, $58
	db len26
	db $13
	db exit
ThisLandPhrase17:
	db tp, -12
	db env, $60, 255
	db len16
	db $18
	db len14
	db $13
	db env, $20, 128
	db len1
	db $1F
	db env, $40, 128
	db $1F
	db env, $20, 128
	db len3
	db $24
	db env, $40, 128
	db len1
	db $24
	db env, $20, 128
	db len3
	db $23
	db env, $40, 128
	db len1
	db $23
	db env, $20, 128
	db len4
	db $21
	db env, $40, 128
	db len2
	db $21
	db env, $20, 128
	db len1
	db $1F
	db env, $40, 128
	db $1F
	db env, $20, 128
	db len3
	db $21
	db env, $40, 128
	db len1
	db $21
	db env, $20, 128
	db len3
	db $1F
	db env, $40, 128
	db len1
	db $1F
	db env, $20, 128
	db len3
	db $21
	db env, $40, 128
	db len1
	db $21
	db env, $20, 128
	db len3
	db $24
	db env, $40, 128
	db len1
	db $24
	db exit
ThisLandPhrase18:
	db env, $20, 128
	db len3
	db $24
	db env, $40, 128
	db len1
	db $24
	db env, $20, 128
	db len3
	db $23
	db env, $40, 128
	db len1
	db $23
	db env, $20, 128
	db len4
	db $24
	db env, $40, 128
	db len2
	db $24
	db env, $20, 128
	db len1
	db $2B
	db env, $40, 128
	db $2B
	db env, $20, 128
	db len3
	db $2B
	db env, $40, 128
	db len1
	db $2B
	db env, $20, 128
	db len3
	db $29
	db env, $40, 128
	db len1
	db $29
	db env, $20, 128
	db len3
	db $28
	db env, $40, 128
	db len1
	db $28
	db env, $20, 128
	db len3
	db $26
	db env, $40, 128
	db len1
	db $26
	db env, $20, 128
	db len3
	db $29
	db env, $40, 128
	db len1
	db $29
	db env, $20, 128
	db len3
	db $28
	db env, $40, 128
	db len1
	db $28
	db env, $20, 128
	db len4
	db $24
	db env, $40, 128
	db len2
	db $24
	db env, $20, 128
	db len1
	db $28
	db env, $40, 128
	db $28
	db env, $20, 128
	db len4
	db $26
	db env, $40, 128
	db $26
	db env, $60, 128
	db len8
	db $28
	db exit
ThisLandPhrase19:
	db env, $20, 128
	db len3
	db $26
	db env, $40, 128
	db len1
	db $26
	db env, $20, 128
	db len3
	db $28
	db env, $40, 128
	db len1
	db $28
	db env, $20, 128
	db len4
	db $26
	db env, $40, 128
	db len2
	db $26
	db env, $20, 128
	db len1
	db $21
	db env, $40, 128
	db $21
	db env, $20, 128
	db len3
	db $23
	db env, $40, 128
	db len1
	db $23
	db env, $20, 128
	db len3
	db $21
	db env, $40, 128
	db len1
	db $21
	db env, $20, 128
	db len3
	db $23
	db env, $40, 128
	db len1
	db $23
	db env, $20, 128
	db len3
	db $26
	db env, $40, 128
	db len1
	db $26
	db env, $20, 128
	db len3
	db $26
	db env, $40, 128
	db len1
	db $26
	db env, $20, 128
	db len3
	db $28
	db env, $40, 128
	db len1
	db $28
	db env, $20, 128
	db len3
	db $26
	db env, $40, 128
	db len1
	db $26
	db env, $20, 128
	db len3
	db $21
	db env, $40, 128
	db len1
	db $21
	db env, $20, 128
	db len4
	db $23
	db env, $40, 128
	db len3
	db $23
	db env, $60, 128
	db len1
	db $23
	db env, $20, 128
	db len4
	db $21
	db env, $40, 128
	db len2
	db $21
	db env, $20, 128
	db len1
	db $15
	db env, $40, 128
	db $15
	db exit
ThisLandPhrase20:
	db env, $20, 128
	db len3
	db $17
	db env, $40, 128
	db len1
	db $17
	db env, $20, 128
	db len4
	db $1C
	db env, $40, 128
	db len2
	db $1C
	db env, $20, 128
	db len1
	db $13
	db env, $40, 128
	db $13
	db env, $20, 128
	db len1
	db $15
	db env, $40, 128
	db $15
	db env, $20, 128
	db len1
	db $17
	db env, $40, 128
	db $17
	db env, $20, 128
	db len3
	db $18
	db env, $40, 128
	db len1
	db $18
	db env, $20, 128
	db len3
	db $17
	db env, $40, 128
	db len1
	db $17
	db env, $20, 128
	db len3
	db $13
	db env, $40, 128
	db len1
	db $13
	db env, $20, 128
	db len3
	db $15
	db env, $40, 128
	db len1
	db $15
	db env, $20, 128
	db len3
	db $17
	db env, $40, 128
	db len1
	db $17
	db env, $20, 128
	db len4
	db $1C
	db env, $40, 128
	db len2
	db $1C
	db env, $20, 128
	db len1
	db $13
	db env, $40, 128
	db $13
	db env, $20, 128
	db len1
	db $15
	db env, $40, 128
	db $15
	db env, $20, 128
	db len1
	db $17
	db env, $40, 128
	db $17
	db env, $20, 128
	db len4
	db $12
	db env, $40, 128
	db len3
	db $12
	db env, $60, 128
	db len1
	db $12
	db env, $20, 128
	db len4
	db $0E
	db env, $40, 128
	db len3
	db $0E
	db env, $60, 128
	db len1
	db $0E
	db exit
ThisLandPhrase21:
	db env, $20, 128
	db len4
	db $23
	db env, $40, 128
	db $23
	db env, $60, 128
	db len2
	db $23
	db env, $20, 128
	db len1
	db $1F
	db env, $40, 128
	db $1F
	db env, $20, 128
	db $1E
	db env, $40, 128
	db $1E
	db env, $20, 128
	db $1F
	db env, $40, 128
	db $1F
	db env, $20, 128
	db len3
	db $1C
	db env, $40, 128
	db len1
	db $1C
	db env, $20, 128
	db len3
	db $1F
	db env, $40, 128
	db len1
	db $1F
	db env, $20, 128
	db len4
	db $24
	db env, $40, 128
	db len2
	db $24
	db env, $20, 128
	db len1
	db $1F
	db env, $40, 128
	db $1F
	db env, $20, 128
	db len4
	db $1A
	db env, $40, 128
	db len2
	db $1A
	db env, $20, 128
	db len1
	db $1F
	db env, $40, 128
	db $1F
	db env, $20, 128
	db len4
	db $1A
	db env, $40, 128
	db len3
	db $1A
	db env, $60, 128
	db len1
	db $1A
	db env, $20, 128
	db len4
	db $1B
	db env, $40, 128
	db len2
	db $1B
	db env, $20, 128
	db len4
	db $1C
	db env, $40, 128
	db len2
	db $1C
	db env, $20, 128
	db len3
	db $1E
	db env, $40, 128
	db len1
	db $1E
	db exit
ThisLandPhrase22:
	db env, $20, 128
	db len4
	db $1F
	db env, $40, 128
	db len2
	db $1F
	db env, $20, 128
	db len4
	db $1E
	db env, $40, 128
	db len2
	db $1E
	db env, $20, 128
	db len3
	db $21
	db env, $40, 128
	db len1
	db $21
	db env, $20, 128
	db len4
	db $1F
	db env, $40, 128
	db len2
	db $1F
	db env, $20, 128
	db len4
	db $1C
	db env, $40, 128
	db len2
	db $1C
	db env, $20, 128
	db len1
	db $1F
	db env, $40, 128
	db $1F
	db env, $20, 128
	db $23
	db env, $40, 128
	db $23
	db env, $20, 128
	db len4
	db $28
	db env, $40, 128
	db len2
	db $28
	db env, $20, 128
	db len1
	db $26
	db env, $40, 128
	db $26
	db env, $20, 128
	db len3
	db $24
	db env, $40, 128
	db len1
	db $24
	db env, $20, 128
	db len3
	db $26
	db env, $40, 128
	db len1
	db $26
	db env, $20, 128
	db len4
	db $23
	db env, $40, 128
	db len3
	db $23
	db env, $40, 128
	db len1
	db $23
	db env, $20, 128
	db len4
	db $1C
	db env, $40, 128
	db len2
	db $1C
	db env, $20, 128
	db len1
	db $1E
	db env, $40, 128
	db $1E
	db exit
ThisLandPhrase23:
	db env, $20, 128
	db len4
	db $1F
	db env, $40, 128
	db len2
	db $1F
	db env, $20, 128
	db len4
	db $1E
	db env, $40, 128
	db len2
	db $1E
	db env, $20, 128
	db len3
	db $21
	db env, $40, 128
	db len1
	db $21
	db env, $20, 128
	db len4
	db $1F
	db env, $40, 128
	db len2
	db $1F
	db env, $20, 128
	db len4
	db $1C
	db env, $40, 128
	db len3
	db $1C
	db env, $60, 128
	db len1
	db $1C
	db env, $20, 128
	db len1
	db $1C
	db env, $40, 128
	db $1C
	db env, $20, 128
	db len4
	db $1B
	db env, $40, 128
	db len2
	db $1B
	db env, $20, 128
	db len4
	db $1C
	db env, $40, 128
	db len2
	db $1C
	db env, $20, 128
	db len3
	db $1E
	db env, $40, 128
	db len1
	db $1E
	db env, $20, 128
	db len4
	db $1C
	db env, $40, 128
	db $1C
	db env, $60, 128
	db len2
	db $1C
	db env, $20, 128
	db len1
	db $28
	db env, $40, 128
	db $28
	db env, $20, 128
	db $26
	db env, $40, 128
	db $26
	db env, $20, 128
	db $24
	db env, $40, 128
	db $24
	db exit
ThisLandPhrase24:
	db env, $20, 128
	db len4
	db $23
	db env, $40, 128
	db len2
	db $23
	db env, $20, 128
	db len1
	db $23
	db env, $40, 128
	db $23
	db env, $20, 128
	db $21
	db env, $40, 128
	db $21
	db env, $20, 128
	db $23
	db env, $40, 128
	db $23
	db env, $20, 128
	db len3
	db $24
	db env, $40, 128
	db len1
	db $24
	db env, $20, 128
	db len3
	db $23
	db env, $40, 128
	db len1
	db $23
	db env, $20, 128
	db len4
	db $21
	db env, $40, 128
	db $21
	db env, $20, 128
	db len3
	db $21
	db env, $40, 128
	db len1
	db $21
	db env, $20, 128
	db len4
	db $1F
	db env, $40, 128
	db $1F
	db env, $60, 128
	db len8
	db $1F
	db env, $20, 128
	db len1
	db $26
	db $23
	db env, $40, 128
	db $23
	db env, $20, 128
	db $23
	db env, $40, 128
	db $23
	db env, $20, 128
	db $21
	db $26
	db env, $40, 128
	db $26
	db env, $20, 128
	db len4
	db $23
	db env, $40, 128
	db len3
	db $23
	db env, $60, 128
	db len1
	db $23
	db exit
ThisLandPhrase25:
	db env, $81
	db len1
	db $07
	db env, $41
	db $07
	db env, $21
	db $07
	db env, $81
	db $07
	db env, $73
	db $05
	db env, $71
	db $01
	db env, $81
	db $07
	db env, $41
	db $07
	db env, $21
	db $07
	db env, $81
	db $07
	db env, $41
	db $07
	db env, $81
	db $07
	db env, $73
	db $05
	db env, $71
	db $01
	db env, $81
	db $07
	db env, $71
	db $01
	db exit

JinglePhrase01:
	db tempo, 38
	db duty, $C0
	db env, $A3
	db len2
	db $18
	db $1A
	db $1C
	db $1D
	db $1F
	db $21
	db $23
	db env, $A8
	db len10
	db $24
	db env, $A4
	db len1
	db $28
	db $24
	db $1F
	db $1C
	db len12
	db $18
	db end
	db exit
JinglePhrase02:
	db tempo, 38
	db duty, $C0
	db len1
	db rest
	db env, $A3
	db len2
	db $1C
	db $1D
	db $1F
	db $21
	db $23
	db $24
	db $26
	db env, $A8
	db len9
	db $28
	db env, $A4
	db len1
	db $24
	db $21
	db $23
	db $1F
	db $6B
	db $1C
	db exit
JinglePhrase03:
	db tp, -12
	db env, $20, 128
	db len1
	db $28
	db $24
	db $26
	db $23
	db $24
	db $21
	db $23
	db $1F
	db $21
	db $1D
	db $1F
	db $1C
	db $1D
	db $1A
	db $1C
	db env, $40, 128
	db $17
	db len6
	db $18
	db env, $60, 128
	db len2
	db $18
	db len1
	db $18
	db env, $20, 128
	db $1C
	db $1F
	db env, $60, 128
	db $21
	db env, $20, 128
	db $24
	db env, $40, 128
	db $24
	db env, $60, 128
	db len2
	db $24
	db env, $00, 128
	db len8
	db $24
	db exit
JinglePhrase04:
	db env, $81
	db len1
	db $27
	db env, $61
	db $01
	db $01
	db $01
	db env, $64
	db $01
	db env, $61
	db $01
	db env, $62
	db $07
	db env, $61
	db $01
	db env, $81
	db $27
	db env, $61
	db $01
	db $01
	db env, $64
	db $01
	db env, $62
	db $07
	db env, $61
	db $01
	db env, $64
	db $01
	db env, $61
	db $01
	db env, $81
	db len1
	db $27
	db env, $61
	db $01
	db $01
	db $01
	db env, $64
	db $01
	db env, $61
	db $01
	db env, $62
	db $07
	db env, $61
	db $01
	db env, $81
	db $27
	db env, $61
	db $01
	db $01
	db env, $64
	db $01
	db env, $62
	db $07
	db env, $61
	db $01
	db env, $64
	db $01
	db env, $61
	db $01
	db len8
	db rest
	db exit

ToDieForPhrase01:
	db len24
	db rest
	db exit
ToDieForPhrase02:
	db duty, $C0
	db env, $A7
	db len2
	db $1A
	db env, $A2
	db $18
	db env, $A3
	db $1A
	db env, $A7
	db len6
	db $13
	db env, $A7
	db len2
	db $1A
	db env, $A2
	db $18
	db env, $A3
	db $1A
	db env, $A7
	db len6
	db $13
	db exit
ToDieForPhrase03:
	db duty, $C0
	db env, $A7
	db len2
	db $1A
	db env, $A2
	db $18
	db env, $A3
	db $1A
	db env, $A7
	db len2
	db $18
	db $1A
	db $18
	db env, $A7
	db len2
	db $1A
	db env, $A2
	db $18
	db env, $A3
	db $11
	db env, $A7
	db len6
	db $13
	db exit
ToDieForPhrase04:
	db duty, $C0
	db env, $A4
	db len3
	db $1A
	db $1A
	db $1A
	db $1A
	db $16
	db env, $57
	db len9
	db $16
	db exit
ToDieForPhrase05:
	db duty, $C0
	db env, $A7
	db len3
	db $1A
	db len5
	db $1A
	db len1
	db $16
	db len3
	db $1A
	db len6
	db $1A
	db exit
ToDieForPhrase06:
	db duty, $C0
	db env, $A7
	db len3
	db $16
	db len5
	db $16
	db len1
	db $11
	db len3
	db $16
	db len6
	db $16
	db exit
ToDieForPhrase07:
	db duty, $C0
	db env, $A7
	db len3
	db $16
	db len6
	db $11
	db len3
	db $11
	db len4
	db $11
	db len1
	db $16
	db $16
	db exit
ToDieForPhrase08:
	db duty, $C0
	db env, $A7
	db len3
	db $16
	db len6
	db $11
	db len7
	db $16
	db len1
	db $16
	db $16
	db exit
ToDieForPhrase09:
	db duty, $C0
	db env, $A7
	db len3
	db $16
	db len6
	db $11
	db len3
	db $11
	db $11
	db $11
	db exit
ToDieForPhrase10:
	db duty, $C0
	db env, $A7
	db len6
	db $15
	db len2
	db $1E
	db len4
	db $1E
	db len6
	db $15
	db $19
	db exit
ToDieForPhrase11:
	db duty, $C0
	db env, $A7
	db len6
	db $15
	db len2
	db $1E
	db len4
	db $1E
	db env, $67
	db len1
	db $25
	db $21
	db $1E
	db $21
	db env, $A7
	db $1E
	db $19
	db $1E
	db $19
	db $15
	db $19
	db $1E
	db $21
	db exit
ToDieForPhrase12:
	db duty, $C0
	db env, $A7
	db len3
	db $1A
	db env, $A2
	db $1A
	db $1A
	db env, $A7
	db $1A
	db env, $A2
	db $1A
	db $1A
	db exit
ToDieForPhrase13:
	db len24
	db rest
	db exit
ToDieForPhrase14:
	db duty, $C0
	db env, $A7
	db len2
	db $1F
	db env, $A2
	db $1D
	db env, $A3
	db $1F
	db env, $A7
	db len6
	db $1A
	db env, $A7
	db len2
	db $1F
	db env, $A2
	db $1D
	db env, $A3
	db $1F
	db env, $A7
	db len6
	db $1A
	db exit
ToDieForPhrase15:
	db duty, $C0
	db env, $A7
	db len2
	db $1F
	db env, $A2
	db $1D
	db env, $A3
	db $1F
	db env, $A7
	db len2
	db $20
	db $1F
	db $1D
	db env, $A7
	db len2
	db $1F
	db env, $A2
	db $1D
	db env, $A3
	db $18
	db env, $A7
	db len6
	db $1A
	db exit
ToDieForPhrase16:
	db duty, $C0
	db env, $A4
	db len3
	db $1F
	db $1F
	db $1F
	db $1F
	db $1A
	db env, $57
	db len9
	db $1A
	db exit
ToDieForPhrase17:
	db duty, $C0
	db env, $A7
	db len3
	db $22
	db len5
	db $21
	db len1
	db $1A
	db len3
	db $22
	db len6
	db $21
	db exit
ToDieForPhrase18:
	db duty, $C0
	db env, $A7
	db len3
	db $19
	db len5
	db $18
	db len1
	db $16
	db len3
	db $19
	db len6
	db $18
	db exit
ToDieForPhrase19:
	db duty, $C0
	db env, $A7
	db len3
	db $1B
	db len6
	db $16
	db len3
	db $16
	db len4
	db $15
	db len1
	db $19
	db $1B
	db exit
ToDieForPhrase20:
	db duty, $C0
	db env, $A7
	db len3
	db $1D
	db len6
	db $16
	db len7
	db $1B
	db len1
	db $19
	db $1B
	db exit
ToDieForPhrase21:
	db duty, $C0
	db env, $A7
	db len3
	db $1D
	db len6
	db $16
	db len3
	db $18
	db $16
	db $15
	db exit
ToDieForPhrase22:
	db duty, $C0
	db env, $A7
	db len6
	db $12
	db len2
	db $21
	db len4
	db $21
	db len6
	db $12
	db $2C
	db exit
ToDieForPhrase23:
	db duty, $C0
	db env, $A7
	db len6
	db $12
	db len2
	db $21
	db len4
	db $21
	db env, $67
	db len1
	db $1C
	db $19
	db $15
	db $19
	db env, $A7
	db $15
	db $12
	db $0D
	db $11
	db $14
	db $17
	db $19
	db $17
	db exit
ToDieForPhrase24:
	db duty, $C0
	db env, $A7
	db len3
	db $1F
	db env, $A2
	db $1F
	db $1F
	db env, $A7
	db $1F
	db env, $A2
	db $1F
	db $1F
	db exit
ToDieForPhrase25:
	db env, $40
	db $0C
	db len1
	db $11
	db $13
	db $13
	db $13
	db $13
	db $13
	db $11
	db $13
	db $13
	db $13
	db $13
	db $13
	db $11
	db $13
	db $13
	db $13
	db $13
	db $13
	db $1B
	db $1A
	db $18
	db $1A
	db $18
	db $16
	db exit
ToDieForPhrase26:
	db env, $40, 12
	db len1
	db $11
	db $13
	db $13
	db $13
	db $13
	db $13
	db $11
	db $13
	db $13
	db $13
	db $13
	db $13
	db $18
	db $1A
	db $1A
	db $1A
	db $1A
	db $1A
	db $18
	db $1A
	db $1A
	db $1A
	db $1A
	db $1A
	db exit
ToDieForPhrase27:
	db env, $40, 12
	db len1
	db $11
	db $13
	db $13
	db $13
	db $13
	db $13
	db $13
	db $13
	db $13
	db $11
	db $13
	db $13
	db $13
	db $13
	db $13
	db $13
	db $13
	db $13
	db exit
ToDieForPhrase28:
	db env, $40, 12
	db len1
	db $15
	db $16
	db $16
	db $16
	db $16
	db $16
	db $16
	db $16
	db $16
	db $15
	db $16
	db $16
	db $16
	db $16
	db $16
	db $16
	db $16
	db $16
	db exit
ToDieForPhrase29:
	db env, $40, 12
	db len1
	db $17
	db $19
	db $19
	db $19
	db $19
	db $19
	db $19
	db $19
	db $19
	db $19
	db $1B
	db $1B
	db $1B
	db $1B
	db $1B
	db $1B
	db $1B
	db $1B
	db exit
ToDieForPhrase30:
	db env, $60, 128
	db len1
	db $12
	db $15
	db $17
	db env, $40, 128
	db $18
	db $19
	db $1C
	db len6
	db $1E
	db env, $60, 128
	db len1
	db $12
	db $15
	db $17
	db env, $40, 128
	db $18
	db $19
	db $1C
	db len6
	db $1D
	db exit
ToDieForPhrase31:
	db env, $40, 12
	db len1
	db $11
	db $13
	db $13
	db $13
	db $13
	db $13
	db $13
	db $13
	db $13
	db $11
	db $13
	db $16
	db $18
	db $1A
	db $1D
	db $1E
	db $1F
	db $22
	db exit
ToDieForPhrase32:
	db env, $40, 12
	db len1
	db $11
	db $13
	db $13
	db $13
	db $13
	db $13
	db $13
	db $13
	db $13
	db env, $40, 128
	db len2
	db $13
	db env, $60, 128
	db len1
	db $13
	db env, $40, 128
	db len2
	db $13
	db env, $60, 128
	db len1
	db $13
	db env, $40, 128
	db len2
	db $13
	db env, $60, 128
	db len1
	db $13
	db exit
ToDieForPhrase33:
	db env, $82
	db len2
	db $07
	db $07
	db env, $81
	db len1
	db $27
	db env, $82
	db len1
	db $07
	db len2
	db $07
	db env, $42
	db $07
	db env, $22
	db len1
	db $07
	db env, $81
	db len1
	db $27
	db env, $82
	db len2
	db $07
	db $07
	db env, $81
	db len1
	db $27
	db env, $82
	db len1
	db $07
	db len2
	db $07
	db env, $42
	db $07
	db env, $22
	db len1
	db $07
	db env, $81
	db len1
	db $27
	db exit
ToDieForPhrase34:
	db env, $82
	db len1
	db $07
	db env, $81
	db $27
	db $27
	db env, $82
	db $07
	db env, $81
	db $27
	db $27
	db env, $82
	db $07
	db $07
	db env, $81
	db $27
	db env, $82
	db len1
	db $07
	db env, $81
	db $27
	db $27
	db env, $82
	db $07
	db env, $81
	db $27
	db $27
	db env, $82
	db $07
	db $07
	db env, $81
	db $27
	db exit
ToDieForPhrase35:
	db env, $82
	db len2
	db $07
	db $07
	db env, $81
	db len1
	db $27
	db len2
	db $27
	db env, $42
	db len1
	db $07
	db len2
	db $07
	db len1
	db $07
	db env, $82
	db len1
	db $07
	db env, $82
	db len2
	db $07
	db $07
	db env, $81
	db len1
	db $27
	db len2
	db $27
	db env, $42
	db len1
	db $07
	db len2
	db $07
	db len1
	db $07
	db env, $82
	db len1
	db $07
	db exit

ExilePhrase01:
	db tempo, 32
	db duty, $C0
	db len10
	db rest
	db env, $C3
	db len2
	db $0D
	db exit
ExilePhrase02:
	db duty, $C0
	db env, $C7
	db len2
	db $11
	db $11
	db len4
	db $11
	db env, $CF
	db len12
	db $0F
	db env, $C4
	db len4
	db $0F
	db env, $C4
	db len2
	db $15
	db $15
	db len4
	db $15
	db env, $C7
	db $16
	db len12
	db $16
	db exit
ExilePhrase03:
	db duty, $C0
	db env, $C7
	db len4
	db $14
	db $14
	db $14
	db $18
	db $18
	db $18
	db len12
	db $18
	db exit
ExilePhrase04:
	db duty, $C0
	db env, $C7
	db len4
	db $0D
	db $11
	db $11
	db $11
	db $11
	db $11
	db $0D
	db $14
	db $14
	db $12
	db $12
	db env, $67
	db $1E
	db exit
ExilePhrase05:
	db duty, $C0
	db env, $67
	db len4
	db $22
	db len6
	db $22
	db len2
	db $1E
	db len4
	db $22
	db len6
	db $22
	db len2
	db $1E
	db len4
	db $1B
	db $1B
	db $1B
	db len12
	db $1D
	db exit
ExilePhrase06:
	db duty, $C0
	db env, $C7
	db len12
	db $0D
	db $0D
	db len8
	db $15
	db len4
	db $15
	db len12
	db $14
	db exit
ExilePhrase07:
	db duty, $C0
	db env, $C7
	db len12
	db $0D
	db $0D
	db len8
	db $0C
	db len4
	db $14
	db len12
	db $14
	db exit
ExilePhrase08:
	db duty, $C0
	db len10
	db rest
	db env, $C3
	db len2
	db $11
	db exit
ExilePhrase09:
	db duty, $C0
	db env, $C7
	db len2
	db $19
	db $18
	db env, $C3
	db len3
	db $19
	db env, $C7
	db len1
	db $16
	db len4
	db $18
	db env, $C7
	db len10
	db $11
	db env, $C4
	db len2
	db $11
	db $1B
	db $19
	db len3
	db $1B
	db len1
	db $18
	db env, $C7
	db len4
	db $18
	db len8
	db $19
	db len4
	db $1B
	db exit
ExilePhrase10:
	db duty, $C0
	db env, $C7
	db len4
	db $1D
	db $18
	db $1D
	db $1D
	db $1C
	db len3
	db $1F
	db len1
	db $20
	db len4
	db $1F
	db $1D
	db len2
	db $12
	db $0F
	db exit
ExilePhrase11:
	db duty, $C0
	db env, $C7
	db len4
	db $11
	db $16
	db len3
	db $16
	db len1
	db $18
	db len4
	db $16
	db $15
	db $14
	db $14
	db $19
	db len3
	db $17
	db len1
	db $19
	db len4
	db $17
	db $16
	db $22
	db exit
ExilePhrase12:
	db duty, $C0
	db env, $67
	db len4
	db $27
	db len6
	db $25
	db len2
	db $22
	db len4
	db $27
	db len6
	db $25
	db len2
	db $16
	db len4
	db $1E
	db $20
	db $21
	db len12
	db $22
	db exit
ExilePhrase13:
	db duty, $C0
	db env, $C7
	db len12
	db $10
	db $10
	db len8
	db $19
	db len4
	db $17
	db len12
	db $17
	db exit
ExilePhrase14:
	db duty, $C0
	db env, $C7
	db len12
	db $10
	db $10
	db len8
	db $14
	db len4
	db $18
	db len12
	db $19
	db exit
ExilePhrase15:
	db env, $20, 128
	db len2
	db $16
	db env, $40, 128
	db len1
	db $16
	db env, $20, 128
	db $16
	db $19
	db env, $60, 128
	db $19
	db env, $20, 128
	db len2
	db $16
	db len4
	db $1D
	db exit
ExilePhrase16:
	db env, $20, 128
	db len2
	db $16
	db env, $40, 128
	db len1
	db $16
	db env, $20, 128
	db $16
	db $19
	db env, $60, 128
	db $19
	db env, $20, 128
	db len2
	db $1D
	db $14
	db env, $40, 128
	db len1
	db $14
	db env, $20, 128
	db $14
	db $18
	db env, $60, 128
	db $18
	db env, $20, 128
	db len5
	db $1B
	db len1
	db $14
	db $18
	db env, $60, 128
	db $18
	db env, $20, 128
	db len2
	db $1B
	db $14
	db env, $40, 128
	db len1
	db $14
	db env, $20, 128
	db $14
	db $18
	db env, $60, 128
	db $18
	db env, $20, 128
	db len2
	db $1B
	db $16
	db env, $40, 128
	db len1
	db $16
	db env, $20, 128
	db $16
	db $19
	db env, $60, 128
	db $19
	db env, $20, 128
	db len8
	db $1D
	db len2
	db $16
	db exit
ExilePhrase17:
	db env, $20, 128
	db len2
	db $14
	db env, $40, 128
	db len1
	db $14
	db env, $20, 128
	db $14
	db $18
	db env, $60, 128
	db $18
	db env, $20, 128
	db len2
	db $1B
	db $14
	db $16
	db $18
	db env, $40, 128
	db len1
	db $18
	db env, $20, 128
	db $18
	db $1C
	db env, $60, 128
	db $1C
	db env, $20, 128
	db len2
	db $1F
	db $13
	db $14
	db $11
	db env, $40, 128
	db len1
	db $11
	db env, $20, 128
	db $11
	db $14
	db env, $60, 128
	db $14
	db env, $20, 128
	db len6
	db $18
	db exit
ExilePhrase18:
	db env, $20, 128
	db len3
	db $16
	db len2
	db $16
	db len1
	db $16
	db len2
	db $11
	db $16
	db $11
	db len3
	db $11
	db len2
	db $11
	db len1
	db $11
	db len2
	db $11
	db $14
	db $12
	db len3
	db $14
	db len2
	db $14
	db len1
	db $14
	db len2
	db $0F
	db $14
	db $0F
	db len3
	db $12
	db len2
	db $12
	db len1
	db $12
	db env, $40, 128
	db len2
	db $12
	db $12
	db $12
	db exit
ExilePhrase19:
	db env, $40, 128
	db len3
	db $0F
	db len2
	db $0F
	db len1
	db $0F
	db len2
	db $12
	db len4
	db $19
	db len3
	db $0F
	db $0F
	db len2
	db $0F
	db len4
	db $12
	db $0F
	db $12
	db $14
	db len12
	db $16
	db exit
ExilePhrase20:
	db env, $20, 128
	db len4
	db $1C
	db $1B
	db env, $40, 128
	db len2
	db $1B
	db env, $20, 128
	db $1E
	db len4
	db $1C
	db $19
	db len1
	db $1C
	db env, $40, 128
	db $1C
	db env, $20, 128
	db $20
	db env, $40, 128
	db $20
	db env, $20, 128
	db len4
	db $25
	db env, $40, 128
	db len2
	db $25
	db env, $20, 128
	db len1
	db $23
	db env, $40, 128
	db $23
	db env, $20, 128
	db len2
	db $21
	db $23
	db len4
	db $20
	db env, $40, 128
	db len3
	db $20
	db env, $60, 128
	db len1
	db $20
	db env, $20, 128
	db len2
	db $19
	db len1
	db $1B
	db env, $40, 128
	db len1
	db $1B
	db exit
ExilePhrase21:
	db env, $20, 128
	db len4
	db $1C
	db $1B
	db env, $40, 128
	db len2
	db $1B
	db env, $20, 128
	db len2
	db $1E
	db len4
	db $1C
	db $19
	db env, $40, 128
	db len2
	db $19
	db env, $20, 128
	db len1
	db $19
	db env, $40, 128
	db $19
	db env, $20, 128
	db len4
	db $18
	db $19
	db len2
	db $1B
	db env, $40, 128
	db $1B
	db env, $20, 128
	db len4
	db $19
	db env, $40, 128
	db $19
	db env, $60, 128
	db $19
	db exit
ExilePhrase22:
	db env, $81
	db len1
	db $07
	db env, $83
	db $01
	db env, $81
	db $01
	db env, $41
	db $27
	db env, $21
	db $27
	db env, $81
	db $01
	db env, $81
	db $27
	db env, $81
	db $01
	db env, $81
	db $07
	db env, $41
	db $07
	db env, $81
	db $27
	db env, $41
	db $27
	db exit
	
UnderTheStarsPhrase01:
	db tempo, 32
	db duty, $C0
	db env, $C7
	db len3
	db $17
	db $13
	db len2
	db $13
	db len3
	db $13
	db $13
	db len2
	db $13
	db len3
	db $17
	db $13
	db len2
	db $18
	db len4
	db $17
	db $13
	db len8
	db $13
	db $13
	db env, $CF
	db len10
	db $0E
	db env, $C4
	db len4
	db $0E
	db len2
	db $0E
	db exit
UnderTheStarsPhrase02:
	db duty, $80
	db env, $C7
	db len3
	db $0E
	db $0E
	db len2
	db $0E
	db len3
	db $10
	db $0C
	db len2
	db $0C
	db len3
	db $13
	db len5
	db $13
	db len2
	db $17
	db len6
	db $13
	db len8
	db $13
	db $13
	db len4
	db $15
	db $13
	db len8
	db $0E
	db exit
UnderTheStarsPhrase03:
	db duty, $40
	db env, $C7
	db len6
	db $12
	db len2
	db $15
	db len6
	db $12
	db len2
	db $0E
	db len6
	db $1A
	db len2
	db $1A
	db len3
	db $1A
	db $15
	db len2
	db $15
	db len6
	db $13
	db len2
	db $13
	db len8
	db $13
	db env, $CF
	db len8
	db $0E
	db env, $C7
	db $0E
	db exit
UnderTheStarsPhrase04:
	db duty, $00
	db env, $C7
	db len8
	db $15
	db $15
	db env, $6F
	db len8
	db $15
	db env, $67
	db $15
	db env, $6F
	db $0E
	db env, $67
	db $0E
	db env, $6F
	db $10
	db env, $67
	db $10
	db exit
UnderTheStarsPhrase05:
	db duty, $00
	db env, $C2
	db len1
	db $0E
	db len2
	db $0E
	db $0E
	db $0E
	db len1
	db $0E
	db env, $C7
	db len2
	db $0E
	db $0E
	db len4
	db $0E
	db env, $C2
	db len1
	db $13
	db len2
	db $13
	db $13
	db $13
	db len1
	db $13
	db env, $C7
	db len2
	db $15
	db $15
	db len6
	db $0E
	db env, $C2
	db len1
	db $15
	db len2
	db $15
	db $15
	db len1
	db $15
	db env, $C5
	db len2
	db $15
	db $15
	db $15
	db len4
	db $15
	db len1
	db $13
	db env, $C2
	db len2
	db $13
	db $13
	db len1
	db $13
	db env, $C5
	db len2
	db $15
	db $13
	db len4
	db $0E
	db exit
UnderTheStarsPhrase06:
	db duty, $C0
	db env, $C7
	db len3
	db $1F
	db $1A
	db len2
	db $1C
	db len3
	db $1A
	db $18
	db len2
	db $17
	db len3
	db $1F
	db $17
	db len2
	db $1C
	db len3
	db $1A
	db len1
	db $18
	db len4
	db $17
	db len6
	db $17
	db len2
	db $18
	db len3
	db $1A
	db len1
	db $18
	db len2
	db $17
	db $1A
	db env, $CF
	db len10
	db $15
	db env, $C4
	db len4
	db $15
	db len2
	db $15
	db exit
UnderTheStarsPhrase07:
	db duty, $80
	db env, $C7
	db len3
	db $15
	db $17
	db len2
	db $15
	db len3
	db $13
	db $10
	db len1
	db $13
	db $17
	db len3
	db $1C
	db $1A
	db len2
	db $18
	db $1A
	db len1
	db $1F
	db $1E
	db len4
	db $1F
	db len6
	db $17
	db len2
	db $18
	db len6
	db $1A
	db len2
	db $1A
	db len4
	db $18
	db $17
	db len6
	db $15
	db len2
	db $0E
	db exit
UnderTheStarsPhrase08:
	db duty, $40
	db env, $C7
	db len6
	db $15
	db len2
	db $1A
	db len6
	db $15
	db len2
	db $15
	db len6
	db $1E
	db len2
	db $1F
	db len3
	db $1E
	db $1C
	db len2
	db $1A
	db len6
	db $1F
	db len2
	db $21
	db len3
	db $1F
	db $1E
	db len2
	db $1C
	db env, $CF
	db len10
	db $21
	db env, $C4
	db len2
	db $1F
	db $1E
	db $1C
	db exit
UnderTheStarsPhrase09:
	db duty, $40
	db env, $C7
	db len8
	db $1A
	db $19
	db env, $6F
	db len8
	db $1A
	db env, $67
	db $1A
	db env, $6F
	db $13
	db env, $67
	db $13
	db env, $6F
	db $15
	db env, $67
	db $15
	db exit
UnderTheStarsPhrase10:
	db duty, $80
	db env, $C2
	db len1
	db $15
	db len2
	db $15
	db $15
	db $15
	db len1
	db $15
	db env, $C7
	db len2
	db $17
	db $13
	db len4
	db $15
	db env, $C2
	db len1
	db $17
	db len2
	db $17
	db $17
	db $17
	db len1
	db $17
	db env, $C7
	db len2
	db $19
	db $19
	db len6
	db $15
	db env, $C2
	db len1
	db $1A
	db len2
	db $1A
	db $1A
	db len1
	db $1A
	db env, $C5
	db len2
	db $1C
	db $1A
	db $1A
	db len4
	db $19
	db len1
	db $1A
	db env, $C2
	db len2
	db $1A
	db $1A
	db len1
	db $1A
	db env, $C5
	db len2
	db $19
	db $17
	db len4
	db $15
	db exit
UnderTheStarsPhrase11:
	db env, $20, 128
	db len3
	db $13
	db len1
	db $13
	db env, $60, 128
	db $13
	db env, $20, 128
	db len3
	db $0E
	db len1
	db $0E
	db env, $60, 128
	db len2
	db $0E
	db env, $20, 128
	db len1
	db $0E
	db len4
	db $0E
	db len3
	db $13
	db len1
	db $13
	db env, $60, 128
	db $13
	db env, $20, 128
	db len2
	db $0E
	db len1
	db $0E
	db len8
	db $0E
	db len1
	db $17
	db env, $60, 128
	db len2
	db $17
	db env, $20, 128
	db len5
	db $17
	db len1
	db $1A
	db env, $60, 128
	db len2
	db $1A
	db env, $20, 128
	db len4
	db $1A
	db len1
	db $17
	db $15
	db env, $60, 128
	db len2
	db $15
	db env, $20, 128
	db len5
	db $15
	db len3
	db $0E
	db len1
	db $0E
	db len4
	db $0E
	db exit
UnderTheStarsPhrase12:
	db env, $20, 128
	db len3
	db $15
	db len5
	db $15
	db len3
	db $13
	db len5
	db $13
	db len3
	db $10
	db $12
	db len2
	db $13
	db len8
	db $0E
	db $13
	db $12
	db len3
	db $10
	db $12
	db len2
	db $13
	db len8
	db $0E
	db exit
UnderTheStarsPhrase13:
	db env, $20, 128
	db len1
	db $0E
	db env, $60, 128
	db len2
	db $0E
	db env, $20, 128
	db len5
	db $0E
	db len1
	db $0E
	db env, $60, 128
	db len2
	db $0E
	db env, $20, 128
	db len5
	db $0E
	db len1
	db $1A
	db env, $60, 128
	db len2
	db $1A
	db env, $20, 128
	db len5
	db $1A
	db len1
	db $19
	db env, $60, 128
	db len2
	db $19
	db env, $20, 128
	db len5
	db $19
	db len1
	db $17
	db env, $60, 128
	db len2
	db $17
	db env, $20, 128
	db len5
	db $17
	db len1
	db $15
	db env, $60, 128
	db len2
	db $15
	db env, $20, 128
	db len5
	db $15
	db len8
	db $12
	db $0E
	db exit
UnderTheStarsPhrase14:
	db env, $20, 128
	db len8
	db $13
	db $12
	db len1
	db $1A
	db $1A
	db env, $60, 128
	db $1A
	db env, $20, 128
	db $1A
	db env, $60, 128
	db $1A
	db env, $20, 128
	db $15
	db $17
	db len2
	db $1A
	db len1
	db $1A
	db $17
	db env, $60, 128
	db $17
	db env, $20, 128
	db len2
	db $15
	db $17
	db len1
	db $1F
	db $1F
	db env, $60, 128
	db $1F
	db env, $20, 128
	db $1F
	db env, $60, 128
	db $1F
	db env, $20, 128
	db $1A
	db $1C
	db len2
	db $1F
	db len1
	db $1F
	db $1C
	db env, $60, 128
	db $1C
	db env, $20, 128
	db len2
	db $1A
	db $1C
	db len1
	db $15
	db $15
	db env, $60, 128
	db $15
	db env, $20, 128
	db $15
	db env, $60, 128
	db $15
	db env, $20, 128
	db $15
	db len4
	db $19
	db env, $40, 128
	db len2
	db $19
	db env, $20, 128
	db len2
	db $15
	db $19
	db exit
UnderTheStarsPhrase15:
	db env, $20, 128
	db len3
	db $0E
	db len1
	db $0E
	db len3
	db $0E
	db env, $40, 128
	db len1
	db $0E
	db env, $20, 128
	db len3
	db $0E
	db len1
	db $0E
	db len3
	db $0E
	db env, $40, 128
	db len1
	db $0E
	db env, $20, 128
	db len3
	db $13
	db len1
	db $13
	db len3
	db $13
	db env, $40, 128
	db len1
	db $13
	db env, $20, 128
	db len3
	db $15
	db len1
	db $15
	db len3
	db $0E
	db env, $40, 128
	db len1
	db $0E
	db env, $20, 128
	db len3
	db $0E
	db len1
	db $0E
	db len3
	db $0E
	db env, $40, 128
	db len1
	db $0E
	db env, $20, 128
	db len3
	db $0E
	db len1
	db $0E
	db len3
	db $0E
	db env, $40, 128
	db len1
	db $0E
	db env, $20, 128
	db len3
	db $13
	db len1
	db $13
	db len3
	db $13
	db env, $40, 128
	db len1
	db $13
	db env, $20, 128
	db len3
	db $15
	db len1
	db $15
	db len3
	db $0E
	db env, $40, 128
	db len1
	db $0E
	db exit
UnderTheStarsPhrase16:
	db env, $81
	db len1
	db $27
	db env, $83
	db $01
	db env, $81
	db $01
	db env, $81
	db $07
	db env, $81
	db $01
	db env, $81
	db $07
	db env, $81
	db $27
	db env, $41
	db $27
	db env, $81
	db $01
	db env, $81
	db $27
	db env, $81
	db $01
	db env, $81
	db $07
	db env, $41
	db $01
	db env, $81
	db $07
	db env, $81
	db $27
	db env, $81
	db $01
	db exit

BugTossPhrase01:	
	db tempo, 32
	db duty, $C0
	db len2
	db rest
	db env, $A2
	db len1
	db $15
	db len2
	db $15
	db env, $A3
	db len2
	db $15
	db env, $A4
	db len1
	db $15
	db len2
	db $15
	db $15
	db $15
	db len4
	db $15
	db len1
	db $15
	db env, $A2
	db len2
	db $15
	db env, $A3
	db $15
	db env, $A4
	db len1
	db $15
	db len2
	db $15
	db $15
	db $17
	db len4
	db $15
	db len1
	db $15
	db env, $A2
	db len2
	db $15
	db env, $A3
	db $15
	db env, $A4
	db len1
	db $15
	db len2
	db $15
	db $15
	db $15
	db len4
	db $15
	db len1
	db $15
	db env, $A2
	db len2
	db $15
	db env, $A3
	db $15
	db env, $A4
	db len1
	db $15
	db len2
	db $15
	db $15
	db $17
	db env, $A3
	db len2
	db $15
	db exit
BugTossPhrase02:
	db duty, $40
	db len2
	db rest
	db env, $A2
	db len1
	db $0E
	db len2
	db $0E
	db env, $A3
	db len2
	db $0E
	db len1
	db $0E
	db len2
	db $0E
	db env, $A2
	db $0E
	db env, $A4
	db $0E
	db len4
	db $0E
	db len1
	db $10
	db env, $A2
	db len2
	db $10
	db env, $A3
	db $10
	db len1
	db $10
	db len2
	db $10
	db env, $A2
	db len2
	db $10
	db len1
	db $10
	db env, $32
	db $0E
	db env, $52
	db $12
	db env, $A2
	db $15
	db exit
BugTossPhrase03:
	db duty, $80
	db env, $A7
	db len5
	db $18
	db len1
	db $18
	db $1A
	db $18
	db len5
	db $17
	db len1
	db $13
	db len2
	db $15
	db env, $AF
	db len8
	db $13
	db env, $A7
	db $13
	db exit
BugTossPhrase04:
	db duty, $00
	db env, $A3
	db len3
	db $10
	db len2
	db $10
	db $10
	db len1
	db $10
	db len2
	db $10
	db $10
	db len4
	db $0E
	db len3
	db $10
	db len2
	db $10
	db $10
	db len1
	db $10
	db len2
	db $12
	db $12
	db len4
	db $15
	db exit
BugTossPhrase05:
	db duty, $00
	db len2
	db rest
	db env, $A2
	db len1
	db $1A
	db len2
	db $1A
	db env, $A3
	db len2
	db $1A
	db env, $A4
	db len1
	db $1A
	db len2
	db $1C
	db $1A
	db $1A
	db len4
	db $19
	db len1
	db $1A
	db env, $A2
	db len2
	db $1A
	db env, $A3
	db $1A
	db env, $A4
	db len1
	db $1A
	db len2
	db $19
	db $17
	db $15
	db len4
	db $12
	db len1
	db $1A
	db env, $A2
	db len2
	db $1A
	db env, $A3
	db $1A
	db env, $A4
	db len1
	db $1A
	db len2
	db $1C
	db $1A
	db $1A
	db len4
	db $19
	db len1
	db $1A
	db env, $A2
	db len2
	db $1A
	db env, $A3
	db $1A
	db env, $A4
	db len1
	db $1A
	db len2
	db $19
	db $17
	db $15
	db env, $A3
	db len2
	db $12
	db exit
BugTossPhrase06:
	db duty, $40
	db len2
	db rest
	db env, $A2
	db len1
	db $15
	db len2
	db $15
	db env, $A3
	db len2
	db $15
	db len1
	db $15
	db len2
	db $17
	db env, $A2
	db $15
	db env, $A4
	db $15
	db len4
	db $12
	db len1
	db $15
	db env, $A2
	db len2
	db $15
	db env, $A3
	db $15
	db len1
	db $15
	db len2
	db $17
	db env, $A2
	db $15
	db env, $A4
	db $15
	db $12
	db exit
BugTossPhrase07:
	db duty, $80
	db env, $A7
	db len8
	db $15
	db $13
	db env, $AF
	db $1A
	db env, $A7
	db $1A
	db exit
BugTossPhrase08:
	db duty, $00
	db env, $A3
	db len3
	db $13
	db len2
	db $13
	db $13
	db len1
	db $13
	db len2
	db $15
	db $15
	db len4
	db $12
	db len3
	db $13
	db len2
	db $13
	db $13
	db len1
	db $13
	db len2
	db $15
	db $15
	db len4
	db $0E
	db exit
BugTossPhrase09:
	db env, $20, 128
	db len1
	db $1A
	db env, $60, 128
	db len2
	db $1A
	db env, $20, 128
	db len2
	db $1A
	db len1
	db $15
	db $17
	db $15
	db $1A
	db env, $60, 128
	db len2
	db $1A
	db env, $20, 128
	db len3
	db $1A
	db len2
	db $15
	db len1
	db $13
	db env, $60, 128
	db len2
	db $13
	db env, $20, 128
	db len2
	db $13
	db len1
	db $0E
	db $10
	db $0E
	db $13
	db env, $60, 128
	db len2
	db $13
	db env, $20, 128
	db len3
	db $15
	db len2
	db $15
	db len1
	db $1A
	db env, $60, 128
	db len2
	db $1A
	db env, $20, 128
	db $1A
	db len1
	db $15
	db $17
	db $15
	db $1A
	db env, $60, 128
	db len2
	db $1A
	db env, $20, 128
	db len3
	db $1A
	db len2
	db $15
	db len1
	db $13
	db env, $60, 128
	db len2
	db $13
	db env, $20, 128
	db $13
	db len1
	db $0E
	db $10
	db $0E
	db $13
	db env, $60, 128
	db len2
	db $13
	db env, $20, 128
	db len3
	db $15
	db len2
	db $15
	db exit
BugTossPhrase10:
	db env, $20, 128
	db len1
	db $1A
	db env, $60, 128
	db len2
	db $1A
	db env, $20, 128
	db len2
	db $1A
	db len1
	db $15
	db $17
	db $15
	db $1A
	db env, $60, 128
	db len2
	db $1A
	db env, $20, 128
	db len2
	db $1A
	db len1
	db $15
	db $17
	db $15
	db $18
	db env, $60, 128
	db len2
	db $18
	db env, $20, 128
	db $18
	db len1
	db $15
	db $17
	db $15
	db $18
	db env, $60, 128
	db len2
	db $18
	db env, $20, 128
	db $18
	db env, $60, 128
	db len1
	db $0E
	db env, $40, 128
	db $12
	db $15
	db exit
BugTossPhrase11:
	db env, $20, 128
	db len5
	db $18
	db env, $40, 128
	db len1
	db $18
	db $1A
	db $18
	db len5
	db $17
	db env, $20, 128
	db len1
	db $13
	db len2
	db $15
	db len1
	db $13
	db env, $60, 128
	db len2
	db $13
	db env, $20, 128
	db $13
	db env, $40, 128
	db len1
	db $0E
	db $10
	db $0E
	db env, $20, 128
	db $13
	db env, $60, 128
	db len2
	db $13
	db env, $20, 128
	db len5
	db $13
	db exit
BugTossPhrase12:
	db env, $20, 128
	db len1
	db $13
	db env, $60, 128
	db len2
	db $13
	db env, $20, 128
	db len1
	db $13
	db env, $40, 128
	db len4
	db $13
	db env, $20, 128
	db len3
	db $15
	db env, $40, 128
	db len1
	db $15
	db env, $20, 128
	db len4
	db $12
	db len1
	db $13
	db env, $60, 128
	db len2
	db $13
	db env, $20, 128
	db len1
	db $13
	db env, $60, 128
	db len4
	db $13
	db env, $20, 128
	db len2
	db $15
	db $0D
	db len1
	db $0E
	db env, $40, 128
	db len3
	db $0E
	db exit
BugTossPhrase13:
	db env, $81
	db len1
	db $27
	db env, $41
	db $27
	db env, $21
	db $27
	db env, $81
	db $07
	db env, $41
	db $07
	db env, $21
	db $07
	db env, $81
	db $07
	db env, $41
	db $07
	db env, $43
	db $01
	db env, $81
	db $01
	db env, $81
	db $27
	db env, $81
	db $01
	db env, $81
	db $07
	db env, $41
	db $07
	db env, $21
	db $07
	db env, $81
	db $01
	db exit
	
DeathTagPhrase01:
	db tempo, 22
	db duty, $00
	db env, $C7
	db len3
	db $11
	db len1
	db $11
	db len2
	db $11
	db $0C
	db env, $87
	db len2
	db $0E
	db env, $6F
	db len6
	db $10
	db env, $67
	db len4
	db $10
	db end
	db exit
DeathTagPhrase02:
	db duty, $40
	db env, $C7
	db len3
	db $18
	db len1
	db $16
	db len2
	db $14
	db env, $CF
	db len10
	db $13
	db env, $C7
	db len4
	db $13
	db exit
DeathTagPhrase03:
	db env, $20, 128
	db len1
	db $11
	db env, $40, 128
	db len3
	db $14
	db env, $20, 128
	db len2
	db $11
	db len4
	db $18
	db env, $40, 128
	db len3
	db $18
	db env, $60, 128
	db len7
	db $18
	db exit
DeathTagPhrase04:
	db len20
	db rest
	db exit

KingTagPhrase01:
	db tempo, 52
	db duty, $40
	db env, $8F
	db len8
	db $19
	db env, $87
	db $19
	db len6
	db $17
	db env, $8F
	db len6
	db $14
	db env, $87
	db len4
	db $14
	db env, $8F
	db len20
	db $19
	db env, $87
	db len4
	db $19
	db len8
	db $0D
	db end
	db exit
KingTagPhrase02:
	db duty, $40
	db env, $8F
	db len8
	db $1E
	db env, $87
	db $1E
	db len6
	db $1B
	db env, $8F
	db len6
	db $19
	db env, $87
	db len4
	db $19
	db env, $8F
	db len20
	db $1E
	db env, $87
	db len4
	db $1E
	db len8
	db $12
	db exit
KingTagPhrase03:
	db env, $20, 128
	db len3
	db $1E
	db len1
	db $22
	db len2
	db $25
	db len2
	db $2A
	db env, $60, 128
	db $2A
	db env, $20, 128
	db $2A
	db env, $60, 128
	db $2A
	db env, $20, 128
	db $2A
	db len4
	db $27
	db len2
	db $23
	db len6
	db $25
	db env, $40, 128
	db len2
	db $25
	db env, $60, 128
	db $25
	db env, $20, 128
	db len3
	db $1E
	db len1
	db $22
	db len2
	db $25
	db len2
	db $2A
	db env, $60, 128
	db $2A
	db env, $20, 128
	db $2A
	db env, $60, 128
	db $2A
	db env, $20, 128
	db len3
	db $2A
	db env, $40, 128
	db len5
	db $2A
	db env, $20, 128
	db len1
	db $25
	db $22
	db len3
	db $1E
	db env, $40, 128
	db len1
	db $1E
	db env, $60, 128
	db $1E
	db env, $00, 128
	db len3
	db $1E
	db exit
KingTagPhrase04:
	db env, $81
	db len2
	db $07
	db env, $C1
	db $27
	db env, $81
	db $01
	db env, $81
	db $07
	db env, $81
	db $01
	db $01
	db env, $81
	db $07
	db env, $81
	db $01
	db $01
	db env, $81
	db $07
	db $07
	db env, $81
	db $01
	db env, $81
	db $07
	db env, $C1
	db $27
	db env, $81
	db $01
	db $01
	db env, $81
	db len2
	db $07
	db env, $C1
	db $27
	db env, $81
	db $01
	db env, $81
	db $07
	db env, $81
	db $01
	db $01
	db env, $81
	db $07
	db env, $81
	db $01
	db $01
	db env, $81
	db $07
	db $07
	db env, $81
	db $01
	db env, $81
	db len8
	db $07
	db exit
	
Transpose0Phrase:
	db tpglobal, 0
	db exit
TransposeUp3Phrase:
	db tpglobal, 3
	db exit
TransposeUp5Phrase:
	db tpglobal, 5
	db exit
TransposeChDownOctPhrase:
	db tp, -12
	db exit
TransposeChan0Phrase:
	db tp, 0
	db exit
Vibrato00Phrase:
	db vib, $00
	db exit
Vibrato01Phrase:
	db vib, $01
	db exit
Vibrato02Phrase:
	db vib, $02
	db exit
Vibrato03Phrase:
	db vib, $03
	db exit
Rest48Phrase:
	db len32
	db rest
	db len16
	db rest
	db exit
Rest8Phrase:
	db len8
	db rest
	db exit

EndString:
	db "EndMusicFX."
	
SECTION "Audio RAM", WRAM0[AudioRAM]

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