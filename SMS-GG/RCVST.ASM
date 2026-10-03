;RoboCop vs. The Terminator (GG) audio disassembly
;Original audio & code by Mark Cooksey
;Disassembly by Will Trowbridge

.DEFINE Port_PSG 0x7F EXPORT

.ORG $0215
	jp Init

	jp LoadSong

	jp PlaySongSFX

	jp LoadSFX

	jp MusicOff

	jp MusicOn

PlaySongSFX:
	;Check if music is enabled
	ld a, (MusicPlayFlag)
	and a
	;If not, then just play SFX
	jr z, .PlaySFX
	call PlaySongC1
.PlaySFX
	call CheckC1SFX
	call ProcessC1
	ret

;Initialize RAM variables
Init:
	;Set default volume values
	ld a, 15
	ld (C1Vol), a
	ld (C2Vol), a
	ld (C3Vol), a
	ld (C4Vol), a
	ld (C1SFXVol), a
	ld (C2SFXVol), a
	ld (C3SFXVol), a
	ld (C4SFXVol), a
	
	;Clear play flags
	xor a
	ld (C1PlayFlag), a
	ld (C2PlayFlag), a
	ld (C3PlayFlag), a
	ld (C4PlayFlag), a
	
	;Clear SFX positions
	ld (C1SFXPos), a
	ld (C1SFXPos+1), a
	ld (C2SFXPos), a
	ld (C2SFXPos+1), a
	ld (C3SFXPos), a
	ld (C3SFXPos+1), a
	ld (C4SFXPos), a
	ld (C4SFXPos+1), a
	ld (MusicPlayFlag), a
	call ProcessC1
	ret

LoadSong:
	ld b, a
	;Load song number into RAM
	ld a, (MusicSwitch)
	;If music on/off value is 0 (off), then set to maximum value (music off)
	or a
	jr nz, .LoadSong2
	ld b, 7
.LoadSong2
	;Get song address
	;x10 bytes = Song entry length
	ld a, b
	add a, a
	add a, a
	add a, a
	add a, b
	add a, b
	ld hl, SongTab
	add a, l
	ld l, a
	jr nc, .LoadSong3
	inc h
.LoadSong3
	;Load starting positions and note length pointers into RAM
	ld a, (hl)
	ld (C1Pos), a
	inc hl
	ld a, (hl)
	ld (C1Pos+1), a
	inc hl
	ld a, (hl)
	ld (C2Pos), a
	inc hl
	ld a, (hl)
	ld (C2Pos+1), a
	inc hl
	ld a, (hl)
	ld (C3Pos), a
	inc hl
	ld a, (hl)
	ld (C3Pos+1), a
	inc hl
	ld a, (hl)
	ld (C4Pos), a
	inc hl
	ld a, (hl)
	ld (C4Pos+1), a
	inc hl
	ld a, (hl)
	ld (NoteLens), a
	inc hl
	ld a, (hl)
	ld (NoteLens+1), a
	
	;Set default volumes
	ld a, 15
	ld (C1Vol), a
	ld (C2Vol), a
	ld (C3Vol), a
	ld (C4Vol), a
	
	;Disable macro transpose
	xor a
	ld (C1MacroTrans), a
	ld (C2MacroTrans), a
	ld (C3MacroTrans), a
	
	;Clear macro times left flag
	ld (C1MacroTimesLeft), a
	ld (C2MacroTimesLeft), a
	ld (C3MacroTimesLeft), a
	ld (C4MacroTimesLeft), a
	
	;Enable play flags
	ld a, 1
	ld (C1PlayFlag), a
	ld (C2PlayFlag), a
	ld (C3PlayFlag), a
	ld (C4PlayFlag), a
	
	;Set default delay values
	ld (C1EnvSeqDelay), a
	ld (C2EnvSeqDelay), a
	ld (C3EnvSeqDelay), a
	ld (C4EnvSeqDelay), a
	ld (C1VibSeqDelay), a
	ld (C2VibSeqDelay), a
	ld (C3VibSeqDelay), a
	ld (C1ModSeqDelay), a
	ld (C2ModSeqDelay), a
	ld (C3ModSeqDelay), a
	ld (C1Delay), a
	ld (C2Delay), a
	ld (C3Delay), a
	ld (C4Delay), a
	
	;Also set "play music" flag
	ld (MusicPlayFlag), a
	
	;Set default tempo and beat count
	ld a, 255
	ld (Tempo), a
	
	xor a
	ld (BeatCounter), a
	ret

;Disable music
MusicOff:
	xor a
	ld (MusicPlayFlag), a
	ld a, 15
	ld (C1Vol), a
	ld (C2Vol), a
	ld (C3Vol), a
	ld (C4Vol), a
	ret

;Enable music
MusicOn:
	ld a, 1
	ld (MusicPlayFlag), a
	ret

PlaySongC1:
	;Get the current song tempo and number of beats
	ld a, (Tempo)
	ld b, a
	ld a, (BeatCounter)
	add a, b
	ld (BeatCounter), a
	;Don't update if no overflow
	ret nc
	
	;Check to see if channel 1 is active
	ld a, (C1PlayFlag)
	and a
	;If not, then skip to channel 2
	jp z, PlaySongC2
	;Otherwise, decrement channel 1 delay
	ld hl, C1Delay
	dec (hl)
	;If not done playing, then process envelope/vibrato/pitch modulation
	jp nz, .C1ProcessInsSeqs
	
	;Update channel 1 position
	ld a, (C1Pos)
	ld l, a
	ld a, (C1Pos+1)
	ld h, a
.C1GetNextByte
	xor a
	ld (C1InsAdd), a
	;Check current byte value
	ld a, (hl)
	;Is bit 1 set?
	cp $80
	jr c, .C1CheckVCMD	
	;If so, then add to instrument count (instrument is +16)
	ld a, $10
	ld (C1InsAdd), a
	jr .C1GetNote

;Is it over 60?
.C1CheckVCMD
	cp $60
	;Then it is a VCMD...
	jr nc, .C1GetVCMD
;Otherwise, it is a note
.C1GetNote
	;Get the current transpose
	ld a, (C1MacroTrans)
	ld b, a
	;Mask out the highest bit
	ld a, (hl)
	and %01111111
	;Add the transpose
	add a, b
	;Load the note into RAM
	ld (C1Note), a
	call GetFreq
	ld a, e
	ld (C1Freq), a
	ld a, d
	ld (C1Freq+1), a
	;Get the next byte
	inc hl
	ld a, (hl)
	;Mask out the lower 4 bits to get the instrument number
	and %11110000
	;Shift right 4 bits
	srl a
	srl a
	srl a
	srl a
	;If 16 or over, OR 16 to total
	ld b, a
	ld a, (C1InsAdd)
	or b
	;Now load the instrument values into RAM
	ld bc, C1EnvSeqDelay
	push hl
	call ProcessInst
	pop hl

;Now get the note length
.C1GetLen
	;Load the current note length pointer from RAM
	ld a, (NoteLens)
	ld e, a
	ld a, (NoteLens+1)
	ld d, a

	;Mask out the upper 4 bits to get the note length index
	ld a, (hl)
	and %00001111
	;Add the index to get the length value
	add a, e
	ld e, a
	jr nc, .C1GetLen2
	inc d
.C1GetLen2
	;Store the value in RAM
	ld a, (de)
	ld (C1Delay), a
.C1UpdatePos
	;Update the current position
	inc hl
	ld a, l
	ld (C1Pos), a
	ld a, h
	ld (C1Pos+1), a
	jp .C1ProcessInsSeqs

.C1GetVCMD
;Check the current voice command (VCMD)

.C1EventTie
;Delay the next note by length, increasing note length
;Parameters: -x (- = unused, x = length)
	;Is this the command?
	cp $60
	;If not, then check for next command
	jr nz, .C1EventStop
	
	;Get the note length from the next byte and the note lengths pointer
	inc hl
	ld a, (NoteLens)
	ld e, a
	ld a, (NoteLens+1)
	ld d, a
	ld a, (hl)
	;Mask out the upper 4 bits to get the length index
	and %00001111
	;Add it to get the pointer to the pointer to the length
	add a, e
	ld e, a
	jr nc, .C1EventTie2
	inc d
.C1EventTie2
	;Set the delay
	ld a, (de)
	ld (C1Delay), a
	;Update the pointer
	jr .C1UpdatePos

.C1EventStop
;Stop the channel
	;Is this the command?
	cp $61
	;If not, then check for next command
	jr nz, .C1EventJump
	
	;Set the channel play flag to 0
	xor a
	ld (C1PlayFlag), a
	;Also set volume to default
	ld a, 15
	ld (C1Vol), a
	;Go to next channel
	jp PlaySongC2

.C1EventJump
;Jump to the following pointer (used for looping)
;Parameters: xx xx (x = Pointer)
	;Is this the command?
	cp $62
	;If not, then check for next command
	jr nz, .C1EventNoise
	
	inc hl
	ld e, (hl)
	inc hl
	ld d, (hl)
	ld h, d
	ld l, e
	jp .C1GetNextByte

.C1EventNoise
;Change the noise (channel 4) "fee.dback" value
;Parameters: xx (X = Value)
	;Is this the command?
	cp $63
	;If not, then check for next command
	jr nz, .C1EventMacro
	
	;Get next noise parameter and load it into RAM
	inc hl
	ld a, (hl)
	ld (C4Noise), a
	inc hl
	jp .C1GetNextByte

.C1EventMacro
;Go to a macro (subroutine) with transpose for specified number of times
;Parameters: xx yy zz (X = Macro number, Y = Transpose, Z = Number of times)
;(Note: 1 level only)
	;Is this the command?
	cp $64
	;If not, then check for next command
	jr nz, .C1EventMacroRet
	
	;Get the macro transpose value and load it into RAM
	ld bc, C1MacroTrans
	call ProcessMacro
	ld h, b
	ld l, c
	jp .C1GetNextByte

.C1EventMacroRet
;Return from the current macro
	;Is this the command?
	cp $65
	;If not, then check for next command
	jr nz, .C1EventCondFlag
	
	ld hl, C1MacroTimesLeft
	call ProcessMacroRet
	ld h, b
	ld l, c
	jp .C1GetNextByte

.C1EventCondFlag
;Set a conditional flag (not used by the driver)
;Parameters: xx (X = Value)	
	;Is this the command?
	cp $66
	;If not, then check for next command
	jr nz, .C1EventNoteLens
	
	inc hl
	ld a, (hl)
	ld (LoopFlag), a
	inc hl
	jp .C1GetNextByte

.C1EventNoteLens
;Set note lengths from the following pointer (for all channels)
;Parameters: xx xx (X = Pointer)
	;Is this the command?
	cp $67
	;If not, then check for next command
	jr nz, .C1EventTempo
	
	inc hl
	ld a, (hl)
	ld (NoteLens), a
	inc hl
	ld a, (hl)
	ld (NoteLens+1), a
	inc hl
	jp .C1GetNextByte

.C1EventTempo
;Set the tempo
;Parameters: x (X = Value)
	;Is this the command?
	cp $68
	;If not, then disable channel
	jr nz, .C1Disable
	
	inc hl
	ld a, (hl)
	ld (Tempo), a
	inc hl
	jp .C1GetNextByte

.C1Disable
	xor a
	ld (C1PlayFlag), a
	ld (C1Vol), a
	;Skip to next channel
	jp PlaySongC2

;Get instrument parameter bytes
.C1ProcessInsSeqs
	;Process the channel envelope from sequence
	ld hl, C1EnvSeqDelay
	ld bc, C1Vol
	call ProcessEnvSeq
	;Process the channel vibrato from sequence 
	ld hl, C1VibSeqDelay
	ld bc, C1Freq
	call ProcessVibrato
	;Process the channel pitch modulation from sequence
	ld hl, C1ModSeqDelay
	ld bc, C1Freq
	call ProcessModSeq

PlaySongC2:
	;Check to see if channel 2 is active
	ld a, (C2PlayFlag)
	and a
	;If not, then skip to channel 3
	jp z, PlaySongC3
	;Otherwise, decrement channel 2 delay
	ld hl, C2Delay
	dec (hl)
	;If not done playing, then process envelope/vibrato/pitch modulation
	jp nz, .C2ProcessInsSeqs
	
	;Update channel 2 position
	ld a, (C2Pos)
	ld l, a
	ld a, (C2Pos+1)
	ld h, a
.C2GetNextByte
	xor a
	ld (C2InsAdd), a
	;Check current byte value
	ld a, (hl)
	cp $80
	jr c, .C2CheckVCMD
	;If so, then add to instrument count (instrument is +16)
	ld a, $10
	ld (C2InsAdd), a
	jr .C2GetNote

;Is it over 60?
.C2CheckVCMD
	cp $60
	;Then it is a VCMD...
	jr nc, .C2GetVCMD
;Otherwise, it is a note
.C2GetNote
	;Get the current transpose
	ld a, (C2MacroTrans)
	ld b, a
	;Mask out the highest bit
	ld a, (hl)
	and %01111111
	;Add the transpose
	add a, b
	;Load the note into RAM
	ld (C2Note), a
	call GetFreq
	ld a, e
	ld (C2Freq), a
	ld a, d
	ld (C2Freq+1), a
	;Get the next byte
	inc hl
	ld a, (hl)
	;Mask out the lower 4 bits to get the instrument number
	and %11110000
	;Shift left 4 bits
	srl a
	srl a
	srl a
	srl a
	;If 16 or over, OR 16 to total
	ld b, a
	ld a, (C2InsAdd)
	or b
	;Now load the instrument values into RAM
	ld bc, C2EnvSeqDelay
	push hl
	call ProcessInst
	pop hl
	
;Now get the note length
.C2GetLen
	;Load the current note length pointer from RAM
	ld a, (NoteLens)
	ld e, a
	ld a, (NoteLens+1)
	ld d, a
	
	;Mask out the upper 4 bits to get the note length index
	ld a, (hl)
	and %00001111
	add a, e
	ld e, a
	jr nc, .C2GetLen2
	inc d
.C2GetLen2
	;Store the value in RAM
	ld a, (de)
	ld (C2Delay), a
.C2UpdatePos
	;Update the current position
	inc hl
	ld a, l
	ld (C2Pos), a
	ld a, h
	ld (C2Pos+1), a
	jp .C2ProcessInsSeqs

.C2GetVCMD
;Check the current voice command (VCMD)

.C2EventTie
;Delay the next note by length, increasing note length
;Parameters: -x (- = unused, x = length)
	;Is this the command?
	cp $60
	;If not, then check for next command
	jr nz, .C2EventStop
	
	;Get the note length from the next byte and the note lengths pointer
	inc hl
	ld a, (NoteLens)
	ld e, a
	ld a, (NoteLens+1)
	ld d, a
	ld a, (hl)
	;Mask out the upper 4 bits to get the length index
	and %00001111
	;Add it to get the pointer to the pointer to the length
	add a, e
	ld e, a
	jr nc, .C2EventTie2
	inc d
.C2EventTie2
	;Set the delay
	ld a, (de)
	ld (C2Delay), a
	;Update the pointer
	jr .C2UpdatePos

.C2EventStop
;Stop the channel
	;Is this the command?
	cp $61
	;If not, then check for next command
	jr nz, .C2EventJump
	
	;Set the channel play flag to 0
	xor a
	ld (C2PlayFlag), a
	;Also set volume to default
	ld a, 15
	ld (C2Vol), a
	;Go to next channel
	jp PlaySongC3

.C2EventJump
;Parameters: xx xx (x = Pointer)
	;Is this the command?
	cp $62
	;If not, then check for next command
	jr nz, .C2EventNoise
	
	inc hl
	ld e, (hl)
	inc hl
	ld d, (hl)
	ld h, d
	ld l, e
	jp .C2GetNextByte

.C2EventNoise
;Change the noise (channel 4) "fee.dback" value
;Parameters: xx (X = Value)
	;Is this the command?
	cp $63
	;If not, then check for next command
	jr nz, .C2EventMacro
	
	;Get next noise parameter and load it into RAM
	inc hl
	ld a, (hl)
	ld (C4Noise), a
	inc hl
	jp .C2GetNextByte

.C2EventMacro
;Go to a macro (subroutine) with transpose for specified number of times
;Parameters: xx yy zz (X = Macro number, Y = Transpose, Z = Number of times)
;(Note: 1 level only)
	;Is this the command?
	cp $64
	;If not, then check for next command
	jr nz, .C2EventMacroRet
	
	;Get the macro transpose value and load it into RAM
	ld bc, C2MacroTrans
	call ProcessMacro
	ld h, b
	ld l, c
	jp .C2GetNextByte

.C2EventMacroRet
;Return from the current macro
	;Is this the command?
	cp $65
	;If not, then check for next command
	jr nz, .C2EventCondFlag
	
	ld hl, C2MacroTimesLeft
	call ProcessMacroRet
	ld h, b
	ld l, c
	jp .C2GetNextByte

.C2EventCondFlag
;Set a conditional flag (not used by the driver)
;Parameters: xx (X = Value)	
	;Is this the command?
	cp $66
	;If not, then check for next command
	jr nz, .C2EventNoteLens
	
	inc hl
	ld a, (hl)
	ld (LoopFlag), a
	inc hl
	jp .C2GetNextByte

.C2EventNoteLens
;Set note lengths from the following pointer (for all channels)
;Parameters: xx xx (X = Pointer)
	;Is this the command?
	cp $67
	;If not, then check for next command
	jr nz, .C2EventTempo
	
	inc hl
	ld a, (hl)
	ld (NoteLens), a
	inc hl
	ld a, (hl)
	ld (NoteLens+1), a
	inc hl
	jp .C2GetNextByte

.C2EventTempo
;Set the tempo
;Parameters: x (X = Value)
	;Is this the command?
	cp $68
	;If not, then disable channel
	jr nz, .C2Disable
	
	inc hl
	ld a, (hl)
	ld (Tempo), a
	inc hl
	jp .C2GetNextByte

.C2Disable
	xor a
	ld (C2PlayFlag), a
	ld (C2Vol), a
	;Skip to next channel
	jp PlaySongC3

;Get instrument parameter bytes
.C2ProcessInsSeqs
	;Process the channel envelope from sequence
	ld hl, C2EnvSeqDelay
	ld bc, C2Vol
	call ProcessEnvSeq
	;Process the channel vibrato from sequence 
	ld hl, C2VibSeqDelay
	ld bc, C2Freq
	call ProcessVibrato
	;Process the channel pitch modulation from sequence
	ld hl, C2ModSeqDelay
	ld bc, C2Freq
	call ProcessModSeq
	
PlaySongC3:
	;Check to see if channel 3 is active
	ld a, (C3PlayFlag)
	and a
	;If not, then skip to channel 4
	jp z, PlaySongC4
	;Otherwise, decrement channel 3 delay
	ld hl, C3Delay
	dec (hl)
	;If not done playing, then process envelope/vibrato/pitch modulation
	jp nz, C3ProcessInsSeqs
	
	;Update channel 1 position
	ld a, (C3Pos)
	ld l, a
	ld a, (C3Pos+1)
	ld h, a
