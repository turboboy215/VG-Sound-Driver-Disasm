;Monster Traveler audio disassembly - bank 1
;Disassembly by Will Trowbridge & Claude

;The engine lives in bank $C0, but every song table entry names the ROM bank its
;channel data is stored in - banks $C0 through $C5 are all used. Each sequence
;byte is fetched through GetSeqByte in ROM0, which maps that bank in, reads the
;byte and maps bank $C0 back in. The data banks are in MTB.ASM - MTF.ASM.

include "HARDWARE.INC"

def AudioROM equ $4000
def AudioBank1 equ $C0
def AudioBank2 equ $C1
def AudioBank3 equ $C2
def AudioBank4 equ $C3
def AudioBank5 equ $C4
def AudioBank6 equ $C5
def PlayerBank1 equ $01
def PlayerBank2 equ $02
def PlayerBank3 equ $03
def PlayerBank4 equ $04
def PlayerBank5 equ $05
def PlayerBank6 equ $06
def BankOffset equ AudioBank1 - PlayerBank1
def AudioRAM equ $DE00
def WaveRAM equ $FF30
def TrackRAMSize equ $2C

def MusC1RAM equ $DE00
def MusC2RAM equ $DE2C
def MusC3RAM equ $DE58
def MusC4RAM equ $DE84
def SFXC1RAM equ $DEB0
def SFXC2RAM equ $DEDC
def SFXC3RAM equ $DF20
def SFXC4RAM equ $DF4C

;GetSeqByte lives in ROM0 and is stubbed in FUNCTION.ASM

SECTION "Audio 1", ROMX[AudioROM], BANK[PlayerBank1]

;Silence every channel and clear the hardware register shadows.
;Channels whose length counters are still running are left alone -
;rNR52 is polled to see which ones are still on.
AudioOff:
	;Clear master volume and panning
	xor a
	ldh [rNR50], a
	ldh [rNR51], a
	ld [NR51Val], a	
	;Turn on audio
	ld a, %10000000
	ldh [rNR52], a
	
.AudioOffCh1
	;Reset channel 1 sweep
	ld a, 0
	ldh [rNR10], a
	ld [NR10Val], a
	;Check if channel 1 is on
	ldh a, [rNR52]
	bit 0, a
	jr z, .AudioOffCh2
	;If on, then clear channel 1 registers
	xor a
	ldh [rNR11], a
	ld [NR11Val], a
	ld a, 8
	ldh [rNR12], a
	ld [NR12Val], a
	xor a
	ldh [rNR13], a
	ld [NR13Val], a
	ld [NR14Val], a
	ld a, %10000000
	ldh [rNR14], a
	xor a

.AudioOffCh2
	;Check if channel 2 is on
	ldh a, [rNR52]
	bit 1, a
	jr z, .AudioOffCh3
	;If on, then clear channel 2 registers
	xor a
	ldh [rNR21], a
	ld [NR21Val], a
	ldh [rNR22], a
	ld [NR22Val], a
	ldh [rNR23], a
	ld [NR23Val], a
	ld [NR24Val], a
	ld a, %10000000
	ldh [rNR24], a

.AudioOffCh3
	;Clear channel 3 registers
	xor a
	ldh [rNR32], a
	ld [NR32Val], a
	ld [NR34Val], a
	ld a, %10000000
	ldh [rNR34], a
	;Check if channel 4 is on
	ldh a, [rNR52]
	bit 3, a
	jr z, .AudioOffRet
	;If on, then clear channel 4 registers
	xor a
	ldh [rNR41], a
	ld [NR41Val], a
	ld a, %00001000
	ldh [rNR42], a
	ld [NR42Val], a
	xor a
	ldh [rNR43], a
	ld [NR43Val], a
	ld [NR44Val], a
	ld a, %10000000
	ldh [rNR44], a

.AudioOffRet
	ret

;Start a sound effect. The song table index is passed in SFXNum.
;Everything below is shared with LoadSong.
CallSFX:
	ld a, [SFXNum]
	jr LoadSong2

;Start a song. The song table index is passed in MusNum.
;
;A song table entry is a channel mask, a priority, the ROM bank its
;channel data is stored in, and one sequence pointer per set mask bit.
;Mask bit 0 is music channel 1 and bit 7 is sound effect channel 4, so
;music entries use mask $0F and sound effects use $10/$30/$80/$90.
LoadSong:
	ld a, [MusNum]

LoadSong2:
	;Get song number from RAM variable
	ld [SongNum], a
	;Get pointer from song table
	push bc
	push de
	push de
	ld d, 0
	ld e, a
	ld hl, SongTab
	add hl, de
	add hl, de
	pop de
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	;Load header values into RAM
	xor a
	ld [CurTrack], a
	ld a, [hl+]
	ld [ChanMask], a					;Byte 1 = Channel mask
	ld a, [hl+]
	ld [Priority], a					;Byte 2 = priority
	ld a, [hl+]
	ld [SongBank], a					;Byte 3 = bank
	ld b, h
	ld c, l
	ld a, [CurTrack]

GetTracks:
	;Get track RAM from pointer table
	add a
	add LOW(TrackRAMPtrs)
	ld l, a
	ld a, HIGH(TrackRAMPtrs)
	adc 0
	ld h, a
	ld a, [hl+]
	ld e, a
	ld d, [hl]
	
	;Check if each track (SFX 4-1, then music 4-1) is present
	ld hl, ChanMask
	srl [hl]
	
	;If track present
	jr c, .InitTrackRAM
	
	;When finished
	jr z, .LoadSongRet

.NextTrack
	;Advance channel
	ld hl, CurTrack
	inc [hl]
	;Get next track RAM pointer
	ld a, [hl]
	jr GetTracks

.LoadSongRet
	;Return from routine
	pop de
	pop bc
	ret

.InitTrackRAM
	;Get song number
	ld hl, $00                         ;MusNum
	add hl, de
	ld a, [hl+]
	or a
	jr z, .InitTrackRAM2
	
	;If not below priority, then don't play channel
	ld a, [Priority]
	cp [hl]
	jr nc, .InitTrackRAM2
	inc bc
	inc bc
	jr .NextTrack

.InitTrackRAM2
	;Get pointer from current song
	ld hl, $1E
	add hl, de
	ld a, [bc]
	ld [hl+], a
	inc bc
	ld a, [bc]
	ld [hl], a
	inc bc
	;Add current channel mask to tracks used value
	ld a, [CurTrack]
	add LOW(TrackMaskVals)
	ld l, a
	ld a, HIGH(TrackMaskVals)
	adc 0
	ld h, a
	ld a, [TracksUsed]
	or [hl]
	ld [TracksUsed], a
	;Copy SFX number value to channel music number
	ld h, d
	ld l, e
	ld a, [SongNum]
	ld [hl+], a
	;Get priority value and copy to channel location
	ld a, [Priority]
	ld [hl+], a
	;Set sweep value
	ld a, 0
	ld [hl+], a
	;Set transpose and tuning to 0
	xor a
	ld [hl+], a
	ld [hl+], a
	;Set panning
	ld a, %00000011
	ld [hl+], a
	ld [hl+], a
	;Set gate and note delay
	ld a, 0
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	;Set note speed to 1
	inc a
	ld [hl+], a
	;Set data bank
	ld hl, $2B
	add hl, de
	ld a, [SongBank]
	ld [hl], a
	;Set vibrato sequence pointer
	xor a
	ld hl, $0F
	add hl, de
	ld [hl+], a
	ld [hl], a
	;Set volume delay
	ld a, $FF
	ld hl, $16
	add hl, de
	ld [hl], a
	;Set volume value 
	ld a, [CurTrack]
	add LOW(EnvValInit)
	ld l, a
	ld a, HIGH(EnvValInit)
	adc 0
	ld h, a
	ld a, [hl]
	ld hl, $1D
	add hl, de
	ld [hl], a
	;Go to next track
	jr .NextTrack

;Reset both volume levels to maximum. Called by the game, not by the
;engine itself.
InitVolume:
	ld a, 7
	ld [MusVolume], a
	ld [SFXVolume], a
	ret

;Run one frame of audio. Every track is stepped in turn, then the whole
;set of shadow registers is written out at once by OutputTracks.
PlayAudio:
	;Check all tracks to see if they are playing
	xor a
	ld hl, CurTrackCheck
	ld [hl], a

CheckTrack:
	;Get current channel RAM
	add a
	add LOW(TrackRAMPtrs)
	ld l, a
	ld a, HIGH(TrackRAMPtrs)
	adc 0
	ld h, a
	ld a, [hl+]
	ld e, a
	ld d, [hl]
	call ProcTrack
	
	;If not done checking all 8 tracks, then check next track
	ld hl, CurTrackCheck
	inc [hl]
	ld a, [hl]
	cp 8	
	;Also get playing status for each music channel
	jr c, CheckTrack
	ld hl, MusC1MusNum
	ld a, [hl]
	ld hl, MusC2MusNum
	or [hl]
	ld hl, MusC3MusNum
	or [hl]
	ld hl, MusC4MusNum
	or [hl]
	ld [MusPlaying], a
	jp OutputTracks

;Step one track. DE points at the track's RAM block.
;
;A track that is not playing anything returns immediately. Otherwise the
;gate counter (how long the note sounds) and then the step counter (how
;long until the next command) are counted down; when the step counter
;reaches zero the next command is read. The sequence bank is copied to
;SeqBank first so GetSeqByte knows which bank to map in.
ProcTrack:

	;Check if the track is playing anything
	ld hl, $00                         ;MusNum
	add hl, de
	ld a, [hl]
	or a
	;If not, then return
	ret z
	
	;Get current bank
	ld hl, $2B                         ;DataBank
	add hl, de
	ld a, [hl]
	ld [SeqBank], a

.ProcTrack2
	;Check if gate has reached 0
	ld hl, $07                         ;Gate
	add hl, de
	ld a, [hl+]
	or [hl]
	;If so, then skip to note delay
	jr z, .ProcTrack4
	;Otherwise, decrement gate
	dec hl
	ld a, [hl]
	dec a
	cp $FF
	ld [hl+], a
	jr nz, .ProcTrack3
	dec [hl]

.ProcTrack3
	jr .ProcTrack7

.ProcTrack4
	;Reset flag
	ld hl, $2A                         ;Flags
	add hl, de
	res 0, [hl]
	;Check if delay has reached 0
	ld hl, $09                         ;NoteDelay
	add hl, de
	ld a, [hl+]
	or [hl]
	;If so, then get the next command
	jr z, .ProcTrack6
	;Otherwise, decrement delay
	dec hl
	ld a, [hl]
	dec a
	cp $FF
	ld [hl+], a
	jr nz, .ProcTrack5
	dec [hl]

.ProcTrack5
	jr .ProcTrack7

.ProcTrack6
	;Get the next command
	call NextCommand
	;Then check if channel is still playing
	ld a, [de]
	or a
	;If not, then return
	jr z, .ProcTrackRet
	;Otherwise, keep going
	jr .ProcTrack2

.ProcTrack7
	;Process envelope and vibrato sequences and output frequency
	call ProcEnvSeq
	call ProcVibSeq
	call CalcFreqOut

.ProcTrackRet
	ret

;Restart this track's envelope sequence from the beginning.
ResetEnvSeq:
	xor a
	ld hl, $16                         ;EnvDelay
	add hl, de
	ld [hl], a
	ld hl, $14                         ;EnvSeqPos
	add hl, de
	ld [hl], a
	ret

;Step the envelope sequence. The sequence is a list of delay/value pairs
;that are written to the channel's NRx2 register; $FE restarts the
;sequence at its loop point and $FF holds the last value forever.
ProcEnvSeq:
	;Is the delay RAM value FF (end)?
	ld hl, $16                         ;EnvDelay
	add hl, de
	ld a, [hl]
	cp $FF
	;If so, then return
	ret z
	;Otherwise, check if delay is 0
	cp 0
	;If so, then keep going
	jr z, .ProcEnvSeq2
	;Otherwise, decrement delay
	dec a
	ld [hl], a
	ret

.ProcEnvSeq2
	;Get next delay or command value from sequence - next byte
	push bc
	ld hl, $11                         ;EnvSeqPtr
	add hl, de
	ld a, [hl+]
	ld c, a
	ld b, [hl]
	ld hl, $14                         ;EnvSeqPos
	add hl, de
	ld l, [hl]
	ld h, 0
	;Add values to get absolute pointer
	add hl, bc
	ld c, l
	ld b, h
	;Get delay/command value
	call GetSeqByte
	;If FF, then end
	cp $FF
	jr z, .ProcEnvStop
	;If FE, then restart
	cp $FE
	jr z, .ProcEnvLoop
	;Otherwise, is delay - now get envelope
	ld hl, $16                         ;EnvDelay
	add hl, de
	ld [hl], a
	inc bc
	;Get envelope value
	call GetSeqByte
	ld hl, $1D                         ;EnvVal
	add hl, de
	ld [hl], a
	;Set flag value
	ld hl, $2A                         ;Flags
	add hl, de
	set 4, [hl]
	;Increment pointer
	ld hl, $14                         ;EnvSeqPos
	add hl, de
	inc [hl]
	inc [hl]
	pop bc
	ret

.ProcEnvStop
	;Set delay value to FF - end
	pop bc
	ld hl, $16                         ;EnvDelay
	add hl, de
	ld [hl], a
	ret

.ProcEnvLoop
	;Check bit 0 of flags
	pop bc
	ld hl, $2A                         ;Flags
	add hl, de
	bit 0, [hl]
	;If set, then return
	ret nz
	;Otherwise, increase position
	ld hl, $14                         ;EnvSeqPos
	add hl, de
	inc [hl]
	jr .ProcEnvSeq2

;Start this track's vibrato sequence. The first byte of a vibrato sequence
;is the delay before the first step, so it is read here; the delay and
;value pairs that follow start at offset 1.
;A track with no vibrato sequence parks VibDelay at $FF.
StartVibSeq:
	;Set vibrato value to 0
	push bc
	xor a
	ld hl, $18                         ;VibVal
	add hl, de
	ld [hl], a
	;Get pointer for vibrato sequence
	ld hl, $0F                         ;VibSeqPtr
	add hl, de
	ld a, [hl+]
	ld c, a
	ld b, [hl]
	;If no vibrato sequence, then end
	or b
	jr z, SeqEnd
	;Otherwise, get next byte from sequence
	call GetSeqByte
	ld hl, $15                         ;VibDelay
	add hl, de
	ld [hl], a
	;Set position to 1
	ld a, 1
	ld hl, $13                         ;VibSeqPos
	add hl, de
	ld [hl], a
	pop bc
	ret

SeqEnd:
	;Set delay value to FF - end
	ld hl, $15                         ;VibDelay
	add hl, de
	ld a, $FF
	ld [hl], a
	pop bc
	ret

;Step the vibrato sequence. Each pair is a delay and a signed offset that
;is added to the note's frequency; $FF loops back to offset 1.
ProcVibSeq:
	;Get vibrato delay
	ld hl, $15                         ;VibDelay
	add hl, de
	ld a, [hl]
	;If 0, then continue sequence
	cp 0
	jr z, .ProcVibratoSeq2
	;Otherwise, decrement delay
	dec a
	ld [hl], a
	ret

.ProcVibratoSeq2
	;Get next delay or command value from sequence - next byte
	push bc
	ld hl, $0F                         ;VibSeqPtr
	add hl, de
	ld a, [hl+]
	ld c, a
	ld b, [hl]
	or b
	jr z, SeqEnd
	ld hl, $13                         ;VibSeqPos
	add hl, de
	ld l, [hl]
	ld h, 0
	;Add values to get absolute pointer
	add hl, bc
	ld c, l
	ld b, h
	call GetSeqByte
	;If FF, then loop
	cp $FF
	jr z, .ProcVibratoLoop
	;Otherwise, get delay and then value from next 2 bytes
	ld hl, $15                         ;VibDelay
	add hl, de
	ld [hl], a
	inc bc
	call GetSeqByte
	ld hl, $18                         ;VibVal
	add hl, de
	ld [hl], a
	;Increment position by 2
	ld hl, $13                         ;VibSeqPos
	add hl, de
	inc [hl]
	inc [hl]
	pop bc
	ret

.ProcVibratoLoop
	;Reset step to 1
	pop bc
	ld hl, $13                         ;VibSeqPos
	add hl, de
	ld a, 1
	ld [hl], a
	jr .ProcVibratoSeq2

;FreqOut = Freq + VibVal + Tuning, sign extending the 8-bit offset.
CalcFreqOut:
	;Get frequency value
	push bc
	ld hl, $1B                         ;Freq
	add hl, de
	ld a, [hl+]
	ld c, a
	ld b, [hl]
	;Add vibrato to frequency
	ld hl, $18                         ;VibVal
	add hl, de
	ld a, [hl]
	;Also add tuning
	ld hl, $04                         ;Tuning
	add hl, de
	add [hl]
	ld l, a
	ld h, 0
	;If negative, then decrease
	bit 7, l
	jr z, .CalcFreqOut2
	dec h

.CalcFreqOut2
	;Load value to output frequency
	add hl, bc
	push hl
	ld hl, $19                         ;FreqOut
	add hl, de
	pop bc
	ld a, c
	ld [hl+], a
	ld [hl], b
	pop bc
	ret

;Read and act on commands until one of them produces a note.
;
;$00-$7F are notes ($00 is a rest), $80-$9F are voice commands and $FF
;ends the track. Unlike the earlier games in this family every note is
;followed by two lengths - the gate time and the step time - each of
;which is one byte, or two when bit 7 of the first byte is set.
NextCommand:
	;Get channel pointer
	ld hl, $1E                         ;SongPos
	add hl, de
	ld a, [hl+]
	ld c, a
	ld b, [hl]

.NextCommand2
	;Get next byte from channel pointer
	call GetSeqByte
	;Increment pointer
	inc bc
	;Load current command into RAM variable
	ld [CurCommand], a
	cp $80
	;If less than 80, is a note or rest
	jr c, .NoteOrRest
	;Otherwise, is parameters or VCMD
	call DoVCMD
	;Check if music is playing
	ld hl, $00                         ;MusNum
	add hl, de
	ld a, [hl]
	cp 0
	;If so, then keep going and get next command
	jr nz, .NextCommand2
	ret

.NoteOrRest
	;Set bit
	ld hl, $2A                         ;Flags
	add hl, de
	ld [hl], %00100000
	;Check if track is 3 (music 4)
	ld a, [CurTrackCheck]
	cp 3
	;If so, then perform special handler
	jr z, ProcNoteMusCh4
	
	;Get next panning value
	call NextPan
	;Check if track is SFX 4
	cp 7
	jr z, ProcNoteSFXCh4
	;Otherwise...
	jr ProcNote

ProcNoteMusCh4:
	;Get lower 6 bits of note
	ld a, [CurCommand]
	and %00111111
	;Get percussion pointer from table using note value
	push bc
	add LOW(PercSongIDs)
	ld c, a
	ld a, HIGH(PercSongIDs)
	adc 0
	ld b, a
	ld a, [bc]
	;If 0, then is a rest
	or a
	jr z, .ProcNoteMusCh4
	;Otherwise, set SFX number and play SFX
	ld [SFXNum], a
	push de
	push hl
	call CallSFX
	pop hl
	pop de

.ProcNoteMusCh4
	pop bc
	jr ProcNote2

ProcNoteSFXCh4:
	;Load byte value into frequency in RAM
	ld hl, $1B                         ;Freq
	add hl, de
	ld a, [CurCommand]
	ld [hl+], a
	xor a
	ld [hl], a
	jr ProcNote2

ProcNote:
	;Get note/rest byte
	ld a, [CurCommand]
	;If 0, then is a rest
	or a
	jr z, ProcNote2
	;Otherwise, get frequency + transpose
	push bc
	ld hl, $03                         ;Transpose
	add hl, de
	add [hl]
	;Add frequency from table
	add a
	add LOW(FreqTab)
	ld c, a
	ld a, HIGH(FreqTab)
	adc 0
	ld b, a
	;Load final frequency value in RAM
	ld hl, $1B                         ;Freq
	add hl, de
	ld a, [bc]
	ld [hl+], a
	inc bc
	ld a, [bc]
	ld [hl], a
	pop bc

ProcNote2:
	;Get channel speed value and load into RAM
	ld hl, $0B                         ;Speed
	add hl, de
	ld a, [hl]
	ld [CurSpeed], a
	;Get length value from next 1-2 bytes
	call GetLength
	;Scale note value
	call ScaleLength
	;Load length value in gate
	ld hl, $07                         ;Gate
	add hl, de
	ld a, [LengthVal]
	ld [hl+], a
	ld a, [LengthVal+1]
	ld [hl-], a
	;If 0, then set new envelope
	or [hl]
	jr z, .ProcNoteEnv
	;Otherwise, set bit in flag
	ld hl, $2A                         ;Flags
	add hl, de
	set 0, [hl]
	;Reset envelope 
	call ResetEnvSeq
	;Start vibrato sequence
	call StartVibSeq
	jr .ProcNoteLen

.ProcNoteEnv
	;Load envelope value from table
	ld a, [CurTrackCheck]
	add LOW(EnvValDefault)
	ld l, a
	ld a, HIGH(EnvValDefault)
	adc 0
	ld h, a
	ld a, [hl]
	;Load into RAM
	ld hl, $1D                         ;EnvVal
	add hl, de
	ld [hl], a
	;Set bit in flag
	ld hl, $2A                         ;Flags
	add hl, de
	set 4, [hl]

.ProcNoteLen
	;Get length from next 1-2 bytes
	call GetLength
	;Scale note value
	call ScaleLength
	;Load into RAM
	ld hl, $09                         ;NoteDelay
	add hl, de
	ld a, [LengthVal]
	ld [hl+], a
	ld a, [LengthVal+1]
	ld [hl], a
	;Save postive value
	call SaveSongPos
	ret

;Read a note length. One byte if bit 7 is clear, otherwise a 15 bit
;value built from the low seven bits of this byte and the next one.
;Returns the length in HL.
GetLength:
	;Get length from next byte
	ld l, 0
	ld h, l
	call GetSeqByte
	inc bc
	;If bit 1 is set, then length is 15-bit - use lower 7 bits + next byte
	bit 7, a
	jr z, .GetLength2
	and %01111111
	ld h, a
	call GetSeqByte
	inc bc
	sla a
	srl h
	rr a

.GetLength2
	ld l, a
	ret

;Advance the panning for the next note. With PanMode zero the panning
;alternates between left and right, otherwise it is left as it is.
NextPan:
	;Get pan mode value
	push af
	ld hl, $05                         ;PanMode
	add hl, de
	ld a, [hl+]
	;If 0, then alternate between left and right
	or a
	jr nz, .NextPan3
	ld a, [hl]
	;If not full, then alternate between 1 and 2
	cp 3
	jr nz, .NextPan2
	ld a, 1

.NextPan2
	;Invert value
	xor %00000011

.NextPan3
	;Mask out unneccessary bits
	and %00000011
	ld [hl], a
	pop af
	ret

;Save BC back into the track's sequence pointer.
SaveSongPos:
	ld hl, $1E                         ;SongPos
	add hl, de
	ld [hl], c
	inc l
	ld [hl], b
	ret

;Multiply the length in HL by Speed and store it in LengthVal.
ScaleLength:
	push bc
	ld a, [CurSpeed]
	and %00001111
	jr z, .ScaleLength3
	ld c, l
	ld b, h

.ScaleLength2
	dec a
	jr z, .ScaleLength3
	add hl, bc
	jr .ScaleLength2

