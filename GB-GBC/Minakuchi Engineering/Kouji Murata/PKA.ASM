;Pocket King audio disassembly - bank 1
;Disassembly by Will Trowbridge & Claude

include "HARDWARE.INC"

def AudioROM equ $4000
;AudioBankN is the bank number as the song table headers store it, so the data
;stays byte for byte what the original ROM holds. PlayerBankN is where this test
;ROM actually packs the two banks, which keeps it down to 64 KB; GetSeqByte
;subtracts the difference before selecting a bank.
def AudioBank1 equ $0E
def AudioBank2 equ $0F
def PlayerBank1 equ $01
def PlayerBank2 equ $02
def BankOffset equ AudioBank1 - PlayerBank1
def AudioRAM equ $DE00
def WaveRAM equ $FF30
def TrackRAMSize equ $30
def MusC1RAM equ $DE00
def MusC2RAM equ $DE30
def MusC3RAM equ $DE60
def MusC4RAM equ $DE90
def SFXC1RAM equ $DEC0
def SFXC2RAM equ $DF00
def SFXC3RAM equ $DF30
def SFXC4RAM equ $DF60

;GetSeqByte and SetRomBank live in ROM0 and are stubbed in FUNCTION.ASM

SECTION "Audio 1", ROMX[AudioROM], BANK[PlayerBank1]

AudioOff:
	;Turn off audio
	xor a
	ldh [rNR50], a
	ld a, %10000000
	ldh [rNR52], a
	
ClearCh1:
	;Reset NR10 (sweep)
	ld a, %00001000
	ldh [rNR10], a
	ld [NR10Val], a
	;Check if channel is on
	ldh a, [rNR52]
	bit 0, a
	;If not, then skip
	jr z, ClearCh2
	
	xor a
	;Clear NR11-NR14
	ldh [rNR11], a
	ld [NR11Val], a
	ld a, %00001000
	ldh [rNR12], a
	ld [NR12Val], a
	xor a
	ldh [rNR13], a
	ld [NR13Val], a
	ld [NR14Val], a
	;Set trigger bit
	ld a, %10000000
	ldh [rNR14], a
	xor a

ClearCh2:
	;Check if channel is on
	ldh a, [rNR52]
	bit 1, a
	;If not, then skip
	jr z, ClearCh3
	
	xor a
	;Clear NR21-NR24
	ldh [rNR21], a
	ld [NR21Val], a
	ldh [rNR22], a
	ld [NR22Val], a
	ldh [rNR23], a
	ld [NR23Val], a
	ld [NR24Val], a
	;Set trigger bit
	ld a, %10000000
	ldh [rNR24], a

ClearCh3:
	xor a
	;Clear NR32 and NR34
	ldh [rNR32], a
	ld [NR32Val], a
	ld [NR34Val], a
	;Set trigger bit
	ld a, %10000000
	ldh [rNR34], a
	
ClearCh4:
	;Check if channel is on
	ldh a, [rNR52]
	bit 3, a
	;If not, then return
	jr z, AudioOffRet
	
	xor a
	;Clear NR41-NR14
	ldh [rNR41], a
	ld [NR41Val], a
	ld a, 8
	ldh [rNR42], a
	ld [NR42Val], a
	xor a
	ldh [rNR43], a
	ld [NR43Val], a
	ld [NR44Val], a
	;Set trigger bit
	ld a, %10000000
	ldh [rNR44], a

AudioOffRet:
	ret

LoadSong:
	ld a, [SFXNum]

	;If song is $06, then fade out current music
	cp $06
	jp z, FadeOutMus
	
	push bc
	push de
	;Get pointer from song table
	add a
	add LOW(SongTab)
	ld l, a
	ld a, HIGH(SongTab)
	adc 0
	ld h, a
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	
	;Load header values into RAM
	xor a
	ld [CurTrack], a
	ld a, [hl+]
	ld [Temp1], a					;Byte 1 = Channel mask

LoadSong2:
	ld a, [hl+]
	ld [Temp2], a					;Byte 2 = priority
	ld a, [hl+]
	ld [SongBank], a				;Byte 3 = bank	
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
	ld hl, Temp1
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
	ld hl, $00
	add hl, de
	ld a, [hl+]
	or a
	jr z, .InitTrackRAM2

	;If not below priority, then don't play channel
	ld a, [Temp2]
	cp [hl]
	jr nc, .InitTrackRAM2
	inc bc
	inc bc
	jr .NextTrack

.InitTrackRAM2
	;Get pointer from current song
	ld hl, $20
	add hl, de
	ld a, [bc]
	ld [hl+], a
	inc bc
	ld a, [bc]
	ld [hl], a
	inc bc
	;Add current channel mask to output value
	ld a, [CurTrack]
	add LOW(TrackMaskVals)
	ld l, a
	ld a, HIGH(TrackMaskVals)
	adc 0
	ld h, a
	ld a, [Output]
	or [hl]
	ld [Output], a
	;Copy SFX number value to channel music number
	ld h, d
	ld l, e
	ld a, [SFXNum]
	ld [hl+], a
	;Get priority value and copy to channel location
	ld a, [Temp2]
	ld [hl+], a
	;Set sweep value
	ld a, %00001000
	ld [hl+], a
	;Set transpose and tuning to 0
	xor a
	ld [hl+], a
	ld [hl+], a
	;Set volume to maximum
	ld a, %00000011
	ld [hl+], a
	ld [hl+], a
	;Set delay to 1
	ld a, 1
	ld [hl+], a
	;Set speed to 0
	xor a
	ld [hl], a
	;Set rest switch to 0
	ld hl, $2D
	add hl, de
	ld [hl+], a
	;Set data bank to song bank
	ld a, [SongBank]
	ld [hl], a
	;Set vibrato value to FF
	ld hl, $1A
	add hl, de
	ld a, $FF
	ld [hl], a
	;Set envelope duration to 5
	ld hl, $18
	add hl, de
	ld a, 5
	ld [hl], a
	;Set gate
	ld hl, $1F
	add hl, de
	;If music channel 3, then set to 0
	ld a, [CurTrack]
	cp 2
	jr z, .InitTrackRAM2_C3
	;Otherwise, set to 8
	ld a, 8
	ld [hl], a
	jr .NextTrack

.InitTrackRAM2_C3
	xor a
	ld [hl], a
	jr .NextTrack

FadeOutMus:
	ld a, 7
	ld [Fade], a
	ld [FadeTime], a
	ret

CallSFXCheck:
	;Start a sound effect, ignoring $00 (silence) and $06 (fade out) -
	;the percussion path is the only caller, and a drum number of 6 would
	;otherwise fade the music out. The game itself calls CallSFX below.
	or a
	ret z
	cp 6
	ret z

;Call sound effect with music
CallSFX:
	;Get sound effect number called
	push bc
	push de
	ld [SFXNum], a
	;Get sound effect pointer from RAM
	add a
	add LOW(SongTab)
	ld l, a
	ld a, HIGH(SongTab)
	adc 0
	ld h, a
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	;Set current track to 4 (SFX track 1)
	ld a, 4
	ld [CurTrack], a
	;Get mask value
	ld a, [hl+]
	swap a
	and %00001111
	ld [Temp1], a
	jp LoadSong2

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

ProcTrack:

	;Check if the track is playing anything
	ld hl, $00
	add hl, de
	ld a, [hl]
	or a
	;If not, then return
	ret z

	;Otherwise, count the 16-bit note delay down. dec [hl] leaves the
	;carry alone, so the borrow is spotted by testing whether the low
	;byte just wrapped to $FF and decrementing the high byte by hand.
	ld hl, $07
	add hl, de
	dec [hl]
	ld a, $FF
	cp [hl]
	jr nz, .ProcTrack2
	inc l
	dec [hl]
	dec l

.ProcTrack2
	;If both bytes are now zero, get the next command
	ld a, [hl+]
	or [hl]
	call z, NextCommand	
	;Otherwise, check if track is 3 (music 4)
	ld a, [CurTrackCheck]
	cp 3
	;If so, return
	ret z
	;Otherwise, check if delay is 0
	ld a, [de]
	or a
	;If so, then process track register values
	jr z, .ProcTrack3
	call ProcEnvVib
	call EnvSustain

.ProcTrack3
	call ProcTrackRegVals
	ret

ProcEnvVib:
	;Get channel envelope
	ld hl, $0F
	add hl, de
	ld a, [hl]

	;If no carry, then process vibrato
	add a
	jp nc, ProcVibrato
	ld hl, $1A
	add hl, de
	dec [hl]
	ret nz

	;Check if wave channel
	ld a, [CurTrackCheck]
	and %00000011
	cp 2
	;If so, then perform special envelope handler
	jp z, ProcEnvStateCh3

ProcEnvState:
	;Otherwise, this is a decaying (CH1/CH2) envelope.
	;Jump to the handler for the current envelope stage.
	ld hl, $18
	add hl, de
	ld a, [hl]
	and %00000111
	add a
	add LOW(EnvStates)
	ld l, a
	ld a, HIGH(EnvStates)
	adc 0
	ld h, a
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	jp hl

EnvStates:
	dw EnvState0
	dw EnvState1
	dw EnvState2
	dw EnvState3
	dw EnvState4
	dw EnvStateDone
	dw EnvStateDone
	dw EnvStateDone

EnvStateDone:
	ret

EnvState0:
	;Increase envelope state
	ld hl, $18
	add hl, de
	inc [hl]

	;Get envelope value
	ld hl, $0F
	add hl, de
	ld a, [hl]

	;Get volume from envelope
	and %00001111
	ld b, a
	ld a, [hl]
	swap a

	;Load the value into current hardware volume register (NRx2)
	ld hl, $1F
	add hl, de
	ld [hl], a

	;Then load upper 3 bits
	and %00000111
	jr z, EnvState1
	ld c, a

	;Get decay
	ld hl, $0B
	add hl, de
	ld a, [hl]
	swap a
	and %00001111

	;Subtract volume
	sub b
	;If not 0 or below, then go to next stage
	jr c, EnvState1
	ld l, c

	;Otherwise, multiply the volume by decay
	call Multiply
	;If result is 0, then skip to next state
	or a
	jp nz, SaveStageDur

EnvState1:
	;Increase envelope state
	ld hl, $18
	add hl, de
	inc [hl]

	;Get decay
	ld hl, $0B
	add hl, de
	ld a, [hl]
	and %11110000
	ld b, a

	;Also get secondary decay parameter
	ld hl, $10
	add hl, de
	ld a, [hl]
	swap a
	and %00000111

	;Combine these values and save as current NRx1 volume
	ld c, a
	or b
	ld hl, $1F
	add hl, de
	ld [hl], a

	;Compute next stage's duration as
	;(high nibble of +$0B - low nibble of +$10) x 7-bit count of +$10.
	ld hl, $10
	add hl, de
	ld a, [hl]
	and %00001111
	ld l, a
	swap b
	ld a, b
	sub l
	;If not 0 or below, then go to next stage
	jr c, EnvState2
	ld l, c
	call Multiply
	or a
	jp nz, SaveStageDur

EnvState2:
	;Increase envelope state
	ld hl, $18
	add hl, de
	inc [hl]

	;Get secondary decay parameter
	ld hl, $10
	add hl, de
	ld a, [hl]
	swap a
	and %11110000

	;Save as current NRx1 volume
	ld hl, $1F
	add hl, de
	ld [hl], a
	ld a, 1
	jp SaveStageDur

EnvState3:
	ld hl, $2C
	add hl, de
	ld a, [hl]
	and %00001000
	jr nz, EnvState3_2
	ld hl, $2D
	add hl, de
	ld a, [hl]
	and %00001000
	jr z, .EnvState3_1C

	;Get note delay, high byte
	ld hl, $08
	add hl, de
	ld a, [hl]

	;And get the release threshold, high byte
	ld hl, $13
	add hl, de
	cp [hl]
	jr z, .EnvState3_1B
	jr nc, .EnvState3_1C
	jr EnvState3_2

.EnvState3_1B
	ld hl, $07
	add hl, de
	ld a, [hl]
	ld hl, $12
	add hl, de
	cp [hl]
	jr z, EnvState3_2
	;If not negative, then go to next state
	jr c, EnvState3_2

.EnvState3_1C
	ld a, 1
	jp SaveStageDur

EnvState3_2:
	;Increase envelope state
	ld hl, $18
	add hl, de
	inc [hl]

	;Get secondary decay parameter
	ld hl, $10
	add hl, de
	ld a, [hl]
	and %00001111
	push af
	swap a
	ld b, a

	;Get tertiary decay parameter
	ld hl, $11
	add hl, de
	ld a, [hl]
	and %00000111
	ld c, a

	;Combine these values and save as current NRx1 volume
	or b
	ld hl, $1F
	add hl, de
	ld [hl], a

	;Get primary decay value
	ld hl, $0B
	add hl, de
	ld a, [hl]
	and %00001111
	ld b, a

	;Subtract secondary decay value
	pop af
	sub b

	;If decay is more than 0, then go to next stage
	jr c, EnvState4
	ld l, c

	;Multiply values otherwise
	call Multiply
	or a
	jp nz, SaveStageDur

EnvState4:
	;Get primary decay value
	ld hl, $0B
	add hl, de
	ld a, [hl]
	and %00001111
	swap a

	;Set secondary decay value to it
	ld hl, $1F
	add hl, de
	ld [hl], a
	ld hl, $18
	add hl, de
	inc [hl]
	ld a, $FF
	;Set stage duration to 255 into RAM
	jp SaveStageDur

ProcEnvStateCh3:

	;Check envelope stage
	ld hl, $18
	add hl, de
	ld a, [hl]
	and %00000111
	add a
	add LOW(EnvStatesCh3)
	ld l, a
	ld a, HIGH(EnvStatesCh3)
	adc 0
	ld h, a
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	jp hl

EnvStatesCh3:
	dw EnvState1Ch3
	dw EnvState2Ch3
	dw EnvState3Ch3
	dw EnvState4Ch3
	dw EnvStateDoneCh3
	dw EnvStateDoneCh3
	dw EnvStateDoneCh3
	dw EnvStateDoneCh3

EnvStateDoneCh3:
	ret

EnvState1Ch3:
	;Get new volume
	ld a, %11110000
	ld hl, $1F
	add hl, de
	ld [hl], a

	;Increase envelope state
	ld hl, $18
	add hl, de
	inc [hl]

	;Get envelope value (lower 7 bits)
	ld hl, $0F
	add hl, de
	ld a, [hl]
	and %01111111

	;Set envelope length to it
	ld hl, $1A
	add hl, de
	ld [hl], a
	ret

EnvState2Ch3:
	;Get new volume
	ld a, %01010000
	
	;Set NR31 volume
	ld hl, $1F
	add hl, de
	ld [hl], a
	
	;Increase envelope state
	ld hl, $18
	add hl, de
	inc [hl]
	
	;Set envelope length to 1
	ld hl, $1A
	add hl, de
	ld a, 1
	ld [hl], a
	ret

EnvState3Ch3:
	;Get channel note flags
	ld hl, $2C
	add hl, de
	ld a, [hl]
	;If bit 3 is set, then is a rest
	and %00001000
	
	;Otherwise, is a note
	jr nz, EnvState3Ch3_3
	;If a rest, check data flags
	ld hl, $2D
	add hl, de
	ld a, [hl]
	;If bit 3 is not set, then get note delay
	and %00001000
	jr z, EnvState3Ch3_4

	;Get note delay, high byte
	ld hl, $08
	add hl, de
	ld a, [hl]
	
	;And get the release threshold, high byte
	ld hl, $13
	add hl, de
	cp [hl]
	;If equal to delay, then get low byte
	jr z, EnvState3Ch3_2
	;If more, then set envelope duration to 1
	jr nc, EnvState3Ch3_4
	;Otherwise, set volume and tertiary decay
	jr EnvState3Ch3_3

EnvState3Ch3_2:
	ld hl, $07
	add hl, de
	ld a, [hl]
	;Compare to release time
	ld hl, $12
	add hl, de
	cp [hl]
	;If more or equal, then keep going
	jr z, EnvState3Ch3_3
	jr nc, EnvState3Ch3_4

EnvState3Ch3_3:
	;Set current volume
	ld a, $10
	ld hl, $1F
	add hl, de
	ld [hl], a
	;Get tertiary decay
	ld hl, $11
	add hl, de
	ld a, [hl]
	and %00001111
	;Load lower 4 bits into envelope duration
	ld hl, $1A
	add hl, de
	ld [hl], a
	;Increment envelope state
	ld hl, $18
	add hl, de
	inc [hl]
	ret

EnvState3Ch3_4:
	;Set envelope duration to 1
	ld hl, $1A
	add hl, de
	ld a, 1
	ld [hl], a
	ret

EnvState4Ch3:
	;Set NR31 volume to 0
	ld a, 0
	ld hl, $1F
	add hl, de
	ld [hl], a

	;Increase envelope state
	ld hl, $18
	add hl, de
	inc [hl]
	ret