.C3GetNextByte
	xor a
	ld (C3InsAdd), a
	;Check current byte value
	ld a, (hl)
	;Is bit 1 set?
	cp $80
	jr c, .C3CheckVCMD
	;If so, then add to instrument count (instrument is +16)
	ld a, $10
	ld (C3InsAdd), a
	jr .C3GetNote

;Is it over 60?
.C3CheckVCMD
	cp $60
	;Then it is a VCMD...
	jr nc, .C3GetVCMD
;Otherwise, it is a note
.C3GetNote
	;Get the current transpose
	ld a, (C3MacroTrans)
	ld b, a
	;Mask out the highest bit
	ld a, (hl)
	and %01111111
	;Add the transpose
	add a, b
	;Load the note into RAM
	ld (C3Note), a
	call GetFreq
	ld a, e
	ld (C3Freq), a
	ld a, d
	ld (C3Freq+1), a
	;Get the next byte
	inc hl
	ld a, (hl)
	;Mask out the lower 4 bits to get the instrument number
	and %11110000
	;Shift left 4 bits
	srl a
	srl a
	srl a
	srl a
	;If 16 or over, OR 16 to total
	ld b, a
	ld a, (C3InsAdd)
	or b
	;Now load the instrument values into RAM
	ld bc, C3EnvSeqDelay
	push hl
	call ProcessInst
	pop hl
	
;Now get the note length
.C3GetLen
	;Load the current note length pointer from RAM
	ld a, (NoteLens)
	ld e, a
	ld a, (NoteLens+1)
	ld d, a
	
	;Mask out the upper 4 bits to get the note length index
	ld a, (hl)
	and %00001111
	;Add the index to get the length value
	add a, e
	ld e, a
	jr nc, .C3GetLen2
	inc d
.C3GetLen2
	;Store the value in RAM
	ld a, (de)
	ld (C3Delay), a
.C3UpdatePos
	;Update the current position
	inc hl
	ld a, l
	ld (C3Pos), a
	ld a, h
	ld (C3Pos+1), a
	jp C3ProcessInsSeqs

.C3GetVCMD
;Check the current voice command (VCMD)

.C3EventTie
;Delay the next note by length, increasing note length
;Parameters: -x (- = unused, x = length)
	;Is this the command?
	cp $60
	;If not, then check for next command
	jr nz, .C3EventStop
	
	;Get the note length from the next byte and the note lengths pointer
	inc hl
	ld a, (NoteLens)
	ld e, a
	ld a, (NoteLens+1)
	ld d, a
	ld a, (hl)
	;Mask out the upper 4 bits to get the length index
	and %00001111
	;Add it to get the pointer to the pointer to the length
	add a, e
	ld e, a
	jr nc, .C3EventTie2
	inc d
.C3EventTie2
	;Set the delay
	ld a, (de)
	ld (C3Delay), a
	;Update the pointer
	jr .C3UpdatePos

.C3EventStop:
;Stop the channel
	;Is this the command?
	cp $61
	;If not, then check for next command
	jr nz, .C3EventJump
	
	;Set the channel play flag to 0
	xor a
	ld (C3PlayFlag), a
	;Also set volume to default
	ld a, 15
	ld (C3Vol), a
	;Go to next channel
	jp PlaySongC4

.C3EventJump
;Jump to the following pointer (used for looping)
;Parameters: xx xx (x = Pointer)
	;Is this the command?
	cp $62
	;If not, then check for next command
	jr nz, .C3EventNoise
	
	inc hl
	ld e, (hl)
	inc hl
	ld d, (hl)
	ld h, d
	ld l, e
	jp .C3GetNextByte

.C3EventNoise
;Change the noise (channel 4) "fee.dback" value
;Parameters: xx (X = Value)
	;Is this the command?
	cp $63
	;If not, then check for next command
	jr nz, .C3EventMacro
	
	inc hl
	inc hl
	jp .C3GetNextByte

.C3EventMacro
;Go to a macro (subroutine) with transpose for specified number of times
;Parameters: xx yy zz (X = Macro number, Y = Transpose, Z = Number of times)
;(Note: 1 level only)
	;Is this the command?
	cp $64
	;If not, then check for next command
	jr nz, .C3EventMacroRet
	
	;Get the macro transpose value and load it into RAM
	ld bc, C3MacroTrans
	call ProcessMacro
	ld h, b
	ld l, c
	jp .C3GetNextByte

.C3EventMacroRet
;Return from the current macro
	;Is this the command?
	cp $65
	;If not, then check for next command
	jr nz, .C3EventCondFlag
	
	ld hl, C3MacroTimesLeft
	call ProcessMacroRet
	ld h, b
	ld l, c
	jp .C3GetNextByte

.C3EventCondFlag
;Set a conditional flag (not used by the driver)
;Parameters: xx (X = Value)	
	;Is this the command?
	cp $66
	;If not, then check for next command
	jr nz, .C3EventNoteLens
	
	inc hl
	ld a, (hl)
	ld (LoopFlag), a
	inc hl
	jp .C3GetNextByte

.C3EventNoteLens
;Set note lengths from the following pointer (for all channels)
;Parameters: xx xx (X = Pointer)
	;Is this the command?
	cp $67
	;If not, then check for next command
	jr nz, .C3EventTempo
	inc hl
	ld a, (hl)
	ld (NoteLens), a
	inc hl
	ld a, (hl)
	ld (NoteLens+1), a
	inc hl
	jp .C3GetNextByte

.C3EventTempo
;Set the tempo
;Parameters: x (X = Value)
	;Is this the command?
	cp $68
	;If not, then disable channel
	jr nz, .C3Disable
	
	inc hl
	ld a, (hl)
	ld (Tempo), a
	inc hl
	jp .C3GetNextByte

.C3Disable
	xor a
	ld (C3PlayFlag), a
	ld (C3Vol), a
	jp PlaySongC4

;Get instrument parameter bytes
C3ProcessInsSeqs:
	;Process the channel envelope from sequence
	ld hl, C3EnvSeqDelay
	ld bc, C3Vol
	call ProcessEnvSeq
	;Process the channel vibrato from sequence 
	ld hl, C3VibSeqDelay
	ld bc, C3Freq
	call ProcessVibrato
	;Process the channel pitch modulation from sequence
	ld hl, C3ModSeqDelay
	ld bc, C3Freq
	call ProcessModSeq
	
PlaySongC4:
	;Check to see if channel 4 is active
	ld a, (C4PlayFlag)
	and a
	;If not, then return
	jp z, .C4Ret
	;Otherwise, decrement channel 4 delay
	ld hl, C4Delay
	dec (hl)
	;If not done playing, then process envelope
	jp nz, .C4ProcessInsSeqs
	
	;Update channel 4 position
	ld a, (C4Pos)
	ld l, a
	ld a, (C4Pos+1)
	ld h, a
.C4GetNextByte
	xor a
	ld (C4InsAdd), a
	;Check current byte value
	ld a, (hl)
	;Is bit 1 set?
	cp $80
	jr c, .C4CheckVCMD
	;If so, then add to instrument count (instrument is +16)
	ld a, $10
	ld (C4InsAdd), a
	jr .C4GetNote

;Is it over 60?
.C4CheckVCMD
	cp $60
	;Then it is a VCMD...
	jr nc, .C4GetVCMD
;Otherwise, it is a note	
.C4GetNote
	;Get the next byte
	inc hl
	ld a, (hl)
	;Mask out the lower 4 bits to get the instrument number
	and %11110000
	;Shift left 4 bits
	srl a
	srl a
	srl a
	srl a
	;If 16 or over, OR 16 to total
	ld b, a
	ld a, (C4InsAdd)
	or b
	;Now load the instrument values into RAM
	ld bc, C4EnvSeqDelay
	push hl
	call ProcessInst
	pop hl
	
;Now get the note length
.C4GetLen
	;Load the current note length pointer from RAM
	ld a, (NoteLens)
	ld e, a
	ld a, (NoteLens+1)
	ld d, a
	
	;Mask out the upper 4 bits to get the note length index
	ld a, (hl)
	and %00001111
	;Add the index to get the length value
	add a, e
	ld e, a
	jr nc, .C4GetLen2
	inc d
.C4GetLen2
	;Store the value in RAM
	ld a, (de)
	ld (C4Delay), a
.C4UpdatePos
	;Update the current position
	inc hl
	ld a, l
	ld (C4Pos), a
	ld a, h
	ld (C4Pos+1), a
	jp .C4ProcessInsSeqs

.C4GetVCMD
;Check the current voice command (VCMD)

.C4EventTie
;Delay the next note by length, increasing note length
;Parameters: -x (- = unused, x = length)
	;Is this the command?
	cp $60
	;If not, then check for next command
	jr nz, .C4EventStop
	
	;Get the note length from the next byte and the note lengths pointer
	inc hl
	ld a, (NoteLens)
	ld e, a
	ld a, (NoteLens+1)
	ld d, a
	ld a, (hl)
	;Mask out the upper 4 bits to get the length index
	and %00001111
	;Add it to get the pointer to the pointer to the length
	add a, e
	ld e, a
	jr nc, .C4EventTie2
	inc d
.C4EventTie2
	;Set the delay
	ld a, (de)
	ld (C4Delay), a
	;Update the pointer
	jr .C4UpdatePos

.C4EventStop
;Stop the channel
	;Is this the command?
	cp $61
	jr nz, .C4EventJump
	
	;Set the channel play flag to 0
	xor a
	ld (C4PlayFlag), a
	;Also set volume to default
	ld a, 15
	ld (C4Vol), a
	;Go to next channel
	jp .C4Ret

.C4EventJump
;Jump to the following pointer (used for looping)
;Parameters: xx xx (x = Pointer)
	;Is this the command?
	cp $62
	;If not, then check for next command
	jr nz, .C4EventNoise
	
	inc hl
	ld e, (hl)
	inc hl
	ld d, (hl)
	ld h, d
	ld l, e
	jp .C4GetNextByte

.C4EventNoise
;Change the noise (channel 4) "fee.dback" value
;Parameters: xx (X = Value)
	;Is this the command?
	cp $63
	;If not, then check for next command
	jr nz, .C4EventMacro
	
	;Get next noise parameter and load it into RAM
	inc hl
	ld a, (hl)
	ld (C4Noise), a
	inc hl
	jp .C4GetNextByte

.C4EventMacro
;Go to a macro (subroutine) with transpose for specified number of times
;Parameters: xx yy zz (X = Macro number, Y = Transpose, Z = Number of times)
;(Note: 1 level only)
	;Is this the command?
	cp $64
	;If not, then check for next command
	jr nz, .C4EventMacroRet
	
	;Get the macro transpose value and load it into RAM
	ld bc, C4MacroTrans
	call ProcessMacro
	ld h, b
	ld l, c
	jp .C4GetNextByte

.C4EventMacroRet
;Return from the current macro
	;Is this the command?
	cp $65
	;If not, then check for next command
	jr nz, .C4EventCondFlag
	
	ld hl, C4MacroTimesLeft
	call ProcessMacroRet
	ld h, b
	ld l, c
	jp .C4GetNextByte

.C4EventCondFlag
;Set a conditional flag (not used by the driver)
;Parameters: xx (X = Value)	
	;Is this the command?
	cp $66
	;If not, then check for next command
	jr nz, .C4EventNoteLens
	
	inc hl
	ld a, (hl)
	ld (LoopFlag), a
	inc hl
	jp .C4GetNextByte

.C4EventNoteLens
;Set note lengths from the following pointer (for all channels)
;Parameters: xx xx (X = Pointer)
	;Is this the command?
	cp $67
	;If not, then check for next command
	jr nz, .C4EventTempo
	
	inc hl
	ld a, (hl)
	ld (NoteLens), a
	inc hl
	ld a, (hl)
	ld (NoteLens+1), a
	inc hl
	jp .C4GetNextByte

.C4EventTempo
;Set the tempo
;Parameters: x (X = Value)
	;Is this the command?
	cp $68
	;If not, then disable channel
	jr nz, .C4EventDisable
	
	inc hl
	ld a, (hl)
	ld (Tempo), a
	inc hl
	jp .C4GetNextByte

.C4EventDisable
	xor a
	ld (C4PlayFlag), a
	ld (C4Vol), a
	;Skip to next channel
	jp .C4Ret

;Get instrument parameter bytes
.C4ProcessInsSeqs
	;Process the channel envelope from sequence
	ld hl, C4EnvSeqDelay
	ld bc, C4Vol
	call ProcessEnvSeq
	;(No vibrato or pitch modulation available for CH4)
	
.C4Ret
	ret

ProcessEnvSeq:
;Decrement envelope sequence delay
	dec (hl)
	;If delay has not yet finished, then return
	ret nz
	ld d, h
	ld e, l
	
	;Otherwise, check if reached end of pattern (value FF)
	push de
	inc hl
	ld e, (hl)
	inc hl
	ld d, (hl)
	ld h, d
	ld l, e
	pop de
	ld a, (hl)
	cp $FF
	ret z
	
	;If not, then load next byte (volume) and update pointer
	ld (bc), a
	inc hl
	ld a, (hl)
	ld (de), a
	inc de
	inc hl
	ld a, l
	ld (de), a
	inc de
	ld a, h
	ld (de), a
	ret

ProcessVibrato:
;Decrement vibrato sequence delay
	dec (hl)
	;If delay has not yet finished, then return
	ret nz
	
	;Otherwise, check if reached end of pattern (value FF)
	push hl
	inc hl
	ld e, (hl)
	inc hl
	ld d, (hl)
	ld h, d
	ld l, e
	ld a, (hl)
	cp $FF
	;If not, then keep going
	jr nz, ProcessVibSeq
	pop hl
	ret

ProcessVibSeq:
	;Is it negative?
	cp $80
	;If so, then subtract from frequency
	jr nc, .SubVibFreq
;Otherwise, add to frequency
.AddVibFreq
	ld d, a
	ld a, (bc)
	add a, d
	ld d, a
	and %00001111
	ld (bc), a
	ld a, d
	srl a
	srl a
	srl a
	srl a
	ld d, a
	inc bc
	ld a, (bc)
	add a, d
	ld (bc), a
	jr .ProcessVibSeq2

.SubVibFreq
	ld d, a
	ld a, (bc)
	add a, d
	ld d, a
	and %00001111
	ld (bc), a
	ld a, d
	srl a
	srl a
	srl a
	srl a
	and %00000001
	ld d, a
	inc bc
	ld a, (bc)
	sub d
	and %00111111
	ld (bc), a
	
.ProcessVibSeq2
;Load next byte (delay) and update pointer
	inc hl
	ld a, (hl)
	inc hl
	ld d, h
	ld e, l
	pop hl
	ld (hl), a
	inc hl
	ld (hl), e
	inc hl
	ld (hl), d
	ret

ProcessModSeq:
;Decrement pitch modulation sequence delay
	dec (hl)
	;If delay has not yet finished, then return
	ret nz
	
	;Otherwise, check if reached end of pattern (value FF)
	push hl
	inc hl
	ld e, (hl)
	inc hl
	ld d, (hl)
	ld h, d
	ld l, e
	ld a, (hl)
	cp $FF
	;If not, then keep going
	jr nz, .ProcessModSeq2
	
	;Otherwise, restart sequence
	ld d, h
	ld e, l
	;Get the original position...
	pop hl
	push hl
	inc hl
	inc hl
	inc hl
	ld e, (hl)
	inc hl
	ld d, (hl)
	dec hl
	dec hl
	ld (hl), d
	dec hl
	ld (hl), e
	ld h, d
	ld l, e
	;...Then reset the delay
	pop hl
	ld a, 1
	ld (hl), a
	jr ProcessModSeq

.ProcessModSeq2
	;Load the note change/modulation value into RAM
	ld (ModVal), a
	
	;Load next byte (delay) and update pointer
	inc hl
	ld a, (hl)
	ld d, h
	ld e, l
	inc de
	pop hl
	ld (hl), a
	inc hl
	ld (hl), e
	inc hl
	ld (hl), d
	;Then get back the modulation value...
	inc hl
	inc hl
	inc hl
	ld a, (hl)
	ld d, a
	ld a, (ModVal)
	;...and add to the current note value
	add a, d
	push bc
	call GetFreq
	pop bc
	;Finally, update the position
	ld a, e
	ld (bc), a
	inc bc
	ld a, d
	ld (bc), a
	ret

;Process the current instrument
ProcessInst:
	;Get the current instrument offset in table
	add a, a
	ld hl, InstTab
	add a, l
	ld l, a
	jr nc, .ProcessInst2
	inc h
.ProcessInst2
	;Envelope sequence delay = 1
	ld e, (hl)
	inc hl
	ld d, (hl)
	ld a, 1
	ld (bc), a
	;Instrument byte 1-2
	;Envelope sequence pointer
	inc bc
	ld a, (de)
	ld (bc), a
	inc de
	inc bc
	ld a, (de)
	ld (bc), a
	;Vibrato sequence delay = 1
	inc bc
	inc de
	ld a, 1
	ld (bc), a
	;Instrument byte 3-4
	;Vibrato sequence pointer
	inc bc
	ld a, (de)
	ld (bc), a
	inc de
	inc bc
	ld a, (de)
	ld (bc), a
	;Pitch modulation sequence delay = 1
	inc bc
	inc de
	ld a, 1
	ld (bc), a
	;Instrument byte 5-6
	;Pitch modulation sequence pointer
	inc bc
	ld a, (de)
	ld (bc), a
	ld l, a
	inc bc
	inc de
	ld a, (de)
	ld (bc), a
	ld h, a
	;Store the pitch modulation sequence pointer again as a restart point
	inc bc
	ld a, l
	ld (bc), a
	inc bc
	ld a, h
	ld (bc), a
	ret

ProcessMacro:
	;Get number from next byte and multiply by 2 to get macro pointer
	ld de, MacroTab
	inc hl
	ld a, (hl)
	add a, a
	add a, e
	ld e, a
	jr nc, .ProcessMacro2
	inc d
.ProcessMacro2
	;Now get the macro transpose value and load it into RAM
	inc hl
	ld a, (hl)
	ld (bc), a
	inc hl
	;Now check the macro times flag in RAM
	inc bc
	ld a, (bc)
	and a
	;If not 0, then skip
	jr nz, .ProcessMacro3
	;Otherwise, set flag and get the times in macro
	ld a, (hl)
	ld (bc), a
.ProcessMacro3
	;Now get the number of times in macro and load into RAM (times left)
	inc bc
	inc hl
	ld a, l
	ld (bc), a
	;Now store the address to return from the macro into RAM
	inc bc
	ld a, h
	ld (bc), a
	ld a, (de)
	ld c, a
	inc de
	ld a, (de)
	ld b, a
	ret

ProcessMacroRet:
	;Decrement the amount of times remaining
	dec (hl)
	;If 0, then return
	jr z, .ProcessMacroRetEnd
	
	;Otherwise, jump to macro start
	;(Get return pointer and subtract 4)
	inc hl
	ld a, (hl)
	ld c, a
	inc hl
	ld a, (hl)
	ld b, a
	ld a, c
	sub 4
	jr nc, .ProcessMacroRet2
	dec b