.ScaleLength3
	ld a, l
	ld [LengthVal], a
	ld a, h
	ld [LengthVal+1], a
	pop bc
	ret

;Dispatch a voice command through VCMDTab. $FF is handled separately
;because it is outside the table.
DoVCMD:
	cp $FF
	jp z, EventEndTrack
	sub $80
	add a
	add LOW(VCMDTab)
	ld l, a
	ld a, HIGH(VCMDTab)
	adc 0
	ld h, a
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	jp hl

;Voice command jump table, $80-$9F. Commands the engine does not
;implement point at EventSkip.
VCMDTab:
	dw EventUnused0D                  ;$80
	dw EventTranspose                 ;$81
	dw EventDutyVol                   ;$82
	dw EventTuning                    ;$83
	dw EventPanMode                   ;$84
	dw EventDuty                      ;$85
	dw EventSkip                      ;$86
	dw EventSpeed                     ;$87
	dw EventSweep                     ;$88
	dw EventSweepOff                  ;$89
	dw EventSkip                      ;$8A
	dw EventSkip                      ;$8B
	dw EventVibSeq                    ;$8C
	dw EventSkip                      ;$8D
	dw EventEnvSeq                    ;$8E
	dw EventSkip                      ;$8F
	dw EventSkip                      ;$90
	dw EventSkip                      ;$91
	dw EventMacro1                    ;$92
	dw EventMacro1End                 ;$93
	dw EventSkip                      ;$94
	dw EventRepeat1                   ;$95
	dw EventRepeat1End                ;$96
	dw EventSkip                      ;$97
	dw EventSkip                      ;$98
	dw EventSkip                      ;$99
	dw EventEndTrack                  ;$9A
	dw EventMacro2                    ;$9B
	dw EventMacro2End                 ;$9C
	dw EventRepeat2                   ;$9D
	dw EventRepeat2End                ;$9E
	dw EventEndTrack                  ;$9F

;$85 - duty cycle, or the noise mode on sound effect channel 4.
;The pulse channels keep the duty in the top two bits of DutyVol; on
;the wave channel this field is the waveform number instead.
;Parameters: xxxxxxxx (x = value)
EventDuty:
	ld a, [CurTrackCheck]
	cp 7
	jr z, .EventDutySFX4
	call GetSeqByte
	and %00110011
	add a
	add a
	ld hl, $0C                         ;DutyVol
	add hl, de
	jr LoadValToRAM

.EventDutySFX4
	call GetSeqByte
	or a
	jr z, .EventDutySFX4_2
	ld a, 8

.EventDutySFX4_2
	ld hl, $0C                         ;DutyVol
	add hl, de
	jr LoadValToRAM

;$80 - stores a byte that nothing in the engine ever reads back.
;Parameters: xxxxxxxx (x = value)
EventUnused0D:
	ld hl, $0D                         ;Unused0D
	add hl, de
	call GetSeqByte


;Load value to RAM
LoadValToRAM:
	ld [hl], a

;Skip one parameter byte. Every command the engine does not implement
;points here, and so does the tail of the repeat commands.
;Parameters: xxxxxxxx (x = value)
EventSkip:
	inc bc
	ret

;$88 - frequency sweep (rNR10), clearing the top bit.
;Parameters: xxxxxxxx (x = value)
EventSweep:
	ld hl, $02                         ;Sweep
	add hl, de
	call GetSeqByte
	and %01111111
	ld [hl], a
	inc bc
	ret

;$89 - turn the frequency sweep off.
EventSweepOff:
	ld hl, $02                         ;Sweep
	add hl, de
	ld a, 0
	ld [hl], a
	ret

;$8C - set the vibrato sequence pointer.
;Parameters: xxxxxxxx xxxxxxxx (x = pointer)
EventVibSeq:
	call GetSeqByte
	ld hl, $0F                         ;VibSeqPtr
	add hl, de
	ld [hl+], a
	inc bc
	call GetSeqByte
	ld [hl], a
	inc bc
	ret

;$81 - transpose, added to every note number before the frequency
;table is indexed.
;Parameters: xxxxxxxx (x = value, signed)
EventTranspose:
	ld hl, $03                         ;Transpose
	add hl, de
	call GetSeqByte
	ld [hl], a
	inc bc
	ret

;$82 - duty cycle and volume, or the waveform number on channel 3.
;Parameters: xxxxxxxx (x = value)
EventDutyVol:
	ld hl, $0C                         ;DutyVol
	add hl, de
	call GetSeqByte
	ld [hl], a
	inc bc
	ret

;$8E - set the envelope sequence pointer.
;Parameters: xxxxxxxx xxxxxxxx (x = pointer)
EventEnvSeq:
	call GetSeqByte
	ld hl, $11                         ;EnvSeqPtr
	add hl, de
	ld [hl+], a
	inc bc
	call GetSeqByte
	ld [hl], a
	inc bc
	ret

;$83 - fine tuning, added to the frequency.
;Parameters: xxxxxxxx (x = value, signed)
EventTuning:
	ld hl, $04                         ;Tuning
	add hl, de
	call GetSeqByte
	ld [hl], a
	inc bc
	ret

;$84 - panning mode.
;Parameters: xxxxxxxx (x = value)
EventPanMode:
	ld hl, $05                         ;PanMode
	add hl, de
	call GetSeqByte
	and %00000011
	ld [hl], a
	inc bc
	ret

;$87 - note length multiplier.
;Parameters: ----xxxx (- = unused, x = value)
EventSpeed:
	ld hl, $0B                         ;Speed
	add hl, de
	call GetSeqByte
	and %00001111
	ld [hl], a
	inc bc
	ret

;$92 - call macro 1. The return address is kept per track, so a macro
;cannot call another macro at the same level.
;Parameters: xxxxxxxx xxxxxxxx (x = pointer)
EventMacro1:
	call GetSeqByte
	ld l, a
	inc bc
	call GetSeqByte
	ld h, a
	inc bc
	push hl
	ld hl, $24                         ;Macro1Pos
	add hl, de
	ld [hl], c
	inc l
	ld [hl], b
	pop bc
	ret

;$9B - call macro 2.
;Parameters: xxxxxxxx xxxxxxxx (x = pointer)
EventMacro2:
	call GetSeqByte
	ld l, a
	inc bc
	call GetSeqByte
	ld h, a
	inc bc
	push hl
	ld hl, $26                         ;Macro2Pos
	add hl, de
	ld [hl], c
	inc l
	ld [hl], b
	pop bc
	ret

;$93 - return from macro 1.
EventMacro1End:
	ld hl, $24                         ;Macro1Pos
	add hl, de
	ld a, [hl+]
	ld b, [hl]
	ld c, a
	ret

;$9C - return from macro 2.
EventMacro2End:
	ld hl, $26                         ;Macro2Pos
	add hl, de
	ld a, [hl+]
	ld b, [hl]
	ld c, a
	ret

;$95 - mark the start of repeat 1.
EventRepeat1:
	ld hl, $20                         ;Repeat1Start
	add hl, de
	ld a, c
	ld [hl+], a
	ld [hl], b
	ld hl, $28                         ;Repeat1Times
	add hl, de
	ld [hl], 0
	ret

;$9D - mark the start of repeat 2.
EventRepeat2:
	ld hl, $22                         ;Repeat2Start
	add hl, de
	ld a, c
	ld [hl+], a
	ld [hl], b
	ld hl, $29                         ;Repeat2Times
	add hl, de
	ld [hl], 0
	ret

;$96 - end of repeat 1. The parameter is the number of times to repeat;
;zero repeats forever, which is how songs loop.
;Parameters: xxxxxxxx (x = times to repeat, 0 = infinite)
EventRepeat1End:
	call GetSeqByte
	;If 0, then endless repeat
	or a
	jr z, .EventRepeat1End2
	ld hl, $28                         ;Repeat1Times
	add hl, de
	push hl
	ld h, [hl]
	cp h
	pop hl
	jr z, RepeatEnd3
	inc [hl]

.EventRepeat1End2
	ld hl, $20                         ;Repeat1Start
	add hl, de
	ld a, [hl+]
	ld c, a
	ld b, [hl]
	ret

RepeatEnd3:
	ld [hl], 0
	jp EventSkip

;$9E - end of repeat 2.
;Parameters: xxxxxxxx (x = times to repeat, 0 = infinite)
EventRepeat2End:
	call GetSeqByte
	;If 0, then endless repeat
	or a
	jr z, .EventRepeat2End2
	ld hl, $29                         ;Repeat2Times
	add hl, de
	push hl
	ld h, [hl]
	cp h
	pop hl
	jr z, RepeatEnd3
	inc [hl]

.EventRepeat2End2
	ld hl, $22                         ;Repeat2Start
	add hl, de
	ld a, [hl+]
	ld c, a
	ld b, [hl]
	ret

;$9A/$9F/$FF - end of track. The track is released, its bit is cleared
;from TracksUsed and the channel is left silent.
EventEndTrack:
	;Set music number to 0 - unused
	ld hl, $00                         ;MusNum
	add hl, de
	ld a, 0
	ld [hl], a
	;Get tracks used flag
	ld a, [CurTrackCheck]
	add LOW(ChanMaskVals)
	ld c, a
	ld a, HIGH(ChanMaskVals)
	adc 0
	ld b, a
	ld a, [bc]
	ld hl, TracksUsed
	and [hl]
	ld [hl], a
	ld a, [CurTrackCheck]
	add LOW(EnvValInit)
	ld l, a
	ld a, HIGH(EnvValInit)
	adc 0
	ld h, a
	ld a, [hl]
	;Set envelope value to it
	ld hl, $1D                         ;EnvVal
	add hl, de
	ld [hl], a
	;Set flag bit
	ld hl, $2A                         ;Flags
	add hl, de
	set 5, [hl]
	;Clear variables
	xor a
	ld h, d
	ld l, e
	ld [hl+], a
	ld [hl+], a
	ld [hl], a
	;If track is 4 (SFX 1), then reset sweep
	ld a, [CurTrackCheck]
	cp 4
	ret nz
	ld a, 0
	ldh [rNR10], a
	ld [NR10Val], a
	ret

;Default rNRx2 value for each track when a song starts.
EnvValInit:
	db $08, $08, $00, $08, $08, $08, $00, $08
	db $08

;rNRx2 value for a note that has no envelope sequence.
EnvValDefault:
	db $08, $08, $00, $08, $08, $08, $00, $08
	db $08

;AND masks used to clear one track's bit out of TracksUsed.
ChanMaskVals:
	db $FE, $FD, $FB, $F7, $EF, $DF, $BF, $7F

;Wave channel output levels.
Vol3LUT:
	db $00, $60, $60, $60, $60, $60, $40, $40
	db $40, $40, $40, $20, $20, $20, $20, $20

;rNR51 masks and values for each channel. The first byte of each group
;clears the channel's bits and the other three are right, left and
;both.
Chan1PanTab:
	db $EE, $01, $10, $11

Chan2PanTab:
	db $DD, $02, $20, $22

Chan3PanTab:
	db $BB, $04, $40, $44

Chan4PanTab:
	db $77, $08, $80, $88

;Write every channel out to the hardware.
;
;Each channel takes its values from the sound effect track if one is
;playing and from the music track otherwise, so a sound effect simply
;takes the channel over for as long as it lasts. C walks along the
;channel's register block while the helpers below write one register
;each and step C past registers they do not touch.
OutputTracks:
	;Channel 1
	ld c, $10
	;If SFX is not playing, then output music
	ld de, SFXC1MusNum
	ld a, [de]
	or a
	jr nz, .OutputTracksCh1
	ld de, MusC1MusNum

.OutputTracksCh1
	;Set track check variable
	ld a, 0
	ld [CurTrackCheck], a
	;Output Ch1 registers
	call OutPanning
	call OutSweep
	call OutDuty
	call OutVol
	call OutFreqLo
	call OutFreqHi
	
	;Channel 2
	ld c, $16
	;If SFX is not playing, then output music
	ld de, SFXC2MusNum
	ld a, [de]
	or a
	jr nz, .OutputTracksCh2
	ld de, MusC2MusNum

.OutputTracksCh2
	;Set track check variable
	ld a, 1
	ld [CurTrackCheck], a
	;Output Ch2 registers
	call OutPanning
	call OutDuty
	call OutVol
	call OutFreqLo
	call OutFreqHi
	
	;Channel 3
	ld c, $1A
	;If SFX is not playing, then output music
	ld de, SFXC3MusNum
	ld a, [de]
	or a
	jr nz, .OutputTracksCh3
	ld de, MusC3MusNum

.OutputTracksCh3
	;Set track check variable
	ld a, 2
	ld [CurTrackCheck], a
	;Output Ch3 registers
	call OutPanning
	call OutWaveOn
	call SkipReg
	call OutVol
	ld c, $1D
	call OutFreqLo
	call OutFreqHi
	
	;Channel 4
	ld c, $20
	ld de, SFXC4MusNum
	ld a, 3
	ld [CurTrackCheck], a
	;Output Ch4 registers
	call OutPanning
	call SkipReg
	call OutVol
	call OutFreqLo
	call OutFreqHi
	
.OutputVol
	ld hl, $FF24
	ld a, %01110111
	cp [hl]
	;If not maximum volume, then set volume to maximum
	jr z, .OutputPan
	ld [hl], a

.OutputPan
	;Set pan value from tracks used value
	ld hl, $FF25
	ld a, [TracksUsed]
	and %11110111
	ld b, a
	swap b
	or b
	ld b, a
	ld a, [NR51Val]
	and b
	cp [hl]
	;If pan is different, then set value
	jr z, .OutputMasterCtrl
	ld [hl], a

.OutputMasterCtrl
	;Combine track control flags
	ld hl, MusC1Flags
	ld a, [hl]
	and %11001111
	ld [hl], a
	ld hl, MusC2Flags
	ld a, [hl]
	and %11001111
	ld [hl], a
	ld hl, MusC3Flags
	ld a, [hl]
	and %11001111
	ld [hl], a
	ld hl, MusC4Flags
	ld a, [hl]
	and %11001111
	ld [hl], a
	ld hl, SFXC1Flags
	ld a, [hl]
	and %11001111
	ld [hl], a
	ld hl, SFXC2Flags
	ld a, [hl]
	and %11001111
	ld [hl], a
	ld hl, SFXC3Flags
	ld a, [hl]
	and %11001111
	ld [hl], a
	ld hl, SFXC4Flags
	ld a, [hl]
	and %11001111
	ld [hl], a
	;Load waveform as well
	call LoadWaveMus
	;Check if channel 3 is on
	ldh a, [rNR52]
	and %00000100
	;If not, return
	ret nz
	;Otherwise, set channel 3 trigger bit on
	ldh a, [rNR34]
	or %10000000
	ldh [rNR34], a
	ret

;Merge this channel's panning into the rNR51 shadow.
OutPanning:
	;Get pan value from RAM
	ld hl, $06                         ;Panning
	add hl, de
	ld a, [hl]
	and %00000011
	ld [hl], a
	;If 0, then set to max
	jr nz, .OutPanning2
	ld [hl], %00000011

.OutPanning2
	;Get track's pan
	ld a, [CurTrackCheck]
	sla a
	sla a
	ld b, a
	add LOW(Chan1PanTab)
	ld l, a
	ld a, HIGH(Chan1PanTab)
	adc 0
	ld h, a
	ld a, [NR51Val]
	and [hl]
	push af
	;Get pan RAM variable
	ld a, b
	ld hl, $06                         ;Panning
	add hl, de
	add [hl]
	add LOW(Chan1PanTab)
	ld l, a
	ld a, HIGH(Chan1PanTab)
	adc 0
	ld h, a
	pop af
	;Combine the values for NR51
	or [hl]
	ld [NR51Val], a
	ret

;Turn the wave channel on (rNR30).
OutWaveOn:
	ld a, $80
	ldh [c], a

;Step past a register this channel does not use.
SkipReg:
	inc c
	ret

;rNR10 - frequency sweep.
OutSweep:
	;Check if flags bit is set
	ld hl, $2A                         ;Flags
	add hl, de
	bit 5, [hl]
	;If so, then get sweep
	jr z, .OutSweep3
	ld hl, $02                         ;Sweep
	add hl, de
	ld a, [hl]
	;If 0, then set direction to subtract
	cp 0
	jr nz, .OutSweep2
	ld a, %00001000

.OutSweep2
	ldh [c], a

.OutSweep3
	inc c
	ret

;rNRx1 - duty cycle.
OutDuty:
	;Check bit of flag
	ld hl, $2A                         ;Flags
	add hl, de
	bit 5, [hl]
	;If set, then get duty volume
	jr z, .OnDuty2
	ld hl, $0C                         ;DutyVol
	add hl, de
	ld a, [hl]
	jr .OnDuty3

.OnDuty2
	ld hl, $0C                         ;DutyVol
	add hl, de
	ld a, [hl]
	swap a

.OnDuty3
	;Mask out other bits to only get duty
	and %11000000
	;Output value
	ldh [c], a
	inc c
	ret

;rNRx2 - volume envelope.
OutVol:
	;Get volume envelope flag
	ld hl, $2A                         ;Flags
	add hl, de
	ld a, [hl]
	;Mask out volume
	and %00110000
	jr z, .OutVol2
	;If not 0, then output envelope value
	ld hl, $1D                         ;EnvVal
	add hl, de
	ld a, [hl]
	ldh [c], a

.OutVol2
	inc c
	ret

;rNRx3 - frequency, low byte.
OutFreqLo:
	;If bit flag set, then also get sweep
	ld hl, $2A                         ;Flags
	add hl, de
	ld a, [hl]
	and %00100000
	jr nz, .OutFreqLo2
	ld hl, $02                         ;Sweep
	add hl, de
	;If sweep is not 0, then return
	ld a, [hl]
	cp 0
	jr nz, .OutFreqLoRet

.OutFreqLo2
	;Output low frequency
	ld hl, $19                         ;FreqOut
	add hl, de
	ld a, [hl]
	ldh [c], a

.OutFreqLoRet
	inc c
	ret

;rNRx4 - frequency high byte, plus the retrigger bit.
OutFreqHi:
	;If bit flag set, then also get sweep
	ld hl, $2A                         ;Flags
	add hl, de
	ld a, [hl]
	and %00110000
	jr nz, .OutFreqHi2
	ld hl, $02                         ;Sweep
	add hl, de
	;If sweep is not 0, then return
	ld a, [hl]
	cp 0
	jr nz, .OutFreqHiRet
	ld a, 0
	jr .OutFreqHi3

.OutFreqHi2
	;Set trigger bit
	ld a, %10000000

.OutFreqHi3
	;Output high frequency
	ld hl, $1A                         ;FreqOut+1
	add hl, de
	or [hl]
	and %10111111
	ldh [c], a

.OutFreqHiRet
	inc c
	ret

;Copy the waveform the music channel 3 track asks for into wave RAM.
;Nothing is copied while the same waveform is already loaded.
LoadWaveMus:
	ld a, [MusC3DutyVol]
	jr LoadWave2

;As above, but for the sound effect channel 3 track.
LoadWaveSFX:
	ld a, [SFXC3DutyVol]

LoadWave2:
	;If wave is same, then return
	ld hl, CurWave
	cp [hl]
	ret z
	;Otherwise, set new wave
	ld [hl], a
	;Load wave from table
	add a
	add LOW(WaveTab)
	ld c, a
	ld a, HIGH(WaveTab)
	adc 0
	ld b, a
	ld a, [bc]
	ld l, a
	inc bc
	ld a, [bc]
	ld h, a
	ld c, $30
	xor a
	ldh [rNR30], a
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	;Set DAC on
	ld a, %10000000
	ldh [rNR30], a
	;Set trigger bit on
	ld a, [NR34Val]
	or %10000000
	ldh [rNR34], a
	ret

;Frequency for each note number. The last six entries are leftovers
;past the top of the hardware's range.
FreqTab:
	dw $002C
	dw $009D
	dw $0107
	dw $016B
	dw $01C9
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
	dw $053B
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
	dw $07DB
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
	dw $01DF
	dw $01E3
	dw $0243
	dw $0247
	dw $0243
	dw $0257

;Each track's RAM block.
TrackRAMPtrs:
	;Each track's RAM block - the blocks are not evenly spaced,
	;so the engine keeps a pointer table instead of scaling.
	dw MusC1MusNum
	dw MusC2MusNum
	dw MusC3MusNum
	dw MusC4MusNum
	dw SFXC1MusNum
	dw SFXC2MusNum
	dw SFXC3MusNum
	dw SFXC4MusNum

;Each track's bit in TracksUsed.
TrackMaskVals:
	db $01, $02, $04, $08, $10, $20, $40, $80

;Music channel 4 is a percussion track: each note number picks a sound
;effect out of this table and starts it instead of playing a note.
PercSongIDs:
	db $00, $01, $01, $01, $01, $01, $01, $01
	db $01, $01, $01, $01, $05, $01, $03, $01
	db $01, $01, $01, $01, $01, $01, $02, $01
	db $01, $06, $01, $01, $01, $01, $01, $01
	db $01, $06, $01, $01, $01, $01, $01, $01
	db $01, $01, $01, $01, $01, $01, $01, $01
	db $01, $01, $01, $01, $01, $01, $01, $01
	db $01, $01, $01, $01, $01, $01, $01, $01