;Decrease envelope stage duration counter
ProcVibrato:
	ld hl, $1A
	add hl, de
	dec [hl]
	ret nz

	;Otherwise, get next envelope value from sequence
	ld hl, $17
	add hl, de
	inc [hl]
	;Advance the envelope sequence pointer
	ld a, [hl]
	ld hl, $14
	add hl, de
	add [hl]
	ld c, a
	inc l
	ld a, [hl]
	adc 0
	ld b, a
	;Check current envelope value
	ld a, [bc]
	;If FF, then end of sequence
	cp $FF
	;Otherwise, get volume
	jr nz, GetVol

	;Decrement sequence position
	ld hl, $17
	add hl, de
	dec [hl]
	jr SaveStageDur

GetVol:
	;Get volume from upper 4 bits of envelope
	ld hl, $1F
	add hl, de
	push af
	and %11110000
	ld [hl], a
	;Then get duration from lower 4 bits of envelope
	pop af
	and %00001111

SaveStageDur:
	;Load stage duration into RAM value
	ld hl, $1A
	add hl, de
	ld [hl], a
	ret

;After envelope is finished...
EnvSustain:
	;If channel is 2, then return
	ld a, [CurTrackCheck]
	and 2
	ret nz

	;Otherwise, decrease vibrato sequence delay
	ld hl, $19
	add hl, de
	dec [hl]
	ret nz

	;Increase vibrato sequence
	ld hl, $16
	add hl, de
	inc [hl]
	ld a, [hl]

ProcNextVibrato:
	;Get next byte from vibrato sequence
	ld hl, $0D
	add hl, de
	add [hl]
	ld c, a
	inc l
	ld a, [hl]
	adc 0
	ld b, a
	ld a, [bc]
	;If FF, then end of sequence
	cp $FF
	;Otherwise, process value
	jr nz, .ProcNextVibrato2

	;Reset vibrato sequence step - back to start
	ld hl, $16
	add hl, de
	xor a
	ld [hl], a
	jr ProcNextVibrato

.ProcNextVibrato2:
	;Check if value is positive or negative from upper 4 bits
	push af
	swap a
	and %00001111
	cp 8
	jr c, .ProcNextVibrato3

	;If negative
	or %11110000

.ProcNextVibrato3:
	;Set vibrato value
	ld hl, $1C
	add hl, de
	ld [hl], a

	;Set delay from lower 4 bits
	pop af
	and %00001111
	ld hl, $19
	add hl, de
	ld [hl], a

ProcNextVibratoRet:
	ret

NextCommand:
	;Get channel pointer
	ld hl, $20
	add hl, de
	ld a, [hl+]
	ld c, a
	ld b, [hl]

.NextCommand2
	;Get next byte from channel pointer
	call GetSeqByte
	cp $D0
	;If less than D0, is a note or rest
	jr c, .NoteOrRest

	;Otherwise, is parameters or VCMD
	call ParamsOrVCMD
	;Repeat
	jr .NextCommand2

.NoteOrRest
	;If less than C0, is a note
	cp $C0
	;Otherwise, is a rest
	jp nc, SetRestBit
	ld l, a

.IsNote
	;Check if track is 3 (music 4)
	ld a, [CurTrackCheck]
	cp 3
	ld a, l
	;If so, then perform special handler
	jp z, ProcNoteMusCh4
	push bc
	push af

	;Mark this step as a note - bit 5 retriggers the channel
	ld hl, $2C
	add hl, de
	ld [hl], 32
	;Check if track is SFX 4
	ld a, [CurTrackCheck]
	cp 7
	;If so, then perform special handler
	jr z, ProcNoteSFXCh4

	;Get octave
	ld hl, $1B
	add hl, de
	ld a, [hl]

	;Multiply to get proper octave offset
	add a
	add a
	ld b, a
	add a
	add b
	ld b, a

	;Now get note number
	pop af
	swap a
	and %00001111

	;Add to octave
	add b

	;And add transpose
	ld hl, $03
	add hl, de
	add [hl]

	;Get frequency from table
	add a
	add LOW(FreqTab)
	ld c, a
	ld a, HIGH(FreqTab)
	adc 0
	ld b, a

	;Load frequency into RAM
	ld hl, $1D
	add hl, de
	ld a, [bc]
	ld [hl+], a
	inc bc
	ld a, [bc]
	ld [hl], a
	pop bc
	;Then process delay
	call ProcDelay
	call ResetEnvSeq
	;And process the rest of the note
	jr ProcNote2C

ProcNoteSFXCh4:
	pop af
	pop bc

	;Get note from octave
	and %01110000
	ld hl, $1B
	add hl, de
	or [hl]
	swap a

	;OR with volume/duty value
	ld hl, $0A
	add hl, de
	or [hl]

	;Load frequency into RAM
	ld hl, $1D
	add hl, de
	ld [hl+], a
	xor a
	ld [hl], a
	;Then process delay and rest of note
	call ProcDelay
	call ResetEnvSeq
	jr ProcNote2C

ProcNoteMusCh4:
	;Get next byte
	call GetSeqByte
	swap a
	and %00001111
	call CallSFXCheck
	ld hl, $2C
	add hl, de
	ld a, $20
	ld [hl], a
	jr ProcNote2C

SetRestBit:
	;Set "rest" bit of data flags
	ld hl, $2D
	add hl, de
	ld a, [hl]
	and %00001000
	jr z, ProcNote2B

ProcNote2:

	;A rest with the $F4 flag set silences the channel
	ld hl, $1F
	add hl, de
	xor a
	ld [hl], a

ProcNote2B:

	;Mark this step as a rest
	ld hl, $2C
	add hl, de
	ld a, %00001010
	ld [hl], a

ProcNote2C:

	;Advance pointer
	call GetSeqByte

	;Get lower 4 bits
	and %00001111
	jr nz, ProcNote2D
	inc bc
	call GetSeqByte

ProcNote2D:
	push bc
	ld c, a

	;Multiply the length by the channel speed
	ld hl, $09
	add hl, de
	ld a, [hl]
	ld l, c
	call Multiply16LoNibble
	ld b, h
	ld c, l
	ld hl, $07
	add hl, de
	ld [hl], c
	inc l
	ld [hl], b

	;If channel 3 (music 4), then skip
	ld a, [CurTrackCheck]
	cp 3
	jr z, .ProcNote2Ret

	;Otherwise this only applies when the $F4 flag is set, the same bit
	;that makes a rest cut the note off.
	ld hl, $2D
	add hl, de
	ld a, [hl]
	and %00001000
	jr z, .ProcNote2Ret

	;Work out how much of this step should still be left when the
	;release begins.
	;
	;The high nibble of Decay3 is how long to hold the note, in
	;sixteenths of the step, so $FF - Decay3 turns that into the part
	;still to run when the release starts: the low nibble of $FF is $F,
	;so it can never borrow, and the high nibble of the result is exactly
	;15 - (Decay3 >> 4).
	;
	;ReleaseTime = NoteDelay * (15 - (Decay3 >> 4)) / 16, and EnvState3
	;starts the release once NoteDelay has counted down to it. A Decay3
	;high nibble of $F gives 0, so the note holds for the whole step; $0
	;gives fifteen sixteenths, so it releases almost at once.
	ld hl, $11
	add hl, de
	ld h, [hl]
	ld a, $FF
	sub h
	ld h, a

	;Multiply16HiNibble wants an 8-bit multiplicand in L, so whether to
	;multiply first or divide first depends on the size of the step.
	ld a, b
	or a
	jr nz, .ProcNote2E
	ld l, c
	ld a, h
	call Multiply16HiNibble

	;Short step: multiplied first, so shift the 16-bit product right four
	;places into one byte - H's low nibble becomes the high nibble and
	;L's high nibble the low - and store it with a zero high byte, which
	;is safe because 15 * 255 / 16 is only 239.
	ld a, h
	swap a
	and %11110000
	ld h, a
	ld a, l
	swap a
	and %00001111
	or h

	;Save as the release threshold
	ld hl, $12
	add hl, de
	ld [hl+], a
	xor a
	ld [hl], a
	jr .ProcNote2Ret

.ProcNote2E

	;Long step: divide the step by sixteen first instead, the same nibble
	;shuffle one register along, so that the product still fits in HL.
	ld a, c
	swap a
	and %00001111
	ld c, a
	ld a, b
	swap a
	and %11110000
	or c
	ld l, a
	ld a, h
	call Multiply16HiNibble
	ld b, h
	ld c, l
	ld hl, $12
	add hl, de
	ld [hl], c
	inc l
	ld [hl], b

.ProcNote2Ret
	pop bc
	call AdvChanPos
	ret

ProcDelay:
	;Check final volume
	ld hl, $05
	add hl, de
	ld a, [hl+]
	or a
	;If not 0, then don't change volume or delay
	jr nz, .ProcDelay_3

	;Check if output volume is 3 (max)
	ld a, [hl]
	cp 3
	;If not, then don't change
	jr nz, .ProcDelay_2

	;If so, then set to 1
	ld a, 1

;XOR and AND value to lowest 2 bits (for envelope)
.ProcDelay_2:
	xor %00000011

.ProcDelay_3:
	and %00000011
	ld [hl], a
	ret

ResetEnvSeq:

	;Restart both sequences for a new note.
	;
	;VibStep and EnvSeqPos go to $FF so that the first step of each reads
	;index 0 after its own increment, EnvStep and VibVal are cleared,
	;VibSeqDelay is reloaded from EnvLen + 1, and EnvDur is set to 1 so
	;the first envelope stage runs on the next frame.
	ld hl, $16
	add hl, de
	ld a, $FF
	ld [hl+], a
	ld [hl+], a

	;Set envelope state to 0
	xor a
	ld [hl+], a
	ld hl, $1C
	add hl, de
	ld [hl], a

	;Also reset envelope length to 0
	ld hl, $0C
	add hl, de
	ld a, [hl]
	inc a
	ld hl, $19
	add hl, de
	ld [hl+], a

	;Set envelope duration to 1
	ld a, 1
	ld [hl], a
	ret

;Advance channel position
AdvChanPos:
	ld hl, $20
	add hl, de
	inc bc
	ld [hl], c
	inc l
	ld [hl], b
	ret

Multiply16LoNibble:

	;Multiply the LOW nibble of A by L. 16-bit result in HL.
	;Swaps the nibbles and falls through, so see Multiply16HiNibble.
	swap a

Multiply16HiNibble:

	;Multiply the HIGH nibble of A by L. 16-bit result in HL.
	;DE is preserved; A is left holding what fell out of the top of HL.
	;
	;DE takes the multiplicand and HL starts at zero. Each round doubles
	;the running total with `add hl, hl` and pulls the next multiplier bit
	;out of A with `rla`: the carry out of the shift feeds A bit 0, and
	;the bit that falls out of A bit 7 is what the following `jr nc`
	;tests, adding DE when it is set. Entering here runs four rounds, so
	;only A bits 7-4 are used.
	push de
	ld e, l
	ld d, 0
	ld h, d
	ld l, d
	jr Multiply16.Multiply16_5

;The full eight-round entry. Nothing calls it, so these first four rounds are
;unreachable - Multiply16HiNibble above jumps straight past them.
Multiply16:
	push de
	ld e, l
	ld d, 0
	ld h, d
	ld l, d
	add hl, hl
	rla
	jr nc, .Multiply16_2
	add hl, de

.Multiply16_2
	add hl, hl
	rla
	jr nc, .Multiply16_3
	add hl, de

.Multiply16_3
	add hl, hl
	rla
	jr nc, .Multiply16_4
	add hl, de

.Multiply16_4
	add hl, hl
	rla
	jr nc, .Multiply16_5
	add hl, de

.Multiply16_5
	add hl, hl
	rla
	jr nc, .Multiply16_6
	add hl, de

.Multiply16_6
	add hl, hl
	rla
	jr nc, .Multiply16_7
	add hl, de

.Multiply16_7
	add hl, hl
	rla
	jr nc, .Multiply16_8
	add hl, de

.Multiply16_8
	add hl, hl
	rla
	jr nc, .Multiply16Ret
	add hl, de

.Multiply16Ret
	pop de
	ret

Multiply:
	swap a
	ld h, a
	xor a
	add a
	rl h
	;Pick the smaller operand as loop counter
	jr nc, .Multiply_2
	add l

.Multiply_2
	add a
	rl h
	jr nc, .Multiply_3
	add l

.Multiply_3
	add a
	rl h
	jr nc, .Multiply_4
	add l

.Multiply_4
	add a
	rl h
	jr nc, .MultiplyRet
	add l

.MultiplyRet:
	;Return when done
	ret

ParamsOrVCMD:
	;If Dx, is parameters
	sub $E0
	jr c, GetParams

	;Otherwise, is a VCMD - get pointer to jump to from table
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

GetParams:
	;Upper 4 bits of command is speed control
	ld hl, $09
	add hl, de
	and %00001111
	ld [hl+], a

	;If current track is 3 (music 4, then return)
	inc bc
	ld a, [CurTrackCheck]
	cp 3
	ret z

	;If current track is 7 (SFX 4, then perform special handler)
	cp 7
	jr z, GetParamsSFX4

	;If current track is 2 or 6 (music/SFX 3, then perform special handler)
	and %00000011
	cp 2
	jr z, GetParams3
	
	;Otherwise, next byte is duty/volume
	call GetSeqByte
	and %00110011
	add a
	add a
	ld [hl+], a

	;Next byte is decay
	inc bc
	call GetSeqByte
	ld [hl], a

	;Next byte is vibrato
	call EventVibrato
	;Final bytes are envelope and decay (if envelope is signed)
	jp GetEnvVal

GetParamsSFX4:
	;Check next byte - duty/volume
	call GetSeqByte
	;If 0, then 0, otherwise, 8
	or a
	jr z, .GetParamsSFX4_2
	ld a, 8

.GetParamsSFX4_2
	;Load parameter into RAM variable
	ld [hl+], a
	;Next byte is decay
	inc bc
	call GetSeqByte
	ld [hl], a
	;Final bytes are envelope (and decay if envelope is signed)
	jp EventEnvDecay

GetParams3:
	;Current byte is waveform
	call GetSeqByte
	ld [hl+], a
	inc bc
	;Next byte is envelope value
	call GetSeqByte
	ld hl, $0F
	add hl, de
	ld [hl+], a
	;Check if envelope is at max
	add a
	;If not, then set envelope sequence
	jp nc, GetEnvSeq

	;Otherwise, next byte is secondary decay
	inc bc
	inc l
	call GetSeqByte
	ld [hl], a
	inc bc
	ret

VCMDTab:
	dw EventOctave               ;$E0
	dw EventOctave               ;$E1
	dw EventOctave               ;$E2
	dw EventOctave               ;$E3
	dw EventOctave               ;$E4
	dw EventOctave               ;$E5
	dw EventOctave               ;$E6
	dw EventOctave               ;$E7
	dw EventDutyVol              ;$E8
	dw EventDecay                ;$E9
	dw EventSweep                ;$EA
	dw EventVibrato              ;$EB
	dw EventTranspose            ;$EC
	dw EventWaveform             ;$ED
	dw EventEnvDecay             ;$EE
	dw EventTuning               ;$EF
	dw EventEnvVal               ;$F0
	dw EventDecay2               ;$F1
	dw EventDecay3               ;$F2
	dw EventFinalVol             ;$F3
	dw EventSetDataFlag          ;$F4
	dw EventNop                  ;$F5
	dw EventSpeed                ;$F6
	dw EventMacro1               ;$F7
	dw EventMacro2               ;$F8
	dw EventMacro1Ret            ;$F9
	dw EventMacro2Ret            ;$FA
	dw EventRepeat1Start         ;$FB
	dw EventRepeat2Start         ;$FC
	dw EventRepeat1End           ;$FD
	dw EventRepeat2End           ;$FE
	dw EventEnd                  ;$FF

EventOctave:
	call GetSeqByte
	and %00000111
	;Store as octave in RAM
	ld hl, $1B
	add hl, de
	jr StoreVal

EventDutyVol:
;Set duty/volume
;Parameters: xxxxxxxx (x = value)
	inc bc
	;If track is SFX 4, then perform separate handler
	ld a, [CurTrackCheck]
	cp 7
	jr z, .EventDutyVol_SFX4
	call GetSeqByte
	;Mask out bits and multiply to get final value
	and %00110011
	add a
	add a
	ld hl, $0A
	add hl, de
	jr StoreVal

.EventDutyVol_SFX4
	call GetSeqByte
	or a
	jr z, .EventDutyVol_2

	ld a, 8

.EventDutyVol_2
	;Store final value in RAM
	ld hl, $0A
	add hl, de
	jr StoreVal

EventDecay:
;Set decay
;Parameters: xxxxxxxx (x = value)
	ld hl, $0B
	add hl, de
	inc bc
	call GetSeqByte

StoreVal:
	ld [hl], a

EventNop:
;Do nothing but skip a byte
;Parameters: -------- (- = unused)
NextByte:
	inc bc
	ret

EventSweep:
;Set sweep
;Parameters: xxxxxxxx (x = value)
	;Load parameter in RAM
	ld hl, $02
	add hl, de
	inc bc
	call GetSeqByte
	and %01111111
	ld [hl], a
	inc bc
	ret