.ProcessMacroRet2
	ld c, a
	ret

.ProcessMacroRetEnd
	;Reset transpose
	dec hl
	xor a
	ld (hl), a
	;Go to return position
	inc hl
	inc hl
	ld a, (hl)
	ld c, a
	inc hl
	ld a, (hl)
	ld b, a
	ret

ProcessC1:
	;Check if SFX is playing on CH1
	ld a, (C1SFXPos+1)
	and a
	;If so, then get SFX frequency and length instead of music
	jr z, .ProcessC1_2
	ld a, (C1SFXFreq)
	ld (C1Freq), a
	ld a, (C1SFXFreq+1)
	ld (C1Freq+1), a
	ld a, (C1SFXVol)
	ld (C1Vol), a
.ProcessC1_2
	;Process frequency and send to PSG
	ld a, (C1Freq)
	and %00001111
	or %10000000
	out (Port_PSG), a
	ld a, (C1Freq+1)
	and %00111111
	out (Port_PSG), a
	;Then process volume
	ld a, (C1Vol)
	and %00001111
	or %10010000
	out (Port_PSG), a

ProcessC2:
	;Check if SFX is playing on CH2
	ld a, (C2SFXPos+1)
	and a
	;If so, then get SFX frequency and length instead of music
	jr z, .ProcessC2_2
	ld a, (C2SFXFreq)
	ld (C2Freq), a
	ld a, (C2SFXFreq+1)
	ld (C2Freq+1), a
	ld a, (C2SFXVol)
	ld (C2Vol), a
.ProcessC2_2
	;Process frequency and send to PSG
	ld a, (C2Freq)
	and %00001111
	or %10100000
	out (Port_PSG), a
	ld a, (C2Freq+1)
	and %00111111
	out (Port_PSG), a
	;Then process volume
	ld a, (C2Vol)
	and %00001111
	or %10110000
	out (Port_PSG), a
	
ProcessC3:
	;Check if SFX is playing on CH3
	ld a, (C3SFXPos+1)
	and a
	;If so, then get SFX frequency and length instead of music
	jr z, .ProcessC3_2
	ld a, (C3SFXFreq)
	ld (C3Freq), a
	ld a, (C3SFXFreq+1)
	ld (C3Freq+1), a
	ld a, (C3SFXVol)
	ld (C3Vol), a
.ProcessC3_2
	;Process frequency and send to PSG
	ld a, (C3Freq)
	and %00001111
	or %11000000
	out (Port_PSG), a
	ld a, (C3Freq+1)
	and %00111111
	out (Port_PSG), a
	;Then process volume
	ld a, (C3Vol)
	and %00001111
	or %11010000
	out (Port_PSG), a

ProcessC4:
	;Check if SFX is playing on CH4
	ld a, (C4SFXPos+1)
	and a
	;If so, then get SFX noise and length instead of music
	jr z, .ProcessC4_2
	ld a, (C4SFXNoise)
	ld (C4Noise), a
	ld a, (C4SFXVol)
	ld (C4Vol), a
.ProcessC4_2
	;Process frequency and send to PSG
	ld a, (C4Noise)
	ld b, a
	ld a, (PrevNoise)
	cp b
	jr z, .ProcessC4_3
	ld a, (C4Noise)
	ld (PrevNoise), a
	and %00000111
	or %11100000
	out (Port_PSG), a
.ProcessC4_3
	;Then process volume
	ld a, (C4Vol)
	and %00001111
	or %11110000
	out (Port_PSG), a
	ret

;Get the current note frequency from table
GetFreq:
	add a, a
	ld bc, FreqTab
	add a, c
	ld c, a
	jr nc, .GetFreq2
	inc b
.GetFreq2
	ld a, (bc)
	ld e, a
	inc bc
	ld a, (bc)
	ld d, a
	ret

;Load the current sound effect
LoadSFX:
	;If SFX on/off value is 0 (off), then return
	ld c, a
	ld a, (SFXSwitch)
	or a
	ret z
	
	;Otherwise, get SFX macro pointer from table
	ld a, c
	ld hl, SFXTab
	add a, a
	add a, l
	ld l, a
	jr nc, .LoadSFX2
	inc h
.LoadSFX2
	ld a, (hl)
	ld e, a
	inc hl
	ld a, (hl)
	ld d, a
	;Check the channel number from register B
	ld a, b
	
	;Is it channel 1?
	and a
	jr z, .InitSFXC1
	
	;Is it channel 2?
	cp 1
	jr z, .InitSFXC2
	
	;Is it channel 3?
	cp 2
	jr z, .InitSFXC3
	
	;Is it channel 4?
	cp 3
	jr z, .InitSFXC4
	ret

.InitSFXC1
	;Set SFX position in RAM
	ld a, e
	ld (C1SFXPos), a
	ld a, d
	ld (C1SFXPos+1), a
	;Set SFX channel delay
	ld a, 1
	ld (C1SFXDelay), a
	jr .LoadSFXRet

.InitSFXC2
	;Set SFX position in RAM
	ld a, e
	ld (C2SFXPos), a
	ld a, d
	ld (C2SFXPos+1), a
	;Set SFX channel delay
	ld a, 1
	ld (C2SFXDelay), a
	jr .LoadSFXRet

.InitSFXC3
	;Set SFX position in RAM
	ld a, e
	ld (C3SFXPos), a
	ld a, d
	ld (C3SFXPos+1), a
	;Set SFX channel delay
	ld a, 1
	ld (C3SFXDelay), a
	jr .LoadSFXRet

.InitSFXC4
	;Set SFX position in RAM
	ld a, e
	ld (C4SFXPos), a
	ld a, d
	ld (C4SFXPos+1), a
	;Set SFX channel delay
	ld a, 1
	ld (C4SFXDelay), a

;Return
.LoadSFXRet
	ret

CheckC1SFX:
	;Check if SFX is playing on CH1
	ld a, (C1SFXPos+1)
	and a
	;If not, then check CH2
	jr z, CheckC2SFX
	
	;Otherwise, process channel
	ld hl, C1SFXDelay
	ld bc, C1SFXVol
	call PlaySFX
CheckC2SFX:
	;Check if SFX is playing on CH2
	ld a, (C2SFXPos+1)
	and a
	;If not, then check CH3
	jr z, CheckC3SFX
	
	;Otherwise, process channel
	ld hl, C2SFXDelay
	ld bc, C2SFXVol
	call PlaySFX
CheckC3SFX:
	;Check if SFX is playing on CH3
	ld a, (C3SFXPos+1)
	and a
	;If not, then check CH4
	jr z, CheckC4SFX
	
	;Otherwise, process channel	
	ld hl, C3SFXDelay
	ld bc, C3SFXVol
	call PlaySFX
CheckC4SFX:
	;Check if SFX is playing on CH4
	ld a, (C4SFXPos+1)
	and a
	;If not, then return
	ret z
	
	;Otherwise, process channel
	ld hl, C4SFXDelay
	ld bc, C4SFXVol

;Play SFX macro (channel 4)
PlaySFXC4:
;Decrement delay
	dec (hl)
	;If not 0, then return (wait)
	ret nz
	
	;Otherwise, continue
	;Get pointer of SFX macro from RAM
	inc hl
	ld a, (hl)
	ld e, a
	inc hl
	ld a, (hl)
	ld d, a
	;Then, get the next SFX command
	ld a, (de)
	;Is it a stop command (FF)?
	cp $FF
	;If not, then continue
	jr nz, .PlaySFXC4_2
	
	;Otherwise, then clear position high byte flag and return
	xor a
	ld (hl), a
	ret

.PlaySFXC4_2
	;First, get the volume
	ld (bc), a
	inc de
	;Then, get the noise value
	ld a, (de)
	and %00000111
	dec bc
	ld (bc), a
	;Finally, get the length/delay
	inc de
	ld a, (de)
	ld b, a
	;Update pointer and return
	inc de
	ld a, d
	ld (hl), a
	dec hl
	ld a, e
	ld (hl), a
	ld a, b
	dec hl
	ld (hl), a
	ret

;Process SFX macro (channel 1-3)
PlaySFX:
	;Decrement delay
	dec (hl)
	;If not 0, then return (wait)
	ret nz
	
	;Otherwise, continue
	;Get pointer of SFX macro from RAM
	inc hl
	ld a, (hl)
	ld e, a
	inc hl
	ld a, (hl)
	ld d, a
	;Then, get the next SFX command
	ld a, (de)
	;Is it a stop command (FF)?
	cp $FF
	;If not, then continue
	jr nz, .PlaySFX2
	
	;Otherwise, then clear position high byte flag and return
	xor a
	ld (hl), a
	ret

.PlaySFX2
	;First, get the volume
	ld (bc), a
	inc de
	;Then, get the frequency (2 bytes)
	ld a, (de)
	and %00111111
	dec bc
	ld (bc), a
	inc de
	ld a, (de)
	and %00001111
	dec bc
	ld (bc), a
	;Finally, get the length/delay
	inc de
	ld a, (de)
	ld b, a
	;Update pointer and return
	inc de
	ld a, d
	ld (hl), a
	dec hl
	ld a, e
	ld (hl), a
	ld a, b
	dec hl
	ld (hl), a
	ret

SFX00:
	.db 8, $06, $09, 3
	.db 8, $03, $04, 3
	.db 8, $00, $0D, 2
	.db 8, $00, $0E, 2
	.db 8, $00, $0F, 2
	.db 8, $00, $0F, 2
	.db 8, $01, $00, 2
	.db 8, $01, $02, 2
	.db 8, $01, $03, 2
	.db 8, $01, $04, 2
	.db 10, $01, $05, 2
	.db 12, $01, $06, 2
	.db 13, $01, $07, 2
	.db 14, $01, $09, 2
	.db 14, $01, $0A, 2
	.db 14, $01, $0C, 2
	.db 14, $01, $0E, 2
	.db 15, $00, $00, 1
	.db $FF
SFX01:
	.db 0, $07, $03, 0
	.db 7, $03, $00, 7
	.db 4, $00, $07, 4
	.db 0, $07, $04, 1
	.db 7, $04, $02, 7
	.db 4, $03, $07, 4
	.db 4, $07, $04, 5
	.db 7, $04, $06, 7
	.db 2, $0F, $00, 1
	.db $FF
SFX02:
	.db 3, $00, $0F, 1
	.db 0, $00, $0F, 2
	.db 3, $02, $0F, 1
	.db 4, $05, $00, 1
	.db 5, $05, $0F, 1
	.db 5, $07, $01, 1
	.db 6, $08, $0E, 1
	.db 7, $0A, $09, 1
	.db 9, $0D, $03, 1
	.db 11, $0F, $0E, 2
	.db 12, $14, $00, 3
	.db 13, $17, $0D, 4
	.db 14, $1C, $05, 4
	.db 15, $00, $00, 1
	.db $FF
SFX03:
	.db 0, $07, 1
	.db 1, $07, 1
	.db 2, $07, 1
	.db 4, $07, 1
	.db 5, $07, 1
	.db 6, $07, 1
	.db 7, $07, 1
	.db 9, $07, 1
	.db 11, $07, 2
	.db 12, $07, 3
	.db 13, $07, 4
	.db 14, $07, 4
	.db 15, $07, 1
	.db $FF
SFX04:
	.db 15, $01, $0F, 1
	.db 15, $02, $01, 1
	.db 15, $02, $03, 1
	.db 15, $02, $05, 1
	.db 15, $02, $0A, 6
	.db $FF
SFX05:
	.db 0, $07, $01, 3
	.db 7, $01, $05, 7
	.db 1, $07, $07, 1
	.db 8, $07, $01, 9
	.db 7, $01, $0A, 7
	.db 1, $0B, $07, 1
	.db 12, $07, $01, 13
	.db 7, $01, $0E, 7
	.db 1, $0F, $07, 1
	.db $FF
SFX06:
	.db 15, $07, $0F, 1
	.db 15, $05, $0F, 1
	.db 15, $03, $0F, 2
	.db 15, $03, $04, 1
	.db 15, $03, $0F, 1
	.db 15, $05, $00, 3
	.db 15, $05, $0F, 4
	.db 15, $06, $09, 4
	.db 15, $07, $0F, 4
	.db 15, $0A, $00, 4
	.db 15, $0B, $0E, 4
	.db 15, $0D, $03, 4
	.db 15, $0F, $0E, 4
	.db 15, $00, $00, 1
	.db $FF
SFX07:
	.db 5, $07, 1
	.db 3, $07, 1
	.db 0, $07, 2
	.db 2, $07, 1
	.db 3, $07, 1
	.db 4, $07, 3
	.db 5, $07, 4
	.db 6, $07, 4
	.db 7, $07, 4
	.db 8, $07, 4
	.db 9, $07, 4
	.db 10, $07, 4
	.db 11, $07, 4
	.db 15, $07, 1
	.db $FF
SFX08:
	.db 15, $03, $0F, 1
	.db 15, $03, $08, 1
	.db 15, $03, $0F, 1
	.db 15, $03, $08, 1
	.db 15, $03, $0F, 1
	.db 15, $00, $00, 1
	.db $FF
SFX09:
	.db 0, $07, 1
	.db 3, $07, 1
	.db 5, $07, 1
	.db 8, $07, 1
	.db 10, $07, 1
	.db 15, $07, 1
	.db $FF
SFX0A:
	.db 15, $01, $0A, 1
	.db 15, $01, $0C, 1
	.db 15, $01, $0F, 1
	.db 15, $02, $05, 1
	.db 15, $02, $0A, 6
	.db $FF
SFX0B:
	.db 0, $07, 1
	.db 3, $07, 1
	.db 5, $07, 1
	.db 7, $07, 1
	.db 8, $07, 1
	.db 9, $07, 1
	.db 10, $07, 1
	.db 11, $07, 1
	.db 12, $07, 1
	.db 13, $07, 1
	.db 14, $07, 1
	.db 15, $07, 1
	.db $FF
SFX0C:
	.db 2, $0F, $0E, 1
	.db 5, $07, $0F, 1
	.db 2, $0E, $02, 1
	.db 5, $07, $01, 1
	.db 2, $0C, $09, 1
	.db 5, $06, $04, 1
	.db 2, $0B, $0E, 1
	.db 5, $05, $0F, 1
	.db 2, $0A, $09, 1
	.db 5, $05, $04, 1
	.db 2, $09, $07, 1
	.db 5, $04, $0B, 1
	.db 2, $08, $06, 1
	.db 5, $04, $03, 1
	.db 2, $07, $0F, 1
	.db 5, $03, $0F, 1
	.db 3, $07, $0F, 1
	.db 6, $03, $0F, 1
	.db 4, $07, $0F, 1
	.db 7, $03, $0F, 1
	.db 5, $07, $0F, 1
	.db 8, $03, $0F, 1
	.db 6, $07, $0F, 1
	.db 9, $03, $0F, 1
	.db 7, $07, $0F, 1
	.db 10, $03, $0F, 1
	.db 8, $07, $0F, 1
	.db 11, $03, $0F, 1
	.db 9, $07, $0F, 1
	.db 12, $03, $0F, 1
	.db 10, $07, $0F, 1
	.db 13, $03, $0F, 1
	.db 11, $07, $0F, 1
	.db 13, $03, $0F, 1
	.db 12, $07, $0F, 1
	.db 14, $03, $0F, 1
	.db 15, $00, $00, 1
	.db $FF
SFX0D:
	.db 1, $0D, $03, 1
	.db 4, $06, $09, 1
	.db 2, $0D, $03, 1
	.db 5, $06, $09, 1
	.db 1, $08, $0E, 1
	.db 4, $04, $07, 1
	.db 2, $08, $0E, 1
	.db 5, $04, $07, 1
	.db 1, $0A, $09, 1
	.db 4, $05, $04, 1
	.db 2, $0A, $09, 1
	.db 5, $05, $04, 1
	.db 1, $06, $09, 1
	.db 4, $03, $04, 1
	.db 2, $06, $09, 1
	.db 5, $03, $04, 1
	.db 1, $08, $0E, 1
	.db 4, $04, $07, 1
	.db 1, $0A, $09, 1
	.db 4, $05, $04, 1
	.db 1, $0D, $03, 1
	.db 4, $06, $09, 1
	.db 1, $0D, $03, 1
	.db 4, $06, $09, 1
	.db 2, $0D, $03, 1
	.db 5, $06, $09, 1
	.db 3, $0D, $03, 1
	.db 6, $06, $09, 1
	.db 4, $0D, $03, 1
	.db 7, $06, $09, 1
	.db 5, $0D, $03, 1
	.db 8, $06, $09, 1
	.db 6, $0D, $03, 1
	.db 9, $06, $09, 1
	.db 7, $0D, $03, 1
	.db 10, $06, $09, 1
	.db 8, $0D, $03, 1
	.db 11, $06, $09, 1
	.db 9, $0D, $03, 1
	.db 12, $06, $09, 1
	.db 10, $0D, $03, 1
	.db 13, $06, $09, 1
	.db 11, $0D, $03, 1
	.db 14, $06, $09, 1
	.db 15, $00, $00, 1
	.db $FF
SFX0E:
	.db 2, $05, $04, 1
	.db 4, $02, $0A, 1
	.db 3, $05, $04, 1
	.db 6, $02, $0A, 1
	.db 15, $00, $00, 2
	.db 2, $04, $07, 1
	.db 4, $02, $03, 1
	.db 3, $04, $07, 1
	.db 6, $02, $03, 1
	.db 15, $00, $00, 1
	.db $FF
SFX0F:
	.db 0, $02, $05, 1
	.db 15, $00, $00, 1
	.db 2, $02, $05, 1
	.db 15, $00, $00, 1
	.db 3, $02, $05, 1
	.db 15, $00, $00, 1
	.db 4, $02, $05, 1
	.db 15, $00, $00, 1
	.db $FF
SFX10:
	.db 0, $03, $0F, 1
	.db 15, $00, $00, 1
	.db 2, $03, $0F, 1
	.db 15, $00, $00, 1
	.db $FF
SFX11:
	.db 0, $08, $06, 1
	.db 15, $00, $00, 1
	.db 2, $08, $06, 1
	.db 15, $00, $00, 1
	.db 3, $08, $06, 1
	.db 15, $00, $00, 1
	.db $FF
SFX12:
	.db 3, $3F, $09, 1
	.db 2, $3C, $00, 1
	.db 1, $38, $0A, 1
	.db 0, $35, $07, 1
	.db 1, $2F, $0A, 1
	.db 2, $2A, $07, 1
	.db 2, $28, $01, 1
	.db 3, $23, $0B, 1
	.db 3, $1F, $0C, 1
	.db 4, $1A, $06, 1
	.db 4, $15, $03, 1
	.db 5, $11, $0D, 1
	.db 5, $0D, $03, 1
	.db 6, $0A, $09, 1
	.db 7, $08, $0E, 1
	.db 8, $07, $01, 1
	.db 9, $06, $09, 1
	.db 15, $00, $00, 2
	.db 3, $02, $0A, 1
	.db 4, $02, $0A, 1
	.db 5, $02, $0A, 1
	.db 6, $02, $0A, 1
	.db 7, $02, $0A, 2
	.db 8, $02, $0A, 2
	.db 9, $02, $0A, 3
	.db 10, $02, $0A, 3
	.db 11, $02, $0A, 4
	.db 12, $02, $0A, 5
	.db 13, $02, $0A, 6
	.db 14, $02, $0A, 7
	.db 15, $00, $00, 1
	.db $FF