;Song table. Every entry points at a header made up of a channel mask,
;a priority, the ROM bank its channel data lives in and one sequence
;pointer per set mask bit.
SongTab:
	dw SongNone00                ;$00
	dw SFX01                     ;$01
	dw SFX02                     ;$02
	dw SFX03                     ;$03
	dw SFX04                     ;$04
	dw SFX05                     ;$05
	dw SFX06                     ;$06
	dw SFX05                     ;$07
	dw SFX05                     ;$08
	dw SFX05                     ;$09
	dw SFX0A                     ;$0A
	dw SFX0B                     ;$0B
	dw SFX0C                     ;$0C
	dw SongNone00                ;$0D
	dw Mus0E                     ;$0E
	dw Mus0F                     ;$0F
	dw SFX10                     ;$10
	dw SFX11                     ;$11
	dw SFX12                     ;$12
	dw SFX13                     ;$13
	dw SFX14                     ;$14
	dw SFX15                     ;$15
	dw SFX16                     ;$16
	dw SFX17                     ;$17
	dw SFX18                     ;$18
	dw SFX19                     ;$19
	dw SFX13                     ;$1A
	dw SFX13                     ;$1B
	dw SFX13                     ;$1C
	dw SFX13                     ;$1D
	dw SFX13                     ;$1E
	dw SFX13                     ;$1F
	dw SFX20                     ;$20
	dw SFX21                     ;$21
	dw SFX22                     ;$22
	dw SFX23                     ;$23
	dw SFX24                     ;$24
	dw SFX25                     ;$25
	dw SFX26                     ;$26
	dw SFX27                     ;$27
	dw SFX28                     ;$28
	dw SFX29                     ;$29
	dw SFX2A                     ;$2A
	dw SFX2B                     ;$2B
	dw SFX2C                     ;$2C
	dw SFX2D                     ;$2D
	dw SFX2E                     ;$2E
	dw SFX2F                     ;$2F
	dw SFX30                     ;$30
	dw SFX31                     ;$31
	dw SFX32                     ;$32
	dw SFX33                     ;$33
	dw SFX34                     ;$34
	dw SFX35                     ;$35
	dw SFX36                     ;$36
	dw SFX37                     ;$37
	dw SFX38                     ;$38
	dw SFX39                     ;$39
	dw SFX3A                     ;$3A
	dw SFX3B                     ;$3B
	dw SFX3C                     ;$3C
	dw SFX3D                     ;$3D
	dw SFX3E                     ;$3E
	dw SFX3F                     ;$3F
	dw SFX40                     ;$40
	dw SFX41                     ;$41
	dw SFX42                     ;$42
	dw SFX43                     ;$43
	dw SFX44                     ;$44
	dw SFX45                     ;$45
	dw SFX46                     ;$46
	dw SFX47                     ;$47
	dw SFX48                     ;$48
	dw SFX49                     ;$49
	dw SFX4A                     ;$4A
	dw SFX4B                     ;$4B
	dw SFX4C                     ;$4C
	dw SFX4D                     ;$4D
	dw SFX4E                     ;$4E
	dw SFX4F                     ;$4F
	dw SFX50                     ;$50
	dw SFX51                     ;$51
	dw SFX52                     ;$52
	dw SFX53                     ;$53
	dw SFX54                     ;$54
	dw SFX55                     ;$55
	dw SFX56                     ;$56
	dw SFX57                     ;$57
	dw SFX58                     ;$58
	dw SFX59                     ;$59
	dw SFX5A                     ;$5A
	dw SFX5B                     ;$5B
	dw SFX5C                     ;$5C
	dw SFX5D                     ;$5D
	dw SFX5E                     ;$5E
	dw SFX13                     ;$5F
	dw Mus60                     ;$60
	dw Mus61                     ;$61
	dw Mus62                     ;$62
	dw Mus63                     ;$63
	dw Mus64                     ;$64
	dw Mus65                     ;$65
	dw Mus66                     ;$66
	dw Mus67                     ;$67
	dw Mus68                     ;$68
	dw Mus69                     ;$69
	dw Mus6A                     ;$6A
	dw Mus6B                     ;$6B
	dw Mus6C                     ;$6C
	dw Mus6D                     ;$6D
	dw Mus6E                     ;$6E
	dw Mus6F                     ;$6F
	dw Mus70                     ;$70
	dw Mus71                     ;$71
	dw Mus72                     ;$72
	dw Mus73                     ;$73
	dw Mus74                     ;$74
	dw Mus75                     ;$75
	dw Mus76                     ;$76
	dw Mus77                     ;$77
	dw Mus78                     ;$78
	dw Mus79                     ;$79
	dw Mus7A                     ;$7A
	dw Mus7B                     ;$7B
	dw Mus7C                     ;$7C
	dw Mus7D                     ;$7D
	dw SFX13                     ;$7E
	dw SFX13                     ;$7F
	dw SFX13                     ;$80
	dw SFX13                     ;$81
	dw SFX13                     ;$82
	dw SFX13                     ;$83
	dw SFX13                     ;$84
	dw SFX13                     ;$85
	dw SFX13                     ;$86
	dw SFX13                     ;$87
	dw SFX13                     ;$88
	dw SFX13                     ;$89
	dw SFX13                     ;$8A
	dw SFX13                     ;$8B
	dw SFX13                     ;$8C
	dw SFX13                     ;$8D
	dw SFX13                     ;$8E
	dw SFX13                     ;$8F

SongNone00:
SongNone0D:
	db %00000000		;Channel mask
	db 0				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw EmptyTrack

SFX01:
	db %10000000		;Channel mask
	db 0				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX01D

SFX02:
	db %10000000		;Channel mask
	db 0				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX02D

SFX03:
	db %10000000		;Channel mask
	db 0				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX03D

SFX04:
	db %10000000		;Channel mask
	db 0				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX04D

SFX05:
SFX07:
SFX08:
SFX09:
	db %10000000		;Channel mask
	db 0				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX05D

SFX06:
	db %10000000		;Channel mask
	db 0				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX06D

SFX10:
	db %00010000		;Channel mask
	db 14				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX10A

SFX11:
	db %00010000		;Channel mask
	db 14				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX11A

SFX12:
	db %00010000		;Channel mask
	db 14				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX12A

SFX13:
SFX1A:
SFX1B:
SFX1C:
SFX1D:
SFX1E:
SFX1F:
SFX5F:
SFX7E:
SFX7F:
SFX80:
SFX81:
SFX82:
SFX83:
SFX84:
SFX85:
SFX86:
SFX87:
SFX88:
SFX89:
SFX8A:
SFX8B:
SFX8C:
SFX8D:
SFX8E:
SFX8F:
	db %00010000		;Channel mask
	db 14				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX13A

SFX14:
	db %00010000		;Channel mask
	db 14				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX14A

SFX15:
	db %00010000		;Channel mask
	db 14				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX15A

SFX16:
	db %10010000		;Channel mask
	db 2				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX16A
	dw SFX16D

SFX17:
	db %00110000		;Channel mask
	db 14				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX17A
	dw SFX17B

SFX18:
	db %00010000		;Channel mask
	db 14				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX18A

SFX19:
	db %00010000		;Channel mask
	db 14				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX19A

SFX20:
	db %10000000		;Channel mask
	db 2				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX20D

SFX21:
	db %10000000		;Channel mask
	db 2				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX21D

SFX22:
	db %00010000		;Channel mask
	db 2				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX22A

SFX23:
	db %10000000		;Channel mask
	db 2				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX23D

SFX24:
	db %00010000		;Channel mask
	db 2				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX24A

SFX25:
	db %00010000		;Channel mask
	db 2				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX25A

SFX26:
	db %00010000		;Channel mask
	db 2				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX26A

SFX27:
	db %10000000		;Channel mask
	db 2				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX27D

SFX28:
	db %10000000		;Channel mask
	db 2				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX28D

SFX0C:
	db %10000000		;Channel mask
	db 2				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw EmptyTrack

SFX29:
	db %10000000		;Channel mask
	db 2				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX29D

SFX2A:
	db %10010000		;Channel mask
	db 2				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX2AA
	dw SFX2AD

SFX2B:
	db %00010000		;Channel mask
	db 2				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX2BA

SFX2C:
	db %00010000		;Channel mask
	db 2				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX2CA

SFX2D:
	db %10000000		;Channel mask
	db 6				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX2DD

SFX2E:
	db %10010000		;Channel mask
	db 6				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX2EA
	dw SFX2ED

SFX2F:
	db %10000000		;Channel mask
	db 6				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX2FD

SFX30:
	db %10010000		;Channel mask
	db 6				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX30A
	dw SFX30D

SFX31:
	db %10000000		;Channel mask
	db 6				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX31D

SFX32:
	db %10000000		;Channel mask
	db 6				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX32D

SFX33:
	db %10000000		;Channel mask
	db 6				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX33D

SFX34:
	db %10010000		;Channel mask
	db 6				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX34A
	dw SFX34D

SFX35:
	db %10010000		;Channel mask
	db 6				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX35A
	dw SFX35D

SFX36:
	db %00010000		;Channel mask
	db 6				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX36A

SFX37:
	db %10000000		;Channel mask
	db 6				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX37D

SFX38:
	db %10000000		;Channel mask
	db 6				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX38D

SFX39:
	db %00110000		;Channel mask
	db 6				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX39A
	dw SFX39B

SFX3A:
	db %10000000		;Channel mask
	db 6				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX3AD

SFX3B:
	db %10000000		;Channel mask
	db 6				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX3BD

SFX3C:
	db %10010000		;Channel mask
	db 6				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX3CA
	dw SFX3CD

SFX3D:
	db %00110000		;Channel mask
	db 6				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX3DA
	dw SFX3DB

SFX3E:
	db %00110000		;Channel mask
	db 6				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX3EA
	dw SFX3EB

SFX3F:
	db %10010000		;Channel mask
	db 6				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX3FA
	dw SFX3FD

SFX40:
	db %10010000		;Channel mask
	db 6				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX40A
	dw SFX40D

SFX0A:
	db %10010000		;Channel mask
	db 6				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw EmptyTrack
	dw EmptyTrack

SFX41:
	db %10000000		;Channel mask
	db 6				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX41D

SFX0B:
	db %10000000		;Channel mask
	db 6				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX0BD

SFX42:
	db %10000000		;Channel mask
	db 6				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX42D

SFX43:
	db %10000000		;Channel mask
	db 6				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX43D

SFX44:
	db %00010000		;Channel mask
	db 6				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX44A

SFX45:
	db %10000000		;Channel mask
	db 6				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX45D

SFX46:
	db %00010000		;Channel mask
	db 6				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX46A

SFX47:
	db %10010000		;Channel mask
	db 6				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX47A
	dw SFX47D

SFX48:
	db %00010000		;Channel mask
	db 6				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX48A

SFX49:
	db %10000000		;Channel mask
	db 6				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX49D

SFX4A:
	db %10010000		;Channel mask
	db 6				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX4AA
	dw SFX4AD

SFX4B:
	db %10010000		;Channel mask
	db 6				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX4BA
	dw SFX4BD

SFX4C:
	db %10010000		;Channel mask
	db 6				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX4CA
	dw SFX4CD

SFX4D:
	db %00010000		;Channel mask
	db 14				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX4DA

SFX4E:
	db %00010000		;Channel mask
	db 14				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX4EA

SFX4F:
	db %10000000		;Channel mask
	db 2				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX4FD

SFX50:
	db %00010000		;Channel mask
	db 14				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX50A

SFX51:
	db %00010000		;Channel mask
	db 14				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX51A

SFX52:
	db %00010000		;Channel mask
	db 2				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX52A

SFX53:
	db %00110000		;Channel mask
	db 2				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX53A
	dw SFX53B

SFX54:
	db %10010000		;Channel mask
	db 2				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX54A
	dw SFX54D

SFX55:
	db %10010000		;Channel mask
	db 2				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX55A
	dw SFX55D

SFX56:
	db %10010000		;Channel mask
	db 2				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX56A
	dw SFX56D

SFX57:
	db %10010000		;Channel mask
	db 2				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX57A
	dw SFX57D

SFX58:
	db %00010000		;Channel mask
	db 2				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX58A

SFX59:
	db %10000000		;Channel mask
	db 2				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX59D

SFX5A:
	db %00010000		;Channel mask
	db 2				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX5AA

SFX5B:
	db %10010000		;Channel mask
	db 14				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX5BA
	dw SFX5BD

SFX5C:
	db %00010000		;Channel mask
	db 14				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX5CA

SFX5D:
	db %00010000		;Channel mask
	db 14				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX5DA

SFX5E:
	db %10010000		;Channel mask
	db 2				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw SFX5EA
	dw SFX5ED

Mus0E:
	db %00001111		;Channel mask
	db 2				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw EmptyTrack
	dw EmptyTrack
	dw EmptyTrack
	dw EmptyTrack

Mus0F:
	db %11110000		;Channel mask
	db 15				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw EmptyTrack
	dw EmptyTrack
	dw EmptyTrack
	dw EmptyTrack

SFX10A:
	db $87, $01
	db $85, $11
	db $8E, $C8, $60
	db $28, $01, $00
	db $2B, $01, $00
	db $2F, $01, $00
	db $30, $01, $00
	db $8E, $A4, $60
	db $28, $01, $00
	db $2B, $01, $00
	db $2F, $01, $00
	db $30, $01, $00
	db $8E, $9E, $60
	db $28, $01, $00
	db $2B, $01, $00
	db $2F, $01, $00
	db $30, $01, $00
	db $FF

SFX11A:
	db $87, $02
	db $85, $11
	db $8E, $F2, $60
	db $34, $01, $00
	db $30, $01, $00
	db $2B, $01, $00
	db $8E, $BC, $60
	db $34, $01, $00
	db $30, $01, $00
	db $2B, $01, $00
	db $8E, $A4, $60
	db $34, $01, $00
	db $30, $01, $00
	db $2B, $01, $00
	db $FF

SFX12A:
	db $87, $02
	db $85, $11
	db $8E, $F2, $60
	db $81, $F4
	db $37, $01, $00
	db $31, $01, $00
	db $34, $01, $00
	db $2E, $01, $00
	db $31, $01, $00
	db $2B, $01, $00
	db $8E, $BC, $60
	db $37, $01, $00
	db $31, $01, $00
	db $34, $01, $00
	db $2E, $01, $00
	db $31, $01, $00
	db $2B, $01, $00
	db $8E, $A4, $60
	db $37, $01, $00
	db $31, $01, $00
	db $34, $01, $00
	db $2E, $01, $00
	db $31, $01, $00
	db $2B, $01, $00
	db $FF

SFX13A:
	db $87, $01
	db $85, $22
	db $8E, $F2, $60
	db $81, $02
	db $15, $01, $00
	db $1C, $01, $00
	db $8E, $A4, $60
	db $15, $01, $00
	db $1C, $01, $00
	db $15, $01, $00
	db $1C, $01, $00
	db $15, $01, $00
	db $1C, $01, $00
	db $FF

SFX14A:
	db $87, $01
	db $85, $11
	db $8E, $F2, $60
	db $1C, $03, $00
	db $21, $03, $00
	db $24, $03, $00
	db $28, $04, $00
	db $24, $03, $00
	db $28, $03, $00
	db $2B, $03, $00
	db $2F, $03, $00
	db $8E, $BC, $60
	db $85, $00
	db $24, $03, $00
	db $28, $03, $00
	db $2B, $03, $00
	db $2F, $03, $00
	db $8E, $A4, $60
	db $24, $03, $00
	db $28, $03, $00
	db $2B, $03, $00
	db $2F, $03, $00
	db $FF

SFX15A:
	db $87, $01
	db $85, $11
	db $8E, $F2, $60
	db $18, $03, $00
	db $1A, $03, $00
	db $1C, $03, $00
	db $1E, $05, $00
	db $1C, $03, $00
	db $1A, $03, $00
	db $18, $03, $00
	db $1C, $03, $00
	db $20, $03, $00
	db $8E, $C8, $60
	db $18, $03, $00
	db $1C, $03, $00
	db $20, $03, $00
	db $8E, $B0, $60
	db $18, $03, $00
	db $1C, $03, $00
	db $20, $03, $00
	db $8E, $A4, $60
	db $18, $03, $00
	db $1C, $03, $00
	db $20, $03, $00
	db $FF

VibSeq00:
	db $01
	db $01, $ED
	db $01, $F1
	db $01, $F5
	db $01, $F7
	db $01, $F9
	db $01, $FB
	db $01, $FD
	db $01, $FF
	db $01, $FD
	db $01, $FB
	db $01, $F7
	db $01, $FB
	db $01, $FD
	db $01, $FF
	db $01, $01
	db $01, $04
	db $01, $07
	db $71, $0A
	db $FF

EnvSeq00:
	db $20, $4F
	db $14, $72
	db $FF

SFX16A:
	db $87, $01
	db $85, $22
	db $8E, $72, $4D
	db $8C, $4C, $4D
	db $00, $00, $18
	db $84, $01
	db $41, $22, $1A
	db $84, $02
	db $3E, $22, $08
	db $FF

EnvSeq01:
	db $20, $3D
	db $40, $90
	db $20, $97
	db $FF

SFX16D:
	db $87, $01
	db $8E, $8F, $4D
	db $37, $7F, $30
	db $FF

SFX17B_1:
	db $85, $11
	db $21, $02, $00
	db $85, $22
	db $18, $02, $00
	db $1B, $02, $00
	db $1E, $02, $00
	db $93

SFX17A_1:
	db $85, $00
	db $21, $02, $00
	db $18, $02, $00
	db $1B, $02, $00
	db $1E, $02, $00
	db $93

SFX17A:
	db $83, $01
	db $87, $01
	db $85, $22
	db $81, $F8
	db $8E, $F2, $60
	db $92
	dw SFX17A_1
	db $8E, $E0, $60
	db $92
	dw SFX17A_1
	db $8E, $B6, $60
	db $92
	dw SFX17A_1
	db $8E, $C8, $60
	db $92
	dw SFX17A_1
	db $8E, $B6, $60
	db $92
	dw SFX17A_1
	db $8E, $A4, $60
	db $92
	dw SFX17A_1
	db $8E, $BC, $60
	db $92
	dw SFX17A_1
	db $8E, $AA, $60
	db $92
	dw SFX17A_1
	db $FF

SFX17B:
	db $87, $01
	db $85, $22
	db $81, $03
	db $8E, $F2, $60
	db $92
	dw SFX17B_1
	db $8E, $E0, $60
	db $92
	dw SFX17B_1
	db $8E, $B6, $60
	db $92
	dw SFX17B_1
	db $8E, $C8, $60
	db $92
	dw SFX17B_1
	db $8E, $B6, $60
	db $92
	dw SFX17B_1
	db $8E, $A4, $60
	db $92
	dw SFX17B_1
	db $8E, $BC, $60
	db $92
	dw SFX17B_1
	db $8E, $AA, $60
	db $92
	dw SFX17B_1
	db $8E, $9E, $60
	db $92
	dw SFX17B_1
	db $FF

EnvSeq02:
	db $01, $F3
	db $FF

SFX18A:
	db $87, $04
	db $85, $11
	db $8E, $35, $4E
	db $28, $01, $01
	db $24, $02, $02
	db $8E, $A4, $60
	db $24, $02, $02
	db $FF

SFX19A:
	db $87, $01
	db $85, $11
	db $8E, $F2, $60
	db $81, $07
	db $15, $01, $00
	db $1C, $01, $00
	db $15, $01, $00
	db $1C, $01, $00
	db $00, $00, $03
	db $15, $01, $00
	db $1C, $01, $00
	db $15, $01, $00
	db $1C, $01, $00
	db $15, $01, $00
	db $1C, $01, $00
	db $15, $01, $00
	db $1C, $01, $00
	db $15, $01, $00
	db $1C, $01, $00
	db $15, $01, $00
	db $1C, $01, $00
	db $15, $01, $00
	db $1C, $01, $00
	db $15, $01, $00
	db $1C, $01, $00
	db $15, $01, $00
	db $1C, $01, $00
	db $15, $01, $00
	db $1C, $01, $00
	db $8E, $A4, $60
	db $15, $01, $00
	db $1C, $01, $00
	db $15, $01, $00
	db $1C, $01, $00
	db $15, $01, $00
	db $1C, $01, $00
	db $15, $01, $00
	db $1C, $01, $00
	db $FF

SFX20D:
	db $87, $01
	db $8E, $F2, $60
	db $42, $01, $00
	db $8E, $D4, $60
	db $52, $01, $00
	db $FF

SFX21D:
	db $87, $01
	db $8E, $B0, $60
	db $47, $01, $00
	db $8E, $C8, $60
	db $43, $01, $00
	db $8E, $D4, $60
	db $42, $01, $02
	db $8E, $EC, $60
	db $41, $01, $00
	db $8E, $C8, $60
	db $52, $01, $08
	db $8E, $D4, $60
	db $41, $01, $00
	db $8E, $BC, $60
	db $52, $01, $08
	db $8E, $BC, $60
	db $41, $01, $00
	db $8E, $AA, $60
	db $52, $01, $08
	db $8E, $B0, $60
	db $41, $01, $00
	db $8E, $A4, $60
	db $52, $01, $08
	db $FF

SFX22A:
	db $87, $01
	db $85, $10
	db $88, $15
	db $8E, $C8, $60
	db $0C, $06, $00
	db $8E, $E0, $60
	db $0C, $06, $00
	db $8E, $F2, $60
	db $0C, $06, $00
	db $8E, $F2, $60
	db $0C, $06, $00
	db $8E, $B0, $60
	db $0C, $06, $00
	db $8E, $AA, $60
	db $0C, $06, $00
	db $8E, $A4, $60
	db $0C, $06, $00
	db $8E, $9E, $60
	db $0C, $06, $00
	db $FF

SFX23D:
	db $87, $03
	db $8E, $A4, $60
	db $15, $01, $00
	db $8E, $B0, $60
	db $15, $01, $00
	db $8E, $BC, $60
	db $15, $01, $00
	db $8E, $C8, $60
	db $15, $01, $00
	db $8E, $D4, $60
	db $15, $01, $00
	db $8E, $E0, $60
	db $15, $01, $00
	db $25, $01, $00
	db $26, $01, $00
	db $27, $01, $00
	db $8E, $D4, $60
	db $27, $01, $00
	db $8E, $C8, $60
	db $27, $01, $00
	db $8E, $B0, $60
	db $27, $01, $00
	db $8E, $A4, $60
	db $27, $01, $00
	db $FF

SFX24A:
	db $87, $01
	db $85, $33
	db $88, $1D
	db $8E, $BC, $60
	db $04, $03, $00
	db $05, $03, $00
	db $8E, $D4, $60
	db $06, $03, $00
	db $07, $03, $00
	db $8E, $E0, $60
	db $08, $03, $00
	db $09, $03, $00
	db $8E, $F2, $60
	db $0A, $03, $00
	db $0B, $03, $00
	db $0A, $03, $00
	db $0B, $03, $00
	db $0C, $03, $00
	db $0D, $03, $00
	db $0E, $03, $00
	db $0F, $03, $00
	db $10, $03, $00
	db $10, $03, $00
	db $10, $03, $00
	db $8E, $E0, $60
	db $10, $03, $00
	db $0F, $03, $00
	db $0F, $03, $00
	db $8E, $C8, $60
	db $0F, $03, $00
	db $0F, $03, $00
	db $0F, $03, $00
	db $8E, $AA, $60
	db $0F, $03, $00
	db $0F, $03, $00
	db $0F, $03, $00
	db $8E, $A4, $60
	db $0F, $03, $00
	db $0F, $03, $00
	db $0F, $03, $00
	db $FF

SFX25A:
	db $87, $01
	db $85, $11
	db $8E, $E0, $60
	db $88, $1D
	db $28, $08, $00
	db $88, $2F
	db $8E, $F2, $60
	db $30, $10, $00
	db $8E, $C8, $60
	db $30, $10, $00
	db $8E, $B0, $60
	db $30, $10, $00
	db $8E, $A4, $60
	db $30, $08, $00
	db $FF

VibSeq01:
	db $01
	db $01, $FF
	db $01, $FE
	db $01, $FD
	db $01, $FC
	db $01, $FB
	db $01, $FA
	db $01, $F9
	db $01, $F8
	db $01, $F7
	db $01, $F6
	db $01, $F5
	db $01, $F4
	db $01, $F3
	db $01, $F2
	db $01, $F1
	db $01, $F0
	db $01, $EE
	db $01, $EC
	db $01, $EA
	db $01, $E8
	db $01, $E6
	db $01, $E4
	db $01, $E2
	db $01, $E0
	db $01, $DE
	db $01, $DC
	db $01, $DA
	db $01, $D8
	db $01, $D6
	db $01, $D4
	db $01, $D2
	db $01, $D0
	db $FF

EnvSeq03:
	db $18, $1A
	db $20, $F4
	db $FF

SFX26A:
	db $87, $01
	db $85, $22
	db $8E, $6E, $50
	db $8C, $2C, $50
	db $40, $40, $00
	db $FF

SFX27D:
	db $87, $03
	db $95
	db $8E, $CE, $60
	db $56, $01, $00
	db $8E, $E0, $60
	db $55, $01, $00
	db $8E, $F2, $60
	db $54, $01, $00
	db $8E, $E0, $60
	db $55, $01, $00
	db $8E, $CE, $60
	db $56, $01, $00
	db $8E, $B0, $60
	db $57, $01, $00
	db $96, $00
	db $FF

SFX28D:
	db $87, $01
	db $8E, $C8, $60
	db $36, $01, $00
	db $8E, $D4, $60
	db $47, $02, $00
	db $8E, $E6, $60
	db $46, $01, $00
	db $8E, $D4, $60
	db $45, $01, $00
	db $8E, $CE, $60
	db $23, $01, $00
	db $8E, $D4, $60
	db $11, $03, $00
	db $8E, $C8, $60
	db $11, $03, $00
	db $8E, $AA, $60
	db $11, $03, $00
	db $FF

