;Itsudemo Nyanto Wonderful audio disassembly
;Disassembly by Will Trowbridge & Claude

;The audio lives in ROM bank $0D, which has no jump vector at its start -
;the game calls LoadSong, PlayAudio and InitSound at fixed addresses. The rest
;of the bank past $60EF holds unrelated tile graphics and is not disassembled here.

include "HARDWARE.INC"

def AudioROM equ $4000
def AudioBank equ $0D
def AudioRAM equ $C700
def WaveRAM equ $FF30
def TrackRAMSize equ $2C
def MusC1RAM equ $C700
def MusC2RAM equ $C72C
def MusC3RAM equ $C758
def MusC4RAM equ $C784
def SFXC1RAM equ $C7B0
def SFXC2RAM equ $C7DC
def SFXC3RAM equ $C808
def SFXC4RAM equ $C834

SECTION "Audio", ROMX[AudioROM], BANK[$1]

SongTab:
	dw Perc_Empty
	dw Perc01
	dw Perc02
	dw Perc03
	dw Perc04
	dw Perc05
	dw FadeOutTrack
	dw SFXEmpty1
	dw SFXEmpty2
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
	dw Mus18
	dw Mus19
	dw Mus1A
	dw Mus1B
	dw Mus1C
	dw Mus1D
	dw Mus1E
	dw Mus1F
	dw Mus20
	dw Mus21
	dw Mus22
	dw Mus23
	dw Mus24

Perc_Empty:

FadeOutTrack:
	db %00000000
	db 0
	dw EmptySeq

Perc01:
	db %10000000
	db 0
	dw Perc01D

Perc02:
	db %10000000
	db 0
	dw Perc02D

Perc03:
	db %10000000
	db 0
	dw Perc03D

Perc04:
	db %10000000
	db 0
	dw Perc04D

Perc05:
	db %10000000
	db 0
	dw Perc05D

SFX09:
	db %00010000
	db 14
	dw SFX09A

SFX0A:
	db %00010000
	db 14
	dw SFX0AA

SFX0B:
	db %00010000
	db 3
	dw SFX0BA

SFX0C:
	db %00010000
	db 3
	dw SFX0CA

SFX0D:
	db %00010000
	db 14
	dw SFX0DA

SFX0E:
	db %00010000
	db 14
	dw SFX0EA

SFX10:
	db %00010000
	db 2
	dw SFX10A

SFX0F:
	db %00010000
	db 2
	dw SFX0FA

SFX11:
	db %00010000
	db 2
	dw SFX11A

SFX12:
	db %10000000
	db 2
	dw SFX12D

SFX13:
	db %10000000
	db 2
	dw SFX13D

SFX14:
	db %10000000
	db 2
	dw SFX14D

SFX15:
	db %10000000
	db 2
	dw SFX15D

SFX16:
	db %00010000
	db 2
	dw SFX16A

SFX17:
	db %00010000
	db 2
	dw SFX17A

SFXEmpty1:
	db %00001111
	db 2
	dw EmptySeq
	dw EmptySeq
	dw EmptySeq
	dw EmptySeq

SFXEmpty2:
	db %11110000
	db 15
	dw EmptySeq
	dw EmptySeq
	dw EmptySeq
	dw EmptySeq

Mus18:
	db %00001111
	db 0
	dw Mus18A
	dw Mus18B
	dw Mus18C
	dw Mus18D

Mus19:
	db %00001111
	db 0
	dw Mus19A
	dw Mus19B
	dw Mus19C
	dw EmptySeq

Mus1A:
	db %00001111
	db 0
	dw Mus1AA
	dw Mus1AB
	dw Mus1AC
	dw Mus1AD

Mus1B:
	db %00001111
	db 0
	dw Mus1BA
	dw Mus1BB
	dw Mus1BC
	dw EmptySeq

Mus1C:
	db %00001111
	db 0
	dw Mus1CA
	dw Mus1CB
	dw Mus1CC
	dw EmptySeq

Mus21:
	db %00001111
	db 0
	dw Mus21A
	dw Mus21B
	dw Mus21C
	dw EmptySeq

Mus1D:
	db %00001111
	db 0
	dw Mus1DA
	dw Mus1DB
	dw Mus1DC
	dw Mus1DD

Mus1E:
	db %00001111
	db 0
	dw Mus1EA
	dw Mus1EB
	dw Mus1EC
	dw Mus1ED

Mus1F:
	db %00001111
	db 0
	dw Mus1FA
	dw Mus1FB
	dw Mus1FC
	dw EmptySeq

Mus20:
	db %00001111
	db 0
	dw Mus20A
	dw Mus20B
	dw Mus20C
	dw EmptySeq

Mus22:
	db %00001111
	db 0
	dw Mus22A
	dw Mus22B
	dw Mus22C
	dw Mus22D

Mus23:
	db %00001111
	db 0
	dw Mus23A
	dw Mus23B
	dw Mus23C
	dw EmptySeq

Mus24:
	db %00001111
	db 0
	dw Mus24A
	dw Mus24B
	dw Mus24C
	dw EmptySeq

;Load song/sound effect
LoadSong:
	;If song is 0
	or a
	jp z, NoAudio

	;If song is $0A, then fade out current music
	cp $06
	jp z, FadeOutMus
	push bc
	push de
	;Load number to SFX number RAM variable
	ld [SFXNum], a
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
	ld a, [hl+]
	ld [Temp1], a				;Byte 1 = Channel mask
	ld a, [hl+]
	ld [Temp2], a				;Byte 2 = priority
	ld b, h
	ld c, l
	;Set channel number to 0
	xor a
	ld [CurTrack], a
	ld de, MusC1MusNum

GetTracks:
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
	;Skip to next channel area in RAM
	ld hl, TrackRAMSize
	add hl, de
	ld d, h
	ld e, l
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
	ld h, b
	ld l, c
	ld a, [hl+]
	ld b, [hl]
	inc hl
	push hl
	ld hl, $20
	add hl, de
	ld [hl+], a
	ld [hl], b
	inc hl
	ld [hl+], a
	ld [hl], b
	inc hl
	ld [hl+], a
	ld [hl], b
	;Set vibrato to first sequence
	ld hl, $0F
	add hl, de
	ld a, LOW(Vibrato0)
	ld [hl+], a
	ld a, HIGH(Vibrato0)
	ld [hl], a
	pop bc
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
	ld [hl], a
	jr .NextTrack

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
	ld a, [hl+]
	;Get mask and priority values
	and %11110000
	swap a
	ld [Temp1], a
	ld a, [hl+]
	ld [Temp2], a
	ld b, h
	ld c, l
	;Set current track to 4 (SFX track 1)
	ld a, 4
	ld [CurTrack], a
	ld de, SFXC1MusNum
	jp GetTracks

FadeOutMus:
	ld a, 7
	ld [Fade], a
	ld [FadeTime], a
	ret

PlayAudio:
	;Check if fade out is enabled
	ld a, [Fade]
	or a
	;If not, then play audio
	jr z, .PlayAudio2

	;Otherwise, decrement fade and check again
	ld hl, FadeTime
	dec [hl]
	;If not done, then continue playing audio
	jr nz, .PlayAudio2

	;Otherwise, check NR50 value
	ld [hl], a
	ld hl, NR50Val
	ld a, [hl]
	;If not 0, then subtract volume
	or a
	;Otherwise, disable audio
	jp z, NoAudio
	sub %00010001
	ld [hl], a

.PlayAudio2
	call CheckAllTracks
	jp OutputTracks

CheckAllTracks:
	;Check all tracks to see if they are playing
	xor a
	ld [CurTrackCheck], a
	ld de, MusC1MusNum

CheckTrack:
	;Check if track is on (with song number)
	ld hl, $00
	add hl, de
	ld a, [hl]
	or a
	;If 0, then skip to next track
	jr z, NextTrack

	;Process the track
	call ProcTrack
	;Copy values to register RAM values
	call ProcTrackRegVals

NextTrack:
	;Skip to next track
	ld hl, $2C
	add hl, de
	ld d, h
	ld e, l
	ld hl, CurTrackCheck
	inc [hl]
	;If not done checking all 8 tracks, then check this track
	ld a, 8
	cp [hl]
	jr nz, CheckTrack
	;Combine the four music channels' song numbers into a
	;"music playing" flag for the rest of the game to read
	ld hl, MusC1MusNum
	ld de, $2C
	ld a, [hl]
	add hl, de
	or [hl]
	add hl, de
	or [hl]
	add hl, de
	or [hl]
	ld [MusPlaying], a
	ret

ProcTrack:
	;Process note length
	ld hl, $08
	add hl, de				;Increase time
	inc [hl]
	dec hl
	dec [hl]				;Decrease delay
	;If delay is complete, then get next command
	call z, NextCommand
	;If track is music 4, then return
	ld a, [CurTrackCheck]
	cp 3
	ret z

	;Check if envelope is on
	ld hl, $09
	add hl, de
	ld a, [hl]
	or a
	;If not, then return
	ret z

	;Otherwise, get envelope value
	ld hl, $11
	add hl, de
	ld a, [hl]

	;If no carry, then process vibrato
	add a
	jp nc, ProcVibrato

	;Check if wave channel
	ld a, [CurTrackCheck]
	and %00000011
	cp 2
	;If so, then perform special envelope handler
	jp z, ProcEnvStateCh3

ProcEnvState:
	;Otherwise, this is a decaying (CH1/CH2) envelope.
	;Wait out the current envelope stage.
	ld hl, $1A
	add hl, de
	dec [hl]
	;If not 0, then skip
	jp nz, EnvSustain

	;Stage expired: pick the handler for the current envelope state.
	;State # is kept in +$18 and indexes the table below.
	ld hl, $18
	add hl, de
	ld a, [hl]
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
	dw EnvSustain
	dw EnvSustain
	dw EnvSustain

EnvState0:
	;Increase envelope state
	push bc
	ld hl, $18
	add hl, de
	inc [hl]

	;Get envelope value
	ld hl, $11
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
	ld c, a

	;Get decay
	ld hl, $0D
	add hl, de
	ld a, [hl]
	swap a
	and %00001111

	;Subtract volume
	sub b
	;If not 0 or below, then go to next stage
	jr c, EnvState1_2

	;Otherwise, multiply the volume by decay
	call Multiply
	;If result is 0, then skip to next state
	or a
	jr z, EnvState1_2

	;Otherwise, then save stage duration into RAM
	pop bc
	jp SaveStageDur

EnvState1:
	push bc

EnvState1_2:
	;Increase envelope state
	ld hl, $18
	add hl, de
	inc [hl]

	;Get decay
	ld hl, $0D
	add hl, de
	ld a, [hl]
	and %11110000
	ld b, a

	;Also get secondary decay parameter
	ld hl, $12
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

	;Compute next stage's duration as (high nibble of +$0D - low nibble of +$12) x 7-bit count of +$12.
	ld hl, $12
	add hl, de
	ld a, [hl]
	and %00001111
	swap b
	ld l, a
	ld a, b
	sub l
	;If not 0 or below, then go to next stage
	jr c, EnvState2_1
	call Multiply
	or a
	;If result is 0, then skip to next state
	jr z, EnvState2_1
	pop bc
	jp SaveStageDur

EnvState2:
	push bc

EnvState2_1:
	;Increase envelope state
	ld hl, $18
	add hl, de
	inc [hl]

	;Get secondary decay parameter
	ld hl, $12
	add hl, de
	ld a, [hl]
	swap a
	and %11110000

	;Save as current NRx1 volume
	ld hl, $1F
	add hl, de
	ld [hl], a
	;Get envelope time-base/speed
	ld hl, $0A
	add hl, de
	ld a, [hl]
	;And get note time
	ld hl, $08
	add hl, de
	ld b, [hl]

	;Subtract note time from envelope time
	sub b
	;If not negative, then go to next state
	jr c, EnvState3_2
	jr z, EnvState3_2

	;Otherwise, then save stage duration into RAM
	pop bc
	jp SaveStageDur

EnvState3:
	push bc

EnvState3_2:
	;Increase envelope state
	ld hl, $18
	add hl, de
	inc [hl]

	;Get secondary decay parameter
	ld hl, $12
	add hl, de
	ld a, [hl]
	and %00001111
	swap a
	ld b, a

	;Get tertiary decay parameter
	ld hl, $13
	add hl, de
	ld a, [hl]
	and %00000111
	ld c, a

	;Combine these values and save as current NRx1 volume
	or b
	ld hl, $1F
	add hl, de
	ld [hl], a

	;Get secondary decay and revert swap
	ld a, b
	swap a
	push af

	;Get primary decay value
	ld hl, $0D
	add hl, de
	ld a, [hl]
	and %00001111
	ld b, a

	;Subtract secondary decay value
	pop af
	sub b

	;If decay is more than 0, then go to next stage
	jr c, EnvState4_1

	;Multiply values otherwise
	call Multiply
	or a
	;If 0, then go to next stage
	jr z, EnvState4_1

	;Otherwise, then save stage duration into RAM
	pop bc
	jp SaveStageDur

EnvState4_1:
	pop bc

EnvState4:
	;Get primary decay value
	ld hl, $0D
	add hl, de
	ld a, [hl]
	and %00001111
	swap a

	;Set secondary decay value to it
	ld hl, $1F
	add hl, de
	ld [hl], a

	;Increase envelope state
	ld a, $FF
	ld hl, $18
	add hl, de
	inc [hl]
	;Set stage duration to 255 into RAM
	jp SaveStageDur

ProcEnvStateCh3:
	;Check envelope duration
	ld hl, $1A
	add hl, de
	;If not done, then return
	dec [hl]
	ret nz

	;Otherwise, check state
	ld hl, $18
	add hl, de
	ld a, [hl]

	;Jump to the handler of the correct state
	cp 1
	jr c, EnvState1Ch3
	cp 2
	jr c, EnvState2Ch3
	cp 3
	jr c, EnvState3Ch3
	cp 4
	jr c, EnvState4Ch3

	;If none of the above, then return
	ret

EnvState1Ch3:
	;Set NR31 volume to maximum
	ld a, %11110000
	ld hl, $1F
	add hl, de
	ld [hl], a

	;Increase envelope state
	ld hl, $18
	add hl, de
	inc [hl]

	;Get envelope time + 1
	ld hl, $0A
	add hl, de
	ld a, [hl]
	inc a

	;Set envelope length to it
	ld hl, $1A
	add hl, de
	ld [hl], a
	ret

EnvState2Ch3:
	;Get new volume
	ld a, %01010000

EnvState2Ch3_2:
	;Set NR31 volume
	ld hl, $1F
	add hl, de
	ld [hl], a

	;Increase envelope state
	ld hl, $18
	add hl, de
	inc [hl]

	;Get envelope value (lower 7 bits)
	ld hl, $11
	add hl, de
	ld a, [hl]
	and %01111111

	;Set envelope length to it
	ld hl, $1A
	add hl, de
	ld [hl], a
	ret

EnvState3Ch3:
	;Get new volume
	ld a, %00010000
	;Rest of state is same as 2
	jr EnvState2Ch3_2

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
	;If not done, then sustain
	jr nz, EnvSustain

	;Otherwise, get next envelope value from sequence
	ld hl, $17
	add hl, de
	inc [hl]
	;Advance the envelope sequence pointer
	ld a, [hl]
	ld hl, $14
	add hl, de
	push bc
	add [hl]
	ld c, a
	inc hl
	ld a, [hl]
	adc 0
	ld b, a
	;Check current envelope value
	ld a, [bc]
	pop bc
	;If FF, then end of sequence
	cp $FF
	;Otherwise, get volume
	jr nz, GetVol

	;Decrement sequence position
	ld hl, $17
	add hl, de
	dec [hl]
	;Restart envelope duration
	ld hl, $1A
	add hl, de
	ld [hl], a
	jr EnvSustain

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