EventVibrato:
;Set vibrato
;Parameters: xxxxxxxx (x = value)
	;First, get note envelope length from upper 4 bits
	inc bc
	call GetSeqByte
	swap a
	and %00001111
	;Then multiply by speed
	ld hl, $09
	add hl, de
	ld l, [hl]
	ld h, l
	dec h
	jr nz, .EventVibrato_2
	add a
	add a
	jr .EventVibrato_3

.EventVibrato_2
	call Multiply

.EventVibrato_3
	;Then, get vibrato
	ld hl, $0C
	add hl, de
	inc a
	ld [hl+], a
	call GetSeqByte
	and %00001111
	push bc
	add a
	add LOW(VibTab)
	ld c, a
	ld a, HIGH(VibTab)
	adc 0
	ld b, a

StorePtr:
	;Store pointer into RAM
	ld a, [bc]
	ld [hl+], a
	inc bc
	ld a, [bc]
	ld [hl], a
	pop bc
	inc bc
	ret

EventTranspose:
;Set transpose (per-channel)
;Parameters: xxxxxxxx (x = value, signed)
	;Load parameter in RAM
	ld hl, $03
	add hl, de
	inc bc
	call GetSeqByte
	ld [hl], a
	inc bc
	ret

EventWaveform:
;Set waveform
;Parameters: xxxxxxxx (x = value)
	;Check current track and set its respective waveform
	ld hl, $0A
	add hl, de
	inc bc
	call GetSeqByte
	ld [hl], a
	inc bc
	ret

EventEnvDecay:
;Set duty/volume and decay 2/3
;Parameters: xyyyyyyy (zzzzzzzz aaaaaaaa)  (x = if set, z and a are used, z = decay 2, a = decay 3)
	inc bc

GetEnvVal:
	;Get envelope value from byte
	call GetSeqByte
	ld hl, $0F
	add hl, de
	ld [hl+], a
	;If signed, then get decay parameters from next 2 bytes
	add a
	jr c, GetDecay

GetEnvSeq:
	;Get envelope sequence number from parameter
	call GetSeqByte

	push bc
	;Get envelope sequence pointer from table
	add a
	add LOW(EnvSeqTab)
	ld c, a
	ld a, HIGH(EnvSeqTab)
	adc 0
	;Load pointer into RAM
	ld b, a
	ld hl, $14
	add hl, de
	jr StorePtr

;Get decay parameters
GetDecay:
	inc bc
	call GetSeqByte
	ld [hl+], a
	inc bc
	call GetSeqByte
	ld [hl], a
	inc bc
	ret

EventTuning:
;Set tuning
;Parameters: xxxxxxxx (x = relative pitch, signed)
	;Load parameter in RAM
	ld hl, $04
	add hl, de
	inc bc
	call GetSeqByte
	ld [hl], a
	inc bc
	ret

EventEnvVal:
;Set envelope value
;Parameters: xxxxxxxx (x = value)
	;Load parameter in RAM
	ld hl, $0F
	add hl, de
	inc bc
	call GetSeqByte
	ld [hl], a
	;If carry, then advance byte
	add a
	jr c, .EventEnvVal2
	call GetSeqByte
	push bc
	add a
	add LOW(EnvSeqTab)
	ld c, a
	ld a, HIGH(EnvSeqTab)
	adc 0
	ld b, a
	ld hl, $14
	add hl, de
	jp StorePtr

.EventEnvVal2
	inc bc
	ret

EventDecay2:
;Set secondary decay
;Parameters: xxxxxxxx (x = value)
	;Load parameter in RAM
	ld hl, $10
	add hl, de
	inc bc
	call GetSeqByte
	ld [hl], a
	inc bc
	ret

EventDecay3:
;Set tertiary decay
;Parameters: xxxxxxxx (x = value)
	;Load parameter in RAM
	ld hl, $11
	add hl, de
	inc bc
	call GetSeqByte
	ld [hl], a
	inc bc
	ret

EventFinalVol:
;Set final channel volume
;Parameters: xxxxxxxx (x = value)
	;Load parameter in RAM
	ld hl, $05
	add hl, de
	inc bc
	call GetSeqByte
	ld [hl], a
	inc bc
	ret

EventSetDataFlag:
;Set the data flag - bit 3 makes a rest cut the note off
;Parameters: xxxxxxxx (x = value)
	;Load parameter in RAM
	ld hl, $2D
	add hl, de
	inc bc
	call GetSeqByte
	ld [hl], a
	inc bc
	ret

EventSpeed:
;Set channel speed
;Parameters: xxxxxxxx (x = value)
	;Load parameter in RAM
	ld hl, $09
	add hl, de
	inc bc
	call GetSeqByte
	and %00001111
	ld [hl], a
	inc bc
	ret

EventMacro1:
;Go to macro (subroutine) (1)
;Parameters: xxxxxxxx xxxxxxxx (X = position, absolute)
;(NOTE: 1 level only)
	;Get pointer from 2 parameters
	inc bc
	call GetSeqByte
	ld l, a
	inc bc
	call GetSeqByte
	ld h, a
	inc bc

	;Load pointer into RAM
	push hl
	ld hl, $26
	add hl, de
	ld [hl], c
	inc l
	ld [hl], b
	pop bc
	ret

EventMacro2:
;Go to macro (subroutine) (2)
;Parameters: xxxxxxxx xxxxxxxx (X = position, absolute)
;(NOTE: 1 level only)
;Get pointer from 2 parameters
	inc bc
	call GetSeqByte
	ld l, a
	inc bc
	call GetSeqByte
	ld h, a
	inc bc

	;Load pointer into RAM
	push hl
	ld hl, $28
	add hl, de
	ld [hl], c
	inc l
	ld [hl], b
	pop bc
	ret

EventMacro1Ret:
;Return from macro (subroutine) (1)
	;Go to position in RAM
	ld hl, $26
	add hl, de
	ld a, [hl+]
	ld b, [hl]
	ld c, a
	ret

EventMacro2Ret:
;Return from macro (subroutine) (2)
	;Go to position in RAM
	ld hl, $28
	add hl, de
	ld a, [hl+]
	ld b, [hl]
	ld c, a
	ret

EventRepeat1Start:
;Start repeat (1) after command
;(NOTE: 1 level only)
	;Load pointer in RAM
	inc bc
	ld hl, $22
	add hl, de
	ld a, c
	ld [hl+], a
	ld [hl], b

	;Set loop times to 0
	ld hl, $2A
	add hl, de
	ld [hl], 0
	ret

EventRepeat2Start:
;Start repeat (2) after command
;(NOTE: 1 level only)
	;Load pointer in RAM
	inc bc
	ld hl, $24
	add hl, de
	ld a, c
	ld [hl+], a
	ld [hl], b

	;Set loop times to 0
	ld hl, $2B
	add hl, de
	ld [hl], 0
	ret

EventRepeat1End:
	;End of repeat (1) - jump to start
	;Parameters: xxxxxxxx (x = times to repeat, 0 = infinite)
	;Check if times parameter is 0
	inc bc
	call GetSeqByte
	or a
	;If so, then repeat infinitely
	jr z, .EventRepeat1End_GoBack

	;Otherwise, get times currently repeated
	ld hl, $2A
	add hl, de
	push hl
	ld h, [hl]
	cp h
	pop hl
	;If done repeating, then continue ahead
	jr z, EventRepeatEnd_Done

	;Otherwise, increase value and go to repeat start
	inc [hl]

;Go to repeat start
.EventRepeat1End_GoBack
	ld hl, $22
	add hl, de
	ld a, [hl+]
	ld c, a
	ld b, [hl]
	ret

;Reset repeat count and continue ahead
EventRepeatEnd_Done:
	ld [hl], 0
	jp EventNop

EventRepeat2End:
;End of repeat (2) - jump to start
;Parameters: xxxxxxxx (x = times to repeat, 0 = infinite)
	;Check if times parameter is 0
	inc bc
	call GetSeqByte
	or a
	;If so, then repeat infinitely
	jr z, .EventRepeat2End_GoBack

	;Otherwise, get times currently repeated
	ld hl, $2B
	add hl, de
	push hl
	ld h, [hl]
	cp h
	pop hl
	;If done repeating, then continue ahead
	jr z, EventRepeatEnd_Done

	;Otherwise, increase value and go to repeat start
	inc [hl]

;Go to repeat start
.EventRepeat2End_GoBack
	ld hl, $24
	add hl, de
	ld a, [hl+]
	ld c, a
	ld b, [hl]
	ret

EventEnd:
;End of track
	;Get channel mask and add to output
	ld a, [CurTrackCheck]
	add LOW(ChanMaskVals)
	ld c, a
	ld a, HIGH(ChanMaskVals)
	adc 0
	ld b, a
	ld a, [bc]
	ld hl, Output
	and [hl]
	ld [hl], a

	;If SFX 1, then reset sweep
	ld a, [CurTrackCheck]
	cp 4
	jr z, .EventEnd_ResetSweep

	;Otherwise, if channel 1, then set decay to 8
	and %00000011
	jr z, .EventEnd_DecayVol8

	;If music 4, then set decay and volume to 0
	cp 3
	jr nz, .EventEnd_DecayVol0

.EventEnd_DecayVol8
	ld a, 8
	jr .EventEnd_2

.EventEnd_DecayVol0
	xor a

.EventEnd_2
	;Set decay
	ld hl, $0B
	add hl, de
	ld [hl], a

	;Set current volume
	ld hl, $1F
	add hl, de
	ld [hl], a

	;Set frequency to 0
	xor a
	ld hl, $1D
	add hl, de
	ld [hl+], a
	ld [hl], a

	;Also clear music number and priority
	ld h, d
	ld l, e
	ld [hl+], a
	ld [hl+], a

	;Reset sweep
	ld a, %00001000
	ld [hl], a
	pop hl
	ret

.EventEnd_ResetSweep
	;Reset sweep
	ld a, %00001000
	ldh [rNR10], a
	ld [NR10Val], a
	jr .EventEnd_DecayVol8

ChanMaskVals:
	db $FE, $FD, $FB, $F7, $EF, $DF, $BF, $7F

Vol3LUT:
	db $00, $60, $40, $40, $40, $40, $40, $40
	db $20, $20, $20, $20, $20, $20, $20, $20

Duty1PanTab:
	db $11, $01, $10, $11

Duty2PanTab:
	db $22, $02, $20, $22

Duty3PanTab:
	db $44, $04, $40, $44

Duty4PanTab:
	db $88, $08, $80, $88

ProcTrackRegVals:
	;Get pointer for track routine
	ld a, [CurTrackCheck]
	add a
	add LOW(PrepStates)
	ld l, a
	ld a, HIGH(PrepStates)
	adc 0
	ld h, a
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	jp hl

PrepStates:
	dw MusC1Prep
	dw MusC2Prep
	dw MusC3Prep
	dw MusC4Prep
	dw SFXC1Prep
	dw SFXC2Prep
	dw SFXC3Prep
	dw SFXC4Prep

MusC1Prep:
	;Check if SFX is playing in channel 1
	ld hl, SFXC1MusNum
	ld a, [hl]
	or a
	;Return if so
	ret nz

;Otherwise, get duty/pan value from table
SFXC1Prep:
	ld hl, $06
	add hl, de
	ld a, [hl]
	and %00000011
	add LOW(Duty1PanTab)
	ld l, a
	ld a, HIGH(Duty1PanTab)
	adc 0
	ld h, a

	;Load into NR51 RAM value
	ld bc, NR51Val
	ld a, [bc]
	and %11101110
	or [hl]
	ld [bc], a

	;Load sweep into NR10 RAM value
	ld bc, NR10Val
	ld hl, $02
	;Combine the four music channels' song numbers into a
	;"music playing" flag for the rest of the game to read
	add hl, de
	ld a, [hl]
	ld [bc], a

	;Load note time into "gate off" value
	inc bc
	ld hl, $2C
	add hl, de
	ld a, [hl]
	and %00100000
	xor %00100000
	ld [Gate1Off], a

MusC1Prep_2:
	;If note time is 0, then set duty/volume value to it
	or a
	jr z, MusC1Prep_3A

	;Otherwise, set it and swap
	ld hl, $0A
	add hl, de
	ld a, [hl]
	swap a
	jr MusC1Prep_3B

MusC1Prep_3A:
	ld hl, $0A
	add hl, de
	ld a, [hl]

MusC1Prep_3B:
	;Set NR11 wave duty
	and %11000000
	ld [bc], a

	;Then check if envelope is on
	inc bc
	ld hl, $2D
	add hl, de
	ld a, [hl]
	and %00001000
	jr z, MusC1Prep_4
	ld hl, $2C
	add hl, de
	ld a, [hl]
	and %00000010
	jr z, MusC1Prep_4

	;If not, then use empty value
	ld a, %00001000
	jr MusC1Prep_5

MusC1Prep_4:
	;Get hardware volume
	ld hl, $1F
	add hl, de
	ld a, [hl]

MusC1Prep_5:
	;Set NR12 value to it
	ld [bc], a
	inc bc

MusC1Prep_6:
	;Get tuning
	ld hl, $04
	add hl, de
	ld a, [hl]

	;And add to vibrato
	ld hl, $1C
	add hl, de
	add [hl]
	inc l

	;Check if positive or negative
	bit 7, a
	jr nz, MusC1Prep_Neg

	;If positive, then add to frequency
	add [hl]
	;And set NR13 value to it
	ld [bc], a
	inc l
	ld a, [hl]
	adc 0

MusC1Prep_7:
	;Set NR14 value
	inc bc
	and %00000111
	ld [bc], a
	ld hl, $2C
	add hl, de
	bit 5, [hl]
	ret z
	res 5, [hl]
	ld a, [bc]
	or %10000000
	ld [bc], a

MusC4Prep:
	;Do nothing
	ret

MusC1Prep_Neg:
	;If negative, then add negative to frequency
	add [hl]
	ld [bc], a
	inc l
	ld a, [hl]
	adc -1
	jr MusC1Prep_7

MusC2Prep:
	;Check if SFX is playing in channel 2
	ld hl, SFXC2MusNum
	ld a, [hl]
	or a
	;Return if so
	ret nz

;Otherwise, get duty/pan value from table
SFXC2Prep:
	ld hl, $06
	add hl, de
	ld a, [hl]
	and %00000011
	add LOW(Duty2PanTab)
	ld l, a
	ld a, HIGH(Duty2PanTab)
	adc 0
	ld h, a

	;Load into NR51 RAM value
	ld bc, NR51Val
	ld a, [bc]
	and %11011101
	or [hl]
	ld [bc], a

	;Load note time into "gate off" value
	ld bc, NR21Val
	ld hl, $2C
	add hl, de
	ld a, [hl]
	and %00100000
	xor %00100000
	ld [Gate2Off], a
	jp MusC1Prep_2

MusC3Prep:
	;Check if music is playing in SFX channel 3
	ld hl, SFXC3MusNum
	ld a, [hl]
	or a
	;Return if so
	ret nz

;Otherwise, get duty/pan value from table
SFXC3Prep:
	ld hl, $06
	add hl, de
	ld a, [hl]
	and %00000011
	add LOW(Duty3PanTab)
	ld l, a
	ld a, HIGH(Duty3PanTab)
	adc 0
	ld h, a

	;Load into NR51 RAM value
	ld bc, NR51Val
	ld a, [bc]
	and %10111011
	or [hl]
	ld [bc], a

	;Load "on" value into NR10 RAM value
	ld bc, NR30Val
	ld a, %10000000
	ld [bc], a
	inc bc
	xor a
	ld [bc], a
	inc bc

	;Then check the data flag
	ld hl, $2D
	add hl, de
	ld a, [hl]
	and %00001000
	;If rest bit is not set, then get hardware volume from LUT
	jr z, SFXC3Prep_1B
	;Otherwise, check the note flag
	ld hl, $2C
	add hl, de
	ld a, [hl]
	;If bit 1 is not set, then is a rest
	and %00000010
	jr z, SFXC3Prep_1B
	xor a
	jr SFXC3Prep_2

SFXC3Prep_1B:
	;Otherwise, get hardware volume
	ld hl, $1F
	add hl, de
	ld a, [hl]

	;Get volume from look-up table
	swap a
	and %00001111
	push bc
	add LOW(Vol3LUT)
	ld c, a
	ld a, HIGH(Vol3LUT)
	adc 0
	ld b, a
	ld a, [bc]
	pop bc

;Set NR33
SFXC3Prep_2:
	ld [bc], a
	inc bc
	call MusC1Prep_6
	ldh a, [rNR52]
	and %00000100
	ret nz
	ld a, [bc]
	or %10000000
	ld [bc], a
	ret