SFX13:
	.db 15, $07, $01, 2
	.db 15, $06, $09, 1
	.db 15, $06, $04, 1
	.db 15, $05, $0F, 3
	.db 15, $06, $09, 1
	.db 15, $07, $01, 1
	.db 15, $07, $01, 1
	.db 15, $07, $0F, 2
	.db 15, $07, $0F, 5
	.db 15, $07, $0F, 5
	.db 15, $07, $0F, 5
	.db 15, $07, $0F, 5
	.db 15, $07, $0F, 7
	.db 15, $07, $0F, 7
	.db 15, $07, $0F, 10
	.db 15, $07, $0F, 10
	.db 15, $07, $0F, 10
	.db 15, $07, $0F, 10
	.db 15, $00, $00, 1
	.db $FF
SFX14:
	.db 0, $07, 2
	.db 2, $07, 1
	.db 1, $07, 1
	.db 0, $07, 3
	.db 1, $07, 1
	.db 2, $07, 1
	.db 3, $07, 1
	.db 4, $07, 2
	.db 5, $07, 5
	.db 6, $07, 5
	.db 7, $07, 5
	.db 8, $07, 5
	.db 9, $07, 7
	.db 10, $07, 7
	.db 11, $07, 10
	.db 12, $07, 10
	.db 13, $07, 10
	.db 14, $07, 10
	.db 15, $00, 1
	.db $FF
SFX15:
	.db 15, $07, $01, 2
	.db 15, $06, $09, 1
	.db 15, $06, $04, 1
	.db 15, $05, $0F, 3
	.db 15, $06, $09, 1
	.db 15, $07, $01, 1
	.db 15, $07, $01, 1
	.db 15, $07, $0F, 2
	.db 15, $07, $0F, 5
	.db 15, $07, $0F, 5
	.db 15, $07, $0F, 5
	.db 15, $07, $0F, 5
	.db 15, $07, $0F, 7
	.db 15, $07, $0F, 7
	.db 15, $07, $0F, 7
	.db 15, $07, $0F, 7
	.db 15, $07, $0F, 7
	.db 15, $07, $0F, 7
	.db 15, $00, $00, 1
	.db $FF
SFX16:
	.db 3, $07, 2
	.db 5, $07, 1
	.db 4, $07, 1
	.db 3, $07, 3
	.db 4, $07, 1
	.db 5, $07, 1
	.db 6, $07, 1
	.db 7, $07, 2
	.db 8, $07, 5
	.db 9, $07, 5
	.db 10, $07, 5
	.db 11, $07, 5
	.db 12, $07, 7
	.db 13, $07, 7
	.db 14, $07, 7
	.db 12, $07, 7
	.db 13, $07, 7
	.db 14, $07, 7
	.db 15, $00, 1
	.db $FF
SFX17:
	.db 15, $01, $0A, 255
	.db 15, $01, $0A, 255
	.db 15, $01, $0A, 255
	.db $FF
SFX18:
	.db 7, $07, 254
	.db 7, $07, 254
	.db 7, $07, 254
	.db 15, $07, 1
	.db $FF
SFX19:
	.db 0, $01, $22, 1
	.db 0, $01, $15, 1
	.db 0, $01, $3A, 1
	.db 0, $01, $30, 1
	.db 0, $01, $17, 1
	.db 1, $01, $15, 1
	.db 2, $01, $26, 1
	.db 3, $01, $12, 1
	.db 4, $01, $1E, 1
	.db 5, $01, $23, 1
	.db 6, $01, $0E, 1
	.db 7, $01, $1F, 1
	.db 8, $01, $10, 1
	.db 9, $01, $2C, 1
	.db 10, $01, $1E, 2
	.db 15, $00, $00, 1
	.db $FF
SFX1A:
	.db 0, $04, 2
	.db 3, $04, 2
	.db 12, $04, 2
	.db 12, $04, 2
	.db 12, $04, 2
	.db 12, $04, 2
	.db 15, $00, 1
	.db $FF
SFX1B:
	.db 0, $02, $03, 1
	.db 1, $02, $02, 1
	.db 2, $02, $01, 1
	.db 3, $02, $02, 1
	.db 4, $02, $04, 1
	.db 5, $02, $06, 1
	.db 6, $02, $07, 1
	.db 7, $02, $08, 1
	.db 8, $02, $09, 1
	.db 9, $02, $0A, 1
	.db 10, $02, $0B, 2
	.db 12, $02, $0C, 2
	.db 12, $02, $0D, 2
	.db 13, $02, $0E, 2
	.db 14, $02, $0F, 2
	.db 15, $00, $00, 1
	.db $FF
SFX1C:
	.db 0, $07, 1
	.db 1, $07, 1
	.db 2, $07, 1
	.db 3, $07, 1
	.db 4, $07, 1
	.db 5, $07, 1
	.db 6, $07, 1
	.db 7, $07, 1
	.db 8, $07, 1
	.db 9, $07, 1
	.db 10, $07, 2
	.db 11, $07, 2
	.db 12, $07, 2
	.db 13, $07, 2
	.db 14, $07, 2
	.db 15, $00, 1
	.db $FF
SFX1D:
	.db 0, $26, $00, 2
	.db 0, $27, $00, 2
	.db 0, $3A, $00, 2
	.db 1, $3B, $00, 2
	.db 1, $3C, $00, 2
	.db 1, $3D, $00, 2
	.db 2, $3E, $00, 2
	.db 2, $3F, $00, 2
	.db 15, $00, $00, 1
	.db $FF
SFX1E:
	.db 3, $04, $02, 5
	.db 4, $02, $04, 4
	.db 2, $06, $04, 2
	.db 5, $04, $02, 7
	.db 4, $03, $06, 4
	.db 3, $0F, $00, 1
	.db $FF
SFX1F:
	.db 0, $01, $22, 2
	.db 1, $02, $15, 2
	.db 1, $01, $3A, 2
	.db 2, $02, $30, 2
	.db 3, $01, $17, 2
	.db 4, $01, $15, 2
	.db 5, $02, $26, 2
	.db 15, $00, $00, 1
	.db $FF
SFX20:
	.db 0, $04, 2
	.db 3, $04, 2
	.db 12, $04, 1
	.db 12, $04, 1
	.db 12, $04, 1
	.db 12, $04, 1
	.db 15, $00, 1
	.db $FF
SFX21:
	.db 0, $23, $00, 1
	.db 0, $22, $00, 1
	.db 0, $21, $00, 1
	.db 0, $22, $00, 1
	.db 0, $23, $00, 1
	.db 0, $24, $00, 1
	.db 0, $25, $00, 1
	.db 0, $26, $00, 1
	.db 0, $27, $00, 1
	.db 0, $3A, $00, 1
	.db 0, $3B, $00, 1
	.db 0, $3C, $00, 1
	.db 0, $3D, $00, 1
	.db 0, $3E, $00, 1
	.db 0, $3F, $00, 1
	.db 1, $3F, $00, 1
	.db 2, $3F, $00, 1
	.db 3, $3F, $00, 1
	.db 4, $3F, $00, 1
	.db 5, $3F, $00, 1
	.db 6, $3E, $00, 1
	.db 7, $3F, $00, 1
	.db 8, $3E, $00, 1
	.db 9, $3F, $00, 1
	.db 10, $3E, $00, 1
	.db 15, $00, $00, 1
	.db $FF
SFX22:
	.db 0, $04, 2
	.db 1, $04, 2
	.db 2, $04, 2
	.db 3, $04, 2
	.db 4, $04, 2
	.db 5, $04, 2
	.db 6, $04, 2
	.db 7, $04, 2
	.db 8, $04, 2
	.db 9, $04, 2
	.db 10, $04, 2
	.db 11, $04, 2
	.db 12, $04, 2
	.db 13, $04, 2
	.db 14, $04, 2
	.db 15, $00, 1
	.db $FF
SFX23:
	.db 15, $07, $0F, 13
	.db $FF
SFX24:
	.db 0, $07, 1
	.db 5, $07, 1
	.db 2, $07, 1
	.db 6, $07, 1
	.db 4, $07, 1
	.db 7, $07, 1
	.db 6, $07, 1
	.db 9, $07, 1
	.db 9, $07, 1
	.db 11, $07, 1
	.db 10, $07, 1
	.db 13, $07, 1
	.db 15, $00, 1
	.db $FF
SFX25:
	.db 15, $0F, $0E, 1
	.db 15, $0B, $0E, 1
	.db 15, $07, $0F, 2
	.db 15, $06, $09, 1
	.db 15, $07, $0F, 1
	.db 15, $0A, $00, 3
	.db 15, $0B, $0E, 4
	.db 15, $0D, $03, 4
	.db 15, $0F, $0E, 4
	.db 15, $14, $00, 4
	.db 15, $17, $0D, 4
	.db 15, $1A, $06, 4
	.db 15, $1F, $0C, 4
	.db 15, $00, $00, 1
	.db $FF
SFX26:
	.db 5, $07, 1
	.db 3, $07, 1
	.db 0, $07, 2
	.db 2, $07, 1
	.db 3, $07, 1
	.db 4, $07, 3
	.db 5, $07, 4
	.db 6, $07, 4
	.db 7, $07, 4
	.db 8, $07, 4
	.db 9, $07, 4
	.db 10, $07, 4
	.db 11, $07, 4
	.db 15, $07, 1
	.db $FF
SFX27:
	.db 0, $23, $00, 2
	.db 1, $24, $00, 2
	.db 2, $25, $00, 2
	.db 3, $26, $00, 2
	.db 4, $27, $00, 2
	.db 5, $3A, $00, 2
	.db 4, $3B, $00, 2
	.db 3, $3C, $00, 2
	.db 2, $3D, $00, 2
	.db 3, $3E, $00, 2
	.db 4, $3F, $00, 2
	.db 5, $3F, $00, 2
	.db 6, $3F, $00, 2
	.db 7, $3F, $00, 2
	.db 8, $3F, $00, 2
	.db 9, $3F, $00, 2
	.db 10, $3F, $00, 2
	.db 11, $3F, $00, 2
	.db 12, $3F, $00, 2
	.db 13, $3F, $00, 2
	.db 14, $3F, $00, 2
	.db 15, $00, $00, 1
	.db $FF
SFX28:
	.db 0, $23, $04, 2
	.db 1, $24, $04, 2
	.db 2, $25, $04, 2
	.db 3, $26, $04, 2
	.db 4, $27, $04, 2
	.db 5, $3A, $04, 2
	.db 4, $3B, $04, 2
	.db 3, $3C, $04, 2
	.db 2, $3D, $04, 2
	.db 3, $3E, $04, 2
	.db 4, $3F, $04, 2
	.db 5, $3F, $08, 2
	.db 6, $3F, $0C, 2
	.db 7, $3F, $08, 2
	.db 8, $3F, $04, 2
	.db 9, $3F, $08, 2
	.db 10, $3F, $0C, 2
	.db 11, $3F, $08, 2
	.db 12, $3F, $0C, 2
	.db 13, $3F, $04, 2
	.db 14, $3F, $08, 2
	.db 15, $00, $00, 1
	.db $FF
SFX29:
	.db 15, $00, $00, 1
	.db $FF
SFX2A:
	.db 15, $00, 1
	.db $FF

SFXTab:
.SFX00
	.dw $8AC0
	.dw $8B09
	.dw $8B2E
	.dw $8B67
	.dw $8B8F
	.dw $8BA4
	.dw $8BC9
	.dw $8C02
	.dw $8C2D
	.dw $8C46
	.dw $8C59
	.dw $8C6E
	.dw $8C93
	.dw $8D28
	.dw $8DDD
	.dw $8E06
	.dw $8E27
	.dw $8E38
	.dw $8E51
	.dw $8ECE
	.dw $8F1B
	.dw $8F55
	.dw $8FA2
	.dw $8FDC
	.dw $8FE9
	.dw $8FF6
	.dw $9037
	.dw $904D
	.dw $908E
	.dw $90BF
	.dw $90E4
	.dw $90FD
	.dw $911E
	.dw $9134
	.dw $919D
	.dw $91CE
	.dw $91D3
	.dw $91FB
	.dw $9234
	.dw $925F
	.dw $92B8
	.dw $9311
	.dw $9316

FreqTab:
	.dw $3F09
	.dw $3C00
	.dw $380A
	.dw $3507
	.dw $3207
	.dw $2F0A
	.dw $2C0F
	.dw $2A07
	.dw $2801
	.dw $250D
	.dw $230B
	.dw $210B
	.dw $3F09
	.dw $3C00
	.dw $380A
	.dw $3507
	.dw $3207
	.dw $2F0A
	.dw $2C0F
	.dw $2A07
	.dw $2801
	.dw $250D
	.dw $230B
	.dw $210B
	.dw $3F09
	.dw $3C00
	.dw $380A
	.dw $3507
	.dw $3207
	.dw $2F0A
	.dw $2C0F
	.dw $2A07
	.dw $2801
	.dw $250D
	.dw $230B
	.dw $210B
	.dw $1F0C
	.dw $1E00
	.dw $1C05
	.dw $1A0C
	.dw $1904
	.dw $170D
	.dw $1608
	.dw $1503
	.dw $1400
	.dw $120E
	.dw $110D
	.dw $100D
	.dw $0F0E
	.dw $0F00
	.dw $0E02
	.dw $0D06
	.dw $0C0A
	.dw $0B0E
	.dw $0B04
	.dw $0A0A
	.dw $0A00
	.dw $0907
	.dw $080F
	.dw $0807
	.dw $070F
	.dw $0708
	.dw $0701
	.dw $060B
	.dw $0605
	.dw $050F
	.dw $050A
	.dw $0505
	.dw $0500
	.dw $040C
	.dw $0407
	.dw $0403
	.dw $0400
	.dw $030C
	.dw $0309
	.dw $0305
	.dw $0302
	.dw $0300
	.dw $020D
	.dw $020A
	.dw $0208
	.dw $0206
	.dw $0203
	.dw $0201
	.dw $0200
	.dw $010E
	.dw $010C
	.dw $010A
	.dw $0109
	.dw $0108
	.dw $0106
	.dw $0105
	.dw $0104
	.dw $0103
	.dw $0102
	.dw $0101
	.dw $0100
	.dw $000F
	.dw $000E
	.dw $000D
	.dw $000C
	.dw $000C
	.dw $000B
	.dw $000A
	.dw $000A
	.dw $0009
	.dw $0009
	.dw $0008

SongTab:
.Victory
	.dw VictoryA, VictoryB, VictoryC, VictoryD, LenTab2
.FlightTerm
	.dw FlightTermA, FlightTermB, FlightTermC, FlightTermD, LenTab2
.HellCorp
	.dw HellCorpA, HellCorpB, HellCorpC, HellCorpD, LenTab2
.Street
	.dw StreetA, StreetB, StreetC, StreetD, LenTab2
.GameOver
	.dw GameOverA, GameOverB, GameOverC, GameOverD, LenTab2
.Complete
	.dw CompleteA, CompleteB, CompleteC, CompleteD, LenTab1
.Bang
	.dw BangA, BangB, BangC, BangD, LenTab2
.Silence
	.dw SilenceA, SilenceB, SilenceC, SilenceD, LenTab2
	
LenTab1:
	.db 2, 3, 4, 6, 8, 12, 16, 24, 32, 48, 64, 96, 128, 192, 5, 10
	
LenTab2:
	.db 3, 4, 6, 9, 12, 18, 24, 36, 48, 72, 96, 144, 192, 8, 16, 32
	
LenTab3:
	.db 4, 6, 8, 12, 16, 24, 32, 48, 64, 96, 128, 192, 252, 5, 10, 20
	
LenTab4:
	.db 5, 7, 10, 15, 20, 30, 40, 60, 80, 120, 160, 240, 16, 32, 64, 128

InstTab:
	.dw Ins00
	.dw Ins01
	.dw Ins02
	.dw Ins03
	.dw Ins04
	.dw Ins05
	.dw Ins06
	.dw Ins07
	.dw Ins08
	.dw Ins09
	.dw Ins0A
	.dw Ins0B
	.dw Ins0C
	.dw Ins0D
	.dw Ins0E
	.dw Ins0F
Ins00:
	.dw EnvSeq00
	.dw VibSeq00
	.dw ModSeq00
Ins01:
	.dw EnvSeq01
	.dw VibSeq01
	.dw ModSeq00
Ins02:
	.dw EnvSeq02
	.dw VibSeq01
	.dw ModSeq00
Ins03:
	.dw EnvSeq03
	.dw VibSeq01
	.dw ModSeq00
Ins04:
	.dw EnvSeq04
	.dw VibSeq02
	.dw ModSeq00
Ins05:
	.dw EnvSeq05
	.dw VibSeq02
	.dw ModSeq00
Ins06:
	.dw EnvSeq06
	.dw VibSeq02
	.dw ModSeq00
Ins07:
	.dw EnvSeq07
	.dw VibSeq00
	.dw ModSeq00
Ins08:
	.dw EnvSeq08
	.dw VibSeq00
	.dw ModSeq00
Ins09:
	.dw EnvSeq09
	.dw VibSeq00
	.dw ModSeq00
Ins0A:
	.dw EnvSeq0A
	.dw VibSeq00
	.dw ModSeq00
Ins0B:
	.dw EnvSeq0B
	.dw VibSeq00
	.dw ModSeq01
Ins0C:
	.dw EnvSeq0B
	.dw VibSeq00
	.dw ModSeq02
Ins0D:
	.dw EnvSeq0C
	.dw VibSeq02
	.dw ModSeq03
Ins0E:
	.dw EnvSeq0D
	.dw VibSeq02
	.dw ModSeq00
Ins0F:
	.dw EnvSeq0E
	.dw VibSeq02
	.dw ModSeq00

EnvSeq00:
	.db 15, 255
	.db $FF
EnvSeq01:
	.db 3, 1
	.db 4, 1
	.db 5, 1
	.db 6, 1
	.db 7, 1
	.db 8, 1
	.db 9, 2
	.db 10, 2
	.db 11, 3
	.db 12, 3
	.db 13, 3
	.db 14, 3
	.db 15, 1
	.db $FF
EnvSeq02:
	.db 3, 1
	.db 4, 1
	.db 5, 1
	.db 6, 1
	.db 7, 2
	.db 8, 2
	.db 9, 4
	.db 10, 4
	.db 11, 6
	.db 12, 6
	.db 13, 6
	.db 14, 6
	.db 15, 1
	.db $FF