;After envelope is finished...
EnvSustain:
	;If channel is 2, then return
	ld a, [CurTrackCheck]
	and 2
	jr nz, ProcNextVibratoRet

	;Otherwise, decrease vibrato sequence delay
	ld hl, $19
	add hl, de
	dec [hl]
	;If not done, then return
	jp nz, ProcNextVibratoRet

	;Increase vibrato sequence
	ld hl, $16
	add hl, de
	inc [hl]
	ld a, [hl]

ProcNextVibrato:
	;Get next byte from vibrato sequence
	ld hl, $0F
	add hl, de
	push bc
	add [hl]
	ld c, a
	inc hl
	ld a, [hl]
	adc 0
	ld b, a
	ld a, [bc]
	pop bc
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

.ProcNextVibrato2
	;Check if value is positive or negative from upper 4 bits
	push af
	swap a
	and %00001111
	cp 8
	jr c, .ProcNextVibrato3

	;If negative
	or %11110000

.ProcNextVibrato3
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
	ld a, [bc]
	cp $D0
	;If less than D0, is a note or rest
	jr c, .NoteOrRest

	;Otherwise, is parameters or VCMD
	call ParamsOrVCMD
	;Repeat
	jr .NextCommand2

.NoteOrRest
	;Check if track is 3 (music 4)
	ld a, [CurTrackCheck]
	cp 3
	;If so, then use special handler
	jp z, ProcNoteMusC4

	;Otherwise, load envelope on/off address value into HL
	ld hl, $09
	add hl, de
	;Check current command
	ld a, [bc]
	cp $C0
	;If less than C0, then is a note
	jr c, ProcNote

	;Otherwise, is a rest
	ld [hl], 0
	jp ProcNoteMusC43

;It is a note
ProcNote:
	;Set envelope on/off value to on
	ld [hl], $FF
	push bc
	push af
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
	jr ProcNote2

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
	ld hl, $0C
	add hl, de
	or [hl]

	;Load frequency into RAM
	ld hl, $1D
	add hl, de
	ld [hl+], a
	xor a
	ld [hl], a

ProcNote2:
	;Reset note time
	ld hl, $08
	add hl, de
	xor a
	ld [hl], a

	;Get note length value
	ld a, [bc]
	and %00001111
	;Convert to actual note length with speed
	call ProcNoteLen

	;Set delay to result
	ld hl, $07
	add hl, de
	ld [hl], a

	;Advance pointer
	call AdvChanPos

	;Check for duty/volume flag
	ld hl, $11
	add hl, de
	;If highest bit not set, then skip processing delay
	bit 7, [hl]
	jr z, ProcDelay
	push af

	;Get lower 4 bits
	and %00001111
	ld c, a
	;Multiply with tertiary decay value
	ld hl, $13
	add hl, de
	ld a, [hl]
	swap a
	and %00001111
	push af
	call Multiply
	swap a
	and %00001111

	;Set envelope time to it
	ld hl, $0A
	add hl, de
	ld [hl], a
	pop af

	;Load original value and multiply more to get final decay value
	ld c, a
	pop af
	swap a
	and %00001111
	call Multiply
	add [hl]
	ld [hl], a

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
.ProcDelay_2
	xor %00000011

.ProcDelay_3
	and %00000011
	ld [hl], a
	;Reset vibrato step and envelope sequence position to FF
	ld hl, $16
	add hl, de
	ld a, $FF
	ld [hl+], a
	ld [hl+], a

	;Set envelope state to 0
	xor a
	ld [hl+], a

	;Reset vibrato to 0
	push hl
	ld hl, $1C
	add hl, de
	ld [hl], a

	;Also reset envelope length to 0
	ld hl, $0E
	add hl, de
	ld a, [hl]

	;Reset vibrato sequence delay to 0
	pop hl
	inc a
	ld [hl+], a

	;Set envelope duration to 1
	ld a, 1
	ld [hl], a
	ret

ProcNoteMusC4:
	;Get channel 3 SFX number
	ld a, [SFXC3MusNum]

	;If between $06 and $12, cue a tom-tom drum
	cp $06
	jr c, ProcNoteMusC42
	cp $0C
	jr nc, ProcNoteMusC42

	;Set pointer to "empty sequence"
	ld a, LOW(EmptySeq)
	ld [SFXC3SongPos], a
	ld a, HIGH(EmptySeq)
	ld [$C829], a

	;Set channel on output
	ld a, [Output]
	or %01000000
	ld [Output], a

	;Set SFX 3 note delay and SFX number to 1
	ld a, 1
	ld [SFXC3NoteDelay], a
	ld [SFXC3MusNum], a

	;Clear SFX 3 priority
	xor a
	ld [SFXC3Priority], a

ProcNoteMusC42:
	;Get current note value from upper 4 bits of sequence byte
	ld a, [bc]
	swap a
	;If less than $0C, then use the value to play SFX as "percussion"
	and %00001111
	cp $0C
	call nz, CallSFX

ProcNoteMusC43:
	;Get length as lower 4 bits and process the note length
	ld a, [bc]
	and %00001111
	call ProcNoteLen

	;Set actual length as delay
	ld hl, $07
	add hl, de
	ld [hl], a
	;Also clear note time
	ld hl, $08
	add hl, de
	xor a
	ld [hl], a
	pop hl

;Advance channel position
AdvChanPos:
	ld hl, $20
	add hl, de
	inc bc
	ld [hl], c
	inc hl
	ld [hl], b
	ret

ProcNoteLen:
	;Check if note length is 0
	ld hl, $0B

ProcNoteLen2:
	add hl, de
	or a
	;If so, then set to maximum speed value
	jr z, ProcNoteLenMax

ProcNoteLen3:

	;Otherwise, check if less than speed
	cp [hl]
	;If not, then multiply (same as otherwise?)
	jr nc, ProcNoteLenMult2

	;Otherwise, multiply value
	push bc
	ld c, a
	ld b, [hl]
	xor a

ProcNoteLenMult:
	add b
	dec c
	jr nz, ProcNoteLenMult
	pop bc
	ret

;Multiply value (same as before?)
ProcNoteLenMult2:
	push bc
	ld c, a
	ld b, [hl]
	xor a

.ProcNoteLenMult2_2:
	add b
	dec c
	jr nz, .ProcNoteLenMult2_2
	pop bc
	ret

ProcNoteLenMax:
	;Set note length to max length of speed
	ld a, [hl]
	swap a
	and %11110000
	ret

; Unsigned 8-bit multiply: A = A(in) * C(in).
; Early-out: if A==0 or C==0 the result is 0 (so callers test it afterwards
; with `or a; jr z` to skip a zero-length envelope stage). The `cp b` isn't a
; range test - it just picks the smaller operand as the loop counter so the
; repeated-add loop runs fewer iterations. Result is left in A.
Multiply:
	;If operand A is 0, then return
	or a
	ret z

	;Otherwise, then load into A and check operand C
	ld b, a
	xor a
	or c
	;Return if 0
	ret z

	;Compare B vs. C
	cp b
	;Pick the smaller operand as loop counter
	jr nc, .Multiply3
	xor a

;Now perform multiplication loop
.Multiply2:
	add b
	dec c
	jr nz, .Multiply2

	;Return when done
	ret

;Alternate loop
.Multiply3:
	xor a

.Multiply4:
	add c
	dec b
	jr nz, .Multiply4

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
	ld hl, $0B
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
	ld a, [bc]
	and %00110011
	add a
	add a
	ld [hl+], a

	;Next byte is decay
	inc bc
	ld a, [bc]
	ld [hl], a

	;Next byte is vibrato
	call EventVibrato
	;Final bytes are envelope and decay (if envelope is signed)
	jp GetEnvVal

GetParamsSFX4:
	;Check next byte - duty/volume
	ld a, [bc]
	;If 0, then 0, otherwise, 8
	or a
	jr z, .GetParamsSFX4_2
	ld a, 8

.GetParamsSFX4_2:
	;Load parameter into RAM variable
	ld [hl+], a
	;Next byte is decay
	inc bc
	ld a, [bc]
	ld [hl], a
	;Final bytes are envelope (and decay if envelope is signed)
	jp EventEnvDecay

GetParams3:
	;Current byte is waveform
	dec bc
	call EventWaveform
	;Next byte is envelope value
	ld a, [bc]
	ld hl, $11
	add hl, de
	ld [hl+], a
	;Check if envelope is at max
	add a
	;If not, then set envelope sequence
	jp nc, GetEnvSeq

	;Otherwise, next byte is secondary decay
	inc bc
	inc hl
	ld a, [bc]
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
	dw EventNop                  ;$F4
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
;Set the current octave (0-7)
	;Get lower 3 bits of command byte
	ld a, [bc]
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
	ld a, [bc]
	;Mask out bits and multiply to get final value
	and %00110011
	add a
	add a
	ld hl, $0C
	add hl, de
	jr StoreVal

.EventDutyVol_SFX4:
	ld a, [bc]
	or a
	jr z, .EventDutyVol_2
	ld a, 8

.EventDutyVol_2:
	;Store final value in RAM
	ld hl, $0C
	add hl, de
	jr StoreVal

EventDecay:
;Set decay
;Parameters: xxxxxxxx (x = value)
	ld hl, $0D
	add hl, de
	inc bc
	ld a, [bc]

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
	ld a, [bc]
	ld [hl], a
	inc bc
	ret

EventVibrato:
;Set vibrato
;Parameters: xxxxxxxx (x = value)
	;First, get note envelope length from upper 4 bits
	inc bc
	ld a, [bc]
	swap a
	and %00001111
	;Get the channel speed here, then enter ProcNoteLen past its own set-up
	ld hl, $0B
	add hl, de
	call ProcNoteLen3
	;Then, get vibrato
	ld hl, $0E
	add hl, de
	inc a
	ld [hl+], a
	ld a, [bc]
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
	ld a, [bc]
	ld [hl], a
	inc bc
	ret

EventWaveform:
;Set waveform
;Parameters: xxxxxxxx (x = value)
	;Check current track and set its respective waveform
	ld a, [CurTrackCheck]
	cp 2
	jr z, .EventWaveform2
	cp 6
	;If neither channel 3 tracks, then do nothing
	jr nz, NextByte
	inc bc
	ld a, [bc]
	ld [WaveformSFX], a
	inc bc
	ret

.EventWaveform2
	inc bc
	ld a, [bc]
	ld [WaveformMus], a
	inc bc
	ret

EventEnvDecay:
;Set duty/volume and decay 2/3
;Parameters: xyyyyyyy (zzzzzzzz aaaaaaaa)  (x = if set, z and a are used, z = decay 2, a = decay 3)
	inc bc

GetEnvVal:
	;Get envelope value from byte
	ld a, [bc]
	ld hl, $11
	add hl, de
	ld [hl+], a
	;If signed, then get decay parameters from next 2 bytes
	add a
	jr c, GetDecay

GetEnvSeq:
	;Get envelope sequence number from parameter
	ld a, [bc]

GetEnvSeq2:
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
	ld a, [bc]
	ld [hl+], a
	inc bc
	ld a, [bc]
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
	ld a, [bc]
	ld [hl], a
	inc bc
	ret

EventEnvVal:
;Set envelope value
;Parameters: xxxxxxxx (x = value)
	;Load parameter in RAM
	ld hl, $11
	add hl, de
	inc bc
	ld a, [bc]
	ld [hl], a
	inc bc
	ret

EventDecay2:
;Set secondary decay
;Parameters: xxxxxxxx (x = value)
	;Load parameter in RAM
	ld hl, $12
	add hl, de
	inc bc
	ld a, [bc]
	ld [hl], a
	inc bc
	ret

EventDecay3:
;Set tertiary decay
;Parameters: xxxxxxxx (x = value)
	;Load parameter in RAM
	ld hl, $13
	add hl, de
	inc bc
	ld a, [bc]
	ld [hl], a
	inc bc
	ret

EventFinalVol:
;Set final channel volume step
;Parameters: xxxxxxxx (x = value)
	;Load parameter in RAM
	ld hl, $05
	add hl, de
	inc bc
	ld a, [bc]
	ld [hl], a
	inc bc
	ret

EventSpeed:
;Set channel speed
;Parameters: xxxxxxxx (x = value)
	;Load parameter in RAM
	ld hl, $0B
	add hl, de
	inc bc
	ld a, [bc]
	ld [hl], a
	inc bc
	ret

EventMacro1:
;Go to macro (subroutine) (1)
;Parameters: xxxxxxxx xxxxxxxx (X = position, absolute)
;(NOTE: 1 level only)
	;Get pointer from 2 parameters
	inc bc
	ld a, [bc]
	ld l, a
	inc bc
	ld a, [bc]
	ld h, a
	inc bc

	;Load pointer into RAM
	push hl
	ld hl, $26
	add hl, de
	ld [hl], c
	inc hl
	ld [hl], b
	pop bc
	ret

EventMacro2:
;Go to macro (subroutine) (2)
;Parameters: xxxxxxxx xxxxxxxx (X = position, absolute)
;(NOTE: 1 level only)
	;Get pointer from 2 parameters
	inc bc
	ld a, [bc]
	ld l, a
	inc bc
	ld a, [bc]
	ld h, a
	inc bc

	;Load pointer into RAM
	push hl
	ld hl, $28
	add hl, de
	ld [hl], c
	inc hl
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
	ld a, [bc]
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
	jp NextByte

EventRepeat2End:
;End of repeat (2) - jump to start
;Parameters: xxxxxxxx (x = times to repeat, 0 = infinite)
	;Check if times parameter is 0
	inc bc
	ld a, [bc]
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
	ld hl, $0D
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

	;Set envelope on/off to off
	ld hl, $09
	add hl, de
	ld [hl], a

	;Also clear music number and priority
	ld h, d
	ld l, e
	ld [hl+], a
	ld [hl+], a

	;Reset sweep
	ld a, %00001000
	ld [hl], a

	;Set note time to 8
	ld hl, $08
	add hl, de
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

TrackMaskVals:
	db $01, $02, $04, $08, $10, $20, $40, $80

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
	add hl, de
	ld a, [hl]
	ld [bc], a

	;Load note time into "gate off" value
	inc bc
	ld hl, $08
	add hl, de
	ld a, [hl]
	ld [Gate1Off], a

MusC1Prep_2:
	;If note time is 0, then set duty/volume value to it
	or a
	jr z, MusC1Prep_3A

	;Otherwise, set it and swap
	ld hl, $0C
	add hl, de
	ld a, [hl]
	swap a
	jr MusC1Prep_3B

MusC1Prep_3A:
	ld hl, $0C
	add hl, de
	ld a, [hl]

MusC1Prep_3B:
	;Set NR11 wave duty
	and %11000000
	ld [bc], a

	;Then check if envelope is on
	inc bc
	ld hl, $09
	add hl, de
	ld a, [hl]
	or a
	;If so, then get hardware volume
	jr nz, MusC1Prep_4

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
	inc hl

	;Check if positive or negative
	bit 7, a
	jr nz, MusC1Prep_Neg

	;If positive, then add to frequency
	add [hl]
	inc hl
	;And set NR13 value to it
	ld [bc], a
	ld a, [hl]
	adc 0

MusC1Prep_7:
	;Set NR14 value
	inc bc
	and %00000111
	ld [bc], a

MusC4Prep:
	;Do nothing
	ret

