;Blaster Master: Enemy Below audio disassembly
;Disassembly by Will Trowbridge

include "HARDWARE.INC"

def AudioROM equ $4000

def AudioRAM1 equ $D000
def AudioRAM2 equ $FFB0

def CondFlag equ $FF80

SECTION "Audio", ROMX[AudioROM], BANK[$1]

PlayAudio:
;Check if game conditional flag is set to value 11
	ldh a, [CondFlag]
	cp $11
	jr nz, CheckMus
	
;If not, then increment timer value
	ldh a, [SoundTimer]
	inc a
	ldh [SoundTimer], a
	bit 0, a
	ret z

CheckMus:
	;Check if new song is requested
	ld a, [MusCtrl]
	bit 7, a
	;If not, then skip to SFX
	jp nz, CheckSFX

	ld b, a
	;Check if song ID matches current
	ld a, [MusID]
	cp b
	;If so, then skip load process
	jp z, CheckSFX

	;Otherwise, load new song
	ld a, b
	ld [MusID], a
	
InitSong:
	;Get song address from pointer table
	add a
	ld e, a
	ld d, 0
	ld hl, SongTab
	add hl, de
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	;Disable all audio
	xor a
	ldh [rNR52], a
	
	;Then, copy the pointer information for each channel
	ld de, Ch1Pos
	ld b, 8

.CopySongPtrs
	;Copy the pointer in song header to each channel
	ld a, [hl+]
	ld [de], a
	inc de
	dec b
	jr nz, .CopySongPtrs

.InitChans
	;Disable sound effects (set SFX pointers to empty sequence)
	ld a, LOW(SoundNone)
	ldh [SFXCh2Pos], a
	ldh [SFXCh3Pos], a
	ldh [SFXCh4Pos], a
	ld a, HIGH(SoundNone)
	ldh [SFXCh2Pos+1], a
	ldh [SFXCh3Pos+1], a
	ldh [SFXCh4Pos+1], a
	
	;Set default tempo
	ld a, 192
	ldh [rTIMA], a
	ldh [rTMA], a
	
	;Set default octave pointer (4)
	ld a, LOW(Freq4Tab)
	ldh [Ch1OctPtr], a
	ldh [Ch2OctPtr], a
	ldh [Ch3OctPtr], a
	ld a, HIGH(Freq4Tab)
	ldh [Ch1OctPtr+1], a
	ldh [Ch2OctPtr+1], a
	ldh [Ch3OctPtr+1], a
	
	;Also set octave number
	ld a, 4
	ldh [Ch1Oct], a
	ldh [Ch2Oct], a
	ldh [Ch3Oct], a
	ldh [Ch4Oct], a
	
	;Set sound register values
	ld a, %10000000					;Set "trigger" bit(s) for NRx4
	ldh [MusNR14], a
	ldh [MusNR24], a
	ld a, %11000000
	ldh [MusNR44], a
	
	xor a							;Reset channel 3
	ldh [MusNR34], a
	
	ldh [Ch1Delay], a				;Also set note length for channels
	ldh [Ch2Delay], a
	ldh [Ch3Delay], a
	ldh [Ch4Delay], a

	ldh [SFXCh4Delay], a			;Set note length for SFX CH4
	ld a, %10000000					;Turn on audio
	ldh [rNR52], a

;Load waveform specified from table
	ld a, [MusCtrl]
	add a
	ld c, a
	ld b, 0
	ld hl, WaveTab
	add hl, bc
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	;B = Waveform length, C = Low byte of FF30 - Wave RAM
	ld bc, $1030

;Copy the waveform into wave RAM
.CopyWave
	ld a, [hl+]
	ldh [c], a
	inc c
	dec b
	jr nz, .CopyWave

.InitSongFinal
	;Set panning (NR51)
	ld a, %11111111
	ldh [MusNR51], a
	ldh [rNR51], a
	
	;Also set volume (NR50)
	ld a, %01110111
	ldh [rNR50], a
	
	;Set CH1 sweep
	ld a, %00001000
	ldh [rNR10], a
	
	;Enable CH3 DAC
	ld a, %10000000
	ldh [rNR30], a
	
	;Clear CH3 output
	xor a
	ldh [rNR32], a
	
	;Trigger on CH3
	ld a, %10000000
	ldh [rNR34], a
	
	;Request process?
	ld a, $8F
	ld [MusCtrl], a

;Check if SFX are playing
CheckSFX:
	ld a, [SFXCtrl]
	bit 7, a
	;If not, then skip
	jr nz, ProcCh1

;Initialize SFX
InitSFX:
	;Initialize SFX channel 1 with pointer to effect
	add a
	ld e, a
	ld d, 0
	ld hl, SFXC2Tab
	add hl, de
	ld a, [hl+]
	ldh [SFXCh2Pos], a
	ld a, [hl]
	ldh [SFXCh2Pos+1], a
	xor a
	ldh [SFXCh2Delay], a
	inc a
	ldh [SFXCh2Used], a
	
	;Initialize SFX channel 2 with pointer to effect
	ld hl, SFXC3Tab
	add hl, de
	ld a, [hl+]
	ldh [SFXCh3Pos], a
	ld a, [hl]
	ldh [SFXCh3Pos+1], a
	xor a
	ldh [SFXCh3Delay], a
	inc a
	ldh [SFXCh3Used], a
	
	;Initialize SFX channel 4 with pointer to effect
	ld hl, SFXC4Tab
	add hl, de
	ld a, [hl+]
	ldh [SFXCh4Pos], a
	ld a, [hl]
	ldh [SFXCh4Pos+1], a
	xor a
	ldh [SFXCh4Delay], a
	inc a
	ldh [SFXCh4Used], a
	
	;Set control flag
	ld a, $8E
	ld [SFXCtrl], a

ProcCh1:
	;Is channel 1 playing a note?
	ldh a, [Ch1Delay]
	or a
	;If so, then decrement delay and skip to channel 2
	jp nz, .C1DecDelay

	;Otherwise, load current pointer
	ldh a, [Ch1Pos]
	ld l, a
	ldh a, [Ch1Pos+1]
	ld h, a

.C1GetCommand
	;Get next command
	ld a, [hl+]
	ld c, a
	;Is it $C0 or higher?
	swap a
	and %00001111
	cp $0C
	;If so, then check for VCMD
	jr nc, .C1CheckVCMD

	;Otherwise, it must be a note
.C1Note
;00-BF = Play note with length
;Format: xxxxyyyy (X = note (C-B), Y = length (decoded with function, see below))
	add a						;Get note and add to octave pointer to get frequency
	ld e, a
	ldh a, [Ch1OctPtr]
	add e
	ld e, a
	ldh a, [Ch1OctPtr+1]
	adc 0
	ld d, a
	ld a, [de]
	ldh [MusNR13], a			;Load frequency into NRx3-NRx4 RAM values
	inc de
	ld a, [de]
	or %10000000				;Also set channel "trigger" flag (new note)
	ldh [MusNR14], a
	ldh a, [MusNR12Init]		;Set default volume/envelope
	ldh [MusNR12], a
	;Decode note length from lower 4 bits with command
	call DecLen
	;Then set delay to it
	ldh [Ch1Delay], a
	jp .C1CopyRegs

.C1CheckVCMD
	;Is the command Cx?
	jr nz, .C1EventTie			;If not, then it is a tie, rest, or octave control

	;Otherwise, check lower 4 bits of VCMD
	ld a, c
	and %00001111

.C1EventTempo
;C0 = Set tempo
;Parameters: xxxxxxxx (X = tempo - raw TMA value)
	;If this is not the command, then check for next command
	jr nz, .C1EventDuty

	;Load parameter into TMA
	ld a, [hl+]
	ldh [rTIMA], a
	ldh [rTMA], a
	;Then get next command
	jr .C1GetCommand

.C1EventDuty
;C1 = Set duty and length (NRx1)
;Parameters: xxxxxxxx (X = raw NRx1 value)
	;If this is not the command, then check for next command
	dec a
	jr nz, .C1EventVol

	;Load parameter into NRx1
	ld a, [hl+]
	ldh [rNR11], a
	;Then get next command
	jr .C1GetCommand

.C1EventVol
;C2 = Set volume/envelope (NRx2)
;Parameters: xxxxxxxx (X = raw NRx2 value)
	dec a
	;If this is not the command, then check for next command
	jr nz, .C1EventJump

	ld a, [hl+]
	ldh [MusNR12Init], a
	jr .C1GetCommand

.C1EventJump
;C3 = Jump to position
;Parameters: xxxxxxxx xxxxxxxx (X = position)
;(Can be used for loop)
	dec a
	;If this is not the command, then check for next command
	jr nz, .C1EventPan

	;Get new position from parameters
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	jr .C1GetCommand

.C1EventPan
;C4 = Set panning (NR51)
;Parameters: xxxxxxxx (X = raw NR51 value)
	dec a
	;If this is not the command, then check for next command
	jr nz, .C1EventMacroRet

	ld a, [hl+]
	ldh [MusNR51], a
	ldh [rNR51], a
	jr .C1GetCommand

.C1EventMacroRet
;C9 = Return from macro (subroutine)
	cp $05
	;If this is not the command, then check for next command
	jr nz, .C1EventMacro

	;Go to macro return position from RAM
	ldh a, [Ch1Ret]
	ld l, a
	ldh a, [Ch1Ret+1]
	ld h, a
	jp .C1GetCommand


.C1EventMacro
;CD = Go to a macro (subroutine)
;Parameters: xxxxxxxx xxxxxxxx (X = position)
;(Note: 1 level only)
	cp $09
	;If this is not the command, then check for next command
	jr nz, .C1EventEnd

	;Store new position from parameters into DE
	ld a, [hl+]
	ld e, a
	ld a, [hl+]
	ld d, a
	ld a, l
	;Also get return address and store in RAM
	ldh [Ch1Ret], a
	ld a, h
	ldh [Ch1Ret+1], a
	;Get new position from stored DE value
	ld l, e
	ld h, d
	jp .C1GetCommand


.C1EventEnd
;CE = Stop the current channel
	;Turn off channel volume
	ld a, %00001000
	ldh [MusNR12], a
	
	;Decrement position
	dec hl
	
	;Clear music control bit 0
	ld a, [MusCtrl]
	res 0, a
	ld [MusCtrl], a
	jr .C1CopyRegs

.C1EventTie
;Dx = Delay the current note for set length
;Parameters: CCCCxxxx (C = command, x = length (decoded with function, see below))
	cp $0D
	;If this is not the command, then check for next command
	jr nz, .C1EventRest

	;Decode note length from lower 4 bits with command
	call DecLen
	;Then set delay to it
	ldh [Ch1Delay], a
	jr .C1UpdatePos

.C1EventRest
;Ex = Key off the channel for set length
;Parameters: CCCCxxxx (C = command, x = length (decoded with function, see below))
	cp $0E
	;If this is not the command, then check for next command
	jr nz, .C1EventOctave

	;Turn off channel volume
	ld a, %00001000
	ldh [MusNR12], a
	
	;Decode note length from lower 4 bits with command
	call DecLen
	;Then set delay to it
	ldh [Ch1Delay], a
	jr .C1CopyRegs

;If none of the above, then it must be...

.C1EventOctave
;Fx = Set the current octave
;Parameters: CCCCxyyy (C = command, y = "relative mode" flag, x = octave number))
;(If X (relative mode) is set, then the octave will be controlled relative to the current octave.
;0-3 is positive, while 4-7 is negative.
;For example, an octave value of 1 means +1 octave.)				   
	ld a, c
	;Get the octave number from last 3 bits
	and %00000111
	;Check if "relative mode" flag is set
	bit 3, c
	;If not, then octave value is absolute
	jr z, .C1EventOctave_Set

	;Otherwise, check if value is less than 4 (positive)
	cp 4
	jr c, .C1EventOctave_Add

	;Otherwise, then is negative (use raw value which equals Fx = negative signed value)
	ld a, c

;Add to current octave
.C1EventOctave_Add
	ld b, a
	ldh a, [Ch1Oct]
	adc b

;Now set the current octave and get pointer
.C1EventOctave_Set
	ldh [Ch1Oct], a
	dec a
	add a
	add LOW(OctTab)
	ld e, a
	ld a, 0
	adc HIGH(OctTab)
	ld d, a
	ld a, [de]
	;Store the pointer into RAM
	ldh [Ch1OctPtr], a
	inc de
	ld a, [de]
	ldh [Ch1OctPtr+1], a
	jp .C1GetCommand


;Copy the NRxx values from RAM to actual registers
.C1CopyRegs
	ldh a, [MusNR12]
	ldh [rNR12], a
	ldh a, [MusNR13]
	ldh [rNR13], a
	ldh a, [MusNR14]
	ldh [rNR14], a

;Advance the pointer
.C1UpdatePos
	ld a, l
	ldh [Ch1Pos], a
	ld a, h
	ldh [Ch1Pos+1], a

;Decrement channel 1 note length/delay
.C1DecDelay
	ld hl, Ch1Delay
	dec [hl]


ProcCh2:
	;Is channel 2 playing a note?
	ldh a, [Ch2Delay]
	or a
	;If so, then decrement delay and skip to channel 3
	jp nz, .C2DecDelay

	;Otherwise, load current pointer
	ldh a, [Ch2Pos]
	ld l, a
	ldh a, [Ch2Pos+1]
	ld h, a

.C2GetCommand
	;Get next command
	ld a, [hl+]
	ld c, a
	;Is it $C0 or higher?
	swap a
	and %00001111
	cp $0C
	;If so, then check for VCMD
	jr nc, .C2CheckVCMD

	;Otherwise, it must be a note
.C2Note
;00-BF = Play note with length
;Format: xxxxyyyy (X = note (C-B), Y = length (decoded with function, see below))
	add a						;Get note and add to octave pointer to get frequency
	ld e, a
	ldh a, [Ch2OctPtr]
	add e
	ld e, a
	ldh a, [Ch2OctPtr+1]
	adc 0
	ld d, a
	ld a, [de]
	ldh [MusNR23], a			;Load frequency into NRx3-NRx4 RAM values
	inc de
	ld a, [de]
	or %10000000				;Also set channel "trigger" flag (new note)
	ldh [MusNR24], a
	ldh a, [MusNR22Init]		;Set default volume/envelope
	ldh [MusNR22], a
	;Decode note length from lower 4 bits with command
	call DecLen
	;Then set delay to it
	ldh [Ch2Delay], a
	jp .C2CopyRegs


.C2CheckVCMD
	;Is the command Cx?
	jr nz, .C2EventTie			;If not, then it is a tie, rest, or octave control

	;Otherwise, check lower 4 bits of VCMD
	ld a, c
	and %00001111
	
.C2EventTempo
;C0 = Set tempo
;Parameters: xxxxxxxx (X = tempo - raw TMA value)
	;If this is not the command, then check for next command
	jr nz, .C2EventDuty

	ld a, [hl+]
	ldh [rTIMA], a
	ldh [rTMA], a
	jr .C2GetCommand

.C2EventDuty
;C1 = Set duty and length (NRx1)
;Parameters: xxxxxxxx (X = raw NRx1 value)
	;If this is not the command, then check for next command
	dec a
	jr nz, .C2EventVol

	;Load parameter into NRx1
	ld a, [hl+]
	ldh [rNR21], a
	;Then get next command
	jr .C2GetCommand

.C2EventVol
;C2 = Set volume/envelope (NRx2)
;Parameters: xxxxxxxx (X = raw NRx2 value)
	dec a
	;If this is not the command, then check for next command
	jr nz, .C2EventJump

	ld a, [hl+]
	ldh [MusNR22Init], a
	jr .C2GetCommand

.C2EventJump
;C3 = Jump to position
;Parameters: xxxxxxxx xxxxxxxx (X = position)
;(Can be used for loop)
	dec a
	;If this is not the command, then check for next command
	jr nz, .C2EventMacroRet

	;Get new position from parameters
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	jr .C2GetCommand

.C2EventMacroRet
;C9 = Return from macro (subroutine)
	cp $06
	;If this is not the command, then check for next command
	jr nz, .C2EventMacro

	;Go to macro return position from RAM
	ldh a, [Ch2Ret]
	ld l, a
	ldh a, [Ch2Ret+1]
	ld h, a
	jp .C2GetCommand


.C2EventMacro
;CD = Go to a macro (subroutine)
;Parameters: xxxxxxxx xxxxxxxx (X = position)
;(Note: 1 level only)
	cp $0A
	;If this is not the command, then check for next command
	jr nz, .C2EventEnd

	;Store new position from parameters into DE
	ld a, [hl+]
	ld e, a
	ld a, [hl+]
	ld d, a
	ld a, l
	;Also get return address and store in RAM
	ldh [Ch2Ret], a
	ld a, h
	ldh [Ch2Ret+1], a
	;Get new position from stored DE value
	ld l, e
	ld h, d
	jp .C2GetCommand


.C2EventEnd
;CE = Stop the current channel
	;Turn off channel volume
	ld a, %00001000
	ldh [MusNR22], a
	
	;Decrement position
	dec hl
	
	;Clear music control bit 0
	ld a, [MusCtrl]
	res 1, a
	ld [MusCtrl], a
	jr .C2CopyRegs

.C2EventTie
;Dx = Delay the current note for set length
;Parameters: CCCCxxxx (C = command, x = length (decoded with function, see below))
	cp $0D
	;If this is not the command, then check for next command
	jr nz, .C2EventRest

	;Decode note length from lower 4 bits with command
	call DecLen
	ldh [Ch2Delay], a
	;Then set delay to it
	jr .C2UpdatePos

.C2EventRest
;Ex = Key off the channel for set length
;Parameters: CCCCxxxx (C = command, x = length (decoded with function, see below))
	cp $0E
	;If this is not the command, then check for next command
	jr nz, .C2EventOctave

	;Turn off channel volume
	ld a, %00001000
	ldh [MusNR22], a
	
	;Decode note length from lower 4 bits with command
	call DecLen
	;Then set delay to it
	ldh [Ch2Delay], a
	jr .C2CopyRegs
	
;If none of the above, then it must be...


.C2EventOctave
;Fx = Set the current octave
;Parameters: CCCCxyyy (C = command, y = "relative mode" flag, x = octave number))
;(If X (relative mode) is set, then the octave will be controlled relative to the current octave.
;0-3 is positive, while 4-7 is negative.
;For example, an octave value of 1 means +1 octave.)
	ld a, c
	;Get the octave number from last 3 bits
	and %00000111
	;Check if "relative mode" flag is set
	bit 3, c
	;If not, then octave value is absolute  
	jr z, .C2EventOctave_Set

	;Otherwise, check if value is less than 4 (positive)
	cp 4
	jr c, .C2EventOctave_Add

	;Otherwise, then is negative (use raw value which equals Fx = negative signed value)
	ld a, c

;Add to current octave
.C2EventOctave_Add
	ld b, a
	ldh a, [Ch2Oct]
	adc b

;Now set the current octave and get pointer
.C2EventOctave_Set
	ldh [Ch2Oct], a
	dec a
	add a
	add LOW(OctTab)
	ld e, a
	ld a, 0
	adc HIGH(OctTab)
	ld d, a
	ld a, [de]
	;Store the pointer into RAM
	ldh [Ch2OctPtr], a
	inc de
	ld a, [de]
	ldh [Ch2OctPtr+1], a
	jp .C2GetCommand


;Copy the NRxx values from RAM to actual registers
.C2CopyRegs
	;Don't play if SFX is playing
	ldh a, [SFXCh2Used]
	or a
	jr nz, .C2UpdatePos

	ldh a, [MusNR22]
	ldh [rNR22], a
	ldh a, [MusNR23]
	ldh [rNR23], a
	ldh a, [MusNR24]
	ldh [rNR24], a

;Advance the pointer
.C2UpdatePos
	ld a, l
	ldh [Ch2Pos], a
	ld a, h
	ldh [Ch2Pos+1], a

;Decrement channel 2 note length/delay
.C2DecDelay
	ld hl, Ch2Delay
	dec [hl]
	
	;Check if SFX are playing on channel
	ldh a, [SFXCh2Used]
	or a
	;If not, then skip
	jr z, ProcC3

ProcSFXC2:
	;Otherwise, check if channel is still playing note
	ldh a, [SFXCh2Delay]
	or a
	;If so, then...
	jr nz, .ProcSFXC2_DecDelay

	;If done playing note, then get next command
	ldh a, [SFXCh2Pos]
	ld l, a
	ldh a, [SFXCh2Pos+1]
	ld h, a
	ld a, [hl+]
	;Is it FF (end of sequence)?
	cp $FF
	;If not, then continue processing channel
	jr nz, .ProcSFXC2_CheckDelay

	;Otherwise, mute the channel
	ld a, %00001000
	ldh [rNR22], a
	swap a
	ldh [rNR24], a
	
	;Set "used" flag to 0
	xor a
	ldh [SFXCh2Used], a
	
	;Also clear SFX control bit
	ld a, [SFXCtrl]
	res 1, a
	ld [SFXCtrl], a
	jr ProcC3

.ProcSFXC2_CheckDelay
	;Set length timer
	ldh [rNR21], a
	;Now check delay from byte 1
	and %00111111
	;If 0, then calculate new delay from the following duty value
	jr z, .ProcSFXC2_DelayFromDutyVal

	;Otherwise, then set delay to it
	ldh [SFXCh2Delay], a
	;Then, load envelope value to register
	ld a, [hl+]
	ldh [rNR22], a
	jr .ProcSFXC2_Period

.ProcSFXC2_DelayFromDutyVal
	;If length timer was 0, then load envelope value to register
	ld a, [hl+]
	ldh [rNR22], a
	;Calculate new delay from byte 2 - duty value
	and %00000111
	add a
	add a
	add a
	ldh [SFXCh2Delay], a

.ProcSFXC2_Period
	;Then, get period values from byte 3-4
	ld a, [hl+]
	ldh [rNR23], a
	ld a, [hl+]
	;Also set trigger bit for period
	or %10000000
	ldh [rNR24], a

	;Load updated position into RAM
	ld a, l
	ldh [SFXCh2Pos], a
	ld a, h
	ldh [SFXCh2Pos+1], a

.ProcSFXC2_DecDelay
	;Decrement SFX channel delay
	ld hl, SFXCh2Delay
	dec [hl]

ProcC3:
	;Is channel 3 playing a note?
	ldh a, [Ch3Delay]
	or a
	;If so, then decrement delay and skip to channel 4
	jp nz, .C3DecDelay

	;Otherwise, load current pointer
	ldh a, [Ch3Pos]
	ld l, a
	ldh a, [Ch3Pos+1]
	ld h, a

.C3GetCommand
	;Get next command
	ld a, [hl+]
	ld c, a
	;Is it $C0 or higher?
	swap a
	and %00001111
	cp $0C
	;If so, then check for VCMD
	jr nc, .C3CheckVCMD

	;Otherwise, it must be a note
.C3Note
;00-BF = Play note with length
;Format: xxxxyyyy (X = note (C-B), Y = length (decoded with function, see below))
	add a						;Get note and add to octave pointer to get frequency
	ld e, a
	ldh a, [Ch3OctPtr]
	add e
	ld e, a
	ldh a, [Ch3OctPtr+1]
	adc 0
	ld d, a
	ld a, [de]
	ldh [MusNR33], a			;Load frequency into NRx3-NRx4 RAM values
	inc de
	ld a, [de]
	or %11000000				;Also set channel "trigger" flag (new note)
	ldh [MusNR34], a
	ldh a, [MusNR32Init]		;Set default volume/envelope
	ldh [MusNR32], a
	;Decode note length from lower 4 bits with command
	call DecLen
	;Then set delay to it
	ldh [Ch3Delay], a
	jp .C3CopyRegs


.C3CheckVCMD:
	;Is the command Cx?
	jr nz, .C3EventTie			;If not, then it is a tie, rest, or octave control

	;Otherwise, check lower 4 bits of VCMD
	ld a, c
	and %00001111
	