SFXC4Prep:
	;Get duty/pan value from table
	ld hl, $06
	add hl, de
	ld a, [hl]
	and %00000011
	add LOW(Duty4PanTab)
	ld l, a
	ld a, HIGH(Duty4PanTab)
	adc 0
	ld h, a

	;Load into NR51 RAM value
	ld bc, NR51Val
	ld a, [bc]
	and %01110111
	or [hl]
	ld [bc], a

	;Point BC at the first register shadow this channel writes
	ld bc, NR42Val
	ld hl, $2C
	add hl, de
	ld a, [hl]

	;Turn the "new note" flag into the "gate off" value the output
	;routines want. Bit 5 of NoteFlags is set when this step started a
	;note, and the xor inverts it, so the variable ends up 0 on a new
	;note and $20 while one is still running - OutputRegTrig tests it
	;with `or a`, so zero is what asks for a retrigger.
	
	and %00100000
	xor %00100000
	ld [Gate4Off], a
	or a
	jr nz, .SFXC4Prep_1B
	
	;The noise channel has no sweep and its registers run NR41-NR44, so
	;it does not share the tail above - its trigger bit goes straight
	;into the NR44 shadow here.
	ld a, %10000000
	ld [NR44Val], a

.SFXC4Prep_1B
	;Consume the flag either way.
	res 5, [hl]

	;Then check the data flag
	ld hl, $2D
	add hl, de
	ld a, [hl]
	
	;If "rest" bit set, then check note flag
	and %00001000
	jr z, SFXC4Prep_2
	ld hl, $2C
	add hl, de
	ld a, [hl]
	and %00000010
	;If bit not set, then use hardware volume
	jr z, SFXC4Prep_2

	;Otherwise, use this bit set
	ld a, %00001000
	jr SFXC4Prep_3

SFXC4Prep_2:
	;Get hardware volume
	ld hl, $1F
	add hl, de
	ld a, [hl]

SFXC4Prep_3:
	;Set NR42 value
	ld [bc], a
	inc bc

	;Finally, load frequency into NR43-NR44
	ld hl, $1D
	add hl, de
	ld a, [hl+]
	ld [bc], a
	inc bc
	ld a, [hl]
	ld [bc], a
	ret

OutputTracks:
	ld hl, NR10Val
	ld c, $10
	ld d, $7F
	;Check "gate off" value
	ld a, [Gate1Off]
	ld b, a
	or a
	;If gate off, set register value
	jr z, .SetRegVal
	
	;Otherwise leave channel 1 entirely alone if a sweep is running and its
	;shadow has not changed - rewriting rNR11-rNR14 would restart it. $08 is
	;the idle value, so that case falls through and writes normally.
	ldh a, [c]
	and d
	cp 8
	jr z, .SetRegVal
	cp [hl]
	jr nz, .SetRegVal
	inc l
	inc c
	inc l
	inc c
	inc l
	inc c
	inc l
	inc c
	inc l
	inc c
	jr OutputCh2Regs

.SetRegVal
	;rNR10 gets the shadow written to it twice in a row - the same value to
	;the same port. A deliberate workaround for a sweep quirk; no other
	;register is treated this way.
	ld a, [hl]
	ldh [c], a
	ldh [c], a
	inc l
	inc c
	ld d, $C0

;Channel 1, rNR11-rNR14. rNR10 was written above, before the skip test.
OutputCh1Regs:
	call OutputRegMasked
	ld a, b
	call OutputRegTrig
	ld a, b
	call OutputRegForce
	call OutputRegTrigClear

;Channel 2, rNR21-rNR24.
OutputCh2Regs:
	inc c
	ld d, %11000000
	call OutputRegMasked
	ld a, [Gate2Off]
	call OutputRegTrig
	call OutputRegForce
	call OutputRegTrigClear

;Channel 3, rNR30-rNR34. rNR31 is the length counter and is skipped.
OutputCh3Regs:
	ld d, %10000000
	call OutputRegMasked
	inc l
	inc c
	ld d, %01100000
	call OutputRegMasked
	call OutputRegForce
	call OutputRegTrigClear

;Channel 4, rNR42-rNR44. rNR41 is the length counter and is skipped.
OutputCh4Regs:
	inc c
	inc l
	inc c
	ld a, [Gate4Off]
	call OutputRegTrig
	ld d, $FF
	call OutputRegMasked
	call OutputRegTrigClear

	;Output NR50 and NR51 values
	ld hl, $FF24
	ld a, [NR50Val]
	ld [hl+], a
	ld a, [NR51Val]
	ld [hl+], a

	;Check if SFX on channel 3 is playing
	ld a, [SFXC3MusNum]
	or a
	;If so, set SFX waveform
	jr nz, SetSFXWaveform

;Otherwise, set music waveform
SetMusWaveform:
	ld a, [MusC3DutyVol]
	jr LoadWaveform

SetSFXWaveform:
	ld a, [SFXC3DutyVol]

LoadWaveform:
	;If waveform is same, then return
	ld hl, NewWave
	cp [hl]
	ret z

	;Otherwise, load new waveform - get pointer to waveform from table
	ld [hl], a
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

	;Load all bytes of the waveform into wave RAM
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

	;Turn on CH3 DAC
	ld a, %10000000
	ldh [rNR30], a

	;Set CH3 trigger bit on
	ld a, [NR34Val]
	or %10000000
	ldh [rNR34], a
	ret

OutputRegTrig:
	;Check "gate off" value
	or a
	;If gate off, get new value and set trigger
	jr z, OutputRegTrig_2
	ldh a, [c]
	cp [hl]
	jr z, SkipReg

OutputRegTrig_2:
	;Get next register value from RAM
	ld a, [hl+]
	;Also load in real register
	ldh [c], a
	inc l
	set 7, [hl]
	dec l
	inc c
	ret

OutputRegMasked:
	ldh a, [c]
	and d

	;Otherwise, check if main value is the same
	cp [hl]
	;If so, then return
	jr z, SkipReg

;Otherwise, output new value
OutputRegForce:
	ld a, [hl]
	ldh [c], a

SkipReg:
	inc l
	inc c
	ret

OutputRegTrigClear:
	ld a, [hl]
	ldh [c], a
	and %00000111
	ld [hl], a
	inc l
	inc c
	ret

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

TrackRAMPtrs:
	;Each track's RAM block, looked up by track number - the blocks are
	;not evenly spaced, so the engine keeps a pointer table instead.
	dw MusC1MusNum
	dw MusC2MusNum
	dw MusC3MusNum
	dw MusC4MusNum
	dw SFXC1MusNum
	dw SFXC2MusNum
	dw SFXC3MusNum
	dw SFXC4MusNum

TrackMaskVals:
	db $01, $02, $04, $08, $10, $20, $40, $80

SongTab:
	;Percussion
	dw Perc_Empty
	dw Perc01
	dw Perc02
	dw Perc03
	dw Perc04
	dw Perc05
	dw FadeOutTrack
	;SFX
	dw SFX_Empty1
	dw SFX_Empty2
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
	;Music
	dw Mus43
	dw Mus44
	dw Mus45
	dw Mus46
	dw Mus47
	dw Mus48
	dw Mus49
	dw Mus4A
	dw Mus4B
	dw Mus4C
	dw Mus4D
	dw Mus4E
	dw Mus4F
	dw Mus50
	dw Mus51
	dw Mus52
	dw Mus53
	dw Mus54
	dw Mus55
	dw Mus56
	dw Mus57
	dw Mus58
	dw Mus59
	dw Mus5A
	dw Mus5B
	dw Mus5C
	dw Mus5D
	dw Mus5E
	dw Mus5F

Perc_Empty:
FadeOutTrack:
	db %00000000			;Channel mask
	db 0					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data

UnusedData_4CCB:
	db $CE
	db $3F

Perc01:
	db %10000000			;Channel mask
	db 0					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw Perc01D

Perc02:
	db %10000000			;Channel mask
	db 0					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw Perc02D

Perc03:
	db %10000000			;Channel mask
	db 0					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw Perc03D

Perc04:
	db %10000000			;Channel mask
	db 0					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw Perc04D

Perc05:
	db %10000000			;Channel mask
	db 0					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw Perc05D

SFX09:
	db %00001111			;Channel mask
	db 14					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX09A
	dw SFX09B
	dw SFX09C
	dw $3FCE

SFX0A:
	db %00001111			;Channel mask
	db 14					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX0AA
	dw SFX0AB
	dw SFX0AC
	dw $3FCE

SFX0B:
	db %00010000			;Channel mask
	db 14					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX0BA

SFX0C:
	db %00010000			;Channel mask
	db 14					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX0CA

SFX0D:
	db %00010000			;Channel mask
	db 14					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX0DA

SFX0E:
	db %00010000			;Channel mask
	db 14					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX0EA

SFX0F:
	db %00010000			;Channel mask
	db 14					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX0FA

SFX10:
	db %00010000			;Channel mask
	db 14					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX10A

SFX11:
	db %00010000			;Channel mask
	db 14					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX11A

SFX12:
	db %00010000			;Channel mask
	db 14					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX12A

SFX13:
	db %00010000			;Channel mask
	db 14					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX13A

SFX14:
	db %00010000			;Channel mask
	db 14					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX14A

SFX15:
	db %00010000			;Channel mask
	db 14					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX15A

SFX16:
	db %00010000			;Channel mask
	db 14					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX16A

SFX17:
	db %10000000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX17D

SFX18:
	db %10000000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX18D

SFX19:
	db %10000000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX19D

SFX1A:
	db %00010000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX1AA

SFX1B:
	db %10000000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX1BD

SFX1C:
	db %00010000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX1CA

SFX1D:
	db %10000000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX1DD

SFX1E:
	db %00010000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX1EA

SFX1F:
	db %00010000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX1FA

SFX20:
	db %00010000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX20A

SFX21:
	db %10000000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX21D

SFX22:
	db %10000000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX22D

SFX23:
	db %10000000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX23D

SFX24:
	db %10000000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX24D

SFX25:
	db %10010000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX25A
	dw SFX25D

SFX26:
	db %10010000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX26A
	dw SFX26D

SFX27:
	db %10010000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX27A
	dw SFX27D

SFX28:
	db %10010000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX28A
	dw SFX28D

SFX29:
	db %10010000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX29A
	dw SFX29D

SFX2A:
	db %10010000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX2AA
	dw SFX2AD

SFX2B:
	db %00010000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX2BA

SFX2C:
	db %00010000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX2CA

SFX2D:
	db %00010000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX2DA

SFX2E:
	db %10010000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX2EA
	dw SFX2ED

SFX2F:
	db %10010000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX2FA
	dw SFX2FD

SFX30:
	db %10010000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX30A
	dw SFX30D

SFX31:
	db %10000000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX31D

SFX32:
	db %10000000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX32D

SFX33:
	db %10000000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX33D

SFX34:
	db %00010000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX34A

SFX35:
	db %00010000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX35A

SFX36:
	db %10000000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX36D

SFX37:
	db %00010000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX37A

SFX38:
	db %00010000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX38A

SFX39:
	db %10000000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX39D

SFX3A:
	db %00010000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX3AA

SFX3B:
	db %00010000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX3BA

SFX3C:
	db %00010000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX3CA

SFX3D:
	db %10110000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX3DA
	dw SFX3DB
	dw SFX3DD

SFX3E:
	db %10000000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX3ED

SFX3F:
	db %10000000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX3FD

SFX40:
	db %00010000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX40A

SFX41:
	db %00010000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX41A

SFX42:
	db %00010000			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw SFX42A

SFX_Empty1:
	db %00001111			;Channel mask
	db 2					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw $3FCE
	dw $3FCE
	dw $3FCE
	dw $3FCE

SFX_Empty2:
	db %11110000			;Channel mask
	db 15					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw $3FCE
	dw $3FCE
	dw $3FCE
	dw $3FCE

Mus46:
	db %00001111			;Channel mask
	db 0					;Priority
	db AudioBank2			;ROM bank holding this entry's channel data
	dw Mus46A
	dw Mus46B
	dw Mus46C
	dw $3FCE

Mus47:
	db %00001111			;Channel mask
	db 0					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw Mus47A
	dw Mus47B
	dw Mus47C
	dw $3FCE

Mus51:
	db %00001111			;Channel mask
	db 0					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw Mus51A
	dw Mus51B
	dw Mus51C
	dw EmptySeq2

Mus58:
	db %00001111			;Channel mask
	db 0					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw Mus58A
	dw Mus58B
	dw Mus58C
	dw Mus58D

Mus4F:
	db %00001111			;Channel mask
	db 0					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw Mus4FA
	dw Mus4FB
	dw Mus4FC
	dw Mus4FD

Mus50:
	db %00001111			;Channel mask
	db 0					;Priority
	db AudioBank1			;ROM bank holding this entry's channel data
	dw Mus50A
	dw Mus50B
	dw Mus50C
	dw EmptySeq

Mus43:
	db %00001111			;Channel mask
	db 0					;Priority
	db AudioBank2			;ROM bank holding this entry's channel data
	dw Mus43A
	dw SFX3DD
	dw Mus43C
	dw Mus43D

Mus44:
	db %00001111			;Channel mask
	db 0					;Priority
	db AudioBank2			;ROM bank holding this entry's channel data
	dw Mus44A
	dw Mus44B
	dw Mus44C
	dw $3FCE

Mus45:
	db %00001111			;Channel mask
	db 0					;Priority
	db AudioBank2			;ROM bank holding this entry's channel data
	dw Mus45A
	dw Mus45B
	dw Mus45C
	dw $3FCE

Mus48:
	db %00001111			;Channel mask
	db 0					;Priority
	db AudioBank2			;ROM bank holding this entry's channel data
	dw Mus48A
	dw Mus48B
	dw Mus48C
	dw $3FCE

Mus49:
	db %00001111			;Channel mask
	db 0					;Priority
	db AudioBank2			;ROM bank holding this entry's channel data
	dw Mus49A
	dw Mus49B
	dw Mus49C
	dw $3FCE

Mus4A:
	db %00001111			;Channel mask
	db 0					;Priority
	db AudioBank2			;ROM bank holding this entry's channel data
	dw Mus4AA
	dw Mus4AB
	dw Mus4AC
	dw $3FCE

Mus4B:
	db %00001111			;Channel mask
	db 0					;Priority
	db AudioBank2			;ROM bank holding this entry's channel data
	dw Mus4BA
	dw Mus4BB
	dw Mus4BC
	dw $3FCE

Mus5F:
	db %00001111			;Channel mask
	db 0					;Priority
	db AudioBank2			;ROM bank holding this entry's channel data
	dw Mus5FA
	dw Mus5FB
	dw Mus5FC
	dw Mus5FD

Mus4C:
	db %00001111			;Channel mask
	db 0					;Priority
	db AudioBank2			;ROM bank holding this entry's channel data
	dw Mus4CA
	dw Mus4CB
	dw Mus4CC
	dw $3FCE

Mus4D:
	db %00001111			;Channel mask
	db 0					;Priority
	db AudioBank2			;ROM bank holding this entry's channel data
	dw Mus4DA
	dw Mus4DB
	dw Mus4DC
	dw $3FCE

Mus4E:
	db %00001111			;Channel mask
	db 0					;Priority
	db AudioBank2			;ROM bank holding this entry's channel data
	dw Mus4EA
	dw Mus4EB
	dw Mus4EC
	dw $3FCE

Mus52:
	db %00001111			;Channel mask
	db 0					;Priority
	db AudioBank2			;ROM bank holding this entry's channel data
	dw Mus52A
	dw Mus52B
	dw Mus52C
	dw $3FCE

Mus53:
	db %00001111			;Channel mask
	db 0					;Priority
	db AudioBank2			;ROM bank holding this entry's channel data
	dw Mus53A
	dw Mus53B
	dw Mus53C
	dw $3FCE

Mus54:
	db %00001111			;Channel mask
	db 0					;Priority
	db AudioBank2			;ROM bank holding this entry's channel data
	dw Mus54A
	dw Mus54B
	dw Mus54C
	dw Mus54D

Mus55:
	db %00001111			;Channel mask
	db 0					;Priority
	db AudioBank2			;ROM bank holding this entry's channel data
	dw Mus55A
	dw Mus55B
	dw Mus55C
	dw $3FCE

Mus56:
	db %00001111			;Channel mask
	db 0					;Priority
	db AudioBank2			;ROM bank holding this entry's channel data
	dw Mus56A
	dw Mus56B
	dw Mus56C
	dw Mus56D

Mus57:
	db %00001111			;Channel mask
	db 0					;Priority
	db AudioBank2			;ROM bank holding this entry's channel data
	dw SFX2FD
	dw Mus57B
	dw Mus57C
	dw $3FCE

Mus59:
	db %00001111			;Channel mask
	db 0					;Priority
	db AudioBank2			;ROM bank holding this entry's channel data
	dw Mus59A
	dw Mus59B
	dw Mus59C
	dw Mus59D

Mus5A:
	db %00001111			;Channel mask
	db 0					;Priority
	db AudioBank2			;ROM bank holding this entry's channel data
	dw Mus5AA
	dw Mus5AB
	dw Mus5AC
	dw $3FCE

Mus5B:
	db %00001111			;Channel mask
	db 0					;Priority
	db AudioBank2			;ROM bank holding this entry's channel data
	dw Mus5BA
	dw Mus5BB
	dw Mus5BC
	dw $3FCE

Mus5C:
	db %00001111			;Channel mask
	db 0					;Priority
	db AudioBank2			;ROM bank holding this entry's channel data
	dw Mus5CA
	dw Mus5CB
	dw SFX09C
	dw $3FCE