MusC1Prep_Neg:
	;If negative, then add negative to frequency
	add [hl]
	push af
	inc hl
	ld [bc], a
	pop af
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
	ld hl, $08
	add hl, de
	ld a, [hl]
	ld [Gate2Off], a
	jr MusC1Prep_2

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
	inc bc

	;Then check if envelope is on
	ld hl, $09
	add hl, de
	ld a, [hl]
	or a
	;If not, then set NR33 to 0
	jr z, SFXC3Prep_2

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
	jp MusC1Prep_6

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

	;Load note time into "gate off" value
	ld bc, NR42Val
	ld hl, $08
	add hl, de
	ld a, [hl]
	ld [Gate4Off], a

	;Then check if envelope is on
	ld hl, $09
	add hl, de
	xor a
	or [hl]
	;If so, then get hardware volume
	jr nz, SFXC4Prep_2

	;If not, then use empty value
	ld a, %00001000
	jr SFXC4Prep_3

SFXC4Prep_2:
	;Get hardware volume
	ld hl, $1F
	add hl, de
	ld a, [hl]

SFXC4Prep_3:
	;Set NR42 value to it
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

OutputTracks:
	ld hl, NR10Val
	ld de, NR10ValCopy
	ld c, $10
	;Check "gate off" value
	ld a, [Gate1Off]
	ld b, a
	or a
	;If gate off, set register value
	jr z, .SetRegVal

	;Otherwise, check if copy register variable is the same as register value
	ld a, [de]
	cp [hl]
	;If so, then increase values
	jr z, .IncVals

.SetRegVal
	;Set temporary copy variable to register value
	ld a, [hl]
	ld [de], a
	;Also load to real register
	ldh [c], a
	ldh [c], a

.IncVals
	inc l
	inc e
	inc c

DoAllRegs:
	;Copy all register values in RAM to actual values and set appropriately
	call OutputReg
	ld a, b
	call OutputRegTrig
	ld a, b
	call OutputRegCheck
	call OutputRegWithTrig
	inc c
	call OutputReg
	ld a, [Gate2Off]
	call OutputRegTrig
	call OutputReg
	call OutputRegWithTrig
	call OutputReg
	inc l
	inc e
	inc c
	call OutputReg
	call OutputReg
	call OutputRegWithTrig
	inc c
	inc l
	inc e
	inc c
	ld a, [Gate4Off]
	call OutputRegTrig
	call OutputReg
	call OutputRegWithTrig

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
	ld a, [WaveformMus]
	jr LoadWaveform

SetSFXWaveform:
	ld a, [WaveformSFX]

LoadWaveform:
	;If waveform is same, then return
	ld hl, NewWave
	cp [hl]
	ret z

	;Otherwise, load new waveform - get pointer to waveform from table
	ld [hl], a
	add a
	add LOW(WaveTab)
	ld l, a
	ld a, HIGH(WaveTab)
	adc 0
	ld h, a
	ld a, [hl+]
	ld h, [hl]
	ld l, a

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
	jr z, .OutputRegTrig_2

	;Otherwise, check if copy register variable is the same as register value
	ld a, [de]
	cp [hl]
	jr z, OutputReg2IncVals

.OutputRegTrig_2
	;Get next register value from RAM
	ld a, [hl+]
	;Copy to copy register in RAM
	ld [de], a
	;Also load in real register
	ldh [c], a
	inc l
	set 7, [hl]
	dec l
	inc e
	inc c
	ret

OutputRegCheck:
	;Check "gate off" value
	or a
	;If gate off, get new value
	jr z, OutputReg2

OutputReg:
	;Get copy value and compare to main register value
	ld a, [de]
	cp [hl]
	;If same, then increase values and return
	jr z, OutputReg2IncVals

;Otherwise, load to main register value and actual register
OutputReg2:
	ld a, [hl]
	ld [de], a
	ldh [c], a

;Increase values
OutputReg2IncVals:
	inc l
	inc e
	inc c
	ret

OutputRegWithTrig:
	;Check "trigger" bit of copy value
	ld a, [de]
	bit 7, a
	;If set, then output new value
	jr nz, .OutputRegWithTrig2

	;Otherwise, check if main value is the same
	cp [hl]
	;If so, then return
	jr z, OutputReg2IncVals

;Otherwise, output new value
.OutputRegWithTrig2
	ld a, [hl]
	ldh [c], a
	and %00000111
	ld [de], a
	inc l
	inc e
	inc c
	ret

;Initialize audio with no music/SFX
NoAudio:
	push bc
	push de
	call ClearCh1
	ld a, %01110111
	ld [NR50Val], a
	jr InitSoundRAM

;Initialize audio
InitSound:
	push bc
	push de
	call AudioOff
	ld a, %01110111
	ldh [rNR50], a
	ld [NR50Val], a

;Initialize RAM variables
InitSoundRAM:
	ld hl, MusC1MusNum
	ld de, TrackRAMSize
	ld a, 0
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	ld hl, MusC1NoteTime				;Set note time flag to 1
	ld a, 1
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	ld a, 0
	ld [Output], a				;Set output flag to 0
	ld [Fade], a				;Disable fade out routine
	ld [FadeTime], a
	ld a, $FF
	ld [NewWave], a				;Set (new) waveform value
	pop de
	pop bc
	ret

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
	;Check if channel is on
	ldh a, [rNR52]
	bit 2, a
	;If not, then skip
	jr z, ClearCh4
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
	ld a, %00001000
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

EmptySeq:
	db $FF

Perc01D:
	db $D7, $00, $70, $87, $11, $81
	db $E0
	db $12
	db $FF

Perc02D:
	db $D7, $00, $80, $88, $31, $F4
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

VibTab:
	dw Vibrato0
	dw Vibrato1
	dw Vibrato2
	dw Vibrato3
	dw Vibrato4
	dw Vibrato5
	dw Vibrato6
	dw Vibrato7
	dw Vibrato7
	dw Vibrato7
	dw Vibrato7
	dw Vibrato7
	dw Vibrato7
	dw Vibrato7
	dw Vibrato7
	dw Vibrato7

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
	db $03, $13, $23, $13
	db $FF

WaveTab:
	dw Waveform00
	dw Waveform00
	dw Waveform00
	dw Waveform00
	dw Waveform00
	dw Waveform00
	dw Waveform00
	dw Waveform07
	dw Waveform07
	dw Waveform09
	dw Waveform09
	dw Waveform09
	dw Waveform09
	dw Waveform09
	dw Waveform09
	dw Waveform09

Waveform00:
	db $03, $69, $CF, $FC, $96, $30, $03, $56, $77, $65, $44, $33, $20, $00, $52, $00

Waveform07:
	db $01, $11, $12, $23, $34, $45, $56, $67, $78, $89, $9A, $AB, $BC, $CD, $DD, $D0

Waveform09:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $ED, $CB, $A9, $87, $65, $43, $21, $00

SFX09A:
	db $D2, $22, $00, $00, $0E
	db $EA, $16
	db $E3
	db $91
	db $EE, $04
	db $91
	db $EE, $02
	db $91
	db $FF

SFX0AA:
	db $D1, $22, $00, $00, $0E
	db $C1
	db $F6, $04
	db $EA, $16
	db $E3
	db $B1
	db $EE, $04
	db $B1
	db $EE, $02
	db $B1
	db $FF

SFX0BA:
	db $D1, $11, $C0, $00, $0F
	db $EA, $1E
	db $E8, $00
	db $E2
	db $38
	db $E8, $11
	db $EE, $03
	db $36
	db $FF

SFX0CA:
	db $D1, $00, $00, $00, $0E
	db $E3
	db $EA, $47
	db $12
	db $EA, $4F
	db $E3
	db $7C
	db $EE, $05
	db $7C
	db $EE, $02
	db $76
	db $FF

SFX0DA:
	db $D1, $22, $00, $00, $09
	db $E4
	db $31
	db $41
	db $51
	db $61
	db $71
	db $EE, $0E
	db $81
	db $71
	db $61
	db $51
	db $41
	db $31
	db $21
	db $11
	db $01
	db $11
	db $21
	db $31
	db $41
	db $51
	db $61
	db $71
	db $81
	db $91
	db $A1
	db $B1
	db $EE, $05
	db $51
	db $61
	db $71
	db $81
	db $91
	db $A1
	db $B1
	db $EE, $02
	db $51
	db $61
	db $71
	db $81
	db $91
	db $A1
	db $B1
	db $FF

SFX0EA:
	db $D2, $22, $00, $00, $0D
	db $E2
	db $71
	db $A1
	db $EE, $0F
	db $31
	db $71
	db $01
	db $EE, $05
	db $71
	db $A1
	db $31
	db $71
	db $01
	db $EE, $02
	db $71
	db $A1
	db $31
	db $71
	db $01
	db $FF

SFX0FA:
	db $EC, $FD

SFX10A:
	db $D1, $11, $00, $00, $0F
	db $E3
	db $42
	db $EE, $0A
	db $45
	db $EE, $0F
	db $02
	db $EE, $0A
	db $05
	db $EE, $0F
	db $42
	db $EE, $0A
	db $45
	db $EE, $0F
	db $02
	db $EE, $0A
	db $05
	db $EE, $02
	db $05
	db $FF

SFX11A:
	db $D1, $00, $00, $00, $0F
	db $E2
	db $41
	db $91
	db $41
	db $91
	db $41
	db $91
	db $41
	db $91
	db $41
	db $91
	db $41
	db $91
	db $41
	db $91
	db $41
	db $91
	db $41
	db $91
	db $EE, $0A
	db $41
	db $91
	db $41
	db $91
	db $41
	db $91
	db $EE, $02
	db $41
	db $91
	db $41
	db $91
	db $41
	db $91
	db $FF

SFX12D:
	db $D1, $11, $00, $0E
	db $E6
	db $52
	db $12
	db $EE, $05
	db $52
	db $12
	db $EE, $02
	db $52
	db $12
	db $FF

SFX13D:
	db $D1, $11, $00, $0C
	db $E7
	db $12
	db $E6
	db $52
	db $EE, $05
	db $E7
	db $12
	db $E6
	db $52
	db $FF

SFX14D:
	db $D1, $11, $00, $0E
	db $E6
	db $12
	db $52
	db $FF

SFX15D:
	db $D1, $00, $00, $08
	db $E0
	db $21
	db $EE, $0C
	db $21
	db $EE, $0F
	db $22
	db $EE, $08
	db $21
	db $EE, $04
	db $21
	db $FF

SFX16A:
	db $D1, $11, $A0, $00, $0E
	db $EA, $1E
	db $E7
	db $12
	db $EA, $17
	db $E4
	db $26
	db $EE, $06
	db $26
	db $FF

SFX17A:
	db $D1, $22, $A0, $00, $09
	db $EA, $1D
	db $E4
	db $12
	db $EA, $17
	db $E3
	db $26
	db $EE, $02
	db $26
	db $FF

Mus18B:
	db $D6, $11, $B2, $20, $8B, $34, $B0
	db $EC, $02
	db $FB
	db $E3
	db $46
	db $44
	db $24
	db $42
	db $54
	db $44
	db $24
	db $04
	db $E2
	db $96
	db $94
	db $B4
	db $E3
	db $02
	db $24
	db $44
	db $54
	db $74
	db $E3
	db $46
	db $44
	db $24
	db $42
	db $54
	db $44
	db $24
	db $04
	db $E2
	db $92
	db $B4
	db $E3
	db $04
	db $22
	db $42
	db $52
	db $72
	db $72
	db $C2
	db $94
	db $72
	db $62
	db $72
	db $D6, $12, $A1, $33, $8A, $74, $E3
	db $E4
	db $06
	db $E3
	db $B6
	db $E4
	db $04
	db $D6, $12, $B1, $33, $8B, $44, $E3
	db $E3
	db $B2
	db $92
	db $72
	db $24
	db $42
	db $52
	db $22
	db $74
	db $74
	db $54
	db $74
	db $42
	db $22
	db $C2
	db $04
	db $E2
	db $92
	db $B2
	db $E3
	db $02
	db $06
	db $E2
	db $94
	db $E3
	db $02
	db $52
	db $42
	db $72
	db $E2
	db $72
	db $C2
	db $B4
	db $B2
	db $92
	db $B2
	db $E3
	db $06
	db $E2
	db $B1
	db $E3
	db $01
	db $28
	db $36
	db $21
	db $31
	db $56
	db $31
	db $51
	db $D6, $12, $A1, $33, $8A, $76, $E3
	db $F6, $0C
	db $7C
	db $F6, $06
	db $52
	db $72
	db $92
	db $B2
	db $E4
	db $06
	db $F6, $0C
	db $E3
	db $79
	db $F6, $06
	db $D6, $11, $B2, $20, $8B, $34, $B0
	db $E2
	db $92
	db $B2
	db $E3
	db $02
	db $22
	db $FD, $00

Mus18A:
	db $D6, $00, $91, $20, $89, $23, $B0
	db $EC, $02
	db $FB
	db $E2
	db $76
	db $74
	db $54
	db $72
	db $94
	db $74
	db $54
	db $44
	db $06
	db $04
	db $24
	db $42
	db $54
	db $74
	db $94
	db $B4
	db $E2
	db $76
	db $74
	db $54
	db $72
	db $94
	db $74
	db $54
	db $44
	db $02
	db $24
	db $44
	db $52
	db $72
	db $92
	db $B2
	db $B2
	db $C2
	db $E3
	db $04
	db $E2
	db $B2
	db $A2
	db $B2
	db $D6, $11, $91, $20, $89, $23, $B0
	db $E1
	db $91
	db $E2
	db $01
	db $51
	db $01
	db $51
	db $91
	db $E3
	db $01
	db $E2
	db $91
	db $E3
	db $51
	db $01
	db $E2
	db $91
	db $51
	db $E3
	db $01
	db $E2
	db $91
	db $51
	db $01
	db $E3
	db $22
	db $02
	db $E2
	db $B2
	db $72
	db $21
	db $71
	db $B1
	db $71
	db $B1
	db $E3
	db $21
	db $E2
	db $B1
	db $71
	db $42
	db $E1
	db $B2
	db $E2
	db $B2
	db $E1
	db $B2
	db $E2
	db $92
	db $E1
	db $B2
	db $E2
	db $B2
	db $E1
	db $B2
	db $E2
	db $02
	db $E1
	db $B4
	db $92
	db $41
	db $E1
	db $91
	db $E2
	db $02
	db $22
	db $42
	db $52
	db $92
	db $52
	db $22
	db $E1
	db $92
	db $E2
	db $52
	db $92
	db $E3
	db $02
	db $22
	db $E2
	db $22
	db $E1
	db $B1
	db $E2
	db $71
	db $24
	db $22
	db $02
	db $22
	db $91
	db $51
	db $01
	db $E1
	db $91
	db $E2
	db $01
	db $51
	db $71
	db $91
	db $B1
	db $71
	db $21
	db $71
	db $B1
	db $71
	db $21
	db $71
	db $E3
	db $01
	db $E2
	db $81
	db $31
	db $01
	db $31
	db $81
	db $B1
	db $E3
	db $01
	db $21
	db $E2
	db $A1
	db $51
	db $21
	db $51
	db $A1
	db $E3
	db $01
	db $21
	db $42
	db $E2
	db $42
	db $42
	db $C2
	db $52
	db $42
	db $22
	db $02
	db $C2
	db $02
	db $C2
	db $42
	db $22
	db $42
	db $52
	db $22
	db $C2
	db $42
	db $42
	db $C2
	db $52
	db $42
	db $22
	db $02
	db $C2
	db $E1
	db $92
	db $C2
	db $E2
	db $02
	db $22
	db $42
	db $52
	db $72
	db $D6, $00, $91, $20, $89, $23, $B0
	db $FD, $00