EnvSeq03:
	.db 3, 1
	.db 4, 1
	.db 5, 1
	.db 6, 1
	.db 7, 4
	.db 8, 4
	.db 9, 8
	.db 10, 8
	.db 11, 12
	.db 12, 12
	.db 13, 12
	.db 14, 12
	.db 15, 1
	.db $FF
EnvSeq04:
	.db 8, 2
	.db 9, 4
	.db 10, 5
	.db 11, 6
	.db 12, 6
	.db 13, 7
	.db 14, 8
	.db 15, 1
	.db $FF
EnvSeq05:
	.db 5, 1
	.db 6, 1
	.db 7, 1
	.db 8, 1
	.db 9, 6
	.db 10, 8
	.db 11, 10
	.db 12, 12
	.db 13, 14
	.db 14, 16
	.db 15, 1
	.db $FF
EnvSeq06:
	.db 5, 1
	.db 6, 1
	.db 7, 1
	.db 8, 1
	.db 9, 12
	.db 10, 16
	.db 11, 20
	.db 12, 24
	.db 13, 28
	.db 14, 32
	.db 15, 1
	.db $FF
EnvSeq07:
	.db 9, 1
	.db 15, 1
	.db $FF
EnvSeq08:
	.db 10, 1
	.db 15
	.db $FF
EnvSeq09:
	.db 8, 1
	.db 15, 1
	.db $FF
EnvSeq0A:
	.db 5, 1
	.db 15, 1
	.db $FF
EnvSeq0B:
	.db 6, 2
	.db 8, 1
	.db 7, 1
	.db 8, 2
	.db 9, 1
	.db 10, 1
	.db 11, 1
	.db 12, 1
	.db 13, 2
	.db 14, 2
	.db 15, 1
	.db $FF
EnvSeq0C:
	.db 3, 1
	.db 4, 1
	.db 5, 3
	.db 6, 3
	.db 7, 4
	.db 8, 8
	.db 9, 12
	.db 10, 16
	.db 11, 20
	.db 12, 24
	.db 13, 28
	.db 14, 32
	.db 15, 1
	.db $FF
EnvSeq0D:
	.db 10, 2
	.db 11, 4
	.db 12, 5
	.db 13, 6
	.db 14, 6
	.db 14, 7
	.db 14, 8
	.db 15, 1
	.db $FF
EnvSeq0E:
	.db 5, 2
	.db 6, 6
	.db 7, 12
	.db 8, 12
	.db 9, 24
	.db 10, 24
	.db 11, 25
	.db 12, 25
	.db 13, 25
	.db 14, 32
	.db 15, 1
	.db $FF
	
VibSeq00:
	.db 0, 255
	.db $FF
VibSeq01:
	.db 0, 10
	.db -5, 4
	.db 5, 4
	.db -5, 4
	.db 5, 4
	.db -5, 4
	.db 5, 4
	.db -5, 4
	.db 5, 4
	.db -5, 4
	.db 5, 4
	.db -5, 4
	.db 5, 4
	.db -5, 4
	.db 5, 4
	.db -5, 4
	.db 5, 4
	.db -5, 4
	.db 5, 4
	.db -5, 4
	.db 5, 4
	.db -5, 4
	.db 5, 4
	.db -5, 4
	.db 5, 4
	.db -5, 4
	.db 5, 4
	.db -5, 4
	.db 5, 4
	.db -5, 4
	.db 5, 4
	.db -5, 4
	.db 5, 4
	.db -5, 4
	.db 5, 4
	.db -5, 4
	.db 5, 4
	.db -5, 4
	.db 5, 4
	.db -5, 4
	.db 5, 4
	.db -5, 4
	.db 5, 4
	.db -5, 4
	.db 5, 4
	.db $FF
VibSeq02:
	.db 0, 10
	.db -2, 4
	.db 2, 4
	.db -2, 4
	.db 2, 4
	.db -2, 4
	.db 2, 4
	.db -2, 4
	.db 2, 4
	.db -2, 4
	.db 2, 4
	.db -2, 4
	.db 2, 4
	.db -2, 4
	.db 2, 4
	.db -2, 4
	.db 2, 4
	.db -2, 4
	.db 2, 4
	.db -2, 4
	.db 2, 4
	.db -2, 4
	.db 2, 4
	.db -2, 4
	.db 2, 4
	.db -2, 4
	.db 2, 4
	.db -2, 4
	.db 2, 4
	.db -2, 4
	.db 2, 4
	.db -2, 4
	.db 2, 4
	.db -2, 4
	.db 2, 4
	.db -2, 4
	.db 2, 4
	.db -2, 4
	.db 2, 4
	.db -2, 4
	.db 2, 4
	.db -2, 4
	.db 2, 4
	.db -2, 4
	.db 2, 4
	.db $FF

ModSeq00:
	.db 0, 255
	.db $FF
ModSeq01:
	.db 12, 2
	.db 0, 1
	.db 3, 1
	.db 7, 1
	.db 0, 1
	.db 3, 1
	.db 7, 1
	.db 0, 1
	.db 3, 1
	.db 7, 1
	.db $FF
ModSeq02:
	.db 12, 2
	.db 0, 1
	.db 4, 1
	.db 7, 1
	.db 0, 1
	.db 4, 1
	.db 7, 1
	.db 0, 1
	.db 4, 1
	.db 7, 1
	.db $FF
ModSeq03:
	.db 0, 1
	.db 12, 1
	.db 0, 1
	.db 12, 1
	.db 0, 2
	.db 12, 2
	.db 0, 2
	.db 12, 2
	.db 0, 3
	.db 12, 3
	.db 0, 3
	.db 12, 3
	.db 0, 4
	.db 12, 4
	.db 0, 4
	.db 12, 4
	.db 0, 3
	.db 12, 3
	.db 0, 3
	.db 12, 3
	.db 0, 2
	.db 12, 2
	.db 0, 2
	.db 12, 2
	.db $FF
	
VictoryA:
	.db $68, 216
	.db $64, $00, -3, 1
	.db $60, $00
	.db $66, 1
	.db $62
	.dw VictoryA
VictoryB:
	.db $64, $01, -3, 1
	.db $62
	.dw VictoryB
VictoryC:
	.db $46, $00
	.db $64, $00, -3, 1
	.db $62
	.dw VictoryC
VictoryD:
	.db $64, $02, 0, 1
	.db $62
	.dw VictoryD
SongMacro00:
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $27, $42
	.db $2E, $42
	.db $36, $42
	.db $27, $42
	.db $2E, $42
	.db $33, $42
	.db $3A, $42
	.db $27, $42
	.db $2E, $42
	.db $36, $42
	.db $27, $42
	.db $35, $42
	.db $2E, $42
	.db $33, $42
	.db $27, $42
	.db $2E, $42
	.db $29, $42
	.db $2E, $42
	.db $3A, $42
	.db $29, $42
	.db $38, $42
	.db $2E, $42
	.db $29, $42
	.db $2E, $42
	.db $35, $42
	.db $38, $42
	.db $29, $42
	.db $2E, $42
	.db $33, $42
	.db $35, $42
	.db $38, $42
	.db $35, $42
	.db $29, $42
	.db $2C, $42
	.db $2F, $42
	.db $35, $42
	.db $38, $42
	.db $2C, $42
	.db $2F, $42
	.db $35, $42
	.db $3F, $42
	.db $3B, $42
	.db $38, $42
	.db $35, $42
	.db $2F, $42
	.db $38, $42
	.db $2C, $42
	.db $2F, $42
	.db $27, $42
	.db $2C, $42
	.db $33, $42
	.db $38, $42
	.db $36, $42
	.db $35, $42
	.db $33, $42
	.db $31, $42
	.db $2F, $42
	.db $33, $42
	.db $36, $42
	.db $2C, $42
	.db $2F, $42
	.db $33, $42
	.db $2C, $42
	.db $2F, $42
	.db $27, $42
	.db $2E, $42
	.db $36, $42
	.db $27, $42
	.db $2E, $42
	.db $33, $42
	.db $3A, $42
	.db $27, $42
	.db $2E, $42
	.db $36, $42
	.db $27, $42
	.db $35, $42
	.db $2E, $42
	.db $33, $42
	.db $27, $42
	.db $2E, $42
	.db $29, $42
	.db $2E, $42
	.db $3A, $42
	.db $29, $42
	.db $38, $42
	.db $2E, $42
	.db $29, $42
	.db $2E, $42
	.db $35, $42
	.db $38, $42
	.db $29, $42
	.db $2E, $42
	.db $33, $42
	.db $35, $42
	.db $38, $42
	.db $35, $42
	.db $29, $42
	.db $2C, $42
	.db $2F, $42
	.db $35, $42
	.db $38, $42
	.db $2C, $42
	.db $2F, $42
	.db $35, $42
	.db $3F, $42
	.db $3B, $42
	.db $38, $42
	.db $35, $42
	.db $2F, $42
	.db $38, $42
	.db $2C, $42
	.db $2F, $42
	.db $27, $42
	.db $2C, $42
	.db $33, $42
	.db $38, $42
	.db $36, $42
	.db $35, $42
	.db $33, $42
	.db $31, $42
	.db $2F, $42
	.db $33, $42
	.db $36, $42
	.db $2C, $42
	.db $2F, $42
	.db $33, $42
	.db $2C, $42
	.db $2F, $42
	.db $27, $42
	.db $2E, $42
	.db $37, $42
	.db $27, $42
	.db $2E, $42
	.db $33, $42
	.db $3A, $42
	.db $27, $42
	.db $2E, $42
	.db $37, $42
	.db $27, $42
	.db $35, $42
	.db $2E, $42
	.db $33, $42
	.db $27, $42
	.db $2E, $42
	.db $29, $42
	.db $2E, $42
	.db $3A, $42
	.db $29, $42
	.db $38, $42
	.db $2E, $42
	.db $29, $42
	.db $2E, $42
	.db $35, $42
	.db $38, $42
	.db $29, $42
	.db $2E, $42
	.db $33, $42
	.db $35, $42
	.db $38, $42
	.db $35, $42
	.db $29, $42
	.db $2C, $42
	.db $30, $42
	.db $35, $42
	.db $38, $42
	.db $2C, $42
	.db $30, $42
	.db $35, $42
	.db $3F, $42
	.db $3C, $42
	.db $38, $42
	.db $35, $42
	.db $30, $42
	.db $38, $42
	.db $2C, $42
	.db $30, $42
	.db $27, $42
	.db $2C, $42
	.db $33, $42
	.db $38, $42
	.db $37, $42
	.db $35, $42
	.db $33, $42
	.db $32, $42
	.db $30, $42
	.db $33, $42
	.db $37, $42
	.db $2C, $42
	.db $30, $42
	.db $33, $42
	.db $2C, $42
	.db $30, $40
	.db $65
SongMacro01:
	.db $1B, $15
 	.db $1B, $15
  	.db $1B, $16
 	.db $1B, $14
 	.db $1B, $16
 	.db $16, $15
  	.db $16, $15
 	.db $16, $16
 	.db $16, $14
 	.db $16, $16
  	.db $1D, $15
 	.db $1D, $15
 	.db $1D, $16
 	.db $1D, $14
  	.db $1D, $16
 	.db $20, $15
 	.db $20, $15
 	.db $20, $16
  	.db $20, $14
 	.db $20, $14
 	.db $1E, $14
 	.db $1B, $15
  	.db $1B, $15
 	.db $1B, $16
 	.db $1B, $14
 	.db $1B, $14
  	.db $1B, $14
 	.db $22, $15
 	.db $22, $15
 	.db $22, $17
  	.db $22, $14
 	.db $22, $14
 	.db $1D, $15
 	.db $1D, $15
  	.db $1D, $16
 	.db $1D, $16
 	.db $1D, $14
 	.db $20, $15
  	.db $20, $15
 	.db $20, $16
 	.db $14, $14
 	.db $20, $12
  	.db $14, $12
 	.db $20, $14
 	.db $1B, $12
 	.db $1B, $14
  	.db $1B, $12
 	.db $1B, $15
 	.db $1B, $12
 	.db $1B, $12
  	.db $1B, $12
 	.db $1B, $15
 	.db $1B, $12
 	.db $1B, $12
  	.db $1B, $12
 	.db $16, $12
 	.db $16, $12
 	.db $16, $12
  	.db $16, $12
 	.db $16, $14
 	.db $16, $12
 	.db $16, $12
  	.db $16, $12
 	.db $16, $12
 	.db $16, $12
 	.db $16, $14
  	.db $16, $12
 	.db $16, $14
 	.db $1D, $12
 	.db $1D, $12
  	.db $1D, $12
 	.db $1D, $12
 	.db $1D, $14
 	.db $1D, $14
  	.db $1D, $12
 	.db $1D, $12
 	.db $1D, $12
 	.db $1D, $14
  	.db $1D, $12
 	.db $1D, $14
 	.db $20, $12
 	.db $20, $12
  	.db $20, $12
 	.db $20, $12
 	.db $20, $14
 	.db $20, $12
  	.db $20, $12
 	.db $20, $12
 	.db $20, $12
 	.db $20, $12
  	.db $20, $12
 	.db $1E, $12
 	.db $1E, $12
 	.db $1D, $12
  	.db $1D, $12
 	.db $1B, $12
 	.db $1B, $12
 	.db $1B, $12
  	.db $1B, $14
 	.db $1B, $12
 	.db $1B, $12
 	.db $1B, $12
  	.db $1B, $12
 	.db $1B, $12
 	.db $1B, $12
 	.db $1B, $12
  	.db $1B, $12
 	.db $1B, $12
 	.db $1B, $12
 	.db $1B, $12
  	.db $16, $12
 	.db $16, $12
 	.db $16, $12
 	.db $16, $14
  	.db $16, $12
 	.db $16, $12
 	.db $16, $12
 	.db $16, $14
  	.db $16, $14
 	.db $16, $14
 	.db $16, $14
 	.db $1D, $12
  	.db $1D, $12
 	.db $1D, $12
 	.db $1D, $14
 	.db $1D, $15
  	.db $1D, $12
 	.db $29, $12
 	.db $1D, $14
 	.db $1D, $12
  	.db $29, $12
 	.db $1D, $14
 	.db $20, $12
 	.db $20, $14
  	.db $20, $14
 	.db $20, $15
 	.db $20, $12
 	.db $2C, $12
  	.db $20, $14
 	.db $1F, $12
 	.db $2B, $12
 	.db $1F, $14
  	.db $1B, $16
 	.db $1B, $14
 	.db $1B, $16
 	.db $1B, $14
  	.db $1B, $12
 	.db $27, $12
 	.db $1B, $12
 	.db $27, $12
  	.db $16, $15
 	.db $16, $15
 	.db $16, $14
 	.db $16, $14
  	.db $16, $14
 	.db $16, $12
 	.db $22, $12
 	.db $16, $12
  	.db $22, $12
 	.db $1D, $15
 	.db $1D, $15
 	.db $1D, $14
  	.db $1D, $12
 	.db $29, $12
 	.db $1D, $14
 	.db $1D, $12
  	.db $29, $12
 	.db $1D, $16
 	.db $20, $14
 	.db $20, $15
  	.db $20, $14
 	.db $2C, $12
 	.db $20, $14
 	.db $1F, $12
  	.db $2B, $12
 	.db $1F, $14
 	.db $1B, $15
 	.db $1B, $15
  	.db $1B, $14
 	.db $1B, $12
 	.db $27, $12
 	.db $1B, $14
  	.db $1B, $12
 	.db $27, $12
 	.db $1B, $14
 	.db $16, $15
  	.db $16, $15
 	.db $16, $14
 	.db $16, $12
 	.db $22, $12
  	.db $16, $14
 	.db $16, $12
 	.db $22, $12
 	.db $16, $15
  	.db $1D, $12
 	.db $1D, $14
 	.db $1D, $15
 	.db $1D, $14
  	.db $1D, $12
 	.db $1D, $14
 	.db $1D, $12
 	.db $29, $12
  	.db $1D, $12
 	.db $29, $12
 	.db $20, $12
 	.db $2C, $12
  	.db $20, $12
 	.db $2C, $12
 	.db $20, $12
 	.db $2C, $12
  	.db $20, $12
 	.db $2C, $12
 	.db $20, $12
 	.db $2C, $12
  	.db $20, $12
 	.db $2C, $12
 	.db $1F, $12
 	.db $2B, $12
  	.db $1F, $12
 	.db $2B, $12
	.db $65
SongMacro02:
	.db $63, $04
	.db $0F, $92
	.db $63, $04
	.db $17, $72
	.db $63, $04
	.db $0F, $92
	.db $63, $04
	.db $17, $72
	.db $63, $04
	.db $11, $A2
	.db $63, $04
	.db $17, $72
	.db $63, $04
	.db $0F, $92
	.db $0F, $92
	.db $63, $04
	.db $17, $72
	.db $63, $04
	.db $0F, $92
	.db $0F, $82
	.db $0F, $82
	.db $63, $04
	.db $11, $A2
	.db $63, $04
	.db $17, $72
	.db $17, $72
	.db $17, $72
	.db $65
	.db $0F, $82
	.db $17, $82
	.db $0F, $82
	.db $17, $82
	.db $11, $82
	.db $17, $82
	.db $0F, $82
	.db $0F, $82
	.db $17, $82
	.db $0F, $82
	.db $0F, $82
	.db $0F, $82
	.db $11, $82
	.db $17, $82
	.db $17, $82
	.db $11, $82
	.db $0F, $82
	.db $17, $82
	.db $0F, $82
	.db $17, $82
	.db $11, $82
	.db $17, $82
	.db $0F, $82
	.db $0F, $82
	.db $17, $82
	.db $0F, $82
	.db $0F, $82
	.db $0F, $82
	.db $11, $82
	.db $17, $82
	.db $17, $82
	.db $17, $82
	.db $0F, $82
	.db $0F, $82
	.db $17, $82
	.db $17, $82
	.db $11, $82
	.db $17, $82
	.db $0F, $82
	.db $0F, $82
	.db $17, $82
	.db $0F, $82
	.db $0F, $82
	.db $0F, $82
	.db $11, $82
	.db $17, $82
	.db $17, $82
	.db $11, $82
	.db $65

FlightTermA:
	.db $68, 252
	.db $64, $03, -15, 1
	.db $66, 1
	.db $62
	.dw FlightTermA
FlightTermB:
	.db $64, $04, -3, 1
	.db $62
	.dw FlightTermB
FlightTermC:
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $64, $05, -3, 12
	.db $64, $05, -5, 4
	.db $64, $05, -3, 4
	.db $64, $05, 0, 4
	.db $64, $05, -1, 3
	.db $64, $05, -3, 1
	.db $62
	.dw FlightTermC
FlightTermD:
	.db $64, $06, 0, 1
	.db $62
	.dw FlightTermD
	