Mus5D:
	db %00001111			;Channel mask
	db 0					;Priority
	db AudioBank2			;ROM bank holding this entry's channel data
	dw Mus5DA
	dw Mus5DB
	dw Mus5DC
	dw $3FCE

Mus5E:
	db %00001111			;Channel mask
	db 0					;Priority
	db AudioBank2			;ROM bank holding this entry's channel data
	dw Mus5EA
	dw Mus5EB
	dw Mus5EC
	dw $3FCE

Perc01D:
	db $D7, $00, $70, $87, $11, $81
	db $F4, $08
	db $E0
	db $12
	db $FF

Perc02D:
	db $D7, $00, $A0, $8A, $14, $33
	db $F4, $08
	db $E0
	db $13
	db $FF

Perc03D:
	db $D7, $00, $80, $88, $11, $B1
	db $E1
	db $B2
	db $FF

Perc04D:
	db $D7, $00, $80, $88, $11, $B1
	db $E1
	db $B2
	db $FF

Perc05D:
	db $D1, $11, $00, $09
	db $E5
	db $32
	db $EE, $06
	db $31
	db $EE, $02
	db $31
	db $FF

SFX0AA:
	db $D1, $22, $00, $00, $0E
	db $E2
	db $03
	db $33
	db $63
	db $93
	db $E3
	db $03
	db $33
	db $63
	db $93
	db $E4
	db $03
	db $33
	db $63
	db $93
	db $EE, $04
	db $E4
	db $03
	db $33
	db $63
	db $93
	db $EE, $02
	db $E4
	db $03
	db $33
	db $63
	db $93
	db $FF

SFX0AB:
	db $D1, $11, $00, $00, $0C
	db $EF, $02
	db $F3, $03
	db $E2
	db $03
	db $33
	db $63
	db $93
	db $E3
	db $03
	db $33
	db $63
	db $93
	db $E4
	db $03
	db $33
	db $63
	db $93
	db $EE, $03
	db $E4
	db $03
	db $33
	db $63
	db $93
	db $EE, $01
	db $E4
	db $03
	db $33
	db $63
	db $93
	db $FF

SFX0AC:
	db $D1, $04, $86, $83
	db $E1
	db $63
	db $93
	db $E2
	db $03
	db $33
	db $63
	db $93
	db $E3
	db $03
	db $33
	db $63
	db $93
	db $E4
	db $03
	db $33
	db $FF

SFX0BA:
	db $D1, $22, $00, $00, $0E
	db $E3
	db $22
	db $E4
	db $22
	db $EE, $04
	db $E3
	db $22
	db $E4
	db $22
	db $EE, $02
	db $E3
	db $22
	db $E4
	db $22
	db $FF

SFX0CA:
	db $D1, $22, $00, $00, $0F
	db $EA, $17
	db $E3
	db $B4
	db $EE, $08
	db $B4
	db $EE, $04
	db $B4
	db $EE, $02
	db $B4
	db $FF

SFX0DA:
	db $D2, $22, $00, $00, $08
	db $EC, $FE
	db $E4
	db $01
	db $EE, $0A
	db $E3
	db $01
	db $EE, $0C
	db $31
	db $EE, $0E
	db $61
	db $91
	db $E4
	db $01
	db $EE, $03
	db $E3
	db $01
	db $31
	db $61
	db $91
	db $E4
	db $01
	db $FF

SFX0EA:
	db $D1, $11, $00, $00, $0F
	db $F4, $08
	db $C1
	db $E1
	db $42
	db $C4
	db $4E
	db $EE, $06
	db $45
	db $EE, $02
	db $45
	db $FF

SFX0FA:
	db $D1, $11, $00, $00, $09
	db $E4
	db $02
	db $EE, $0D
	db $E3
	db $92
	db $62
	db $32
	db $EE, $04
	db $E4
	db $02
	db $E3
	db $92
	db $62
	db $32
	db $FF

SFX10A:
	db $D1, $22, $00, $00, $0E
	db $E3
	db $92
	db $E4
	db $22
	db $EE, $04
	db $E3
	db $92
	db $E4
	db $22
	db $EE, $02
	db $E3
	db $92
	db $E4
	db $22
	db $FF

SFX11A:
	db $D1, $22, $00, $00, $0E
	db $E3
	db $62
	db $E4
	db $62
	db $EE, $04
	db $E3
	db $62
	db $E4
	db $62
	db $EE, $02
	db $E3
	db $62
	db $E4
	db $62
	db $FF

SFX12A:
	db $D1, $22, $00, $00, $0F
	db $E2
	db $93
	db $E3
	db $41
	db $21
	db $92
	db $EE, $06
	db $E2
	db $93
	db $E3
	db $41
	db $21
	db $92
	db $EE, $02
	db $E2
	db $93
	db $E3
	db $41
	db $21
	db $92
	db $FF

SFX13A:
	db $D1, $22, $00, $00, $05
	db $E5
	db $01
	db $EE, $07
	db $11
	db $EE, $0B
	db $21
	db $EE, $07
	db $32
	db $EE, $02
	db $01
	db $EE, $03
	db $11
	db $EE, $04
	db $21
	db $EE, $02
	db $32
	db $FF

SFX14A:
	db $D1, $22, $00, $00, $0F
	db $EA, $1C
	db $E2
	db $B6
	db $EA, $14
	db $EE, $0A
	db $E0
	db $76
	db $EE, $04
	db $76
	db $FF

SFX15A:
	db $D1, $11, $00, $00, $05
	db $E4
	db $83
	db $EE, $07
	db $A2
	db $EE, $0B
	db $E5
	db $01
	db $21
	db $EE, $07
	db $41
	db $61
	db $EE, $02
	db $E4
	db $83
	db $EE, $03
	db $A2
	db $EE, $04
	db $E5
	db $01
	db $21
	db $EE, $02
	db $41
	db $61
	db $FF

SFX16A:
	db $D1, $22, $F1, $00, $8F, $11, $F1
	db $E3
	db $32
	db $EE, $08
	db $82
	db $EE, $04
	db $82
	db $EE, $02
	db $84
	db $FF

SFX17D:
	db $D1, $01, $00, $06
	db $E5
	db $72
	db $EE, $0A
	db $62
	db $EE, $0E
	db $61
	db $EE, $0F
	db $62
	db $EE, $0A
	db $61
	db $EE, $06
	db $71
	db $EE, $04
	db $71
	db $FF

SFX18D:
	db $D1, $01, $00, $0F
	db $E6
	db $32
	db $42
	db $E8, $00
	db $E1
	db $52
	db $EE, $0A
	db $31
	db $21
	db $FF

SFX19D:
	db $D1, $01, $00, $0F
	db $E5
	db $52
	db $E8, $00
	db $E1
	db $02
	db $EE, $0A
	db $11
	db $21
	db $FF

SFX1AA:
	db $D1, $00, $00, $00, $0A
	db $EA, $1F
	db $E7
	db $45
	db $EE, $05
	db $45
	db $EE, $02
	db $45
	db $FF

SFX1BD:
	db $D1, $01, $00, $0E
	db $E5
	db $41
	db $E8, $00
	db $E1
	db $01
	db $FF

SFX1CA:
	db $D1, $22, $00, $00, $0F
	db $EA, $1C
	db $E3
	db $66
	db $EE, $03
	db $66
	db $FF

SFX1DD:
	db $D1, $01, $00, $0F
	db $E6
	db $51
	db $E5
	db $31
	db $E8, $00
	db $E1
	db $61
	db $EE, $0A
	db $22
	db $01
	db $FF

SFX1EA:
	db $D2, $22, $00, $00, $08
	db $E2
	db $91
	db $E3
	db $61
	db $EE, $0E
	db $E3
	db $21
	db $91
	db $61
	db $E4
	db $21
	db $E3
	db $91
	db $E4
	db $61
	db $EE, $08
	db $E3
	db $21
	db $91
	db $61
	db $E4
	db $21
	db $E3
	db $91
	db $E4
	db $61
	db $EE, $06
	db $E3
	db $21
	db $91
	db $61
	db $E4
	db $21
	db $E3
	db $91
	db $E4
	db $61
	db $EE, $04
	db $E3
	db $21
	db $91
	db $61
	db $E4
	db $21
	db $E3
	db $91
	db $E4
	db $61
	db $EE, $02
	db $E3
	db $21
	db $91
	db $61
	db $E4
	db $21
	db $E3
	db $91
	db $E4
	db $61
	db $FF

SFX1FA:
	db $D1, $11, $00, $00, $0E
	db $EA, $1F
	db $E5
	db $43
	db $EA, $08
	db $E2
	db $B1
	db $E3
	db $01
	db $31
	db $61
	db $91
	db $E4
	db $01
	db $31
	db $61
	db $91
	db $E5
	db $01
	db $31
	db $61
	db $93
	db $EE, $08
	db $E4
	db $91
	db $E5
	db $01
	db $31
	db $61
	db $93
	db $EE, $03
	db $E4
	db $91
	db $E5
	db $01
	db $31
	db $61
	db $93
	db $FF

SFX20A:
	db $D1, $22, $00, $00, $0E
	db $E2
	db $03
	db $33
	db $63
	db $93
	db $E3
	db $03
	db $33
	db $63
	db $93
	db $E4
	db $03
	db $33
	db $63
	db $93
	db $EE, $04
	db $E4
	db $03
	db $33
	db $63
	db $93
	db $EE, $02
	db $E4
	db $03
	db $33
	db $63
	db $93
	db $FF

SFX21D:
	db $D1, $01, $00, $0F
	db $E0
	db $32
	db $52
	db $E2
	db $01
	db $E0
	db $32
	db $52
	db $E2
	db $01
	db $EE, $0F
	db $E1
	db $01
	db $E0
	db $01
	db $EE, $0A
	db $04
	db $EE, $05
	db $01
	db $EE, $06
	db $E1
	db $01
	db $E0
	db $01
	db $EE, $04
	db $04
	db $EE, $02
	db $01
	db $EE, $03
	db $E1
	db $01
	db $E0
	db $01
	db $EE, $02
	db $04
	db $EE, $01
	db $01
	db $FF

SFX22D:
	db $D1, $01, $00, $06
	db $E6
	db $32
	db $EE, $0F
	db $34
	db $EE, $08
	db $34
	db $EE, $03
	db $33
	db $FF

SFX23D:
	db $D1, $01, $00, $06
	db $E6
	db $32
	db $EE, $0F
	db $3F
	db $EE, $08
	db $3C
	db $EE, $03
	db $33
	db $FF

SFX24D:
	db $D1, $01, $00, $0F
	db $E6
	db $22
	db $EE, $0F
	db $32
	db $22
	db $32
	db $22
	db $32
	db $22
	db $32
	db $22
	db $EE, $08
	db $34
	db $24
	db $EE, $03
	db $33
	db $FF

SFX25A:
	db $D2, $22, $B1, $00, $8B, $11, $F2
	db $EF, $FE
	db $E6
	db $03
	db $F1, $21
	db $0F
	db $FF

SFX25D:
	db $D2, $01, $F1, $8F, $11, $F2
	db $E0
	db $13
	db $F1, $21
	db $0F
	db $FF

SFX26A:
	db $D2, $11, $C1, $00, $8C, $11, $F1
	db $E5
	db $53
	db $B3
	db $83
	db $E6
	db $23
	db $E5
	db $B3
	db $E6
	db $53
	db $E9, $81
	db $F0, $88
	db $E5
	db $B3
	db $E6
	db $53
	db $E9, $31
	db $F0, $83
	db $E5
	db $B3
	db $E6
	db $53
	db $FF

SFX26D:
	db $D2, $01, $F1, $8F, $11, $F1
	db $E0
	db $13
	db $03
	db $13
	db $03
	db $13
	db $03
	db $E9, $C1
	db $F0, $8C
	db $E0
	db $13
	db $03
	db $E9, $61
	db $F0, $86
	db $E0
	db $13
	db $03
	db $FF

SFX27A:
	db $D5, $11, $C1, $00, $8C, $11, $F1
	db $E6
	db $51
	db $21
	db $E5
	db $B1
	db $81
	db $51
	db $E6
	db $21
	db $E5
	db $B1
	db $81
	db $51
	db $E5
	db $B1
	db $81
	db $51
	db $21
	db $E9, $81
	db $F0, $88
	db $E5
	db $81
	db $51
	db $21
	db $E9, $41
	db $F0, $84
	db $E5
	db $81
	db $51
	db $21
	db $FF

SFX27D:
	db $D5, $01, $F1, $8F, $11, $F1
	db $E0
	db $11
	db $01
	db $11
	db $01
	db $11
	db $01
	db $11
	db $01
	db $11
	db $01
	db $11
	db $01
	db $11
	db $E9, $C1
	db $F0, $8C
	db $11
	db $01
	db $11
	db $E9, $61
	db $F0, $86
	db $11
	db $01
	db $11
	db $FF

SFX28A:
	db $D1, $22, $00, $00, $06
	db $EA, $1C
	db $E3
	db $65
	db $FF

SFX28D:
	db $D1, $01, $00, $0F
	db $F4, $08
	db $E6
	db $64
	db $C1
	db $D4, $01, $A0, $8A, $30, $F3
	db $E5
	db $5A
	db $FF

SFX29A:
	db $D1, $22, $00, $00, $08
	db $EA, $1C
	db $E3
	db $65
	db $64
	db $FF

SFX29D:
	db $D1, $01, $00, $0F
	db $F4, $08
	db $E6
	db $64
	db $C1
	db $53
	db $C1
	db $D4, $01, $C0, $8C, $30, $F3
	db $E5
	db $5C
	db $FF

SFX2AA:
	db $D1, $22, $00, $00, $0A
	db $EA, $1C
	db $E3
	db $65
	db $64
	db $64
	db $FF

SFX2AD:
	db $D1, $01, $00, $0F
	db $F4, $08
	db $E6
	db $64
	db $C1
	db $53
	db $C1
	db $63
	db $C1
	db $D4, $01, $F0, $8F, $30, $F3
	db $E5
	db $5E
	db $FF

SFX2BA:
	db $D1, $22, $00, $00, $0F
	db $EA, $1B
	db $E3
	db $86
	db $EE, $05
	db $66
	db $FF

SFX2CA:
	db $D1, $22, $00, $00, $0F
	db $EA, $1B
	db $E3
	db $86
	db $E3
	db $86
	db $E3
	db $86
	db $EE, $05
	db $66
	db $FF

SFX2DA:
	db $D1, $22, $00, $00, $0F
	db $EA, $1B
	db $E3
	db $86
	db $E3
	db $86
	db $E3
	db $86
	db $EE, $0A
	db $E3
	db $86
	db $E3
	db $86
	db $EE, $08
	db $E3
	db $86
	db $EE, $05
	db $66
	db $FF

SFX2EA:
	db $D1, $11, $00, $00, $07
	db $E4
	db $41
	db $51
	db $61
	db $71
	db $81
	db $91
	db $EE, $0A
	db $A1
	db $B1
	db $E5
	db $01
	db $11
	db $EE, $08
	db $21
	db $32
	db $EE, $06
	db $E4
	db $A1
	db $B1
	db $E5
	db $01
	db $11
	db $21
	db $32
	db $EE, $03
	db $E4
	db $A1
	db $B1
	db $E5
	db $01
	db $11
	db $21
	db $32
	db $FF

SFX2ED:
	db $D2, $00, $B1, $91, $31, $C3
	db $E4
	db $2F
	db $FF

SFX2FA:
	db $D1, $11, $00, $00, $07
	db $E4
	db $41
	db $51
	db $61
	db $71
	db $81
	db $91
	db $EE, $0A
	db $A1
	db $B1
	db $E5
	db $01
	db $11
	db $21
	db $31
	db $41
	db $EE, $08
	db $31
	db $21
	db $11
	db $01
	db $E4
	db $B1
	db $A1
	db $91
	db $81
	db $71
	db $61
	db $EE, $06
	db $E4
	db $B1
	db $A1
	db $91
	db $81
	db $71
	db $61
	db $EE, $03
	db $E4
	db $B1
	db $A1
	db $91
	db $81
	db $71
	db $61
	db $FF

SFX2FD:
	db $D3, $00, $B1, $91, $31, $C3
	db $E4
	db $2C
	db $FF

SFX30A:
	db $D1, $22, $00, $00, $07
	db $E4
	db $41
	db $51
	db $61
	db $71
	db $81
	db $91
	db $EE, $0A
	db $A1
	db $B1
	db $E5
	db $01
	db $11
	db $21
	db $31
	db $41
	db $EE, $08
	db $31
	db $21
	db $11
	db $01
	db $E4
	db $B1
	db $A1
	db $91
	db $81
	db $71
	db $61
	db $EE, $06
	db $E4
	db $B1
	db $A1
	db $91
	db $81
	db $71
	db $61
	db $EE, $03
	db $E4
	db $B1
	db $A1
	db $91
	db $81
	db $71
	db $61
	db $FF

SFX30D:
	db $D3, $00, $F1, $94, $31, $C3
	db $E4
	db $3C
	db $FF