Mus18C:
	db $D6, $06, $82, $90
	db $EC, $02
	db $FB
	db $FC
	db $E1
	db $02
	db $E2
	db $02
	db $FE, $07
	db $FC
	db $E0
	db $52
	db $E1
	db $52
	db $FE, $03
	db $FC
	db $E0
	db $72
	db $E1
	db $72
	db $FE, $03
	db $FC
	db $E1
	db $02
	db $E2
	db $02
	db $FE, $03
	db $FC
	db $E0
	db $A2
	db $E1
	db $A2
	db $FE, $03
	db $FC
	db $E0
	db $52
	db $E1
	db $52
	db $FE, $03
	db $E0
	db $72
	db $FC
	db $E1
	db $72
	db $E0
	db $72
	db $FE, $01
	db $B2
	db $E1
	db $22
	db $72
	db $FC
	db $E0
	db $52
	db $E1
	db $52
	db $FE, $07
	db $FC
	db $E0
	db $42
	db $E1
	db $42
	db $FE, $03
	db $FC
	db $E0
	db $92
	db $E1
	db $92
	db $FE, $03
	db $FC
	db $E1
	db $22
	db $E2
	db $22
	db $FE, $03
	db $FC
	db $E0
	db $72
	db $E1
	db $72
	db $FE, $03
	db $E0
	db $52
	db $E1
	db $52
	db $E0
	db $52
	db $E1
	db $52
	db $E0
	db $72
	db $E1
	db $72
	db $E0
	db $72
	db $E1
	db $72
	db $E0
	db $82
	db $E1
	db $82
	db $E0
	db $82
	db $E1
	db $82
	db $E0
	db $A2
	db $E1
	db $A2
	db $E0
	db $A2
	db $E1
	db $A2
	db $E1
	db $02
	db $E2
	db $02
	db $02
	db $C2
	db $22
	db $02
	db $E1
	db $B2
	db $92
	db $C2
	db $92
	db $C2
	db $E2
	db $02
	db $E1
	db $B2
	db $E2
	db $02
	db $22
	db $E1
	db $B2
	db $C2
	db $E2
	db $02
	db $02
	db $C2
	db $22
	db $02
	db $E1
	db $B2
	db $92
	db $C2
	db $52
	db $C2
	db $92
	db $52
	db $72
	db $92
	db $B2
	db $FD, $00

Mus18D:
	db $D6
	db $FB
	db $FC
	db $C4
	db $32
	db $32
	db $C4
	db $34
	db $FE, $02
	db $C4
	db $32
	db $32
	db $C2
	db $32
	db $34
	db $FC
	db $C4
	db $32
	db $32
	db $C4
	db $34
	db $FE, $02
	db $C4
	db $32
	db $32
	db $C2
	db $32
	db $32
	db $32
	db $FC
	db $C4
	db $34
	db $C4
	db $34
	db $FE, $06
	db $C4
	db $34
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $FC
	db $34
	db $FE, $0D
	db $31
	db $31
	db $32
	db $31
	db $31
	db $31
	db $31
	db $FD, $00

Mus19A:
	db $D7, $11, $B2, $20, $84, $23, $F8
	db $C2
	db $E1
	db $92
	db $E2
	db $22
	db $92
	db $C2
	db $E1
	db $A2
	db $E2
	db $42
	db $72
	db $A2
	db $92
	db $72
	db $42
	db $54
	db $C4
	db $FF

Mus19B:
	db $D7, $11, $C0, $20, $8B, $24, $EF
	db $E3
	db $52
	db $42
	db $22
	db $52
	db $72
	db $52
	db $42
	db $12
	db $2C
	db $FF

Mus19C:
	db $D7, $06, $82, $E0
	db $E1
	db $28
	db $18
	db $44
	db $E0
	db $94
	db $E1
	db $24
	db $FF

Mus1AB:
	db $D5, $12, $92, $20, $8B, $34, $B0
	db $EC, $07
	db $FB
	db $F7
	dw Mus1AB_1
	db $C4
	db $08
	db $E2
	db $B2
	db $C2
	db $E3
	db $08
	db $E2
	db $B2
	db $C2
	db $E3
	db $08
	db $E2
	db $B2
	db $C2
	db $98
	db $C4
	db $F7
	dw Mus1AB_1
	db $74
	db $48
	db $24
	db $04
	db $E2
	db $B4
	db $E3
	db $04
	db $E2
	db $94
	db $B4
	db $E3
	db $04
	db $24
	db $14
	db $04
	db $FD, $00

Mus1AB_1:
	db $E2
	db $B8
	db $A2
	db $C2
	db $B8
	db $A2
	db $C2
	db $B8
	db $E3
	db $22
	db $C2
	db $28
	db $F9

Mus1AA:
	db $D5, $12, $62, $20, $8B, $34, $B0
	db $EC, $07
	db $FB
	db $F7
	dw Mus1AA_1
	db $C4
	db $98
	db $82
	db $C2
	db $98
	db $82
	db $C2
	db $98
	db $72
	db $C2
	db $68
	db $C4
	db $F7
	dw Mus1AA_1
	db $E3
	db $24
	db $08
	db $E2
	db $B4
	db $94
	db $84
	db $94
	db $64
	db $74
	db $94
	db $B4
	db $A4
	db $94
	db $FD, $00

Mus1AA_1:
	db $E2
	db $78
	db $62
	db $C2
	db $78
	db $62
	db $C2
	db $78
	db $B2
	db $C2
	db $B8
	db $F9

Mus1AC:
	db $D5, $06, $82, $E0
	db $EC, $07
	db $FB
	db $FC
	db $F7
	dw Mus1AC_1
	db $FE, $02
	db $E0
	db $74
	db $E2
	db $22
	db $E1
	db $B2
	db $72
	db $B2
	db $FC
	db $E0
	db $94
	db $E2
	db $42
	db $02
	db $42
	db $02
	db $FE, $01
	db $E1
	db $24
	db $E2
	db $62
	db $22
	db $E1
	db $92
	db $62
	db $E1
	db $24
	db $62
	db $E2
	db $22
	db $E1
	db $92
	db $E2
	db $62
	db $F7
	dw Mus1AC_1
	db $F7
	dw Mus1AC_1
	db $E1
	db $44
	db $B2
	db $72
	db $B2
	db $72
	db $44
	db $B2
	db $72
	db $B2
	db $E2
	db $42
	db $FC
	db $E1
	db $04
	db $E2
	db $42
	db $E1
	db $72
	db $E2
	db $42
	db $E1
	db $72
	db $FE, $01
	db $E1
	db $24
	db $E2
	db $62
	db $E1
	db $92
	db $E2
	db $62
	db $E1
	db $92
	db $E1
	db $22
	db $E2
	db $22
	db $E1
	db $42
	db $E2
	db $42
	db $E1
	db $62
	db $E2
	db $62
	db $FD, $00

Mus1AC_1:
	db $E0
	db $74
	db $E2
	db $22
	db $E1
	db $B2
	db $E2
	db $22
	db $E1
	db $B2
	db $F9

Mus1AD:
	db $D5
	db $FB
	db $FC
	db $C4
	db $32
	db $C2
	db $32
	db $C2
	db $FE, $0E
	db $32
	db $C2
	db $32
	db $C2
	db $32
	db $C2
	db $FD, $00

Mus1BB:
	db $D7, $11, $B2, $20, $8B, $34, $B2
	db $FB
	db $E3
	db $02
	db $02
	db $E2
	db $B2
	db $E3
	db $02
	db $22
	db $01
	db $C3
	db $E2
	db $92
	db $A4
	db $94
	db $74
	db $C4
	db $C2
	db $A2
	db $92
	db $A2
	db $72
	db $A2
	db $E3
	db $22
	db $52
	db $42
	db $C2
	db $22
	db $C2
	db $02
	db $C2
	db $E2
	db $A2
	db $C2
	db $92
	db $A2
	db $B2
	db $E3
	db $02
	db $22
	db $01
	db $C3
	db $E2
	db $92
	db $A2
	db $92
	db $A2
	db $E3
	db $22
	db $54
	db $C4
	db $42
	db $42
	db $42
	db $52
	db $72
	db $52
	db $42
	db $72
	db $52
	db $C2
	db $02
	db $C2
	db $53
	db $C5
	db $22
	db $C2
	db $22
	db $C2
	db $22
	db $52
	db $42
	db $22
	db $02
	db $E2
	db $A2
	db $92
	db $A2
	db $E3
	db $04
	db $C4
	db $E2
	db $A2
	db $92
	db $72
	db $A2
	db $E3
	db $22
	db $E2
	db $B2
	db $E3
	db $22
	db $52
	db $42
	db $52
	db $72
	db $52
	db $44
	db $C4
	db $22
	db $C2
	db $22
	db $C2
	db $22
	db $42
	db $52
	db $72
	db $92
	db $52
	db $92
	db $E4
	db $22
	db $02
	db $E3
	db $A2
	db $92
	db $72
	db $52
	db $C2
	db $22
	db $C2
	db $92
	db $51
	db $C1
	db $52
	db $21
	db $C1
	db $72
	db $52
	db $42
	db $22
	db $04
	db $C4
	db $FD, $00

Mus1BA:
	db $D7, $11, $91, $20, $89, $23, $B2
	db $FB
	db $E4
	db $51
	db $E3
	db $91
	db $E1
	db $91
	db $F7
	dw Mus1BA_1
	db $22
	db $E2
	db $21
	db $C3
	db $21
	db $C3
	db $21
	db $C3
	db $A1
	db $C1
	db $C2
	db $41
	db $C3
	db $42
	db $E3
	db $A1
	db $E4
	db $A1
	db $E3
	db $71
	db $E4
	db $71
	db $E3
	db $41
	db $E4
	db $41
	db $E3
	db $01
	db $E4
	db $01
	db $C2
	db $E1
	db $91
	db $F7
	dw Mus1BA_1
	db $E3
	db $02
	db $E2
	db $41
	db $C3
	db $42
	db $E3
	db $42
	db $22
	db $02
	db $42
	db $E2
	db $92
	db $E1
	db $92
	db $E2
	db $72
	db $42
	db $91
	db $E3
	db $91
	db $01
	db $E4
	db $01
	db $E3
	db $51
	db $E4
	db $51
	db $E3
	db $91
	db $E4
	db $91
	db $E4
	db $51
	db $E3
	db $A1
	db $E2
	db $21
	db $C3
	db $21
	db $C3
	db $21
	db $C3
	db $21
	db $C1
	db $C2
	db $01
	db $C3
	db $02
	db $E4
	db $91
	db $41
	db $01
	db $E3
	db $91
	db $E4
	db $41
	db $01
	db $E3
	db $91
	db $41
	db $22
	db $E1
	db $A1
	db $C3
	db $A2
	db $E2
	db $52
	db $72
	db $52
	db $B2
	db $E3
	db $02
	db $22
	db $42
	db $22
	db $01
	db $E4
	db $01
	db $E2
	db $71
	db $E3
	db $71
	db $E2
	db $41
	db $E3
	db $41
	db $E2
	db $01
	db $E3
	db $01
	db $E2
	db $A1
	db $51
	db $21
	db $C3
	db $22
	db $A2
	db $E3
	db $02
	db $22
	db $E2
	db $A2
	db $E3
	db $02
	db $E2
	db $01
	db $C3
	db $02
	db $E3
	db $92
	db $72
	db $52
	db $42
	db $22
	db $E2
	db $A1
	db $E1
	db $A1
	db $FC
	db $C2
	db $E2
	db $A1
	db $E1
	db $A1
	db $FE, $02
	db $E3
	db $42
	db $22
	db $02
	db $E2
	db $A2
	db $41
	db $E4
	db $01
	db $E2
	db $51
	db $E3
	db $11
	db $E2
	db $61
	db $E3
	db $21
	db $E2
	db $71
	db $E3
	db $41
	db $FD, $00

Mus1BA_1:
	db $C3
	db $91
	db $C3
	db $92
	db $E4
	db $01
	db $E5
	db $01
	db $E2
	db $01
	db $C1
	db $C2
	db $E1
	db $A1
	db $C3
	db $A1
	db $C3
	db $A2
	db $E4
	db $71
	db $21
	db $E3
	db $A1
	db $71
	db $F9

Mus1BC:
	db $D7, $06, $82, $92
	db $FB
	db $F7
	dw Mus1BC_1
	db $FC
	db $E0
	db $A2
	db $E1
	db $A2
	db $E2
	db $52
	db $E1
	db $A2
	db $FE, $01
	db $E1
	db $02
	db $E2
	db $02
	db $72
	db $02
	db $E1
	db $02
	db $72
	db $42
	db $02
	db $F7
	dw Mus1BC_1
	db $E1
	db $02
	db $E2
	db $02
	db $72
	db $02
	db $E1
	db $02
	db $E2
	db $02
	db $E1
	db $72
	db $02
	db $E0
	db $52
	db $E1
	db $52
	db $02
	db $E2
	db $02
	db $E0
	db $52
	db $92
	db $E1
	db $02
	db $52
	db $F7
	dw Mus1BC_2
	db $72
	db $42
	db $02
	db $E0
	db $72
	db $F7
	dw Mus1BC_2
	db $02
	db $12
	db $22
	db $42
	db $FD, $00

Mus1BC_1:
	db $FC
	db $E0
	db $52
	db $E1
	db $52
	db $E2
	db $02
	db $E1
	db $52
	db $FE, $01
	db $FC
	db $E0
	db $72
	db $E1
	db $72
	db $E2
	db $22
	db $E1
	db $72
	db $FE, $01
	db $F9

Mus1BC_2:
	db $FC
	db $E0
	db $A2
	db $E1
	db $A2
	db $E2
	db $52
	db $E1
	db $A2
	db $FE, $01
	db $FC
	db $E0
	db $92
	db $E1
	db $92
	db $E2
	db $42
	db $E1
	db $92
	db $FE, $01
	db $FC
	db $E0
	db $72
	db $E1
	db $72
	db $E2
	db $22
	db $E1
	db $72
	db $FE, $01
	db $E1
	db $02
	db $E2
	db $02
	db $72
	db $02
	db $E1
	db $F9

Mus1CB:
	db $D6, $01, $B2, $20, $8F, $34, $B0
	db $FB
	db $E3
	db $11
	db $C1
	db $11
	db $C1
	db $12
	db $22
	db $32
	db $42
	db $12
	db $E2
	db $92
	db $E3
	db $61
	db $C1
	db $61
	db $C1
	db $62
	db $82
	db $96
	db $C2
	db $82
	db $92
	db $B2
	db $92
	db $81
	db $C1
	db $84
	db $42
	db $E2
	db $B2
	db $E3
	db $22
	db $62
	db $52
	db $44
	db $C4
	db $22
	db $12
	db $22
	db $62
	db $B2
	db $92
	db $82
	db $62
	db $41
	db $C1
	db $41
	db $C1
	db $42
	db $62
	db $42
	db $24
	db $12
	db $E2
	db $B2
	db $A2
	db $B2
	db $E3
	db $32
	db $62
	db $52
	db $62
	db $92
	db $84
	db $94
	db $B4
	db $C4
	db $E4
	db $12
	db $E3
	db $91
	db $C1
	db $92
	db $41
	db $C1
	db $62
	db $84
	db $91
	db $C1
	db $B2
	db $92
	db $82
	db $B2
	db $94
	db $C4
	db $FD, $00