SongMacro03:
	.db $35, $52
	.db $37, $52
	.db $3A, $52
	.db $3C, $52
	.db $37, $52
	.db $3A, $52
	.db $3C, $52
	.db $3E, $52
	.db $3A, $52
	.db $3C, $52
	.db $3E, $52
	.db $41, $52
	.db $3A, $52
	.db $3C, $52
	.db $41, $52
	.db $43, $52
	.db $3E, $52
	.db $41, $52
	.db $43, $52
	.db $46, $52
	.db $41, $52
	.db $43, $52
	.db $46, $52
	.db $48, $52
	.db $41, $52
	.db $43, $52
	.db $46, $52
	.db $48, $52
	.db $43, $52
	.db $46, $52
	.db $41, $52
	.db $43, $52
	.db $46, $52
	.db $48, $52
	.db $46, $52
	.db $48, $52
	.db $43, $52
	.db $46, $52
	.db $48, $52
	.db $4A, $52
	.db $46, $52
	.db $48, $52
	.db $4A, $52
	.db $4D, $52
	.db $46, $52
	.db $48, $52
	.db $4D, $52
	.db $4F, $52
	.db $4A, $52
	.db $4D, $52
	.db $4F, $52
	.db $52, $52
	.db $4D, $52
	.db $4F, $52
	.db $52, $52
	.db $54, $52
	.db $4D, $52
	.db $4F, $52
	.db $52, $52
	.db $54, $52
	.db $4F, $52
	.db $52, $52
	.db $41, $52
	.db $43, $52
	.db $4D, $54
	.db $4F, $56
	.db $41, $52
	.db $43, $52
	.db $4D, $54
	.db $4F, $52
	.db $4D, $55
	.db $41, $52
	.db $43, $52
	.db $4D, $54
	.db $4F, $56
	.db $41, $52
	.db $43, $52
	.db $4D, $54
	.db $4F, $52
	.db $4D, $55
	.db $41, $52
	.db $43, $52
	.db $4D, $54
	.db $4F, $56
	.db $41, $52
	.db $43, $52
	.db $4D, $54
	.db $4F, $52
	.db $4D, $55
	.db $41, $52
	.db $43, $52
	.db $4D, $54
	.db $4F, $56
	.db $41, $52
	.db $43, $52
	.db $4D, $54
	.db $4F, $52
	.db $4D, $55
	.db $41, $52
	.db $43, $52
	.db $46, $54
	.db $48, $56
	.db $41, $52
	.db $43, $52
	.db $46, $54
	.db $48, $52
	.db $46, $55
	.db $41, $52
	.db $43, $52
	.db $46, $54
	.db $48, $56
	.db $41, $52
	.db $43, $52
	.db $46, $54
	.db $48, $52
	.db $46, $55
	.db $41, $52
	.db $43, $52
	.db $46, $54
	.db $48, $56
	.db $41, $52
	.db $43, $52
	.db $46, $54
	.db $48, $52
	.db $46, $55
	.db $41, $52
	.db $43, $52
	.db $46, $54
	.db $48, $56
	.db $41, $52
	.db $43, $52
	.db $48, $54
	.db $4A, $52
	.db $48, $55
	.db $41, $52
	.db $43, $52
	.db $4D, $54
	.db $4F, $56
	.db $41, $52
	.db $43, $52
	.db $4D, $54
	.db $4F, $52
	.db $4D, $55
	.db $41, $52
	.db $43, $52
	.db $4D, $54
	.db $4F, $56
	.db $41, $52
	.db $43, $52
	.db $4D, $54
	.db $4F, $52
	.db $4D, $55
	.db $41, $52
	.db $43, $52
	.db $4D, $54
	.db $4F, $56
	.db $41, $52
	.db $43, $52
	.db $4D, $54
	.db $4F, $52
	.db $4D, $55
	.db $41, $52
	.db $43, $52
	.db $35, $52
	.db $37, $52
	.db $3A, $52
	.db $3C, $52
	.db $37, $52
	.db $3A, $52
	.db $3C, $52
	.db $3E, $52
	.db $3A, $52
	.db $3C, $52
	.db $3E, $52
	.db $41, $52
	.db $3A, $52
	.db $3C, $52
	.db $41, $52
	.db $43, $52
	.db $30, $0A
	.db $30, $0A
	.db $34, $52
	.db $35, $52
	.db $3A, $52
	.db $3C, $52
	.db $3A, $52
	.db $35, $52
	.db $34, $52
	.db $35, $52
	.db $3A, $52
	.db $3C, $52
	.db $3A, $52
	.db $35, $52
	.db $34, $52
	.db $35, $52
	.db $3A, $52
	.db $3C, $52
	.db $3A, $52
	.db $35, $52
	.db $34, $52
	.db $35, $52
	.db $3A, $52
	.db $3C, $52
	.db $3A, $52
	.db $35, $52
	.db $34, $52
	.db $35, $52
	.db $3A, $52
	.db $3C, $52
	.db $3A, $52
	.db $35, $52
	.db $34, $52
	.db $35, $52
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $2A, $52
	.db $37, $52
	.db $3C, $52
	.db $3E, $52
	.db $3C, $52
	.db $37, $52
	.db $36, $52
	.db $37, $52
	.db $3C, $52
	.db $3E, $52
	.db $3C, $52
	.db $37, $52
	.db $36, $52
	.db $37, $52
	.db $3C, $52
	.db $3E, $52
	.db $65
SongMacro05:
	.db $2B, $B4
	.db $2B, $B2
	.db $2B, $B2
	.db $2B, $B4
	.db $2B, $B2
	.db $2B, $B2
	.db $2B, $B4
	.db $2B, $B2
	.db $2B, $B2
	.db $2B, $B4
	.db $2B, $B2
	.db $2B, $B2
	.db $65
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $28, $52
	.db $29, $52
	.db $2E, $52
	.db $30, $52
	.db $2E, $52
	.db $29, $52
	.db $28, $52
	.db $29, $52
	.db $2E, $52
	.db $30, $52
	.db $2E, $52
	.db $29, $52
	.db $28, $52
	.db $29, $52
	.db $2E, $52
	.db $30, $52
	.db $2E, $52
	.db $29, $52
	.db $28, $52
	.db $29, $52
	.db $2E, $52
	.db $30, $52
	.db $2E, $52
	.db $29, $52
	.db $28, $52
	.db $29, $52
	.db $2E, $52
	.db $30, $52
	.db $2E, $52
	.db $29, $52
	.db $28, $52
	.db $29, $52
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $28, $52
	.db $29, $52
	.db $2E, $52
	.db $30, $52
	.db $2E, $52
	.db $29, $52
	.db $28, $52
	.db $29, $52
	.db $2E, $52
	.db $30, $52
	.db $2E, $52
	.db $29, $52
	.db $28, $52
	.db $29, $52
	.db $2E, $52
	.db $30, $52
	.db $2E, $52
	.db $29, $52
	.db $28, $52
	.db $29, $52
	.db $2E, $52
	.db $30, $52
	.db $2E, $52
	.db $29, $52
	.db $28, $52
	.db $29, $52
	.db $2E, $52
	.db $30, $52
	.db $2E, $52
	.db $29, $52
	.db $28, $52
	.db $29, $52
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $2A, $52
	.db $2B, $52
	.db $30, $52
	.db $32, $52
	.db $30, $52
	.db $2B, $52
	.db $2A, $52
	.db $2B, $52
	.db $30, $52
	.db $32, $52
	.db $30, $52
	.db $2B, $52
	.db $2A, $52
	.db $2B, $52
	.db $30, $52
	.db $32, $52
	.db $65
SongMacro04:
	.db $30, $0A
	.db $13, $3C
	.db $30, $0A
	.db $13, $14
	.db $13, $14
	.db $16, $14
	.db $16, $14
	.db $18, $15
	.db $30, $06
	.db $13, $14
	.db $13, $12
	.db $13, $14
	.db $16, $14
	.db $16, $14
	.db $18, $14
	.db $18, $12
	.db $1A, $14
	.db $1A, $12
	.db $1D, $12
	.db $1F, $12
	.db $13, $14
	.db $13, $14
	.db $16, $14
	.db $16, $14
	.db $18, $16
	.db $11, $12
	.db $1D, $12
	.db $13, $12
	.db $1F, $12
	.db $13, $14
	.db $13, $14
	.db $16, $14
	.db $16, $14
	.db $1A, $14
	.db $1A, $12
	.db $18, $14
	.db $18, $12
	.db $16, $14
	.db $13, $14
	.db $13, $14
	.db $16, $14
	.db $16, $14
	.db $18, $17
	.db $30, $02
	.db $13, $14
	.db $13, $12
	.db $13, $14
	.db $16, $14
	.db $16, $14
	.db $18, $14
	.db $18, $12
	.db $1A, $14
	.db $1A, $12
	.db $1D, $12
	.db $1F, $12
	.db $13, $14
	.db $13, $14
	.db $16, $14
	.db $16, $14
	.db $18, $16
	.db $11, $12
	.db $1D, $12
	.db $13, $12
	.db $1F, $12
	.db $13, $14
	.db $13, $14
	.db $16, $14
	.db $16, $14
	.db $18, $14
	.db $1A, $12
	.db $1D, $12
	.db $18, $12
	.db $1A, $12
	.db $1F, $12
	.db $16, $12
	.db $13, $14
	.db $13, $14
	.db $16, $14
	.db $16, $14
	.db $18, $17
	.db $30, $02
	.db $13, $14
	.db $13, $12
	.db $13, $14
	.db $16, $14
	.db $16, $14
	.db $18, $14
	.db $18, $12
	.db $1A, $14
	.db $1A, $12
	.db $1D, $12
	.db $1F, $12
	.db $13, $14
	.db $13, $14
	.db $16, $14
	.db $16, $14
	.db $18, $16
	.db $11, $12
	.db $1D, $12
	.db $13, $12
	.db $1F, $12
	.db $13, $12
	.db $1F, $12
	.db $13, $12
	.db $1D, $14
	.db $11, $12
	.db $1B, $12
	.db $10, $12
	.db $1F, $14
	.db $18, $12
	.db $0C, $12
	.db $1D, $12
	.db $13, $12
	.db $1F, $12
	.db $22, $12
	.db $11, $14
	.db $11, $14
	.db $14, $14
	.db $14, $14
	.db $16, $17
	.db $30, $02
	.db $11, $14
	.db $11, $12
	.db $11, $14
	.db $14, $14
	.db $14, $14
	.db $16, $14
	.db $16, $12
	.db $18, $14
	.db $18, $12
	.db $1B, $12
	.db $1D, $12
	.db $11, $14
	.db $11, $14
	.db $14, $14
	.db $14, $14
	.db $16, $17
	.db $30, $02
	.db $11, $14
	.db $11, $12
	.db $11, $14
	.db $14, $14
	.db $14, $14
	.db $16, $14
	.db $18, $12
	.db $1B, $12
	.db $16, $12
	.db $18, $12
	.db $1D, $12
	.db $14, $12
	.db $13, $14
	.db $13, $14
	.db $16, $14
	.db $16, $14
	.db $18, $16
	.db $11, $12
	.db $1D, $12
	.db $13, $12
	.db $1F, $12
	.db $13, $12
	.db $13, $12
	.db $13, $12
	.db $13, $12
	.db $16, $14
	.db $16, $14
	.db $18, $14
	.db $1A, $12
	.db $1A, $14
	.db $1A, $12
	.db $1D, $12
	.db $1F, $12
	.db $13, $14
	.db $13, $14
	.db $16, $14
	.db $16, $14
	.db $18, $16
	.db $11, $12
	.db $1D, $12
	.db $22, $12
	.db $11, $12
	.db $13, $12
	.db $1F, $12
	.db $13, $12
	.db $1D, $14
	.db $11, $12
	.db $1B, $12
	.db $10, $12
	.db $1F, $14
	.db $18, $12
	.db $0C, $12
	.db $1D, $12
	.db $13, $12
	.db $1F, $12
	.db $22, $12
	.db $16, $14
	.db $16, $14
	.db $19, $14
	.db $19, $14
	.db $1B, $16
	.db $14, $12
	.db $20, $12
	.db $16, $12
	.db $22, $12
	.db $16, $12
	.db $16, $12
	.db $16, $12
	.db $16, $12
	.db $19, $14
	.db $19, $14
	.db $1B, $14
	.db $1D, $12
	.db $1D, $14
	.db $1D, $12
	.db $20, $12
	.db $22, $12
	.db $16, $14
	.db $16, $14
	.db $19, $14
	.db $19, $14
	.db $1B, $16
	.db $14, $12
	.db $20, $12
	.db $16, $12
	.db $22, $12
	.db $16, $12
	.db $22, $12
	.db $16, $12
	.db $20, $14
	.db $14, $12
	.db $20, $12
	.db $13, $12
	.db $1F, $14
	.db $22, $12
	.db $14, $12
	.db $20, $12
	.db $16, $12
	.db $22, $14
	.db $15, $14
	.db $15, $14
	.db $18, $14
	.db $18, $14
	.db $1A, $16
	.db $13, $12
	.db $1F, $12
	.db $24, $12
	.db $13, $12
	.db $15, $12
	.db $15, $12
	.db $15, $12
	.db $15, $12
	.db $18, $14
	.db $18, $14
	.db $1A, $12
	.db $1A, $12
	.db $1C, $12
	.db $1C, $14
	.db $1C, $12
	.db $1F, $12
	.db $21, $12
	.db $15, $14
	.db $15, $14
	.db $18, $14
	.db $18, $14
	.db $1A, $16
	.db $1F, $12
	.db $20, $12
	.db $21, $12
	.db $24, $12
	.db $30, $08
	.db $07, $12
	.db $07, $12
	.db $07, $12
	.db $07, $12
	.db $07, $12
	.db $07, $12
	.db $07, $12
	.db $07, $12
	.db $65
SongMacro06:
	.db $63, $04
	.db $0F, $94
	.db $63, $04
	.db $15, $74
	.db $63, $04
	.db $11, $A2
	.db $63, $04
	.db $15, $72
	.db $15, $74
	.db $63, $04
	.db $0F, $94
	.db $63, $04
	.db $15, $74
	.db $63, $04
	.db $0F, $92
	.db $63, $04
	.db $15, $72
	.db $15, $74
	.db $65
	
HellCorpA:
	.db $68, 252
	.db $64, $07, 12, 1
	.db $66, 1
	.db $62
	.dw HellCorpA
HellCorpB:
	.db $64, $08, 0, 1
	.db $62
	.dw HellCorpB
HellCorpC:
	.db $64, $09, 0, 1
	.db $62
	.dw HellCorpC
HellCorpD:
	.db $64, $0A, 0, 1
	.db $62
	.dw HellCorpD
	
SongMacro09:
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $30, $0A
	.db $30, $E4
	.db $31, $E4
	.db $32, $E4
	.db $33, $E4
	.db $31, $E4
	.db $32, $E4
	.db $33, $E4
	.db $34, $E4
	.db $32, $ED
	.db $33, $ED
	.db $34, $ED
	.db $35, $ED
	.db $33, $ED
	.db $34, $ED
	.db $35, $ED
	.db $36, $ED
	.db $33, $ED
	.db $34, $ED
	.db $35, $ED
	.db $36, $ED
	.db $29, $E2
	.db $2A, $E2
	.db $2B, $E2
	.db $2C, $E2
	.db $2B, $E2
	.db $2C, $E2
	.db $2D, $E2
	.db $2E, $E2
	.db $2C, $E2
	.db $2D, $E2
	.db $2E, $E2
	.db $2F, $E2
	.db $2E, $E2
	.db $2F, $E2
	.db $30, $E2
	.db $31, $E2
	.db $30, $E1
	.db $31, $E1
	.db $32, $E1
	.db $31, $E1
	.db $32, $E1
	.db $33, $E1
	.db $32, $E1
	.db $33, $E1
	.db $34, $E1
	.db $33, $E1
	.db $34, $E1
	.db $35, $E1
	.db $35, $E1
	.db $36, $E1
	.db $37, $E1
	.db $35, $E1
	.db $36, $E1
	.db $38, $E1
	.db $37, $E1
	.db $38, $E1
	.db $39, $E1
	.db $38, $E1
	.db $39, $E1
	.db $3A, $E1
	.db $2D, $E0
	.db $2E, $E0
	.db $2F, $E0
	.db $30, $E0
	.db $2E, $E0
	.db $2F, $E0
	.db $30, $E0
	.db $31, $E0
	.db $2F, $E0
	.db $30, $E0
	.db $31, $E0
	.db $32, $E0
	.db $30, $E0
	.db $31, $E0
	.db $32, $E0
	.db $33, $E0
	.db $31, $E0
	.db $32, $E0
	.db $33, $E0
	.db $34, $E0
	.db $32, $E0
	.db $33, $E0
	.db $34, $E0
	.db $35, $E0
	.db $33, $E0
	.db $34, $E0
	.db $35, $E0
	.db $36, $E0
	.db $35, $E0
	.db $36, $E0
	.db $37, $E0
	.db $38, $E0
	.db $3C, $E2
	.db $37, $E2
	.db $33, $E2
	.db $30, $E2
	.db $37, $E2
	.db $33, $E2
	.db $30, $E2
	.db $2B, $E2
	.db $30, $E2
	.db $2E, $E2
	.db $2B, $E2
	.db $33, $E2
	.db $2E, $E2
	.db $2B, $E2
	.db $33, $E2
	.db $30, $E2
	.db $33, $E2
	.db $30, $E2
	.db $2E, $E2
	.db $2B, $E2
	.db $30, $E2
	.db $2E, $E2
	.db $2B, $E2
	.db $27, $E2
	.db $2B, $E2
	.db $27, $E2
	.db $24, $E2
	.db $2B, $E2
	.db $27, $E2
	.db $24, $E2
	.db $24, $E0
	.db $27, $E0
	.db $2B, $E2
	.db $2E, $EA
	.db $30, $E1
	.db $31, $E1
	.db $32, $E1
	.db $33, $E1
	.db $34, $E1
	.db $35, $E1
	.db $36, $E1
	.db $37, $E1
	.db $38, $E1
	.db $39, $E1
	.db $3A, $E1
	.db $3B, $E1
	.db $3C, $E2
	.db $37, $E2
	.db $35, $E2
	.db $30, $E2
	.db $2E, $E4
	.db $2D, $E4
	.db $2E, $E1
	.db $2F, $E1
	.db $30, $E1
	.db $31, $E1
	.db $32, $E1
	.db $33, $E1
	.db $34, $E1
	.db $35, $E1
	.db $36, $E1
	.db $37, $E1
	.db $38, $E1
	.db $39, $E1
	.db $3A, $E2
	.db $35, $E2
	.db $33, $E2
	.db $2E, $E2
	.db $2C, $E4
	.db $2B, $E4
	.db $3C, $E5
	.db $3F, $E5
	.db $3A, $E4
	.db $3C, $E6
	.db $39, $E6
	.db $30, $E1
	.db $31, $E1
	.db $32, $E1
	.db $33, $E1
	.db $34, $E1
	.db $35, $E1
	.db $36, $E1
	.db $37, $E1
	.db $38, $E1
	.db $39, $E1
	.db $3A, $E1
	.db $3B, $E1
	.db $3C, $E2
	.db $37, $E2
	.db $35, $E2
	.db $30, $E2
	.db $2E, $E4
	.db $2D, $E4
	.db $30, $E1
	.db $31, $E1
	.db $32, $E1
	.db $33, $E1
	.db $34, $E1
	.db $35, $E1
	.db $36, $E1
	.db $37, $E1
	.db $38, $E1
	.db $39, $E1
	.db $3A, $E1
	.db $3B, $E1
	.db $3C, $E1
	.db $33, $E1
	.db $2B, $E1
	.db $3C, $E5
	.db $3A, $E5
	.db $2E, $E1
	.db $2F, $E1
	.db $30, $E1
	.db $31, $E1
	.db $32, $E1
	.db $33, $E1
	.db $34, $E1
	.db $35, $E1
	.db $36, $E1
	.db $37, $E1
	.db $38, $E1
	.db $39, $E1
	.db $3A, $E2
	.db $35, $E2
	.db $33, $E2
	.db $2E, $E2
	.db $2C, $E4
	.db $2B, $E4
	.db $3F, $E5
	.db $3C, $E5
	.db $3A, $E4
	.db $3F, $E5
	.db $3C, $E5
	.db $3A, $E4
	.db $2E, $E2
	.db $2B, $E2
	.db $33, $E2
	.db $30, $E2
	.db $33, $E2
	.db $30, $E2
	.db $2E, $E2
	.db $2B, $E2
	.db $30, $E2
	.db $2E, $E2
	.db $2B, $E2
	.db $27, $E2
	.db $2B, $E2
	.db $27, $E2
	.db $24, $E2
	.db $2B, $E2
	.db $27, $E2
	.db $24, $EA
	.db $30, $75
	.db $30, $E4
	.db $31, $E4
	.db $32, $E4
	.db $33, $E4
	.db $31, $E4
	.db $32, $E4
	.db $33, $E4
	.db $34, $E4
	.db $32, $ED
	.db $33, $ED
	.db $34, $ED
	.db $35, $ED
	.db $33, $ED
	.db $34, $ED
	.db $35, $ED
	.db $36, $ED
	.db $33, $ED
	.db $34, $ED
	.db $35, $ED
	.db $36, $ED
	.db $29, $E2
	.db $2A, $E2
	.db $2B, $E2
	.db $2C, $E2
	.db $2B, $E2
	.db $2C, $E2
	.db $2D, $E2
	.db $2E, $E2
	.db $2C, $E2
	.db $2D, $E2
	.db $2E, $E2
	.db $2F, $E2
	.db $2E, $E2
	.db $2F, $E2
	.db $30, $E2
	.db $31, $E2
	.db $30, $E1
	.db $31, $E1
	.db $32, $E1
	.db $31, $E1
	.db $32, $E1
	.db $33, $E1
	.db $32, $E1
	.db $33, $E1
	.db $34, $E1
	.db $33, $E1
	.db $34, $E1
	.db $35, $E1
	.db $35, $E1
	.db $36, $E1
	.db $37, $E1
	.db $35, $E1
	.db $36, $E1
	.db $38, $E1
	.db $37, $E1
	.db $38, $E1
	.db $39, $E1
	.db $38, $E1
	.db $39, $E1
	.db $3A, $E1
	.db $2D, $E0
	.db $2E, $E0
	.db $2F, $E0
	.db $30, $E0
	.db $2E, $E0
	.db $2F, $E0
	.db $30, $E0
	.db $31, $E0
	.db $2F, $E0
	.db $30, $E0
	.db $31, $E0
	.db $32, $E0
	.db $30, $E0
	.db $31, $E0
	.db $32, $E0
	.db $33, $E0
	.db $31, $E0
	.db $32, $E0
	.db $33, $E0
	.db $34, $E0
	.db $32, $E0
	.db $33, $E0
	.db $34, $E0
	.db $35, $E0
	.db $33, $E0
	.db $34, $E0
	.db $35, $E0
	.db $36, $E0
	.db $35, $E0
	.db $36, $E0
	.db $37, $E0
	.db $38, $E0
	.db $3C, $E2
	.db $37, $E2
	.db $33, $E2
	.db $30, $E2
	.db $37, $E2
	.db $33, $E2
	.db $30, $E2
	.db $2B, $E2
	.db $30, $E2
	.db $2E, $E2
	.db $2B, $E2
	.db $33, $E2
	.db $65