SFX29D:
	db $87, $01
	db $8E, $A4, $60
	db $21, $02, $00
	db $8E, $BC, $60
	db $22, $02, $00
	db $8E, $D4, $60
	db $23, $01, $00
	db $24, $01, $00
	db $25, $01, $00
	db $8E, $BC, $60
	db $26, $02, $00
	db $8E, $A4, $60
	db $27, $02, $00
	db $21, $02, $00
	db $8E, $BC, $60
	db $22, $02, $00
	db $8E, $D4, $60
	db $23, $01, $00
	db $24, $01, $00
	db $25, $01, $00
	db $8E, $BC, $60
	db $26, $02, $00
	db $8E, $A4, $60
	db $27, $02, $00
	db $21, $02, $00
	db $8E, $BC, $60
	db $22, $02, $00
	db $8E, $D4, $60
	db $23, $01, $00
	db $24, $01, $00
	db $25, $01, $00
	db $8E, $BC, $60
	db $26, $02, $00
	db $8E, $A4, $60
	db $27, $02, $00
	db $FF

SFX2AD:
	db $87, $01
	db $8E, $E0, $60
	db $36, $01, $00
	db $46, $01, $00
	db $56, $01, $00
	db $8E, $BC, $60
	db $1B, $28, $00
	db $8E, $A4, $60
	db $1B, $08, $00
	db $FF

VibSeq02:
	db $01
	db $01, $06
	db $01, $0C
	db $01, $12
	db $01, $18
	db $01, $1E
	db $01, $24
	db $01, $2A
	db $01, $30
	db $01, $36
	db $01, $3C
	db $01, $42
	db $01, $48
	db $01, $4E
	db $01, $54
	db $01, $5A
	db $01, $60
	db $01, $66
	db $01, $6C
	db $01, $72
	db $01, $78
	db $01, $7E
	db $01, $84
	db $01, $8A
	db $01, $90
	db $01, $96
	db $01, $9C
	db $01, $A2
	db $01, $A8
	db $01, $AE
	db $01, $B4
	db $01, $BA
	db $01, $C0
	db $01, $C6
	db $01, $CC
	db $01, $D2
	db $01, $D8
	db $01, $DE
	db $01, $E4
	db $01, $EA
	db $FF

SFX2AA:
	db $87, $01
	db $85, $00
	db $8C, $62, $51
	db $8E, $B6, $60
	db $1C, $28, $00
	db $FF

SFX2BA:
	db $87, $01
	db $85, $22
	db $8E, $BC, $60
	db $81, $00
	db $92
	dw SFX2BA_1
	db $81, $01
	db $92
	dw SFX2BA_1
	db $8E, $C8, $60
	db $81, $02
	db $92
	dw SFX2BA_1
	db $81, $03
	db $92
	dw SFX2BA_1
	db $8E, $D4, $60
	db $81, $04
	db $92
	dw SFX2BA_1
	db $81, $05
	db $92
	dw SFX2BA_1
	db $8E, $EC, $60
	db $81, $06
	db $92
	dw SFX2BA_1
	db $81, $07
	db $92
	dw SFX2BA_1
	db $8E, $F2, $60
	db $81, $08
	db $92
	dw SFX2BA_1
	db $81, $09
	db $92
	dw SFX2BA_1
	db $81, $0A
	db $92
	dw SFX2BA_1
	db $92
	dw SFX2BA_1
	db $92
	dw SFX2BA_1
	db $8E, $C8, $60
	db $92
	dw SFX2BA_1
	db $8E, $B0, $60
	db $92
	dw SFX2BA_1
	db $8E, $A4, $60
	db $92
	dw SFX2BA_1
	db $FF

SFX2BA_1:
	db $04, $01, $00
	db $06, $01, $00
	db $08, $01, $00
	db $0A, $01, $00
	db $93

SFX2CA:
	db $87, $01
	db $85, $00
	db $8E, $AA, $60
	db $81, $FF
	db $92
	dw SFX2CA_1
	db $8E, $B6, $60
	db $81, $00
	db $92
	dw SFX2CA_1
	db $8E, $C2, $60
	db $81, $01
	db $92
	dw SFX2CA_1
	db $8E, $CE, $60
	db $81, $02
	db $92
	dw SFX2CA_1
	db $8E, $DA, $60
	db $81, $03
	db $92
	dw SFX2CA_1
	db $8E, $EC, $60
	db $81, $04
	db $92
	dw SFX2CA_1
	db $8E, $F2, $60
	db $92
	dw SFX2CA_1
	db $8E, $B6, $60
	db $92
	dw SFX2CA_1
	db $8E, $AA, $60
	db $92
	dw SFX2CA_1
	db $FF

SFX2CA_1:
	db $34, $02, $00
	db $30, $01, $00
	db $3C, $02, $00
	db $37, $01, $00
	db $93

SFX2DD:
	db $87, $01
	db $8E, $B0, $60
	db $42, $01, $00
	db $8E, $BC, $60
	db $32, $01, $00
	db $8E, $F2, $60
	db $12, $02, $00
	db $8E, $D4, $60
	db $11, $02, $00
	db $8E, $AA, $60
	db $11, $03, $00
	db $FF

SFX2EA:
	db $87, $01
	db $85, $22
	db $8E, $F2, $60
	db $88, $1C
	db $44, $08, $00
	db $34, $06, $00
	db $8E, $E0, $60
	db $20, $06, $00
	db $8E, $C8, $60
	db $20, $06, $00
	db $8E, $B0, $60
	db $20, $06, $00
	db $8E, $A4, $60
	db $20, $06, $00
	db $FF

SFX2ED:
	db $87, $01
	db $8E, $F2, $60
	db $5F, $01, $01
	db $37, $01, $01
	db $5F, $01, $01
	db $47, $01, $01
	db $37, $06, $00
	db $8E, $BC, $60
	db $37, $06, $00
	db $8E, $B0, $60
	db $37, $06, $00
	db $8E, $AA, $60
	db $37, $06, $00
	db $8E, $A4, $60
	db $37, $06, $00
	db $8E, $9E, $60
	db $37, $06, $00
	db $FF

SFX2FD:
	db $87, $01
	db $8E, $F2, $60
	db $3E, $01, $00
	db $8E, $E0, $60
	db $3F, $01, $00
	db $8E, $B6, $60
	db $3E, $02, $00
	db $8E, $A4, $60
	db $3F, $01, $00
	db $3E, $04, $00
	db $FF

SFX30A:
	db $87, $01
	db $85, $22
	db $81, $04
	db $8E, $F2, $60
	db $1F, $01, $00
	db $8E, $EC, $60
	db $1E, $01, $00
	db $8E, $E6, $60
	db $1D, $01, $00
	db $8E, $E0, $60
	db $1C, $01, $00
	db $8E, $DA, $60
	db $1A, $01, $00
	db $8E, $D4, $60
	db $18, $01, $00
	db $8E, $CE, $60
	db $16, $01, $00
	db $8E, $C8, $60
	db $12, $01, $00
	db $8E, $C2, $60
	db $0E, $01, $00
	db $8E, $BC, $60
	db $0A, $01, $00
	db $8E, $B6, $60
	db $05, $01, $00
	db $8E, $B0, $60
	db $1C, $01, $00
	db $1A, $01, $00
	db $18, $01, $00
	db $16, $01, $00
	db $12, $01, $00
	db $0E, $01, $00
	db $0A, $01, $00
	db $05, $01, $00
	db $8E, $A4, $60
	db $1C, $01, $00
	db $1A, $01, $00
	db $18, $01, $00
	db $16, $01, $00
	db $12, $01, $00
	db $0E, $01, $00
	db $0A, $01, $00
	db $05, $01, $00
	db $FF

SFX30D:
	db $87, $01
	db $8E, $C8, $60
	db $3D, $01, $00
	db $8E, $AA, $60
	db $3E, $01, $00
	db $8E, $A4, $60
	db $3D, $02, $00
	db $FF

SFX31D:
	db $87, $01
	db $8E, $F2, $60
	db $36, $01, $01
	db $47, $02, $01
	db $2E, $02, $00
	db $3D, $01, $00
	db $2D, $01, $00
	db $3C, $01, $00
	db $8E, $C8, $60
	db $2C, $01, $00
	db $3B, $01, $00
	db $2B, $01, $00
	db $3A, $01, $00
	db $8E, $D4, $60
	db $2E, $02, $00
	db $3D, $01, $00
	db $2D, $01, $00
	db $3C, $01, $00
	db $8E, $BC, $60
	db $2C, $01, $00
	db $3B, $01, $00
	db $2B, $01, $00
	db $3A, $01, $00
	db $8E, $C8, $60
	db $2E, $02, $00
	db $3D, $01, $00
	db $2D, $01, $00
	db $3C, $01, $00
	db $8E, $B0, $60
	db $2C, $01, $00
	db $3B, $01, $00
	db $2B, $01, $00
	db $3A, $01, $00
	db $8E, $BC, $60
	db $2E, $02, $00
	db $3D, $01, $00
	db $2D, $01, $00
	db $3C, $01, $00
	db $8E, $A4, $60
	db $2C, $01, $00
	db $3B, $01, $00
	db $2B, $01, $00
	db $3A, $01, $00
	db $8E, $AA, $60
	db $2E, $02, $00
	db $3D, $01, $00
	db $2D, $01, $00
	db $3C, $01, $00
	db $8E, $9E, $60
	db $2C, $02, $00
	db $3B, $01, $00
	db $2B, $01, $00
	db $3A, $01, $00
	db $8E, $A4, $60
	db $2E, $02, $00
	db $3D, $01, $00
	db $2D, $01, $00
	db $3C, $01, $00
	db $8E, $9E, $60
	db $2C, $02, $00
	db $3B, $01, $00
	db $2B, $01, $00
	db $3A, $01, $00
	db $FF

SFX32D:
	db $87, $01
	db $8E, $B0, $60
	db $22, $01, $00
	db $8E, $E0, $60
	db $10, $03, $00
	db $11, $03, $00
	db $8E, $F2, $60
	db $12, $03, $00
	db $13, $03, $00
	db $8E, $C8, $60
	db $12, $03, $00
	db $13, $03, $00
	db $8E, $B6, $60
	db $12, $03, $00
	db $13, $03, $00
	db $8E, $AA, $60
	db $12, $03, $00
	db $13, $03, $00
	db $FF

SFX33D:
	db $87, $01
	db $8E, $C8, $60
	db $5F, $02, $00
	db $8E, $F2, $60
	db $51, $01, $01
	db $8E, $B0, $60
	db $22, $01, $00
	db $8E, $F2, $60
	db $10, $03, $00
	db $11, $03, $00
	db $12, $03, $00
	db $13, $03, $00
	db $8E, $BC, $60
	db $12, $03, $00
	db $13, $03, $00
	db $8E, $B0, $60
	db $12, $03, $00
	db $13, $03, $00
	db $8E, $AA, $60
	db $12, $03, $00
	db $13, $03, $00
	db $8E, $A4, $60
	db $12, $03, $00
	db $13, $03, $00
	db $FF

SFX34A:
	db $87, $01
	db $85, $00
	db $88, $17
	db $8E, $F2, $60
	db $2C, $06, $00
	db $88, $1F
	db $3F, $08, $00
	db $8E, $C8, $60
	db $3F, $08, $00
	db $8E, $BC, $60
	db $3F, $08, $00
	db $8E, $A4, $60
	db $3F, $08, $00
	db $FF

SFX34D:
	db $87, $01
	db $8E, $A4, $60
	db $27, $06, $00
	db $8E, $E0, $60
	db $23, $08, $00
	db $8E, $D4, $60
	db $23, $08, $00
	db $8E, $BC, $60
	db $23, $08, $00
	db $8E, $A4, $60
	db $23, $08, $00
	db $FF

SFX35A:
	db $87, $01
	db $81, $0F
	db $85, $00
	db $8E, $A4, $60
	db $28, $01, $00
	db $29, $01, $00
	db $2A, $01, $00
	db $8E, $AA, $60
	db $2B, $01, $00
	db $2C, $01, $00
	db $2D, $01, $00
	db $2E, $0E, $00
	db $8E, $B6, $60
	db $2F, $01, $00
	db $30, $01, $00
	db $31, $01, $00
	db $32, $01, $00
	db $8E, $E0, $60
	db $33, $08, $00
	db $8E, $B0, $60
	db $33, $08, $00
	db $8E, $AA, $60
	db $33, $08, $00
	db $8E, $A4, $60
	db $33, $08, $00
	db $FF

SFX35D:
	db $87, $01
	db $8E, $C8, $60
	db $5F, $03, $00
	db $8E, $F2, $60
	db $53, $01, $01
	db $8E, $C8, $60
	db $52, $01, $00
	db $8E, $F2, $60
	db $35, $04, $00
	db $34, $0A, $00
	db $33, $06, $00
	db $32, $04, $00
	db $8E, $BC, $60
	db $33, $04, $00
	db $32, $04, $00
	db $8E, $B0, $60
	db $33, $04, $00
	db $32, $04, $00
	db $8E, $AA, $60
	db $33, $04, $00
	db $32, $04, $00
	db $8E, $A4, $60
	db $33, $04, $00
	db $32, $04, $00
	db $FF

SFX36A:
	db $87, $01
	db $81, $FA
	db $85, $22
	db $88, $16
	db $8E, $E0, $60
	db $1F, $06, $00
	db $8E, $D4, $60
	db $28, $04, $00
	db $24, $04, $00
	db $20, $04, $00
	db $1C, $04, $00
	db $8E, $BC, $60
	db $20, $04, $00
	db $1C, $04, $00
	db $8E, $A4, $60
	db $20, $04, $00
	db $1C, $04, $00
	db $FF

SFX37D:
	db $87, $01
	db $8E, $D4, $60
	db $51, $01, $01
	db $8E, $E0, $60
	db $44, $01, $00
	db $22, $02, $00
	db $8E, $F2, $60
	db $92
	dw SFX37D_1
	db $8E, $E0, $60
	db $92
	dw SFX37D_1
	db $8E, $C8, $60
	db $92
	dw SFX37D_1
	db $8E, $BC, $60
	db $92
	dw SFX37D_1
	db $8E, $B0, $60
	db $92
	dw SFX37D_1
	db $8E, $A4, $60
	db $92
	dw SFX37D_1
	db $FF

SFX37D_1:
	db $11, $0C, $00
	db $93

SFX38D:
	db $87, $02
	db $8E, $EC, $60
	db $2D, $01, $00
	db $2C, $01, $00
	db $1F, $01, $00
	db $92
	dw SFX38D_1
	db $92
	dw SFX38D_1
	db $92
	dw SFX38D_1
	db $8E, $B0, $60
	db $92
	dw SFX38D_2
	db $8E, $A4, $60
	db $92
	dw SFX38D_2
	db $FF

SFX38D_1:
	db $1E, $01, $00
	db $2D, $01, $00
	db $1F, $01, $00

SFX38D_2:
	db $2D, $01, $00
	db $1F, $01, $00
	db $1E, $01, $00
	db $2D, $01, $00
	db $93

SFX39A:
	db $87, $01
	db $85, $11
	db $8E, $F2, $60
	db $44, $01, $00
	db $8E, $D4, $60
	db $46, $01, $00
	db $8E, $E0, $60
	db $48, $03, $02
	db $8E, $F2, $60
	db $48, $05, $00
	db $8E, $C8, $60
	db $48, $05, $00
	db $8E, $BC, $60
	db $48, $05, $00
	db $8E, $A4, $60
	db $48, $0A, $00
	db $FF

SFX39B:
	db $87, $01
	db $85, $11
	db $8E, $F2, $60
	db $43, $01, $00
	db $8E, $D4, $60
	db $45, $01, $00
	db $83, $02
	db $8E, $E0, $60
	db $48, $03, $02
	db $8E, $F2, $60
	db $48, $05, $00
	db $8E, $C8, $60
	db $48, $05, $00
	db $8E, $BC, $60
	db $48, $05, $00
	db $8E, $A4, $60
	db $48, $0A, $00
	db $FF

SFX3AD:
	db $87, $01
	db $8E, $B0, $60
	db $47, $03, $00
	db $8E, $C8, $60
	db $46, $03, $00
	db $8E, $D4, $60
	db $46, $03, $00
	db $8E, $E0, $60
	db $46, $04, $00
	db $8E, $F2, $60
	db $46, $10, $00
	db $8E, $BC, $60
	db $46, $09, $00
	db $8E, $A4, $60
	db $46, $09, $00
	db $FF

SFX3BD:
	db $87, $01
	db $8E, $D4, $60
	db $57, $07, $00
	db $8E, $F2, $60
	db $57, $38, $00
	db $8E, $D4, $60
	db $57, $07, $00
	db $8E, $BC, $60
	db $57, $07, $00
	db $8E, $AA, $60
	db $57, $07, $00
	db $FF

SFX3CA:
	db $87, $01
	db $85, $22
	db $88, $16
	db $8E, $B0, $60
	db $0D, $07, $00
	db $8E, $C8, $60
	db $0E, $07, $00
	db $8E, $E0, $60
	db $0F, $07, $00
	db $10, $07, $00
	db $11, $07, $00
	db $12, $07, $00
	db $13, $07, $00
	db $8E, $BC, $60
	db $13, $07, $00
	db $8E, $AA, $60
	db $13, $07, $00
	db $FF

SFX3CD:
	db $87, $01
	db $8E, $B0, $60
	db $57, $07, $00
	db $8E, $BC, $60
	db $55, $2A, $00
	db $8E, $B0, $60
	db $55, $07, $00
	db $8E, $A4, $60
	db $55, $07, $00
	db $FF

SFX3DA:
	db $87, $01
	db $85, $33
	db $8E, $E0, $60
	db $44, $01, $00
	db $8E, $C8, $60
	db $44, $01, $00
	db $8E, $D4, $60
	db $46, $03, $02
	db $8E, $E0, $60
	db $46, $01, $00
	db $8E, $C8, $60
	db $46, $01, $00
	db $8E, $D4, $60
	db $48, $03, $02
	db $8E, $E0, $60
	db $48, $06, $00
	db $8E, $B0, $60
	db $48, $06, $00
	db $8E, $A4, $60
	db $48, $06, $00
	db $FF

SFX3DB:
	db $87, $01
	db $85, $33
	db $8E, $E0, $60
	db $43, $01, $00
	db $8E, $C8, $60
	db $43, $01, $00
	db $83, $02
	db $8E, $D4, $60
	db $46, $03, $02
	db $83, $00
	db $8E, $E0, $60
	db $45, $01, $00
	db $8E, $C8, $60
	db $45, $01, $00
	db $83, $02
	db $8E, $D4, $60
	db $48, $03, $02
	db $8E, $E0, $60
	db $48, $06, $00
	db $8E, $B0, $60
	db $48, $06, $00
	db $8E, $A4, $60
	db $48, $06, $00
	db $FF

SFX3EA:
	db $87, $01
	db $85, $22
	db $84, $03
	db $8E, $F2, $60
	db $22, $02, $00
	db $8E, $D4, $60
	db $22, $04, $00
	db $8E, $9E, $60
	db $22, $0A, $00
	db $8E, $D4, $60
	db $22, $18, $00
	db $8E, $A4, $60
	db $22, $08, $00
	db $FF

SFX3EB:
	db $87, $01
	db $83, $01
	db $85, $22
	db $84, $00
	db $00, $00, $0A
	db $8E, $D4, $60
	db $22, $02, $00
	db $8E, $C8, $60
	db $22, $04, $00
	db $8E, $B0, $60
	db $22, $0A, $00
	db $8E, $C2, $60
	db $22, $18, $00
	db $8E, $A4, $60
	db $22, $08, $00
	db $FF

SFX41D:
	db $87, $01
	db $8E, $C8, $60
	db $67, $07, $00
	db $67, $08, $00
	db $8E, $E0, $60
	db $66, $07, $00
	db $66, $07, $00
	db $65, $07, $00
	db $65, $09, $00
	db $8E, $EC, $60
	db $57, $07, $00
	db $8E, $F2, $60
	db $95
	db $57, $07, $00
	db $57, $08, $00
	db $57, $07, $00
	db $57, $07, $00
	db $57, $09, $00
	db $57, $07, $00
	db $96, $00

VibSeq03:
	db $01
	db $01, $ED
	db $01, $EE
	db $01, $EF
	db $01, $F0
	db $01, $F1
	db $01, $F2
	db $01, $F3
	db $01, $F4
	db $01, $F5
	db $01, $F6
	db $01, $F7
	db $01, $F8
	db $01, $F9
	db $01, $FA
	db $01, $FB
	db $01, $FC
	db $01, $FD
	db $01, $FE
	db $01, $FF
	db $01, $FE
	db $01, $FD
	db $01, $FC
	db $01, $FB
	db $01, $FA
	db $01, $F9
	db $01, $F8
	db $01, $F7
	db $01, $F6
	db $01, $F5
	db $01, $F4
	db $01, $F3
	db $01, $F2
	db $01, $F1
	db $01, $F0
	db $01, $EF
	db $01, $EE
	db $01, $ED
	db $FF

EnvSeq04:
	db $20, $1D
	db $20, $67
	db $FF

EnvSeq05:
	db $20, $3D
	db $20, $97
	db $FF

SFX3FA:
	db $87, $01
	db $85, $22
	db $8E, $B0, $58
	db $8C, $64, $58
	db $40, $60, $00
	db $FF

SFX3FD:
	db $87, $01
	db $8E, $B5, $58
	db $11, $60, $00
	db $FF

EnvSeq06:
	db $20, $1F
	db $20, $47
	db $FF

EnvSeq07:
	db $20, $3D
	db $20, $97
	db $FF

SFX40A:
	db $87, $01
	db $85, $22
	db $8E, $D1, $58
	db $8C, $64, $58
	db $95
	db $44, $54, $00
	db $96, $00
	db $FF

SFX40D:
	db $87, $01
	db $8E, $D6, $58
	db $95
	db $46, $54, $00
	db $96, $00
	db $FF

SFX0BD:
	db $8E, $C8, $60
	db $57, $07, $00
	db $8E, $B0, $60
	db $57, $07, $00
	db $FF

SFX42D:
	db $87, $01
	db $8E, $F2, $60
	db $45, $01, $01
	db $51, $01, $00
	db $8E, $E0, $60
	db $47, $03, $00
	db $8E, $BC, $60
	db $57, $03, $00
	db $FF

SFX43D:
	db $87, $01
	db $8E, $F2, $60
	db $44, $01, $01
	db $51, $01, $00
	db $8E, $E0, $60
	db $22, $03, $00
	db $8E, $BC, $60
	db $21, $03, $00
	db $FF

SFX44A:
	db $87, $01
	db $85, $12
	db $88, $1C
	db $8E, $F2, $60
	db $28, $06, $00
	db $8E, $F2, $60
	db $28, $06, $00
	db $8E, $AA, $60
	db $28, $06, $00
	db $FF

SFX45D:
	db $87, $01
	db $8E, $F2, $60
	db $57, $01, $00
	db $11, $02, $00
	db $8E, $E0, $60
	db $22, $02, $00
	db $8E, $D4, $60
	db $33, $01, $00
	db $8E, $C8, $60
	db $37, $01, $00
	db $5B, $01, $00
	db $8E, $D4, $60
	db $14, $01, $00
	db $8E, $F2, $60
	db $12, $01, $00
	db $8E, $C8, $60
	db $11, $02, $00
	db $8E, $A4, $60
	db $11, $02, $00
	db $FF