Mus1CA:
	db $D6, $00, $91, $20, $89, $23, $B0
	db $FB
	db $E2
	db $41
	db $11
	db $41
	db $C2
	db $41
	db $92
	db $41
	db $11
	db $41
	db $C2
	db $41
	db $12
	db $91
	db $61
	db $21
	db $C2
	db $91
	db $22
	db $61
	db $21
	db $61
	db $C2
	db $21
	db $61
	db $91
	db $B1
	db $41
	db $B1
	db $C2
	db $81
	db $42
	db $B1
	db $41
	db $B1
	db $C2
	db $B1
	db $81
	db $41
	db $61
	db $21
	db $61
	db $91
	db $B1
	db $21
	db $B1
	db $91
	db $81
	db $41
	db $E1
	db $B1
	db $E2
	db $41
	db $81
	db $B1
	db $81
	db $41
	db $61
	db $21
	db $61
	db $C2
	db $91
	db $62
	db $61
	db $21
	db $61
	db $C2
	db $21
	db $91
	db $21
	db $81
	db $41
	db $81
	db $C2
	db $11
	db $81
	db $11
	db $81
	db $11
	db $82
	db $11
	db $41
	db $81
	db $41
	db $61
	db $31
	db $61
	db $C2
	db $61
	db $31
	db $E1
	db $B1
	db $E2
	db $31
	db $E1
	db $B1
	db $E2
	db $32
	db $E1
	db $B1
	db $E2
	db $31
	db $61
	db $B1
	db $B1
	db $41
	db $B1
	db $C2
	db $41
	db $B1
	db $41
	db $81
	db $41
	db $E1
	db $B1
	db $E2
	db $41
	db $81
	db $41
	db $81
	db $B1
	db $41
	db $11
	db $41
	db $C2
	db $41
	db $11
	db $91
	db $22
	db $44
	db $62
	db $E1
	db $B1
	db $E2
	db $21
	db $61
	db $B1
	db $41
	db $81
	db $B1
	db $E3
	db $41
	db $E2
	db $91
	db $41
	db $11
	db $E1
	db $91
	db $E3
	db $41
	db $11
	db $E2
	db $91
	db $41
	db $FD, $00

Mus1CC:
	db $D6, $06, $82, $90
	db $FB
	db $FC
	db $E0
	db $92
	db $92
	db $E1
	db $12
	db $42
	db $FE, $01
	db $F7
	dw Mus1CC_1
	db $FC
	db $42
	db $42
	db $82
	db $B2
	db $FE, $01
	db $E0
	db $B2
	db $B2
	db $E1
	db $22
	db $62
	db $42
	db $42
	db $E0
	db $B2
	db $E1
	db $42
	db $F7
	dw Mus1CC_1
	db $FC
	db $12
	db $12
	db $42
	db $82
	db $FE, $01
	db $FC
	db $E0
	db $B2
	db $B2
	db $E1
	db $32
	db $62
	db $FE, $01
	db $42
	db $42
	db $82
	db $B2
	db $42
	db $22
	db $12
	db $E0
	db $B2
	db $92
	db $92
	db $E1
	db $12
	db $42
	db $22
	db $22
	db $62
	db $92
	db $E0
	db $B2
	db $E1
	db $B2
	db $42
	db $E2
	db $42
	db $E0
	db $92
	db $42
	db $62
	db $82
	db $FD, $00

Mus1CC_1:
	db $FC
	db $22
	db $22
	db $62
	db $92
	db $FE, $01
	db $F9

Mus1DB:
	db $D6, $01, $C2, $20, $82, $34, $B0
	db $EC, $00
	db $FB
	db $E2
	db $B4
	db $74
	db $E3
	db $24
	db $E2
	db $B4
	db $E3
	db $72
	db $62
	db $72
	db $28
	db $C2
	db $04
	db $E2
	db $94
	db $E3
	db $54
	db $44
	db $22
	db $E2
	db $62
	db $72
	db $84
	db $92
	db $82
	db $92
	db $B4
	db $74
	db $E3
	db $24
	db $E2
	db $B4
	db $E3
	db $72
	db $92
	db $B2
	db $B4
	db $92
	db $72
	db $52
	db $42
	db $32
	db $42
	db $72
	db $E4
	db $02
	db $E3
	db $B2
	db $92
	db $72
	db $32
	db $52
	db $72
	db $74
	db $52
	db $32
	db $52
	db $22
	db $C4
	db $E2
	db $94
	db $62
	db $72
	db $84
	db $92
	db $92
	db $92
	db $E3
	db $22
	db $02
	db $E2
	db $B2
	db $92
	db $B6
	db $76
	db $B4
	db $92
	db $E3
	db $62
	db $52
	db $64
	db $22
	db $E2
	db $92
	db $62
	db $42
	db $62
	db $72
	db $64
	db $72
	db $92
	db $62
	db $72
	db $92
	db $B2
	db $94
	db $B2
	db $E3
	db $02
	db $22
	db $42
	db $E4
	db $02
	db $E3
	db $B2
	db $B4
	db $92
	db $72
	db $B2
	db $92
	db $B2
	db $E4
	db $02
	db $22
	db $C8
	db $F7
	dw Mus1DB_1
	db $E2
	db $62
	db $72
	db $82
	db $92
	db $B2
	db $E3
	db $02
	db $12
	db $F7
	dw Mus1DB_1
	db $E2
	db $22
	db $32
	db $42
	db $62
	db $72
	db $82
	db $92
	db $FD, $00

Mus1DB_1:
	db $E3
	db $24
	db $74
	db $94
	db $B4
	db $C2
	db $E4
	db $02
	db $E3
	db $B2
	db $E4
	db $04
	db $E3
	db $92
	db $52
	db $02
	db $44
	db $74
	db $E4
	db $04
	db $E3
	db $B4
	db $92
	db $F9

Mus1DC:
	db $D6, $06, $82, $E0
	db $EC, $00
	db $FB
	db $FC
	db $E1
	db $72
	db $E2
	db $22
	db $FE, $07
	db $FC
	db $E1
	db $52
	db $E2
	db $22
	db $FE, $03
	db $FC
	db $E1
	db $22
	db $92
	db $FE, $03
	db $FC
	db $E1
	db $72
	db $E2
	db $22
	db $FE, $03
	db $FC
	db $E1
	db $52
	db $E2
	db $22
	db $FE, $03
	db $FC
	db $E1
	db $42
	db $E2
	db $02
	db $FE, $03
	db $FC
	db $E1
	db $32
	db $E2
	db $02
	db $FE, $03
	db $FC
	db $E1
	db $22
	db $92
	db $FE, $07
	db $FC
	db $02
	db $72
	db $FE, $03
	db $FC
	db $E1
	db $22
	db $92
	db $FE, $03
	db $02
	db $22
	db $42
	db $24
	db $42
	db $62
	db $22
	db $42
	db $62
	db $72
	db $64
	db $72
	db $92
	db $B2
	db $FC
	db $E2
	db $02
	db $E1
	db $72
	db $FE, $03
	db $92
	db $B2
	db $E2
	db $02
	db $24
	db $22
	db $E1
	db $B2
	db $92
	db $F7
	dw Mus1DC_1
	db $62
	db $72
	db $82
	db $92
	db $B2
	db $92
	db $82
	db $F7
	dw Mus1DC_1
	db $22
	db $32
	db $42
	db $62
	db $72
	db $82
	db $92
	db $FD, $00

Mus1DC_1:
	db $FC
	db $E1
	db $72
	db $E2
	db $22
	db $FE, $03
	db $E1
	db $52
	db $E2
	db $02
	db $E1
	db $52
	db $E2
	db $02
	db $E1
	db $52
	db $E2
	db $02
	db $E1
	db $92
	db $52
	db $FC
	db $02
	db $72
	db $FE, $03
	db $22
	db $F9

Mus1DA:
	db $D6, $01, $91, $20, $81, $23, $B0
	db $EC, $00
	db $FB
	db $EF, $01
	db $F7
	dw Mus1DA_1
	db $62
	db $72
	db $21
	db $E2
	db $71
	db $E3
	db $21
	db $71
	db $E4
	db $21
	db $B1
	db $71
	db $21
	db $E3
	db $B1
	db $E4
	db $01
	db $E3
	db $03
	db $91
	db $E2
	db $93
	db $E4
	db $51
	db $E3
	db $53
	db $E4
	db $41
	db $E3
	db $43
	db $E4
	db $21
	db $E3
	db $21
	db $E2
	db $22
	db $42
	db $54
	db $62
	db $52
	db $62
	db $F7
	dw Mus1DA_1
	db $92
	db $B2
	db $B2
	db $71
	db $21
	db $E2
	db $B1
	db $E3
	db $21
	db $E2
	db $B1
	db $71
	db $B1
	db $E3
	db $02
	db $E2
	db $B2
	db $E3
	db $02
	db $42
	db $71
	db $01
	db $41
	db $01
	db $41
	db $E2
	db $71
	db $E3
	db $01
	db $01
	db $01
	db $E2
	db $71
	db $E3
	db $21
	db $E2
	db $71
	db $E3
	db $31
	db $E2
	db $71
	db $E3
	db $31
	db $E2
	db $71
	db $E3
	db $31
	db $E2
	db $71
	db $E3
	db $21
	db $E2
	db $71
	db $E3
	db $01
	db $71
	db $E4
	db $01
	db $31
	db $21
	db $E3
	db $61
	db $91
	db $E4
	db $21
	db $61
	db $E3
	db $91
	db $E4
	db $21
	db $61
	db $91
	db $E2
	db $91
	db $22
	db $42
	db $52
	db $E4
	db $91
	db $E3
	db $91
	db $E2
	db $61
	db $E3
	db $91
	db $E2
	db $61
	db $E3
	db $91
	db $E2
	db $61
	db $E3
	db $91
	db $E4
	db $21
	db $E3
	db $21
	db $E4
	db $01
	db $E3
	db $01
	db $B1
	db $E2
	db $B1
	db $E3
	db $91
	db $E2
	db $91
	db $71
	db $B1
	db $E3
	db $01
	db $41
	db $71
	db $B1
	db $E4
	db $01
	db $41
	db $71
	db $41
	db $01
	db $E3
	db $71
	db $E4
	db $41
	db $01
	db $E3
	db $71
	db $41
	db $21
	db $E2
	db $61
	db $91
	db $61
	db $81
	db $61
	db $91
	db $E3
	db $21
	db $E2
	db $61
	db $91
	db $E3
	db $91
	db $21
	db $61
	db $E2
	db $91
	db $E3
	db $21
	db $E2
	db $61
	db $E1
	db $71
	db $E2
	db $41
	db $E1
	db $91
	db $E2
	db $61
	db $E1
	db $B1
	db $E2
	db $71
	db $E1
	db $91
	db $E2
	db $61
	db $E4
	db $21
	db $91
	db $E1
	db $B1
	db $E2
	db $71
	db $01
	db $91
	db $E1
	db $91
	db $E2
	db $61
	db $E1
	db $B1
	db $E2
	db $71
	db $01
	db $91
	db $21
	db $B1
	db $21
	db $91
	db $E4
	db $21
	db $91
	db $E2
	db $21
	db $B1
	db $41
	db $E3
	db $01
	db $61
	db $E3
	db $21
	db $71
	db $01
	db $41
	db $71
	db $E3
	db $01
	db $E2
	db $41
	db $71
	db $E3
	db $01
	db $41
	db $E2
	db $71
	db $E3
	db $01
	db $41
	db $71
	db $01
	db $41
	db $71
	db $E2
	db $62
	db $72
	db $92
	db $62
	db $E4
	db $91
	db $61
	db $21
	db $E3
	db $91
	db $61
	db $21
	db $E2
	db $91
	db $61
	db $F7
	dw Mus1DA_2
	db $61
	db $E3
	db $41
	db $E2
	db $71
	db $E3
	db $51
	db $E2
	db $81
	db $E3
	db $61
	db $E2
	db $91
	db $E3
	db $71
	db $E2
	db $B1
	db $E3
	db $91
	db $01
	db $A1
	db $11
	db $F7
	dw Mus1DA_2
	db $21
	db $E3
	db $31
	db $E2
	db $31
	db $E3
	db $41
	db $E2
	db $41
	db $E3
	db $61
	db $E2
	db $61
	db $E3
	db $71
	db $E2
	db $71
	db $E3
	db $81
	db $E2
	db $81
	db $E3
	db $91
	db $E2
	db $91
	db $FD, $00

Mus1DA_2:
	db $E2
	db $B1
	db $E3
	db $21
	db $E2
	db $B1
	db $71
	db $B1
	db $E3
	db $71
	db $E2
	db $B1
	db $71
	db $B1
	db $E3
	db $91
	db $E2
	db $B1
	db $71
	db $B1
	db $E3
	db $B1
	db $E2
	db $B1
	db $71
	db $E3
	db $91
	db $51
	db $E2
	db $91
	db $E4
	db $01
	db $E2
	db $91
	db $E3
	db $B1
	db $E2
	db $91
	db $E4
	db $01
	db $E3
	db $91
	db $51
	db $01
	db $91
	db $E2
	db $91
	db $E3
	db $51
	db $E2
	db $51
	db $E3
	db $01
	db $E2
	db $71
	db $E3
	db $41
	db $E2
	db $71
	db $41
	db $71
	db $E3
	db $71
	db $E2
	db $71
	db $41
	db $71
	db $E4
	db $01
	db $E2
	db $71
	db $41
	db $71
	db $E3
	db $B1
	db $E2
	db $71
	db $41
	db $62
	db $E3
	db $21
	db $E2
	db $F9

Mus1DA_1:
	db $E3
	db $B1
	db $E2
	db $B3
	db $E3
	db $71
	db $E2
	db $73
	db $E4
	db $21
	db $E3
	db $23
	db $B1
	db $E2
	db $B3
	db $E4
	db $71
	db $E3
	db $72
	db $F9

Mus1DD:
	db $D6
	db $FB
	db $FC
	db $C4
	db $34
	db $FE, $06
	db $C4
	db $32
	db $32
	db $FC
	db $C4
	db $34
	db $FE, $06
	db $C4
	db $31
	db $31
	db $31
	db $31
	db $FC
	db $C4
	db $34
	db $FE, $07
	db $36
	db $3A
	db $36
	db $3A
	db $34
	db $34
	db $34
	db $34
	db $3C
	db $31
	db $31
	db $31
	db $31
	db $FC
	db $C4
	db $34
	db $FE, $05
	db $36
	db $34
	db $34
	db $32
	db $FC
	db $C4
	db $34
	db $FE, $06
	db $FC
	db $31
	db $FE, $07
	db $FD, $00

Mus1EB:
	db $D3, $11, $A2, $20, $8B, $34, $B0
	db $FB
	db $F7
	dw Mus1EB_1
	db $54
	db $34
	db $44
	db $54
	db $54
	db $94
	db $E4
	db $04
	db $E3
	db $B4
	db $A4
	db $94
	db $88
	db $74
	db $64
	db $74
	db $F7
	dw Mus1EB_1
	db $84
	db $94
	db $E4
	db $04
	db $34
	db $28
	db $04
	db $14
	db $22
	db $C6
	db $E3
	db $A4
	db $B2
	db $72
	db $E4
	db $72
	db $CA
	db $E2
	db $EF, $02
	db $F7
	dw Mus1EA_2
	db $EF, $00
	db $E4
	db $C0
	db $12
	db $22
	db $E3
	db $A2
	db $B2
	db $62
	db $72
	db $12
	db $22
	db $FD, $00

Mus1EB_1:
	db $E3
	db $04
	db $04
	db $44
	db $54
	db $64
	db $72
	db $C6
	db $74
	db $E4
	db $04
	db $E3
	db $A4
	db $94
	db $70
	db $C4
	db $C4
	db $F9

Mus1EC:
	db $D3, $06, $82, $E0
	db $FB
	db $F7
	dw Mus1EC_1
	db $54
	db $44
	db $24
	db $F7
	dw Mus1EC_1
	db $E0
	db $74
	db $94
	db $B4
	db $E1
	db $F7
	dw Mus1EA_2
	db $C4
	db $E0
	db $74
	db $E1
	db $74
	db $E0
	db $74
	db $C0
	db $FD, $00