SongMacro08:
	.db $18, $12
	.db $18, $12
	.db $18, $12
	.db $18, $12
	.db $18, $12
	.db $18, $12
	.db $18, $12
	.db $18, $12
	.db $16, $12
	.db $16, $12
	.db $16, $12
	.db $16, $12
	.db $16, $12
	.db $16, $12
	.db $16, $12
	.db $16, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1F, $12
	.db $1F, $12
	.db $1F, $12
	.db $1F, $12
	.db $1F, $12
	.db $1F, $12
	.db $1F, $12
	.db $1F, $12
	.db $18, $12
	.db $18, $12
	.db $18, $12
	.db $18, $12
	.db $18, $12
	.db $18, $12
	.db $18, $12
	.db $18, $12
	.db $16, $12
	.db $16, $12
	.db $16, $12
	.db $16, $12
	.db $16, $12
	.db $16, $12
	.db $16, $12
	.db $16, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $13, $12
	.db $1F, $12
	.db $11, $12
	.db $1D, $12
	.db $13, $12
	.db $1F, $12
	.db $16, $12
	.db $22, $12
	.db $18, $12
	.db $18, $12
	.db $18, $12
	.db $18, $12
	.db $18, $12
	.db $18, $12
	.db $18, $12
	.db $18, $12
	.db $16, $12
	.db $16, $12
	.db $16, $12
	.db $16, $12
	.db $16, $12
	.db $16, $12
	.db $16, $12
	.db $16, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1F, $12
	.db $1F, $12
	.db $1F, $12
	.db $1F, $12
	.db $1F, $12
	.db $1F, $12
	.db $1F, $12
	.db $1F, $12
	.db $18, $12
	.db $18, $12
	.db $18, $12
	.db $18, $12
	.db $18, $12
	.db $18, $12
	.db $18, $12
	.db $18, $12
	.db $16, $12
	.db $16, $12
	.db $16, $12
	.db $16, $12
	.db $16, $12
	.db $16, $12
	.db $16, $12
	.db $16, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $13, $12
	.db $1F, $12
	.db $16, $12
	.db $22, $12
	.db $18, $12
	.db $24, $12
	.db $16, $12
	.db $22, $12
	.db $1A, $12
	.db $1A, $12
	.db $1A, $12
	.db $1A, $12
	.db $1A, $12
	.db $1A, $12
	.db $1A, $12
	.db $1A, $12
	.db $1B, $12
	.db $1B, $12
	.db $1B, $12
	.db $1B, $12
	.db $1B, $12
	.db $1B, $12
	.db $1B, $12
	.db $1B, $12
	.db $1F, $12
	.db $1F, $12
	.db $1F, $12
	.db $1F, $12
	.db $1F, $12
	.db $1F, $12
	.db $1F, $12
	.db $1F, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1A, $12
	.db $1A, $12
	.db $1A, $12
	.db $1A, $12
	.db $1A, $12
	.db $1A, $12
	.db $1A, $12
	.db $1A, $12
	.db $1F, $12
	.db $1F, $12
	.db $1F, $12
	.db $1F, $12
	.db $1F, $12
	.db $1F, $12
	.db $1F, $12
	.db $1F, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1B, $12
	.db $27, $12
	.db $1A, $12
	.db $26, $12
	.db $16, $12
	.db $22, $12
	.db $1A, $12
	.db $26, $12
	.db $1B, $12
	.db $1B, $12
	.db $1B, $12
	.db $1B, $12
	.db $1B, $12
	.db $1B, $12
	.db $1B, $12
	.db $1B, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $16, $12
	.db $16, $12
	.db $16, $12
	.db $16, $12
	.db $16, $12
	.db $16, $12
	.db $16, $12
	.db $16, $12
	.db $18, $12
	.db $18, $12
	.db $18, $12
	.db $18, $12
	.db $18, $12
	.db $18, $12
	.db $18, $12
	.db $18, $12
	.db $1B, $12
	.db $1B, $12
	.db $1B, $12
	.db $1B, $12
	.db $1B, $12
	.db $1B, $12
	.db $1B, $12
	.db $1B, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1F, $12
	.db $1F, $12
	.db $1F, $12
	.db $1F, $12
	.db $1F, $12
	.db $1F, $12
	.db $1F, $12
	.db $1F, $12
	.db $1F, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1D, $12
	.db $1B, $12
	.db $27, $12
	.db $1D, $12
	.db $29, $12
	.db $65
SongMacro07:
	.db $30, $0A
	.db $24, $65
	.db $30, $65
	.db $37, $64
	.db $35, $66
	.db $33, $66
	.db $24, $69
	.db $30, $04
	.db $22, $64
	.db $24, $65
	.db $2E, $65
	.db $30, $64
	.db $33, $66
	.db $35, $66
	.db $24, $69
	.db $30, $04
	.db $22, $64
	.db $24, $65
	.db $2E, $65
	.db $30, $64
	.db $37, $66
	.db $35, $66
	.db $24, $6A
	.db $27, $66
	.db $29, $64
	.db $35, $64
	.db $37, $66
	.db $30, $66
	.db $26, $66
	.db $23, $64
	.db $27, $68
	.db $30, $04
	.db $2B, $68
	.db $29, $68
	.db $26, $66
	.db $23, $64
	.db $2B, $68
	.db $30, $04
	.db $29, $68
	.db $27, $68
	.db $27, $68
	.db $29, $68
	.db $22, $67
	.db $26, $64
	.db $24, $68
	.db $27, $67
	.db $24, $64
	.db $29, $67
	.db $2B, $64
	.db $27, $66
	.db $2B, $66
	.db $29, $68
	.db $24, $62
	.db $30, $62
	.db $24, $62
	.db $30, $68
	.db $30, $02
	.db $22, $64
	.db $24, $64
	.db $2E, $65
	.db $30, $65
	.db $37, $64
	.db $35, $66
	.db $33, $66
	.db $24, $62
	.db $30, $62
	.db $24, $62
	.db $30, $66
	.db $30, $02
	.db $22, $62
	.db $2E, $62
	.db $22, $62
	.db $2E, $67
	.db $30, $02
	.db $29, $62
	.db $35, $62
	.db $29, $62
	.db $35, $65
	.db $2B, $62
	.db $37, $62
	.db $2B, $62
	.db $37, $66
	.db $30, $02
	.db $24, $62
	.db $30, $62
	.db $24, $62
	.db $30, $66
	.db $30, $02
	.db $22, $64
	.db $2E, $67
	.db $24, $62
	.db $30, $62
	.db $24, $62
	.db $30, $66
	.db $2B, $64
	.db $37, $62
	.db $2B, $64
	.db $29, $62
	.db $35, $62
	.db $29, $66
	.db $22, $62
	.db $2E, $62
	.db $22, $62
	.db $2E, $65
	.db $24, $62
	.db $30, $62
	.db $24, $62
	.db $30, $66
	.db $30, $02
	.db $27, $62
	.db $33, $62
	.db $27, $62
	.db $33, $62
	.db $29, $62
	.db $35, $62
	.db $29, $62
	.db $35, $62
	.db $2B, $62
	.db $37, $62
	.db $2B, $62
	.db $37, $62
	.db $29, $62
	.db $35, $62
	.db $29, $62
	.db $35, $62
	.db $26, $66
	.db $23, $64
	.db $22, $68
	.db $30, $04
	.db $26, $68
	.db $24, $68
	.db $26, $66
	.db $23, $64
	.db $2B, $68
	.db $30, $04
	.db $2C, $68
	.db $2B, $68
	.db $22, $68
	.db $24, $68
	.db $26, $67
	.db $27, $64
	.db $2B, $68
	.db $27, $67
	.db $24, $64
	.db $24, $67
	.db $2B, $64
	.db $24, $62
	.db $22, $62
	.db $24, $62
	.db $29, $62
	.db $27, $62
	.db $29, $62
	.db $2B, $62
	.db $2E, $62
	.db $30, $62
	.db $2E, $62
	.db $30, $62
	.db $35, $62
	.db $33, $62
	.db $35, $62
	.db $37, $62
	.db $3A, $62
	.db $65
SongMacro0A:
	.db $63, $04
	.db $0F, $90
	.db $63, $04
	.db $15, $72
	.db $15, $80
	.db $15, $82
	.db $15, $82
	.db $63, $04
	.db $11, $A2
	.db $63, $04
	.db $15, $72
	.db $15, $82
	.db $63, $04
	.db $0F, $92
	.db $63, $04
	.db $0F, $92
	.db $63, $04
	.db $0F, $92
	.db $63, $04
	.db $15, $74
	.db $63, $04
	.db $11, $A2
	.db $63, $04
	.db $15, $72
	.db $15, $84
	.db $63, $04
	.db $0F, $90
	.db $63, $04
	.db $15, $72
	.db $15, $80
	.db $15, $80
	.db $15, $82
	.db $15, $80
	.db $63, $04
	.db $11, $A2
	.db $63, $04
	.db $15, $72
	.db $15, $82
	.db $63, $04
	.db $0F, $92
	.db $63, $04
	.db $0F, $92
	.db $63, $04
	.db $0F, $94
	.db $63, $04
	.db $15, $72
	.db $63, $04
	.db $11, $A4
	.db $63, $04
	.db $15, $74
	.db $65
	
StreetA:
	.db $68, 252
	.db $64, $0B, 12, 1
	.db $66, 1
	.db $62
	.dw StreetA
StreetB:
	.db $64, $0C, 0, 3
	.db $64, $0C, -2, 1
	.db $64, $0C, 5, 1
	.db $64, $0C, 3, 1
	.db $64, $0C, 1, 1
	.db $64, $0C, -5, 1
	.db $64, $0C, 0, 1
	.db $64, $0C, -2, 1
	.db $64, $0C, -4, 1
	.db $64, $0C, -5, 1
	.db $64, $0C, 0, 1
	.db $64, $0C, -2, 1
	.db $64, $0C, 5, 1
	.db $64, $0C, 3, 1
	.db $64, $0C, 1, 1
	.db $64, $0C, -5, 1
	.db $64, $0C, 0, 2
	.db $64, $0C, 5, 1
	.db $64, $0C, 1, 1
	.db $64, $0C, 3, 1
	.db $64, $0C, 0, 1
	.db $64, $0C, 1, 1
	.db $64, $0C, -2, 1
	.db $64, $0C, 0, 2
	.db $64, $0C, 5, 1
	.db $64, $0C, 1, 1
	.db $64, $0C, 3, 1
	.db $64, $0C, 0, 1
	.db $64, $0C, 1, 1
	.db $64, $0C, -5, 1
	.db $64, $0C, 0, 2
	.db $62
	.dw StreetB
StreetC:
	.db $64, $0D, 0, 3
	.db $64, $0D, 7, 1
	.db $64, $0D, 5, 1
	.db $64, $0D, 0, 1
	.db $64, $0F, 1, 1
	.db $64, $0F, 7, 1
	.db $64, $0D, 0, 1
	.db $64, $0D, 7, 1
	.db $64, $0F, 8, 1
	.db $64, $0F, 7, 1
	.db $64, $0D, 0, 1
	.db $64, $0D, 7, 1
	.db $64, $0D, 5, 1
	.db $64, $0D, 0, 1
	.db $64, $0F, 1, 1
	.db $64, $0F, 7, 1
	.db $64, $0D, 0, 2
	.db $64, $0D, 5, 1
	.db $64, $0F, 1, 1
	.db $64, $0F, 3, 1
	.db $64, $0D, 0, 1
	.db $64, $0F, 1, 1
	.db $64, $0D, -2, 1
	.db $64, $0F, 0, 2
	.db $64, $0D, 5, 1
	.db $64, $0F, 1, 1
	.db $64, $0F, 3, 1
	.db $64, $0D, 0, 1
	.db $64, $0F, 1, 1
	.db $64, $0F, 7, 1
	.db $64, $0D, 0, 2
	.db $62
	.dw StreetC
StreetD:
	.db $64, $0E, 0, 1
	.db $62
	.dw StreetD
SongMacro0B:
	.db $30, $0A
	.db $30, $0A
	.db $2B, $D6
	.db $2C, $D4
	.db $29, $D8
	.db $30, $04
	.db $2B, $D6
	.db $2C, $D4
	.db $29, $D7
	.db $29, $D2
	.db $2B, $D2
	.db $2C, $D2
	.db $2E, $D2
	.db $30, $D6
	.db $31, $D4
	.db $2E, $D8
	.db $30, $04
	.db $30, $D6
	.db $31, $D4
	.db $2E, $D8
	.db $30, $04
	.db $2E, $D6
	.db $2C, $D4
	.db $2A, $D6
	.db $29, $D4
	.db $2A, $D4
	.db $29, $D4
	.db $28, $D6
	.db $2B, $D4
	.db $2E, $D4
	.db $31, $D6
	.db $30, $D4
	.db $2E, $D4
	.db $2C, $D6
	.db $29, $D7
	.db $2B, $D4
	.db $2C, $D4
	.db $2B, $D9
	.db $29, $D4
	.db $2B, $D6
	.db $29, $D6
	.db $29, $D6
	.db $2B, $D4
	.db $2C, $D4
	.db $2E, $D6
	.db $30, $DA
	.db $2B, $D6
	.db $2C, $D4
	.db $29, $D8
	.db $30, $04
	.db $2B, $D6
	.db $2C, $D4
	.db $29, $D7
	.db $29, $D2
	.db $2B, $D2
	.db $2C, $D2
	.db $2E, $D2
	.db $30, $D6
	.db $31, $D4
	.db $2E, $D8
	.db $30, $04
	.db $30, $D6
	.db $31, $D4
	.db $2E, $D8
	.db $30, $04
	.db $2E, $D6
	.db $2C, $D4
	.db $2A, $D6
	.db $29, $D6
	.db $28, $D6
	.db $2B, $D4
	.db $2E, $D4
	.db $31, $D6
	.db $30, $D4
	.db $2E, $D6
	.db $2C, $D6
	.db $29, $D6
	.db $29, $D4
	.db $27, $04
	.db $29, $D4
	.db $29, $DA
	.db $30, $04
	.db $31, $D4
	.db $30, $D4
	.db $31, $D4
	.db $2E, $D7
	.db $30, $D4
	.db $31, $D4
	.db $31, $D4
	.db $30, $D4
	.db $31, $D4
	.db $2E, $D6
	.db $30, $D4
	.db $31, $D6
	.db $33, $D4
	.db $31, $D4
	.db $33, $D4
	.db $30, $D7
	.db $30, $D4
	.db $2E, $D4
	.db $2C, $D4
	.db $2E, $D4
	.db $30, $D4
	.db $30, $D7
	.db $31, $D6
	.db $31, $D4
	.db $30, $D4
	.db $2E, $D4
	.db $2A, $D8
	.db $30, $04
	.db $31, $D4
	.db $30, $D4
	.db $2E, $D4
	.db $2E, $D6
	.db $30, $D4
	.db $31, $D4
	.db $30, $DA
	.db $30, $04
	.db $30, $06
	.db $2D, $D6
	.db $29, $D4
	.db $2B, $D4
	.db $2D, $D2
	.db $2E, $D2
	.db $30, $D4
	.db $31, $D4
	.db $30, $D4
	.db $31, $D4
	.db $2E, $D8
	.db $30, $04
	.db $31, $D4
	.db $30, $D4
	.db $31, $D4
	.db $2E, $D6
	.db $30, $D4
	.db $31, $D6
	.db $30, $D4
	.db $2E, $D4
	.db $30, $D4
	.db $30, $D6
	.db $31, $D4
	.db $33, $D6
	.db $35, $D8
	.db $30, $04
	.db $33, $D4
	.db $31, $D6
	.db $31, $D6
	.db $30, $D4
	.db $2E, $D6
	.db $2C, $D4
	.db $2B, $D4
	.db $29, $D4
	.db $28, $D6
	.db $2B, $D6
	.db $2E, $D6
	.db $2C, $D4
	.db $2B, $D4
	.db $29, $DC
	.db $65