SFX31D:
	db $D5, $00, $B1, $91, $51, $C1
	db $E4
	db $1F
	db $FF

SFX32D:
	db $D1, $00, $00, $0C
	db $F4, $08
	db $E5
	db $24
	db $C1
	db $D5, $00, $B1, $91, $51, $C1
	db $E5
	db $2F
	db $FF

SFX33D:
	db $D1, $01, $00, $0F
	db $F4, $08
	db $E5
	db $45
	db $C9
	db $D5, $00, $F1, $8F, $51, $C1
	db $E5
	db $3F
	db $FF

SFX34A:
	db $D4, $10, $E1, $00, $8E, $11, $F1
	db $E5
	db $31
	db $21
	db $E4
	db $B1
	db $A1
	db $71
	db $61
	db $31
	db $21
	db $D4, $00, $81, $00, $88, $11, $F1
	db $71
	db $61
	db $31
	db $21
	db $D4, $00, $31, $00, $83, $11, $F1
	db $71
	db $61
	db $31
	db $21
	db $FF

SFX35A:
	db $D2, $21, $F1, $00, $8F, $11, $F1
	db $E1
	db $62
	db $71
	db $E1
	db $A2
	db $B1
	db $E2
	db $22
	db $31
	db $62
	db $71
	db $A2
	db $B1
	db $E3
	db $22
	db $31
	db $D2, $21, $81, $00, $88, $11, $F1
	db $E2
	db $71
	db $A2
	db $B1
	db $E3
	db $22
	db $31
	db $D2, $21, $31, $00, $83, $11, $F1
	db $E2
	db $71
	db $A2
	db $B1
	db $E3
	db $22
	db $31
	db $FF

SFX36D:
	db $D1, $01, $00, $0F
	db $E0
	db $11
	db $21
	db $31
	db $E1
	db $21
	db $31
	db $21
	db $E0
	db $31
	db $21
	db $E0
	db $11
	db $21
	db $31
	db $E1
	db $21
	db $31
	db $21
	db $E0
	db $31
	db $21
	db $E0
	db $11
	db $21
	db $31
	db $E1
	db $21
	db $31
	db $21
	db $E0
	db $31
	db $21
	db $EE, $0A
	db $E0
	db $11
	db $21
	db $31
	db $E1
	db $21
	db $31
	db $21
	db $E0
	db $31
	db $21
	db $EE, $08
	db $E0
	db $11
	db $21
	db $31
	db $E1
	db $21
	db $31
	db $21
	db $E0
	db $31
	db $21
	db $EE, $06
	db $E0
	db $11
	db $21
	db $31
	db $E1
	db $21
	db $31
	db $21
	db $E0
	db $31
	db $21
	db $EE, $03
	db $E0
	db $11
	db $21
	db $31
	db $E1
	db $21
	db $31
	db $21
	db $E0
	db $31
	db $21
	db $FF

SFX37A:
	db $D1, $22, $F1, $00, $96, $11, $F1
	db $EA, $17
	db $E1
	db $0B
	db $2A
	db $49
	db $68
	db $87
	db $E2
	db $06
	db $26
	db $46
	db $66
	db $86
	db $EE, $04
	db $66
	db $86
	db $EE, $02
	db $66
	db $86
	db $FF

SFX38A:
	db $D2, $11, $00, $00, $08
	db $E4
	db $61
	db $41
	db $EE, $0C
	db $21
	db $01
	db $E3
	db $A1
	db $E4
	db $01
	db $21
	db $41
	db $21
	db $01
	db $E8, $22
	db $E3
	db $A1
	db $81
	db $61
	db $41
	db $21
	db $01
	db $E2
	db $A1
	db $81
	db $61
	db $EE, $08
	db $A1
	db $81
	db $61
	db $EE, $04
	db $A1
	db $81
	db $61
	db $EE, $02
	db $A1
	db $81
	db $61
	db $FF

SFX39D:
	db $D4, $01, $00, $04
	db $E0
	db $01
	db $11
	db $21
	db $31
	db $EE, $08
	db $E1
	db $21
	db $31
	db $EE, $0C
	db $E2
	db $21
	db $31
	db $EE, $0F
	db $E3
	db $21
	db $31
	db $EE, $04
	db $E2
	db $21
	db $31
	db $E3
	db $21
	db $31
	db $EE, $02
	db $E2
	db $21
	db $31
	db $E3
	db $21
	db $31
	db $FF

SFX3AA:
	db $D1, $22, $00, $00, $0E
	db $EA, $17
	db $E1
	db $85
	db $66
	db $47
	db $28
	db $08
	db $E0
	db $AC
	db $AC
	db $EE, $0A
	db $AC
	db $EE, $04
	db $AC
	db $EE, $02
	db $AC
	db $FF

SFX3BA:
	db $D4, $00, $00, $00, $0F
	db $E2
	db $01
	db $31
	db $91
	db $61
	db $EC, $FE
	db $01
	db $31
	db $91
	db $61
	db $EC, $FC
	db $01
	db $31
	db $91
	db $61
	db $EE, $06
	db $31
	db $91
	db $61
	db $EE, $03
	db $31
	db $91
	db $61
	db $FF

SFX3CA:
	db $D1, $11, $00, $00, $0C
	db $EA, $1F
	db $E3
	db $43
	db $EA, $08
	db $E2
	db $B1
	db $E3
	db $01
	db $31
	db $61
	db $91
	db $81
	db $71
	db $61
	db $51
	db $41
	db $31
	db $21
	db $11
	db $01
	db $E2
	db $B1
	db $A1
	db $91
	db $81
	db $71
	db $61
	db $51
	db $41
	db $31
	db $21
	db $11
	db $01
	db $E1
	db $B1
	db $A1
	db $91
	db $81
	db $71
	db $61
	db $51
	db $41
	db $31
	db $21
	db $11
	db $01
	db $EE, $04
	db $91
	db $81
	db $71
	db $61
	db $51
	db $41
	db $31
	db $21
	db $11
	db $01
	db $EE, $02
	db $91
	db $81
	db $71
	db $61
	db $51
	db $41
	db $31
	db $21
	db $11
	db $01
	db $FF

SFX3DB:
	db $D1, $11, $00, $00, $0F
	db $EC, $0F
	db $F4, $08
	db $E2
	db $81
	db $41
	db $E3
	db $01
	db $E2
	db $81
	db $E3
	db $41
	db $01
	db $EE, $06
	db $C3
	db $E2
	db $81
	db $41
	db $E3
	db $01
	db $E2
	db $81
	db $E3
	db $41
	db $01
	db $EE, $03
	db $C3
	db $E2
	db $81
	db $41
	db $E3
	db $01
	db $E2
	db $81
	db $E3
	db $41
	db $01
	db $EE, $02
	db $C3
	db $E2
	db $81
	db $41
	db $E3
	db $01
	db $E2
	db $81
	db $E3
	db $41
	db $01
	db $FF

SFX3DA:
	db $D1, $11, $00, $00, $0F
	db $EC, $0F
	db $F4, $08
	db $E2
	db $41
	db $01
	db $E2
	db $81
	db $41
	db $E3
	db $01
	db $E2
	db $81
	db $EE, $06
	db $C3
	db $E2
	db $41
	db $01
	db $E2
	db $81
	db $41
	db $E3
	db $01
	db $E2
	db $81
	db $EE, $03
	db $C3
	db $E2
	db $41
	db $01
	db $E2
	db $81
	db $41
	db $E3
	db $01
	db $E2
	db $81
	db $EE, $02
	db $C3
	db $E2
	db $41
	db $01
	db $E2
	db $81
	db $41
	db $E3
	db $01
	db $E2
	db $81
	db $FF

SFX3DD:
	db $D1, $01, $00, $0F
	db $E6
	db $32
	db $E8, $00
	db $E1
	db $52
	db $EE, $0A
	db $31
	db $21
	db $FF

SFX3ED:
	db $D1, $01, $00, $0F
	db $F4, $08
	db $E5
	db $32
	db $22
	db $C1
	db $32
	db $22
	db $C1
	db $32
	db $22
	db $C1
	db $EE, $08
	db $32
	db $22
	db $C1
	db $32
	db $22
	db $C1
	db $32
	db $22
	db $C1
	db $EE, $06
	db $32
	db $22
	db $C1
	db $32
	db $22
	db $C1
	db $32
	db $22
	db $C1
	db $EE, $03
	db $32
	db $22
	db $C1
	db $32
	db $22
	db $C1
	db $32
	db $22
	db $C1
	db $FF

SFX3FD:
	db $D1, $01, $00, $0F
	db $E6
	db $32
	db $42
	db $E8, $00
	db $C2
	db $E1
	db $42
	db $E2
	db $32
	db $E3
	db $42
	db $E4
	db $32
	db $42
	db $E5
	db $32
	db $42
	db $FF

SFX40A:
	db $D1, $11, $00, $00, $0F
	db $EA, $1F
	db $E1
	db $02
	db $42
	db $EE, $0D
	db $82
	db $E8, $00
	db $92
	db $72
	db $52
	db $32
	db $12
	db $E0
	db $B2
	db $EE, $08
	db $E1
	db $92
	db $72
	db $52
	db $32
	db $12
	db $E0
	db $B2
	db $EE, $04
	db $E1
	db $92
	db $72
	db $52
	db $32
	db $12
	db $E0
	db $B2
	db $EE, $02
	db $E1
	db $92
	db $72
	db $52
	db $32
	db $12
	db $E0
	db $B2
	db $FF

SFX41A:
	db $D1, $11, $00, $00, $0E
	db $EA, $2F
	db $E4
	db $21
	db $B1
	db $A2
	db $E8, $00
	db $92
	db $82
	db $72
	db $62
	db $52
	db $42
	db $32
	db $22
	db $12
	db $02
	db $E3
	db $B1
	db $EE, $08
	db $E4
	db $42
	db $32
	db $22
	db $12
	db $02
	db $E3
	db $B1
	db $EE, $04
	db $E4
	db $42
	db $32
	db $22
	db $12
	db $02
	db $E3
	db $B1
	db $EE, $02
	db $E4
	db $42
	db $32
	db $22
	db $12
	db $02
	db $E3
	db $B1
	db $FF

SFX42A:
	db $D1, $11, $00, $00, $0E
	db $EA, $1E
	db $E3
	db $73
	db $EA, $16
	db $E2
	db $1A
	db $EE, $08
	db $1A
	db $EE, $06
	db $1A
	db $EE, $04
	db $1A
	db $EE, $02
	db $1A
	db $FF

EnvSeqTab:
	dw EnvSeq00
	dw EnvSeq01
	dw EnvSeq02
	dw EnvSeq03
	dw EnvSeq04
	dw EnvSeq05
	dw EnvSeq06
	dw EnvSeq07
	dw EnvSeq08
	dw EnvSeq09
	dw EnvSeq0A
	dw EnvSeq0B
	dw EnvSeq0C
	dw EnvSeq0D
	dw EnvSeq0E
	dw EnvSeq0F
	dw EnvSeq10
	dw EnvSeq11

EnvSeq00:
	db $8F
	db $FF

EnvSeq01:
	db $1F
	db $FF

EnvSeq02:
	db $2F
	db $FF

EnvSeq03:
	db $3F
	db $FF

EnvSeq04:
	db $4F
	db $FF

EnvSeq05:
	db $5F
	db $FF

EnvSeq06:
	db $6F
	db $FF

EnvSeq07:
	db $7F
	db $FF

EnvSeq08:
	db $8F
	db $FF

EnvSeq09:
	db $9F
	db $FF

EnvSeq0A:
	db $AF
	db $FF

EnvSeq0B:
	db $BF
	db $FF

EnvSeq0C:
	db $CF
	db $FF

EnvSeq0D:
	db $DF
	db $FF

EnvSeq0E:
	db $EF
	db $FF

EnvSeq0F:
	db $FE
	db $FF

EnvSeq10:
	db $84, $51, $21, $11
	db $FF

EnvSeq11:
	db $A1, $91, $81, $72
	db $11, $35, $25, $1F
	db $FF

VibTab:
	dw Vibrato0
	dw Vibrato1
	dw Vibrato2
	dw Vibrato3
	dw Vibrato4
	dw Vibrato5
	dw Vibrato6
	dw Vibrato7
	dw Vibrato8
	dw Vibrato8
	dw Vibrato8
	dw Vibrato8
	dw Vibrato8
	dw Vibrato8
	dw Vibrato8
	dw Vibrato8

Vibrato0:
	db $0F
	db $FF

Vibrato1:
	db $14, $03, $F4, $03
	db $FF

Vibrato2:
	db $11, $22, $11, $02
	db $F1, $E2, $F1, $02
	db $FF

Vibrato3:
	db $21, $32, $21, $02
	db $E1, $D2, $E1, $02
	db $FF

Vibrato4:
	db $21, $42, $21, $02
	db $E1, $C2, $E1, $02
	db $FF

Vibrato5:
	db $31, $52, $31, $02
	db $D1, $B2, $D1, $02
	db $FF

Vibrato6:
	db $31, $62, $31, $02
	db $D1, $A2, $D1, $02
	db $FF

Vibrato7:
	db $41, $72, $41, $02
	db $C1, $92, $C1, $02
	db $FF

Vibrato8:
	db $41, $72, $41, $02
	db $C1, $92, $C1, $02
	db $FF

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

Mus47B:
	db $FB
	db $D1, $11, $B1, $53, $8B, $36, $93
	db $F4, $08
	db $E1
	db $7F
	db $E2
	db $20
	db $10
	db $1F
	db $50
	db $10
	db $40
	db $17
	db $C8
	db $47
	db $C3
	db $48
	db $C2
	db $4B
	db $E1
	db $A0
	db $2E
	db $C0
	db $10
	db $7F
	db $E2
	db $20
	db $10
	db $1F
	db $50
	db $10
	db $40
	db $17
	db $C8
	db $47
	db $C3
	db $48
	db $C2
	db $4B
	db $E1
	db $60
	db $2E
	db $C0
	db $10
	db $7F
	db $E2
	db $20
	db $10
	db $1F
	db $50
	db $10
	db $40
	db $17
	db $C8
	db $AA
	db $E3
	db $1A
	db $7B
	db $60
	db $17
	db $58
	db $60
	db $1F
	db $77
	db $C8
	db $68
	db $C8
	db $50
	db $55
	db $C8
	db $2F
	db $E2
	db $90
	db $10
	db $E3
	db $0F
	db $30
	db $10
	db $20
	db $1F
	db $E2
	db $90
	db $1F
	db $E3
	db $00
	db $1F
	db $E2
	db $A0
	db $17
	db $68
	db $9F
	db $70
	db $10
	db $90
	db $3E
	db $AF
	db $C8
	db $A8
	db $90
	db $5D
	db $AF
	db $C8
	db $A8
	db $90
	db $5D
	db $C0
	db $1F
	db $D1, $22, $B1, $54, $98, $36, $93
	db $3A
	db $5A
	db $7B
	db $E3
	db $00
	db $1F
	db $20
	db $1F
	db $3F
	db $C8
	db $38
	db $20
	db $1F
	db $E2
	db $A0
	db $1F
	db $70
	db $2E
	db $A8
	db $88
	db $70
	db $17
	db $68
	db $70
	db $55
	db $C8
	db $5A
	db $7A
	db $9B
	db $E3
	db $20
	db $1F
	db $40
	db $1F
	db $5F
	db $C8
	db $58
	db $40
	db $1F
	db $00
	db $1F
	db $50
	db $2E
	db $48
	db $28
	db $00
	db $17
	db $E2
	db $A8
	db $90
	db $17
	db $A8
	db $95
	db $A5
	db $95
	db $A5
	db $95
	db $A6
	db $95
	db $A5
	db $E9, $90
	db $95
	db $A5
	db $E9, $70
	db $95
	db $E9, $50
	db $A6
	db $FD, $00