Mus1EC_1:
	db $FC
	db $E1
	db $02
	db $72
	db $02
	db $C6
	db $02
	db $72
	db $04
	db $04
	db $34
	db $44
	db $FE, $01
	db $52
	db $E2
	db $02
	db $E1
	db $52
	db $C6
	db $52
	db $E2
	db $02
	db $E1
	db $54
	db $54
	db $04
	db $54
	db $72
	db $22
	db $E0
	db $72
	db $C6
	db $72
	db $E1
	db $22
	db $74
	db $F9

Mus1EA_2:
	db $04
	db $34
	db $44
	db $54
	db $C4
	db $64
	db $C4
	db $74
	db $F9

Mus1EA:
	db $D3, $00, $81, $20, $89, $23, $B0
	db $FB
	db $F7
	dw Mus1EA_1
	db $94
	db $64
	db $74
	db $94
	db $94
	db $E3
	db $04
	db $54
	db $24
	db $14
	db $04
	db $22
	db $E2
	db $52
	db $74
	db $B4
	db $A4
	db $B4
	db $F7
	dw Mus1EA_1
	db $B4
	db $E3
	db $04
	db $54
	db $92
	db $02
	db $92
	db $52
	db $E2
	db $52
	db $92
	db $E3
	db $02
	db $52
	db $64
	db $74
	db $E2
	db $72
	db $B2
	db $E3
	db $22
	db $72
	db $22
	db $E2
	db $B2
	db $E3
	db $B4
	db $E2
	db $71
	db $41
	db $01
	db $E1
	db $91
	db $91
	db $E2
	db $01
	db $41
	db $71
	db $F7
	dw Mus1EA_2
	db $C4
	db $E1
	db $74
	db $E2
	db $74
	db $E1
	db $74
	db $E2
	db $A2
	db $B2
	db $62
	db $72
	db $12
	db $22
	db $E1
	db $A2
	db $B2
	db $FD, $00

Mus1EA_1:
	db $E2
	db $44
	db $44
	db $74
	db $A4
	db $B4
	db $E3
	db $02
	db $C6
	db $04
	db $44
	db $24
	db $04
	db $E2
	db $A8
	db $74
	db $44
	db $04
	db $C4
	db $F9

Mus1ED:
	db $D3
	db $FB
	db $FC
	db $C8
	db $38
	db $C8
	db $38
	db $C8
	db $38
	db $C8
	db $34
	db $34
	db $FE, $02
	db $C8
	db $38
	db $C8
	db $38
	db $C8
	db $38
	db $C4
	db $34
	db $34
	db $34
	db $38
	db $38
	db $38
	db $38
	db $38
	db $C0
	db $32
	db $32
	db $32
	db $32
	db $FD, $00

Mus1FB:
	db $D4, $11, $B2, $20, $8B, $34, $B0
	db $E3
	db $34
	db $24
	db $04
	db $34
	db $FC
	db $41
	db $51
	db $FE, $06
	db $42
	db $54
	db $34
	db $24
	db $54
	db $FC
	db $61
	db $71
	db $FE, $07
	db $FF

Mus1FC:
	db $D4, $06, $82, $E0
	db $E2
	db $00
	db $10
	db $20
	db $30
	db $FF

Mus1FA:
	db $D4, $00, $91, $20, $89, $23, $B0
	db $E2
	db $64
	db $94
	db $64
	db $94
	db $74
	db $A4
	db $74
	db $A4
	db $84
	db $B4
	db $84
	db $B4
	db $FC
	db $91
	db $A1
	db $FE, $07
	db $FF

Mus20B:
	db $D3, $11, $B2, $20, $8B, $34, $B0
	db $E3
	db $22
	db $E2
	db $62
	db $92
	db $E3
	db $22
	db $62
	db $E2
	db $92
	db $E3
	db $22
	db $62
	db $92
	db $22
	db $62
	db $92
	db $E4
	db $22
	db $E3
	db $62
	db $92
	db $E4
	db $22
	db $E3
	db $22
	db $E2
	db $72
	db $B2
	db $E3
	db $22
	db $72
	db $E2
	db $B2
	db $E3
	db $22
	db $72
	db $92
	db $E2
	db $92
	db $E3
	db $12
	db $42
	db $92
	db $E4
	db $12
	db $42
	db $92
	db $FC
	db $E4
	db $21
	db $E3
	db $61
	db $FE, $0F
	db $FF

Mus20C:
	db $D3, $06, $82, $E0
	db $E2
	db $24
	db $E3
	db $24
	db $E2
	db $64
	db $E3
	db $64
	db $E2
	db $94
	db $E3
	db $94
	db $24
	db $E4
	db $24
	db $E2
	db $74
	db $E3
	db $74
	db $E2
	db $B4
	db $E3
	db $B4
	db $E2
	db $94
	db $E3
	db $94
	db $44
	db $E4
	db $44
	db $E3
	db $FC
	db $61
	db $91
	db $FE, $0F
	db $FF

Mus20A:
	db $D3, $00, $91, $20, $89, $23, $B0
	db $EF, $01
	db $E2
	db $62
	db $E1
	db $92
	db $E2
	db $22
	db $62
	db $92
	db $22
	db $62
	db $92
	db $E3
	db $22
	db $E2
	db $62
	db $92
	db $E3
	db $22
	db $62
	db $E2
	db $92
	db $E3
	db $22
	db $62
	db $E2
	db $72
	db $E1
	db $B2
	db $E2
	db $22
	db $72
	db $B2
	db $22
	db $72
	db $B2
	db $E3
	db $12
	db $E2
	db $12
	db $42
	db $92
	db $E3
	db $22
	db $42
	db $92
	db $E4
	db $12
	db $E3
	db $FC
	db $91
	db $21
	db $FE, $0F
	db $FF

Mus21B:
	db $EC, $00
	db $FB
	db $D3, $11, $F2, $20, $8B, $34, $B0
	db $C8
	db $E3
	db $58
	db $24
	db $C4
	db $C8
	db $18
	db $24
	db $C4
	db $C8
	db $38
	db $04
	db $C4
	db $C8
	db $E2
	db $B8
	db $E3
	db $04
	db $C4
	db $F6, $0C
	db $EE, $8C, $54, $A3
	db $22
	db $12
	db $22
	db $54
	db $E2
	db $A2
	db $E3
	db $76
	db $C4
	db $F6, $03
	db $EE, $8B, $34, $B0
	db $C0
	db $98
	db $54
	db $C4
	db $C8
	db $48
	db $54
	db $C4
	db $C8
	db $E4
	db $08
	db $E3
	db $94
	db $C4
	db $C8
	db $88
	db $94
	db $C4
	db $F6, $06
	db $EE, $8C, $54, $A3
	db $A4
	db $54
	db $24
	db $74
	db $34
	db $74
	db $94
	db $A4
	db $E4
	db $04
	db $E3
	db $9C
	db $F6, $03
	db $EE, $8B, $34, $B0
	db $C8
	db $74
	db $C4
	db $74
	db $C4
	db $A1
	db $97
	db $74
	db $C4
	db $94
	db $C4
	db $A8
	db $98
	db $78
	db $5C
	db $C4
	db $28
	db $38
	db $08
	db $28
	db $38
	db $78
	db $A8
	db $98
	db $E4
	db $08
	db $E3
	db $A8
	db $98
	db $54
	db $CC
	db $F6, $06
	db $EE, $8C, $54, $A3
	db $78
	db $A4
	db $9C
	db $A8
	db $E4
	db $24
	db $0C
	db $FD, $00

Mus21C:
	db $D3, $06, $82, $92
	db $EC, $00
	db $FB
	db $F7
	dw Mus21C_1
	db $FC
	db $E2
	db $08
	db $E3
	db $32
	db $C6
	db $32
	db $C6
	db $FE, $01
	db $F7
	dw Mus21C_1
	db $F7
	dw Mus21C_2
	db $E2
	db $38
	db $E3
	db $72
	db $C6
	db $72
	db $A2
	db $E4
	db $32
	db $72
	db $FC
	db $E2
	db $58
	db $E3
	db $52
	db $C6
	db $52
	db $C6
	db $FE, $01
	db $F7
	dw Mus21C_2
	db $F7
	dw Mus21C_2
	db $E2
	db $28
	db $E3
	db $22
	db $C6
	db $22
	db $C6
	db $F7
	dw Mus21C_2
	db $E2
	db $58
	db $E3
	db $52
	db $C6
	db $52
	db $C6
	db $E2
	db $94
	db $84
	db $94
	db $74
	db $54
	db $44
	db $F7
	dw Mus21C_2
	db $F7
	dw Mus21C_2
	db $E2
	db $28
	db $E3
	db $52
	db $C6
	db $52
	db $C6
	db $E2
	db $28
	db $E3
	db $22
	db $52
	db $A2
	db $E4
	db $22
	db $E3
	db $A2
	db $E4
	db $22
	db $52
	db $A2
	db $E2
	db $04
	db $74
	db $E3
	db $02
	db $C6
	db $02
	db $C6
	db $E2
	db $04
	db $74
	db $E3
	db $32
	db $C6
	db $32
	db $C6
	db $FC
	db $E2
	db $54
	db $E3
	db $04
	db $52
	db $C6
	db $92
	db $C6
	db $FE, $01
	db $E2
	db $38
	db $E3
	db $72
	db $C6
	db $72
	db $C6
	db $E2
	db $58
	db $E3
	db $92
	db $C6
	db $92
	db $C6
	db $E2
	db $78
	db $E3
	db $A2
	db $C6
	db $A2
	db $C6
	db $54
	db $E4
	db $04
	db $E3
	db $04
	db $54
	db $E2
	db $54
	db $04
	db $FD, $00

Mus21C_1:
	db $FC
	db $E1
	db $A8
	db $E3
	db $22
	db $C6
	db $22
	db $C6
	db $FE, $01
	db $F9

Mus21C_2:
	db $E2
	db $38
	db $E3
	db $32
	db $C6
	db $32
	db $C6
	db $F9

Mus21A:
	db $D3, $11, $91, $20, $89, $23, $B2
	db $EC, $00
	db $FB
	db $F7
	dw Mus21A_1
	db $C4
	db $E1
	db $74
	db $E2
	db $A2
	db $C6
	db $A4
	db $E4
	db $54
	db $C4
	db $E1
	db $74
	db $E2
	db $92
	db $C6
	db $94
	db $E4
	db $54
	db $F7
	dw Mus21A_1
	db $C4
	db $E1
	db $A4
	db $E2
	db $A2
	db $C6
	db $A4
	db $E4
	db $34
	db $C4
	db $E1
	db $A4
	db $E3
	db $32
	db $C6
	db $A2
	db $E4
	db $32
	db $72
	db $A2
	db $94
	db $E2
	db $04
	db $E3
	db $02
	db $C6
	db $04
	db $E4
	db $54
	db $FC
	db $C4
	db $E2
	db $04
	db $E3
	db $02
	db $C6
	db $04
	db $E4
	db $54
	db $FE, $02
	db $C4
	db $E1
	db $A4
	db $E2
	db $A2
	db $C6
	db $A4
	db $E4
	db $54
	db $C4
	db $E1
	db $A4
	db $E2
	db $A2
	db $C6
	db $A4
	db $E4
	db $34
	db $C4
	db $E2
	db $04
	db $E3
	db $02
	db $C6
	db $04
	db $E4
	db $54
	db $E3
	db $04
	db $E2
	db $B4
	db $E3
	db $04
	db $E2
	db $A4
	db $92
	db $E4
	db $02
	db $52
	db $92
	db $A2
	db $E3
	db $A2
	db $E1
	db $A4
	db $E2
	db $A4
	db $74
	db $A4
	db $E3
	db $34
	db $C4
	db $E2
	db $04
	db $E3
	db $02
	db $C6
	db $02
	db $E4
	db $52
	db $02
	db $92
	db $C4
	db $E1
	db $A4
	db $E3
	db $22
	db $C6
	db $22
	db $C6
	db $C4
	db $E1
	db $A4
	db $E2
	db $A2
	db $E3
	db $22
	db $52
	db $A2
	db $52
	db $A2
	db $E4
	db $22
	db $52
	db $E3
	db $74
	db $E4
	db $74
	db $E3
	db $34
	db $E4
	db $34
	db $E3
	db $54
	db $E4
	db $54
	db $E3
	db $74
	db $E4
	db $74
	db $E3
	db $02
	db $C6
	db $04
	db $E5
	db $04
	db $E4
	db $54
	db $E3
	db $04
	db $E4
	db $94
	db $E3
	db $54
	db $E4
	db $74
	db $E3
	db $34
	db $52
	db $E2
	db $96
	db $E4
	db $92
	db $52
	db $02
	db $E3
	db $92
	db $E4
	db $52
	db $02
	db $E3
	db $92
	db $52
	db $C4
	db $E1
	db $A4
	db $E3
	db $32
	db $C6
	db $32
	db $A2
	db $E4
	db $32
	db $72
	db $C4
	db $E2
	db $04
	db $E3
	db $52
	db $C6
	db $54
	db $E5
	db $04
	db $C4
	db $E2
	db $24
	db $E3
	db $72
	db $C6
	db $72
	db $E4
	db $22
	db $72
	db $A2
	db $E5
	db $02
	db $E4
	db $02
	db $92
	db $E3
	db $92
	db $E4
	db $52
	db $E3
	db $52
	db $E4
	db $02
	db $E3
	db $02
	db $92
	db $E2
	db $92
	db $E3
	db $52
	db $E2
	db $52
	db $FD, $00

Mus21A_1:
	db $FC
	db $C4
	db $E1
	db $54
	db $E2
	db $A2
	db $C6
	db $A4
	db $E4
	db $54
	db $FE, $01
	db $F9

Mus22B:
	db $D4, $11, $C2, $20, $8B, $56, $B0
	db $FB
	db $E3
	db $70
	db $C4
	db $44
	db $74
	db $E4
	db $04
	db $E3
	db $B4
	db $E4
	db $04
	db $E3
	db $B4
	db $94
	db $74
	db $04
	db $44
	db $74
	db $90
	db $C4
	db $04
	db $54
	db $94
	db $E4
	db $24
	db $04
	db $E3
	db $B4
	db $94
	db $B4
	db $E4
	db $04
	db $44
	db $E3
	db $94
	db $B4
	db $E4
	db $04
	db $24
	db $E3
	db $B4
	db $E4
	db $04
	db $E3
	db $94
	db $44
	db $74
	db $54
	db $74
	db $94
	db $E4
	db $24
	db $04
	db $E3
	db $B4
	db $94
	db $B4
	db $FD, $00

Mus22C:
	db $FB
	db $D1, $06, $82, $F0
	db $E2
	db $08
	db $C2
	db $09
	db $C2
	db $09
	db $C2
	db $D4, $06, $82, $F0
	db $03
	db $C1
	db $03
	db $C1
	db $FC
	db $01
	db $41
	db $FE, $06
	db $C2
	db $FC
	db $01
	db $41
	db $FE, $06
	db $C2
	db $FC
	db $01
	db $41
	db $FE, $06
	db $C2
	db $D1, $06, $82, $F0
	db $08
	db $C2
	db $09
	db $C2
	db $09
	db $C2
	db $D4, $06, $82, $F0
	db $03
	db $C1
	db $03
	db $C1
	db $FC
	db $01
	db $51
	db $FE, $06
	db $C2
	db $FC
	db $01
	db $51
	db $FE, $06
	db $C2
	db $FC
	db $01
	db $51
	db $FE, $06
	db $C2
	db $24
	db $44
	db $54
	db $24
	db $44
	db $04
	db $E1
	db $94
	db $E2
	db $04
	db $24
	db $44
	db $54
	db $94
	db $FC
	db $71
	db $B1
	db $FE, $07
	db $FD, $00