.C3EventTempo
;C0 = Set tempo
;Parameters: xxxxxxxx (X = tempo - raw TMA value)
	;If this is not the command, then check for next command
	jr nz, .C3EventDuty

	ld a, [hl+]
	ldh [rTIMA], a
	ldh [rTMA], a
	jr .C3GetCommand

.C3EventDuty
;C1 = Set duty and length (NRx1)
;Parameters: xxxxxxxx (X = raw NRx1 value)
	;If this is not the command, then check for next command
	dec a
	jr nz, .C3EventVol

	;Load parameter into NRx1
	ld a, [hl+]
	ldh [MusNR31], a
	;Then get next command
	jr .C3GetCommand

.C3EventVol
;C2 = Set volume/envelope (NRx2)
;Parameters: xxxxxxxx (X = raw NRx2 value)
	dec a
	;If this is not the command, then check for next command
	jr nz, .C3EventJump

	ld a, [hl+]
	ldh [MusNR32Init], a
	jr .C3GetCommand

.C3EventJump
;C3 = Jump to position
;Parameters: xxxxxxxx xxxxxxxx (X = position)
;(Can be used for loop)
	dec a
	;If this is not the command, then check for next command
	jr nz, .C3EventMacroRet

	;Get new position from parameters
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	jr .C3GetCommand

.C3EventMacroRet:
;C9 = Return from macro (subroutine)
	cp $06
	;If this is not the command, then check for next command
	jr nz, .C3EventMacro

	;Go to macro return position from RAM
	ldh a, [Ch3Ret]
	ld l, a
	ldh a, [Ch3Ret+1]
	ld h, a
	jp .C3GetCommand


.C3EventMacro
;CD = Go to a macro (subroutine)
;Parameters: xxxxxxxx xxxxxxxx (X = position)
;(Note: 1 level only)
	cp $0A
	;If this is not the command, then check for next command
	jr nz, .C3EventEnd

	;Store new position from parameters into DE
	ld a, [hl+]
	ld e, a
	ld a, [hl+]
	ld d, a
	ld a, l
	;Also get return address and store in RAM
	ldh [Ch3Ret], a
	ld a, h
	ldh [Ch3Ret+1], a
	;Get new position from stored DE value
	ld l, e
	ld h, d
	jp .C3GetCommand


.C3EventEnd
;CE = Stop the current channel
	;Turn off channel volume
	xor a
	ldh [MusNR32], a
	
	;Decrement position
	dec hl
	
	;Clear music control bit 0
	ld a, [MusCtrl]
	res 2, a
	ld [MusCtrl], a
	jr .C3CopyRegs

.C3EventTie
;Dx = Delay the current note for set length
;Parameters: CCCCxxxx (C = command, x = length (decoded with function, see below))
	cp $0D
	;If this is not the command, then check for next command
	jr nz, .C3EventRest

	;Decode note length from lower 4 bits with command
	call DecLen
	ldh [Ch3Delay], a
	;Then set delay to it
	jr .C3UpdatePos

.C3EventRest
;Ex = Key off the channel for set length
;Parameters: CCCCxxxx (C = command, x = length (decoded with function, see below))
	cp $0E
	;If this is not the command, then check for next command
	jr nz, .C3EventOctave

	;Turn off channel volume
	xor a
	ldh [MusNR32], a
	
	;Decode note length from lower 4 bits with command
	call DecLen
	;Then set delay to it
	ldh [Ch3Delay], a
	jr .C3CopyRegs

;If none of the above, then it must be...

.C3EventOctave
;Fx = Set the current octave
;Parameters: CCCCxyyy (C = command, y = "relative mode" flag, x = octave number))
;(If X (relative mode) is set, then the octave will be controlled relative to the current octave.
;0-3 is positive, while 4-7 is negative.
;For example, an octave value of 1 means +1 octave.)
	ld a, c
	;Get the octave number from last 3 bits
	and %00000111
	;Check if "relative mode" flag is set
	bit 3, c
	;If not, then octave value is absolute 
	jr z, .C3EventOctave_Set

	;Otherwise, check if value is less than 4 (positive)
	cp 4
	jr c, .C3EventOctave_Add

	;Otherwise, then is negative (use raw value which equals Fx = negative signed value)
	ld a, c

;Add to current octave
.C3EventOctave_Add
	ld b, a
	ldh a, [Ch3Oct]
	adc b

;Now set the current octave and get pointer
.C3EventOctave_Set
	ldh [Ch3Oct], a
	dec a
	add a
	add LOW(OctTab)
	ld e, a
	ld a, 0
	adc HIGH(OctTab)
	ld d, a
	ld a, [de]
	;Store the pointer into RAM
	ldh [Ch3OctPtr], a
	inc de
	ld a, [de]
	ldh [Ch3OctPtr+1], a
	jp .C3GetCommand


;Copy the NRxx values from RAM to actual registers
.C3CopyRegs
	;Don't play if SFX is playing
	ldh a, [SFXCh3Used]
	or a
	jr nz, .C3UpdatePos

	ldh a, [MusNR31]
	ldh [rNR31], a
	ldh a, [MusNR32]
	ldh [rNR32], a
	ldh a, [MusNR33]
	ldh [rNR33], a
	ldh a, [MusNR34]
	ldh [rNR34], a

;Advance the pointer
.C3UpdatePos
	ld a, l
	ldh [Ch3Pos], a
	ld a, h
	ldh [Ch3Pos+1], a

;Decrement channel 3 note length/delay
.C3DecDelay
	ld hl, Ch3Delay
	dec [hl]
	
	;Check if SFX are playing on channel
	ldh a, [SFXCh3Used]
	or a
	;If not, then skip
	jr z, ProcCh4

ProcSFXC3:
	;Otherwise, check if channel is still playing note
	ldh a, [SFXCh3Delay]
	or a
	;If so, then...
	jr nz, .ProcSFXC3_DecDelay

	;If done playing note, then get next command
	ldh a, [SFXCh3Pos]
	ld l, a
	ldh a, [SFXCh3Pos+1]
	ld h, a
	ld a, [hl+]
	;Is it FF (end of sequence)?
	cp $FF
	;If not, then continue processing channel
	jr nz, .ProcSFXC3_CheckDelay

	;Otherwise, mute the channel
	ld a, %00001000
	ldh [rNR32], a
	swap a
	ldh [rNR34], a
	
	;Set "used" flag to 0
	xor a
	ldh [SFXCh3Used], a
	
	;Also clear SFX control bit
	ld a, [SFXCtrl]
	res 2, a
	ld [SFXCtrl], a
	jr ProcCh4

.ProcSFXC3_CheckDelay
	;Set length timer
	ldh [rNR31], a
	;Now check delay from byte 1
	and %00111111
	;If 0, then calculate new delay from the following duty value
	jr z, .ProcSFXC3_DelayFromDutyVal

	;Otherwise, then set delay to it
	ldh [SFXCh3Delay], a
	;Then, load envelope value to register
	ld a, [hl+]
	ldh [rNR32], a
	jr .ProcSFXC3_Period

.ProcSFXC3_DelayFromDutyVal
	;If length timer was 0, then load envelope value to register
	ld a, [hl+]
	ldh [rNR32], a
	;Calculate new delay from byte 2 - duty value
	and %00000111
	add a
	add a
	add a
	ldh [SFXCh3Delay], a

.ProcSFXC3_Period
	;Then, get period values from byte 3-4
	ld a, [hl+]
	ldh [rNR33], a
	ld a, [hl+]
	;Also set trigger bit for period
	or %10000000
	ldh [rNR34], a
	
	;Load updated position into RAM
	ld a, l
	ldh [SFXCh3Pos], a
	ld a, h
	ldh [SFXCh3Pos+1], a

.ProcSFXC3_DecDelay
	;Decrement SFX channel delay
	ld hl, SFXCh3Delay
	dec [hl]

ProcCh4:
	;Is channel 4 playing a note?
	ldh a, [Ch4Delay]
	or a
	;If so, then decrement note (and then return)
	jp nz, .C4DecDelay

	;Otherwise, load current pointer
	ldh a, [Ch4Pos]
	ld l, a
	ldh a, [Ch4Pos+1]
	ld h, a

.C4GetCommand
	;Get next command
	ld a, [hl+]
	ld c, a
	;Is it $C0 or higher?
	swap a
	and %00001111
	cp $0C
	;If so, then check for VCMD
	jr nc, .C4CheckVCMD

	;Otherwise, it must be a note
.C4Note
;00-BF = Play note with length
;Format: xxxxyyyy (X = note (C-B), Y = length (decoded with function, see below))
	ldh a, [MusNR42Init]
	ldh [MusNR42], a
	;Get frequency from table using index of upper 4 bits
	ld de, NoiseFreqTab
	ld a, c
	and %11110000
	swap a
	add e
	ld e, a
	ld a, d
	adc 0
	ld d, a
	ld a, [de]
	ldh [MusNR43], a			;Load frequency into NRx3-NRx4 RAM values	
	ld a, %11000000				;Also set channel "trigger" flags (new note)
	ldh [MusNR44], a
	;Decode note length from lower 4 bits with command
	call DecLen
	;Then set delay to it
	ldh [Ch4Delay], a
	jp .C4CopyRegs


.C4CheckVCMD
	;Is the command Cx?
	jr nz, .C4EventTie			;If not, then it is a tie, rest, or octave control

	;Otherwise, check lower 4 bits of VCMD
	ld a, c
	and %00001111
.C4EventTempo
;C0 = Set tempo
;Parameters: xxxxxxxx (X = tempo - raw TMA value)
	;If this is not the command, then check for next command
	jr nz, .C4EventDuty

	ld a, [hl+]
	ldh [rTIMA], a
	ldh [rTMA], a
	jr .C4GetCommand

.C4EventDuty
;C1 = Set duty and length (NRx1)
;Parameters: xxxxxxxx (X = raw NRx1 value)
	;If this is not the command, then check for next command
	dec a
	jr nz, .C4EventVol

	;Load parameter into NRx1
	ld a, [hl+]
	ldh [MusNR41], a
	;Then get next command
	jr .C4GetCommand

.C4EventVol
;C2 = Set volume/envelope (NRx2)
;Parameters: xxxxxxxx (X = raw NRx2 value)
	dec a
	;If this is not the command, then check for next command
	jr nz, .C4EventJump

	ld a, [hl+]
	ldh [MusNR42Init], a
	jr .C4GetCommand

.C4EventJump
;C3 = Jump to position
;Parameters: xxxxxxxx xxxxxxxx (X = position)
;(Can be used for loop)
	dec a
	;If this is not the command, then check for next command
	jr nz, .C4EventMacroRet

	;Get new position from parameters
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	jr .C4GetCommand

.C4EventMacroRet
;C9 = Return from macro (subroutine)
	cp $06
	;If this is not the command, then check for next command
	jr nz, .C4EventMacro

	;Go to macro return position from RAM
	ldh a, [Ch4Ret]
	ld l, a
	ldh a, [Ch4Ret+1]
	ld h, a
	jp .C4GetCommand


.C4EventMacro
;CD = Go to a macro (subroutine)
;Parameters: xxxxxxxx xxxxxxxx (X = position)
;(Note: 1 level only)
	cp $0A
	;If this is not the command, then check for next command
	jr nz, .C4EventEnd

	;Store new position from parameters into DE
	ld a, [hl+]
	ld e, a
	ld a, [hl+]
	ld d, a
	ld a, l
	;Also get return address and store in RAM
	ldh [Ch4Ret], a
	ld a, h
	ldh [Ch4Ret+1], a
	;Get new position from stored DE value
	ld l, e
	ld h, d
	jp .C4GetCommand


.C4EventEnd
;CE = Stop the current channel
	;Turn off channel volume
	ld a, %00001000
	ldh [MusNR42], a
	
	;Decrement position
	dec hl
	
	;Clear music control bit 0
	ld a, [MusCtrl]
	res 3, a
	ld [MusCtrl], a
	jr .C4CopyRegs

.C4EventTie
;Delay the current note for set length
;Parameters: CCCCxxxx (C = command, x = length (decoded with function, see below))
	cp $0D
	;If this is not the command, then check for next command
	jr nz, .C4EventRest

	;Decode note length from lower 4 bits with command
	call DecLen
	ldh [Ch4Delay], a
	;Then set delay to it
	jr .C4UpdatePos