Mus47A:
	db $FB
	db $D1, $11, $61, $53, $86, $43, $95
	db $F4, $08
	db $EF, $FF
	db $E1
	db $70
	db $17
	db $E2
	db $20
	db $10
	db $1F
	db $50
	db $10
	db $40
	db $1F
	db $4A
	db $4A
	db $4B
	db $E1
	db $A0
	db $3E
	db $7F
	db $E2
	db $20
	db $10
	db $1F
	db $50
	db $10
	db $40
	db $1F
	db $4A
	db $4A
	db $4B
	db $E1
	db $60
	db $16
	db $D7, $11, $91, $F0, $80, $20, $13
	db $F4, $00
	db $EF, $00
	db $E3
	db $F6, $0A
	db $E9, $71
	db $F6, $01
	db $28
	db $98
	db $E4
	db $28
	db $67
	db $78
	db $68
	db $58
	db $47
	db $58
	db $68
	db $78
	db $67
	db $58
	db $E2
	db $C0
	db $17
	db $E9, $91
	db $48
	db $C3
	db $48
	db $C2
	db $4A
	db $E1
	db $A0
	db $18
	db $97
	db $A0
	db $1F
	db $E2
	db $20
	db $10
	db $18
	db $27
	db $30
	db $10
	db $28
	db $37
	db $40
	db $18
	db $C7
	db $48
	db $C3
	db $48
	db $C2
	db $4A
	db $60
	db $10
	db $2F
	db $30
	db $10
	db $E1
	db $9F
	db $70
	db $10
	db $E2
	db $2F
	db $10
	db $10
	db $5F
	db $30
	db $10
	db $E1
	db $9F
	db $E2
	db $20
	db $3E
	db $00
	db $1F
	db $E1
	db $70
	db $10
	db $E2
	db $2F
	db $10
	db $10
	db $5F
	db $60
	db $18
	db $C7
	db $68
	db $C3
	db $68
	db $C2
	db $6A
	db $20
	db $3E
	db $E1
	db $C0
	db $10
	db $9F
	db $80
	db $10
	db $AF
	db $90
	db $18
	db $C7
	db $98
	db $C3
	db $98
	db $C2
	db $98
	db $C2
	db $70
	db $18
	db $E2
	db $C7
	db $3B
	db $5A
	db $7A
	db $50
	db $10
	db $38
	db $27
	db $00
	db $1F
	db $E1
	db $A0
	db $10
	db $E2
	db $0F
	db $20
	db $10
	db $5F
	db $C0
	db $10
	db $5F
	db $30
	db $10
	db $2F
	db $00
	db $10
	db $E1
	db $AF
	db $E2
	db $30
	db $10
	db $0F
	db $20
	db $10
	db $38
	db $27
	db $00
	db $10
	db $E1
	db $AF
	db $90
	db $18
	db $E2
	db $C7
	db $5B
	db $7A
	db $9A
	db $70
	db $10
	db $58
	db $47
	db $20
	db $1F
	db $00
	db $10
	db $2F
	db $40
	db $10
	db $7F
	db $90
	db $10
	db $78
	db $57
	db $40
	db $10
	db $5F
	db $00
	db $10
	db $2F
	db $40
	db $10
	db $E1
	db $9F
	db $E2
	db $00
	db $10
	db $E1
	db $AF
	db $98
	db $C8
	db $E9, $B0
	db $6F
	db $C1
	db $FD, $00

Mus47C:
	db $D1, $04, $85, $73
	db $F4, $08
	db $FB
	db $FC
	db $E0
	db $70
	db $1F
	db $E1
	db $20
	db $1F
	db $FE, $04
	db $E0
	db $90
	db $1F
	db $E1
	db $00
	db $1F
	db $FC
	db $E0
	db $70
	db $1F
	db $E1
	db $20
	db $1F
	db $FE, $01
	db $E0
	db $60
	db $1F
	db $E1
	db $10
	db $1F
	db $FC
	db $E0
	db $70
	db $1F
	db $E1
	db $20
	db $1F
	db $FE, $01
	db $E0
	db $60
	db $1F
	db $E1
	db $20
	db $1F
	db $E0
	db $70
	db $1F
	db $E1
	db $10
	db $1F
	db $00
	db $1F
	db $E0
	db $90
	db $1F
	db $A0
	db $1F
	db $E1
	db $20
	db $1F
	db $E0
	db $70
	db $1F
	db $A0
	db $1F
	db $E1
	db $20
	db $1F
	db $E0
	db $90
	db $1F
	db $E1
	db $6F
	db $00
	db $10
	db $2F
	db $E0
	db $90
	db $10
	db $E1
	db $20
	db $1F
	db $00
	db $1F
	db $20
	db $1F
	db $60
	db $1F
	db $00
	db $1F
	db $E0
	db $70
	db $1F
	db $E1
	db $00
	db $1F
	db $70
	db $1F
	db $50
	db $1F
	db $E0
	db $A0
	db $1F
	db $FC
	db $E1
	db $30
	db $1F
	db $E0
	db $A0
	db $1F
	db $FE, $02
	db $E1
	db $20
	db $1F
	db $E0
	db $90
	db $1F
	db $E1
	db $20
	db $1F
	db $90
	db $1F
	db $70
	db $1F
	db $00
	db $1F
	db $50
	db $1F
	db $00
	db $1F
	db $50
	db $1F
	db $00
	db $1F
	db $20
	db $1F
	db $E0
	db $97
	db $E1
	db $C8
	db $00
	db $10
	db $FD, $00

Mus4FB:
	db $D2, $11, $B2, $00, $8B, $32, $44
	db $F4, $08
	db $E3
	db $04
	db $E2
	db $74
	db $E3
	db $04
	db $44
	db $74
	db $E4
	db $04
	db $E3
	db $94
	db $54
	db $94
	db $B3
	db $E3
	db $23
	db $73
	db $E4
	db $23
	db $49
	db $53
	db $70
	db $18
	db $FF

Mus4FA:
	db $D2, $11, $A2, $00, $8A, $32, $44
	db $F4, $08
	db $E2
	db $44
	db $04
	db $44
	db $74
	db $E3
	db $04
	db $44
	db $04
	db $E2
	db $94
	db $E3
	db $04
	db $23
	db $E2
	db $73
	db $B3
	db $E3
	db $73
	db $E4
	db $09
	db $E3
	db $B3
	db $E4
	db $00
	db $18
	db $FF

Mus4FC:
	db $D2, $05, $8A, $CF
	db $F4, $08
	db $E1
	db $74
	db $44
	db $74
	db $E2
	db $04
	db $44
	db $74
	db $54
	db $04
	db $54
	db $73
	db $E1
	db $B3
	db $E2
	db $23
	db $73
	db $E3
	db $09
	db $23
	db $40
	db $18
	db $FF

Mus4FD:
	db $D2
	db $3C
	db $34
	db $34
	db $34
	db $3C
	db $34
	db $34
	db $34
	db $39
	db $33
	db $30
	db $18
	db $FF

Mus50B:
	db $D6, $00, $B2, $00, $8B, $32, $44
	db $F4, $08
	db $E2
	db $21
	db $11
	db $71
	db $E3
	db $21
	db $E4
	db $21
	db $21
	db $51
	db $21
	db $E3
	db $81
	db $81
	db $B1
	db $81
	db $51
	db $E2
	db $51
	db $81
	db $E3
	db $21
	db $B1
	db $E4
	db $51
	db $82
	db $FF

Mus50A:
	db $D6, $00, $A2, $00, $8A, $32, $44
	db $F4, $08
	db $EF, $01
	db $E1
	db $71
	db $E2
	db $11
	db $51
	db $E3
	db $21
	db $E2
	db $B1
	db $E3
	db $B1
	db $21
	db $B1
	db $E2
	db $51
	db $E3
	db $51
	db $E2
	db $81
	db $51
	db $E1
	db $81
	db $E2
	db $21
	db $51
	db $B1
	db $E3
	db $81
	db $E4
	db $21
	db $52
	db $FF

Mus50C:
	db $D6, $05, $8A, $CF
	db $F4, $08
	db $E0
	db $71
	db $E1
	db $11
	db $51
	db $71
	db $88
	db $21
	db $81
	db $B1
	db $E2
	db $21
	db $81
	db $E3
	db $51
	db $B2
	db $FF

EmptySeq:
	db $FF

Mus51B:
	db $D7, $22, $A2, $47, $8B, $46, $A4
	db $F4, $08
	db $C1
	db $E1
	db $73
	db $E2
	db $02
	db $E3
	db $01
	db $71
	db $E2
	db $91
	db $51
	db $01
	db $E1
	db $91
	db $E2
	db $02
	db $E1
	db $A2
	db $94
	db $FF

Mus51A:
	db $D7, $22, $A2, $47, $8B, $46, $A4
	db $F4, $08
	db $C2
	db $E2
	db $03
	db $E3
	db $73
	db $51
	db $01
	db $E2
	db $91
	db $E3
	db $01
	db $E2
	db $A1
	db $71
	db $21
	db $41
	db $54
	db $FF

Mus51C:
	db $D7, $05, $80, $86
	db $F4, $08
	db $E1
	db $03
	db $E2
	db $45
	db $C6
	db $E1
	db $02
	db $54
	db $FF

EmptySeq2:
	db $FF

Mus58B:
	db $D2, $11, $A2, $62, $8B, $46, $A4
	db $F4, $08
	db $E3
	db $50
	db $12
	db $53
	db $53
	db $94
	db $54
	db $94
	db $E4
	db $04
	db $E3
	db $94
	db $E4
	db $04
	db $50
	db $18
	db $E2
	db $53
	db $03
	db $03
	db $E1
	db $93
	db $53
	db $E2
	db $03
	db $53
	db $93
	db $E2
	db $A0
	db $12
	db $E3
	db $50
	db $12
	db $AC
	db $E4
	db $06
	db $E3
	db $86
	db $36
	db $E4
	db $0C
	db $26
	db $36
	db $06
	db $23
	db $E3
	db $A3
	db $53
	db $23
	db $E2
	db $AC
	db $FF

Mus58A:
	db $D2, $10, $82, $47, $88, $35, $A5
	db $F4, $08
	db $EF, $01
	db $E3
	db $00
	db $12
	db $E2
	db $93
	db $E3
	db $03
	db $04
	db $E2
	db $94
	db $E3
	db $04
	db $54
	db $04
	db $54
	db $E4
	db $03
	db $E3
	db $53
	db $93
	db $03
	db $53
	db $E2
	db $93
	db $E3
	db $03
	db $E2
	db $53
	db $93
	db $03
	db $53
	db $E1
	db $93
	db $93
	db $E2
	db $03
	db $53
	db $E3
	db $03
	db $E2
	db $26
	db $23
	db $23
	db $26
	db $26
	db $26
	db $23
	db $23
	db $26
	db $23
	db $23
	db $36
	db $33
	db $33
	db $36
	db $36
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $E3
	db $A3
	db $53
	db $23
	db $E2
	db $A3
	db $5C
	db $FF

Mus58C:
	db $D2, $05, $81, $86
	db $F4, $08
	db $E2
	db $50
	db $12
	db $53
	db $93
	db $50
	db $18
	db $5C
	db $0C
	db $E1
	db $5C
	db $E0
	db $5C
	db $E0
	db $A6
	db $E1
	db $56
	db $E0
	db $56
	db $E1
	db $56
	db $E0
	db $A6
	db $E1
	db $56
	db $E0
	db $56
	db $E1
	db $56
	db $E0
	db $86
	db $E1
	db $36
	db $E0
	db $36
	db $E1
	db $36
	db $E0
	db $86
	db $E1
	db $36
	db $E0
	db $36
	db $E1
	db $36
	db $E0
	db $AC
	db $A3
	db $A3
	db $A6
	db $FF

Mus58D:
	db $D2
	db $3C
	db $C6
	db $33
	db $33
	db $3C
	db $C6
	db $33
	db $33
	db $3C
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $33
	db $33
	db $33
	db $33
	db $C6
	db $36
	db $C6
	db $36
	db $C6
	db $36
	db $C6
	db $36
	db $C6
	db $36
	db $C6
	db $36
	db $C6
	db $36
	db $C6
	db $36
	db $3C
	db $33
	db $33
	db $36
	db $FF

SFX09A:
	db $D1, $01, $B0, $30, $8B, $46, $A4
	db $F4, $08
	db $E2
	db $C3
	db $28
	db $78
	db $E3
	db $28
	db $77
	db $E4
	db $28
	db $78
	db $E5
	db $C4
	db $14
	db $E4
	db $94
	db $E5
	db $13
	db $E4
	db $B4
	db $74
	db $B4
	db $94
	db $54
	db $94
	db $74
	db $43
	db $14
	db $E3
	db $94
	db $44
	db $14
	db $FF

SFX09B:
	db $D1, $11, $B0, $F0, $8B, $22, $84
	db $F4, $08
	db $E2
	db $C7
	db $48
	db $B8
	db $E3
	db $48
	db $B7
	db $E4
	db $48
	db $B8
	db $C8
	db $E9, $90
	db $43
	db $24
	db $E3
	db $B4
	db $E4
	db $24
	db $04
	db $E3
	db $94
	db $E4
	db $04
	db $14
	db $E3
	db $93
	db $44
	db $14
	db $E2
	db $94
	db $44
	db $FF

SFX09C:
	db $D1, $05, $FF, $FF
	db $E1
	db $90
	db $70
	db $FF

SECTION "Audio RAM MusC1", WRAMX[MusC1RAM]
MusC1MusNum: ds 1		;$DE00 = $00
MusC1Priority: ds 1		;$DE01 = $01
MusC1Sweep: ds 1		;$DE02 = $02
MusC1Transpose: ds 1	;$DE03 = $03
MusC1Tuning: ds 1		;$DE04 = $04
MusC1VolFinal: ds 1		;$DE05 = $05
MusC1VolOutput: ds 1	;$DE06 = $06
MusC1NoteDelay: ds 2	;$DE07 = $07
MusC1Speed: ds 1		;$DE09 = $09
MusC1DutyVol: ds 1		;$DE0A = $0A
MusC1Decay: ds 1		;$DE0B = $0B
MusC1EnvLen: ds 1		;$DE0C = $0C
MusC1Vibrato: ds 2		;$DE0D = $0D
MusC1EnvVal: ds 1		;$DE0F = $0F
MusC1Decay2: ds 1		;$DE10 = $10
MusC1Decay3: ds 1		;$DE11 = $11
MusC1ReleaseTime: ds 2	;$DE12 = $12
MusC1EnvSeqPtr: ds 2	;$DE14 = $14
MusC1VibStep: ds 1		;$DE16 = $16
MusC1EnvSeqPos: ds 1	;$DE17 = $17
MusC1EnvStep: ds 1		;$DE18 = $18
MusC1VibSeqDelay: ds 1	;$DE19 = $19
MusC1EnvDur: ds 1		;$DE1A = $1A
MusC1Octave: ds 1		;$DE1B = $1B
MusC1VibVal: ds 1		;$DE1C = $1C
MusC1Freq: ds 2			;$DE1D = $1D
MusC1VolCur: ds 1		;$DE1F = $1F
MusC1SongPos: ds 2		;$DE20 = $20
MusC1Repeat1Start: ds 2	;$DE22 = $22
MusC1Repeat2Start: ds 2	;$DE24 = $24
MusC1Macro1Pos: ds 2	;$DE26 = $26
MusC1Macro2Pos: ds 2	;$DE28 = $28
MusC1Repeat1Times: ds 1	;$DE2A = $2A
MusC1Repeat2Times: ds 1	;$DE2B = $2B
MusC1NoteFlags: ds 1	;$DE2C = $2C
MusC1DataFlags: ds 1	;$DE2D = $2D
MusC1DataBank: ds 1		;$DE2E = $2E
MusC1Unused2F: ds 1		;$DE2F = $2F

SECTION "Audio RAM MusC2", WRAMX[MusC2RAM]
MusC2MusNum: ds 1		;$DE30 = $00
MusC2Priority: ds 1		;$DE31 = $01
MusC2Sweep: ds 1		;$DE32 = $02
MusC2Transpose: ds 1	;$DE33 = $03
MusC2Tuning: ds 1		;$DE34 = $04
MusC2VolFinal: ds 1		;$DE35 = $05
MusC2VolOutput: ds 1	;$DE36 = $06
MusC2NoteDelay: ds 2	;$DE37 = $07
MusC2Speed: ds 1		;$DE39 = $09
MusC2DutyVol: ds 1		;$DE3A = $0A
MusC2Decay: ds 1		;$DE3B = $0B
MusC2EnvLen: ds 1		;$DE3C = $0C
MusC2Vibrato: ds 2		;$DE3D = $0D
MusC2EnvVal: ds 1		;$DE3F = $0F
MusC2Decay2: ds 1		;$DE40 = $10
MusC2Decay3: ds 1		;$DE41 = $11
MusC2ReleaseTime: ds 2	;$DE42 = $12
MusC2EnvSeqPtr: ds 2	;$DE44 = $14
MusC2VibStep: ds 1		;$DE46 = $16
MusC2EnvSeqPos: ds 1	;$DE47 = $17
MusC2EnvStep: ds 1		;$DE48 = $18
MusC2VibSeqDelay: ds 1	;$DE49 = $19
MusC2EnvDur: ds 1		;$DE4A = $1A
MusC2Octave: ds 1		;$DE4B = $1B
MusC2VibVal: ds 1		;$DE4C = $1C
MusC2Freq: ds 2			;$DE4D = $1D
MusC2VolCur: ds 1		;$DE4F = $1F
MusC2SongPos: ds 2		;$DE50 = $20
MusC2Repeat1Start: ds 2	;$DE52 = $22
MusC2Repeat2Start: ds 2	;$DE54 = $24
MusC2Macro1Pos: ds 2	;$DE56 = $26
MusC2Macro2Pos: ds 2	;$DE58 = $28
MusC2Repeat1Times: ds 1	;$DE5A = $2A
MusC2Repeat2Times: ds 1	;$DE5B = $2B
MusC2NoteFlags: ds 1	;$DE5C = $2C
MusC2DataFlags: ds 1	;$DE5D = $2D
MusC2DataBank: ds 1		;$DE5E = $2E
MusC2Unused2F: ds 1		;$DE5F = $2F