Mus22A:
	db $FB
	db $D1, $00, $91, $20, $89, $23, $B0
	db $E2
	db $76
	db $C4
	db $77
	db $C4
	db $77
	db $C4
	db $F6, $04
	db $73
	db $C1
	db $73
	db $C1
	db $FC
	db $71
	db $91
	db $FE, $07
	db $E3
	db $22
	db $E2
	db $72
	db $E3
	db $42
	db $E2
	db $72
	db $E3
	db $22
	db $E2
	db $72
	db $E3
	db $02
	db $E2
	db $72
	db $E3
	db $42
	db $E2
	db $42
	db $72
	db $42
	db $E3
	db $02
	db $E2
	db $42
	db $E3
	db $42
	db $E2
	db $42
	db $F6, $01
	db $96
	db $C4
	db $97
	db $C4
	db $97
	db $C4
	db $F6, $04
	db $93
	db $C1
	db $93
	db $C1
	db $FC
	db $91
	db $B1
	db $FE, $07
	db $E3
	db $52
	db $E2
	db $92
	db $E3
	db $42
	db $E2
	db $92
	db $E3
	db $22
	db $E2
	db $92
	db $E3
	db $02
	db $E2
	db $92
	db $E3
	db $22
	db $E2
	db $92
	db $E3
	db $42
	db $E2
	db $92
	db $E3
	db $92
	db $E2
	db $92
	db $E3
	db $52
	db $E2
	db $92
	db $F6, $01
	db $B6
	db $75
	db $75
	db $E3
	db $26
	db $E2
	db $B5
	db $75
	db $B6
	db $75
	db $75
	db $E3
	db $26
	db $E2
	db $B5
	db $75
	db $E3
	db $06
	db $E2
	db $95
	db $E3
	db $05
	db $46
	db $05
	db $E2
	db $95
	db $E3
	db $06
	db $E2
	db $95
	db $E3
	db $05
	db $46
	db $05
	db $E2
	db $95
	db $F6, $04
	db $E2
	db $92
	db $52
	db $B2
	db $72
	db $E3
	db $02
	db $E2
	db $92
	db $E3
	db $52
	db $22
	db $FC
	db $71
	db $21
	db $FE, $07
	db $FD, $00

Mus22D:
	db $FB
	db $FC
	db $D1
	db $3A
	db $3B
	db $3B
	db $D4
	db $34
	db $34
	db $34
	db $34
	db $C4
	db $34
	db $38
	db $C4
	db $32
	db $32
	db $38
	db $C4
	db $32
	db $32
	db $FE, $01
	db $38
	db $C4
	db $32
	db $32
	db $38
	db $C4
	db $32
	db $32
	db $38
	db $38
	db $38
	db $34
	db $32
	db $32
	db $FD, $00

Mus23B:
	db $FB
	db $D1, $12, $B2, $20, $81, $23, $B2
	db $E3
	db $7B
	db $6B
	db $7A
	db $4B
	db $3B
	db $4A
	db $E4
	db $0B
	db $E3
	db $BB
	db $E4
	db $0A
	db $E3
	db $7B
	db $6B
	db $7A
	db $9B
	db $8B
	db $9A
	db $8B
	db $9B
	db $8A
	db $90
	db $C0
	db $C0
	db $C0
	db $BB
	db $AB
	db $BA
	db $7B
	db $6B
	db $7A
	db $E4
	db $2B
	db $1B
	db $2A
	db $E3
	db $BB
	db $AB
	db $BA
	db $9B
	db $8B
	db $9A
	db $BB
	db $E4
	db $0B
	db $1A
	db $20
	db $C0
	db $E3
	db $74
	db $E4
	db $74
	db $E3
	db $74
	db $E4
	db $74
	db $E3
	db $74
	db $E4
	db $74
	db $C8
	db $E3
	db $7B
	db $6B
	db $7A
	db $4B
	db $3B
	db $4A
	db $E4
	db $08
	db $E3
	db $B8
	db $98
	db $78
	db $58
	db $48
	db $28
	db $08
	db $9B
	db $8B
	db $9A
	db $5B
	db $4B
	db $5A
	db $9B
	db $AB
	db $BA
	db $E4
	db $00
	db $C0
	db $2B
	db $1B
	db $2A
	db $E3
	db $BB
	db $AB
	db $BA
	db $E4
	db $78
	db $68
	db $58
	db $48
	db $28
	db $E3
	db $B8
	db $78
	db $B8
	db $E4
	db $0B
	db $E3
	db $6B
	db $7A
	db $3B
	db $4B
	db $E2
	db $BA
	db $98
	db $B8
	db $E3
	db $08
	db $18
	db $28
	db $48
	db $58
	db $68
	db $FD, $00

Mus23C:
	db $D1, $06, $82, $86
	db $FB
	db $F7
	dw Mus23C_1
	db $FC
	db $E1
	db $50
	db $C6
	db $E2
	db $0A
	db $50
	db $C6
	db $0A
	db $FE, $01
	db $F7
	dw Mus23C_2
	db $E1
	db $20
	db $C6
	db $9A
	db $E2
	db $60
	db $C6
	db $E1
	db $9A
	db $D1, $06, $82, $E6
	db $7B
	db $6B
	db $7A
	db $BB
	db $AB
	db $BA
	db $D1, $06, $82, $86
	db $F7
	dw Mus23C_1
	db $20
	db $C6
	db $9A
	db $E2
	db $50
	db $C6
	db $E1
	db $9A
	db $20
	db $C6
	db $9A
	db $E2
	db $20
	db $C6
	db $E1
	db $9A
	db $F7
	dw Mus23C_2
	db $E1
	db $00
	db $C6
	db $E2
	db $0A
	db $E1
	db $70
	db $C6
	db $E2
	db $7A
	db $E1
	db $90
	db $C6
	db $E2
	db $9A
	db $E1
	db $B0
	db $C6
	db $E2
	db $BA
	db $FD, $00

Mus23C_1:
	db $E1
	db $00
	db $C6
	db $7A
	db $E2
	db $00
	db $C6
	db $E1
	db $7A
	db $E1
	db $00
	db $C6
	db $7A
	db $E2
	db $40
	db $C6
	db $E1
	db $7A
	db $F9

Mus23C_2:
	db $E1
	db $70
	db $C6
	db $E2
	db $2A
	db $70
	db $C6
	db $2A
	db $E1
	db $70
	db $C6
	db $E2
	db $2A
	db $B0
	db $C6
	db $2A
	db $F9

Mus23A:
	db $FB
	db $D4, $00, $C1, $20, $89, $23, $B0
	db $E2
	db $C8
	db $48
	db $C8
	db $78
	db $C8
	db $98
	db $C8
	db $92
	db $E3
	db $02
	db $52
	db $92
	db $C8
	db $E2
	db $B8
	db $C8
	db $E3
	db $28
	db $C8
	db $E2
	db $98
	db $F6, $01
	db $BB
	db $AB
	db $BA
	db $7B
	db $6B
	db $7A
	db $F6, $04
	db $C8
	db $48
	db $C8
	db $78
	db $C8
	db $98
	db $F6, $01
	db $5B
	db $7B
	db $8A
	db $9B
	db $BB
	db $E3
	db $0A
	db $F6, $04
	db $C8
	db $E2
	db $B8
	db $C8
	db $E3
	db $28
	db $03
	db $E2
	db $73
	db $42
	db $B3
	db $73
	db $22
	db $52
	db $72
	db $92
	db $A2
	db $B2
	db $E3
	db $02
	db $12
	db $22
	db $FD, $00

Mus24B:
	db $D7, $11, $B2, $52, $8B, $34, $B0
	db $EC, $05
	db $EE, $8C, $C7, $C2
	db $FB
	db $E3
	db $3C
	db $2C
	db $0C
	db $2C
	db $3C
	db $58
	db $74
	db $5C
	db $CC
	db $7C
	db $88
	db $A4
	db $E4
	db $0C
	db $E3
	db $3C
	db $2C
	db $3C
	db $5C
	db $7C
	db $FD, $00

Mus24C:
	db $D7, $06, $82, $C5
	db $EC, $05
	db $FB
	db $FC
	db $E1
	db $34
	db $74
	db $A4
	db $FE, $05
	db $24
	db $54
	db $A4
	db $24
	db $54
	db $A4
	db $14
	db $74
	db $A4
	db $14
	db $74
	db $A4
	db $04
	db $34
	db $84
	db $04
	db $34
	db $84
	db $FC
	db $E0
	db $A4
	db $E1
	db $54
	db $84
	db $FE, $02
	db $E3
	db $21
	db $E4
	db $21
	db $E2
	db $A1
	db $E3
	db $A1
	db $E2
	db $51
	db $E3
	db $51
	db $E2
	db $21
	db $E3
	db $21
	db $E1
	db $A1
	db $E2
	db $A1
	db $E1
	db $51
	db $E2
	db $51
	db $FD, $00

Mus24A:
	db $D7, $22, $91, $20, $89, $23, $B0
	db $EC, $05
	db $FB
	db $E4
	db $32
	db $F7
	dw Mus24A_1
	db $E4
	db $22
	db $F7
	dw Mus24A_1
	db $E4
	db $02
	db $F7
	dw Mus24A_1
	db $E4
	db $22
	db $F7
	dw Mus24A_1
	db $E4
	db $32
	db $F7
	dw Mus24A_1
	db $E4
	db $52
	db $F7
	dw Mus24A_1
	db $E4
	db $52
	db $F7
	dw Mus24A_2
	db $E3
	db $A2
	db $F7
	dw Mus24A_2
	db $E4
	db $72
	db $F7
	dw Mus24A_1
	db $E4
	db $82
	db $F7
	dw Mus24A_1
	db $E5
	db $02
	db $F7
	dw Mus24A_3
	db $E4
	db $32
	db $F7
	dw Mus24A_3
	db $E4
	db $22
	db $F7
	dw Mus24A_2
	db $E4
	db $32
	db $F7
	dw Mus24A_2
	db $E4
	db $52
	db $F7
	dw Mus24A_2
	db $E4
	db $A2
	db $52
	db $22
	db $E2
	db $A2
	db $52
	db $22
	db $FD, $00

Mus24A_1:
	db $E1
	db $72
	db $A2
	db $E2
	db $32
	db $72
	db $A2
	db $F9

Mus24A_2:
	db $E1
	db $52
	db $A2
	db $E2
	db $22
	db $52
	db $A2
	db $F9

Mus24A_3:
	db $E1
	db $82
	db $E2
	db $02
	db $32
	db $82
	db $E3
	db $02
	db $F9

SECTION "Audio RAM", WRAM0[AudioRAM]

MusC1MusNum: ds 1		;$C700 = $00
MusC1Priority: ds 1		;$C701 = $01
MusC1Sweep: ds 1		;$C702 = $02
MusC1Transpose: ds 1		;$C703 = $03
MusC1Tuning: ds 1		;$C704 = $04
MusC1VolFinal: ds 1		;$C705 = $05
MusC1VolOutput: ds 1		;$C706 = $06
MusC1NoteDelay: ds 1		;$C707 = $07
MusC1NoteTime: ds 1		;$C708 = $08
MusC1EnvOn: ds 1		;$C709 = $09
MusC1EnvTime: ds 1		;$C70A = $0A
MusC1Speed: ds 1		;$C70B = $0B
MusC1DutyVol: ds 1		;$C70C = $0C
MusC1Decay: ds 1		;$C70D = $0D
MusC1EnvLen: ds 1		;$C70E = $0E
MusC1Vibrato: ds 2		;$C70F = $0F
MusC1EnvVal: ds 1		;$C711 = $11
MusC1Decay2: ds 1		;$C712 = $12
MusC1Decay3: ds 1		;$C713 = $13
MusC1EnvSeqPtr: ds 2		;$C714 = $14
MusC1VibStep: ds 1		;$C716 = $16
MusC1EnvSeqPos: ds 1		;$C717 = $17
MusC1EnvStep: ds 1		;$C718 = $18
MusC1VibSeqDelay: ds 1		;$C719 = $19
MusC1EnvDur: ds 1		;$C71A = $1A
MusC1Octave: ds 1		;$C71B = $1B
MusC1VibVal: ds 1		;$C71C = $1C
MusC1Freq: ds 2		;$C71D = $1D
MusC1VolCur: ds 1		;$C71F = $1F
MusC1SongPos: ds 2		;$C720 = $20
MusC1Repeat1Start: ds 2		;$C722 = $22
MusC1Repeat2Start: ds 2		;$C724 = $24
MusC1Macro1Pos: ds 2		;$C726 = $26
MusC1Macro2Pos: ds 2		;$C728 = $28
MusC1Repeat1Times: ds 1		;$C72A = $2A
MusC1Repeat2Times: ds 1		;$C72B = $2B

MusC2MusNum: ds 1		;$C72C = $00
MusC2Priority: ds 1		;$C72D = $01
MusC2Sweep: ds 1		;$C72E = $02
MusC2Transpose: ds 1		;$C72F = $03
MusC2Tuning: ds 1		;$C730 = $04
MusC2VolFinal: ds 1		;$C731 = $05
MusC2VolOutput: ds 1		;$C732 = $06
MusC2NoteDelay: ds 1		;$C733 = $07
MusC2NoteTime: ds 1		;$C734 = $08
MusC2EnvOn: ds 1		;$C735 = $09
MusC2EnvTime: ds 1		;$C736 = $0A
MusC2Speed: ds 1		;$C737 = $0B
MusC2DutyVol: ds 1		;$C738 = $0C
MusC2Decay: ds 1		;$C739 = $0D
MusC2EnvLen: ds 1		;$C73A = $0E
MusC2Vibrato: ds 2		;$C73B = $0F
MusC2EnvVal: ds 1		;$C73D = $11
MusC2Decay2: ds 1		;$C73E = $12
MusC2Decay3: ds 1		;$C73F = $13
MusC2EnvSeqPtr: ds 2		;$C740 = $14
MusC2VibStep: ds 1		;$C742 = $16
MusC2EnvSeqPos: ds 1		;$C743 = $17
MusC2EnvStep: ds 1		;$C744 = $18
MusC2VibSeqDelay: ds 1		;$C745 = $19
MusC2EnvDur: ds 1		;$C746 = $1A
MusC2Octave: ds 1		;$C747 = $1B
MusC2VibVal: ds 1		;$C748 = $1C
MusC2Freq: ds 2		;$C749 = $1D
MusC2VolCur: ds 1		;$C74B = $1F
MusC2SongPos: ds 2		;$C74C = $20
MusC2Repeat1Start: ds 2		;$C74E = $22
MusC2Repeat2Start: ds 2		;$C750 = $24
MusC2Macro1Pos: ds 2		;$C752 = $26
MusC2Macro2Pos: ds 2		;$C754 = $28
MusC2Repeat1Times: ds 1		;$C756 = $2A
MusC2Repeat2Times: ds 1		;$C757 = $2B