.C4EventRest
;Ex = Key off the channel for set length
;Parameters: CCCCxxxx (C = command, x = length (decoded with function, see below)
	cp $0E
	;If this is not the command, then check for next command
	jr nz, .C4CopyRegs

	;Turn off channel volume
	ld a, %00001000
	ldh [MusNR42], a
	
	;Decode note length from lower 4 bits with command
	call DecLen
	ldh [Ch4Delay], a
	jr .C4CopyRegs

	jp .C4GetCommand
	
;If none of the above, then do nothing


;Copy the NRxx values from RAM to actual registers
.C4CopyRegs
	;Don't play if SFX is playing
	ldh a, [SFXCh4Used]
	or a
	jr nz, .C4UpdatePos

	ldh a, [MusNR41]
	ldh [rNR41], a
	ldh a, [MusNR42]
	ldh [rNR42], a
	ldh a, [MusNR43]
	ldh [rNR43], a
	ldh a, [MusNR44]
	ldh [rNR44], a

;Advance the pointer
.C4UpdatePos
	ld a, l
	ldh [Ch4Pos], a
	ld a, h
	ldh [Ch4Pos+1], a

;Decrement channel 4 note length/delay
.C4DecDelay
	ld hl, Ch4Delay
	dec [hl]
	
	;Check if SFX are playing on channel
	ldh a, [SFXCh4Used]
	or a
	;If not, then return
	ret z

ProcSFXC4:
	;Otherwise, check if channel is still playing note
	ldh a, [SFXCh4Delay]
	or a
	jr nz, .ProcSFXC4_DecDelay

	;If done playing note, then get next command
	ldh a, [SFXCh4Pos]
	ld l, a
	ldh a, [SFXCh4Pos+1]
	ld h, a
	ld a, [hl+]
	;Is it FF (end of sequence)?
	cp $FF
	;If not, then continue processing channel
	jr nz, .ProcSFXC4_CheckDelay

	;Otherwise, mute the channel
	ld a, %00001000
	ldh [rNR42], a
	swap a
	ldh [rNR44], a
	
	;Set "used" flag to 0
	xor a
	ldh [SFXCh4Used], a
	
	;Also clear SFX control bit
	ld a, [SFXCtrl]
	res 3, a
	ld [SFXCtrl], a
	ret


.ProcSFXC4_CheckDelay
	;Set length timer
	ldh [rNR41], a
	;Now check delay from byte 1
	and %00111111
	;If 0, then calculate new delay from the following duty value
	jr z, .ProcSFXC4_DelayFromDutyVal

	;Otherwise, then set delay to it
	ldh [SFXCh4Delay], a
	;Then, load envelope value to register
	ld a, [hl+]
	ldh [rNR42], a
	jr .ProcSFXC4_Period

.ProcSFXC4_DelayFromDutyVal
	;If length timer was 0, then load envelope value to register
	ld a, [hl+]
	ldh [rNR42], a
	;Calculate new delay from byte 2 - duty value
	and %00000111
	add a
	add a
	add a
	ldh [SFXCh4Delay], a

.ProcSFXC4_Period
	;Then, get period values from byte 3-4
	ld a, [hl+]
	ldh [rNR43], a
	ld a, [hl+]
	;Also set trigger bit for period
	or %10000000
	ldh [rNR44], a
	
	;Load updated position into RAM
	ld a, l
	ldh [SFXCh4Pos], a
	ld a, h
	ldh [SFXCh4Pos+1], a

.ProcSFXC4_DecDelay
	;Decrement SFX channel delay
	ld hl, SFXCh4Delay
	dec [hl]
	ret


DecLen:
;Decode the length of a note from lower 4 bits
;Format: ----xyyy (X = "half flag" - multiply value by 1.5, Y = shift count (right))
	;Get lower 3 bits - shift count right
	ld a, c
	and %00000111
	ld b, a
	;Set number of ticks = 128
	ld a, 128
	;If shift value is 0, then don't shift value
	jr z, .DecLenAddHalf

;Otherwise, shift the result
.DecLenShift
	;Shift and decrease shift count until 0
	srl a
	dec b
	jr nz, .DecLenShift


;Multiply value by 1.5 if "half flag" is set
.DecLenAddHalf
	;Shift the value once (divide by 2)
	ld b, a
	srl b
	;Check if "longer" value is set - if so, then add half amount to value
	bit 3, c
	;If not, then skip
	jr z, .DecLenRet

	add b

;Return from function
.DecLenRet
	ret


SoundNone:
	db $00
	
OctTab:
	dw Freq1Tab
	dw Freq2Tab
	dw Freq3Tab
	dw Freq4Tab
	dw Freq5Tab
	dw Freq6Tab
	dw Freq7Tab
	
Freq1Tab:
	dw $002C
	dw $009D
	dw $0107
	dw $016B
	dw $01C9
	dw $0222
	dw $0277
	dw $02C7
	dw $0312
	dw $0358
	dw $039B
	dw $03DA
Freq2Tab:
	dw $0416
	dw $044E
	dw $0483
	dw $04B5
	dw $04E5
	dw $0511
	dw $053B
	dw $0563
	dw $0589
	dw $05AC
	dw $05CE
	dw $05ED
Freq3Tab:
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
Freq4Tab:
	dw $0706
	dw $070F
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
Freq5Tab:
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
Freq6Tab:
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
Freq7Tab:
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
	
SongTab:
	dw Song00
	dw Song01
	dw Song02
	dw Song03
	dw Song04
	dw Song05
	dw Song06
	dw Song07
	dw Song08
	dw Song09
	dw Song0A
	dw Song0B
	dw Song0C
	dw Song0D
	dw Song0E
	dw Song0F
	
SFXC2Tab:
	dw SFX00C2
	dw SFX01C2
	dw SFX02C2
	dw SFX03C2
	dw SFX04C2
	dw SFX05C2
	dw SFX06C2
	dw SFX07C2
	dw SFX08C2
	dw SFX09C2
	dw SFX0AC2
	dw SFX0BC2
	dw SFX0CC2
	dw SFX0DC2
	dw SFX0EC2
	dw SFX0FC2
	dw SFX10C2
	dw SFX11C2
	dw SFX12C2
	dw SFX13C2
	dw SFX14C2
	dw SFX15C2
	dw SFX16C2
	dw SFX17C2
	dw SFX18C2
	dw SFX19C2
	dw SFX1AC2
	dw SFX1BC2
	dw SFX1CC2
	dw SFX1DC2
	dw SFX1EC2
	dw SFX1FC2
	dw SFX20C2
	dw SFX21C2
	dw SFX22C2
	dw SFX23C2
	dw SFX24C2
	dw SFX25C2
	dw SFX26C2
	dw SFX27C2
	dw SFX28C2
	dw SFX29C2
	dw SFX2AC2
	dw SFX2BC2
	dw SFX2CC2
	dw SFX2DC2
	dw SFX2EC2
	dw SFX2FC2
	dw SFX30C2
	dw SFX31C2
	dw SFX32C2
	dw SFX33C2
	dw SFX34C2
	dw SFX35C2
	dw SFX36C2
	dw SFX37C2
	dw SFX38C2
	dw SFX39C2
	dw SFX3AC2
	dw SFX3BC2
	dw SFX3CC2
	dw SFX3DC2
	dw SFX3EC2
	dw SFX3FC2
	dw SFX40C2
	dw SFX41C2
	dw SFX42C2
	dw SFX43C2

SFXC3Tab:
	dw SFX00C3
	dw SFX01C3
	dw SFX02C3
	dw SFX03C3
	dw SFX04C3
	dw SFX05C3
	dw SFX06C3
	dw SFX07C3
	dw SFX08C3
	dw SFX09C3
	dw SFX0AC3
	dw SFX0BC3
	dw SFX0CC3
	dw SFX0DC3
	dw SFX0EC3
	dw SFX0FC3
	dw SFX10C3
	dw SFX11C3
	dw SFX12C3
	dw SFX13C3
	dw SFX14C3
	dw SFX15C3
	dw SFX16C3
	dw SFX17C3
	dw SFX18C3
	dw SFX19C3
	dw SFX1AC3
	dw SFX1BC3
	dw SFX1CC3
	dw SFX1DC3
	dw SFX1EC3
	dw SFX1FC3
	dw SFX20C3
	dw SFX21C3
	dw SFX22C3
	dw SFX23C3
	dw SFX24C3
	dw SFX25C3
	dw SFX26C3
	dw SFX27C3
	dw SFX28C3
	dw SFX29C3
	dw SFX2AC3
	dw SFX2BC3
	dw SFX2CC3
	dw SFX2DC3
	dw SFX2EC3
	dw SFX2FC3
	dw SFX30C3
	dw SFX31C3
	dw SFX32C3
	dw SFX33C3
	dw SFX34C3
	dw SFX35C3
	dw SFX36C3
	dw SFX37C3
	dw SFX38C3
	dw SFX39C3
	dw SFX3AC3
	dw SFX3BC3
	dw SFX3CC3
	dw SFX3DC3
	dw SFX3EC3
	dw SFX3FC3
	dw SFX40C3
	dw SFX41C3
	dw SFX42C3
	dw SFX43C3

SFXC4Tab:
	dw SFX00C4
	dw SFX01C4
	dw SFX02C4
	dw SFX03C4
	dw SFX04C4
	dw SFX05C4
	dw SFX06C4
	dw SFX07C4
	dw SFX08C4
	dw SFX09C4
	dw SFX0AC4
	dw SFX0BC4
	dw SFX0CC4
	dw SFX0DC4
	dw SFX0EC4
	dw SFX0FC4
	dw SFX10C4
	dw SFX11C4
	dw SFX12C4
	dw SFX13C4
	dw SFX14C4
	dw SFX15C4
	dw SFX16C4
	dw SFX17C4
	dw SFX18C4
	dw SFX19C4
	dw SFX1AC4
	dw SFX1BC4
	dw SFX1CC4
	dw SFX1DC4
	dw SFX1EC4
	dw SFX1FC4
	dw SFX20C4
	dw SFX21C4
	dw SFX22C4
	dw SFX23C4
	dw SFX24C4
	dw SFX25C4
	dw SFX26C4
	dw SFX27C4
	dw SFX28C4
	dw SFX29C4
	dw SFX2AC4
	dw SFX2BC4
	dw SFX2CC4
	dw SFX2DC4
	dw SFX2EC4
	dw SFX2FC4
	dw SFX30C4
	dw SFX31C4
	dw SFX32C4
	dw SFX33C4
	dw SFX34C4
	dw SFX35C4
	dw SFX36C4
	dw SFX37C4
	dw SFX38C4
	dw SFX39C4
	dw SFX3AC4
	dw SFX3BC4
	dw SFX3CC4
	dw SFX3DC4
	dw SFX3EC4
	dw SFX3FC4
	dw SFX40C4
	dw SFX41C4
	dw SFX42C4
	dw SFX43C4
	
WaveTab:
	dw Wave00
	dw Wave00
	dw Wave00
	dw Wave00
	dw Wave00
	dw Wave00
	dw Wave00
	dw Wave00
	dw Wave00
	dw Wave00
	dw Wave00
	dw Wave00
	dw Wave00
	dw Wave00
	dw Wave00
	dw Wave00
	dw Wave00
	dw Wave00
	dw Wave00
	dw Wave00
	dw Wave00
	dw Wave00
	dw Wave00
	dw Wave00
	dw Wave00
	dw Wave00
	dw Wave00
	dw Wave00
	dw Wave00
	dw Wave00
	dw Wave00
	dw Wave00

Wave00:
	db $00, $55, $AA, $FF, $00, $55, $AA, $FF, $00, $55, $AA, $FF, $00, $55, $AA, $FF
Wave01:
	db $00, $55, $AA, $FF, $AA, $55, $00, $55, $AA, $FF, $AA, $55, $00, $55, $AA, $FF
Wave02:
	db $00, $22, $44, $66, $88, $AA, $CC, $EE, $FF, $DD, $BB, $99, $77, $55, $33, $11
Wave03:
	db $00, $ED, $FE, $C6, $00, $F5, $F3, $D5, $00, $F5, $FB, $D7, $00, $F5, $03, $C9
	
NoiseFreqTab:
	db $01, $11, $21, $31, $41, $51, $29, $39, $2A, $3A, $49, $59
	
Song00:
	dw Song00A
	dw Song00B
	dw Song00C
	dw Song00D
Song00A:
	db $C4, %11111111
	db $C0, $C0
Song00B:
	db $C1, $80
	db $C2, $F3
	db $CE
Song00C:
	db $C1, $F0
	db $C2, $20
	db $CE
Song00D:
	db $C1, $01
	db $C2, $F1
	db $CE
	
Song01:
	dw Song01A
	dw Song01B
	dw Song01C
	dw Song01D
Song01A:
	db $C4, %11111111
	db $C0, 176
	db $C1, $80
	db $C2, $91
	db $F3
	db $2C
	db $2D
	db $2D
	db $2C
	db $2D
	db $2D
	db $2C
	db $2D
	db $2D
	db $2D
	db $2D
	db $2D
	db $2D
	db $7C
	db $7D
	db $7D
	db $7C
	db $7D
	db $7D
	db $7C
	db $7D
	db $7D
	db $7D
	db $7D
	db $7D
	db $7D
	db $F4
	db $0C
	db $0D
	db $0D
	db $0C
	db $0D
	db $0D
	db $0C
	db $0D
	db $0D
	db $0D
	db $0D
	db $0D
	db $0D
	db $0D
	db $0D
	db $0D
	db $0D
	db $0D
	db $0D
	db $0D
	db $0D
	db $0D
	db $0D
	db $0D
	db $0D
	db $0D
	db $0D
	db $0D
	db $0D
Song01ALoop:
	db $C2, $95
	db $F3
	db $7A
	db $DC
	db $7C
	db $BD
	db $F4
	db $2C
	db $5D
	db $5A
	db $DD
	db $5D
	db $4D
	db $2C
	db $0D
	db $4D
	db $2D
	db $29
	db $CD
	dw SongMacro00
	db $D9
	db $EC
	db $F2
	db $5D
	db $5D
	db $5D
	db $53
	db $D6
	db $5D
	db $5D
	db $5D
	db $5B
	db $DD
	db $F3
	db $7A
	db $DC
	db $7C
	db $BD
	db $F4
	db $2C
	db $5D
	db $5A
	db $DD
	db $5D
	db $4D
	db $2C
	db $0D
	db $4D
	db $2D
	db $29
	db $CD
	dw SongMacro00
	db $D9
	db $EC
	db $F2
	db $5D
	db $5D
	db $5D
	db $53
	db $D6
	db $5D
	db $5D
	db $5D
	db $53
	db $D6
	db $F4
	db $4C
	db $29
	db $29
	db $11
	db $D4
	db $24
	db $44
	db $F3
	db $94
	db $73
	db $D6
	db $F4
	db $21
	db $DC
	db $D6
	db $11
	db $D4
	db $24
	db $44
	db $94
	db $73
	db $D6
	db $23
	db $D6
	db $F3
	db $BC
	db $F4
	db $2B
	db $F3
	db $BB
	db $F4
	db $11
	db $D4
	db $24
	db $44
	db $F3
	db $94
	db $73
	db $D6
	db $F4
	db $2A
	db $DD
	db $F3
	db $BB
	db $F4
	db $13
	db $D6
	db $F3
	db $A3
	db $D6
	db $6C
	db $AB
	db $1B
	db $69
	db $C2, $93
	db $EC
	db $F2
	db $5D
	db $5D
	db $5D
	db $53
	db $D6
	db $5D
	db $5D
	db $5D
	db $5B
	db $DD
	db $5D
	db $5D
	db $5D
	db $5D
	db $5D
	db $53
	db $D6
	db $5D
	db $5D
	db $5D
	db $5B
	db $DD
	db $EC
	db $5D
	db $5D
	db $5D
	db $53
	db $D6
	db $5D
	db $5D
	db $5D
	db $5B
	db $5D
	db $DD
	db $5D
	db $5D
	db $5D
	db $5D
	db $53
	db $D6
	db $5D
	db $5D
	db $5D
	db $5B
	db $DD
	db $C2, $97
	db $F3
	db $71
	db $D4
	db $7D
	db $2D
	db $7D
	db $5D
	db $5A
	db $5C
	db $4B
	db $2C
	db $71
	db $D4
	db $7D
	db $2D
	db $7D
	db $5D
	db $DC
	db $9B
	db $F4
	db $0C
	db $5A
	db $C3
	dw Song01ALoop
SongMacro00:
	db $EC
	db $F2
	db $5D
	db $5D
	db $5D
	db $73
	db $D6
	db $5D
	db $5D
	db $5D
	db $7B
	db $F3
	db $7D
	db $DA
	db $DC
	db $7C
	db $BD
	db $F4
	db $2C
	db $5D
	db $5A
	db $5D
	db $9D
	db $7D
	db $5D
	db $4D
	db $0D
	db $4D
	db $2D
	db $C9
Song01B:
	db $C1
	db $C0
	db $C2, $61
	db $F2
	db $CD
	dw SongMacro01
	db $CD
	dw SongMacro01
	db $CD
	dw SongMacro01
	db $7D
	db $7D
	db $7D
	db $7D
	db $7D
	db $7D
	db $7D
	db $7D
	db $7D
	db $7D
	db $7D
	db $7D
	db $7D
	db $7D
	db $7D
	db $7D
Song01BLoop:
	db $C2, $91
	db $F2
	db $CD
	dw SongMacro02
	db $CD
	dw SongMacro03
	db $CD
	dw SongMacro02
	db $CD
	dw SongMacro03
	db $CD
	dw SongMacro02
	db $CD
	dw SongMacro03
	db $CD
	dw SongMacro02
	db $EC
	db $AD
	db $AD
	db $AD
	db $F3
	db $03
	db $D6
	db $F2
	db $AD
	db $AD
	db $AD
	db $F3
	db $03
	db $D6
	db $F4
	db $0C
	db $C2, $95
	db $F3
	db $BA
	db $73
	db $D6
	db $23
	db $D6
	db $0C
	db $F2
	db $B9
	db $C2, $91
	db $9D
	db $F3
	db $1D
	db $4D
	db $9D
	db $F2
	db $9D
	db $F3
	db $1D
	db $4D
	db $9D
	db $F2
	db $9D
	db $F3
	db $1D
	db $4D
	db $9D
	db $F2
	db $9D
	db $F3
	db $1D
	db $4D
	db $9D
	db $CD
	dw SongMacro04
	db $CD
	dw SongMacro05
	db $CD
	dw SongMacro04
	db $CD
	dw SongMacro05
	db $F2
	db $7D
	db $BD
	db $F3
	db $2D
	db $7D
	db $F2
	db $7D
	db $BD
	db $F3
	db $2D
	db $7D
	db $F2
	db $7D
	db $BD
	db $F3
	db $2D
	db $7D
	db $F2
	db $7D
	db $BD
	db $F3
	db $2D
	db $7D
	db $F2
	db $6D
	db $AD
	db $F3
	db $1D
	db $6D
	db $F2
	db $6D
	db $AD
	db $F3
	db $1D
	db $6D
	db $F2
	db $6D
	db $AD
	db $F3
	db $1D
	db $6D
	db $F2
	db $6D
	db $AD
	db $F3
	db $1D
	db $6D
	db $F2
	db $6D
	db $AD
	db $F3
	db $1D
	db $4D
	db $7D
	db $AD
	db $F4
	db $1D
	db $4D
	db $6D
	db $4D
	db $1D
	db $F3
	db $AD
	db $7D
	db $4D
	db $0D
	db $0D
	db $EC
	db $F2
	db $AD
	db $AD
	db $AD
	db $F3
	db $03
	db $D6
	db $F2
	db $AD
	db $AD
	db $AD
	db $F3
	db $0B
	db $DD
	db $F2
	db $AD
	db $AD
	db $AD
	db $AD
	db $AD
	db $F3
	db $03
	db $D6
	db $F2
	db $AD
	db $AD
	db $AD
	db $F3
	db $0B
	db $DD
	db $EC
	db $F2
	db $AD
	db $AD
	db $AD
	db $F3
	db $03
	db $D6
	db $F2
	db $AD
	db $AD
	db $AD
	db $F3
	db $0B
	db $F2
	db $AD
	db $AD
	db $AD
	db $AD
	db $AD
	db $AD
	db $F3
	db $03
	db $D6
	db $F2
	db $AD
	db $AD
	db $AD
	db $F3
	db $0B
	db $DD
	db $C2, $97
	db $F2
	db $B9
	db $D9
	db $B1
	db $DB
	db $D6
	db $9D
	db $DC
	db $F3
	db $0B
	db $4C
	db $9A
	db $C3
	dw Song01BLoop
SongMacro01:
	db $7C
	db $7D
	db $7D
	db $7C
	db $7D
	db $7D
	db $7C
	db $7D
	db $7D
	db $7D
	db $7D
	db $7D
	db $7D
	db $C9
SongMacro02:
	db $F2
	db $7C
	db $7D
	db $7D
	db $7C
	db $7D
	db $7D
	db $7C
	db $7D
	db $7D
	db $7C
	db $7D
	db $7D
	db $7C
	db $7D
	db $7D
	db $7C
	db $7D
	db $7D
	db $7C
	db $7D
	db $7D
	db $7C
	db $7D
	db $7D
	db $7C
	db $7D
	db $7D
	db $7C
	db $7D
	db $7D
	db $7C
	db $7D
	db $7D
	db $7C
	db $7D
	db $7D
	db $C9
SongMacro03:
	db $EC
	db $AD
	db $AD
	db $AD
	db $F3
	db $03
	db $D6
	db $F2
	db $AD
	db $AD
	db $AD
	db $F3
	db $0B
	db $DD
	db $C9
SongMacro04:
	db $F2
	db $7D
	db $BD
	db $F3
	db $2D
	db $7D
	db $F2
	db $7D
	db $BD
	db $F3
	db $2D
	db $7D
	db $F2
	db $7D
	db $BD
	db $F3
	db $2D
	db $7D
	db $F2
	db $7D
	db $BD
	db $F3
	db $2D
	db $5D
	db $C9
SongMacro05:
	db $F2
	db $9D
	db $F3
	db $1D
	db $4D
	db $9D
	db $F2
	db $9D
	db $F3
	db $1D
	db $4D
	db $9D
	db $F2
	db $9D
	db $F3
	db $1D
	db $4D
	db $9D
	db $F2
	db $9D
	db $F3
	db $1D
	db $4D
	db $9D
	db $C9
Song01C:
	db $C1, $F0
	db $C2, $40
	db $F2
	db $CD
	dw SongMacro06
	db $CD
	dw SongMacro06
	db $CD
	dw SongMacro06
	db $2D
	db $2D
	db $2D
	db $2D
	db $2D
	db $2D
	db $2D
	db $2D
	db $2D
	db $2D
	db $2D
	db $2D
	db $2D
	db $2D
	db $2D
	db $2D
Song01CLoop:
	db $CD
	dw SongMacro07
	db $CD
	dw SongMacro07
	db $CD
	dw SongMacro07
	db $CD
	dw SongMacro08
	db $CD
	dw SongMacro07
	db $CD
	dw SongMacro07
	db $CD
	dw SongMacro07
	db $CD
	dw SongMacro09
	db $CD
	dw SongMacro07
	db $CD
	dw SongMacro07
	db $CD
	dw SongMacro07
	db $CD
	dw SongMacro08
	db $CD
	dw SongMacro07
	db $CD
	dw SongMacro07
	db $CD
	dw SongMacro07
	db $CD
	dw SongMacro09
	db $CD
	dw SongMacro07
	db $F1
	db $7D
	db $7D
	db $F2
	db $7D
	db $7D
	db $F1
	db $7D
	db $7D
	db $F2
	db $7D
	db $7D
	db $F1
	db $7D
	db $7D
	db $F2
	db $7D
	db $7D
	db $F1
	db $7D
	db $7D
	db $F2
	db $8D
	db $8D
	db $CD
	dw SongMacro0A
	db $CD
	dw SongMacro0B
	db $CD
	dw SongMacro0A
	db $CD
	dw SongMacro0B
	db $CD
	dw SongMacro0A
	db $7B
	db $7B
	db $7B
	db $7C
	db $F2
	db $7D
	db $7D
	db $F1
	db $6B
	db $6B
	db $6B
	db $6B
	db $61
	db $D3
	db $D5
	db $F2
	db $6D
	db $6D
	db $CD
	dw SongMacro09
	db $CD
	dw SongMacro09
	db $F1
	db $5D
	db $5D
	db $F2
	db $5D
	db $5D
	db $F1
	db $5D
	db $F2
	db $5C
	db $5D
	db $F1
	db $5D
	db $F2
	db $5D
	db $5D
	db $F1
	db $5C
	db $5D
	db $F2
	db $5D
	db $F1
	db $5D
	db $5D
	db $5D
	db $F2
	db $5D
	db $5D
	db $F1
	db $5D
	db $F2
	db $5C
	db $5D
	db $F1
	db $5D
	db $F2
	db $5D
	db $5D
	db $F1
	db $5C
	db $5D
	db $F2
	db $5D
	db $5D
	db $CD
	dw SongMacro0C
	db $CD
	dw SongMacro0C
	db $F1
	db $7B
	db $7B
	db $7B
	db $7C
	db $F2
	db $7D
	db $F1
	db $5D
	db $DC
	db $F2
	db $5B
	db $F1
	db $5C
	db $52
	db $D5
	db $F2
	db $7D
	db $7D
	db $C3	
	dw Song01CLoop
SongMacro06:
	db $2C
	db $2D
	db $2D
	db $2C
	db $2D
	db $2D
	db $2C
	db $2D
	db $2D
	db $2D
	db $2D
	db $2D
	db $2D
	db $C9
SongMacro07:
	db $F1
	db $7D
	db $7D
	db $F2
	db $7D
	db $7D
	db $F1
	db $7D
	db $7D
	db $F2
	db $7D
	db $7D
	db $F1
	db $7D
	db $7D
	db $F2
	db $7D
	db $7D
	db $F1
	db $7D
	db $7D
	db $F2
	db $7D
	db $7D
	db $C9
SongMacro08:
	db $F1
	db $5D
	db $5D
	db $F2
	db $5D
	db $5D
	db $F1
	db $5D
	db $5D
	db $F2
	db $5D
	db $5D
	db $F1
	db $5D
	db $5D
	db $F2
	db $5D
	db $5D
	db $F1
	db $5D
	db $5D
	db $F2
	db $5D
	db $5D
	db $C9
SongMacro09:
	db $F1
	db $5D
	db $5D
	db $F2
	db $5D
	db $5D
	db $F1
	db $5D
	db $F2
	db $5C
	db $5D
	db $F1
	db $5D
	db $F2
	db $5D
	db $5D
	db $F1
	db $5C
	db $5D
	db $F2
	db $5D
	db $5D
	db $C9
SongMacro0A:
	db $F1
	db $9B
	db $9B
	db $9B
	db $9B
	db $C9
SongMacro0B:
	db $7B
	db $7B
	db $7B
	db $7C
	db $F2
	db $8D
	db $8D
	db $C9
SongMacro0C:
	db $F1
	db $7B
	db $7B
	db $7B
	db $7C
	db $F2
	db $7D
	db $7D
	db $C9
Song01D:
	db $C1, $01
	db $C2, $61
	db $CD
	dw SongMacro0D
	db $CD
	dw SongMacro0D
	db $CD
	dw SongMacro0D
	db $5C
	db $4D
	db $2D
	db $5C
	db $4D
	db $2D
	db $5D
	db $4D
	db $2D
	db $2D
	db $4D
	db $2D
	db $2D
	db $2D
Song01DLoop:
	db $CD
	dw SongMacro0E
	db $CD
	dw SongMacro0E
	db $CD
	dw SongMacro0E
	db $CD
	dw SongMacro0E
	db $CD
	dw SongMacro0E
	db $CD
	dw SongMacro0E
	db $CD
	dw SongMacro0E
	db $CD
	dw SongMacro0F
	db $CD
	dw SongMacro0E
	db $CD
	dw SongMacro0E
	db $CD
	dw SongMacro0E
	db $CD
	dw SongMacro0E
	db $CD
	dw SongMacro0E
	db $CD
	dw SongMacro0E
	db $CD
	dw SongMacro0E
	db $CD
	dw SongMacro0F
	db $CD
	dw SongMacro0E
	db $5D
	db $2D
	db $2D
	db $2D
	db $4D
	db $2D
	db $2D
	db $2D
	db $5D
	db $2D
	db $2D
	db $2D
	db $4D
	db $4D
	db $4D
	db $4D
	db $CD
	dw SongMacro0E
	db $CD
	dw SongMacro0E
	db $CD
	dw SongMacro0E
	db $CD
	dw SongMacro0E
	db $CD
	dw SongMacro0E
	db $CD
	dw SongMacro0E
	db $CD
	dw SongMacro0E
	db $5D
	db $2D
	db $2D
	db $2D
	db $4D
	db $2D
	db $2D
	db $2D
	db $5D
	db $2D
	db $2D
	db $2D
	db $4D
	db $2D
	db $4D
	db $4D
	db $5D
	db $2D
	db $2D
	db $2D
	db $4D
	db $4D
	db $2D
	db $5D
	db $5D
	db $4D
	db $4D
	db $4C
	db $2D
	db $4D
	db $4D
	db $5D
	db $2D
	db $4D
	db $4D
	db $4D
	db $4D
	db $2D
	db $5D
	db $5D
	db $4D
	db $4D
	db $4C
	db $4D
	db $4D
	db $4D
	db $5D
	db $2D
	db $2D
	db $2D
	db $4D
	db $4D
	db $2D
	db $5D
	db $5D
	db $4D
	db $4D
	db $4C
	db $2D
	db $4D
	db $5D
	db $ED
	db $2D
	db $4D
	db $4D
	db $4D
	db $4D
	db $2D
	db $5D
	db $5D
	db $4D
	db $4D
	db $4C
	db $4D
	db $4D
	db $4D
	db $CD
	dw SongMacro0E
	db $CD
	dw SongMacro0E
	db $5D
	db $2D
	db $2D
	db $2D
	db $4D
	db $2D
	db $2D
	db $2D
	db $5D
	db $2D
	db $2D
	db $2D
	db $4D
	db $2D
	db $2D
	db $5D
	db $ED
	db $2D
	db $4D
	db $2D
	db $2D
	db $2D
	db $5D
	db $2D
	db $5D
	db $4D
	db $2D
	db $2D
	db $4D
	db $2D
	db $2D
	db $2D
	db $C3
	dw Song01DLoop
SongMacro0D:
	db $5C
	db $2D
	db $2D
	db $5C
	db $2D
	db $2D
	db $5C
	db $2D
	db $2D
	db $5D
	db $2D
	db $2D
	db $2D
	db $C9
SongMacro0E:
	db $5D
	db $2D
	db $2D
	db $2D
	db $4D
	db $2D
	db $2D
	db $2D
	db $5D
	db $2D
	db $2D
	db $2D
	db $4D
	db $2D
	db $2D
	db $2D
	db $C9
SongMacro0F:	
	db $5D
	db $2D
	db $2D
	db $2D
	db $4D
	db $4D
	db $2D
	db $5D
	db $5D
	db $4D
	db $4D
	db $4C
	db $4D
	db $4D
	db $4D
	db $C9
	
Song02:
	dw Song02A
	dw Song02B
	dw Song02C
	dw Song02D
Song02A:
	db $C4, %11111111
	db $C0, 188
	db $C1, $C0
Song02ALoop:
	db $CD
	dw SongMacro10
	db $C3
	dw Song02ALoop
Song02B:
	db $C1, $C0
	db $EE
Song02BLoop:
	db $CD
	dw SongMacro10
	db $C3
	dw Song02BLoop
SongMacro10:
	db $C2, $93
	db $F2
	db $93
	db $94
	db $93
	db $94
	db $74
	db $94
	db $F3
	db $04
	db $F2
	db $B4
	db $94
	db $74
	db $93
	db $94
	db $93
	db $94
	db $24
	db $44
	db $74
	db $24
	db $44
	db $74
	db $93
	db $94
	db $93
	db $94
	db $74
	db $94
	db $F3
	db $04
	db $F2
	db $B4
	db $94
	db $74
	db $93
	db $94
	db $93
	db $94
	db $24
	db $44
	db $74
	db $24
	db $44
	db $74
	db $C2, $97
	db $F3
	db $91
	db $44
	db $93
	db $74
	db $7A
	db $74
	db $64
	db $44
	db $23
	db $44
	db $D9
	db $54
	db $44
	db $24
	db $54
	db $44
	db $24
	db $74
	db $54
	db $44
	db $74
	db $54
	db $44
	db $91
	db $44
	db $93
	db $74
	db $7A
	db $74
	db $64
	db $44
	db $23
	db $44
	db $D9
	db $54
	db $44
	db $24
	db $54
	db $44
	db $24
	db $74
	db $54
	db $44
	db $74
	db $54
	db $44
	db $41
	db $DB
	db $54
	db $51
	db $DB
	db $74
	db $D2
	db $D4
	db $5A
	db $44
	db $49
	db $41
	db $DB
	db $54
	db $D1
	db $DB
	db $74
	db $71
	db $DB
	db $84
	db $D9
	db $C9
Song02C:
	db $C1, $E0
	db $C2, $40
Song02CLoop:
	db $F1
	db $CD
	dw SongMacro11
	db $CD
	dw SongMacro11
	db $CD
	dw SongMacro11
	db $CD
	dw SongMacro11
	db $CD
	dw SongMacro11
	db $CD
	dw SongMacro11
	db $CD
	dw SongMacro11
	db $CD
	dw SongMacro12
	db $CD
	dw SongMacro11
	db $CD
	dw SongMacro11
	db $CD
	dw SongMacro11
	db $CD
	dw SongMacro12
	db $F2
	db $CD
	dw SongMacro13
	db $CD
	dw SongMacro13
	db $CD
	dw SongMacro13
	db $CD
	dw SongMacro13
	db $CD
	dw SongMacro13
	db $CD
	dw SongMacro13
	db $CD
	dw SongMacro13
	db $43
	db $44
	db $24
	db $F1
	db $B4
	db $F2
	db $24
	db $44
	db $F1
	db $B4
	db $F2
	db $44
	db $F1
	db $44
	db $64
	db $84
	db $C3
	dw Song02CLoop
SongMacro11:
	db $93
	db $94
	db $93
	db $94
	db $93
	db $94
	db $93
	db $94
	db $C9
SongMacro12:
	db $53
	db $54
	db $53
	db $54
	db $73
	db $74
	db $73
	db $74
	db $C9
SongMacro13:
	db $43
	db $44
	db $24
	db $F1
	db $B4
	db $F2
	db $24
	db $43
	db $44
	db $24
	db $F1
	db $B4
	db $F2
	db $24
	db $C9
Song02D:
	db $C1, $01
	db $C2, $61
Song02DLoop:
	db $CD
	dw SongMacro14
	db $CD
	dw SongMacro14
	db $CD
	dw SongMacro14
	db $CD
	dw SongMacro15
	db $CD
	dw SongMacro14
	db $CD
	dw SongMacro14
	db $CD
	dw SongMacro14
	db $CD
	dw SongMacro15
	db $CD
	dw SongMacro14
	db $CD
	dw SongMacro14
	db $CD
	dw SongMacro14
	db $CD
	dw SongMacro15
	db $CD
	dw SongMacro14
	db $CD
	dw SongMacro14
	db $CD
	dw SongMacro14
	db $CD
	dw SongMacro14
	db $CD
	dw SongMacro14
	db $CD
	dw SongMacro14
	db $CD
	dw SongMacro14
	db $53
	db $24
	db $43
	db $24
	db $54
	db $44
	db $54
	db $44
	db $44
	db $44
	db $C3
	dw Song02DLoop
SongMacro14:
	db $53
	db $24
	db $43
	db $24
	db $53
	db $24
	db $43
	db $24
	db $C9
SongMacro15:
	db $53
	db $24
	db $43
	db $24
	db $54
	db $44
	db $54
	db $44
	db $24
	db $44
	db $C9

Song03:
	dw Song03A
	dw Song03B
	dw Song03C
	dw Song03D
Song03A:
	db $C4, %11111111
	db $C0, 188
	db $C1, $80
	db $C2, $97
	db $E9
Song03ALoop:
	db $F4
	db $49
	db $29
	db $19
	db $09
	db $49
	db $29
	db $19
	db $09
	db $C2, $95
	db $CD
	dw SongMacro16
	db $61
	db $DC
	db $64
	db $64
	db $65
	db $CD
	dw SongMacro16
	db $DA
	db $DC
	db $64
	db $64
	db $64
	db $64
	db $65
	db $CD
	dw SongMacro17
	db $CD
	dw SongMacro18
	db $F3
	db $A9
	db $CD
	dw SongMacro17
	db $B2
	db $D5
	db $92
	db $D5
	db $BB
	db $BA
	db $DC
	db $9D
	db $8D
	db $6D
	db $4D
	db $3D
	db $1D
	db $CD
	dw SongMacro16
	db $D1
	db $DC
	db $64
	db $64
	db $65
	db $CD
	dw SongMacro16
	db $6A
	db $DC
	db $64
	db $64
	db $64
	db $64
	db $65
	db $CD
	dw SongMacro17
	db $CD
	dw SongMacro18
	db $F3
	db $A9
	db $CD
	dw SongMacro17
	db $B2
	db $D5
	db $F4
	db $62
	db $D5
	db $F3
	db $BB
	db $D9
	db $C3
	dw Song03ALoop
SongMacro16:
	db $F2
	db $BC
	db $F3
	db $4C
	db $9C
	db $8B
	db $F2
	db $BC
	db $F3
	db $4C
	db $9C
	db $8A
	db $BB
	db $4B
	db $8B
	db $62
	db $D5
	db $8B
	db $6C
	db $C9
SongMacro17:
	db $1C
	db $2C
	db $4C
	db $1C
	db $2C
	db $4C
	db $9C
	db $F4
	db $1C
	db $22
	db $D5
	db $12
	db $D5
	db $F3
	db $9B
	db $C9
SongMacro18:
	db $A2
	db $D5
	db $F4
	db $72
	db $D5
	db $3B
	db $C9
Song03B:
	db $C1, $C0
	db $E9
Song03BLoop:
	db $C2, $63
	db $CD
	dw SongMacro19
	db $CD
	dw SongMacro19
	db $CD
	dw SongMacro1A
	db $CD
	dw SongMacro1B
	db $4D
	db $F3
	db $BD
	db $8D
	db $BD
	db $F4
	db $4D
	db $F3
	db $BD
	db $8D
	db $BD
	db $F4
	db $4D
	db $F3
	db $BD
	db $8D
	db $BD
	db $F4
	db $4D
	db $F3
	db $BD
	db $8D
	db $BD
	db $CD
	dw SongMacro19
	db $CD
	dw SongMacro1A
	db $CD
	dw SongMacro1B
	db $C2, $95
	db $CD
	dw SongMacro1C
	db $21
	db $D4
	db $24
	db $24
	db $24
	db $CD
	dw SongMacro1C
	db $D1
	db $24
	db $24
	db $24
	db $24
	db $F2
	db $12
	db $D5
	db $82
	db $D5
	db $F3
	db $1C
	db $4C
	db $CD
	dw SongMacro1D
	db $CD
	dw SongMacro1E
	db $7B
	db $5B
	db $3B
	db $F2
	db $AB
	db $CD
	dw SongMacro1F
	db $CD
	dw SongMacro1D
	db $31
	db $D4
	db $3B
	db $39
	db $CD
	dw SongMacro1C
	db $D1
	db $D4
	db $24
	db $24
	db $24
	db $CD
	dw SongMacro1C
	db $21
	db $24
	db $24
	db $24
	db $24
	db $F2
	db $CD
	dw SongMacro1F
	db $CD
	dw SongMacro1D
	db $CD
	dw SongMacro1E
	db $3D
	db $5D
	db $3D
	db $5D
	db $7D
	db $8D
	db $7D
	db $8D
	db $AD
	db $F4
	db $0D
	db $F3
	db $AD
	db $F4
	db $0D
	db $1D
	db $3D
	db $2D
	db $3D
	db $F2
	db $CD
	dw SongMacro1F
	db $CD
	dw SongMacro1D
	db $32
	db $D5
	db $92
	db $D5
	db $3B
	db $3D
	db $4D
	db $3D
	db $4D
	db $6D
	db $8D
	db $6D
	db $8D
	db $9D
	db $BD
	db $9D
	db $BD
	db $F4
	db $1D
	db $3D
	db $1D
	db $3D
	db $C3
	dw Song03BLoop
SongMacro19:
	db $F4
	db $4D
	db $F3
	db $BD
	db $8D
	db $BD
	db $F4
	db $4D
	db $F3
	db $BD
	db $8D
	db $BD
	db $F4
	db $4D
	db $F3
	db $BD
	db $8D
	db $BD
	db $F4
	db $4D
	db $F3
	db $BD
	db $8D
	db $BD
	db $C9
SongMacro1A:
	db $F4
	db $4D
	db $1D
	db $F3
	db $9D
	db $F4
	db $1D
	db $4D
	db $1D
	db $F3
	db $9D
	db $F4
	db $1D
	db $4D
	db $1D
	db $F3
	db $9D
	db $F4
	db $1D
	db $4D
	db $1D
	db $F3
	db $9D
	db $F4
	db $1D
	db $C9
SongMacro1B:
	db $4D
	db $0D
	db $F3
	db $9D
	db $F4
	db $0D
	db $4D
	db $0D
	db $F3
	db $9D
	db $F4
	db $0D
	db $4D
	db $0D
	db $F3
	db $9D
	db $F4
	db $0D
	db $4D
	db $0D
	db $F3
	db $9D
	db $F4
	db $0D
	db $C9
SongMacro1C:
	db $F2
	db $8C
	db $8C
	db $F3
	db $1C
	db $F2
	db $BB
	db $8C
	db $8C
	db $F3
	db $1C
	db $F2
	db $BA
	db $F3
	db $3B
	db $F2
	db $BB
	db $F3
	db $1B
	db $F2
	db $92
	db $D5
	db $F3
	db $4B
	db $2C
	db $C9
SongMacro1D:
	db $62
	db $D5
	db $42
	db $D5
	db $1B
	db $C9
SongMacro1E:
	db $22
	db $D5
	db $A2
	db $D5
	db $7B
	db $C9
SongMacro1F:
	db $82
	db $D5
	db $8C
	db $82
	db $D5
	db $F3
	db $4C
	db $C9
Song03C:
	db $C1, $E0
	db $C2, $40
	db $F1
	db $4A
	db $9B
	db $BC
	db $F2
	db $BC
Song03CLoop:
	db $CD
	dw SongMacro20
	db $CD
	dw SongMacro20
	db $CD
	dw SongMacro21
	db $CD
	dw SongMacro21
	db $CD
	dw SongMacro22
	db $CD
	dw SongMacro21
	db $CD
	dw SongMacro21
	db $CD
	dw SongMacro22
	db $CD
	dw SongMacro23
	db $BC
	db $F2
	db $4C
	db $F1
	db $BC
	db $F2
	db $4C
	db $F1
	db $BC
	db $F2
	db $4C
	db $F1
	db $BC
	db $F2
	db $4C
	db $CD
	dw SongMacro21
	db $CD
	dw SongMacro22
	db $CD
	dw SongMacro21
	db $CD
	dw SongMacro21
	db $CD
	dw SongMacro22
	db $CD
	dw SongMacro23
	db $C3
	dw Song03CLoop
SongMacro20:
	db $F1
	db $4C
	db $F2
	db $4C
	db $F1
	db $4C
	db $F2
	db $4C
	db $F1
	db $4C
	db $F2
	db $4C
	db $F1
	db $4C
	db $F2
	db $4C
	db $F1
	db $4C
	db $F2
	db $2C
	db $F1
	db $4C
	db $F2
	db $2C
	db $F1
	db $4C
	db $F2
	db $2C
	db $F1
	db $4C
	db $F2
	db $2C
	db $F1
	db $4C
	db $F2
	db $1C
	db $F1
	db $4C
	db $F2
	db $1C
	db $F1
	db $4C
	db $F2
	db $1C
	db $F1
	db $4C
	db $F2
	db $1C
	db $F1
	db $4C
	db $F2
	db $0C
	db $F1
	db $4C
	db $F2
	db $0C
	db $F1
	db $4C
	db $F2
	db $0C
	db $F1
	db $4C
	db $F2
	db $0C
	db $C9
SongMacro21:
	db $F1
	db $BC
	db $F2
	db $4C
	db $F1
	db $BC
	db $F2
	db $4C
	db $F1
	db $BC
	db $F2
	db $4C
	db $F1
	db $BC
	db $F2
	db $4C
	db $C9
SongMacro22:
	db $F1
	db $9C
	db $F2
	db $2C
	db $F1
	db $9C
	db $F2
	db $2C
	db $F1
	db $9C
	db $F2
	db $2C
	db $F1
	db $9C
	db $F2
	db $2C
	db $F1
	db $9C
	db $F2
	db $2C
	db $F1
	db $9C
	db $F2
	db $2C
	db $F1
	db $9C
	db $F2
	db $2C
	db $F1
	db $9C
	db $F2
	db $2C
	db $C9
SongMacro23:
	db $1C
	db $1C
	db $1C
	db $1C
	db $1C
	db $1C
	db $1C
	db $1C
	db $1C
	db $1C
	db $1C
	db $1C
	db $1C
	db $1C
	db $1C
	db $1C
	db $F1
	db $AC
	db $AC
	db $AC
	db $AC
	db $AC
	db $AC
	db $AC
	db $AC
	db $AC
	db $AC
	db $AC
	db $AC
	db $AC
	db $AC
	db $AC
	db $AC
	db $F2
	db $1C
	db $1C
	db $1C
	db $1C
	db $1C
	db $1C
	db $1C
	db $1C
	db $1C
	db $1C
	db $1C
	db $1C
	db $1C
	db $1C
	db $1C
	db $1C
	db $F1
	db $BC
	db $BC
	db $BC
	db $BC
	db $BC
	db $BC
	db $BC
	db $BC
	db $BC
	db $BC
	db $BC
	db $BC
	db $BC
	db $BC
	db $BC
	db $BC
	db $C9
Song03D:
	db $C1, $01
	db $C2, $61
	db $5D
	db $1D
	db $4D
	db $1D
	db $4D
	db $4D
	db $1D
	db $5D
	db $4D
	db $4D
	db $4C
	db $4D
	db $4D
	db $4C
Song03DLoop:
	db $CD
	dw SongMacro24
	db $CD
	dw SongMacro24
	db $CD
	dw SongMacro24
	db $5D
	db $1D
	db $1D
	db $1D
	db $5D
	db $1D
	db $1D
	db $1D
	db $4D
	db $4D
	db $4D
	db $4D
	db $4D
	db $4D
	db $4D
	db $4D
	db $CD
	dw SongMacro25
	db $CD
	dw SongMacro25
	db $CD
	dw SongMacro25
	db $5D
	db $1D
	db $1D
	db $1D
	db $4D
	db $1D
	db $1D
	db $1D
	db $4C
	db $4C
	db $4C
	db $4D
	db $4D
	db $CD
	dw SongMacro25
	db $CD
	dw SongMacro25
	db $CD
	dw SongMacro25
	db $CD
	dw SongMacro25
	db $CD
	dw SongMacro25
	db $CD
	dw SongMacro25
	db $CD
	dw SongMacro25
	db $CD
	dw SongMacro26
	db $CD
	dw SongMacro24
	db $CD
	dw SongMacro24
	db $CD
	dw SongMacro24
	db $CD
	dw SongMacro27
	db $CD
	dw SongMacro24
	db $CD
	dw SongMacro24
	db $CD
	dw SongMacro24
	db $CD
	dw SongMacro28
	db $CD
	dw SongMacro25
	db $CD
	dw SongMacro25
	db $CD
	dw SongMacro25
	db $CD
	dw SongMacro25
	db $CD
	dw SongMacro25
	db $CD
	dw SongMacro25
	db $CD
	dw SongMacro25
	db $CD
	dw SongMacro26
	db $CD
	dw SongMacro24
	db $CD
	dw SongMacro24
	db $CD
	dw SongMacro24
	db $CD
	dw SongMacro27
	db $CD
	dw SongMacro24
	db $CD
	dw SongMacro24
	db $CD
	dw SongMacro24
	db $CD
	dw SongMacro28
	db $C3
	dw Song03DLoop
SongMacro24:
	db $5D
	db $1D
	db $1D
	db $1D
	db $5D
	db $1D
	db $1D
	db $1D
	db $5D
	db $1D
	db $1D
	db $1D
	db $5D
	db $1D
	db $1D
	db $1D
	db $C9
SongMacro25:
	db $5D
	db $1D
	db $1D
	db $1D
	db $4D
	db $1D
	db $1D
	db $1D
	db $5D
	db $1D
	db $1D
	db $1D
	db $4D
	db $1D
	db $1D
	db $1D
	db $C9
SongMacro26:
	db $5D
	db $1D
	db $1D
	db $1D
	db $4D
	db $1D
	db $1D
	db $1D
	db $4D
	db $4D
	db $4D
	db $4D
	db $4D
	db $4D
	db $4D
	db $1D
	db $C9
SongMacro27:
	db $5D
	db $1D
	db $1D
	db $1D
	db $5D
	db $1D
	db $1D
	db $1D
	db $5D
	db $1D
	db $1D
	db $1D
	db $5D
	db $1D
	db $5D
	db $1D
	db $C9
SongMacro28:
	db $5D
	db $1D
	db $1D
	db $1D
	db $5D
	db $1D
	db $1D
	db $1D
	db $4D
	db $4D
	db $4D
	db $1D
	db $4D
	db $4D
	db $4D
	db $1D
	db $C9
	
Song04:
	dw Song04A
	dw Song04B
	dw Song04C
	dw Song04D
Song04A:
	db $C4, %11111111
	db $C1, $80
	db $C2, $65
Song04ALoop:
	db $C0, 166
	db $F3
	db $CD
	dw SongMacro29
	db $CD
	dw SongMacro29
	db $CD
	dw SongMacro29
	db $CD
	dw SongMacro2A
	db $CD
	dw SongMacro2B
	db $CD
	dw SongMacro2C
	db $CD
	dw SongMacro2D
	db $CD
	dw SongMacro2E
	db $CD
	dw SongMacro29
	db $CD
	dw SongMacro29
	db $CD
	dw SongMacro29
	db $CD
	dw SongMacro29
	db $CD
	dw SongMacro2F
	db $CD
	dw SongMacro30
	db $C0
	db $90
	db $CD
	dw SongMacro31
	db $C0
	db $A6
	db $CD
	dw SongMacro32
	db $C3
	dw Song04ALoop
Song04B:
	db $C1
	db $C0
	db $C2
	db $65
	db $EE
Song04BLoop:
	db $F3
	db $CD
	dw SongMacro29
	db $CD
	dw SongMacro29
	db $CD
	dw SongMacro29
	db $CD
	dw SongMacro2A
	db $CD
	dw SongMacro2B
	db $CD
	dw SongMacro2C
	db $CD
	dw SongMacro2D
	db $CD
	dw SongMacro2E
	db $CD
	dw SongMacro29
	db $CD
	dw SongMacro29
	db $CD
	dw SongMacro29
	db $CD
	dw SongMacro29
	db $CD
	dw SongMacro2F
	db $CD
	dw SongMacro30
	db $CD
	dw SongMacro31
	db $CD
	dw SongMacro32
	db $C3
	dw Song04BLoop
SongMacro29:
	db $7C
	db $6C
	db $F4
	db $0C
	db $F3
	db $6C
	db $7C
	db $6C
	db $F4
	db $0C
	db $F3
	db $6C
	db $C9
SongMacro2A:
	db $7C
	db $6C
	db $F4
	db $0C
	db $F3
	db $6C
	db $3C
	db $0C
	db $2C
	db $F2
	db $BC
	db $C9
SongMacro2B:
	db $F3
	db $0C
	db $F2
	db $BC
	db $F3
	db $0C
	db $3C
	db $F4
	db $0C
	db $F3
	db $7C
	db $3C
	db $0C
	db $C9
SongMacro2C:
	db $6C
	db $3C
	db $0C
	db $F2
	db $7C
	db $F3
	db $7C
	db $3C
	db $0C
	db $F2
	db $7C
	db $C9
SongMacro2D:
	db $F3
	db $7C
	db $6C
	db $7C
	db $6C
	db $7C
	db $6C
	db $7C
	db $6C
	db $C9
SongMacro2E:
	db $7C
	db $6C
	db $7C
	db $6C
	db $7C
	db $6C
	db $7C
	db $6C
	db $C9
SongMacro2F:
	db $7C
	db $6C
	db $F4
	db $0C
	db $F3
	db $6C
	db $F4
	db $3C
	db $0C
	db $6C
	db $3C
	db $C9
SongMacro30:
	db $7C
	db $3C
	db $0C
	db $7C
	db $3C
	db $0C
	db $7C
	db $3C
	db $C9
SongMacro31:
	db $0C
	db $7C
	db $3C
	db $0C
	db $7C
	db $3C
	db $0C
	db $7C
	db $C9
SongMacro32:
	db $74
	db $74
	db $74
	db $7D
	db $7D
	db $75
	db $75
	db $75
	db $C9
Song04C:
	db $C1
	db $E0
	db $C2
	db $40
Song04CLoop:
	db $F2
	db $0B
	db $0B
	db $0B
	db $0B
	db $F1
	db $AB
	db $AB
	db $AB
	db $AB
	db $F2
	db $0B
	db $0B
	db $0B
	db $0B
	db $0B
	db $0B
	db $F1
	db $AB
	db $AB
	db $8B
	db $8B
	db $8B
	db $8B
	db $8B
	db $8B
	db $8B
	db $8B
	db $7B
	db $F2
	db $6B
	db $5B
	db $4B
	db $3B
	db $2B
	db $0B
	db $F1
	db $BB
	db $F2
	db $0B
	db $0B
	db $0B
	db $0B
	db $F1
	db $AB
	db $AB
	db $AB
	db $AB
	db $8B
	db $8B
	db $8B
	db $8B
	db $7B
	db $7B
	db $7B
	db $7B
	db $8B
	db $8B
	db $8B
	db $8B
	db $7B
	db $F2
	db $6B
	db $5B
	db $4B
	db $3B
	db $2B
	db $1B
	db $0B
	db $F1
	db $7A
	db $C3
	dw Song04CLoop
Song04D:
	db $C1
	db $01
	db $C2
	db $61
Song04DLoop:
	db $CD
	dw SongMacro33
	db $CD
	dw SongMacro33
	db $CD
	dw SongMacro33
	db $CD
	dw SongMacro33
	db $CD
	dw SongMacro33
	db $CD
	dw SongMacro33
	db $CD
	dw SongMacro33
	db $CD
	dw SongMacro33
	db $CD
	dw SongMacro34
	db $CD
	dw SongMacro34
	db $CD
	dw SongMacro34
	db $CD
	dw SongMacro34
	db $CD
	dw SongMacro34
	db $CD
	dw SongMacro34
	db $CD
	dw SongMacro34
	db $5A
	db $C3
	dw Song04DLoop
SongMacro33:
	db $5B
	db $4B
	db $5B
	db $4B
	db $C9
SongMacro34:
	db $5C
	db $2C
	db $4B
	db $5C
	db $2C
	db $4B
	db $C9

Song05:
	dw Song05A
	dw Song05B
	dw Song05C
	dw Song05D
Song05A:
	db $C4, %11111111
	db $C0, 176
	db $C1, $80
	db $C2, $95
Song05ALoop:
	db $CD
	dw SongMacro35
	db $C3
	dw Song05ALoop
Song05B:
	db $C1, $40
	db $C2, $95
	db $EE
Song05BLoop:
	db $CD
	dw SongMacro35
	db $C3
	dw Song05BLoop
SongMacro35:
	db $F3
	db $4A
	db $DC
	db $1D
	db $2D
	db $4D
	db $9C
	db $4D
	db $42
	db $D5
	db $2D
	db $1D
	db $2C
	db $1C
	db $F2
	db $9D
	db $B3
	db $D6
	db $F3
	db $4A
	db $DC
	db $1D
	db $2D
	db $4D
	db $9C
	db $4D
	db $D2
	db $D5
	db $2D
	db $1D
	db $2C
	db $1C
	db $F2
	db $9D
	db $B3
	db $D6
	db $F3
	db $01
	db $D4
	db $F2
	db $9D
	db $BD
	db $F3
	db $0D
	db $2D
	db $F2
	db $B3
	db $D6
	db $73
	db $D6
	db $BA
	db $DC
	db $91
	db $D4
	db $9D
	db $BD
	db $F3
	db $0D
	db $2D
	db $4A
	db $DD
	db $4D
	db $6D
	db $8D
	db $9D
	db $BD
	db $F4
	db $1D
	db $2D
	db $4A
	db $DC
	db $1D
	db $2D
	db $4D
	db $9C
	db $4D
	db $42
	db $D5
	db $2D
	db $1D
	db $2C
	db $1C
	db $F3
	db $9D
	db $B3
	db $D6
	db $F4
	db $4A
	db $DC
	db $1D
	db $2D
	db $4D
	db $9C
	db $4D
	db $D2
	db $D5
	db $2D
	db $1D
	db $2C
	db $1C
	db $F3
	db $9D
	db $B3
	db $D6
	db $F4
	db $0B
	db $5C
	db $7B
	db $92
	db $D5
	db $BB
	db $F5
	db $0C
	db $F4
	db $7B
	db $42
	db $D5
	db $32
	db $D5
	db $B2
	db $D5
	db $9B
	db $89
	db $F2
	db $BD
	db $F3
	db $1D
	db $F2
	db $BD
	db $F3
	db $1D
	db $41
	db $D4
	db $F2
	db $9D
	db $BD
	db $9D
	db $BD
	db $F3
	db $22
	db $D5
	db $7B
	db $2C
	db $F2
	db $BD
	db $F3
	db $1D
	db $F2
	db $BD
	db $F3
	db $1D
	db $41
	db $D4
	db $F2
	db $9D
	db $BD
	db $9D
	db $BD
	db $F3
	db $22
	db $D5
	db $7B
	db $2C
	db $C9
Song05C:
	db $C1, $E0
	db $C2, $40
Song05CLoop:
	db $CD
	dw SongMacro36
	db $CD
	dw SongMacro37
	db $CD
	dw SongMacro36
	db $CD
	dw SongMacro37
	db $CD
	dw SongMacro38
	db $CD
	dw SongMacro37
	db $CD
	dw SongMacro38
	db $F1
	db $4D
	db $4D
	db $BD
	db $BD
	db $4D
	db $4D
	db $BD
	db $BD
	db $4D
	db $4D
	db $BD
	db $BD
	db $4D
	db $4D
	db $6D
	db $8D
	db $CD
	dw SongMacro39
	db $CD
	dw SongMacro3A
	db $F1
	db $CD
	dw SongMacro39
	db $CD
	dw SongMacro3A
	db $F1
	db $5D
	db $F2
	db $0D
	db $5D
	db $0D
	db $F1
	db $5D
	db $F2
	db $0D
	db $5D
	db $0D
	db $F1
	db $5D
	db $F2
	db $0D
	db $5D
	db $0D
	db $F1
	db $5D
	db $F2
	db $0D
	db $5D
	db $0D
	db $CD
	dw SongMacro3A
	db $F1
	db $BD
	db $F2
	db $6D
	db $BD
	db $6D
	db $F1
	db $BD
	db $F2
	db $6D
	db $BD
	db $6D
	db $F1
	db $BD
	db $F2
	db $6D
	db $BD
	db $6D
	db $F1
	db $BD
	db $F2
	db $6D
	db $BD
	db $6D
	db $4D
	db $BD
	db $F3
	db $4D
	db $F2
	db $BD
	db $4D
	db $BD
	db $F3
	db $4D
	db $F2
	db $BD
	db $4D
	db $BD
	db $F3
	db $4D
	db $F2
	db $BD
	db $4D
	db $BD
	db $F3
	db $4D
	db $F2
	db $BD
	db $CD
	dw SongMacro36
	db $CD
	dw SongMacro37
	db $CD
	dw SongMacro36
	db $CD
	dw SongMacro37
	db $C3
	dw Song05CLoop
SongMacro36:
	db $F1
	db $9D
	db $9D
	db $F2
	db $4D
	db $4D
	db $F1
	db $9D
	db $9D
	db $F2
	db $4D
	db $4D
	db $F1
	db $9D
	db $9D
	db $F2
	db $4D
	db $4D
	db $F1
	db $9D
	db $9D
	db $F2
	db $4D
	db $4D
	db $C9
SongMacro37:
	db $F1
	db $7D
	db $7D
	db $F2
	db $2D
	db $2D
	db $F1
	db $7D
	db $7D
	db $F2
	db $2D
	db $2D
	db $F1
	db $7D
	db $7D
	db $F2
	db $2D
	db $2D
	db $F1
	db $7D
	db $7D
	db $F2
	db $2D
	db $2D
	db $C9
SongMacro38:
	db $F1
	db $5D
	db $5D
	db $F2
	db $0D
	db $0D
	db $F1
	db $5D
	db $5D
	db $F2
	db $0D
	db $0D
	db $F1
	db $5D
	db $5D
	db $F2
	db $0D
	db $0D
	db $F1
	db $5D
	db $5D
	db $F2
	db $0D
	db $0D
	db $C9
SongMacro39:
	db $9D
	db $F2
	db $4D
	db $9D
	db $4D
	db $F1
	db $9D
	db $F2
	db $4D
	db $9D
	db $4D
	db $F1
	db $9D
	db $F2
	db $4D
	db $9D
	db $4D
	db $F1
	db $9D
	db $F2
	db $4D
	db $9D
	db $4D
	db $C9
SongMacro3A:
	db $F1
	db $7D
	db $F2
	db $2D
	db $7D
	db $2D
	db $F1
	db $7D
	db $F2
	db $2D
	db $7D
	db $2D
	db $F1
	db $7D
	db $F2
	db $2D
	db $7D
	db $2D
	db $F1
	db $7D
	db $F2
	db $2D
	db $7D
	db $2D
	db $C9
Song05D:
	db $C1, $01
	db $C2, $61
Song05DLoop:
	db $CD
	dw SongMacro3B
	db $CD
	dw SongMacro3B
	db $CD
	dw SongMacro3B
	db $CD
	dw SongMacro3B
	db $CD
	dw SongMacro3B
	db $CD
	dw SongMacro3B
	db $CD
	dw SongMacro3B
	db $5D
	db $1D
	db $1D
	db $1D
	db $1D
	db $1D
	db $1D
	db $1D
	db $5D
	db $1D
	db $4D
	db $1D
	db $4D
	db $4D
	db $1D
	db $4D
	db $CD
	dw SongMacro3C
	db $CD
	dw SongMacro3C
	db $CD
	dw SongMacro3C
	db $CD
	dw SongMacro3C
	db $CD
	dw SongMacro3D
	db $CD
	dw SongMacro3D
	db $CD
	dw SongMacro3D
	db $5D
	db $1D
	db $4D
	db $1D
	db $4D
	db $4D
	db $1D
	db $4D
	db $4D
	db $4D
	db $4D
	db $1D
	db $4D
	db $4D
	db $4D
	db $4D
	db $CD
	dw SongMacro3E
	db $CD
	dw SongMacro3E
	db $CD
	dw SongMacro3E
	db $5D
	db $1D
	db $1D
	db $1D
	db $1D
	db $1D
	db $1D
	db $1D
	db $4D
	db $1D
	db $1D
	db $1D
	db $4D
	db $1D
	db $4D
	db $4D
	db $C3
	dw Song05DLoop
SongMacro3B:
	db $5D
	db $1D
	db $1D
	db $1D
	db $1D
	db $1D
	db $1D
	db $1D
	db $1D
	db $1D
	db $1D
	db $1D
	db $1D
	db $1D
	db $1D
	db $1D
	db $C9
SongMacro3C:
	db $5D
	db $1D
	db $1D
	db $1D
	db $1D
	db $1D
	db $1D
	db $1D
	db $1D
	db $1D
	db $1D
	db $1D
	db $4D
	db $1D
	db $1D
	db $1D
	db $C9
SongMacro3D:
	db $5D
	db $1D
	db $1D
	db $1D
	db $4D
	db $1D
	db $1D
	db $1D
	db $5D
	db $1D
	db $1D
	db $1D
	db $4D
	db $1D
	db $1D
	db $1D
	db $C9
SongMacro3E:
	db $5D
	db $1D
	db $1D
	db $1D
	db $1D
	db $1D
	db $1D
	db $1D
	db $4D
	db $1D
	db $1D
	db $1D
	db $1D
	db $1D
	db $1D
	db $1D
	db $C9
	
Song06:
	dw Song06A
	dw Song06B
	dw Song06C
	dw Song06D
Song06A:
	db $C4, %11111111
	db $C0, 176
	db $C1, $40
	db $C2, $93
	db $F3
	db $7C
	db $7D
	db $7D
	db $5D
	db $5C
	db $4C
	db $4C
	db $4D
	db $3C
	db $3C
	db $7C
	db $7D
	db $7D
	db $5D
	db $5C
	db $4C
	db $4C
	db $4D
	db $3C
	db $3C
	db $F4
	db $0C
	db $0D
	db $0D
	db $F3
	db $AD
	db $AC
	db $9C
	db $9C
	db $9D
	db $8C
	db $8C
	db $F4
	db $0C
	db $0D
	db $0D
	db $F3
	db $AD
	db $AC
	db $9C
	db $9C
	db $9D
	db $8C
	db $8C
	db $7C
	db $7D
	db $7D
	db $7D
	db $7D
	db $7D
	db $7C
	db $7C
	db $7D
	db $7C
	db $7C
	db $7C
	db $7D
	db $7D
	db $7D
	db $7D
	db $7D
	db $7C
	db $7C
	db $7D
	db $7C
	db $7C
Song06ALoop:
	db $CD
	dw SongMacro3F
	db $C2, $97
	db $F2
	db $A9
	db $C2, $93
	db $CD
	dw SongMacro40
	db $73
	db $D6
	db $7D
	db $71
	db $D4
	db $73
	db $D6
	db $7D
	db $71
	db $D4
	db $CD
	dw SongMacro41
	db $C2, $97
	db $39
	db $C2, $93
	db $CD
	dw SongMacro42
	db $C3
	dw Song06ALoop
Song06B:
	db $C1, $00
	db $C2, $97
	db $F3
	db $09
	db $09
	db $59
	db $59
	db $2C
	db $2D
	db $2D
	db $2D
	db $2D
	db $2D
	db $2C
	db $2C
	db $2D
	db $2C
	db $2C
	db $2C
	db $2D
	db $2D
	db $2D
	db $2D
	db $2D
	db $2C
	db $2C
	db $2D
	db $2C
	db $2C
	db $C2, $93
	db $EE
Song06BLoop:
	db $CD
	dw SongMacro3F
	db $C2, $97
	db $F2
	db $99
	db $C2, $93
	db $CD
	dw SongMacro40
	db $03
	db $D6
	db $0D
	db $01
	db $D4
	db $33
	db $D6
	db $3D
	db $31
	db $D4
	db $CD
	dw SongMacro41
	db $C2, $97
	db $29
	db $C2, $93
	db $CD
	dw SongMacro42
	db $C3
	dw Song06BLoop
SongMacro3F:
	db $03
	db $D6
	db $0D
	db $3D
	db $2D
	db $0D
	db $F2
	db $AC
	db $AD
	db $F3
	db $0D
	db $F2
	db $AD
	db $7C
	db $AC
	db $F3
	db $03
	db $D6
	db $0D
	db $3D
	db $2D
	db $0D
	db $F2
	db $AC
	db $AD
	db $F3
	db $0D
	db $F2
	db $AD
	db $7C
	db $AC
	db $F3
	db $03
	db $D6
	db $0D
	db $3D
	db $2D
	db $0D
	db $F2
	db $AC
	db $AD
	db $F3
	db $0D
	db $F2
	db $AD
	db $F3
	db $3C
	db $5C
	db $73
	db $D6
	db $7D
	db $5D
	db $3D
	db $2D
	db $0D
	db $5D
	db $3D
	db $2D
	db $0D
	db $5D
	db $3D
	db $2D
	db $0D
	db $2D
	db $3D
	db $5D
	db $3D
	db $2D
	db $3D
	db $5D
	db $3D
	db $2D
	db $3D
	db $5D
	db $3D
	db $2D
	db $0D
	db $F2
	db $AD
	db $F3
	db $2D
	db $0D
	db $2D
	db $0A
	db $DC
	db $05
	db $F2
	db $A5
	db $F3
	db $05
	db $25
	db $35
	db $55
	db $7D
	db $AD
	db $7D
	db $F4
	db $0D
	db $F3
	db $7D
	db $AD
	db $7D
	db $F4
	db $0D
	db $F3
	db $7D
	db $AD
	db $7D
	db $F4
	db $0D
	db $F3
	db $7D
	db $AD
	db $7D
	db $F4
	db $0D
	db $C9
SongMacro40:
	db $F3
	db $03
	db $D6
	db $0D
	db $3D
	db $2D
	db $0D
	db $F2
	db $AC
	db $AD
	db $F3
	db $0C
	db $F2
	db $7C
	db $AC
	db $F3
	db $03
	db $D6
	db $0D
	db $3D
	db $2D
	db $0D
	db $F2
	db $AC
	db $AD
	db $F3
	db $0C
	db $F2
	db $7C
	db $AC
	db $F3
	db $03
	db $D6
	db $0D
	db $3D
	db $2D
	db $0D
	db $F2
	db $AC
	db $AD
	db $F3
	db $0C
	db $3C
	db $5C
	db $C9
SongMacro41:
	db $7C
	db $7D
	db $7C
	db $7D
	db $7D
	db $7D
	db $5C
	db $3C
	db $2C
	db $0C
	db $5C
	db $5D
	db $5C
	db $5D
	db $5D
	db $5D
	db $3C
	db $2C
	db $0D
	db $F2
	db $AD
	db $F3
	db $0D
	db $2D
	db $09
	db $C9
SongMacro42:
	db $0D
	db $F2
	db $7D
	db $AD
	db $F3
	db $0C
	db $F2
	db $7D
	db $AD
	db $F3
	db $0D
	db $0D
	db $F2
	db $7D
	db $AD
	db $F3
	db $0C
	db $F2
	db $7D
	db $AD
	db $F3
	db $0D
	db $0D
	db $F2
	db $7D
	db $AD
	db $F3
	db $0C
	db $F2
	db $7D
	db $AD
	db $F3
	db $0C
	db $7D
	db $5D
	db $AD
	db $7D
	db $5D
	db $3D
	db $2D
	db $0D
	db $F2
	db $7D
	db $AD
	db $F3
	db $0C
	db $F2
	db $7D
	db $AD
	db $F3
	db $0D
	db $0D
	db $F2
	db $7D
	db $AD
	db $F3
	db $0C
	db $F2
	db $7D
	db $AD
	db $F3
	db $0D
	db $0D
	db $F2
	db $7D
	db $AD
	db $F3
	db $0C
	db $F2
	db $7D
	db $AD
	db $F3
	db $0C
	db $7D
	db $5D
	db $AD
	db $7D
	db $5D
	db $3D
	db $2D
	db $C9
Song06C:
	db $C1, $E0
	db $C2, $40
	db $F2
	db $09
	db $09
	db $F1
	db $59
	db $59
	db $7C
	db $7C
	db $7D
	db $7C
	db $7C
	db $7C
	db $7D
	db $7C
	db $5C
	db $7C
	db $7D
	db $7D
	db $7D
	db $7C
	db $7C
	db $7C
	db $7D
	db $9C
	db $BC
Song06CLoop:
	db $F2
	db $CD
	dw SongMacro43
	db $CD
	dw SongMacro43
	db $CD
	dw SongMacro43
	db $CD
	dw SongMacro43
	db $CD
	dw SongMacro43
	db $CD
	dw SongMacro43
	db $CD
	dw SongMacro43
	db $CD
	dw SongMacro43
	db $CD
	dw SongMacro43
	db $CD
	dw SongMacro43
	db $CD
	dw SongMacro43
	db $CD
	dw SongMacro43
	db $CD
	dw SongMacro43
	db $0D
	db $3D
	db $7D
	db $AD
	db $0D
	db $3D
	db $7D
	db $3D
	db $0D
	db $3D
	db $7D
	db $AD
	db $0D
	db $3D
	db $7D
	db $3D
	db $0D
	db $3D
	db $5D
	db $8D
	db $0D
	db $5D
	db $8D
	db $5D
	db $F1
	db $AD
	db $F2
	db $2D
	db $5D
	db $8D
	db $F1
	db $AD
	db $F2
	db $2D
	db $8D
	db $2D
	db $CD
	dw SongMacro44
	db $CD
	dw SongMacro44
	db $CD
	dw SongMacro45
	db $CD
	dw SongMacro46
	db $CD
	dw SongMacro45
	db $CD
	dw SongMacro46
	db $C3
	dw Song06CLoop
SongMacro43:
	db $0D
	db $F1
	db $7D
	db $AD
	db $F2
	db $0C
	db $F1
	db $7D
	db $AD
	db $F2
	db $0D
	db $0D
	db $F1
	db $7D
	db $AD
	db $F2
	db $0C
	db $F1
	db $7D
	db $AD
	db $F2
	db $0D
	db $C9
SongMacro44:
	db $0D
	db $7D
	db $3D
	db $7D
	db $0D
	db $7D
	db $3D
	db $7D
	db $0D
	db $7D
	db $3D
	db $7D
	db $0D
	db $7D
	db $3D
	db $7D
	db $C9
SongMacro45:
	db $0D
	db $F1
	db $7D
	db $AD
	db $F2
	db $0C
	db $F1
	db $7D
	db $AD
	db $F2
	db $0D
	db $0D
	db $F1
	db $7D
	db $AD
	db $F2
	db $0C
	db $F1
	db $7D
	db $AD
	db $F2
	db $0D
	db $C9
SongMacro46:
	db $0D
	db $F1
	db $7D
	db $AD
	db $F2
	db $0C
	db $F1
	db $7D
	db $AD
	db $F2
	db $0C
	db $7D
	db $5D
	db $AD
	db $7D
	db $5D
	db $3D
	db $2D
	db $C9
Song06D:
	db $C1, $01
	db $C2, $91
	db $CD
	dw SongMacro47
	db $CD
	dw SongMacro47
	db $CD
	dw SongMacro47
	db $CD
	dw SongMacro47
	db $5D
	db $0D
	db $0D
	db $0D
	db $4D
	db $0D
	db $0D
	db $5C
	db $5D
	db $0D
	db $0D
	db $4D
	db $0D
	db $0D
	db $0D
	db $5D
	db $0D
	db $5D
	db $0D
	db $4D
	db $4D
	db $0D
	db $5C
	db $5D
	db $0D
	db $5D
	db $4D
	db $0D
	db $4D
	db $4D
Song06DLoop:
	db $CD
	dw SongMacro48
	db $CD
	dw SongMacro48
	db $CD
	dw SongMacro48
	db $CD
	dw SongMacro48
	db $CD
	dw SongMacro48
	db $CD
	dw SongMacro48
	db $CD
	dw SongMacro48
	db $CD
	dw SongMacro48
	db $CD
	dw SongMacro48
	db $CD
	dw SongMacro48
	db $CD
	dw SongMacro48
	db $CD
	dw SongMacro48
	db $CD
	dw SongMacro48
	db $CD
	dw SongMacro48
	db $CD
	dw SongMacro48
	db $CD
	dw SongMacro48
	db $CD
	dw SongMacro48
	db $CD
	dw SongMacro48
	db $5D
	db $0D
	db $0D
	db $0D
	db $4D
	db $0D
	db $0D
	db $0D
	db $5D
	db $0D
	db $0D
	db $5D
	db $0D
	db $5D
	db $0D
	db $5D
	db $CD
	dw SongMacro48
	db $5D
	db $0D
	db $0D
	db $0D
	db $4D
	db $0D
	db $0D
	db $0D
	db $5D
	db $0D
	db $0D
	db $5D
	db $0D
	db $4D
	db $4D
	db $4D
	db $C3
	dw Song06DLoop
SongMacro47:
	db $0D
	db $0D
	db $0D
	db $0D
	db $0D
	db $0D
	db $0D
	db $0D
	db $0D
	db $0D
	db $0D
	db $0D
	db $0D
	db $0D
	db $0D
	db $0D
	db $C9
SongMacro48:
	db $5D
	db $0D
	db $0D
	db $0D
	db $4D
	db $0D
	db $0D
	db $0D
	db $5D
	db $0D
	db $0D
	db $0D
	db $4D
	db $0D
	db $0D
	db $0D
	db $C9

Song07:
	dw Song07A
	dw Song07B
	dw Song07C
	dw Song07D
Song07A:
	db $C4, %11111111
	db $C0, 199
	db $C1, $80
	db $E9
	db $E9
	db $E9
Song07ALoop:
	db $C2, $95
	db $CD
	dw SongMacro4D
	db $CD
	dw SongMacro4D
	db $C2, $91
	db $CD
	dw SongMacro49
	db $CD
	dw SongMacro4A
	db $CD
	dw SongMacro49
	db $9D
	db $4D
	db $0D
	db $4D
	db $9D
	db $4D
	db $0D
	db $9D
	db $F4
	db $0D
	db $F3
	db $9D
	db $4D
	db $F4
	db $0D
	db $F3
	db $AD
	db $5D
	db $2D
	db $5D
	db $CD
	dw SongMacro49
	db $CD
	dw SongMacro4A
	db $CD
	dw SongMacro49
	db $9D
	db $4D
	db $0D
	db $4D
	db $9D
	db $4D
	db $0D
	db $9D
	db $F4
	db $0D
	db $F3
	db $9D
	db $4D
	db $0D
	db $AD
	db $5D
	db $2D
	db $F2
	db $AD
	db $CD
	dw SongMacro4B
	db $F3
	db $4D
	db $F2
	db $BD
	db $8D
	db $BD
	db $F3
	db $4D
	db $F2
	db $BD
	db $8D
	db $BD
	db $F3
	db $8D
	db $2D
	db $F2
	db $BD
	db $F3
	db $2D
	db $4D
	db $F2
	db $BD
	db $8D
	db $BD
	db $CD
	dw SongMacro4B
	db $F3
	db $4D
	db $F2
	db $BD
	db $8D
	db $BD
	db $F3
	db $4D
	db $F2
	db $BD
	db $8D
	db $BD
	db $F3
	db $2D
	db $F2
	db $BD
	db $7D
	db $BD
	db $F3
	db $2D
	db $F2
	db $AD
	db $5D
	db $AD
	db $F3
	db $4D
	db $0D
	db $F2
	db $9D
	db $F3
	db $0D
	db $4D
	db $0D
	db $F2
	db $9D
	db $F3
	db $0D
	db $4D
	db $0D
	db $F2
	db $9D
	db $F3
	db $0D
	db $4D
	db $0D
	db $F2
	db $9D
	db $F3
	db $0D
	db $4D
	db $0D
	db $F2
	db $9D
	db $F3
	db $0D
	db $4D
	db $0D
	db $F2
	db $9D
	db $F3
	db $0D
	db $4D
	db $0D
	db $F2
	db $9D
	db $F3
	db $0D
	db $4D
	db $0D
	db $F2
	db $9D
	db $F3
	db $0D
	db $C3
	dw Song07ALoop
SongMacro49:
	db $9D
	db $4D
	db $0D
	db $4D
	db $9D
	db $4D
	db $0D
	db $4D
	db $9D
	db $4D
	db $0D
	db $4D
	db $9D
	db $4D
	db $0D
	db $4D
	db $C9
SongMacro4A:
	db $9D
	db $4D
	db $0D
	db $4D
	db $9D
	db $4D
	db $0D
	db $4D
	db $9D
	db $4D
	db $0D
	db $9D
	db $7D
	db $2D
	db $F2
	db $BD
	db $F3
	db $7D
	db $C9
SongMacro4B:
	db $F3
	db $4D
	db $F2
	db $BD
	db $8D
	db $BD
	db $F3
	db $4D
	db $F2
	db $BD
	db $8D
	db $BD
	db $F3
	db $4D
	db $F2
	db $BD
	db $8D
	db $BD
	db $F3
	db $4D
	db $F2
	db $BD
	db $8D
	db $BD
	db $C9
Song07B:
	db $C1, $C0
	db $EE
	db $E9
	db $E9
	db $E9
Song07BLoop:
	db $C2, $95
	db $CD
	dw SongMacro4D
	db $CD
	dw SongMacro4D
	db $CD
	dw SongMacro4C
	db $CD
	dw SongMacro4C
	db $CD
	dw SongMacro4C
	db $CD
	dw SongMacro4C
	db $B9
	db $DA
	db $8B
	db $4B
	db $B9
	db $DA
	db $7B
	db $AB
	db $C2, $91
	db $9C
	db $9C
	db $9C
	db $9C
	db $9C
	db $9C
	db $9C
	db $9C
	db $9C
	db $9C
	db $9C
	db $9C
	db $9C
	db $9C
	db $9C
	db $9C
	db $C3
	dw Song07BLoop
SongMacro4C:
	db $F2
	db $9A
	db $F3
	db $0A
	db $4A
	db $9B
	db $7B
	db $C9
SongMacro4D:
	db $F4
	db $02
	db $D5
	db $0C
	db $0C
	db $2B
	db $0C
	db $F3
	db $BD
	db $F4
	db $0D
	db $F3
	db $B1
	db $D3
	db $D5
	db $93
	db $D6
	db $B3
	db $D6
	db $F4
	db $0C
	db $23
	db $D6
	db $03
	db $D6
	db $F3
	db $9C
	db $F4
	db $03
	db $D6
	db $F3
	db $B1
	db $DC
	db $D6
	db $F4
	db $02
	db $D5
	db $0C
	db $0C
	db $2B
	db $0C
	db $F3
	db $BD
	db $F4
	db $0D
	db $F3
	db $B1
	db $D3
	db $D5
	db $93
	db $D6
	db $B3
	db $D6
	db $F4
	db $0D
	db $F3
	db $B2
	db $D5
	db $9C
	db $7D
	db $99
	db $C9
Song07C:
	db $C1, $C8
	db $C2, $40
	db $E9
	db $CD
	dw SongMacro4E
	db $CD
	dw SongMacro4E
Song07CLoop:
	db $CD
	dw SongMacro4E
	db $CD
	dw SongMacro4F
	db $CD
	dw SongMacro50
	db $CD
	dw SongMacro51
	db $CD
	dw SongMacro4E
	db $CD
	dw SongMacro4F
	db $CD
	dw SongMacro52
	db $CD
	dw SongMacro4E
	db $CD
	dw SongMacro4E
	db $CD
	dw SongMacro4F
	db $CD
	dw SongMacro50
	db $CD
	dw SongMacro51
	db $CD
	dw SongMacro4E
	db $CD
	dw SongMacro4F
	db $CD
	dw SongMacro52
	db $CD
	dw SongMacro4E
	db $CD
	dw SongMacro53
	db $CD
	dw SongMacro54
	db $CD
	dw SongMacro53
	db $CD
	dw SongMacro55
	db $CD
	dw SongMacro53
	db $CD
	dw SongMacro54
	db $CD
	dw SongMacro53
	db $CD
	dw SongMacro55
	db $F1
	db $CD
	dw SongMacro56
	db $CD
	dw SongMacro56
	db $CD
	dw SongMacro56
	db $4D
	db $4D
	db $BC
	db $4C
	db $BC
	db $7D
	db $7D
	db $F2
	db $2D
	db $F1
	db $7D
	db $AC
	db $F2
	db $5C
	db $CD
	dw SongMacro53
	db $CD
	dw SongMacro53
	db $C3
	dw Song07CLoop
SongMacro4E:
	db $F1
	db $9C
	db $F2
	db $4C
	db $9C
	db $4D
	db $F1
	db $9C
	db $9D
	db $F2
	db $9C
	db $4C
	db $9C
	db $C9
SongMacro4F:
	db $F1
	db $7C
	db $F2
	db $2C
	db $7C
	db $2D
	db $F1
	db $7C
	db $7D
	db $F2
	db $7C
	db $2C
	db $7C
	db $C9
SongMacro50:
	db $F1
	db $5C
	db $F2
	db $0C
	db $5C
	db $0D
	db $F1
	db $5C
	db $5D
	db $F2
	db $5C
	db $0C
	db $5C
	db $C9
SongMacro51:
	db $F1
	db $4C
	db $BC
	db $F2
	db $4C
	db $F1
	db $BD
	db $4C
	db $4D
	db $F2
	db $4C
	db $F1
	db $BC
	db $F2
	db $4C
	db $C9
SongMacro52:
	db $F1
	db $5C
	db $F2
	db $0C
	db $5C
	db $0D
	db $F1
	db $7C
	db $7D
	db $F2
	db $7C
	db $2C
	db $7C
	db $C9
SongMacro53:
	db $F1
	db $9D
	db $9D
	db $F2
	db $4C
	db $F1
	db $9C
	db $F2
	db $4C
	db $F1
	db $9D
	db $9D
	db $F2
	db $4D
	db $F1
	db $9D
	db $9C
	db $F2
	db $4C
	db $C9
SongMacro54:
	db $F1
	db $9D
	db $9D
	db $F2
	db $4C
	db $F1
	db $9C
	db $F2
	db $4C
	db $F1
	db $9D
	db $9D
	db $F2
	db $4D
	db $F1
	db $9D
	db $7C
	db $F2
	db $2C
	db $C9
SongMacro55:
	db $F1
	db $9D
	db $9D
	db $F2
	db $4C
	db $F1
	db $9C
	db $F2
	db $4C
	db $F1
	db $9D
	db $9D
	db $F2
	db $4D
	db $F1
	db $9D
	db $AC
	db $F2
	db $5C
	db $C9
SongMacro56:
	db $4D
	db $4D
	db $BC
	db $4C
	db $BC
	db $4D
	db $4D
	db $BD
	db $4D
	db $4C
	db $BC
	db $C9
Song07D:
	db $C1, $01
	db $C2, $61
	db $EA
	db $4D
	db $4D
	db $4D
	db $4D
	db $4D
	db $4D
	db $4D
	db $4D
	db $CD
	dw SongMacro57
	db $CD
	dw SongMacro58
Song07DLoop:
	db $CD
	dw SongMacro57
	db $CD
	dw SongMacro57
	db $CD
	dw SongMacro57
	db $CD
	dw SongMacro57
	db $CD
	dw SongMacro57
	db $CD
	dw SongMacro57
	db $CD
	dw SongMacro57
	db $CD
	dw SongMacro58
	db $CD
	dw SongMacro57
	db $CD
	dw SongMacro57
	db $CD
	dw SongMacro57
	db $CD
	dw SongMacro57
	db $CD
	dw SongMacro57
	db $CD
	dw SongMacro57
	db $CD
	dw SongMacro57
	db $CD
	dw SongMacro58
	db $CD
	dw SongMacro59
	db $CD
	dw SongMacro59
	db $CD
	dw SongMacro59
	db $CD
	dw SongMacro59
	db $CD
	dw SongMacro59
	db $CD
	dw SongMacro59
	db $CD
	dw SongMacro59
	db $CD
	dw SongMacro59
	db $CD
	dw SongMacro59
	db $CD
	dw SongMacro59
	db $CD
	dw SongMacro59
	db $CD
	dw SongMacro59
	db $CD
	dw SongMacro59
	db $5D
	db $2D
	db $2D
	db $5D
	db $5D
	db $2D
	db $2D
	db $5D
	db $4D
	db $4D
	db $4D
	db $4D
	db $4D
	db $2D
	db $2D
	db $5D
	db $C3
	dw Song07DLoop
SongMacro57:
	db $5D
	db $2D
	db $5D
	db $2D
	db $4D
	db $2D
	db $2D
	db $5D
	db $2D
	db $5D
	db $4D
	db $2D
	db $4D
	db $2D
	db $5D
	db $2D
	db $C9
SongMacro58:
	db $5D
	db $2D
	db $4D
	db $2D
	db $4D
	db $2D
	db $2D
	db $5D
	db $2D
	db $5D
	db $4D
	db $2D
	db $4D
	db $2D
	db $4D
	db $2D
	db $C9
SongMacro59:
	db $5D
	db $2D
	db $2D
	db $5D
	db $5D
	db $2D
	db $2D
	db $5D
	db $5D
	db $2D
	db $2D
	db $5D
	db $4D
	db $2D
	db $2D
	db $5D
	db $C9
	
Song08:
	dw Song08A
	dw Song08B
	dw Song08C
	dw Song08D
Song08A:
	db $C4, %11111111
	db $C0, 144
	db $C1, $80
	db $C2, $97
Song08ALoop:
	db $CD
	dw SongMacro5A
	db $CD
	dw SongMacro5A
	db $CD
	dw SongMacro5A
	db $CD
	dw SongMacro5A
	db $CD
	dw SongMacro5B
	db $C3
	dw Song08ALoop
Song08B:
	db $C1, $C0
	db $C2, $97
	db $EE
Song08BLoop:
	db $CD
	dw SongMacro5A
	db $CD
	dw SongMacro5A
	db $CD
	dw SongMacro5A
	db $CD
	dw SongMacro5A
	db $CD
	dw SongMacro5B
	db $C3
	dw Song08BLoop
Song08C:
	db $C1, $E0
	db $C2, $40
Song08CLoop:
	db $CD
	dw SongMacro5A
	db $CD
	dw SongMacro5A
	db $CD
	dw SongMacro5A
	db $CD
	dw SongMacro5A
	db $CD
	dw SongMacro5B
	db $C3
	dw Song08CLoop
SongMacro5A:
	db $F2
	db $4B
	db $1B
	db $0B
	db $F1
	db $5B
	db $9B
	db $F2
	db $31
	db $D4
	db $2B
	db $8B
	db $7B
	db $0B
	db $39
	db $C9
SongMacro5B:
	db $49
	db $D9
	db $F1
	db $0C
	db $0C
	db $0C
	db $0C
	db $0C
	db $0C
	db $0C
	db $0C
	db $E9
	db $C9
Song08D:
	db $C1
	db $01
Song08DLoop:
	db $C2
	db $91
	db $0E
	db $C2
	db $81
	db $0E
	db $C2
	db $71
	db $0E
	db $C2
	db $61
	db $0E
	db $C2
	db $51
	db $0E
	db $C2
	db $41
	db $0E
	db $C2
	db $31
	db $0E
	db $C2
	db $21
	db $0E
	db $C3
	dw Song08DLoop
	
Song09:
	dw Song09A
	dw Song09B
	dw Song09C
	dw Song09D
Song09A:
	db $C4, %11111111
	db $C0, 188
	db $C1, $40
	db $C2, $93
	db $CD
	dw SongMacro5C
Song09ALoop:
	db $CD
	dw SongMacro5D
	db $C3
	dw Song09ALoop
Song09B:
	db $C1, $00
	db $C2, $93
	db $EE
	db $CD
	dw SongMacro5C
Song09BLoop:
	db $CD
	dw SongMacro5D
	db $C3
	dw Song09BLoop
SongMacro5C:
	db $E1
	db $D3
	db $D5
	db $F2
	db $9D
	db $9D
	db $C9
SongMacro5D:
	db $9D
	db $9D
	db $F3
	db $0C
	db $2C
	db $F2
	db $9D
	db $9D
	db $9D
	db $9D
	db $F3
	db $0C
	db $2C
	db $F2
	db $9D
	db $9D
	db $9D
	db $9D
	db $F3
	db $0C
	db $2C
	db $3D
	db $2D
	db $0D
	db $3D
	db $2D
	db $0D
	db $F2
	db $9D
	db $7D
	db $9D
	db $9D
	db $C9
Song09C:
	db $C1, $D0
	db $C2, $40
	db $E9
Song09CLoop:
	db $F2
	db $2B
	db $2B
	db $2B
	db $2B
	db $2B
	db $2C
	db $F1
	db $73
	db $D6
	db $F2
	db $7C
	db $F1
	db $7D
	db $9C
	db $9D
	db $9D
	db $C3
	dw Song09CLoop
Song09D:
	db $C1, $01
	db $C2, $91
	db $E9
Song09DLoop:
	db $5C
	db $2C
	db $4C
	db $2D
	db $2D
	db $5C
	db $2C
	db $4C
	db $2D
	db $2D
	db $5C
	db $2C
	db $4C
	db $5C
	db $2D
	db $5C
	db $2D
	db $4C
	db $5D
	db $5D
	db $C3
	dw Song09DLoop

Song0A:
	dw Song0AA
	dw Song0AB
	dw Song0AC
	dw Song0AD
Song0AA:
	db $C4, %11111111
	db $C0, 188
	db $C1, $40
	db $C2, $93
	db $CD
	dw SongMacro5E
Song0AALoop:
	db $CD
	dw SongMacro5F
	db $C3
	dw Song0AALoop
Song0AB:
	db $C1, $00
	db $C2, $93
	db $EE
	db $CD
	dw SongMacro5E
Song0ABLoop:
	db $CD
	dw SongMacro5F
	db $C3
	dw Song0ABLoop
SongMacro5E:
	db $E1
	db $D3
	db $D5
	db $F2
	db $9D
	db $9D
	db $C9
SongMacro5F:
	db $9D
	db $9D
	db $9B
	db $F3
	db $0C
	db $22
	db $D5
	db $F2
	db $9D
	db $9D
	db $9D
	db $9D
	db $9B
	db $F3
	db $0C
	db $F2
	db $BC
	db $7C
	db $4C
	db $9D
	db $9D
	db $C9
Song0AC:
	db $C1, $D0
	db $C2, $40
	db $E1
	db $D3
	db $D5
	db $F1
	db $9D
	db $9D
Song0ACLoop:
	db $F2
	db $2C
	db $2D
	db $2D
	db $2C
	db $2D
	db $2D
	db $2D
	db $2D
	db $2D
	db $23
	db $D6
	db $2D
	db $2D
	db $2C
	db $2D
	db $2D
	db $2C
	db $2D
	db $2D
	db $2D
	db $2D
	db $2D
	db $2D
	db $F1
	db $9C
	db $9D
	db $9D
	db $C3
	dw Song0ACLoop
Song0AD:
	db $C1
	db $01
	db $C2
	db $61
	db $E9
Song0ADLoop:
	db $5D
	db $2D
	db $2D
	db $2D
	db $4D
	db $2D
	db $2D
	db $2D
	db $5D
	db $2D
	db $2D
	db $2D
	db $4D
	db $2D
	db $2D
	db $2D
	db $5D
	db $2D
	db $2D
	db $2D
	db $4D
	db $2D
	db $2D
	db $2D
	db $5D
	db $2D
	db $2D
	db $2D
	db $4D
	db $2D
	db $4D
	db $4D
	db $C3
	dw Song0ADLoop

Song0B:
	dw Song0BA
	dw Song0BB
	dw Song0BC
	dw Song0BD
Song0BA:
	db $C4, %11111111
	db $C0, 120
	db $C1, $80
	db $C2
	db $93
Song0BALoop:
	db $CD
	dw SongMacro60
	db $CD
	dw SongMacro60
	db $CD
	dw SongMacro61
	db $CD
	dw SongMacro61
	db $C3
	dw Song0BALoop
SongMacro60:
	db $F3
	db $9D
	db $BD
	db $F4
	db $0D
	db $4D
	db $F3
	db $9D
	db $BD
	db $F4
	db $0D
	db $4D
	db $F3
	db $9D
	db $BD
	db $F4
	db $0D
	db $4D
	db $F3
	db $9D
	db $BD
	db $F4
	db $0D
	db $4D
	db $C9
SongMacro61:
	db $F3
	db $7D
	db $9D
	db $BD
	db $F4
	db $2D
	db $F3
	db $7D
	db $9D
	db $BD
	db $F4
	db $2D
	db $F3
	db $7D
	db $9D
	db $BD
	db $F4
	db $2D
	db $F3
	db $7D
	db $9D
	db $BD
	db $F4
	db $2D
	db $C9
Song0BB:
	db $C1, $C0
	db $C2, $97
Song0BBLoop:
	db $F2
	db $CD
	dw SongMacro62
	db $C3
	dw Song0BBLoop
Song0BC:
	db $C1, $80
	db $C2, $40
Song0BCLoop:
	db $F2
	db $CD
	dw SongMacro62
	db $C3
	dw Song0BCLoop
SongMacro62:
	db $9A
	db $9A
	db $9A
	db $9A
	db $7A
	db $7A
	db $7A
	db $7A
	db $C9
Song0BD:
	db $C1, $01
Song0BDLoop:
	db $E9
	db $E9
	db $E9
	db $E9
	db $CD
	dw SongMacro63
	db $CD
	dw SongMacro63
	db $CD
	dw SongMacro63
	db $CD
	dw SongMacro63
	db $C3
	dw Song0BDLoop
SongMacro63:
	db $C2, $71
	db $2E
	db $C2, $61
	db $2E
	db $C2, $51
	db $2E
	db $C2, $41
	db $2E
	db $C2, $31
	db $2E
	db $C2, $21
	db $2B
	db $C2, $11
	db $DD
	db $DE
	db $C2, $71
	db $46
	db $C2, $61
	db $46
	db $C2, $51
	db $46
	db $C2, $41
	db $4E
	db $C2, $31
	db $4E
	db $C2, $21
	db $4E
	db $C2, $11
	db $4B
	db $DD
	db $DE
	db $C9
	
Song0C:
	dw Song0CA
	dw Song0CB
	dw Song0CC
	dw Song0CD
Song0CA:
	db $C4, %11111111
	db $C1, $80
	db $C0, 142
	db $C2, $97
	db $CD
	dw SongMacro6B
	db $F3
	db $4A
	db $DC
	db $9C
	db $8C
	db $4C
	db $49
	db $4A
	db $DC
	db $9C
	db $8C
	db $4C
	db $D9
	db $4A
	db $4C
	db $9C
	db $8C
	db $4C
	db $4A
	db $6B
	db $7B
	db $9A
	db $DC
	db $BB
	db $9C
	db $DA
	db $7B
	db $6B
	db $C2, $67
	db $CD
	dw SongMacro64
	db $CD
	dw SongMacro64
	db $CD
	dw SongMacro65
	db $CD
	dw SongMacro65
	db $CD
	dw SongMacro66
	db $CD
	dw SongMacro66
	db $F2
	db $4D
	db $BD
	db $F3
	db $4D
	db $6D
	db $8D
	db $6D
	db $4D
	db $F2
	db $BD
	db $4D
	db $BD
	db $F3
	db $4D
	db $6D
	db $8D
	db $6D
	db $4D
	db $F2
	db $BD
	db $4D
	db $F3
	db $2D
	db $F2
	db $BD
	db $8D
	db $4D
	db $F3
	db $2D
	db $F2
	db $BD
	db $8D
	db $F3
	db $4D
	db $F4
	db $2D
	db $1D
	db $F3
	db $BD
	db $9D
	db $8D
	db $6D
	db $4D
	db $C2, $97
	db $4A
	db $DC
	db $9C
	db $8C
	db $4C
	db $49
	db $4A
	db $DC
	db $9C
	db $8C
	db $4C
	db $D9
	db $4A
	db $DC
	db $9C
	db $8C
	db $1C
	db $1A
	db $F2
	db $BB
	db $F3
	db $1B
	db $2A
	db $2C
	db $4B
	db $2C
	db $D1
	db $D4
	db $4D
	db $6D
	db $8D
	db $9D
	db $B9
	db $F4
	db $1A
	db $2A
	db $11
	db $D4
	db $F3
	db $8B
	db $BB
	db $9B
	db $8C
	db $92
	db $D5
	db $F4
	db $21
	db $D4
	db $F3
	db $6B
	db $9B
	db $8B
	db $6C
	db $8B
	db $9C
	db $99
	db $D9
	db $99
	db $D9
	db $CE
SongMacro64:
	db $F2
	db $7D
	db $F3
	db $2D
	db $7D
	db $9D
	db $BD
	db $9D
	db $7D
	db $2D
	db $F2
	db $7D
	db $F3
	db $2D
	db $7D
	db $9D
	db $BD
	db $9D
	db $7D
	db $2D
	db $C9
SongMacro65:
	db $F2
	db $BD
	db $F3
	db $2D
	db $6D
	db $BD
	db $F4
	db $2D
	db $0D
	db $F3
	db $BD
	db $6D
	db $F2
	db $BD
	db $F3
	db $2D
	db $6D
	db $BD
	db $F4
	db $2D
	db $0D
	db $F3
	db $BD
	db $6D
	db $C9
SongMacro66:
	db $F2
	db $5D
	db $F3
	db $0D
	db $5D
	db $7D
	db $9D
	db $7D
	db $5D
	db $0D
	db $F2
	db $5D
	db $F3
	db $0D
	db $5D
	db $7D
	db $9D
	db $7D
	db $5D
	db $0D
	db $C9
Song0CB:
	db $C1, $C0
	db $EF
	db $C2, $97
	db $CD
	dw SongMacro6B
	db $F3
	db $09
	db $0A
	db $F2
	db $9B
	db $BB
	db $F3
	db $09
	db $DA
	db $F2
	db $9B
	db $BB
	db $F3
	db $09
	db $0A
	db $F2
	db $BB
	db $F3
	db $0B
	db $29
	db $DA
	db $BB
	db $F4
	db $0B
	db $29
	db $F3
	db $7A
	db $F4
	db $2C
	db $0C
	db $F3
	db $BC
	db $F4
	db $0C
	db $2A
	db $92
	db $D5
	db $2C
	db $2A
	db $2C
	db $0C
	db $F3
	db $BC
	db $F4
	db $2C
	db $09
	db $F3
	db $5A
	db $F4
	db $0B
	db $2B
	db $49
	db $D9
	db $F3
	db $C2, $67
	db $CD
	dw SongMacro67
	db $CD
	dw SongMacro67
	db $CD
	dw SongMacro67
	db $CD
	dw SongMacro67
	db $CD
	dw SongMacro67
	db $CD
	dw SongMacro67
	db $CD
	dw SongMacro68
	db $2D
	db $4D
	db $6D
	db $2D
	db $2D
	db $4D
	db $6D
	db $2D
	db $2D
	db $4D
	db $6D
	db $2D
	db $1D
	db $2D
	db $4D
	db $1D
	db $CD
	dw SongMacro68
	db $CD
	dw SongMacro69
	db $CD
	dw SongMacro69
	db $CD
	dw SongMacro6A
	db $CD
	dw SongMacro6A
	db $4D
	db $6D
	db $8D
	db $4D
	db $4D
	db $6D
	db $8D
	db $4D
	db $2D
	db $6D
	db $8D
	db $4D
	db $2D
	db $6D
	db $8D
	db $4D
	db $CD
	dw SongMacro67
	db $2D
	db $4D
	db $5D
	db $2D
	db $2D
	db $4D
	db $5D
	db $2D
	db $2D
	db $4D
	db $5D
	db $2D
	db $2D
	db $4D
	db $5D
	db $2D
	db $1D
	db $2D
	db $4D
	db $1D
	db $1D
	db $2D
	db $4D
	db $1D
	db $1D
	db $2D
	db $4D
	db $1D
	db $1D
	db $2D
	db $4D
	db $2D
	db $19
	db $CE
SongMacro67:
	db $1D
	db $2D
	db $4D
	db $1D
	db $1D
	db $2D
	db $4D
	db $1D
	db $1D
	db $2D
	db $4D
	db $1D
	db $1D
	db $2D
	db $4D
	db $1D
	db $C9
SongMacro68:
	db $2D
	db $4D
	db $6D
	db $2D
	db $2D
	db $4D
	db $6D
	db $2D
	db $2D
	db $4D
	db $6D
	db $2D
	db $2D
	db $4D
	db $6D
	db $2D
	db $C9
SongMacro69:
	db $4D
	db $6D
	db $8D
	db $4D
	db $4D
	db $6D
	db $8D
	db $4D
	db $4D
	db $6D
	db $8D
	db $4D
	db $4D
	db $6D
	db $8D
	db $4D
	db $C9
SongMacro6A:
	db $6D
	db $8D
	db $9D
	db $6D
	db $6D
	db $8D
	db $9D
	db $6D
	db $6D
	db $8D
	db $9D
	db $6D
	db $6D
	db $8D
	db $9D
	db $6D
	db $C9
SongMacro6B:
	db $F3
	db $7A
	db $DC
	db $7C
	db $BC
	db $F4
	db $2C
	db $5A
	db $4C
	db $2C
	db $0C
	db $4C
	db $2B
	db $F3
	db $71
	db $D4
	db $A2
	db $D5
	db $F4
	db $02
	db $D5
	db $F3
	db $9B
	db $7A
	db $DC
	db $7C
	db $BC
	db $F4
	db $2C
	db $5A
	db $9C
	db $7C
	db $5C
	db $4C
	db $2B
	db $F3
	db $71
	db $D4
	db $A2
	db $D5
	db $F4
	db $02
	db $D5
	db $F3
	db $9B
	db $F4
	db $02
	db $D5
	db $22
	db $D5
	db $F3
	db $AB
	db $F4
	db $2B
	db $F3
	db $9B
	db $7B
	db $9B
	db $69
	db $2A
	db $DC
	db $7C
	db $6C
	db $2C
	db $2A
	db $F2
	db $7B
	db $9B
	db $F3
	db $2A
	db $DC
	db $7C
	db $6C
	db $2C
	db $DA
	db $F2
	db $7B
	db $9B
	db $F3
	db $2A
	db $2C
	db $5C
	db $4C
	db $F2
	db $BC
	db $9A
	db $9B
	db $BB
	db $F3
	db $0A
	db $0C
	db $2B
	db $0C
	db $F2
	db $7A
	db $8A
	db $C9
Song0CC:
	db $C1, $80
	db $C2, $40
	db $F2
	db $7C
	db $F3
	db $2C
	db $7C
	db $9C
	db $BB
	db $7B
	db $2C
	db $9C
	db $F4
	db $2C
	db $4C
	db $5B
	db $2B
	db $F2
	db $7C
	db $F3
	db $2C
	db $7C
	db $9C
	db $BB
	db $7B
	db $3C
	db $AC
	db $F4
	db $3B
	db $F3
	db $5C
	db $F4
	db $0C
	db $5B
	db $F2
	db $7C
	db $F3
	db $2C
	db $7C
	db $9C
	db $BB
	db $7B
	db $2C
	db $9C
	db $F4
	db $2C
	db $4C
	db $5B
	db $2B
	db $F2
	db $7C
	db $F3
	db $2C
	db $7C
	db $9C
	db $BB
	db $7B
	db $3C
	db $AC
	db $F4
	db $3B
	db $F3
	db $5C
	db $F4
	db $0C
	db $5B
	db $F3
	db $2C
	db $9C
	db $F4
	db $2B
	db $F3
	db $7C
	db $F4
	db $2C
	db $7B
	db $F3
	db $32
	db $D5
	db $3C
	db $32
	db $D5
	db $3C
	db $29
	db $F1
	db $CD
	dw SongMacro6C
	db $CD
	dw SongMacro6C
	db $CD
	dw SongMacro6D
	db $CD
	dw SongMacro6D
	db $CD
	dw SongMacro6E
	db $CD
	dw SongMacro6E
	db $F2
	db $CD
	dw SongMacro6F
	db $CD
	dw SongMacro6F
	db $F1
	db $CD
	dw SongMacro70
	db $CD
	dw SongMacro70
	db $CD
	dw SongMacro6C
	db $CD
	dw SongMacro6C
	db $CD
	dw SongMacro71
	db $CD
	dw SongMacro72
	db $F2
	db $CD
	dw SongMacro73
	db $CD
	dw SongMacro73
	db $F1
	db $CD
	dw SongMacro6C
	db $CD
	dw SongMacro6C
	db $CD
	dw SongMacro6D
	db $CD
	dw SongMacro6D
	db $F2
	db $CD
	dw SongMacro6E
	db $CD
	dw SongMacro6E
	db $CD
	dw SongMacro72
	db $CD
	dw SongMacro72
	db $F1
	db $CD
	dw SongMacro70
	db $CD
	dw SongMacro70
	db $F2
	db $CD
	dw SongMacro74
	db $CD
	dw SongMacro74
	db $F1
	db $CD
	dw SongMacro71
	db $CD
	dw SongMacro71
	db $F2
	db $CD
	dw SongMacro73
	db $CD
	dw SongMacro73
	db $F1
	db $CD
	dw SongMacro6D
	db $F2
	db $CD
	dw SongMacro72
	db $CD
	dw SongMacro74
	db $F1
	db $CD
	dw SongMacro71
	db $F2
	db $CD
	dw SongMacro73
	db $CD
	dw SongMacro72
	db $F1
	db $CD
	dw SongMacro70
	db $CD
	dw SongMacro70
	db $CD
	dw SongMacro70
	db $99
	db $CE
SongMacro6C:
	db $7C
	db $7C
	db $7C
	db $7C
	db $7C
	db $7C
	db $7C
	db $7C
	db $C9
SongMacro6D:
	db $BC
	db $BC
	db $BC
	db $BC
	db $BC
	db $BC
	db $BC
	db $BC
	db $C9
SongMacro6E:
	db $5C
	db $5C
	db $5C
	db $5C
	db $5C
	db $5C
	db $5C
	db $5C
	db $C9
SongMacro6F:
	db $0C
	db $0C
	db $0C
	db $0C
	db $0C
	db $0C
	db $0C
	db $0C
	db $C9
SongMacro70:
	db $9C
	db $9C
	db $9C
	db $9C
	db $9C
	db $9C
	db $9C
	db $9C
	db $C9
SongMacro71:
	db $6C
	db $6C
	db $6C
	db $6C
	db $6C
	db $6C
	db $6C
	db $6C
	db $C9
SongMacro72:
	db $4C
	db $4C
	db $4C
	db $4C
	db $4C
	db $4C
	db $4C
	db $4C
	db $C9
SongMacro73:
	db $2C
	db $2C
	db $2C
	db $2C
	db $2C
	db $2C
	db $2C
	db $2C
	db $C9
SongMacro74:
	db $1C
	db $1C
	db $1C
	db $1C
	db $1C
	db $1C
	db $1C
	db $1C
	db $C9
Song0CD:
	db $C1, $01
	db $C2, $61
	db $CD
	dw SongMacro75
	db $CD
	dw SongMacro75
	db $CD
	dw SongMacro75
	db $CD
	dw SongMacro75
	db $CD
	dw SongMacro75
	db $CD
	dw SongMacro75
	db $CD
	dw SongMacro75
	db $CD
	dw SongMacro75
	db $CD
	dw SongMacro75
	db $CD
	dw SongMacro75
	db $5C
	db $2C
	db $45
	db $C2
	db $51
	db $45
	db $C2
	db $41
	db $45
	db $C2
	db $31
	db $45
	db $C2
	db $21
	db $45
	db $C2
	db $11
	db $45
	db $C2
	db $61
	db $45
	db $C2
	db $51
	db $45
	db $C2
	db $41
	db $45
	db $C2
	db $31
	db $45
	db $C2
	db $21
	db $45
	db $C2
	db $11
	db $45
	db $C2
	db $61
	db $45
	db $C2
	db $51
	db $45
	db $C2
	db $41
	db $45
	db $C2
	db $61
	db $5C
	db $C0
	db $B8
	db $CD
	dw SongMacro76
	db $CD
	dw SongMacro76
	db $CD
	dw SongMacro76
	db $CD
	dw SongMacro76
	db $CD
	dw SongMacro76
	db $CD
	dw SongMacro76
	db $CD
	dw SongMacro76
	db $5C
	db $2C
	db $4C
	db $2C
	db $5C
	db $2C
	db $4D
	db $4D
	db $4D
	db $4D
	db $CD
	dw SongMacro76
	db $CD
	dw SongMacro76
	db $CD
	dw SongMacro76
	db $CD
	dw SongMacro76
	db $CD
	dw SongMacro76
	db $CD
	dw SongMacro76
	db $CD
	dw SongMacro76
	db $5C
	db $2C
	db $4C
	db $2C
	db $4D
	db $4D
	db $4D
	db $4D
	db $4D
	db $4D
	db $4D
	db $4D
	db $CD
	dw SongMacro77
	db $CD
	dw SongMacro77
	db $CD
	dw SongMacro77
	db $5D
	db $2D
	db $2D
	db $2D
	db $4D
	db $2D
	db $2D
	db $2D
	db $4D
	db $4D
	db $4D
	db $2D
	db $4D
	db $4D
	db $4D
	db $2D
	db $CD
	dw SongMacro77
	db $CD
	dw SongMacro77
	db $CD
	dw SongMacro77
	db $5D
	db $2D
	db $2D
	db $2D
	db $4D
	db $2D
	db $2D
	db $2D
	db $5D
	db $2D
	db $2D
	db $2D
	db $4D
	db $4D
	db $4D
	db $4D
	db $CD
	dw SongMacro77
	db $CD
	dw SongMacro77
	db $CD
	dw SongMacro77
	db $CD
	dw SongMacro77
	db $CD
	dw SongMacro77
	db $CD
	dw SongMacro77
	db $CD
	dw SongMacro77
	db $5D
	db $2D
	db $2D
	db $2D
	db $4D
	db $2D
	db $2D
	db $2D
	db $4D
	db $4D
	db $4D
	db $2D
	db $4D
	db $2D
	db $4D
	db $4D
	db $CD
	dw SongMacro77
	db $CD
	dw SongMacro77
	db $CD
	dw SongMacro77
	db $CD
	dw SongMacro77
	db $CD
	dw SongMacro77
	db $CD
	dw SongMacro77
	db $CD
	dw SongMacro77
	db $CD
	dw SongMacro77
	db $5D
	db $2D
	db $2D
	db $2D
	db $4D
	db $2D
	db $2D
	db $2D
	db $4C
	db $4C
	db $4D
	db $4D
	db $4D
	db $4D
	db $59
	db $CE
SongMacro75:
	db $5C
	db $2C
	db $2C
	db $2C
	db $45
	db $C2
	db $61
	db $45
	db $C2
	db $51
	db $45
	db $C2
	db $41
	db $45
	db $C2
	db $31
	db $45
	db $C2
	db $21
	db $45
	db $C2
	db $61
	db $2C
	db $2C
	db $C9
SongMacro76:
	db $5C
	db $2C
	db $4C
	db $2C
	db $5C
	db $2C
	db $4C
	db $2C
	db $C9
SongMacro77:
	db $5D
	db $2D
	db $2D
	db $2D
	db $4D
	db $2D
	db $2D
	db $2D
	db $5D
	db $2D
	db $2D
	db $2D
	db $4D
	db $2D
	db $2D
	db $2D
	db $C9
	
Song0D:
	dw Song0DA
	dw Song0DB
	dw Song0DC
	dw Song0DD
Song0DA:
	db $C4, %11111111
	db $C0, 162
	db $C1, $80
	db $CD
	dw SongMacro78
	db $CE
Song0DB:
	db $C1, $C0
	db $EE
	db $CD
	dw SongMacro78
	db $CE
SongMacro78:
	db $C2, $93
	db $F3
	db $73
	db $D6
	db $F4
	db $23
	db $D6
	db $0C
	db $F3
	db $B3
	db $D6
	db $F4
	db $03
	db $D6
	db $2C
	db $C2
	db $97
	db $49
	db $C9
Song0DC:
	db $C1, $E0
	db $C2, $40
	db $F4
	db $7A
	db $5A
	db $49
	db $CE
Song0DD:
	db $C1, $01
	db $C2
	db $91
	db $05
	db $05
	db $05
	db $05
	db $05
	db $0B
	db $D5
	db $05
	db $05
	db $05
	db $05
	db $05
	db $0B
	db $D5
	db $45
	db $45
	db $45
	db $45
	db $45
	db $41
	db $DC
	db $CE

Song0E:
	dw Song0EA
	dw Song0EB
	dw Song0EC
	dw Song0ED
Song0EA:
	db $C4, %11111111
	db $C0, 168
	db $C1, $40
	db $C2, $93
	db $F1
	db $94
	db $F2
	db $24
	db $44
	db $73
	db $94
	db $F1
	db $94
	db $F2
	db $24
	db $44
	db $73
	db $94
	db $F3
	db $04
	db $24
	db $04
	db $F2
	db $B4
	db $74
	db $B4
	db $92
	db $D4
	db $CE
Song0EB:
	db $C1, $00
	db $C2, $93
	db $EE
	db $F1
	db $94
	db $F2
	db $24
	db $44
	db $73
	db $94
	db $F1
	db $94
	db $F2
	db $24
	db $44
	db $73
	db $94
	db $F3
	db $04
	db $24
	db $04
	db $F2
	db $B4
	db $74
	db $B4
	db $9A
	db $CE
Song0EC:
	db $C1, $E0
	db $C2, $20
	db $F1
	db $94
	db $F2
	db $24
	db $44
	db $73
	db $94
	db $F1
	db $94
	db $F2
	db $24
	db $44
	db $73
	db $94
	db $F3
	db $04
	db $24
	db $04
	db $F2
	db $B4
	db $74
	db $B4
	db $92
	db $D4
	db $CE
Song0ED:
	db $C1, $01
	db $C2, $91
	db $53
	db $54
	db $43
	db $44
	db $53
	db $54
	db $43
	db $44
	db $54
	db $44
	db $54
	db $44
	db $04
	db $44
	db $43
	db $42
	db $CE

Song0F:
	dw Song0FA
	dw Song0FB
	dw Song0FC
	dw Song0FD
Song0FA:
	db $C4, %11111111
	db $C0, 192
Song0FB:
	db $C1, $80
	db $C2, $F3
Song0FBLoop:
	db $E9
	db $C3
	dw Song0FBLoop
Song0FC:
	db $C1, $F0
	db $C2, $20
Song0FCLoop:
	db $E9
	db $C3
	dw Song0FCLoop
	db $CE
Song0FD:
	db $C1, $01
	db $C2, $F1
Song0FDLoop:
	db $E9
	db $C3
	dw Song0FDLoop

SFX00C2:
SFX00C3:
SFX00C4:
	db $FF

SFX01C2:
SFX01C3:
	db $FF
SFX01C4:
	db $05, $F7, $41, $00
	db $05, $F7, $53, $00
	db $05, $F7, $65, $00
	db $05, $F7, $77, $00
	db $05, $E7, $41, $00
	db $05, $E7, $53, $00
	db $05, $E7, $65, $00
	db $05, $E7, $77, $00
	db $05, $D7, $41, $00
	db $05, $D7, $53, $00
	db $05, $D7, $65, $00
	db $05, $D7, $77, $00
	db $05, $C7, $41, $00
	db $05, $C7, $53, $00
	db $05, $C7, $65, $00
	db $05, $C7, $77, $00
	db $05, $B7, $41, $00
	db $05, $B7, $53, $00
	db $05, $B7, $65, $00
	db $05, $B7, $77, $00
	db $05, $A7, $41, $00
	db $05, $A7, $53, $00
	db $05, $A7, $65, $00
	db $05, $A7, $77, $00
	db $05, $97, $41, $00
	db $05, $97, $53, $00
	db $05, $97, $65, $00
	db $05, $97, $77, $00
	db $05, $87, $41, $00
	db $05, $87, $53, $00
	db $05, $87, $65, $00
	db $05, $87, $77, $00
	db $05, $77, $41, $00
	db $05, $77, $53, $00
	db $05, $77, $65, $00
	db $05, $77, $77, $00
	db $05, $67, $41, $00
	db $05, $67, $53, $00
	db $05, $67, $65, $00
	db $05, $67, $77, $00
	db $05, $57, $41, $00
	db $05, $57, $53, $00
	db $05, $57, $65, $00
	db $05, $57, $77, $00
	db $05, $47, $41, $00
	db $05, $47, $53, $00
	db $05, $47, $65, $00
	db $05, $47, $77, $00
	db $05, $37, $41, $00
	db $05, $37, $53, $00
	db $05, $37, $65, $00
	db $05, $37, $77, $00
	db $05, $27, $41, $00
	db $05, $27, $53, $00
	db $05, $27, $65, $00
	db $05, $27, $77, $00
	db $05, $17, $41, $00
	db $05, $17, $53, $00
	db $05, $17, $65, $00
	db $05, $17, $77, $00
	db $FF

SFX02C2:
	db $43, $F3, $B6, $07
	db $43, $F3, $E1, $07
	db $FF

SFX02C3:
SFX02C4:
	db $FF

SFX03C2:
	db $FF

SFX03C3:
	db $04, $20, $80, $01
	db $08, $20, $60, $01
	db $FF

SFX03C4:
	db $00, $F1, $56, $00
	db $00, $F2, $56, $00
	db $FF

SFX04C2:
	db $C2, $F0, $8A, $07
	db $C2, $F0, $83, $07
SFX04C3:
SFX04C4:
	db $FF

SFX05C2:
	db $80, $F3, $C7, $02
	db $FF
SFX05C3:
	db $04, $40, $16, $04
	db $04, $40, $4E, $04
SFX05C4:
	db $FF

SFX06C2:
SFX06C3:
	db $FF
SFX06C4:
	db $04, $F0, $63, $00
	db $04, $F0, $64, $00
	db $04, $F0, $63, $00
	db $08, $F3, $65, $00
	db $04, $F0, $63, $00
	db $04, $F0, $64, $00
	db $04, $F0, $63, $00
	db $08, $F3, $65, $00
	db $FF

SFX07C2:
	db $FF
SFX07C3:
	db $01, $20, $89, $06
	db $01, $20, $9E, $06
	db $01, $20, $89, $06
	db $01, $20, $9E, $06
	db $01, $20, $89, $06
	db $01, $20, $9E, $06
SFX07C4:
	db $FF

SFX08C2:
	db $C4, $F0, $00, $01
	db $C2, $F0, $00, $03
	db $C2, $F0, $40, $03
	db $C2, $F0, $80, $03
	db $C0, $F3, $C0, $03
	db $FF
SFX08C3:
	db $04, $20, $00, $01
	db $02, $20, $00, $03
	db $02, $20, $40, $03
	db $02, $20, $80, $03
	db $02, $20, $C0, $03
	db $01, $20, $00, $04
	db $01, $20, $80, $04
	db $01, $20, $00, $05
	db $01, $20, $80, $05
	db $01, $20, $00, $06
	db $01, $20, $80, $06
SFX08C4:
	db $FF

SFX09C2:
	db $FF
SFX09C3:
	db $02, $20, $C0, $04
	db $02, $20, $80, $04
	db $02, $20, $40, $04
	db $02, $20, $00, $04
	db $02, $20, $C0, $03
	db $02, $20, $80, $03
	db $02, $20, $C0, $04
	db $02, $20, $80, $04
	db $02, $20, $40, $04
	db $02, $20, $00, $04
	db $02, $20, $C0, $03
	db $02, $20, $80, $03
SFX09C4:
	db $FF

SFX0AC2:
	db $FF
SFX0AC3:
	db $01, $20, $42, $06
	db $01, $20, $72, $06
SFX0AC4:
	db $FF

SFX0BC2:
	db $FF
SFX0BC3:
	db $02, $20, $63, $05
	db $02, $20, $63, $05
	db $02, $20, $63, $05
	db $02, $20, $63, $05
	db $02, $20, $63, $05
	db $02, $20, $63, $05
	db $02, $20, $63, $05
	db $02, $20, $63, $05
SFX0BC4:
	db $FF

SFX0CC2:
	db $84, $F0, $72, $06
	db $84, $F0, $89, $06
	db $84, $F0, $72, $06
	db $80, $F1, $89, $06
	db $FF
SFX0CC3:
	db $04, $60, $39, $07
	db $04, $60, $44, $07
	db $04, $60, $39, $07
	db $04, $60, $44, $07
SFX0CC4:
	db $FF

SFX0DC2:
	db $C0, $F1, $16, $04
	db $FF
SFX0DC3:
	db $04, $20, $16, $04
SFX0DC4:
	db $FF

SFX0EC2:
	db $C1, $F0, $80, $07
	db $C1, $F0, $60, $07
	db $C1, $F0, $40, $07
	db $C1, $F0, $20, $07
	db $C1, $F0, $00, $07
SFX0EC3:
	db $FF
SFX0EC4:
	db $02, $F0, $51, $00
	db $FF

SFX0FC2:
	db $41, $F0, $80, $06
	db $41, $F0, $60, $06
	db $41, $F0, $40, $06
	db $41, $F0, $20, $06
	db $41, $F0, $00, $06
SFX0FC3:
	db $FF
SFX0FC4:
	db $02, $F0, $51, $00
	db $FF

SFX10C2:
	db $01, $F0, $C0, $07
	db $01, $F0, $A0, $07
	db $01, $F0, $80, $07
	db $01, $F0, $60, $07
	db $01, $F0, $40, $07
	db $01, $F0, $20, $07
	db $01, $F0, $00, $07
	db $01, $F0, $E0, $06
	db $01, $F0, $C0, $06
	db $01, $F0, $A0, $06
SFX10C3:
	db $FF
SFX10C4:
	db $04, $F0, $51, $00
	db $FF

SFX11C2:
	db $41, $F0, $00, $06
	db $41, $F0, $D6, $06
	db $41, $F0, $00, $06
	db $41, $F0, $D6, $06
	db $41, $F0, $00, $07
	db $41, $F0, $39, $07
	db $41, $F0, $00, $07
	db $41, $F0, $39, $07
	db $41, $F0, $00, $07
	db $41, $F0, $39, $07
	db $41, $F0, $00, $07
	db $41, $F0, $39, $07
SFX11C3:
	db $FF
SFX11C4:
	db $08, $F0, $47, $00
	db $00, $F2, $54, $00
	db $FF

SFX12C2:
	db $01, $A0, $EB, $07
	db $01, $A0, $D6, $07
SFX12C3:
	db $01, $20, $63, $05
	db $01, $20, $C7, $02
	db $01, $20, $63, $05
	db $01, $20, $C7, $02
	db $01, $20, $63, $05
	db $01, $20, $C7, $02
	db $01, $20, $63, $05
	db $01, $20, $C7, $02
	db $FF
SFX12C4:
	db $00, $A1, $52, $00
	db $FF

SFX13C2:
SFX13C3:
	db $FF
SFX13C4:
	db $04, $F0, $52, $00
	db $04, $E0, $53, $00
	db $04, $D0, $40, $00
	db $04, $C0, $41, $00
	db $04, $B0, $52, $00
	db $04, $A0, $53, $00
	db $04, $90, $64, $00
	db $04, $80, $65, $00
	db $FF

SFX14C2:
	db $80, $F1, $CE, $07
SFX14C3:
SFX14C4:
	db $FF

SFX15C2:
SFX15C3:
	db $FF
SFX15C4:
	db $01, $F0, $03, $00
	db $00, $F1, $02, $00
	db $FF

SFX16C2:
SFX16C3:
	db $FF
SFX16C4:
	db $01, $10, $57, $00
	db $01, $20, $57, $00
	db $01, $30, $56, $00
	db $01, $40, $56, $00
	db $01, $50, $55, $00
	db $01, $60, $55, $00
	db $01, $70, $54, $00
	db $01, $80, $54, $00
	db $01, $90, $53, $00
	db $01, $A0, $53, $00
	db $01, $B0, $52, $00
	db $01, $C0, $52, $00
	db $01, $D0, $51, $00
	db $01, $E0, $51, $00
	db $04, $F0, $50, $00
	db $04, $F0, $52, $00
	db $00, $F3, $53, $00
	db $FF

SFX17C2:
	db $41, $F0, $A0, $05
	db $41, $F0, $A8, $05
	db $41, $F0, $B0, $05
	db $41, $F0, $B8, $05
	db $41, $F0, $C0, $05
	db $41, $F0, $C8, $05
SFX17C3:
	db $FF
SFX17C4:
	db $04, $F0, $52, $00
	db $FF

SFX18C2:
	db $41, $F0, $70, $07
	db $41, $E0, $6C, $07
	db $41, $D0, $68, $07
	db $41, $C0, $64, $07
	db $41, $B0, $60, $07
SFX18C3:
SFX18C4:
	db $FF

SFX19C2:
	db $04, $F0, $00, $07
	db $04, $E0, $F8, $06
	db $04, $D0, $F0, $06
	db $04, $C0, $E8, $06
	db $04, $B0, $E0, $06
	db $04, $A0, $D8, $06
	db $04, $90, $D0, $06
	db $04, $80, $C8, $06
	db $04, $70, $C0, $06
	db $04, $60, $B8, $06
	db $04, $50, $B0, $06
	db $04, $40, $A8, $06
	db $04, $30, $A0, $06
	db $04, $20, $98, $06
	db $04, $10, $90, $06
SFX19C3:
SFX19C4:
	db $FF

SFX1AC2:
	db $01, $F0, $E0, $07
	db $01, $D0, $D0, $07
	db $01, $C0, $C0, $07
	db $01, $B0, $B0, $07
	db $01, $A0, $A0, $07
	db $01, $90, $90, $07
	db $01, $80, $80, $07
SFX1AC3:
SFX1AC4:
	db $FF

SFX1BC2:
SFX1BC3:
	db $FF
SFX1BC4:
	db $00, $F1, $54, $00
	db $00, $F2, $52, $00
	db $FF

SFX1CC2:
SFX1CC3:
	db $FF
SFX1CC4:
	db $04, $F0, $65, $00
	db $04, $F0, $64, $00
	db $04, $F0, $51, $00
	db $FF

SFX1DC2:
	db $41, $B0, $50, $07
	db $41, $B0, $54, $07
	db $41, $B0, $58, $07
	db $41, $B0, $5C, $07
	db $41, $B0, $60, $07
	db $41, $C0, $64, $07
	db $41, $D0, $68, $07
	db $41, $E0, $6C, $07
SFX1DC3:
SFX1DC4:
	db $FF

SFX1EC2:
	db $02, $F0, $80, $06
	db $42, $E0, $90, $06
	db $82, $D0, $A0, $06
	db $C2, $C0, $B0, $06
	db $02, $B0, $C0, $06
	db $42, $A0, $D0, $06
	db $82, $90, $E0, $06
	db $C2, $80, $F0, $06
	db $02, $F0, $00, $07
	db $42, $E0, $10, $07
	db $82, $D0, $20, $07
	db $C2, $C0, $30, $07
	db $02, $B0, $40, $07
	db $42, $A0, $50, $07
	db $82, $90, $60, $07
	db $C2, $80, $70, $07
	db $FF
SFX1EC3:
	db $01, $20, $80, $01
	db $01, $20, $90, $01
	db $01, $20, $A0, $01
	db $01, $20, $B0, $01
SFX1EC4:
	db $FF

SFX1FC2:
SFX1FC3:
	db $04, $20, $00, $02
	db $FF
SFX1FC4:
	db $04, $F0, $54, $00
	db $FF

SFX20C2:
	db $C8, $10, $00, $07
	db $C1, $F0, $00, $07
	db $C1, $E0, $08, $07
	db $C1, $D0, $10, $07
	db $C1, $C0, $18, $07
	db $C1, $B0, $20, $07
	db $C1, $A0, $28, $07
SFX20C3:
	db $FF
SFX20C4:
	db $04, $F0, $64, $00
	db $FF

SFX21C2:
SFX21C3:
	db $FF
SFX21C4:
	db $02, $F0, $45, $00
	db $04, $F0, $00, $00
	db $04, $F0, $21, $00
	db $08, $F0, $22, $00
	db $08, $F0, $33, $00
	db $08, $F0, $34, $00
	db $04, $F0, $45, $00
	db $04, $E0, $44, $00
	db $04, $D0, $44, $00
	db $04, $C0, $44, $00
	db $04, $D0, $44, $00
	db $04, $C0, $44, $00
	db $FF

SFX22C2:
SFX22C3:
	db $FF
SFX22C4:
	db $02, $F0, $23, $00
	db $02, $F0, $23, $00
	db $02, $F0, $23, $00
	db $02, $F0, $23, $00
	db $02, $F0, $23, $00
	db $02, $F0, $23, $00
	db $02, $F0, $23, $00
	db $02, $F0, $23, $00
	db $FF

SFX23C2:
	db $81, $80, $19, $06
	db $81, $90, $29, $06
	db $81, $A0, $39, $06
	db $81, $B0, $49, $06
	db $81, $C0, $59, $06
	db $81, $D0, $69, $06
	db $81, $E0, $79, $06
	db $81, $F0, $89, $06
	db $81, $80, $42, $06
	db $81, $90, $52, $06
	db $81, $A0, $62, $06
	db $81, $B0, $72, $06
	db $81, $C0, $82, $06
	db $81, $D0, $92, $06
	db $81, $E0, $A2, $06
	db $81, $F0, $B2, $06
	db $FF
SFX23C3:
	db $01, $20, $B0, $01
	db $01, $20, $C0, $01
	db $01, $20, $D0, $01
	db $01, $20, $E0, $01
	db $01, $20, $F0, $01
	db $01, $20, $00, $02
	db $01, $20, $10, $02
	db $01, $20, $20, $02
	db $01, $20, $58, $02
	db $01, $20, $68, $02
	db $01, $20, $78, $02
	db $01, $20, $88, $02
	db $01, $20, $98, $02
	db $01, $20, $A8, $02
	db $01, $20, $B8, $02
	db $01, $20, $C8, $02
SFX23C4:
	db $FF

SFX24C2:
	db $C1, $80, $70, $07
	db $81, $90, $60, $07
	db $41, $A0, $50, $07
	db $01, $B0, $40, $07
	db $C1, $80, $70, $07
	db $81, $90, $60, $07
	db $41, $A0, $50, $07
	db $01, $B0, $40, $07
	db $C1, $C0, $30, $07
	db $81, $D0, $20, $07
	db $41, $E0, $10, $07
	db $01, $F0, $00, $07
	db $C1, $C0, $30, $07
	db $81, $D0, $20, $07
	db $41, $E0, $10, $07
	db $01, $F0, $00, $07
	db $C1, $80, $F0, $06
	db $81, $90, $E0, $06
	db $41, $A0, $D0, $06
	db $01, $B0, $C0, $06
	db $C1, $C0, $B0, $06
	db $81, $D0, $A0, $06
	db $41, $E0, $90, $06
	db $01, $F0, $80, $06
SFX24C3:
SFX24C4:
	db $FF

SFX25C2:
SFX25C3:
	db $FF
SFX25C4:
	db $00, $F1, $52, $00
	db $02, $F0, $50, $00
	db $02, $F0, $51, $00
	db $02, $F0, $50, $00
	db $02, $F0, $51, $00
	db $FF

SFX26C2:
	db $04, $C0, $B2, $06
	db $04, $C0, $D6, $06
	db $90, $10, $D6, $06
	db $04, $C0, $B2, $06
	db $04, $C0, $D6, $06
	db $90, $10, $D6, $06
SFX26C3:
	db $FF
SFX26C4:
	db $00, $F1, $00, $00
	db $90, $10, $00, $00
	db $00, $F1, $00, $00
	db $90, $10, $00, $00
	db $FF

SFX27C2:
	db $01, $F0, $80, $07
	db $01, $F0, $60, $07
	db $01, $F0, $40, $07
	db $01, $F0, $20, $07
	db $01, $F0, $00, $07
	db $01, $F0, $80, $06
	db $01, $F0, $60, $06
	db $01, $F0, $40, $06
	db $01, $F0, $20, $06
	db $01, $F0, $00, $06
SFX27C3:
	db $FF
SFX27C4:
	db $04, $F0, $51, $00
	db $FF

SFX28C2:
	db $C2, $F0, $80, $06
	db $C1, $F0, $60, $06
	db $C1, $F0, $40, $06
	db $C1, $F0, $20, $06
	db $C1, $F0, $00, $06
	db $C2, $F0, $80, $06
	db $C1, $F0, $60, $06
	db $C1, $F0, $40, $06
	db $C1, $F0, $20, $06
	db $C1, $F0, $00, $06
	db $C2, $F0, $80, $04
	db $C1, $F0, $60, $04
	db $C1, $F0, $40, $04
	db $C1, $F0, $20, $04
	db $C1, $F0, $00, $04
SFX28C3:
	db $FF
SFX28C4:
	db $04, $F0, $51, $00
	db $FF

SFX29C2:
	db $82, $F0, $90, $06
	db $82, $E0, $98, $06
	db $82, $D0, $A0, $06
	db $82, $C0, $A8, $06
	db $82, $B0, $B0, $06
	db $82, $A0, $B8, $06
	db $82, $90, $C0, $06
	db $82, $80, $C8, $06
	db $82, $70, $D0, $06
	db $82, $60, $D8, $06
	db $82, $50, $E0, $06
	db $82, $40, $E8, $06
	db $82, $30, $F0, $06
	db $82, $20, $F8, $06
	db $82, $10, $00, $07
SFX29C3:
SFX29C4:
	db $FF

SFX2AC2:
SFX2AC3:
	db $FF
SFX2AC4:
	db $02, $F0, $56, $00
	db $02, $40, $56, $00
	db $02, $F0, $56, $00
	db $02, $40, $56, $00
	db $02, $F0, $56, $00
	db $02, $40, $56, $00
	db $02, $F0, $56, $00
	db $02, $40, $56, $00
	db $02, $F0, $56, $00
	db $02, $40, $56, $00
	db $02, $F0, $56, $00
	db $02, $40, $56, $00
	db $02, $F0, $56, $00
	db $02, $40, $56, $00
	db $02, $F0, $56, $00
	db $02, $40, $56, $00
	db $02, $F0, $56, $00
	db $02, $40, $56, $00
	db $02, $F0, $56, $00
	db $02, $40, $56, $00
	db $02, $F0, $56, $00
	db $02, $40, $56, $00
	db $02, $F0, $56, $00
	db $02, $40, $56, $00
	db $02, $F0, $56, $00
	db $02, $40, $56, $00
	db $02, $F0, $56, $00
	db $02, $40, $56, $00
	db $02, $F0, $56, $00
	db $02, $40, $56, $00
	db $02, $F0, $56, $00
	db $02, $40, $56, $00
	db $FF

SFX2BC2:
	db $81, $F0, $60, $07
	db $81, $E0, $64, $07
	db $81, $D0, $68, $07
	db $81, $C0, $6C, $07
	db $81, $B0, $70, $07
	db $81, $A0, $74, $07
	db $81, $90, $78, $07
	db $81, $80, $7C, $07
SFX2BC3:
SFX2BC4:
	db $FF

SFX2CC2:
SFX2CC3:
	db $FF
SFX2CC4:
	db $04, $F0, $52, $00
	db $04, $F0, $32, $00
	db $02, $F0, $12, $00
	db $FF

SFX2DC2:
	db $01, $F1, $7F, $07
	db $01, $F0, $00, $04
	db $01, $E0, $10, $04
	db $01, $D0, $20, $04
	db $01, $C0, $30, $04
	db $01, $B0, $40, $04
	db $01, $A0, $50, $04
	db $01, $90, $60, $04
	db $01, $80, $70, $04
	db $01, $70, $80, $04
	db $FF

SFX2DC3:
SFX2DC4:
	db $FF

SFX2EC2:
	db $81, $F0, $80, $06
	db $81, $E0, $90, $06
	db $81, $D0, $A0, $06
	db $81, $C0, $B0, $06
	db $81, $B0, $C0, $06
	db $81, $A0, $D0, $06
	db $81, $90, $E0, $06
	db $81, $80, $F0, $06
	db $81, $F0, $00, $07
	db $81, $E0, $10, $07
	db $81, $D0, $20, $07
	db $81, $C0, $30, $07
	db $81, $F0, $00, $07
	db $81, $E0, $10, $07
	db $81, $D0, $20, $07
	db $81, $C0, $30, $07
	db $81, $B0, $40, $07
	db $81, $A0, $50, $07
	db $81, $90, $60, $07
	db $81, $80, $70, $07
	db $81, $B0, $40, $07
	db $81, $A0, $50, $07
	db $81, $90, $60, $07
	db $81, $80, $70, $07
	db $81, $80, $80, $06
	db $81, $70, $90, $06
	db $81, $60, $A0, $06
	db $81, $50, $B0, $06
	db $81, $40, $C0, $06
	db $81, $30, $D0, $06
	db $81, $20, $E0, $06
	db $81, $10, $F0, $06
	db $81, $80, $00, $07
	db $81, $60, $10, $07
	db $81, $40, $20, $07
	db $81, $20, $30, $07
	db $81, $80, $00, $07
	db $81, $70, $10, $07
	db $81, $60, $20, $07
	db $81, $50, $30, $07
	db $81, $40, $40, $07
	db $81, $30, $50, $07
	db $81, $20, $60, $07
	db $81, $10, $70, $07
	db $81, $40, $40, $07
	db $81, $30, $50, $07
	db $81, $20, $60, $07
	db $81, $10, $70, $07
	db $FF
SFX2EC3:
SFX2EC4:
	db $FF

SFX2FC2:
	db $41, $F0, $80, $06
	db $41, $F0, $F0, $06
	db $42, $F0, $10, $07
	db $41, $E0, $30, $07
	db $41, $D0, $50, $07
	db $41, $C0, $70, $07
	db $41, $B0, $90, $07
	db $41, $A0, $B0, $07
	db $41, $90, $D0, $07
	db $41, $80, $F0, $07
	db $42, $80, $10, $07
	db $41, $70, $30, $07
	db $41, $60, $50, $07
	db $41, $50, $70, $07
	db $41, $40, $90, $07
	db $41, $30, $B0, $07
	db $41, $20, $D0, $07
	db $41, $10, $F0, $07
SFX2FC3:
SFX2FC4:
	db $FF

SFX30C2:
SFX30C3:
	db $FF
SFX30C4:
	db $02, $F0, $42, $00
	db $FF

SFX31C2:
	db $84, $F0, $C7, $02
	db $84, $F0, $58, $03
SFX31C3:
SFX31C4:
	db $FF

SFX32C2:
	db $04, $40, $22, $02
	db $04, $40, $22, $02
	db $04, $40, $22, $02
	db $04, $40, $22, $02
	db $41, $B0, $40, $07
	db $41, $B0, $44, $07
	db $41, $B0, $48, $07
	db $41, $B0, $4C, $07
	db $41, $B0, $50, $07
	db $41, $C0, $54, $07
	db $41, $D0, $58, $07
	db $41, $E0, $5C, $07
	db $FF
SFX32C3:
	db $FF
SFX32C4:
	db $04, $F0, $44, $00
	db $04, $F0, $44, $00
	db $04, $F0, $44, $00
	db $04, $F0, $44, $00
	db $FF

SFX33C2:
	db $02, $F0, $7F, $07
	db $02, $F0, $6F, $07
	db $FF
SFX33C3:
	db $02, $20, $7F, $07
	db $02, $20, $6F, $07
	db $FF
SFX33C4:
	db $00, $F1, $22, $00
	db $FF

SFX34C2:
SFX34C3:
	db $FF
SFX34C4:
	db $01, $F0, $55, $00
	db $FF

SFX35C2:
	db $81, $F0, $64, $07
	db $81, $E0, $68, $07
	db $81, $D0, $6C, $07
	db $81, $C0, $70, $07
	db $81, $B0, $74, $07
	db $81, $A0, $78, $07
	db $81, $90, $7C, $07
	db $81, $80, $7F, $07
SFX35C3:
SFX35C4:
	db $FF

SFX36C2:
	db $01, $F0, $D0, $05
	db $41, $E8, $E0, $05
	db $81, $E0, $F0, $05
	db $C1, $D8, $00, $06
SFX36C3:
SFX36C4:
	db $FF

SFX37C2:
	db $02, $F0, $60, $07
	db $41, $E0, $64, $07
	db $81, $D0, $68, $07
	db $C1, $C0, $6C, $07
	db $01, $B0, $70, $07
	db $41, $A0, $74, $07
	db $81, $90, $78, $07
	db $C1, $F0, $7C, $07
	db $C2, $80, $60, $07
	db $41, $70, $64, $07
	db $81, $60, $68, $07
	db $C1, $50, $6C, $07
	db $01, $40, $70, $07
	db $41, $30, $74, $07
	db $81, $20, $78, $07
	db $81, $80, $7C, $07
SFX37C3:
SFX37C4:
	db $FF

SFX38C2:
	db $81, $F0, $7F, $07
	db $81, $E0, $7C, $07
	db $81, $D0, $78, $07
	db $81, $C0, $74, $07
	db $81, $B0, $60, $07
	db $81, $A0, $6C, $07
	db $81, $90, $68, $07
	db $81, $80, $64, $07
	db $81, $70, $50, $07
	db $81, $60, $5C, $07
	db $81, $50, $58, $07
	db $81, $40, $54, $07
	db $81, $30, $40, $07
	db $81, $20, $4C, $07
	db $80, $13, $48, $07
SFX38C3:
SFX38C4:
	db $FF

SFX39C2:
	db $82, $F0, $22, $02
	db $FF
SFX39C3:
	db $02, $F0, $22, $02
	db $FF
SFX39C4:
	db $01, $80, $21, $00
	db $FF

SFX3AC2:
	db $FF
SFX3AC3:
	db $02, $00, $7F, $07
	db $01, $20, $7F, $07
	db $FF
SFX3AC4:
	db $02, $C2, $20, $00
	db $08, $F0, $56, $00
	db $08, $F0, $55, $00
	db $01, $F0, $23, $00
	db $01, $E0, $22, $00
	db $02, $D0, $21, $00
	db $00, $C2, $20, $00
	db $FF

SFX3BC2:
SFX3BC3:
	db $FF
SFX3BC4:
	db $01, $F0, $54, $00
	db $02, $F0, $24, $00
	db $02, $F0, $34, $00
	db $01, $F0, $55, $00
	db $01, $F0, $54, $00
	db $01, $F0, $53, $00
	db $01, $F0, $52, $00
	db $01, $F0, $51, $00
	db $00, $F3, $50, $00
	db $FF

SFX3CC2:
	db $04, $C0, $CE, $07
	db $00, $C1, $D1, $07
	db $FF
SFX3CC3:
	db $04, $F0, $CE, $07
	db $80, $F1, $D1, $07
SFX3CC4:
	db $FF

SFX3DC2:
SFX3DC3:
	db $FF
SFX3DC4:
	db $02, $F0, $52, $00
	db $02, $E0, $53, $00
	db $02, $D0, $40, $00
	db $02, $C0, $41, $00
	db $02, $B0, $52, $00
	db $02, $A5, $53, $00
	db $FF

SFX3EC2:
	db $FF
SFX3EC3:
	db $01, $20, $00, $05
	db $01, $00, $00, $05
	db $01, $20, $00, $05
	db $01, $00, $00, $05
	db $01, $20, $00, $05
	db $01, $00, $00, $05
	db $01, $20, $00, $05
	db $01, $00, $00, $05
	db $01, $20, $00, $05
	db $01, $00, $00, $05
	db $01, $20, $00, $05
	db $01, $00, $00, $05
	db $01, $20, $00, $05
	db $01, $00, $00, $05
	db $01, $20, $00, $05
	db $01, $00, $00, $05
	db $01, $20, $00, $05
	db $01, $00, $00, $05
	db $01, $20, $00, $05
	db $01, $00, $00, $05
SFX3EC4:
	db $FF

SFX3FC2:
	db $08, $F0, $E5, $04
	db $01, $10, $E5, $04
	db $10, $F0, $E5, $04
	db $FF
SFX3FC3:
	db $08, $20, $E5, $04
	db $01, $60, $E5, $04
	db $10, $20, $E5, $04
SFX3FC4:
	db $FF

SFX40C2:
	db $84, $F0, $00, $02
	db $82, $F0, $00, $04
	db $82, $F0, $40, $04
	db $82, $F0, $80, $04
	db $80, $F3, $C0, $04
SFX40C3:
SFX40C4:
	db $FF

SFX41C2:
SFX41C3:
	db $FF
SFX41C4:
	db $00, $F1, $11, $00
	db $00, $F1, $12, $00
	db $00, $F1, $11, $00
	db $00, $F1, $12, $00
	db $FF

SFX42C2:
	db $01, $F0, $F0, $07
	db $01, $EF, $E0, $07
	db $01, $EE, $D0, $07
	db $01, $ED, $C0, $07
	db $01, $EC, $B0, $07
	db $01, $EB, $A0, $07
	db $01, $EA, $90, $07
	db $01, $E9, $80, $07
	db $01, $E8, $70, $07
	db $01, $E7, $60, $07
	db $01, $E6, $50, $07
	db $01, $E5, $40, $07
	db $01, $E4, $30, $07
	db $01, $E3, $20, $07
	db $01, $E2, $10, $07
	db $01, $E1, $00, $07
	db $01, $E0, $F0, $06
	db $01, $DF, $E0, $06
	db $01, $DE, $D0, $06
	db $01, $DD, $C0, $06
	db $01, $DC, $B0, $06
	db $01, $DB, $A0, $06
	db $01, $DA, $90, $06
	db $01, $D9, $80, $06
	db $01, $C0, $F0, $07
	db $01, $BF, $E0, $07
	db $01, $BE, $D0, $07
	db $01, $BD, $C0, $07
	db $01, $BC, $B0, $07
	db $01, $BB, $A0, $07
	db $01, $BA, $90, $07
	db $01, $B9, $80, $07
	db $01, $B8, $70, $07
	db $01, $B7, $60, $07
	db $01, $B6, $50, $07
	db $01, $B5, $40, $07
	db $01, $B4, $30, $07
	db $01, $B3, $20, $07
	db $01, $B2, $10, $07
	db $01, $B1, $00, $07
	db $01, $B0, $F0, $06
	db $01, $AF, $E0, $06
	db $01, $AE, $D0, $06
	db $01, $AD, $C0, $06
	db $01, $AC, $B0, $06
	db $01, $AB, $A0, $06
	db $01, $AA, $90, $06
	db $01, $A9, $80, $06
	db $01, $80, $F0, $07
	db $01, $7F, $E0, $07
	db $01, $7E, $D0, $07
	db $01, $7D, $C0, $07
	db $01, $7C, $B0, $07
	db $01, $7B, $A0, $07
	db $01, $7A, $90, $07
	db $01, $79, $80, $07
	db $01, $78, $70, $07
	db $01, $77, $60, $07
	db $01, $76, $50, $07
	db $01, $75, $40, $07
	db $01, $74, $30, $07
	db $01, $73, $20, $07
	db $01, $72, $10, $07
	db $01, $71, $00, $07
	db $01, $70, $F0, $06
	db $01, $6F, $E0, $06
	db $01, $6E, $D0, $06
	db $01, $6D, $C0, $06
	db $01, $6C, $B0, $06
	db $01, $6B, $A0, $06
	db $01, $6A, $90, $06
	db $01, $69, $80, $06
	db $01, $40, $F0, $07
	db $01, $3F, $E0, $07
	db $01, $3E, $D0, $07
	db $01, $3D, $C0, $07
	db $01, $3C, $B0, $07
	db $01, $3B, $A0, $07
	db $01, $3A, $90, $07
	db $01, $39, $80, $07
	db $01, $38, $70, $07
	db $01, $37, $60, $07
	db $01, $36, $50, $07
	db $01, $35, $40, $07
	db $01, $34, $30, $07
	db $01, $33, $20, $07
	db $01, $32, $10, $07
	db $01, $31, $00, $07
	db $01, $30, $F0, $06
	db $01, $2F, $E0, $06
	db $01, $2E, $D0, $06
	db $01, $2D, $C0, $06
	db $01, $2C, $B0, $06
	db $01, $2B, $A0, $06
	db $01, $2A, $90, $06
	db $01, $29, $80, $06
SFX42C3:
SFX42C4:
	db $FF

SFX43C2:
SFX43C3:
SFX43C4:
	db $FF
	
SECTION "Audio RAM_Interface", WRAMX[AudioRAM1]
MusCtrl:			ds 1
SFXCtrl:			ds 1
MusID:				ds 1

SECTION "Audio RAM_Main", HRAM[AudioRAM2]
;$FFB0
Ch1Pos:				ds 2
Ch2Pos:				ds 2
Ch3Pos:				ds 2
Ch4Pos:				ds 2

;$FFB8
Ch1Ret:				ds 2
Ch2Ret:				ds 2
Ch3Ret:				ds 2
Ch4Ret:				ds 2

;$FFC0
Ch1OctPtr:			ds 2
Ch2OctPtr:			ds 2
Ch3OctPtr:			ds 2
Ch4OctPtr:			ds 2

;$FFC8
Ch1Delay:			ds 1
Ch2Delay:			ds 1
Ch3Delay:			ds 1
Ch4Delay:			ds 1

;$FFCC
Ch1Oct:				ds 1
Ch2Oct:				ds 1
Ch3Oct:				ds 1
Ch4Oct:				ds 1

;$FFD0
MusNR12Init:		ds 1
MusNR22Init:		ds 1
MusNR32Init:		ds 1
MusNR42Init:		ds 1

;$FFD4
MusNR12:			ds 1
MusNR13:			ds 1
MusNR14:			ds 1
MusNR22:			ds 1
MusNR23:			ds 1
MusNR24:			ds 1
MusNR31:			ds 1
MusNR32:			ds 1
MusNR33:			ds 1
MusNR34:			ds 1
MusNR41:			ds 1
MusNR42:			ds 1
MusNR43:			ds 1
MusNR44:			ds 1
MusNR51:			ds 1

;$FFE3
SFXCh2Pos:			ds 2
SFXCh2Delay:		ds 1	;$FFE5
SFXCh2Used:			ds 1
SFXCh3Pos:			ds 2
SFXCh3Delay:		ds 1	;$FFE9
SFXCh3Used:			ds 1
SFXCh4Pos:			ds 2
SFXCh4Delay:		ds 1	;$FFED
SFXCh4Used:			ds 1

;$FFEF
SoundTimer:		 	ds 1