SongMacro0C:
	.db $11, $16
	.db $1D, $14
	.db $11, $16
	.db $11, $14
	.db $1D, $14
	.db $11, $14
	.db $65
SongMacro0D:
	.db $29, $B4
	.db $29, $B2
	.db $29, $B2
	.db $29, $B4
	.db $29, $B2
	.db $29, $B2
	.db $29, $B4
	.db $29, $B2
	.db $29, $B2
	.db $29, $B4
	.db $29, $B2
	.db $29, $B2
	.db $65
SongMacro0F:
	.db $29, $C4
	.db $29, $C2
	.db $29, $C2
	.db $29, $C4
	.db $29, $C2
	.db $29, $C2
	.db $29, $C4
	.db $29, $C2
	.db $29, $C2
	.db $29, $C4
	.db $29, $C2
	.db $29, $C2
	.db $65
SongMacro0E:
	.db $63, $04
	.db $0F, $92
	.db $63, $04
	.db $15, $72
	.db $15, $72
	.db $15, $72
	.db $63, $04
	.db $11, $A2
	.db $63, $04
	.db $15, $72
	.db $15, $72
	.db $63, $04
	.db $0F, $92
	.db $0F, $92
	.db $63, $04
	.db $15, $72
	.db $63, $04
	.db $0F, $92
	.db $63, $04
	.db $15, $72
	.db $63, $04
	.db $11, $A2
	.db $63, $04
	.db $15, $72
	.db $15, $72
	.db $15, $72
	.db $65
	
GameOverA:
	.db $68, 252
	.db $2C, $D6
	.db $2C, $D4
	.db $2C, $D4
	.db $2B, $D6
	.db $27, $D4
	.db $2B, $D4
	.db $2C, $DA
	.db $66, 1
	.db $61
GameOverB:
	.db $11, $16
	.db $11, $14
	.db $11, $14
	.db $0F, $16
	.db $0C, $14
	.db $0F, $14
	.db $11, $3A
	.db $61
GameOverC:
	.db $20, $66
	.db $20, $64
	.db $20, $64
	.db $1F, $66
	.db $1B, $64
	.db $1F, $64
	.db $20, $6A
	.db $61
GameOverD:
	.db $61
	
CompleteA:
	.db $68, 252
	.db $30, $D4
	.db $34, $D4
	.db $37, $D4
	.db $3C, $D4
	.db $39, $D4
	.db $35, $D4
	.db $30, $D4
	.db $2D, $D4
	.db $2B, $D4
	.db $2F, $D4
	.db $32, $D4
	.db $37, $D4
	.db $30, $D4
	.db $34, $D4
	.db $37, $D4
	.db $3C, $D4
	.db $30, $D8
	.db $66, $01
	.db $61
CompleteB:
	.db $0C, $16
	.db $0C, $14
	.db $0C, $14
	.db $11, $16
	.db $11, $14
	.db $11, $14
	.db $13, $16
	.db $13, $14
	.db $13, $14
	.db $0C, $3A
	.db $61
CompleteC:
	.db $24, $C6
	.db $24, $C4
	.db $24, $C4
	.db $29, $C6
	.db $29, $C4
	.db $29, $C4
	.db $2B, $C6
	.db $2B, $C4
	.db $2B, $C4
	.db $24, $C6
	.db $24, $C4
	.db $24, $C4
	.db $18, $D8
	.db $61
CompleteD:
	.db $61
	
BangA:
	.db $68, 252
	.db $64, $10, 0, 1
	.db $66, 1
	.db $62
	.dw BangA
BangB:
	.db $64, $11, 0, 1
	.db $62
	.dw BangB
BangC:
	.db $64, $12, 0, 1
	.db $62
	.dw BangC
BangD:
	.db $64, $13, 0, 1
	.db $62
	.dw BangD
SongMacro10:
	.db $30, $0A
	.db $30, $0A
	.db $24, $FA
	.db $27, $FA
	.db $22, $FA
	.db $24, $FA
	.db $24, $FA
	.db $27, $FA
	.db $22, $FA
	.db $24, $FA
	.db $29, $F9
	.db $30, $04
	.db $2B, $F4
	.db $2C, $F9
	.db $30, $04
	.db $30, $F4
	.db $2E, $F5
	.db $2B, $F8
	.db $30, $05
	.db $2E, $F4
	.db $2C, $F4
	.db $29, $F9
	.db $30, $04
	.db $30, $FA
	.db $33, $F9
	.db $30, $02
	.db $32, $F2
	.db $30, $F4
	.db $2E, $F9
	.db $30, $04
	.db $2B, $F4
	.db $2C, $FA
	.db $30, $FA
	.db $33, $F9
	.db $30, $04
	.db $30, $F4
	.db $2E, $F4
	.db $2B, $F9
	.db $2E, $F4
	.db $2C, $F4
	.db $29, $F9
	.db $30, $04
	.db $29, $FA
	.db $30, $F9
	.db $2E, $F4
	.db $2C, $F4
	.db $2B, $FA
	.db $29, $FA
	.db $2C, $FA
	.db $2E, $FA
	.db $30, $FA
	.db $32, $FA
	.db $30, $FC
	.db $65
SongMacro12:
	.db $30, $0A
	.db $30, $0A
	.db $20, $FA
	.db $24, $FA
	.db $1F, $FA
	.db $20, $FA
	.db $20, $FA
	.db $24, $FA
	.db $1F, $FA
	.db $20, $FA
	.db $24, $F9
	.db $30, $04
	.db $27, $F4
	.db $27, $F9
	.db $30, $04
	.db $2C, $F4
	.db $2B, $F5
	.db $27, $F8
	.db $30, $05
	.db $2B, $F4
	.db $29, $F4
	.db $24, $F9
	.db $30, $04
	.db $2C, $FA
	.db $30, $F9
	.db $30, $02
	.db $2E, $F2
	.db $2C, $F4
	.db $2B, $F9
	.db $30, $04
	.db $27, $F4
	.db $29, $FA
	.db $2C, $FA
	.db $30, $F9
	.db $30, $04
	.db $2C, $F4
	.db $2B, $F4
	.db $27, $F9
	.db $2B, $F4
	.db $29, $F4
	.db $24, $F9
	.db $30, $04
	.db $24, $FA
	.db $2C, $F9
	.db $2B, $F4
	.db $29, $F4
	.db $27, $FA
	.db $24, $FA
	.db $29, $FA
	.db $2B, $FA
	.db $2C, $FA
	.db $2E, $FA
	.db $28, $FC
	.db $65
SongMacro11:
	.db $11, $14
	.db $11, $14
	.db $11, $12
	.db $0F, $12
	.db $0C, $12
	.db $11, $14
	.db $11, $14
	.db $11, $12
	.db $11, $12
	.db $0F, $12
	.db $0C, $12
	.db $0F, $12
	.db $11, $14
	.db $11, $14
	.db $11, $12
	.db $0F, $12
	.db $0C, $12
	.db $11, $14
	.db $11, $14
	.db $11, $12
	.db $11, $12
	.db $0F, $12
	.db $0C, $12
	.db $0F, $12
	.db $11, $15
	.db $11, $14
	.db $11, $12
	.db $0F, $12
	.db $0C, $12
	.db $11, $14
	.db $11, $14
	.db $11, $12
	.db $0F, $12
	.db $0C, $12
	.db $0F, $12
	.db $14, $15
	.db $14, $14
	.db $11, $12
	.db $0F, $12
	.db $11, $12
	.db $14, $15
	.db $14, $14
	.db $11, $12
	.db $14, $12
	.db $11, $12
	.db $0F, $15
	.db $0F, $14
	.db $13, $12
	.db $16, $12
	.db $13, $12
	.db $0F, $15
	.db $0F, $14
	.db $13, $12
	.db $16, $12
	.db $13, $12
	.db $11, $15
	.db $11, $14
	.db $0F, $12
	.db $0C, $12
	.db $0F, $12
	.db $11, $15
	.db $11, $14
	.db $0F, $12
	.db $0C, $12
	.db $0F, $12
	.db $11, $15
	.db $11, $14
	.db $0F, $12
	.db $0C, $12
	.db $0F, $12
	.db $11, $15
	.db $11, $14
	.db $0F, $12
	.db $0C, $12
	.db $0F, $12
	.db $14, $15
	.db $14, $14
	.db $11, $12
	.db $0F, $12
	.db $11, $12
	.db $14, $15
	.db $14, $14
	.db $11, $12
	.db $14, $12
	.db $11, $12
	.db $0F, $15
	.db $0F, $14
	.db $13, $12
	.db $16, $12
	.db $13, $12
	.db $0F, $15
	.db $0F, $14
	.db $13, $12
	.db $16, $12
	.db $13, $12
	.db $11, $15
	.db $11, $14
	.db $14, $12
	.db $18, $12
	.db $14, $12
	.db $11, $15
	.db $11, $12
	.db $14, $14
	.db $18, $14
	.db $11, $15
	.db $11, $14
	.db $0F, $12
	.db $0C, $12
	.db $0F, $12
	.db $11, $15
	.db $11, $14
	.db $0F, $12
	.db $11, $12
	.db $0F, $12
	.db $14, $15
	.db $14, $14
	.db $14, $12
	.db $11, $12
	.db $0F, $12
	.db $14, $15
	.db $14, $14
	.db $14, $12
	.db $11, $12
	.db $14, $12
	.db $0F, $16
	.db $30, $02
	.db $13, $12
	.db $16, $12
	.db $13, $12
	.db $0F, $15
	.db $13, $14
	.db $16, $12
	.db $13, $12
	.db $16, $12
	.db $11, $15
	.db $11, $14
	.db $0F, $12
	.db $0C, $12
	.db $0F, $12
	.db $11, $15
	.db $11, $14
	.db $0F, $12
	.db $0C, $12
	.db $0F, $12
	.db $11, $15
	.db $11, $14
	.db $0F, $12
	.db $0C, $12
	.db $0F, $12
	.db $11, $15
	.db $11, $14
	.db $0F, $12
	.db $0C, $12
	.db $0F, $12
	.db $14, $15
	.db $14, $14
	.db $11, $12
	.db $0F, $12
	.db $11, $12
	.db $14, $15
	.db $14, $14
	.db $11, $12
	.db $14, $12
	.db $11, $12
	.db $0F, $15
	.db $13, $14
	.db $16, $12
	.db $13, $12
	.db $16, $12
	.db $0F, $15
	.db $13, $14
	.db $16, $12
	.db $13, $12
	.db $16, $12
	.db $11, $15
	.db $14, $14
	.db $18, $12
	.db $14, $12
	.db $11, $12
	.db $11, $14
	.db $11, $14
	.db $11, $12
	.db $0F, $12
	.db $0C, $12
	.db $0F, $12
	.db $11, $15
	.db $11, $14
	.db $0F, $12
	.db $0C, $12
	.db $0F, $12
	.db $11, $15
	.db $11, $14
	.db $0F, $12
	.db $0C, $12
	.db $0F, $12
	.db $14, $15
	.db $14, $14
	.db $11, $12
	.db $0F, $12
	.db $11, $12
	.db $14, $15
	.db $14, $14
	.db $11, $12
	.db $14, $12
	.db $11, $12
	.db $0F, $15
	.db $13, $14
	.db $16, $12
	.db $13, $12
	.db $16, $12
	.db $0F, $15
	.db $13, $14
	.db $16, $12
	.db $13, $12
	.db $16, $12
	.db $11, $16
	.db $30, $02
	.db $14, $12
	.db $18, $12
	.db $14, $12
	.db $11, $15
	.db $11, $14
	.db $0F, $12
	.db $0C, $12
	.db $0F, $12
	.db $11, $15
	.db $11, $14
	.db $0F, $12
	.db $0C, $12
	.db $0F, $12
	.db $11, $15
	.db $11, $14
	.db $0F, $12
	.db $0C, $12
	.db $0F, $12
	.db $14, $15
	.db $14, $14
	.db $11, $12
	.db $0F, $12
	.db $11, $12
	.db $14, $15
	.db $14, $12
	.db $11, $14
	.db $14, $14
	.db $0F, $14
	.db $0F, $14
	.db $0F, $12
	.db $13, $12
	.db $16, $12
	.db $13, $14
	.db $0F, $12
	.db $13, $12
	.db $16, $12
	.db $13, $12
	.db $16, $12
	.db $13, $12
	.db $16, $12
	.db $11, $14
	.db $11, $14
	.db $11, $12
	.db $0F, $12
	.db $0C, $12
	.db $11, $14
	.db $11, $14
	.db $11, $12
	.db $0F, $12
	.db $0C, $12
	.db $0F, $14
	.db $11, $14
	.db $11, $14
	.db $11, $12
	.db $0F, $12
	.db $0C, $12
	.db $11, $12
	.db $0D, $12
	.db $11, $14
	.db $11, $12
	.db $0F, $12
	.db $0C, $12
	.db $11, $14
	.db $0F, $14
	.db $0F, $14
	.db $0F, $12
	.db $13, $12
	.db $16, $12
	.db $0F, $14
	.db $0F, $14
	.db $0F, $12
	.db $13, $12
	.db $16, $12
	.db $13, $12
	.db $18, $12
	.db $14, $14
	.db $14, $14
	.db $14, $12
	.db $18, $12
	.db $1B, $12
	.db $14, $14
	.db $14, $14
	.db $14, $12
	.db $11, $12
	.db $0F, $12
	.db $11, $12
	.db $14, $12
	.db $16, $14
	.db $16, $14
	.db $16, $12
	.db $13, $12
	.db $11, $12
	.db $16, $14
	.db $16, $14
	.db $16, $12
	.db $13, $12
	.db $11, $12
	.db $13, $12
	.db $16, $12
	.db $18, $14
	.db $18, $14
	.db $18, $12
	.db $16, $12
	.db $13, $12
	.db $11, $14
	.db $13, $14
	.db $13, $12
	.db $13, $14
	.db $10, $14
	.db $0C, $14
	.db $0C, $14
	.db $0C, $12
	.db $10, $12
	.db $13, $12
	.db $0C, $14
	.db $0C, $14
	.db $0C, $12
	.db $10, $12
	.db $13, $12
	.db $10, $14
	.db $65
SongMacro13:
	.db $63, $04
	.db $0F, $92
	.db $63, $04
	.db $15, $72
	.db $15, $72
	.db $15, $72
	.db $63, $04
	.db $11, $A2
	.db $63, $04
	.db $15, $72
	.db $15, $72
	.db $63, $04
	.db $0F, $92
	.db $0F, $92
	.db $63, $04
	.db $15, $72
	.db $63, $04
	.db $0F, $92
	.db $63, $04
	.db $15, $72
	.db $63, $04
	.db $11, $A2
	.db $63, $04
	.db $15, $72
	.db $15, $72
	.db $15, $72
	.db $65

SilenceA:
SilenceB:
SilenceC:
SilenceD:
	.db $0F, $0A
	.db $61

MacroTab:
	.dw SongMacro00
	.dw SongMacro01
	.dw SongMacro02
	.dw SongMacro03
	.dw SongMacro04
	.dw SongMacro05
	.dw SongMacro06
	.dw SongMacro07
	.dw SongMacro08
	.dw SongMacro09
	.dw SongMacro0A
	.dw SongMacro0B
	.dw SongMacro0C
	.dw SongMacro0D
	.dw SongMacro0E
	.dw SongMacro0F
	.dw SongMacro10
	.dw SongMacro11
	.dw SongMacro12
	.dw SongMacro13

.enum $D064 export
MusicSwitch db
SFXSwitch db
.ende

.enum $DF00 export
;$RAM values
C1PlayFlag db
C1Delay db
C1Pos dw
C1InsAdd db
C1EnvSeqDelay db
C1EnvSeqPtr dw
C1VibSeqDelay db
C1VibSeqPtr dw
C1ModSeqDelay db
C1ModSeqPtr dw
C1ModSeqRestart dw
C1Note db
C1MacroTrans db
C1MacroTimesLeft db
C1MacroRet dw
Unk15 db
C1Freq dw
C1Vol db
NoteLens dw
C2PlayFlag db
C2Delay db
C2Pos dw
C2InsAdd db
C2EnvSeqDelay db
C2EnvSeqPtr dw
C2VibSeqDelay db
C2VibSeqPtr dw
C2ModSeqDelay db
C2ModSeqPtr dw
C2ModSeqRestart dw
C2Note db
C2MacroTrans db
C2MacroTimesLeft db
C2MacroRet dw
Unk30 db
C2Freq dw
C2Vol db
Unk34 db
Unk35 db
C3PlayFlag db
C3Delay db
C3Pos dw
C3InsAdd db
C3EnvSeqDelay db
C3EnvSeqPtr dw
C3VibSeqDelay db
C3VibSeqPtr dw
C3ModSeqDelay db
C3ModSeqPtr dw
C3ModSeqRestart dw
C3Note db
C3MacroTrans db
C3MacroTimesLeft db
C3MacroRet dw
Unk4B db
C3Freq dw
C3Vol db
Unk4F db
Unk50 db
C4PlayFlag db
C4Delay db
C4Pos dw
C4InsAdd db
C4EnvSeqDelay db
C4EnvSeqPtr dw
C4VibSeqDelay db
C4VibSeqPtr dw
C4ModSeqDelay db
C4ModSeqPtr dw
C4ModSeqRestart dw
C4Note db
C4MacroTrans db
C4MacroTimesLeft db
C4MacroRet dw
Unk66 db
C4Noise db
Unk68 db
C4Vol db
Unk6A db
Unk6B db
C1SFXDelay db
C1SFXPos dw
C1SFXFreq dw
C1SFXVol db
C2SFXDelay db
C2SFXPos dw
C2SFXFreq dw
C2SFXVol db
C3SFXDelay db
C3SFXPos dw
C3SFXFreq dw
C3SFXVol db
C4SFXDelay db
C4SFXPos dw
C4SFXNoise db
C4SFXVol db
ModVal db
Tempo db
BeatCounter db
LoopFlag db
PrevNoise db
MusicPlayFlag db
Unk89 db
Unk8A db
Unk8B db
Unk8C db
Unk8D db
Unk8E db
Unk8F db
.ende