MusC3MusNum: ds 1		;$C758 = $00
MusC3Priority: ds 1		;$C759 = $01
MusC3Sweep: ds 1		;$C75A = $02
MusC3Transpose: ds 1		;$C75B = $03
MusC3Tuning: ds 1		;$C75C = $04
MusC3VolFinal: ds 1		;$C75D = $05
MusC3VolOutput: ds 1		;$C75E = $06
MusC3NoteDelay: ds 1		;$C75F = $07
MusC3NoteTime: ds 1		;$C760 = $08
MusC3EnvOn: ds 1		;$C761 = $09
MusC3EnvTime: ds 1		;$C762 = $0A
MusC3Speed: ds 1		;$C763 = $0B
MusC3DutyVol: ds 1		;$C764 = $0C
MusC3Decay: ds 1		;$C765 = $0D
MusC3EnvLen: ds 1		;$C766 = $0E
MusC3Vibrato: ds 2		;$C767 = $0F
MusC3EnvVal: ds 1		;$C769 = $11
MusC3Decay2: ds 1		;$C76A = $12
MusC3Decay3: ds 1		;$C76B = $13
MusC3EnvSeqPtr: ds 2		;$C76C = $14
MusC3VibStep: ds 1		;$C76E = $16
MusC3EnvSeqPos: ds 1		;$C76F = $17
MusC3EnvStep: ds 1		;$C770 = $18
MusC3VibSeqDelay: ds 1		;$C771 = $19
MusC3EnvDur: ds 1		;$C772 = $1A
MusC3Octave: ds 1		;$C773 = $1B
MusC3VibVal: ds 1		;$C774 = $1C
MusC3Freq: ds 2		;$C775 = $1D
MusC3VolCur: ds 1		;$C777 = $1F
MusC3SongPos: ds 2		;$C778 = $20
MusC3Repeat1Start: ds 2		;$C77A = $22
MusC3Repeat2Start: ds 2		;$C77C = $24
MusC3Macro1Pos: ds 2		;$C77E = $26
MusC3Macro2Pos: ds 2		;$C780 = $28
MusC3Repeat1Times: ds 1		;$C782 = $2A
MusC3Repeat2Times: ds 1		;$C783 = $2B

MusC4MusNum: ds 1		;$C784 = $00
MusC4Priority: ds 1		;$C785 = $01
MusC4Sweep: ds 1		;$C786 = $02
MusC4Transpose: ds 1		;$C787 = $03
MusC4Tuning: ds 1		;$C788 = $04
MusC4VolFinal: ds 1		;$C789 = $05
MusC4VolOutput: ds 1		;$C78A = $06
MusC4NoteDelay: ds 1		;$C78B = $07
MusC4NoteTime: ds 1		;$C78C = $08
MusC4EnvOn: ds 1		;$C78D = $09
MusC4EnvTime: ds 1		;$C78E = $0A
MusC4Speed: ds 1		;$C78F = $0B
MusC4DutyVol: ds 1		;$C790 = $0C
MusC4Decay: ds 1		;$C791 = $0D
MusC4EnvLen: ds 1		;$C792 = $0E
MusC4Vibrato: ds 2		;$C793 = $0F
MusC4EnvVal: ds 1		;$C795 = $11
MusC4Decay2: ds 1		;$C796 = $12
MusC4Decay3: ds 1		;$C797 = $13
MusC4EnvSeqPtr: ds 2		;$C798 = $14
MusC4VibStep: ds 1		;$C79A = $16
MusC4EnvSeqPos: ds 1		;$C79B = $17
MusC4EnvStep: ds 1		;$C79C = $18
MusC4VibSeqDelay: ds 1		;$C79D = $19
MusC4EnvDur: ds 1		;$C79E = $1A
MusC4Octave: ds 1		;$C79F = $1B
MusC4VibVal: ds 1		;$C7A0 = $1C
MusC4Freq: ds 2		;$C7A1 = $1D
MusC4VolCur: ds 1		;$C7A3 = $1F
MusC4SongPos: ds 2		;$C7A4 = $20
MusC4Repeat1Start: ds 2		;$C7A6 = $22
MusC4Repeat2Start: ds 2		;$C7A8 = $24
MusC4Macro1Pos: ds 2		;$C7AA = $26
MusC4Macro2Pos: ds 2		;$C7AC = $28
MusC4Repeat1Times: ds 1		;$C7AE = $2A
MusC4Repeat2Times: ds 1		;$C7AF = $2B

SFXC1MusNum: ds 1		;$C7B0 = $00
SFXC1Priority: ds 1		;$C7B1 = $01
SFXC1Sweep: ds 1		;$C7B2 = $02
SFXC1Transpose: ds 1		;$C7B3 = $03
SFXC1Tuning: ds 1		;$C7B4 = $04
SFXC1VolFinal: ds 1		;$C7B5 = $05
SFXC1VolOutput: ds 1		;$C7B6 = $06
SFXC1NoteDelay: ds 1		;$C7B7 = $07
SFXC1NoteTime: ds 1		;$C7B8 = $08
SFXC1EnvOn: ds 1		;$C7B9 = $09
SFXC1EnvTime: ds 1		;$C7BA = $0A
SFXC1Speed: ds 1		;$C7BB = $0B
SFXC1DutyVol: ds 1		;$C7BC = $0C
SFXC1Decay: ds 1		;$C7BD = $0D
SFXC1EnvLen: ds 1		;$C7BE = $0E
SFXC1Vibrato: ds 2		;$C7BF = $0F
SFXC1EnvVal: ds 1		;$C7C1 = $11
SFXC1Decay2: ds 1		;$C7C2 = $12
SFXC1Decay3: ds 1		;$C7C3 = $13
SFXC1EnvSeqPtr: ds 2		;$C7C4 = $14
SFXC1VibStep: ds 1		;$C7C6 = $16
SFXC1EnvSeqPos: ds 1		;$C7C7 = $17
SFXC1EnvStep: ds 1		;$C7C8 = $18
SFXC1VibSeqDelay: ds 1		;$C7C9 = $19
SFXC1EnvDur: ds 1		;$C7CA = $1A
SFXC1Octave: ds 1		;$C7CB = $1B
SFXC1VibVal: ds 1		;$C7CC = $1C
SFXC1Freq: ds 2		;$C7CD = $1D
SFXC1VolCur: ds 1		;$C7CF = $1F
SFXC1SongPos: ds 2		;$C7D0 = $20
SFXC1Repeat1Start: ds 2		;$C7D2 = $22
SFXC1Repeat2Start: ds 2		;$C7D4 = $24
SFXC1Macro1Pos: ds 2		;$C7D6 = $26
SFXC1Macro2Pos: ds 2		;$C7D8 = $28
SFXC1Repeat1Times: ds 1		;$C7DA = $2A
SFXC1Repeat2Times: ds 1		;$C7DB = $2B

SFXC2MusNum: ds 1		;$C7DC = $00
SFXC2Priority: ds 1		;$C7DD = $01
SFXC2Sweep: ds 1		;$C7DE = $02
SFXC2Transpose: ds 1		;$C7DF = $03
SFXC2Tuning: ds 1		;$C7E0 = $04
SFXC2VolFinal: ds 1		;$C7E1 = $05
SFXC2VolOutput: ds 1		;$C7E2 = $06
SFXC2NoteDelay: ds 1		;$C7E3 = $07
SFXC2NoteTime: ds 1		;$C7E4 = $08
SFXC2EnvOn: ds 1		;$C7E5 = $09
SFXC2EnvTime: ds 1		;$C7E6 = $0A
SFXC2Speed: ds 1		;$C7E7 = $0B
SFXC2DutyVol: ds 1		;$C7E8 = $0C
SFXC2Decay: ds 1		;$C7E9 = $0D
SFXC2EnvLen: ds 1		;$C7EA = $0E
SFXC2Vibrato: ds 2		;$C7EB = $0F
SFXC2EnvVal: ds 1		;$C7ED = $11
SFXC2Decay2: ds 1		;$C7EE = $12
SFXC2Decay3: ds 1		;$C7EF = $13
SFXC2EnvSeqPtr: ds 2		;$C7F0 = $14
SFXC2VibStep: ds 1		;$C7F2 = $16
SFXC2EnvSeqPos: ds 1		;$C7F3 = $17
SFXC2EnvStep: ds 1		;$C7F4 = $18
SFXC2VibSeqDelay: ds 1		;$C7F5 = $19
SFXC2EnvDur: ds 1		;$C7F6 = $1A
SFXC2Octave: ds 1		;$C7F7 = $1B
SFXC2VibVal: ds 1		;$C7F8 = $1C
SFXC2Freq: ds 2		;$C7F9 = $1D
SFXC2VolCur: ds 1		;$C7FB = $1F
SFXC2SongPos: ds 2		;$C7FC = $20
SFXC2Repeat1Start: ds 2		;$C7FE = $22
SFXC2Repeat2Start: ds 2		;$C800 = $24
SFXC2Macro1Pos: ds 2		;$C802 = $26
SFXC2Macro2Pos: ds 2		;$C804 = $28
SFXC2Repeat1Times: ds 1		;$C806 = $2A
SFXC2Repeat2Times: ds 1		;$C807 = $2B

SFXC3MusNum: ds 1		;$C808 = $00
SFXC3Priority: ds 1		;$C809 = $01
SFXC3Sweep: ds 1		;$C80A = $02
SFXC3Transpose: ds 1		;$C80B = $03
SFXC3Tuning: ds 1		;$C80C = $04
SFXC3VolFinal: ds 1		;$C80D = $05
SFXC3VolOutput: ds 1		;$C80E = $06
SFXC3NoteDelay: ds 1		;$C80F = $07
SFXC3NoteTime: ds 1		;$C810 = $08
SFXC3EnvOn: ds 1		;$C811 = $09
SFXC3EnvTime: ds 1		;$C812 = $0A
SFXC3Speed: ds 1		;$C813 = $0B
SFXC3DutyVol: ds 1		;$C814 = $0C
SFXC3Decay: ds 1		;$C815 = $0D
SFXC3EnvLen: ds 1		;$C816 = $0E
SFXC3Vibrato: ds 2		;$C817 = $0F
SFXC3EnvVal: ds 1		;$C819 = $11
SFXC3Decay2: ds 1		;$C81A = $12
SFXC3Decay3: ds 1		;$C81B = $13
SFXC3EnvSeqPtr: ds 2		;$C81C = $14
SFXC3VibStep: ds 1		;$C81E = $16
SFXC3EnvSeqPos: ds 1		;$C81F = $17
SFXC3EnvStep: ds 1		;$C820 = $18
SFXC3VibSeqDelay: ds 1		;$C821 = $19
SFXC3EnvDur: ds 1		;$C822 = $1A
SFXC3Octave: ds 1		;$C823 = $1B
SFXC3VibVal: ds 1		;$C824 = $1C
SFXC3Freq: ds 2		;$C825 = $1D
SFXC3VolCur: ds 1		;$C827 = $1F
SFXC3SongPos: ds 2		;$C828 = $20
SFXC3Repeat1Start: ds 2		;$C82A = $22
SFXC3Repeat2Start: ds 2		;$C82C = $24
SFXC3Macro1Pos: ds 2		;$C82E = $26
SFXC3Macro2Pos: ds 2		;$C830 = $28
SFXC3Repeat1Times: ds 1		;$C832 = $2A
SFXC3Repeat2Times: ds 1		;$C833 = $2B

SFXC4MusNum: ds 1		;$C834 = $00
SFXC4Priority: ds 1		;$C835 = $01
SFXC4Sweep: ds 1		;$C836 = $02
SFXC4Transpose: ds 1		;$C837 = $03
SFXC4Tuning: ds 1		;$C838 = $04
SFXC4VolFinal: ds 1		;$C839 = $05
SFXC4VolOutput: ds 1		;$C83A = $06
SFXC4NoteDelay: ds 1		;$C83B = $07
SFXC4NoteTime: ds 1		;$C83C = $08
SFXC4EnvOn: ds 1		;$C83D = $09
SFXC4EnvTime: ds 1		;$C83E = $0A
SFXC4Speed: ds 1		;$C83F = $0B
SFXC4DutyVol: ds 1		;$C840 = $0C
SFXC4Decay: ds 1		;$C841 = $0D
SFXC4EnvLen: ds 1		;$C842 = $0E
SFXC4Vibrato: ds 2		;$C843 = $0F
SFXC4EnvVal: ds 1		;$C845 = $11
SFXC4Decay2: ds 1		;$C846 = $12
SFXC4Decay3: ds 1		;$C847 = $13
SFXC4EnvSeqPtr: ds 2		;$C848 = $14
SFXC4VibStep: ds 1		;$C84A = $16
SFXC4EnvSeqPos: ds 1		;$C84B = $17
SFXC4EnvStep: ds 1		;$C84C = $18
SFXC4VibSeqDelay: ds 1		;$C84D = $19
SFXC4EnvDur: ds 1		;$C84E = $1A
SFXC4Octave: ds 1		;$C84F = $1B
SFXC4VibVal: ds 1		;$C850 = $1C
SFXC4Freq: ds 2		;$C851 = $1D
SFXC4VolCur: ds 1		;$C853 = $1F
SFXC4SongPos: ds 2		;$C854 = $20
SFXC4Repeat1Start: ds 2		;$C856 = $22
SFXC4Repeat2Start: ds 2		;$C858 = $24
SFXC4Macro1Pos: ds 2		;$C85A = $26
SFXC4Macro2Pos: ds 2		;$C85C = $28
SFXC4Repeat1Times: ds 1		;$C85E = $2A
SFXC4Repeat2Times: ds 1		;$C85F = $2B

NR10Val: ds 1			;$C860
NR11Val: ds 1			;$C861
NR12Val: ds 1			;$C862
NR13Val: ds 1			;$C863
NR14Val: ds 1			;$C864
NR21Val: ds 1			;$C865
NR22Val: ds 1			;$C866
NR23Val: ds 1			;$C867
NR24Val: ds 1			;$C868
NR30Val: ds 1			;$C869
NR31Val: ds 1			;$C86A
NR32Val: ds 1			;$C86B
NR33Val: ds 1			;$C86C
NR34Val: ds 1			;$C86D
NR41Val: ds 1			;$C86E
NR42Val: ds 1			;$C86F
NR43Val: ds 1			;$C870
NR44Val: ds 1			;$C871
NR50Val: ds 1			;$C872
NR51Val: ds 1			;$C873
NR52Val: ds 1			;$C874
NR10ValCopy: ds 1			;$C875
NR11ValCopy: ds 1			;$C876
NR12ValCopy: ds 1			;$C877
NR13ValCopy: ds 1			;$C878
NR14ValCopy: ds 1			;$C879
NR21ValCopy: ds 1			;$C87A
NR22ValCopy: ds 1			;$C87B
NR23ValCopy: ds 1			;$C87C
NR24ValCopy: ds 1			;$C87D
NR30ValCopy: ds 1			;$C87E
NR31ValCopy: ds 1			;$C87F
NR32ValCopy: ds 1			;$C880
NR33ValCopy: ds 1			;$C881
NR34ValCopy: ds 1			;$C882
NR41ValCopy: ds 1			;$C883
NR42ValCopy: ds 1			;$C884
NR43ValCopy: ds 1			;$C885
NR44ValCopy: ds 1			;$C886
NR50ValCopy: ds 1			;$C887
NR51ValCopy: ds 1			;$C888
NR52ValCopy: ds 1			;$C889
Gate1Off: ds 1			;$C88A
Gate2Off: ds 1			;$C88B
Gate3Off: ds 1			;$C88C
Gate4Off: ds 1			;$C88D

ds 18					;$C88E-$C89F (unused)

CurTrack: ds 1			;$C8A0
CurTrackCheck: ds 1			;$C8A1
SFXNum: ds 1			;$C8A2
Temp1: ds 1			;$C8A3
Temp2: ds 1			;$C8A4
Output: ds 1			;$C8A5
WaveformMus: ds 1			;$C8A6
WaveformSFX: ds 1			;$C8A7
NewWave: ds 1			;$C8A8
Fade: ds 1			;$C8A9
FadeTime: ds 1			;$C8AA
MusPlaying: ds 1			;$C8AB