SFX46A:
	db $87, $01
	db $85, $22
	db $8E, $F2, $60
	db $88, $1C
	db $30, $07, $00
	db $8E, $E0, $60
	db $28, $07, $00
	db $8E, $C8, $60
	db $28, $07, $00
	db $8E, $B0, $60
	db $28, $07, $00
	db $FF

SFX47A:
	db $87, $01
	db $85, $22
	db $8E, $F2, $60
	db $88, $1C
	db $26, $04, $00
	db $FF

SFX47D:
	db $87, $01
	db $8E, $F2, $60
	db $5F, $01, $01
	db $4C, $01, $01
	db $8E, $E0, $60
	db $5F, $01, $01
	db $8E, $F2, $60
	db $5F, $01, $02
	db $8E, $C8, $60
	db $32, $02, $00
	db $8E, $B0, $60
	db $21, $03, $00
	db $FF

SFX48A:
	db $87, $01
	db $85, $12
	db $88, $1B
	db $8E, $F2, $60
	db $3C, $08, $00
	db $88, $16
	db $8E, $E0, $60
	db $0A, $0A, $00
	db $8E, $BC, $60
	db $0A, $0A, $00
	db $8E, $A4, $60
	db $0A, $0A, $00
	db $FF

SFX49D:
	db $87, $01
	db $8E, $F2, $60
	db $4D, $01, $01
	db $5F, $01, $01
	db $8E, $E0, $60
	db $4C, $01, $01
	db $8E, $F2, $60
	db $4C, $01, $02
	db $8E, $BC, $60
	db $4C, $01, $01
	db $5F, $01, $01
	db $8E, $B0, $60
	db $4C, $01, $01
	db $8E, $BC, $60
	db $4C, $01, $02
	db $8E, $B0, $60
	db $4C, $01, $01
	db $5F, $01, $01
	db $8E, $A4, $60
	db $4C, $01, $01
	db $8E, $AA, $60
	db $4C, $01, $02
	db $FF

SFX4AA:
	db $87, $01
	db $85, $11
	db $8E, $F2, $60
	db $42, $01, $00
	db $85, $22
	db $47, $01, $01
	db $8E, $E0, $60
	db $48, $01, $00
	db $49, $01, $00
	db $4A, $03, $00
	db $8E, $C8, $60
	db $4A, $02, $00
	db $8E, $BC, $60
	db $4A, $06, $00
	db $8E, $A4, $60
	db $4A, $0C, $00
	db $FF

SFX4AD:
	db $87, $01
	db $8E, $D4, $60
	db $02, $01, $01
	db $FF

SFX4BA:
	db $87, $01
	db $85, $22
	db $88, $1C
	db $8E, $F2, $60
	db $24, $06, $00
	db $8E, $EC, $60
	db $24, $06, $00
	db $8E, $E0, $60
	db $24, $06, $00
	db $8E, $D4, $60
	db $24, $06, $00
	db $8E, $C8, $60
	db $24, $06, $00
	db $8E, $AA, $60
	db $24, $06, $00
	db $FF

SFX4BD:
	db $87, $01
	db $8E, $F2, $60
	db $5F, $01, $01
	db $47, $01, $01
	db $5F, $01, $01
	db $37, $06, $00
	db $8E, $E0, $60
	db $37, $06, $00
	db $8E, $D4, $60
	db $37, $06, $00
	db $8E, $BC, $60
	db $37, $06, $00
	db $8E, $B0, $60
	db $37, $06, $00
	db $8E, $A4, $60
	db $37, $06, $00
	db $FF

SFX4CA:
	db $87, $01
	db $85, $22
	db $8E, $F2, $60
	db $88, $1C
	db $44, $08, $00
	db $34, $07, $00
	db $8E, $EC, $60
	db $24, $07, $00
	db $8E, $D4, $60
	db $24, $07, $00
	db $8E, $C8, $60
	db $24, $07, $00
	db $8E, $C2, $60
	db $24, $07, $00
	db $8E, $B6, $60
	db $24, $07, $00
	db $8E, $B0, $60
	db $24, $07, $00
	db $8E, $AA, $60
	db $24, $07, $00
	db $FF

SFX4CD:
	db $87, $01
	db $8E, $F2, $60
	db $5F, $01, $01
	db $37, $01, $01
	db $5F, $01, $01
	db $47, $01, $01
	db $37, $07, $00
	db $8E, $E0, $60
	db $27, $07, $00
	db $8E, $D4, $60
	db $27, $07, $00
	db $8E, $C8, $60
	db $27, $07, $00
	db $8E, $BC, $60
	db $27, $07, $00
	db $8E, $B0, $60
	db $27, $07, $00
	db $8E, $AA, $60
	db $27, $07, $00
	db $8E, $A4, $60
	db $27, $07, $00
	db $FF

SFX4DA:
	db $81, $FC
	db $87, $01
	db $85, $11
	db $8E, $C8, $60
	db $21, $01, $00
	db $24, $01, $00
	db $27, $01, $00
	db $8E, $D4, $60
	db $2A, $01, $00
	db $2D, $01, $00
	db $8E, $DA, $60
	db $92
	dw SFX4DA_1
	db $8E, $C8, $60
	db $92
	dw SFX4DA_1
	db $8E, $BC, $60
	db $92
	dw SFX4DA_1
	db $8E, $AA, $60
	db $92
	dw SFX4DA_1
	db $FF

SFX4DA_1:
	db $30, $01, $00
	db $2D, $01, $00
	db $2A, $01, $00
	db $27, $01, $00
	db $24, $01, $00
	db $21, $01, $00
	db $1E, $01, $00
	db $1B, $01, $00
	db $93

SFX4EA:
	db $87, $02
	db $85, $11
	db $8E, $BC, $60
	db $38, $01, $00
	db $8E, $D4, $60
	db $3F, $01, $00
	db $3D, $01, $00
	db $8E, $E0, $60
	db $92
	dw SFX4EA_1
	db $8E, $D4, $60
	db $92
	dw SFX4EA_1
	db $8E, $B0, $60
	db $92
	dw SFX4EA_1
	db $8E, $A4, $60
	db $92
	dw SFX4EA_1
	db $FF

SFX4EA_1:
	db $44, $01, $00
	db $42, $01, $00
	db $49, $01, $00
	db $47, $01, $00
	db $4E, $01, $00
	db $93

SFX4FD:
	db $87, $01
	db $8E, $B0, $60
	db $37, $02, $00
	db $8E, $C8, $60
	db $23, $03, $00
	db $8E, $B0, $60
	db $37, $02, $00
	db $8E, $BC, $60
	db $23, $04, $00
	db $FF

SFX50A:
	db $87, $01
	db $85, $22
	db $81, $00
	db $8E, $A4, $60
	db $92
	dw SFX50A_1
	db $81, $02
	db $8E, $B0, $60
	db $92
	dw SFX50A_1
	db $81, $04
	db $8E, $BC, $60
	db $92
	dw SFX50A_1
	db $81, $06
	db $8E, $C8, $60
	db $92
	dw SFX50A_1
	db $81, $08
	db $8E, $D4, $60
	db $92
	dw SFX50A_1
	db $81, $0A
	db $8E, $E0, $60
	db $92
	dw SFX50A_1
	db $81, $0C
	db $8E, $EC, $60
	db $92
	dw SFX50A_1
	db $81, $0E
	db $92
	dw SFX50A_1
	db $8E, $C8, $60
	db $92
	dw SFX50A_1
	db $8E, $B0, $60
	db $92
	dw SFX50A_1
	db $8E, $A4, $60
	db $92
	dw SFX50A_1
	db $FF

SFX50A_1:
	db $21, $01, $00
	db $24, $01, $00
	db $27, $01, $00
	db $29, $01, $00
	db $93

SFX51A:
	db $87, $01
	db $85, $22
	db $81, $0E
	db $8E, $A4, $60
	db $92
	dw SFX50A_1
	db $81, $0C
	db $8E, $B0, $60
	db $92
	dw SFX50A_1
	db $81, $0A
	db $8E, $BC, $60
	db $92
	dw SFX50A_1
	db $81, $08
	db $8E, $C8, $60
	db $92
	dw SFX50A_1
	db $81, $06
	db $8E, $D4, $60
	db $92
	dw SFX50A_1
	db $81, $04
	db $8E, $E0, $60
	db $92
	dw SFX50A_1
	db $81, $02
	db $8E, $EC, $60
	db $92
	dw SFX50A_1
	db $81, $00
	db $92
	dw SFX50A_1
	db $8E, $C8, $60
	db $92
	dw SFX50A_1
	db $8E, $B0, $60
	db $92
	dw SFX50A_1
	db $8E, $A4, $60
	db $92
	dw SFX50A_1
	db $FF

SFX52A:
	db $81, $F6
	db $87, $02
	db $85, $22
	db $88, $1C
	db $8E, $BC, $60
	db $12, $01, $00
	db $8E, $D4, $60
	db $13, $01, $00
	db $8E, $EC, $60
	db $14, $01, $00
	db $15, $01, $00
	db $16, $01, $00
	db $16, $01, $00
	db $16, $01, $00
	db $16, $01, $00
	db $16, $01, $00
	db $16, $01, $00
	db $16, $01, $00
	db $16, $01, $00
	db $16, $01, $00
	db $16, $01, $00
	db $15, $01, $00
	db $14, $01, $00
	db $13, $01, $00
	db $12, $01, $00
	db $8E, $D4, $60
	db $11, $01, $00
	db $11, $01, $00
	db $8E, $C8, $60
	db $11, $01, $00
	db $8E, $AA, $60
	db $11, $01, $00
	db $11, $01, $00
	db $FF

SFX53A:
	db $87, $01
	db $85, $22
	db $88, $1B
	db $8E, $AA, $60
	db $92
	dw SFX53A_1
	db $8E, $B6, $60
	db $81, $01
	db $92
	dw SFX53A_1
	db $8E, $C8, $60
	db $81, $02
	db $92
	dw SFX53A_1
	db $8E, $E0, $60
	db $81, $03
	db $92
	dw SFX53A_1
	db $8E, $F2, $60
	db $81, $05
	db $95
	db $8E, $F2, $60
	db $92
	dw SFX53A_1
	db $96, $0F
	db $8E, $E0, $60
	db $92
	dw SFX53A_1
	db $8E, $D4, $60
	db $92
	dw SFX53A_1
	db $8E, $C8, $60
	db $92
	dw SFX53A_1
	db $8E, $B0, $60
	db $92
	dw SFX53A_1
	db $8E, $A4, $60
	db $92
	dw SFX53A_1
	db $FF

SFX53B:
	db $87, $01
	db $85, $22
	db $88, $1B
	db $81, $E8
	db $84, $00
	db $8E, $AA, $60
	db $92
	dw SFX53A_1
	db $8E, $B6, $60
	db $81, $E9
	db $92
	dw SFX53A_1
	db $8E, $C8, $60
	db $81, $EA
	db $92
	dw SFX53A_1
	db $8E, $D4, $60
	db $81, $EB
	db $92
	dw SFX53A_1
	db $8E, $E0, $60
	db $81, $ED
	db $95
	db $8E, $E0, $60
	db $92
	dw SFX53A_1
	db $96, $0F
	db $8E, $E0, $60
	db $92
	dw SFX53A_1
	db $8E, $D4, $60
	db $92
	dw SFX53A_1
	db $8E, $C8, $60
	db $92
	dw SFX53A_1
	db $8E, $B0, $60
	db $92
	dw SFX53A_1
	db $8E, $A4, $60
	db $92
	dw SFX53A_1
	db $FF

SFX53A_1:
	db $20, $03, $00
	db $20, $03, $00
	db $8E, $98, $60
	db $00, $01, $00
	db $93

VibSeq04:
	db $01
	db $02, $ED
	db $02, $EE
	db $02, $EF
	db $02, $F0
	db $03, $F1
	db $03, $F2
	db $03, $F3
	db $03, $F4
	db $03, $F5
	db $04, $F6
	db $04, $F7
	db $04, $F8
	db $04, $F9
	db $04, $FA
	db $05, $FB
	db $05, $FC
	db $05, $FD
	db $05, $FE
	db $7F, $FF
	db $7F, $FF
	db $FF

EnvSeq08:
	db $30, $1F
	db $40, $60
	db $40, $60
	db $20, $67
	db $FF

SFX54A:
	db $87, $01
	db $85, $22
	db $8E, $DB, $5D
	db $8C, $B1, $5D
	db $40, $82, $60, $00
	db $FF

EnvSeq09:
	db $20, $3D
	db $40, $90
	db $40, $90
	db $20, $97
	db $FF

SFX54D:
	db $87, $01
	db $8E, $F3, $5D
	db $34, $82, $60, $00
	db $FF

SFX55A:
	db $87, $01
	db $85, $22
	db $88, $1C
	db $8E, $F2, $60
	db $10, $06, $01
	db $8E, $F2, $60
	db $20, $07, $00
	db $8E, $C8, $60
	db $20, $07, $00
	db $8E, $AA, $60
	db $20, $07, $00
	db $FF

SFX55D:
	db $87, $01
	db $8E, $E0, $60
	db $4F, $01, $01
	db $FF

VibSeq05:
	db $01
	db $01, $ED
	db $01, $EF
	db $01, $F1
	db $01, $F3
	db $01, $F5
	db $01, $F7
	db $01, $F9
	db $01, $FB
	db $01, $FD
	db $01, $FF
	db $FF

EnvSeq0A:
	db $06, $1D
	db $04, $37
	db $FF

SFX56A:
	db $87, $01
	db $85, $22
	db $8E, $44, $5E
	db $8C, $2E, $5E
	db $48, $0F, $00
	db $FF

EnvSeq0B:
	db $03, $49
	db $1F, $A2
	db $FF

SFX56D:
	db $87, $01
	db $8E, $57, $5E
	db $23, $1F, $00
	db $FF

VibSeq06:
	db $01
	db $01, $ED
	db $01, $F1
	db $01, $F5
	db $01, $F9
	db $01, $FD
	db $01, $01
	db $01, $05
	db $01, $09
	db $01, $0D
	db $01, $11
	db $01, $15
	db $01, $19
	db $01, $1D
	db $01, $21
	db $01, $25
	db $01, $29
	db $01, $2D
	db $01, $31
	db $01, $35
	db $01, $39
	db $01, $3D
	db $01, $41
	db $01, $45
	db $01, $49
	db $01, $4D
	db $01, $51
	db $01, $55
	db $01, $59
	db $01, $5D
	db $01, $61
	db $01, $65
	db $01, $69
	db $7F, $6D
	db $FF

EnvSeq0C:
	db $08, $6C
	db $20, $A0
	db $58, $A7
	db $FF

SFX58A:
	db $87, $01
	db $85, $11
	db $8E, $A9, $5E
	db $8C, $65, $5E
	db $13, $58, $00
	db $FF

SFX57A:
	db $87, $01
	db $85, $11
	db $83, $01
	db $8E, $DA, $5E
	db $4C, $01, $01
	db $4C, $10, $06
	db $FF

SFX57D:
	db $87, $01
	db $8E, $E2, $5E
	db $2C, $01, $01
	db $1D, $10, $06
	db $FF

EnvSeq0D:
	db $0C, $E1
	db $01, $10
	db $FE
	db $7F, $23
	db $FF

EnvSeq0E:
	db $0C, $C1
	db $01, $10
	db $FE
	db $7F, $23
	db $FF

;Unused space (1 bytes)
	ds 1, $FF

SFX59D:
	db $87, $03
	db $8E, $A4, $60
	db $27, $01, $00
	db $8E, $B0, $60
	db $27, $01, $00
	db $8E, $BC, $60
	db $27, $01, $00
	db $8E, $C8, $60
	db $27, $01, $00
	db $8E, $D4, $60
	db $27, $01, $00
	db $8E, $E0, $60
	db $27, $01, $00
	db $26, $01, $00
	db $25, $01, $00
	db $25, $01, $00
	db $8E, $B0, $60
	db $25, $03, $00
	db $8E, $A4, $60
	db $25, $03, $00
	db $8E, $9E, $60
	db $25, $03, $00
	db $FF

EnvSeq0F:
	db $08, $C1
	db $FF

EnvSeq10:
	db $08, $61
	db $FF

EnvSeq11:
	db $08, $32
	db $FF

EnvSeq12:
	db $08, $14
	db $FF

SFX5AA:
	db $87, $01
	db $81, $00
	db $85, $22
	db $88, $17
	db $8E, $2D, $5F
	db $2C, $08, $00
	db $8E, $30, $5F
	db $2C, $08, $00
	db $8E, $33, $5F
	db $2C, $08, $00
	db $8E, $36, $5F
	db $2C, $08, $00
	db $FF

UnusedSeq_5F5A:
	db $08, $C1
	db $FF

SFX5BA:
	db $87, $01
	db $85, $22
	db $88, $1D
	db $8E, $E0, $60
	db $00, $00, $0F
	db $00, $00, $0F
	db $00, $00, $0F
	db $81, $F8
	db $8E, $E0, $60
	db $1C, $06, $00
	db $8E, $9E, $60
	db $1C, $06, $00
	db $81, $03
	db $8E, $E0, $60
	db $1C, $07, $00
	db $81, $F8
	db $8E, $D4, $60
	db $1C, $08, $00
	db $8E, $A4, $60
	db $1C, $08, $00
	db $8E, $9E, $60
	db $1C, $08, $00
	db $FF

SFX5BD:
	db $87, $01
	db $8E, $E0, $60
	db $4D, $02, $00
	db $37, $02, $00
	db $5F, $02, $09
	db $8E, $F2, $60
	db $4D, $02, $00
	db $37, $02, $00
	db $5F, $02, $09
	db $8E, $D4, $60
	db $4D, $02, $00
	db $37, $02, $00
	db $5F, $02, $09
	db $FF

SFX5CA:
	db $87, $01
	db $85, $22
	db $8E, $E0, $60
	db $81, $FC
	db $8E, $C8, $60
	db $28, $05, $00
	db $2B, $05, $00
	db $2F, $05, $00
	db $81, $FE
	db $8E, $D4, $60
	db $28, $05, $00
	db $2B, $05, $00
	db $2F, $05, $00
	db $81, $00
	db $8E, $E0, $60
	db $28, $05, $00
	db $2B, $05, $00
	db $2F, $05, $00
	db $8E, $B0, $60
	db $28, $05, $00
	db $2B, $05, $00
	db $2F, $05, $00
	db $8E, $A4, $60
	db $28, $05, $00
	db $2B, $05, $00
	db $2F, $05, $00
	db $8E, $9E, $60
	db $28, $05, $00
	db $2B, $05, $00
	db $2F, $05, $00
	db $FF

SFX5DA:
	db $87, $02
	db $85, $22
	db $81, $00
	db $8E, $E0, $60
	db $2F, $02, $00
	db $32, $02, $00
	db $2F, $01, $00
	db $33, $02, $00
	db $2F, $01, $00
	db $34, $02, $00
	db $8E, $D4, $60
	db $2F, $01, $00
	db $35, $02, $00
	db $8E, $C8, $60
	db $2F, $01, $00
	db $38, $02, $00
	db $8E, $B0, $60
	db $2F, $01, $00
	db $35, $02, $00
	db $2F, $01, $00
	db $38, $02, $00
	db $8E, $A4, $60
	db $2F, $01, $00
	db $35, $02, $00
	db $2F, $01, $00
	db $38, $02, $00
	db $FF

SFX5EA:
	db $87, $01
	db $85, $11
	db $83, $01
	db $8E, $DA, $5E
	db $4C, $01, $01
	db $4C, $10, $0E
	db $4C, $01, $01
	db $4C, $10, $0E
	db $4C, $01, $01
	db $4C, $10, $0E
	db $FF

SFX5ED:
	db $87, $01
	db $8E, $E2, $5E
	db $2C, $01, $01
	db $1D, $10, $0E
	db $2C, $01, $01
	db $1D, $10, $0E
	db $2C, $01, $01
	db $1D, $10, $0E
	db $FF

EmptyTrack:
	db $FF

EnvSeq13:
	db $01, $00
	db $FE
	db $01, $00
	db $FF

EnvSeq14:
	db $01, $10
	db $FE
	db $01, $00
	db $FF

EnvSeq15:
	db $01, $20
	db $FE
	db $01, $00
	db $FF

EnvSeq16:
	db $01, $30
	db $FE
	db $01, $00
	db $FF

EnvSeq17:
	db $01, $40
	db $FE
	db $01, $00
	db $FF

EnvSeq18:
	db $01, $50
	db $FE
	db $01, $00
	db $FF

EnvSeq19:
	db $01, $60
	db $FE
	db $01, $00
	db $FF

EnvSeq1A:
	db $01, $70
	db $FE
	db $01, $00
	db $FF

EnvSeq1B:
	db $01, $80
	db $FE
	db $01, $00
	db $FF

EnvSeq1C:
	db $01, $90
	db $FE
	db $01, $00
	db $FF

EnvSeq1D:
	db $01, $A0
	db $FE
	db $01, $00
	db $FF

EnvSeq1E:
	db $01, $B0
	db $FE
	db $01, $00
	db $FF

EnvSeq1F:
	db $01, $C0
	db $FE
	db $01, $00
	db $FF

EnvSeq20:
	db $01, $D0
	db $FE
	db $01, $00
	db $FF

EnvSeq21:
	db $01, $E0
	db $FE
	db $01, $00
	db $FF

EnvSeq22:
	db $01, $F0
	db $FE
	db $01, $00
	db $FF

UnusedSeq_60F8:
	db $0F, $F7
	db $03, $C0
	db $03, $80
	db $FE
	db $03, $70
	db $02, $40
	db $01, $10
	db $FF

UnusedSeq_6106:
	db $01, $80
	db $03, $A0
	db $03, $60
	db $FE
	db $02, $40
	db $01, $10
	db $FF

UnusedSeq_6112:
	db $03, $F0
	db $03, $80
	db $FE
	db $08, $20
	db $01, $00
	db $FF

UnusedSeq_611C:
	db $03, $F0
	db $03, $C0
	db $03, $80
	db $FE
	db $03, $70
	db $02, $40
	db $01, $10
	db $FF

UnusedSeq_612A:
	db $03, $20
	db $FE
	db $03, $40
	db $02, $60
	db $01, $00
	db $FF

;Waveforms, copied into wave RAM by LoadWaveMus/LoadWaveSFX.
WaveTab:
	dw Waveform00
	dw Waveform01
	dw Waveform02
	dw Waveform03
	dw Waveform04
	dw Waveform05
	dw Waveform06
	dw Waveform07
	dw Waveform08
	dw Waveform09
	dw Waveform09
	dw Waveform09
	dw Waveform09
	dw Waveform09
	dw Waveform09
	dw Waveform09

Waveform00:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $ED, $CB, $A9, $87, $65, $43, $21, $00

Waveform01:
	db $02, $46, $8A, $CE, $FF, $FF, $FF, $FF, $EC, $A8, $64, $20, $00, $00, $00, $00

Waveform02:
	db $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF

Waveform03:
	db $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF

Waveform04:
	db $FE, $DC, $BA, $98, $76, $54, $32, $10, $76, $54, $32, $10, $44, $00, $22, $00

Waveform05:
	db $79, $8F, $FC, $CF, $FD, $B9, $75, $31, $76, $54, $32, $10, $44, $00, $22, $00

Waveform06:
	db $03, $69, $CF, $FC, $96, $30, $03, $56, $77, $65, $44, $33, $20, $00, $52, $00