SECTION "Audio RAM MusC3", WRAMX[MusC3RAM]
MusC3MusNum: ds 1		;$DE60 = $00
MusC3Priority: ds 1		;$DE61 = $01
MusC3Sweep: ds 1		;$DE62 = $02
MusC3Transpose: ds 1	;$DE63 = $03
MusC3Tuning: ds 1		;$DE64 = $04
MusC3VolFinal: ds 1		;$DE65 = $05
MusC3VolOutput: ds 1	;$DE66 = $06
MusC3NoteDelay: ds 2	;$DE67 = $07
MusC3Speed: ds 1		;$DE69 = $09
MusC3DutyVol: ds 1		;$DE6A = $0A
MusC3Decay: ds 1		;$DE6B = $0B
MusC3EnvLen: ds 1		;$DE6C = $0C
MusC3Vibrato: ds 2		;$DE6D = $0D
MusC3EnvVal: ds 1		;$DE6F = $0F
MusC3Decay2: ds 1		;$DE70 = $10
MusC3Decay3: ds 1		;$DE71 = $11
MusC3ReleaseTime: ds 2	;$DE72 = $12
MusC3EnvSeqPtr: ds 2	;$DE74 = $14
MusC3VibStep: ds 1		;$DE76 = $16
MusC3EnvSeqPos: ds 1	;$DE77 = $17
MusC3EnvStep: ds 1		;$DE78 = $18
MusC3VibSeqDelay: ds 1	;$DE79 = $19
MusC3EnvDur: ds 1		;$DE7A = $1A
MusC3Octave: ds 1		;$DE7B = $1B
MusC3VibVal: ds 1		;$DE7C = $1C
MusC3Freq: ds 2			;$DE7D = $1D
MusC3VolCur: ds 1		;$DE7F = $1F
MusC3SongPos: ds 2		;$DE80 = $20
MusC3Repeat1Start: ds 2	;$DE82 = $22
MusC3Repeat2Start: ds 2	;$DE84 = $24
MusC3Macro1Pos: ds 2	;$DE86 = $26
MusC3Macro2Pos: ds 2	;$DE88 = $28
MusC3Repeat1Times: ds 1	;$DE8A = $2A
MusC3Repeat2Times: ds 1	;$DE8B = $2B
MusC3NoteFlags: ds 1	;$DE8C = $2C
MusC3DataFlags: ds 1	;$DE8D = $2D
MusC3DataBank: ds 1		;$DE8E = $2E
MusC3Unused2F: ds 1		;$DE8F = $2F

SECTION "Audio RAM MusC4", WRAMX[MusC4RAM]
MusC4MusNum: ds 1		;$DE90 = $00
MusC4Priority: ds 1		;$DE91 = $01
MusC4Sweep: ds 1		;$DE92 = $02
MusC4Transpose: ds 1	;$DE93 = $03
MusC4Tuning: ds 1		;$DE94 = $04
MusC4VolFinal: ds 1		;$DE95 = $05
MusC4VolOutput: ds 1	;$DE96 = $06
MusC4NoteDelay: ds 2	;$DE97 = $07
MusC4Speed: ds 1		;$DE99 = $09
MusC4DutyVol: ds 1		;$DE9A = $0A
MusC4Decay: ds 1		;$DE9B = $0B
MusC4EnvLen: ds 1		;$DE9C = $0C
MusC4Vibrato: ds 2		;$DE9D = $0D
MusC4EnvVal: ds 1		;$DE9F = $0F
MusC4Decay2: ds 1		;$DEA0 = $10
MusC4Decay3: ds 1		;$DEA1 = $11
MusC4ReleaseTime: ds 2	;$DEA2 = $12
MusC4EnvSeqPtr: ds 2	;$DEA4 = $14
MusC4VibStep: ds 1		;$DEA6 = $16
MusC4EnvSeqPos: ds 1	;$DEA7 = $17
MusC4EnvStep: ds 1		;$DEA8 = $18
MusC4VibSeqDelay: ds 1	;$DEA9 = $19
MusC4EnvDur: ds 1		;$DEAA = $1A
MusC4Octave: ds 1		;$DEAB = $1B
MusC4VibVal: ds 1		;$DEAC = $1C
MusC4Freq: ds 2			;$DEAD = $1D
MusC4VolCur: ds 1		;$DEAF = $1F
MusC4SongPos: ds 2		;$DEB0 = $20
MusC4Repeat1Start: ds 2	;$DEB2 = $22
MusC4Repeat2Start: ds 2	;$DEB4 = $24
MusC4Macro1Pos: ds 2	;$DEB6 = $26
MusC4Macro2Pos: ds 2	;$DEB8 = $28
MusC4Repeat1Times: ds 1	;$DEBA = $2A
MusC4Repeat2Times: ds 1	;$DEBB = $2B
MusC4NoteFlags: ds 1	;$DEBC = $2C
MusC4DataFlags: ds 1	;$DEBD = $2D
MusC4DataBank: ds 1		;$DEBE = $2E
MusC4Unused2F: ds 1		;$DEBF = $2F

SECTION "Audio RAM SFXC1", WRAMX[SFXC1RAM]
SFXC1MusNum: ds 1		;$DEC0 = $00
SFXC1Priority: ds 1		;$DEC1 = $01
SFXC1Sweep: ds 1		;$DEC2 = $02
SFXC1Transpose: ds 1	;$DEC3 = $03
SFXC1Tuning: ds 1		;$DEC4 = $04
SFXC1VolFinal: ds 1		;$DEC5 = $05
SFXC1VolOutput: ds 1	;$DEC6 = $06
SFXC1NoteDelay: ds 2	;$DEC7 = $07
SFXC1Speed: ds 1		;$DEC9 = $09
SFXC1DutyVol: ds 1		;$DECA = $0A
SFXC1Decay: ds 1		;$DECB = $0B
SFXC1EnvLen: ds 1		;$DECC = $0C
SFXC1Vibrato: ds 2		;$DECD = $0D
SFXC1EnvVal: ds 1		;$DECF = $0F
SFXC1Decay2: ds 1		;$DED0 = $10
SFXC1Decay3: ds 1		;$DED1 = $11
SFXC1ReleaseTime: ds 2	;$DED2 = $12
SFXC1EnvSeqPtr: ds 2	;$DED4 = $14
SFXC1VibStep: ds 1		;$DED6 = $16
SFXC1EnvSeqPos: ds 1	;$DED7 = $17
SFXC1EnvStep: ds 1		;$DED8 = $18
SFXC1VibSeqDelay: ds 1	;$DED9 = $19
SFXC1EnvDur: ds 1		;$DEDA = $1A
SFXC1Octave: ds 1		;$DEDB = $1B
SFXC1VibVal: ds 1		;$DEDC = $1C
SFXC1Freq: ds 2			;$DEDD = $1D
SFXC1VolCur: ds 1		;$DEDF = $1F
SFXC1SongPos: ds 2		;$DEE0 = $20
SFXC1Repeat1Start: ds 2	;$DEE2 = $22
SFXC1Repeat2Start: ds 2	;$DEE4 = $24
SFXC1Macro1Pos: ds 2	;$DEE6 = $26
SFXC1Macro2Pos: ds 2	;$DEE8 = $28
SFXC1Repeat1Times: ds 1	;$DEEA = $2A
SFXC1Repeat2Times: ds 1	;$DEEB = $2B
SFXC1NoteFlags: ds 1	;$DEEC = $2C
SFXC1DataFlags: ds 1	;$DEED = $2D
SFXC1DataBank: ds 1		;$DEEE = $2E
SFXC1Unused2F: ds 1		;$DEEF = $2F

SECTION "Audio RAM SFXC2", WRAMX[SFXC2RAM]
SFXC2MusNum: ds 1		;$DF00 = $00
SFXC2Priority: ds 1		;$DF01 = $01
SFXC2Sweep: ds 1		;$DF02 = $02
SFXC2Transpose: ds 1	;$DF03 = $03
SFXC2Tuning: ds 1		;$DF04 = $04
SFXC2VolFinal: ds 1		;$DF05 = $05
SFXC2VolOutput: ds 1	;$DF06 = $06
SFXC2NoteDelay: ds 2	;$DF07 = $07
SFXC2Speed: ds 1		;$DF09 = $09
SFXC2DutyVol: ds 1		;$DF0A = $0A
SFXC2Decay: ds 1		;$DF0B = $0B
SFXC2EnvLen: ds 1		;$DF0C = $0C
SFXC2Vibrato: ds 2		;$DF0D = $0D
SFXC2EnvVal: ds 1		;$DF0F = $0F
SFXC2Decay2: ds 1		;$DF10 = $10
SFXC2Decay3: ds 1		;$DF11 = $11
SFXC2ReleaseTime: ds 2	;$DF12 = $12
SFXC2EnvSeqPtr: ds 2	;$DF14 = $14
SFXC2VibStep: ds 1		;$DF16 = $16
SFXC2EnvSeqPos: ds 1	;$DF17 = $17
SFXC2EnvStep: ds 1		;$DF18 = $18
SFXC2VibSeqDelay: ds 1	;$DF19 = $19
SFXC2EnvDur: ds 1		;$DF1A = $1A
SFXC2Octave: ds 1		;$DF1B = $1B
SFXC2VibVal: ds 1		;$DF1C = $1C
SFXC2Freq: ds 2			;$DF1D = $1D
SFXC2VolCur: ds 1		;$DF1F = $1F
SFXC2SongPos: ds 2		;$DF20 = $20
SFXC2Repeat1Start: ds 2	;$DF22 = $22
SFXC2Repeat2Start: ds 2	;$DF24 = $24
SFXC2Macro1Pos: ds 2	;$DF26 = $26
SFXC2Macro2Pos: ds 2	;$DF28 = $28
SFXC2Repeat1Times: ds 1	;$DF2A = $2A
SFXC2Repeat2Times: ds 1	;$DF2B = $2B
SFXC2NoteFlags: ds 1	;$DF2C = $2C
SFXC2DataFlags: ds 1	;$DF2D = $2D
SFXC2DataBank: ds 1		;$DF2E = $2E
SFXC2Unused2F: ds 1		;$DF2F = $2F

SECTION "Audio RAM SFXC3", WRAMX[SFXC3RAM]
SFXC3MusNum: ds 1		;$DF30 = $00
SFXC3Priority: ds 1		;$DF31 = $01
SFXC3Sweep: ds 1		;$DF32 = $02
SFXC3Transpose: ds 1	;$DF33 = $03
SFXC3Tuning: ds 1		;$DF34 = $04
SFXC3VolFinal: ds 1		;$DF35 = $05
SFXC3VolOutput: ds 1	;$DF36 = $06
SFXC3NoteDelay: ds 2	;$DF37 = $07
SFXC3Speed: ds 1		;$DF39 = $09
SFXC3DutyVol: ds 1		;$DF3A = $0A
SFXC3Decay: ds 1		;$DF3B = $0B
SFXC3EnvLen: ds 1		;$DF3C = $0C
SFXC3Vibrato: ds 2		;$DF3D = $0D
SFXC3EnvVal: ds 1		;$DF3F = $0F
SFXC3Decay2: ds 1		;$DF40 = $10
SFXC3Decay3: ds 1		;$DF41 = $11
SFXC3ReleaseTime: ds 2	;$DF42 = $12
SFXC3EnvSeqPtr: ds 2	;$DF44 = $14
SFXC3VibStep: ds 1		;$DF46 = $16
SFXC3EnvSeqPos: ds 1	;$DF47 = $17
SFXC3EnvStep: ds 1		;$DF48 = $18
SFXC3VibSeqDelay: ds 1	;$DF49 = $19
SFXC3EnvDur: ds 1		;$DF4A = $1A
SFXC3Octave: ds 1		;$DF4B = $1B
SFXC3VibVal: ds 1		;$DF4C = $1C
SFXC3Freq: ds 2			;$DF4D = $1D
SFXC3VolCur: ds 1		;$DF4F = $1F
SFXC3SongPos: ds 2		;$DF50 = $20
SFXC3Repeat1Start: ds 2	;$DF52 = $22
SFXC3Repeat2Start: ds 2	;$DF54 = $24
SFXC3Macro1Pos: ds 2	;$DF56 = $26
SFXC3Macro2Pos: ds 2	;$DF58 = $28
SFXC3Repeat1Times: ds 1	;$DF5A = $2A
SFXC3Repeat2Times: ds 1	;$DF5B = $2B
SFXC3NoteFlags: ds 1	;$DF5C = $2C
SFXC3DataFlags: ds 1	;$DF5D = $2D
SFXC3DataBank: ds 1		;$DF5E = $2E
SFXC3Unused2F: ds 1		;$DF5F = $2F

SECTION "Audio RAM SFXC4", WRAMX[SFXC4RAM]
SFXC4MusNum: ds 1		;$DF60 = $00
SFXC4Priority: ds 1		;$DF61 = $01
SFXC4Sweep: ds 1		;$DF62 = $02
SFXC4Transpose: ds 1	;$DF63 = $03
SFXC4Tuning: ds 1		;$DF64 = $04
SFXC4VolFinal: ds 1		;$DF65 = $05
SFXC4VolOutput: ds 1	;$DF66 = $06
SFXC4NoteDelay: ds 2	;$DF67 = $07
SFXC4Speed: ds 1		;$DF69 = $09
SFXC4DutyVol: ds 1		;$DF6A = $0A
SFXC4Decay: ds 1		;$DF6B = $0B
SFXC4EnvLen: ds 1		;$DF6C = $0C
SFXC4Vibrato: ds 2		;$DF6D = $0D
SFXC4EnvVal: ds 1		;$DF6F = $0F
SFXC4Decay2: ds 1		;$DF70 = $10
SFXC4Decay3: ds 1		;$DF71 = $11
SFXC4ReleaseTime: ds 2	;$DF72 = $12
SFXC4EnvSeqPtr: ds 2	;$DF74 = $14
SFXC4VibStep: ds 1		;$DF76 = $16
SFXC4EnvSeqPos: ds 1	;$DF77 = $17
SFXC4EnvStep: ds 1		;$DF78 = $18
SFXC4VibSeqDelay: ds 1	;$DF79 = $19
SFXC4EnvDur: ds 1		;$DF7A = $1A
SFXC4Octave: ds 1		;$DF7B = $1B
SFXC4VibVal: ds 1		;$DF7C = $1C
SFXC4Freq: ds 2			;$DF7D = $1D
SFXC4VolCur: ds 1		;$DF7F = $1F
SFXC4SongPos: ds 2		;$DF80 = $20
SFXC4Repeat1Start: ds 2	;$DF82 = $22
SFXC4Repeat2Start: ds 2	;$DF84 = $24
SFXC4Macro1Pos: ds 2	;$DF86 = $26
SFXC4Macro2Pos: ds 2	;$DF88 = $28
SFXC4Repeat1Times: ds 1	;$DF8A = $2A
SFXC4Repeat2Times: ds 1	;$DF8B = $2B
SFXC4NoteFlags: ds 1	;$DF8C = $2C
SFXC4DataFlags: ds 1	;$DF8D = $2D
SFXC4DataBank: ds 1		;$DF8E = $2E
SFXC4Unused2F: ds 1		;$DF8F = $2F

SECTION "Audio Variables", WRAMX[$DEF0]
CurTrack: ds 1			;$DEF0
CurTrackCheck: ds 1		;$DEF1
SFXNum: ds 1			;$DEF2
Temp1: ds 1				;$DEF3
Temp2: ds 1				;$DEF4
Output: ds 1			;$DEF5
SongBank: ds 1			;$DEF6
NewWave: ds 1			;$DEF7
Fade: ds 1				;$DEF8
FadeTime: ds 1			;$DEF9
MusPlaying: ds 1		;$DEFA
Gate1Off: ds 1			;$DEFB
Gate2Off: ds 1			;$DEFC
Gate3Off: ds 1			;$DEFD
Gate4Off: ds 1			;$DEFE

;The block ends here: it fills exactly the 16 bytes between SFXC1RAM and
;SFXC2RAM, and nothing ever touches the last one at $DEFF.

SECTION "Audio Registers", WRAMX[$DF90]
NR10Val: ds 1			;$DF90
NR11Val: ds 1			;$DF91
NR12Val: ds 1			;$DF92
NR13Val: ds 1			;$DF93
NR14Val: ds 1			;$DF94
NR21Val: ds 1			;$DF95
NR22Val: ds 1			;$DF96
NR23Val: ds 1			;$DF97
NR24Val: ds 1			;$DF98
NR30Val: ds 1			;$DF99
NR31Val: ds 1			;$DF9A
NR32Val: ds 1			;$DF9B
NR33Val: ds 1			;$DF9C
NR34Val: ds 1			;$DF9D
NR41Val: ds 1			;$DF9E
NR42Val: ds 1			;$DF9F
NR43Val: ds 1			;$DFA0
NR44Val: ds 1			;$DFA1
NR50Val: ds 1			;$DFA2
NR51Val: ds 1			;$DFA3
NR52Val: ds 1			;$DFA4

;Mega Man III keeps a second copy of every register after this. Pocket King does
;not - OutputRegTrig and OutputRegMasked read the hardware back with
;`ldh a, [c]` instead, so the engine's RAM ends at $DFA4.