Waveform07:
	db $01, $21, $45, $67, $01, $21, $45, $67, $FE, $DC, $BA, $98, $76, $54, $32, $10

Waveform08:
	db $01, $11, $12, $23, $34, $45, $56, $67, $78, $89, $9A, $AB, $BC, $CD, $DD, $D0

Waveform09:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $ED, $CB, $A9, $87, $65, $43, $21, $00

EnvSeq23:
	db $0A, $61
	db $FF

SFX01D:
	db $87, $01
	db $8E, $F4, $61
	db $10, $0A, $00
	db $FF

EnvSeq24:
	db $0A, $64
	db $FF

SFX02D:
	db $87, $01
	db $8E, $00, $62
	db $10, $08, $08
	db $FF

EnvSeq25:
	db $0A, $61
	db $01, $08
	db $FF

SFX03D:
	db $87, $01
	db $8E, $0C, $62
	db $17, $08, $08
	db $FF

EnvSeq26:
	db $07, $81
	db $01, $08
	db $FF

SFX04D:
	db $87, $01
	db $8E, $1A, $62
	db $17, $08, $08
	db $FF

EnvSeq27:
	db $05, $51
	db $01, $00
	db $FF

SFX05D:
	db $87, $01
	db $8E, $28, $62
	db $49, $01, $00
	db $4C, $02, $00
	db $FF

EnvSeq28:
	db $2C, $B4
	db $FF

SFX06D:
	db $87, $01
	db $8E, $39, $62
	db $10, $2C, $00
	db $FF

Mus60:
	db %00001111		;Channel mask
	db 0				;Priority
	db AudioBank5		;ROM bank holding this song's channel data
	dw Mus60A
	dw Mus60B
	dw Mus60C
	dw Mus60D

Mus61:
	db %00001111		;Channel mask
	db 0				;Priority
	db AudioBank3		;ROM bank holding this song's channel data
	dw Mus61A
	dw Mus61B
	dw Mus61C
	dw Mus61D

Mus62:
	db %00001111		;Channel mask
	db 0				;Priority
	db AudioBank5		;ROM bank holding this song's channel data
	dw Mus62A
	dw Mus62B
	dw Mus62C
	dw Mus62D

Mus63:
	db %00001111		;Channel mask
	db 0				;Priority
	db AudioBank3		;ROM bank holding this song's channel data
	dw Mus63A
	dw Mus63B
	dw Mus63C
	dw Mus63D

Mus64:
	db %00001111		;Channel mask
	db 0				;Priority
	db AudioBank3		;ROM bank holding this song's channel data
	dw Mus64A
	dw Mus64B
	dw Mus64C
	dw Mus64D

Mus65:
	db %00001111		;Channel mask
	db 0				;Priority
	db AudioBank2		;ROM bank holding this song's channel data
	dw Mus65A
	dw Mus65B
	dw Mus65C
	dw Mus65D

Mus66:
	db %00001111		;Channel mask
	db 0				;Priority
	db AudioBank2		;ROM bank holding this song's channel data
	dw Mus66A
	dw Mus66B
	dw Mus66C
	dw Mus66D

Mus67:
	db %00001111		;Channel mask
	db 0				;Priority
	db AudioBank4		;ROM bank holding this song's channel data
	dw Mus67A
	dw Mus67B
	dw Mus67C
	dw Mus67D

Mus68:
	db %00001111		;Channel mask
	db 0				;Priority
	db AudioBank3		;ROM bank holding this song's channel data
	dw Mus68A
	dw Mus68B
	dw Mus68C
	dw Mus68D

Mus69:
	db %00001111		;Channel mask
	db 0				;Priority
	db AudioBank3		;ROM bank holding this song's channel data
	dw Mus69A
	dw Mus69B
	dw Mus69C
	dw Mus69D

EnvSeq29:
	db $0A, $C2
	db $01, $70
	db $FE
	db $10, $20
	db $10, $10
	db $7F, $00
	db $FF

VibSeq07:
	db $25
	db $03, $02
	db $01, $00
	db $03, $FE
	db $01, $00
	db $FF

VibSeq08:
	db $7F
	db $7F, $00
	db $FF

Mus6AB:
	db $87, $01
	db $81, $F4
	db $95
	db $85, $00
	db $8E, $B3, $62
	db $8C, $BF, $62
	db $85, $22
	db $26, $25, $00
	db $2F, $4A, $00
	db $2D, $12, $00
	db $2B, $13, $00
	db $2A, $1C, $00
	db $2B, $09, $00
	db $30, $4A, $00
	db $2F, $12, $00
	db $2D, $13, $00
	db $2C, $1B, $00
	db $2D, $09, $00
	db $32, $4A, $00
	db $30, $13, $00
	db $2F, $12, $00
	db $2D, $1C, $00
	db $2B, $09, $00
	db $34, $4A, $12
	db $32, $13, $00
	db $34, $12, $00
	db $36, $13, $00
	db $37, $4A, $00
	db $36, $25, $00
	db $34, $20, $05
	db $32, $24, $00
	db $2B, $25, $00
	db $34, $19, $00
	db $32, $19, $00
	db $30, $18, $00
	db $2F, $4A, $00
	db $2D, $37, $00
	db $28, $13, $00
	db $2D, $65, $0A
	db $26, $25, $00
	db $2F, $49, $00
	db $2D, $13, $00
	db $2B, $12, $00
	db $2A, $1C, $00
	db $2B, $09, $00
	db $30, $4A, $00
	db $2F, $13, $00
	db $2D, $12, $00
	db $2C, $1C, $00
	db $2D, $09, $00
	db $32, $4A, $00
	db $30, $12, $00
	db $2F, $13, $00
	db $2D, $1B, $00
	db $2B, $0A, $00
	db $37, $6E, $00
	db $39, $25, $00
	db $3B, $25, $00
	db $39, $1C, $00
	db $37, $09, $00
	db $36, $25, $00
	db $2F, $25, $00
	db $37, $25, $00
	db $36, $1C, $00
	db $34, $09, $00
	db $32, $25, $00
	db $2B, $25, $00
	db $34, $25, $00
	db $32, $1B, $00
	db $30, $0A, $00
	db $2F, $25, $00
	db $2D, $24, $00
	db $2B, $81, $0B, $09
	db $85, $00
	db $8C, $C9, $62
	db $2B, $33, $05
	db $2B, $04, $05
	db $2B, $04, $05
	db $2B, $0E, $04
	db $2B, $0E, $05
	db $2B, $0E, $04
	db $2B, $0E, $05
	db $2B, $1C, $09
	db $2B, $1B, $0A
	db $2B, $17, $01
	db $2B, $17, $02
	db $2B, $17, $02
	db $34, $49, $00
	db $32, $1C, $09
	db $2B, $0A, $03
	db $2B, $09, $03
	db $2B, $0C, $00
	db $34, $4A, $00
	db $32, $41, $09
	db $2B, $33, $04
	db $2B, $05, $05
	db $2B, $04, $05
	db $2B, $0E, $04
	db $2B, $0E, $05
	db $2B, $0E, $04
	db $2B, $0E, $05
	db $2B, $1B, $0A
	db $2B, $1B, $09
	db $2B, $18, $01
	db $2B, $17, $02
	db $2B, $17, $01
	db $36, $25, $00
	db $34, $45, $05
	db $34, $1C, $00
	db $36, $09, $00
	db $37, $4A, $00
	db $39, $4A, $00
	db $3C, $25, $00
	db $3B, $17, $04
	db $3B, $0A, $00
	db $39, $24, $00
	db $37, $23, $02
	db $36, $25, $00
	db $34, $25, $00
	db $32, $21, $04
	db $37, $17, $05
	db $37, $09, $00
	db $36, $4A, $00
	db $34, $4A, $00
	db $32, $81, $5D, $25
	db $96, $00

EnvSeq2A:
	db $06, $20
	db $20, $40
	db $FE
	db $06, $60
	db $01, $00
	db $FF

Mus6AC:
	db $87, $01
	db $82, $07
	db $8E, $41, $64
	db $95
	db $00, $00, $25
	db $13, $13, $00
	db $1A, $12, $00
	db $23, $12, $00
	db $1A, $13, $00
	db $13, $12, $00
	db $1A, $13, $00
	db $23, $12, $00
	db $1A, $13, $00
	db $13, $12, $00
	db $1B, $13, $00
	db $21, $12, $00
	db $1B, $13, $00
	db $13, $12, $00
	db $1B, $20, $05
	db $1B, $12, $00
	db $13, $13, $00
	db $1A, $12, $00
	db $23, $13, $00
	db $1A, $12, $00
	db $13, $13, $00
	db $1F, $12, $00
	db $21, $13, $00
	db $23, $12, $00
	db $26, $20, $05
	db $24, $13, $00
	db $23, $12, $00
	db $21, $12, $00
	db $1E, $13, $00
	db $1A, $12, $00
	db $1B, $13, $00
	db $1C, $12, $00
	db $1F, $13, $00
	db $23, $12, $00
	db $28, $13, $00
	db $26, $20, $05
	db $24, $25, $00
	db $23, $45, $04
	db $24, $19, $00
	db $23, $19, $00
	db $21, $18, $00
	db $26, $4A, $00
	db $25, $2E, $09
	db $25, $13, $00
	db $26, $25, $00
	db $21, $25, $00
	db $1A, $25, $25
	db $13, $12, $00
	db $1A, $13, $00
	db $23, $12, $00
	db $1A, $12, $00
	db $13, $13, $00
	db $1A, $12, $00
	db $23, $13, $00
	db $1A, $12, $00
	db $13, $13, $00
	db $1B, $12, $00
	db $21, $13, $00
	db $1B, $12, $00
	db $13, $13, $00
	db $1B, $20, $05
	db $1B, $12, $00
	db $13, $12, $00
	db $1A, $13, $00
	db $23, $12, $00
	db $1A, $13, $00
	db $13, $12, $00
	db $1F, $13, $00
	db $21, $12, $00
	db $23, $13, $00
	db $24, $25, $00
	db $1F, $12, $00
	db $1C, $13, $00
	db $18, $24, $00
	db $19, $25, $00
	db $1A, $21, $04
	db $1A, $17, $05
	db $1A, $05, $04
	db $1B, $21, $04
	db $1B, $20, $05
	db $1C, $25, $00
	db $1A, $1C, $00
	db $18, $09, $00
	db $17, $25, $00
	db $23, $25, $00
	db $24, $25, $00
	db $23, $1B, $00
	db $21, $0A, $00
	db $1A, $25, $00
	db $24, $20, $04
	db $24, $25, $00
	db $23, $13, $00
	db $21, $12, $00
	db $23, $41, $81, $1D
	db $28, $1C, $09
	db $28, $1B, $0A
	db $26, $17, $01
	db $26, $17, $02
	db $26, $17, $02
	db $24, $49, $00
	db $23, $46, $04
	db $24, $4A, $00
	db $23, $41, $81, $1D
	db $28, $1B, $0A
	db $28, $1B, $09
	db $26, $18, $01
	db $26, $17, $02
	db $26, $17, $01
	db $24, $21, $04
	db $24, $45, $05
	db $24, $17, $05
	db $24, $09, $00
	db $28, $4A, $00
	db $27, $4A, $00
	db $26, $25, $00
	db $1A, $17, $04
	db $1A, $0A, $00
	db $1B, $24, $00
	db $1C, $23, $02
	db $26, $25, $00
	db $24, $25, $00
	db $23, $25, $00
	db $22, $17, $05
	db $22, $09, $00
	db $21, $45, $05
	db $21, $25, $00
	db $15, $25, $00
	db $1A, $2E, $03
	db $1A, $09, $03
	db $1A, $0D, $00
	db $1C, $0D, $05
	db $1C, $13, $00
	db $1D, $0D, $05
	db $1D, $0E, $04
	db $1D, $1C, $09
	db $1D, $1C, $09
	db $1E, $25, $00
	db $96, $00
	db $FF

EnvSeq2B:
	db $0A, $92
	db $01, $40
	db $FE
	db $10, $20
	db $7F, $00
	db $FF

UnusedSeq_65FD:
	db $0A, $A2
	db $01, $50
	db $FE
	db $10, $20
	db $7F, $00
	db $FF

Mus6AA:
	db $87, $01
	db $81, $F4
	db $85, $11
	db $8E, $F3, $65
	db $95
	db $00, $00, $25
	db $26, $4A, $00
	db $24, $12, $00
	db $23, $13, $00
	db $21, $1C, $00
	db $23, $09, $00
	db $27, $4A, $00
	db $26, $12, $00
	db $24, $13, $00
	db $23, $1B, $00
	db $24, $09, $00
	db $2A, $4A, $00
	db $29, $4A, $00
	db $28, $4A, $00
	db $2A, $12, $00
	db $30, $13, $00
	db $2F, $12, $00
	db $2D, $13, $00
	db $2B, $81, $0F, $05
	db $2B, $45, $04
	db $2B, $16, $03
	db $2B, $16, $03
	db $2B, $15, $03
	db $2B, $45, $05
	db $2B, $37, $00
	db $28, $13, $00
	db $2B, $4A, $00
	db $2A, $25, $00
	db $26, $1B, $0A
	db $26, $49, $00
	db $24, $13, $00
	db $23, $12, $00
	db $21, $1C, $00
	db $23, $09, $00
	db $27, $4A, $00
	db $26, $13, $00
	db $24, $12, $00
	db $23, $1C, $00
	db $24, $09, $00
	db $2A, $4A, $00
	db $29, $4A, $00
	db $28, $6E, $00
	db $34, $25, $00
	db $32, $25, $00
	db $30, $1C, $00
	db $2F, $09, $00
	db $2D, $1C, $09
	db $2D, $1C, $09
	db $2B, $20, $05
	db $2B, $17, $05
	db $2B, $04, $05
	db $2B, $45, $05
	db $2B, $45, $05
	db $2B, $25, $00
	db $2A, $24, $00
	db $26, $81, $0B, $09
	db $83, $FF
	db $2B, $33, $05
	db $2B, $04, $05
	db $2B, $04, $05
	db $2A, $0E, $04
	db $2A, $0E, $05
	db $2A, $0E, $04
	db $2A, $0E, $05
	db $28, $1C, $09
	db $28, $1B, $0A
	db $2A, $17, $01
	db $2A, $17, $02
	db $2A, $17, $02
	db $2B, $45, $04
	db $2B, $1C, $09
	db $2B, $0A, $03
	db $2B, $09, $03
	db $2B, $09, $03
	db $2B, $45, $05
	db $2B, $41, $09
	db $2B, $33, $04
	db $2B, $05, $05
	db $2B, $04, $05
	db $2A, $0E, $04
	db $2A, $0E, $05
	db $2A, $0E, $04
	db $2A, $0E, $05
	db $28, $1B, $0A
	db $28, $1B, $09
	db $2A, $18, $01
	db $2A, $17, $02
	db $2A, $17, $01
	db $2B, $21, $04
	db $2B, $45, $05
	db $2B, $17, $05
	db $2B, $09, $00
	db $30, $45, $05
	db $30, $4A, $00
	db $34, $25, $00
	db $32, $17, $04
	db $32, $0A, $00
	db $30, $24, $00
	db $2F, $23, $02
	db $2B, $21, $04
	db $2B, $21, $04
	db $2B, $21, $04
	db $32, $17, $05
	db $32, $04, $05
	db $32, $45, $05
	db $2D, $25, $00
	db $2B, $25, $00
	db $2A, $2E, $03
	db $2A, $09, $03
	db $2A, $0D, $00
	db $2B, $0D, $05
	db $2B, $13, $00
	db $2C, $0D, $05
	db $2C, $0E, $04
	db $2C, $1C, $09
	db $2C, $1C, $09
	db $2D, $25, $00
	db $83, $00
	db $96, $00
	db $FF

Mus6AD:
	db $87, $01
	db $95
	db $00, $00, $25
	db $0E, $03, $00
	db $0E, $22, $6F
	db $0E, $03, $00
	db $0E, $22, $6E
	db $0E, $04, $00
	db $0E, $21, $25
	db $0E, $03, $00
	db $0E, $22, $25
	db $0E, $03, $00
	db $0E, $22, $6F
	db $0E, $03, $00
	db $0E, $22, $25
	db $0E, $12, $00
	db $0E, $09, $00
	db $0E, $0A, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $0A, $00
	db $0E, $09, $00
	db $0E, $12, $00
	db $0E, $09, $00
	db $0E, $0A, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $03, $00
	db $0E, $04, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $04, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $13, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $0A, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $13, $00
	db $0E, $12, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $0A, $00
	db $0E, $09, $00
	db $0E, $12, $00
	db $0E, $0A, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $0A, $00
	db $0E, $09, $00
	db $0E, $25, $25
	db $0E, $03, $00
	db $0E, $22, $6E
	db $0E, $03, $00
	db $0E, $22, $6F
	db $0E, $03, $00
	db $0E, $22, $25
	db $0E, $03, $00
	db $0E, $22, $25
	db $0E, $03, $00
	db $0E, $22, $00
	db $0E, $03, $00
	db $0E, $22, $00
	db $0E, $03, $00
	db $0E, $21, $25
	db $0E, $13, $00
	db $0E, $12, $00
	db $0E, $0A, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $13, $00
	db $0E, $12, $00
	db $0E, $09, $00
	db $0E, $0A, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $13, $00
	db $0E, $12, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $0A, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $13, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $0A, $00
	db $0E, $09, $00
	db $0E, $12, $00
	db $0E, $13, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $0A, $00
	db $0E, $12, $00
	db $0E, $13, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $13, $00
	db $0E, $12, $00
	db $0E, $0A, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $04, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $04, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $03
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $04, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $04
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $12, $00
	db $0E, $0A, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $0A, $00
	db $0E, $09, $00
	db $0E, $12, $00
	db $0E, $13, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $0A, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $04, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $04, $00
	db $0E, $12, $00
	db $0E, $12, $00
	db $0E, $0A, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $25, $00
	db $0E, $0D, $00
	db $0E, $0C, $00
	db $0E, $0C, $00
	db $0E, $13, $00
	db $0E, $12, $00
	db $0E, $09, $00
	db $0E, $0A, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $13, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $0A, $00
	db $0E, $09, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $04, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $03
	db $0E, $0A, $00
	db $0E, $09, $00
	db $0E, $12, $00
	db $0E, $09, $00
	db $0E, $0A, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $0A, $00
	db $0E, $12, $00
	db $0E, $13, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $04, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $04, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $13, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $0A, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $13, $00
	db $0E, $12, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $04, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $12, $00
	db $0E, $13, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $0A, $00
	db $0E, $09, $00
	db $0E, $12, $00
	db $0E, $0A, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $0A, $00
	db $0E, $12, $00
	db $0E, $13, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $0A, $00
	db $0E, $12, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $0A, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $13, $00
	db $0E, $12, $00
	db $0E, $0A, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $0A, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $13, $00
	db $0E, $09, $00
	db $0E, $13, $00
	db $0E, $12, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $0A, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $0A, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $13, $00
	db $0E, $09, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $04, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $0C, $00
	db $0E, $0C, $00
	db $0E, $0D, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $04, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $13, $00
	db $0E, $12, $00
	db $0E, $0A, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $25, $00
	db $96, $00
	db $FF

Mus6A:
	db %00001111		;Channel mask
	db 0				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw Mus6AA
	dw Mus6AB
	dw Mus6AC
	dw Mus6AD

Mus6B:
	db %00001111		;Channel mask
	db 0				;Priority
	db AudioBank2		;ROM bank holding this song's channel data
	dw Mus6BA
	dw Mus6BB
	dw Mus6BC
	dw Mus6BD

Mus6C:
	db %00001111		;Channel mask
	db 0				;Priority
	db AudioBank4		;ROM bank holding this song's channel data
	dw Mus6CA
	dw Mus6CB
	dw Mus6CC
	dw Mus6CD

Mus6D:
	db %00001111		;Channel mask
	db 0				;Priority
	db AudioBank6		;ROM bank holding this song's channel data
	dw Mus6DA
	dw Mus6DB
	dw Mus6DC
	dw Mus6DD

Mus6E:
	db %00001111		;Channel mask
	db 0				;Priority
	db AudioBank5		;ROM bank holding this song's channel data
	dw Mus6EA
	dw Mus6EB
	dw Mus6EC
	dw Mus6ED

Mus6F:
	db %00001111		;Channel mask
	db 0				;Priority
	db AudioBank5		;ROM bank holding this song's channel data
	dw Mus6FA
	dw Mus6FB
	dw Mus6FC
	dw EmptyTrack2

Mus70:
	db %00001111		;Channel mask
	db 0				;Priority
	db AudioBank6		;ROM bank holding this song's channel data
	dw Mus70A
	dw Mus70B
	dw Mus70C
	dw Mus70D

Mus71:
	db %00001111		;Channel mask
	db 0				;Priority
	db AudioBank2		;ROM bank holding this song's channel data
	dw Mus71A
	dw Mus71B
	dw Mus71C
	dw Mus71D

Mus72:
	db %00001111		;Channel mask
	db 0				;Priority
	db AudioBank5		;ROM bank holding this song's channel data
	dw Mus72A
	dw Mus72B
	dw Mus72C
	dw Mus72D

EnvSeq2C:
	db $0A, $C2
	db $01, $70
	db $FE
	db $7F, $27
	db $FF

EnvSeq2D:
	db $01, $80
	db $FE
	db $7F, $27
	db $FF

VibSeq09:
	db $23
	db $03, $02
	db $01, $00
	db $03, $FE
	db $01, $00
	db $FF

VibSeq0A:
	db $23
	db $03, $01
	db $01, $00
	db $03, $FF
	db $01, $00
	db $FF

VibSeq0B:
	db $19
	db $02, $02
	db $02, $00
	db $02, $FE
	db $02, $00
	db $FF

Mus73B:
	db $87, $01
	db $81, $F4
	db $85, $00
	db $8E, $A1, $6C
	db $8C, $AF, $6C
	db $00, $00, $22
	db $24, $31, $02
	db $24, $07, $02
	db $24, $06, $03
	db $2B, $1E, $04
	db $29, $0B, $00
	db $2B, $0C, $00
	db $2D, $0B, $00
	db $2B, $81, $05, $04
	db $24, $32, $02
	db $24, $06, $02
	db $24, $07, $02
	db $2B, $62, $05
	db $29, $0B, $00
	db $2B, $0C, $00
	db $2D, $0B, $00
	db $2B, $1E, $04
	db $29, $0C, $00
	db $2B, $0B, $00
	db $2D, $0C, $00
	db $2B, $1E, $04
	db $24, $0B, $0C
	db $24, $0B, $00
	db $30, $22, $00
	db $32, $45, $11
	db $2B, $09, $00
	db $2D, $08, $00
	db $2F, $09, $00
	db $30, $08, $00
	db $32, $09, $00
	db $34, $09, $00
	db $35, $1E, $04
	db $35, $11, $00
	db $34, $22, $00
	db $30, $23, $00
	db $33, $2F, $04
	db $33, $11, $00
	db $32, $22, $00
	db $2E, $23, $00
	db $31, $2F, $04
	db $31, $11, $00
	db $30, $23, $00
	db $2C, $1E, $04
	db $2C, $22, $00
	db $2E, $0D, $04
	db $2E, $63, $04
	db $2E, $2F, $05
	db $2E, $06, $02
	db $2E, $07, $02
	db $2E, $2F, $04
	db $2E, $07, $02
	db $2E, $06, $02
	db $2E, $07, $0A
	db $2E, $07, $02
	db $2E, $06, $03
	db $2E, $81, $4D, $23
	db $8E, $A9, $6C
	db $8C, $C3, $6C
	db $85, $22
	db $2B, $15, $04
	db $2B, $07, $02
	db $2B, $22, $00
	db $30, $2F, $05
	db $2B, $11, $00
	db $30, $11, $00
	db $32, $11, $00
	db $34, $22, $00
	db $30, $23, $00
	db $3C, $33, $00
	db $3B, $09, $00
	db $39, $08, $00
	db $37, $22, $00
	db $30, $30, $04
	db $30, $11, $00
	db $32, $11, $00
	db $34, $0D, $04
	db $34, $1A, $00
	db $35, $09, $00
	db $32, $40, $04
	db $2B, $16, $04
	db $2B, $04, $04
	db $2B, $23, $00
	db $30, $2F, $04
	db $2B, $11, $00
	db $30, $11, $00
	db $32, $12, $00
	db $34, $22, $00
	db $30, $22, $00
	db $3C, $22, $00
	db $3B, $1A, $00
	db $39, $09, $00
	db $38, $22, $00
	db $2F, $45, $00
	db $36, $0B, $00
	db $38, $0B, $00
	db $39, $0C, $00
	db $38, $5E, $09
	db $8C, $B9, $6C
	db $8E, $A1, $6C
	db $85, $00
	db $34, $22, $00
	db $3C, $2F, $04
	db $3C, $0D, $05
	db $3C, $11, $00
	db $3B, $11, $00
	db $37, $1A, $00
	db $34, $08, $00
	db $39, $2F, $05
	db $39, $0C, $05
	db $39, $11, $00
	db $37, $11, $00
	db $34, $1A, $00
	db $30, $08, $00
	db $35, $23, $00
	db $34, $19, $00
	db $35, $09, $00
	db $37, $22, $00
	db $32, $22, $00
	db $35, $23, $00
	db $34, $22, $00
	db $32, $22, $00
	db $30, $1E, $05
	db $39, $2F, $04
	db $39, $11, $00
	db $3B, $11, $00
	db $34, $11, $00
	db $33, $12, $00
	db $34, $11, $00
	db $3E, $22, $00
	db $3C, $1A, $00
	db $3B, $08, $00
	db $3C, $1A, $09
	db $39, $0B, $00
	db $3B, $0B, $00
	db $3C, $0C, $00
	db $3B, $22, $00
	db $37, $22, $00
	db $32, $23, $00
	db $39, $22, $00
	db $37, $81, $4E, $22
	db $8E, $A9, $6C
	db $8C, $C3, $6C
	db $85, $22
	db $2B, $15, $05
	db $2B, $06, $02
	db $2B, $23, $00
	db $30, $2F, $04
	db $2B, $11, $00
	db $30, $11, $00
	db $32, $11, $00
	db $34, $23, $00
	db $30, $22, $00
	db $3C, $33, $00
	db $3B, $09, $00
	db $39, $09, $00
	db $37, $22, $00
	db $30, $2F, $04
	db $30, $11, $00
	db $32, $12, $00
	db $34, $0C, $05
	db $34, $19, $00
	db $35, $09, $00
	db $32, $40, $05
	db $2B, $15, $04
	db $2B, $05, $04
	db $2B, $22, $00
	db $30, $2F, $05
	db $2B, $11, $00
	db $30, $11, $00
	db $32, $11, $00
	db $34, $22, $00
	db $30, $23, $00
	db $3C, $22, $00
	db $3B, $1A, $00
	db $39, $08, $00
	db $38, $22, $00
	db $2F, $45, $00
	db $36, $0B, $00
	db $38, $0C, $00
	db $39, $0B, $00
	db $38, $5F, $08
	db $8C, $B9, $6C
	db $8E, $A1, $6C
	db $85, $00
	db $34, $22, $00
	db $3C, $30, $04
	db $3C, $0D, $04
	db $3C, $11, $00
	db $3B, $11, $00
	db $37, $1A, $00
	db $34, $09, $00
	db $39, $2F, $04
	db $39, $0D, $04
	db $39, $11, $00
	db $37, $11, $00
	db $34, $1A, $00
	db $30, $09, $00
	db $35, $22, $00
	db $34, $1A, $00
	db $35, $08, $00
	db $37, $23, $00
	db $32, $22, $00
	db $35, $22, $00
	db $34, $22, $00
	db $32, $23, $00
	db $30, $1E, $04
	db $39, $2F, $04
	db $39, $12, $00
	db $3B, $11, $00
	db $34, $11, $00
	db $33, $11, $00
	db $34, $11, $00
	db $3C, $34, $00
	db $3B, $08, $00
	db $3C, $09, $00
	db $3E, $1E, $04
	db $3C, $1A, $00
	db $3E, $08, $00
	db $40, $1A, $09
	db $34, $0B, $00
	db $37, $09, $02
	db $37, $09, $03
	db $37, $0B, $00
	db $3C, $09, $03
	db $3C, $08, $03
	db $3C, $0C, $00
	db $40, $08, $03
	db $40, $0B, $00
	db $3E, $1A, $09
	db $32, $0B, $00
	db $37, $09, $03
	db $37, $08, $03
	db $37, $0B, $00
	db $3B, $09, $03
	db $3B, $08, $03
	db $3B, $0C, $00
	db $3E, $08, $03
	db $3E, $0C, $00
	db $3C, $19, $09
	db $3C, $1A, $08
	db $3C, $1A, $08
	db $3C, $1A, $09
	db $3C, $19, $09
	db $3C, $1A, $08
	db $3C, $1A, $09
	db $3C, $19, $09
	db $3C, $1A, $2A
	db $40, $1A, $2B
	db $24, $09, $00
	db $24, $81, $1E, $04
	db $3C, $09, $03
	db $3C, $08, $03
	db $3C, $09, $03
	db $3C, $11, $11
	db $30, $1A, $00
	db $FF

EnvSeq2E:
	db $0A, $B2
	db $01, $60
	db $FE
	db $7F, $27
	db $FF

UnusedSeq_6FDF:
	db $01, $70
	db $FE
	db $7F, $27
	db $FF

VibSeq0C:
	db $23
	db $03, $01
	db $01, $00
	db $03, $FF
	db $01, $00
	db $FF

Mus73A:
	db $87, $01
	db $85, $00
	db $8E, $D7, $6F
	db $8C, $E5, $6F
	db $81, $F4
	db $00, $00, $81, $14
	db $28, $0C, $00
	db $29, $0B, $00
	db $26, $81, $05, $49
	db $26, $62, $10
	db $28, $0C, $00
	db $29, $0B, $00
	db $26, $1E, $10
	db $28, $0B, $00
	db $29, $0C, $00
	db $26, $1E, $26
	db $29, $22, $00
	db $30, $45, $45
	db $32, $1E, $04
	db $32, $11, $00
	db $2B, $22, $00
	db $29, $23, $00
	db $30, $2F, $04
	db $30, $11, $00
	db $29, $22, $00
	db $27, $23, $00
	db $2E, $2F, $04
	db $2E, $11, $00
	db $27, $23, $00
	db $24, $1E, $04
	db $24, $22, $00
	db $29, $0D, $04
	db $29, $63, $04
	db $29, $2F, $05
	db $29, $06, $02
	db $29, $07, $02
	db $29, $2F, $04
	db $29, $07, $02
	db $29, $06, $02
	db $29, $07, $0A
	db $29, $07, $02
	db $29, $06, $03
	db $29, $81, $4D, $81, $4E
	db $2B, $22, $00
	db $83, $FF
	db $30, $34, $00
	db $83, $00
	db $2B, $11, $00
	db $30, $11, $00
	db $32, $11, $00
	db $34, $22, $00
	db $83, $FF
	db $30, $34, $00
	db $83, $00
	db $28, $11, $00
	db $29, $11, $00
	db $2B, $0D, $04
	db $2B, $1A, $00
	db $2D, $09, $00
	db $29, $40, $04
	db $29, $16, $04
	db $29, $08, $00
	db $28, $41, $04
	db $83, $FF
	db $2B, $1E, $04
	db $2B, $11, $00
	db $83, $00
	db $29, $12, $00
	db $28, $11, $00
	db $2B, $11, $00
	db $83, $FF
	db $30, $11, $00
	db $83, $00
	db $32, $11, $00
	db $34, $45, $11
	db $20, $11, $00
	db $23, $0B, $00
	db $28, $0C, $00
	db $2A, $0B, $00
	db $2C, $11, $00
	db $28, $12, $00
	db $30, $22, $00
	db $2F, $5E, $09
	db $83, $FF
	db $34, $1E, $04
	db $83, $00
	db $34, $2F, $04
	db $34, $0D, $05
	db $34, $11, $00
	db $32, $11, $00
	db $2F, $1A, $00
	db $2B, $08, $00
	db $30, $2F, $05
	db $30, $0C, $05
	db $30, $11, $00
	db $2F, $11, $00
	db $2B, $1A, $00
	db $28, $08, $00
	db $30, $67, $00
	db $2F, $22, $00
	db $2D, $23, $00
	db $2B, $22, $00
	db $29, $22, $00
	db $28, $1E, $05
	db $30, $2F, $04
	db $30, $11, $00
	db $32, $11, $00
	db $2C, $11, $00
	db $2B, $12, $00
	db $2C, $11, $00
	db $35, $22, $00
	db $34, $1A, $00
	db $32, $08, $00
	db $34, $1E, $05
	db $37, $08, $03
	db $37, $09, $02
	db $37, $09, $03
	db $37, $22, $00
	db $2F, $22, $00
	db $2B, $23, $00
	db $2A, $22, $00
	db $83, $FF
	db $2B, $2F, $04
	db $2B, $05, $04
	db $2B, $09, $00
	db $83, $00
	db $2D, $2F, $04
	db $2D, $04, $05
	db $2D, $08, $00
	db $2E, $1A, $08
	db $2E, $1A, $09
	db $2F, $19, $81, $34
	db $2B, $23, $00
	db $83, $FF
	db $30, $33, $00
	db $83, $00
	db $2B, $11, $00
	db $30, $11, $00
	db $32, $12, $00
	db $34, $22, $00
	db $83, $FF
	db $30, $33, $00
	db $83, $00
	db $28, $11, $00
	db $29, $12, $00
	db $2B, $0C, $05
	db $2B, $19, $00
	db $2D, $09, $00
	db $29, $40, $05
	db $29, $15, $04
	db $29, $09, $00
	db $28, $40, $04
	db $83, $FF
	db $2B, $1E, $05
	db $2B, $11, $00
	db $83, $00
	db $29, $11, $00
	db $28, $11, $00
	db $2B, $11, $00
	db $83, $FF
	db $30, $11, $00
	db $83, $00
	db $32, $12, $00
	db $34, $44, $11
	db $20, $11, $00
	db $23, $0C, $00
	db $28, $0B, $00
	db $2A, $0C, $00
	db $2C, $11, $00
	db $28, $11, $00
	db $30, $22, $00
	db $2F, $5F, $08
	db $83, $FF
	db $34, $1E, $04
	db $83, $00
	db $34, $30, $04
	db $34, $0D, $04
	db $34, $11, $00
	db $32, $11, $00
	db $2F, $1A, $00
	db $2B, $09, $00
	db $30, $2F, $04
	db $30, $0D, $04
	db $30, $11, $00
	db $2F, $11, $00
	db $2B, $1A, $00
	db $28, $09, $00
	db $30, $67, $00
	db $2F, $22, $00
	db $2D, $22, $00
	db $2B, $22, $00
	db $29, $23, $00
	db $28, $1E, $04
	db $30, $2F, $04
	db $30, $12, $00
	db $32, $11, $00
	db $2C, $11, $00
	db $2B, $11, $00
	db $2C, $11, $00
	db $34, $45, $00
	db $35, $44, $00
	db $37, $1A, $09
	db $2B, $0B, $00
	db $30, $09, $02
	db $30, $09, $03
	db $30, $0B, $00
	db $34, $09, $03
	db $34, $08, $03
	db $34, $0C, $00
	db $37, $08, $03
	db $37, $0B, $00
	db $35, $1A, $09
	db $2B, $0B, $00
	db $2F, $09, $03
	db $2F, $08, $03
	db $2F, $0B, $00
	db $32, $09, $03
	db $32, $08, $03
	db $32, $0C, $00
	db $37, $08, $03
	db $37, $0C, $00
	db $34, $19, $09
	db $33, $1A, $08
	db $34, $1A, $08
	db $33, $1A, $09
	db $34, $19, $09
	db $33, $1A, $08
	db $34, $1A, $09
	db $33, $19, $09
	db $34, $1A, $2A
	db $37, $1A, $2B
	db $83, $FF
	db $24, $09, $00
	db $24, $81, $1E, $04
	db $30, $09, $03
	db $30, $08, $03
	db $30, $09, $03
	db $30, $11, $11
	db $24, $1A, $30
	db $83, $00
	db $FF

EnvSeq2F:
	db $06, $20
	db $07, $40
	db $FE
	db $06, $60
	db $01, $00
	db $FF

EnvSeq30:
	db $07, $40
	db $FE
	db $06, $60
	db $01, $00
	db $FF

EnvSeq31:
	db $03, $20
	db $07, $40
	db $FE
	db $06, $60
	db $01, $00
	db $FF

Mus73C:
	db $87, $01
	db $82, $04
	db $8E, $AB, $72
	db $00, $00, $67
	db $24, $1E, $04
	db $26, $0B, $00
	db $24, $0C, $00
	db $22, $0B, $00
	db $24, $81, $05, $49
	db $24, $62, $05
	db $26, $0B, $00
	db $24, $0C, $00
	db $22, $0B, $00
	db $24, $1E, $04
	db $26, $0C, $00
	db $24, $0B, $00
	db $22, $0C, $00
	db $24, $1E, $26
	db $21, $22, $00
	db $1F, $45, $45
	db $22, $1E, $04
	db $22, $11, $00
	db $24, $22, $00
	db $21, $23, $00
	db $20, $2F, $04
	db $20, $11, $00
	db $22, $22, $00
	db $1F, $23, $00
	db $1E, $2F, $04
	db $1E, $11, $00
	db $20, $23, $00
	db $1D, $1E, $04
	db $1D, $22, $00
	db $1B, $0D, $04
	db $1B, $63, $04
	db $27, $2F, $05
	db $27, $06, $02
	db $27, $07, $02
	db $27, $2F, $04
	db $27, $07, $02
	db $27, $06, $02
	db $27, $07, $0A
	db $27, $07, $02
	db $27, $06, $03
	db $27, $81, $4D, $45
	db $8E, $B5, $72
	db $18, $0D, $04
	db $1F, $0D, $04
	db $26, $0D, $04
	db $28, $0D, $04
	db $18, $0E, $04
	db $1F, $0D, $04
	db $28, $0D, $04
	db $29, $0D, $04
	db $18, $0D, $04
	db $23, $0D, $04
	db $24, $0D, $04
	db $2B, $0E, $04
	db $18, $0D, $04
	db $1F, $0D, $04
	db $28, $0D, $04
	db $29, $0D, $04
	db $18, $0D, $04
	db $1F, $0D, $04
	db $26, $0E, $04
	db $28, $0D, $04
	db $18, $0D, $04
	db $1F, $0D, $04
	db $24, $0D, $04
	db $2B, $0D, $04
	db $18, $0D, $04
	db $21, $0E, $04
	db $24, $0D, $04
	db $29, $0D, $04
	db $18, $0D, $04
	db $20, $0D, $04
	db $24, $0D, $04
	db $26, $0D, $04
	db $8E, $BD, $72
	db $18, $12, $00
	db $17, $11, $00
	db $16, $22, $00
	db $15, $22, $00
	db $14, $23, $00
	db $13, $44, $00
	db $12, $45, $00
	db $17, $67, $00
	db $8E, $AB, $72
	db $2D, $0B, $00
	db $2C, $0B, $00
	db $2A, $0C, $00
	db $8E, $BD, $72
	db $28, $1E, $04
	db $28, $16, $04
	db $28, $04, $04
	db $28, $12, $11
	db $28, $11, $11
	db $8E, $AB, $72
	db $21, $1A, $08
	db $21, $1A, $09
	db $1F, $19, $09
	db $1F, $1A, $08
	db $1D, $1A, $08
	db $1D, $1A, $09
	db $1C, $19, $09
	db $1C, $1A, $08
	db $1A, $1A, $09
	db $1A, $19, $09
	db $1F, $1A, $08
	db $1F, $1A, $08
	db $18, $1A, $09
	db $18, $19, $09
	db $1A, $1A, $08
	db $1C, $1A, $09
	db $1D, $19, $09
	db $1D, $1A, $08
	db $1C, $1A, $08
	db $1C, $1A, $09
	db $20, $19, $09
	db $20, $1A, $08
	db $21, $1A, $09
	db $1B, $08, $03
	db $1B, $09, $02
	db $1B, $0C, $00
	db $1A, $1A, $08
	db $1A, $1A, $08
	db $1A, $1A, $09
	db $1A, $19, $09
	db $1F, $1A, $08
	db $1F, $1A, $09
	db $1D, $19, $09
	db $1D, $1A, $08
	db $1B, $1A, $08
	db $1B, $1A, $09
	db $1A, $19, $2B
	db $8E, $B5, $72
	db $18, $0D, $04
	db $1F, $0E, $04
	db $26, $0D, $04
	db $28, $0D, $04
	db $18, $0D, $04
	db $1F, $0D, $04
	db $28, $0D, $04
	db $29, $0D, $04
	db $18, $0E, $04
	db $23, $0D, $04
	db $24, $0D, $04
	db $2B, $0D, $04
	db $18, $0D, $04
	db $1F, $0D, $04
	db $28, $0D, $04
	db $29, $0E, $04
	db $18, $0D, $04
	db $1F, $0D, $04
	db $26, $0D, $04
	db $28, $0D, $04
	db $18, $0D, $04
	db $1F, $0D, $04
	db $24, $0E, $04
	db $2B, $0D, $04
	db $18, $0D, $04
	db $21, $0D, $04
	db $24, $0D, $04
	db $29, $0D, $04
	db $18, $0D, $04
	db $20, $0E, $04
	db $24, $0D, $04
	db $26, $0D, $04
	db $8E, $BD, $72
	db $18, $11, $00
	db $17, $11, $00
	db $16, $22, $00
	db $15, $23, $00
	db $14, $22, $00
	db $13, $45, $00
	db $12, $44, $00
	db $17, $67, $00
	db $8E, $AB, $72
	db $2D, $0B, $00
	db $2C, $0C, $00
	db $2A, $0B, $00
	db $8E, $BD, $72
	db $28, $1E, $05
	db $28, $15, $04
	db $28, $05, $04
	db $28, $11, $11
	db $28, $11, $11
	db $8E, $AB, $72
	db $21, $1A, $09
	db $21, $19, $09
	db $1F, $1A, $08
	db $1F, $1A, $09
	db $1D, $19, $09
	db $1D, $1A, $08
	db $1C, $1A, $08
	db $1C, $1A, $09
	db $1A, $19, $09
	db $1A, $1A, $08
	db $1F, $1A, $09
	db $1F, $19, $09
	db $18, $1A, $08
	db $18, $1A, $08
	db $1A, $1A, $09
	db $1C, $19, $09
	db $1D, $1A, $08
	db $1D, $1A, $09
	db $1C, $19, $09
	db $1C, $1A, $08
	db $21, $1A, $08
	db $21, $1A, $09
	db $20, $19, $09
	db $20, $1A, $08
	db $1F, $1A, $09
	db $1F, $19, $09
	db $2B, $0B, $00
	db $28, $0C, $00
	db $24, $0B, $00
	db $1F, $0C, $00
	db $1C, $0B, $00
	db $18, $0B, $00
	db $13, $1A, $09
	db $13, $19, $09
	db $26, $0B, $00
	db $23, $0C, $00
	db $1F, $0B, $00
	db $1A, $0C, $00
	db $17, $0B, $00
	db $13, $0C, $00
	db $18, $19, $09
	db $14, $1A, $08
	db $18, $1A, $08
	db $14, $1A, $09
	db $18, $19, $09
	db $14, $1A, $08
	db $18, $1A, $09
	db $14, $19, $09
	db $18, $1A, $2A
	db $18, $1A, $2B
	db $18, $09, $00
	db $18, $81, $1E, $04
	db $18, $09, $03
	db $18, $08, $03
	db $18, $09, $03
	db $18, $11, $11
	db $0C, $1A, $30
	db $FF

Mus73D:
	db $87, $01
	db $11, $08, $00
	db $11, $09, $00
	db $11, $08, $00
	db $11, $09, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $02
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $03
	db $0E, $0B, $00
	db $0E, $0C, $00
	db $0E, $0B, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $11, $05, $00
	db $11, $06, $00
	db $11, $06, $00
	db $11, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $11, $06, $00
	db $11, $06, $00
	db $11, $05, $00
	db $11, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $03
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $11, $09, $00
	db $11, $08, $00
	db $11, $11, $00
	db $11, $11, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $0B, $00
	db $0E, $0C, $00
	db $0E, $0B, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $0C, $00
	db $0E, $0B, $00
	db $0E, $0C, $00
	db $0E, $02, $20
	db $0E, $0B, $0C
	db $0E, $0B, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $05
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $11, $08, $00
	db $11, $09, $00
	db $11, $08, $09
	db $11, $08, $09
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $08, $09
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $08, $09
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $03
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $08, $09
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $09, $08
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $02
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $08, $09
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $08
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $03
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $11
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $08, $09
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $11, $09, $00
	db $11, $08, $00
	db $11, $09, $09
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $11, $08, $00
	db $11, $09, $00
	db $11, $09, $08
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $08
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $11, $34
	db $0E, $08, $00
	db $0E, $09, $78
	db $0E, $09, $00
	db $0E, $08, $78
	db $0E, $09, $00
	db $0E, $08, $34
	db $0E, $08, $00
	db $0E, $09, $33
	db $0E, $09, $00
	db $0E, $08, $78
	db $0E, $09, $00
	db $0E, $09, $78
	db $0E, $08, $00
	db $0E, $09, $33
	db $0E, $09, $00
	db $0E, $08, $34
	db $0E, $08, $00
	db $0E, $09, $33
	db $0E, $09, $00
	db $0E, $08, $34
	db $0E, $22, $00
	db $0E, $1A, $00
	db $0E, $08, $00
	db $0E, $23, $00
	db $0E, $22, $00
	db $0E, $11, $00
	db $0E, $11, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $03
	db $0E, $11, $00
	db $0E, $11, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $03
	db $0E, $11, $00
	db $0E, $11, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $11, $00
	db $0E, $11, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $03
	db $0E, $11, $00
	db $0E, $12, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $03
	db $0E, $11, $00
	db $0E, $11, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $02
	db $0E, $12, $00
	db $0E, $11, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $11, $00
	db $0E, $11, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $03
	db $0E, $11, $00
	db $0E, $11, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $11, $00
	db $0E, $11, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $11, $00
	db $0E, $11, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $23, $00
	db $0E, $0B, $00
	db $0E, $0B, $00
	db $0E, $0C, $00
	db $0E, $11, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $12, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $11, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $22, $22
	db $0E, $09, $00
	db $0E, $08, $78
	db $0E, $09, $00
	db $0E, $09, $78
	db $0E, $08, $00
	db $0E, $09, $33
	db $0E, $09, $00
	db $0E, $08, $34
	db $0E, $08, $00
	db $0E, $09, $78
	db $0E, $08, $00
	db $0E, $09, $78
	db $0E, $09, $00
	db $0E, $08, $34
	db $0E, $08, $00
	db $0E, $09, $33
	db $0E, $09, $00
	db $0E, $08, $34
	db $0E, $08, $00
	db $0E, $09, $33
	db $0E, $23, $00
	db $0E, $19, $00
	db $0E, $09, $00
	db $0E, $22, $00
	db $0E, $22, $00
	db $0E, $12, $00
	db $0E, $11, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $03
	db $0E, $11, $00
	db $0E, $11, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $03
	db $0E, $11, $00
	db $0E, $11, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $11, $00
	db $0E, $11, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $03
	db $0E, $11, $00
	db $0E, $11, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $03
	db $0E, $11, $00
	db $0E, $12, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $03
	db $0E, $11, $00
	db $0E, $11, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $12, $00
	db $0E, $11, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $03
	db $0E, $11, $00
	db $0E, $11, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $11, $00
	db $0E, $11, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $11, $00
	db $0E, $11, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $11, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $11, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $23, $00
	db $0E, $0B, $00
	db $0E, $0B, $00
	db $0E, $0C, $00
	db $0E, $0B, $00
	db $0E, $0C, $00
	db $0E, $0B, $00
	db $0E, $0C, $00
	db $0E, $0B, $00
	db $0E, $0B, $00
	db $0E, $23, $00
	db $0E, $0B, $00
	db $0E, $0C, $00
	db $0E, $0B, $00
	db $0E, $0B, $00
	db $0E, $0C, $00
	db $0E, $0B, $00
	db $0E, $0C, $00
	db $0E, $0B, $00
	db $0E, $0C, $00
	db $0E, $11, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $11, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $11, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $11, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $08, $00
	db $0E, $09, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $02, $00
	db $0E, $03, $00
	db $0E, $03, $00
	db $0E, $22, $00
	db $0E, $0C, $00
	db $0E, $0B, $00
	db $0E, $0C, $00
	db $0E, $22, $00
	db $0E, $22, $00
	db $FF

Mus73:
	db %00001111		;Channel mask
	db 0				;Priority
	db AudioBank1		;ROM bank holding this song's channel data
	dw Mus73A
	dw Mus73B
	dw Mus73C
	dw Mus73D

Mus74:
	db %00001111		;Channel mask
	db 0				;Priority
	db AudioBank3		;ROM bank holding this song's channel data
	dw Mus74A
	dw Mus74B
	dw Mus74C
	dw Mus74D

Mus75:
	db %00001111		;Channel mask
	db 0				;Priority
	db AudioBank4		;ROM bank holding this song's channel data
	dw Mus75A
	dw Mus75B
	dw Mus75C
	dw Mus75D

Mus76:
	db %00001111		;Channel mask
	db 0				;Priority
	db AudioBank6		;ROM bank holding this song's channel data
	dw Mus76A
	dw Mus76B
	dw Mus76C
	dw Mus76D

Mus77:
	db %00001111		;Channel mask
	db 0				;Priority
	db AudioBank6		;ROM bank holding this song's channel data
	dw Mus77A
	dw Mus77B
	dw Mus77C
	dw Mus77D

Mus78:
	db %00001111		;Channel mask
	db 0				;Priority
	db AudioBank6		;ROM bank holding this song's channel data
	dw Mus78A
	dw Mus78B
	dw EmptyTrack3
	dw Mus78D

Mus79:
	db %00001111		;Channel mask
	db 0				;Priority
	db AudioBank6		;ROM bank holding this song's channel data
	dw Mus79A
	dw Mus79B
	dw Mus79C
	dw Mus79D

Mus7A:
	db %00001111		;Channel mask
	db 0				;Priority
	db AudioBank6		;ROM bank holding this song's channel data
	dw Mus7AA
	dw Mus7AB
	dw Mus7AC
	dw Mus7AD

Mus7B:
	db %00001111		;Channel mask
	db 0				;Priority
	db AudioBank6		;ROM bank holding this song's channel data
	dw Mus7BA
	dw Mus7BB
	dw Mus7BC
	dw Mus7BD

Mus7C:
	db %00001111		;Channel mask
	db 0				;Priority
	db AudioBank6		;ROM bank holding this song's channel data
	dw Mus7CA
	dw Mus7CB
	dw Mus7CC
	dw Mus7CD

Mus7D:
	db %00001111		;Channel mask
	db 0				;Priority
	db AudioBank6		;ROM bank holding this song's channel data
	dw Mus7DA
	dw Mus7DB
	dw Mus7DC
	dw Mus7DD

;Unused space (79 bytes)
	ds 79

SECTION "Audio RAM MusC1", WRAMX[MusC1RAM]
MusC1MusNum: ds 1		;$DE00 = $00
MusC1Priority: ds 1		;$DE01 = $01
MusC1Sweep: ds 1		;$DE02 = $02
MusC1Transpose: ds 1	;$DE03 = $03
MusC1Tuning: ds 1		;$DE04 = $04
MusC1PanMode: ds 1		;$DE05 = $05
MusC1Panning: ds 1		;$DE06 = $06
MusC1Gate: ds 2			;$DE07 = $07
MusC1NoteDelay: ds 2	;$DE09 = $09
MusC1Speed: ds 1		;$DE0B = $0B
MusC1DutyVol: ds 1		;$DE0C = $0C
MusC1Unused0D: ds 1		;$DE0D = $0D
MusC1Unused0E: ds 1		;$DE0E = $0E
MusC1VibSeqPtr: ds 2	;$DE0F = $0F
MusC1EnvSeqPtr: ds 2	;$DE11 = $11
MusC1VibSeqPos: ds 1	;$DE13 = $13
MusC1EnvSeqPos: ds 1	;$DE14 = $14
MusC1VibDelay: ds 1		;$DE15 = $15
MusC1EnvDelay: ds 1		;$DE16 = $16
MusC1Unused17: ds 1		;$DE17 = $17
MusC1VibVal: ds 1		;$DE18 = $18
MusC1FreqOut: ds 2		;$DE19 = $19
MusC1Freq: ds 2			;$DE1B = $1B
MusC1EnvVal: ds 1		;$DE1D = $1D
MusC1SongPos: ds 2		;$DE1E = $1E
MusC1Repeat1Start: ds 2	;$DE20 = $20
MusC1Repeat2Start: ds 2	;$DE22 = $22
MusC1Macro1Pos: ds 2	;$DE24 = $24
MusC1Macro2Pos: ds 2	;$DE26 = $26
MusC1Repeat1Times: ds 1	;$DE28 = $28
MusC1Repeat2Times: ds 1	;$DE29 = $29
MusC1Flags: ds 1		;$DE2A = $2A
MusC1DataBank: ds 1		;$DE2B = $2B

SECTION "Audio RAM MusC2", WRAMX[MusC2RAM]
MusC2MusNum: ds 1		;$DE2C = $00
MusC2Priority: ds 1		;$DE2D = $01
MusC2Sweep: ds 1		;$DE2E = $02
MusC2Transpose: ds 1	;$DE2F = $03
MusC2Tuning: ds 1		;$DE30 = $04
MusC2PanMode: ds 1		;$DE31 = $05
MusC2Panning: ds 1		;$DE32 = $06
MusC2Gate: ds 2			;$DE33 = $07
MusC2NoteDelay: ds 2	;$DE35 = $09
MusC2Speed: ds 1		;$DE37 = $0B
MusC2DutyVol: ds 1		;$DE38 = $0C
MusC2Unused0D: ds 1		;$DE39 = $0D
MusC2Unused0E: ds 1		;$DE3A = $0E
MusC2VibSeqPtr: ds 2	;$DE3B = $0F
MusC2EnvSeqPtr: ds 2	;$DE3D = $11
MusC2VibSeqPos: ds 1	;$DE3F = $13
MusC2EnvSeqPos: ds 1	;$DE40 = $14
MusC2VibDelay: ds 1		;$DE41 = $15
MusC2EnvDelay: ds 1		;$DE42 = $16
MusC2Unused17: ds 1		;$DE43 = $17
MusC2VibVal: ds 1		;$DE44 = $18
MusC2FreqOut: ds 2		;$DE45 = $19
MusC2Freq: ds 2			;$DE47 = $1B
MusC2EnvVal: ds 1		;$DE49 = $1D
MusC2SongPos: ds 2		;$DE4A = $1E
MusC2Repeat1Start: ds 2	;$DE4C = $20
MusC2Repeat2Start: ds 2	;$DE4E = $22
MusC2Macro1Pos: ds 2	;$DE50 = $24
MusC2Macro2Pos: ds 2	;$DE52 = $26
MusC2Repeat1Times: ds 1	;$DE54 = $28
MusC2Repeat2Times: ds 1	;$DE55 = $29
MusC2Flags: ds 1		;$DE56 = $2A
MusC2DataBank: ds 1		;$DE57 = $2B

SECTION "Audio RAM MusC3", WRAMX[MusC3RAM]
MusC3MusNum: ds 1		;$DE58 = $00
MusC3Priority: ds 1		;$DE59 = $01
MusC3Sweep: ds 1		;$DE5A = $02
MusC3Transpose: ds 1	;$DE5B = $03
MusC3Tuning: ds 1		;$DE5C = $04
MusC3PanMode: ds 1		;$DE5D = $05
MusC3Panning: ds 1		;$DE5E = $06
MusC3Gate: ds 2			;$DE5F = $07
MusC3NoteDelay: ds 2	;$DE61 = $09
MusC3Speed: ds 1		;$DE63 = $0B
MusC3DutyVol: ds 1		;$DE64 = $0C
MusC3Unused0D: ds 1		;$DE65 = $0D
MusC3Unused0E: ds 1		;$DE66 = $0E
MusC3VibSeqPtr: ds 2	;$DE67 = $0F
MusC3EnvSeqPtr: ds 2	;$DE69 = $11
MusC3VibSeqPos: ds 1	;$DE6B = $13
MusC3EnvSeqPos: ds 1	;$DE6C = $14
MusC3VibDelay: ds 1		;$DE6D = $15
MusC3EnvDelay: ds 1		;$DE6E = $16
MusC3Unused17: ds 1		;$DE6F = $17
MusC3VibVal: ds 1		;$DE70 = $18
MusC3FreqOut: ds 2		;$DE71 = $19
MusC3Freq: ds 2			;$DE73 = $1B
MusC3EnvVal: ds 1		;$DE75 = $1D
MusC3SongPos: ds 2		;$DE76 = $1E
MusC3Repeat1Start: ds 2	;$DE78 = $20
MusC3Repeat2Start: ds 2	;$DE7A = $22
MusC3Macro1Pos: ds 2	;$DE7C = $24
MusC3Macro2Pos: ds 2	;$DE7E = $26
MusC3Repeat1Times: ds 1	;$DE80 = $28
MusC3Repeat2Times: ds 1	;$DE81 = $29
MusC3Flags: ds 1		;$DE82 = $2A
MusC3DataBank: ds 1		;$DE83 = $2B

SECTION "Audio RAM MusC4", WRAMX[MusC4RAM]
MusC4MusNum: ds 1		;$DE84 = $00
MusC4Priority: ds 1		;$DE85 = $01
MusC4Sweep: ds 1		;$DE86 = $02
MusC4Transpose: ds 1	;$DE87 = $03
MusC4Tuning: ds 1		;$DE88 = $04
MusC4PanMode: ds 1		;$DE89 = $05
MusC4Panning: ds 1		;$DE8A = $06
MusC4Gate: ds 2			;$DE8B = $07
MusC4NoteDelay: ds 2	;$DE8D = $09
MusC4Speed: ds 1		;$DE8F = $0B
MusC4DutyVol: ds 1		;$DE90 = $0C
MusC4Unused0D: ds 1		;$DE91 = $0D
MusC4Unused0E: ds 1		;$DE92 = $0E
MusC4VibSeqPtr: ds 2	;$DE93 = $0F
MusC4EnvSeqPtr: ds 2	;$DE95 = $11
MusC4VibSeqPos: ds 1	;$DE97 = $13
MusC4EnvSeqPos: ds 1	;$DE98 = $14
MusC4VibDelay: ds 1		;$DE99 = $15
MusC4EnvDelay: ds 1		;$DE9A = $16
MusC4Unused17: ds 1		;$DE9B = $17
MusC4VibVal: ds 1		;$DE9C = $18
MusC4FreqOut: ds 2		;$DE9D = $19
MusC4Freq: ds 2			;$DE9F = $1B
MusC4EnvVal: ds 1		;$DEA1 = $1D
MusC4SongPos: ds 2		;$DEA2 = $1E
MusC4Repeat1Start: ds 2	;$DEA4 = $20
MusC4Repeat2Start: ds 2	;$DEA6 = $22
MusC4Macro1Pos: ds 2	;$DEA8 = $24
MusC4Macro2Pos: ds 2	;$DEAA = $26
MusC4Repeat1Times: ds 1	;$DEAC = $28
MusC4Repeat2Times: ds 1	;$DEAD = $29
MusC4Flags: ds 1		;$DEAE = $2A
MusC4DataBank: ds 1		;$DEAF = $2B

SECTION "Audio RAM SFXC1", WRAMX[SFXC1RAM]
SFXC1MusNum: ds 1		;$DEB0 = $00
SFXC1Priority: ds 1		;$DEB1 = $01
SFXC1Sweep: ds 1		;$DEB2 = $02
SFXC1Transpose: ds 1	;$DEB3 = $03
SFXC1Tuning: ds 1		;$DEB4 = $04
SFXC1PanMode: ds 1		;$DEB5 = $05
SFXC1Panning: ds 1		;$DEB6 = $06
SFXC1Gate: ds 2			;$DEB7 = $07
SFXC1NoteDelay: ds 2	;$DEB9 = $09
SFXC1Speed: ds 1		;$DEBB = $0B
SFXC1DutyVol: ds 1		;$DEBC = $0C
SFXC1Unused0D: ds 1		;$DEBD = $0D
SFXC1Unused0E: ds 1		;$DEBE = $0E
SFXC1VibSeqPtr: ds 2	;$DEBF = $0F
SFXC1EnvSeqPtr: ds 2	;$DEC1 = $11
SFXC1VibSeqPos: ds 1	;$DEC3 = $13
SFXC1EnvSeqPos: ds 1	;$DEC4 = $14
SFXC1VibDelay: ds 1		;$DEC5 = $15
SFXC1EnvDelay: ds 1		;$DEC6 = $16
SFXC1Unused17: ds 1		;$DEC7 = $17
SFXC1VibVal: ds 1		;$DEC8 = $18
SFXC1FreqOut: ds 2		;$DEC9 = $19
SFXC1Freq: ds 2			;$DECB = $1B
SFXC1EnvVal: ds 1		;$DECD = $1D
SFXC1SongPos: ds 2		;$DECE = $1E
SFXC1Repeat1Start: ds 2	;$DED0 = $20
SFXC1Repeat2Start: ds 2	;$DED2 = $22
SFXC1Macro1Pos: ds 2	;$DED4 = $24
SFXC1Macro2Pos: ds 2	;$DED6 = $26
SFXC1Repeat1Times: ds 1	;$DED8 = $28
SFXC1Repeat2Times: ds 1	;$DED9 = $29
SFXC1Flags: ds 1		;$DEDA = $2A
SFXC1DataBank: ds 1		;$DEDB = $2B

SECTION "Audio RAM SFXC2", WRAMX[SFXC2RAM]
SFXC2MusNum: ds 1		;$DEDC = $00
SFXC2Priority: ds 1		;$DEDD = $01
SFXC2Sweep: ds 1		;$DEDE = $02
SFXC2Transpose: ds 1	;$DEDF = $03
SFXC2Tuning: ds 1		;$DEE0 = $04
SFXC2PanMode: ds 1		;$DEE1 = $05
SFXC2Panning: ds 1		;$DEE2 = $06
SFXC2Gate: ds 2			;$DEE3 = $07
SFXC2NoteDelay: ds 2	;$DEE5 = $09
SFXC2Speed: ds 1		;$DEE7 = $0B
SFXC2DutyVol: ds 1		;$DEE8 = $0C
SFXC2Unused0D: ds 1		;$DEE9 = $0D
SFXC2Unused0E: ds 1		;$DEEA = $0E
SFXC2VibSeqPtr: ds 2	;$DEEB = $0F
SFXC2EnvSeqPtr: ds 2	;$DEED = $11
SFXC2VibSeqPos: ds 1	;$DEEF = $13
SFXC2EnvSeqPos: ds 1	;$DEF0 = $14
SFXC2VibDelay: ds 1		;$DEF1 = $15
SFXC2EnvDelay: ds 1		;$DEF2 = $16
SFXC2Unused17: ds 1		;$DEF3 = $17
SFXC2VibVal: ds 1		;$DEF4 = $18
SFXC2FreqOut: ds 2		;$DEF5 = $19
SFXC2Freq: ds 2			;$DEF7 = $1B
SFXC2EnvVal: ds 1		;$DEF9 = $1D
SFXC2SongPos: ds 2		;$DEFA = $1E
SFXC2Repeat1Start: ds 2	;$DEFC = $20
SFXC2Repeat2Start: ds 2	;$DEFE = $22
SFXC2Macro1Pos: ds 2	;$DF00 = $24
SFXC2Macro2Pos: ds 2	;$DF02 = $26
SFXC2Repeat1Times: ds 1	;$DF04 = $28
SFXC2Repeat2Times: ds 1	;$DF05 = $29
SFXC2Flags: ds 1		;$DF06 = $2A
SFXC2DataBank: ds 1		;$DF07 = $2B

SECTION "Audio RAM SFXC3", WRAMX[SFXC3RAM]
SFXC3MusNum: ds 1		;$DF20 = $00
SFXC3Priority: ds 1		;$DF21 = $01
SFXC3Sweep: ds 1		;$DF22 = $02
SFXC3Transpose: ds 1	;$DF23 = $03
SFXC3Tuning: ds 1		;$DF24 = $04
SFXC3PanMode: ds 1		;$DF25 = $05
SFXC3Panning: ds 1		;$DF26 = $06
SFXC3Gate: ds 2			;$DF27 = $07
SFXC3NoteDelay: ds 2	;$DF29 = $09
SFXC3Speed: ds 1		;$DF2B = $0B
SFXC3DutyVol: ds 1		;$DF2C = $0C
SFXC3Unused0D: ds 1		;$DF2D = $0D
SFXC3Unused0E: ds 1		;$DF2E = $0E
SFXC3VibSeqPtr: ds 2	;$DF2F = $0F
SFXC3EnvSeqPtr: ds 2	;$DF31 = $11
SFXC3VibSeqPos: ds 1	;$DF33 = $13
SFXC3EnvSeqPos: ds 1	;$DF34 = $14
SFXC3VibDelay: ds 1		;$DF35 = $15
SFXC3EnvDelay: ds 1		;$DF36 = $16
SFXC3Unused17: ds 1		;$DF37 = $17
SFXC3VibVal: ds 1		;$DF38 = $18
SFXC3FreqOut: ds 2		;$DF39 = $19
SFXC3Freq: ds 2			;$DF3B = $1B
SFXC3EnvVal: ds 1		;$DF3D = $1D
SFXC3SongPos: ds 2		;$DF3E = $1E
SFXC3Repeat1Start: ds 2	;$DF40 = $20
SFXC3Repeat2Start: ds 2	;$DF42 = $22
SFXC3Macro1Pos: ds 2	;$DF44 = $24
SFXC3Macro2Pos: ds 2	;$DF46 = $26
SFXC3Repeat1Times: ds 1	;$DF48 = $28
SFXC3Repeat2Times: ds 1	;$DF49 = $29
SFXC3Flags: ds 1		;$DF4A = $2A
SFXC3DataBank: ds 1		;$DF4B = $2B

SECTION "Audio RAM SFXC4", WRAMX[SFXC4RAM]
SFXC4MusNum: ds 1		;$DF4C = $00
SFXC4Priority: ds 1		;$DF4D = $01
SFXC4Sweep: ds 1		;$DF4E = $02
SFXC4Transpose: ds 1	;$DF4F = $03
SFXC4Tuning: ds 1		;$DF50 = $04
SFXC4PanMode: ds 1		;$DF51 = $05
SFXC4Panning: ds 1		;$DF52 = $06
SFXC4Gate: ds 2			;$DF53 = $07
SFXC4NoteDelay: ds 2	;$DF55 = $09
SFXC4Speed: ds 1		;$DF57 = $0B
SFXC4DutyVol: ds 1		;$DF58 = $0C
SFXC4Unused0D: ds 1		;$DF59 = $0D
SFXC4Unused0E: ds 1		;$DF5A = $0E
SFXC4VibSeqPtr: ds 2	;$DF5B = $0F
SFXC4EnvSeqPtr: ds 2	;$DF5D = $11
SFXC4VibSeqPos: ds 1	;$DF5F = $13
SFXC4EnvSeqPos: ds 1	;$DF60 = $14
SFXC4VibDelay: ds 1		;$DF61 = $15
SFXC4EnvDelay: ds 1		;$DF62 = $16
SFXC4Unused17: ds 1		;$DF63 = $17
SFXC4VibVal: ds 1		;$DF64 = $18
SFXC4FreqOut: ds 2		;$DF65 = $19
SFXC4Freq: ds 2			;$DF67 = $1B
SFXC4EnvVal: ds 1		;$DF69 = $1D
SFXC4SongPos: ds 2		;$DF6A = $1E
SFXC4Repeat1Start: ds 2	;$DF6C = $20
SFXC4Repeat2Start: ds 2	;$DF6E = $22
SFXC4Macro1Pos: ds 2	;$DF70 = $24
SFXC4Macro2Pos: ds 2	;$DF72 = $26
SFXC4Repeat1Times: ds 1	;$DF74 = $28
SFXC4Repeat2Times: ds 1	;$DF75 = $29
SFXC4Flags: ds 1		;$DF76 = $2A
SFXC4DataBank: ds 1		;$DF77 = $2B

SECTION "Audio Variables", WRAMX[$DF08]
CurTrack: ds 1			;$DF08
CurTrackCheck: ds 1		;$DF09
MusNum: ds 1			;$DF0A
SFXNum: ds 1			;$DF0B
SongNum: ds 1			;$DF0C
ChanMask: ds 1			;$DF0D
Priority: ds 1			;$DF0E
TracksUsed: ds 1		;$DF0F
SongBank: ds 1			;$DF10
CurWave: ds 1			;$DF11
MusVolume: ds 1			;$DF12
SFXVolume: ds 1			;$DF13
MusPlaying: ds 1		;$DF14
ds 4
CurSpeed: ds 1			;$DF19
LengthVal: ds 2			;$DF1A
ds 4

SECTION "Audio Registers", WRAMX[$DF78]
NR10Val: ds 1			;$DF78
NR11Val: ds 1			;$DF79
NR12Val: ds 1			;$DF7A
NR13Val: ds 1			;$DF7B
NR14Val: ds 1			;$DF7C
NR21Val: ds 1			;$DF7D
NR22Val: ds 1			;$DF7E
NR23Val: ds 1			;$DF7F
NR24Val: ds 1			;$DF80
NR30Val: ds 1			;$DF81
NR31Val: ds 1			;$DF82
NR32Val: ds 1			;$DF83
NR33Val: ds 1			;$DF84
NR34Val: ds 1			;$DF85
NR41Val: ds 1			;$DF86
NR42Val: ds 1			;$DF87
NR43Val: ds 1			;$DF88
NR44Val: ds 1			;$DF89
NR50Val: ds 1			;$DF8A
NR51Val: ds 1			;$DF8B
NR52Val: ds 1			;$DF8C
CurCommand: ds 1		;$DF8D
SeqBank: ds 1			;$DF8E
