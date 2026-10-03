;Earthworm Jim audio disassembly
;Original audio & code by Martin Walker
;Disassembly by Will Trowbridge
;Referenced from Martin Walker 1994 sound engine source code.

include "HARDWARE.INC"

def AudioROM equ $4000
def AudioRAM equ $C500
def WaveRAM equ $FF30
def RAMSize equ $E2
def ChanRAMSize equ $3F

SECTION "Audio", ROMX[AudioROM], BANK[$1]

	jp InitSound


	jp IntSound


	jp InVec


;Initialize audio
InitSound:
	ld hl, AudioRAM
	ld bc, RAMSize

;Clear audio variable RAM
ClearRAM:
	ld [hl], 0
	inc hl
	dec bc
	ld a, b
	or c
	jr nz, ClearRAM

	;Calculate addresses from vector table
	call InVec
	ld a, $FF				;Initialize RAM variables
	ld [C1SFX], a
	ld [C2SFX], a
	ld [C3SFX], a
	ld [C1Priority], a
	ld [C2Priority], a
	ld [C3Priority], a
	ld [C1VoiceMute], a
	ld [C2VoiceMute], a
	ld [C3VoiceMute], a
	ld [NoiseChan], a
	ld a, 8
	ld [C1EnvVal+1], a
	ld [C2EnvVal+1], a
	ld [C3EnvVal+1], a
	
	ld a, $FF
	ld [TempoVal], a		;Default tempo = 296 (255)
	
	ld a, %10000000
	ldh [rNR52], a			;Enable audio
	ld a, %00001000
	ldh [rNR10], a			;Channel 1 mode - sweep off
	xor a
	ldh [rNR30], a			;Clear channel 3
	ldh [rNR34], a			;Continuous channel 3
	
	;Clear wave RAM
	ld b, 16
	ld hl, WaveRAM

ClearWave:
	ld [hl+], a
	dec b
	jr nz, ClearWave

	ld bc, $0400			;Set all 4 channels to frequency = 0

;Initialize each channel
InitChans:
	push bc
	call FreqOff
	pop bc
	inc c
	dec b
	jr nz, InitChans

	xor a
	ldh [rNR11], a
	ldh [rNR21], a
	ldh [rNR31], a
	ldh [rNR41], a
	ld a, %00100000
	ldh [rNR32], a			;Set sound 3 output
	ld a, %01110111
	ldh [rNR50], a			;Set master volume
	ld a, %11111111
	ldh [rNR51], a			;Set panning to all
	ld a, %10001111
	ldh [rNR52], a			;Turn on all sound channels
	ret


InVec:
	;Chunk table start address
	ld hl, GameDat1
	;Music data start address
	ld de, GameDat1+14
	ld a, e
	ld [SFXBank], a
	ld a, d
	ld [SFXBank+1], a
	ld bc, SFXTab			;Calculate SFX table address
	call StoreVar			;Calculate voice bank address
	call StoreVar			;Calculate sequence data pointer table
	call StoreVar			;Calculate sequence data start address
	call StoreVar			;Calculate track data pointer table
	call StoreVar			;Calculate track data start address

StoreVar:
	ld a, [hl+]				;Get low byte from vector table
	add e					;Add game data low byte address
	ld e, a					;And save in E
	ld [bc], a				;And save in final offset low byte
	inc bc					;Now move to high byte
	ld a, [hl+]				;Get high byte from vector table
	adc d					;Add game data high byte address
	ld d, a					;DE now holds address of this block
	ld [bc], a				;Save to final offset high byte
	inc bc					;Now move to next destination entry
	ret


;Interrupt routine
IntSound:
	;Check if any new sound effects are requested
	ld a, [SFXNum]
	cp $FF
	;If not, then continue
	jr z, .IntSound2

	;Otherwise, load the sound effect from number
	call SendSFX
	;Then set flag to FF (busy)
	ld a, $FF
	ld [SFXNum], a

.IntSound2
	;Check if any new music is playing
	ld a, [MusNum]
	cp $FF
	;If not, then continue
	jr z, .IntSound3

	;Otherwise, load the music from number
	call SendMus
	;Then set flag to FF (busy)
	ld a, $FF
	ld [MusNum], a

.IntSound3
	call IntSFX
	call IntMusic
	ld de, 0				;Channel 1
	ld a, 0
	call ExeSound
	ld de, ChanRAMSize		;Channel 2
	ld a, 1
	call ExeSound
	ld de, ChanRAMSize*2	;Channel 3
	ld a, 2

ExeSound:
	ld [CurChan], a			;Current channel (1-3)
	call OutSound
	ret


SendSFX:
	ld hl, 0
	ld l, a
	;Get SFX number from A = call number
	add hl, hl
	add hl, hl				;4 bytes for each entry
	ld a, [SFXTab]			;Add value to table
	add l
	ld c, a
	ld a, [SFXTab+1]
	adc h
	ld h, a					;Load pointer into HL
	ld l, c

	ld c, [hl]				;Byte 1 = priority
	inc hl
	ld a, [hl+]				;Byte 2 = channel 1 call
	cp $FF					;FF = unused
	jr z, .SendSFX2

	ld [C1SFX], a			;Load SFX call in RAM
	ld a, c
	ld [C1PriorTest], a		;Also load priority

.SendSFX2
	ld a, [hl+]				;Byte 3 = channel 2 call
	cp $FF
	jr z, .SendSFX3

	ld [C2SFX], a			;Load SFX call in RAM
	ld a, c
	ld [C2PriorTest], a		;Also load priority

.SendSFX3
	ld a, [hl+]				;Byte 4 = channel 3 call
	cp $FF
	jr z, .SendSFX4

	ld [C3SFX], a			;Load SFX call in RAM
	ld a, c
	ld [C3PriorTest], a		;Also load priority

.SendSFX4
	ld a, [Status]			;Check status
	rla
	ret c					;Return if not during music

	;Otherwise, set max volume in stereo channels
	ld a, %01110111			;(After fade, etc.)
	ldh [rNR50], a
	ret


IntSFX:
	xor a				;Channel 1
	ld d, a
	ld e, a
	call CallSFX
	ld a, 1				;Channel 2
	ld de, ChanRAMSize
	call CallSFX
	ld a, 2				;Channel 3
	ld de, ChanRAMSize*2

CallSFX:
	;Load current channel number into RAM
	ld [CurChan], a
	;Set frequency offset to 0
	ld hl, C1FreqOff
	add hl, de
	ld [hl], 0
	
	;Check if SFX is playing on channel
	ld hl, C1SFX
	add hl, de
	bit 7, [hl]
	jr nz, TestMusic	;No call in this channel

	;If so, then load SFX number
	ld a, [hl]
	ld b, a				;New sound effect number saved in B
	
	inc hl
	ld c, [hl]			;C = PriorTest for required effect
	
	;Get current priority
	ld hl, C1Priority
	add hl, de
	ld a, [hl]
	cp c
	jr nc, LoadSFX		;Higher or equal, so accept

	;Save address of current priority
	push hl
	ld hl, C1SFXHold
	add hl, de
	ld a, [hl]
	pop hl
	and a
	jr z, LoadSFX		;$64 (100) frames past

	ld hl, C1SFX
	add hl, de
	ld [hl], $FF		;Otherwise, cancel try

TestMusic:
	;Check if SFX on channel is done playing
	ld hl, C1SFXChop
	add hl, de
	xor a
	cp [hl]
	jr z, .TestAbort	;End of sound (end count reduced to 0)

	push hl
	ld hl, C1VoiceMute
	add hl, de
	cp [hl]				;Compare voice mute flag to 0
	pop hl
	jp nz, TimeSFX		;If not 0, process SFX on channel

	ld [hl], a			;Otherwise, set SFX channel operation flag to 0

.TestAbort				;Force to 0 for sounds < 100 frames
	ld hl, C1SFXHold
	add hl, de
	ld [hl], a
	ret


LoadSFX:
	ld [hl], c			;Save this priority
	ld hl, 0
	ld l, b				;Get SFX number
	add hl, hl			;16 bytes each effect
	add hl, hl
	add hl, hl
	add hl, hl
	ld a, [SFXBank]
	add l
	ld c, a
	ld a, [SFXBank+1]
	adc h
	ld b, a
	
	ld hl, C1EnvAD
	add hl, de
	ld a, [bc]
	ld [hl+], a			;Byte 1 = envelope attack/decay - save (overwrite music)
	
	inc bc
	ld a, [bc]
	ld [hl+], a			;Byte 2 = envelope sustain/release - save (overwrite music)
	
	ld a, $F8
	ld [hl+], a			;Force attack volume to maximum volume
	
	inc bc
	ld a, [bc]
	ld [hl+], a			;Byte 3 = attack count - save to attack hold variable
	
	xor a
	ld [hl+], a			;Set envelope sequence to 0
	inc a
	ld [hl+], a			;Set envelope attack to  1
	ld [hl], 8			;Set frequency offset to 8
	
	ld hl, C1SFXChop
	add hl, de
	inc bc
	ld a, [bc]
	ld [hl-], a			;Byte 4 = suspend/release length - save to SFXChop variable
	
	ld [hl], 200		;Set hold time to 200 frames
	dec hl
	dec hl
	ld [hl], $FF		;Set SFX channel 1 flag to FF (busy)
	
	ld hl, C1AttDec
	add hl, de
	inc bc
	ld a, [bc]
	ld [hl+], a			;Byte 5 = wave attack/decay
	
	inc bc
	ld a, [bc]
	ld [hl+], a			;Byte 6 = wave suspend/release
	
	inc bc
	ld a, [bc]			;Byte 7-8 = start frequency
	inc hl				;Skip freq(lo) destination (load in reverse order)
	ld [hl], a
	inc bc
	ld a, [bc]
	dec hl
	ld [hl+], a
	inc hl
	
	inc bc
	ld a, [bc]
	ld [hl+], a			;Byte 9 = bend type (0-9)
	
	inc bc
	ld a, [bc]			;Byte 10-11 = bend
	inc hl				;Skip bend(lo) destination (load in reverse order)
	ld [hl], a
	inc bc
	ld a, [bc]
	dec hl
	ld [hl+], a
	inc hl
	
	inc bc
	push bc
	push hl
	ld a, [bc]			;Byte 12 = stereo placement/panning (10 = left, 11 = center, 01 = right) 
	and $11				;L/R bits only
	ld hl, C1Pan
	add hl, de
	ld [hl], a			;Save stereo/pan in RAM
	push af
	ld a, [CurChan]		;Stereo/panning (first frame only)
	inc a
	ld c, a				;C = channel (1-3)
	pop af				;Retrieve pan value
	ld b, %11101110
	dec c
	jr z, .LoadSFX2		;Channel 1

	add a
	ld b, %11011101
	dec c
	jr z, .LoadSFX2		;Channel 2

	add a				;Channel 3 (22 to 44)
	ld b, %10111011

.LoadSFX2
	ld c, a				;C = stereo bits
	ldh a, [rNR51]		;Get values from register
	and b				;Mask out this channel
	or c				;Add stereo for this channel
	ldh [rNR51], a
	pop hl
	pop bc
	
	inc bc
	ld a, [bc]
	ld [hl+], a			;Byte 13 = special event
	
	inc bc
	ld a, [bc]
	ld [hl+], a			;Byte 14 = special counter - save to Countdown
	ld [hl+], a			;And to CountVal
	inc bc
	ld a, [bc]
	ld [hl+], a			;Byte 15-16 = special frequency
	inc bc
	ld a, [bc]
	ld [hl+], a
	inc hl				;Skip Priority (RAM value)
	ld [hl], $FF		;Set direction flag to FF
	ret


TimeSFX:
	ld hl, C1SFXHold
	add hl, de
	ld a, [hl]
	and a
	;If hold value is not 0, then decrement
	jr z, .TimeSFX2

	dec [hl]

.TimeSFX2
	;Decrement SFX duration remaining
	ld hl, C1Countdown
	add hl, de
	dec [hl]
	bit 7, [hl]
	jr z, .TimeSFX3

	inc hl				;Increase CountVal
	ld a, [hl-]
	ld [hl+], a			;Set "new value" flag
	inc hl
	inc hl
	inc hl
	inc hl
	ld a, [hl]			;Load direction flag
	cpl					;Toggle
	ld [hl], a			;And re-save it

.TimeSFX3
	ld hl, C1AtkHold	;Check attack hold value
	add hl, de
	ld a, [hl]
	and a				;Set flags
	jr nz, .TimeSFX5	;Continue attack cycle

	ld hl, C1SusRel		;Now check sustain/release value
	add hl, de
	ld a, [hl-]
	cp [hl]
	jr nz, .TimeSFX4	;Start release cycle

	dec hl
	ld a, [hl]			;Check SFXChop
	cp $FF				
	jr z, .SBending		;FF = no chop

	dec [hl]			;Try again decrementing value
	jr nz, .SBending	;Not ended, so continue effects

	inc hl
	ld [hl], 0			;Set attack/decay value to 0
	ld hl, C1EnvVal+1
	add hl, de
	ld [hl], 0			;Set envelope value + 1 to 0
	ret


.TimeSFX4
	ld [hl], a			;Sustain/release to attack/decay (start release)
	jr .SBending

.TimeSFX5
	dec [hl]			;Decrement attack hold value

.SBending
	ld hl, C1BendType	;Get bend type value from RAM
	add hl, de
	ld a, [hl]
	and a
	jr z, .SpecialFX	;00 = No bend

.Bend3					;03 = Up start (only during attack count)
	ld hl, C1AtkHold
	add hl, de
	sub 3
	jr nz, .Bend4

	or [hl]
	jr nz, .Bend1A

	jr .SpecialFX

.Bend4					;04 = Down start
	dec a
	jr nz, .Bend5

	or [hl]
	jr nz, .Bend2A

	jr .SpecialFX

.Bend5					;05 = Up/down (up during attack count/down during end count)
	dec a
	jr nz, .Bend6

	or [hl]
	jr nz, .Bend1A

	jr .Bend2A

.Bend6					;06 = Down/up
	dec a
	jr nz, .Bend7

	or [hl]
	jr nz, .Bend2A

	jr .Bend1A

.Bend7					;07 = Up release (only during end count)
	dec a
	jr nz, .Bend8

	or [hl]
	jr z, .Bend1A

	jr .SpecialFX

.Bend8					;08 = Down release
	dec a
	jr nz, .Bend9

	or [hl]
	jr z, .Bend2A

	jr .SpecialFX

.Bend9					;09 = Up/down cycle (changes direction every new count value)
	dec a
	jr nz, .Bend1

	ld hl, C1DirFlag
	add hl, de
	bit 7, [hl]
	jr nz, .Bend1A

	jr .Bend2A

.Bend1					;01 = Up
	sub $F8
	jr nz, .Bend2

.Bend1A					
	ld hl, C1Freq		;Add bend to frequency
	add hl, de
	ld b, h
	ld c, l
	inc bc
	inc bc
	inc bc
	ld a, [bc]			;Bend low byte
	add [hl]
	ld [hl+], a
	inc bc
	ld a, [bc]			;Bend high byte
	adc [hl]
	ld [hl], a
	jr .SpecialFX

.Bend2					;02 = Down
	dec a
	jr nz, .SpecialFX

.Bend2A
	ld hl, C1Freq		;Subtract bend from frequency
	add hl, de
	ld b, h
	ld c, l
	inc hl
	inc hl
	inc hl
	ld a, [bc]			;Bend low byte
	sub [hl]
	ld [bc], a
	inc bc
	inc hl
	ld a, [bc]			;Bend high byte
	sbc [hl]
	ld [bc], a

.SpecialFX
	;Check for special effect value
	ld hl, C1SFXExtra
	add hl, de
	ld a, [hl]
	and a
	ret z				;No special effect

	ld c, a				;Get current frequency
	ld hl, C1Freq+1
	add hl, de
	
.SFX01					;01 = Arpeggio (uses note values at half speed)
	srl c				;(Swap frequency lo/hi at 60Hz)
	jr nc, .SFX02

	ld a, [hl-]
	ld b, [hl]
	ld [hl+], a
	ld [hl], b

.SFX02					;02 = Trill note (alternating with normal note)
						;24-7F/80-FF Normally used with drum sounds.
	srl c				;Complex frequency high sbc bend high/eor new value
	jr nc, .SFX04

	push hl
	ld a, [hl]			;Frequency high byte
	inc hl
	inc hl
	inc hl
	sub [hl]			;Subtract from bend high byte
	ld hl, C1NewVal
	add hl, de
	xor [hl]			;Clear new value
	pop hl
	ld [hl], a			;Also clear high frequency byte

.SFX04					;04 = Drum (wave alternates with voice/frequency bend down)
	srl c				;Waver frequency low + (random and #7)
	jr nc, .SFX08

	ld a, [Seed]		;Random number generator (RNG)
	ld b, a
	add a
	add a
	add a
	add a
	add b
	add 11
	ld [Seed], a
	swap a
	and %00001111
	push hl
	ld hl, C1FreqOff	;08 if effect call/00 if not
	add hl, de
	ld [hl], a			;Random 0-F value (i.e. +/- 8)
	pop hl

.SFX08					;Chord (uses note values)
	srl c				;Reload
	jr nc, .SFX10

	push hl
	ld hl, C1Countdown
	add hl, de
	ld a, [hl+]
	inc hl				;New value variable in RAM is 2 bytes ahead
	and a				;Set flags according to countdown
	ld a, [hl]			;Get new value
	pop hl
	ret nz

	ld [hl], a			;Frequency hi re-loaded with new value

.SFX10					;Attack wave (used instead of waveform during attack count)
	srl c				;Normally used with $81 value for noise "chiff" attack.
	jr nc, .SFX20		;Swap low frequency nibbles at 60Hz

	dec hl
	ld a, [hl]
	swap a
	ld [hl], a
	inc hl

.SFX20					;Attack note (used instead of normal note during attack count)
	srl c				;Complex frequency low to sbc bend low/eor new value 2 (frequency low)
	ret nc

	push hl
	dec hl
	ld a, [hl]			;Frequency low byte
	inc hl
	inc hl
	inc hl
	sub [hl]			;Subtract from bend low byte
	ld hl, C1NewVal2
	add hl, de
	xor [hl]			;Clear new value
	pop hl
	dec hl
	ld [hl], a			;Also clear low frequency byte
	ret


OutSound:
	ld hl, C1SFXHold	;Check for SFX in this channel
	add hl, de
	ld a, [hl]
	cp 0
	jr z, .OutSound2	;Set EffSnd to 0 (music)

	ld a, $FF			;Set EffSnd to 1 (SFX)

.OutSound2
	ld [EffSnd], a
	ld hl, C1AttDec		;Current waveform for SFX or music
	add hl, de
	bit 0, [hl]			;Check "gate (attack/release)" bit
	ld hl, C1EnvSR		;Current sustain/release
	add hl, de
	jr z, Release		;If the gate is off

AttDecSus:
	ld a, [hl-]			;Otherwise, if gate bit is on
	and %11110000		;Envelope sustain/release sustain nibble
	ld b, a				;B holds sustain value
	ld a, [hl+]			;Envelope attack/decay value
	inc hl
	inc hl
	inc hl
	ld c, [hl]			;Load envelope sequence value in C
	push hl
	bit 1, c
	call z, ExEnvF		;If attack or decay phase
	pop hl
	ld [hl], c			;Save new envelope sequence phase
	jr OutFreq

Release:
	ld b, [hl]			;B = Envelope sustain/release value (gate off)
	inc hl
	inc hl
	inc hl
	ld [hl], 0			;Envelope sequence = 0 (set attack phase)
	ld hl, C1EnvVal+1
	add hl, de
	ld a, [hl-]
	sub $08
	jr nz, .Release2	;If not at sustain level

	or [hl]				;At sustain level (envelope value)
	ret z				;At sustain level of 0

.Release2
	ld a, b				;Store envelope sustain/release value in A
	ld bc, 1			;Force decay (release phase)
	call ExEnvF			;Release phase

OutFreq:
	ld hl, C1FreqOff	;Load frequency offset into A
	add hl, de
	ld a, [hl]			;0 = music, 8 or 0-F effect
	ld hl, C1AttDec		;Also load current waveform into B
	add hl, de
	ld b, [hl]
	inc hl
	inc hl
	add [hl]
	ld e, a				;Now load frequency low/high values into DE
	inc hl
	ld d, [hl]
	ld a, d
	
	ld a, b				;Load current waveform into A
	ld bc, $11			;Now load envelope value into HL
	add hl, bc
	ld l, [hl]
	ld h, a
	ld a, [CurChan]		;Load current channel (1-4) into C
	ld c, a
	ld a, l				;L = envelope value (low)
	and %11110000		;Isolate current envelope level
	jr z, .NoVolume		;If 0, then no volume

	ld a, [NoiseChan]	;Load current noise channel into A
	bit 7, h			;H = current waveform
	jr z, .NoNoise		;If noise bit not set

	push af
	ld a, [EffSnd]
	cp 0
	jr z, .Noise		;Music, so check other channels

	pop af				;Otherwise, effect, so force other noise
	jr .Noise_Eff

.Noise
	pop af
	cp $FF				;Check for any other noise
	jr nz, .Noise2		;If so, then leave noise channel alone

.Noise_Eff				;No noise used so far...
	ld a, c				;So this channel will use noise.
	ld [NoiseChan], a

.Noise2					;Check if this channel is used for noise
	cp c
	jr nz, .Pulse		;If not, then skip to pulse

	;Otherwise, there is noise
	push bc
	push de
	push hl				;H was attack/decay value (current waveform)/L was envelope value
	ld b, l				;B = low byte of envelope value
	ld a, d				;Get high byte of frequency
	xor %11111111
	swap a
	and %01110000		;Bits 4, 5, 6 only
	ld d, a
	ld a, e				;Now get high byte of frequency
	xor %11111111
	swap a
	and %00001100		;Bits 2 and 3 only (and force bit 3 low)
	rr a
	rr a				;A has bits 0 and 1
	or %00000100		;Force bit 2 high
	or d				;Add top 4 bits
.Noise3
	ld l, a				;Load low byte into L
	ld c, 3				;Force channel 4 (noise)
	ld h, 0				;3 bits of frequency high always 0
	call SetFreq
	
	ld a, [CurChan]		;Get current channel for noise stereo position (pan)
	ld c, a
	inc c				;C = 1, 2, 3
	ld hl, C1Pan
	dec c
	jr z, .Noise4		;1 to 0

	ld hl, C2Pan
	dec c				;2 to 1 to 0
	jr z, .Noise4

	ld hl, C3Pan

.Noise4
	ld a, [hl]
	add a
	add a
	add a				;Convert to channel 4 bit position
	ld b, %01110111		;Channel 4 mask
	ld c, a				;Load stereo bits into C
	ldh a, [rNR51]		;Get pan value
	and b				;Mask out this channel
	or c				;Add stereo (pan) for this channel
	ldh [rNR51], a
	jr .EndNoise

.NoNoise
	cp c				;If noise bit is off in this channel
	jr nz, .Pulse		;But noise in another channel

	push bc				;No noise and this was noise channel
	push de
	push hl
	call NoiseSwitchOff	;So switch off noise

.EndNoise				;Restore previous register values
	pop hl				;H = current waveform/L = current envelope
	pop de				;DE = frequency
	pop bc				;B = unused/C = current channel

.Pulse					
	ld a, h				;Load current waveform into A
	and %01000000		;Check for pulse wave
	jr z, FreqOff		;No other waveforms (set frequency to 0)

	ld b, l				;Otherwise, set B to envelope value
	ld l, e				;Transfer DE to HL
	ld h, d
	jr SetFreq			;Other waveforms needed

.NoVolume
	ld a, [NoiseChan]	;If envelope level is 0
	cp c				;Check if this was the noise channel
	jr nz, FreqOff		;If not, then just set tone and level to 0

	call FreqOff		;Otherwise, do the same

NoiseSwitchOff:			;Cancel noise channel
	ld a, $FF
	ld [NoiseChan], a
	ld c, 3				;Set noise frequency and level to 0 at channel 4

FreqOff:
	ld hl, 0
	ld b, h				;Force 0 volume

;Set channel frequency
SetFreq:
	push bc				;Save envelope value and current channel
	ld a, c
	ld bc, rNR13		;Period (channel 1) - low byte
	and a				;Set flags
	jr z, .SetFreq2

	ld bc, rNR23		;Channel 2
	dec a
	jr z, .SetFreq2

	ld bc, rNR33		;Channel 3
	dec a
	jr z, .SetFreq2

	ld bc, rNR43		;Channel 4

.SetFreq2
	ld a, l				;Get low byte value
	ld [bc], a			;Save low byte value to NRx3
	inc c				;Now move to high frequency register
	ld a, h
	and %00000111		;Only 3 bits used for frequency high
	ld [bc], a			;Save high byte to NRx4
	
	pop hl				;Retrieve envelope value
	ld l, a				;Load high frequency byte into L
	ld a, h				;Load envelope value into A
	and %11110000		;Isolate the envelope level
	ld h, a				;Load the current envelope level into H
	ld a, c
	cp LOW(rNR34)		;Check for channel 3
	jr z, SetWave		;If so, then set wave

	dec c
	dec c
	cp LOW(rNR44)		;Otherwise, check for channel 4
	jr z, SetEnv		;If so, then ignore

	push hl				;Then it must be channel 1 or 2
	ld hl, C1AttDec		;Channel 1 and 2 current waveform
	cp LOW(rNR14)		;Check if channel 1
	jr z, SetPulseWave

	ld hl, C2AttDec		;If not, then is channel 2

;Set channel 1/2 registers
SetPulseWave:			;Get current waveform
	ld a, [hl]
	and %00110000		;Pulse width bits only
	add a
	add a				;Move to bit 7 and 6
	dec c
	ld [bc], a			;Save waveform to NRx1
	pop hl
	inc c

SetEnv:
	ld a, [bc]			;Get NRx2 envelope
	and %11110000		;Current envelope level
	cp h				;Desired envelope level
	ret z				;If the same, then don't change

	ld a, h
	ld [bc], a			;Save new envelope level
	inc c
	inc c

SetInit:
	ld a, l				;High 3 bits of frequency (NRx3)
	or %10000000		;Set trigger/restart bit
	ld [bc], a			;Save to NRx4
	and %00000111		;Then get frequency bits only
	ld [bc], a			;Save to NRx4 (already triggered/restarted)
	ret


;Set channel 3 parameters
SetWave:
	ld a, [EnvC3]		;Get channel 3 envelope
	cp h				;Check if same as desired level
	ret z				;If same, then don't change

	xor a				;Otherwise, turn off sound 3 
	ldh [rNR30], a
	ld a, h
	ld [EnvC3], a		;Then, save new desired envelope
	swap a				;A has level in each nibble
	or h
	
	push hl
	push af
	ld hl, C3AttDec		;Get channel 3 attack/decay value
	ld a, [hl]
	swap a
	and %00000011		;Pulse width bits only
	inc a				;1-4
	ld l, a
	
	pop af				;Retrieve volume level
	ldh [WaveRAM], a	;12.5% width
	ldh [WaveRAM+8], a
	dec l
	;If l = 0, then exit
	call z, .SetWaveExit
	ldh [WaveRAM+1], a	;25% width (l = 2)
	ldh [WaveRAM+9], a
	dec l
	call z, .SetWaveExit
	ldh [WaveRAM+2], a	;50% width (l = 3)
	ldh [WaveRAM+3], a
	ldh [WaveRAM+10], a
	ldh [WaveRAM+11], a
	dec l
	call z, .SetWaveExit
	ldh [WaveRAM+4], a	;75% width (l = 4)
	ldh [WaveRAM+5], a
	ldh [WaveRAM+12], a
	ldh [WaveRAM+13], a
	pop hl
	ld a, %10000000
	ldh [rNR30], a		;Turn sound 3 on
	jr SetInit			;Now restart sound

.SetWaveExit
	xor a
	ret


;A = Envelope attack/decay (gate on) OR envelope sustain/release (gate off)
ExEnvF:
	push de				;Save channel offset
	push af				;Also save waveform
	ld hl, C1AtkVol		;Get channel attack/decay value
	add hl, de
	ld a, [hl]
	ld [MaxVol], a		;Set maximum volume value
	pop af				;Load original waveform
	ld hl, C1EnvVal
	add hl, de
	push hl
	ld e, [hl]			;Get envelope value
	inc hl
	ld h, [hl]
	ld l, e				;Set HL to envelope value (word)
	
	;Create new envelope
	call ExEnv			;Exits with HL = new envelope value
	pop de				;Restore envelope value address
	ld a, l
	ld [de], a
	inc de
	ld a, h
	ld [de], a			;Set final value of envelope (word)
	pop de				;Restore channel offset
	ret


;Create envelopes
;A = envelope attack/decay/B = sustain value 00-F0 (gate on)
;A = envelope sustain/release/B = 0			 	   (gate off)
;C = envelope sequence (0 = attack, 1 = decay, 2 = sustain phase)
ExEnv:
	push hl				;HL = envelope value (word)
	bit 0, c			;C = envelope sequence
	jr nz, .ExEnv2		;If not in attack phase, then skip

	rrca				;Attack times are shorter
	rrca
	rrca				;Divide by 8
	jr .ExEnv3

.ExEnv2
	add a				;Decay times are longer - multiply by 2
.ExEnv3
	and $1e				;Only 15*2 bytes in table
	add LOW(ADRTab)
	ld l, a
	adc HIGH(ADRTab)
	sub l
	ld h, a				;Load envelope time table entry address into HL
	ld e, [hl]
	inc hl
	ld d, [hl]			;Load envelope time (word) into DE
	pop hl				;HL = envelope value (word)
	bit 0, c			;Check if envelope sequence is at attack
	jr nz, Env_Dec		;Otherwise, is in decay phase

Env_Atk:
	add hl, de			;Add envelope time to value
	jr c, .Env_Atk2

	add hl, de
	jr c, .Env_Atk2

	add hl, de
	jr c, .Env_Atk2

	ld a, h
	
	push hl				;Save new envelope value - now check maximum volume
	ld hl, MaxVol		;Previously found 00-0F
	cp [hl]				;Maximum volume for this voice
	pop hl
	ret c				;Return if not reached peak yet

.Env_Atk2
	ld hl, MaxVol
	ld a, [hl]
	ld h, a
	ld l, 0
	inc c				;Move to decay phase next
	ret


Env_Dec:
	ld a, b				;(or forced release)
	and %11110000		;B = 00-F0 - isolate sustain nibble
	or %00000111
	ld b, a
	scf					;Set carry
	ld a, l
	sbc e
	ld l, a
	ld a, h
	sbc d
	ld h, a				;HL = envelope value - envelope time
	ld a, b				;A = (sustain OR 7)
	jr c, Env_Sus

	cp h				;Check maximum volume
	inc hl
	ret c				;Return if not reached sustain phase

Env_Sus:
	inc a				;Increase sustain
	ld h, a
	ld l, 0
	inc c				;Move to sustain phase next
	ret


SendMus:
	bit 7, a			;Enter with A = song number or ($80 + fader count)
	jr z, .SendMus2

	and %01111111		;Negative value = fade  value
	ld [Fader], a
	ret					;Nothing this time, so return


;Load song pointers from offset
.SendMus2
	ld l, a
	ld h, 0
	add hl, hl
	add hl, hl
	add hl, hl			;Multiply by 8 - 8 bytes per track
	ld a, l
	ld b, h				;Save high byte of word offset
	ld hl, TrackOff		;Get pointer for this music data
	add [hl]			;Add low byte of track offset
	ld e, a				;Save low byte of final address
	inc hl
	ld a, b				;Now retrieve high byte
	adc [hl]			;Add high byte of track offset
	ld h, a				;Save high byte of final address
	ld l, e
	ld a, [hl+]			;Load channel pointers - A pointers to first low byte
	ld [C1Track], a
	ld a, [hl+]
	ld [C1Track+1], a
	ld a, [hl+]
	ld [C2Track], a
	ld a, [hl+]
	ld [C2Track+1], a
	ld a, [hl+]
	ld [C3Track], a
	ld a, [hl+]
	ld [C3Track+1], a
	
	ld de, 0
	ld b, 3				;3 channels

.SendMus3
	push bc
	ld hl, C1VoiceMute
	add hl, de
	xor a
	;Clear channel flags
	ld [hl], a
	ld hl, C1LoopFlag
	add hl, de
	ld [hl], a
	ld hl, C1SeqStep
	add hl, de
	ld [hl], a
	ld hl, C1AttDec
	add hl, de
	ld [hl], a
	ld hl, C1EnvSR
	add hl, de
	ld [hl], a
	ld hl, C1Dur
	add hl, de
	ld [hl], 1
	;Set voice (instrument) number
	ld a, $FF
	ld hl, C1VoiceNum
	add hl, de
	ld [hl], a
	;Set threshold to max
	ld hl, C1Threshold
	add hl, de
	ld [hl], a
	;Also track step
	ld hl, C1TrackStep
	add hl, de
	ld [hl], a
	;Now read track
	call ReadTrack
	;Repeat for all 3 channels
	ld hl, ChanRAMSize
	add hl, de
	ld d, h
	ld e, l
	pop bc
	dec b
	jr nz, .SendMus3

	;Set fade count and global transpose to 0
	xor a
	ld [FadeCnt], a
	ld [GlobalTranspose], a
	dec a
	;Set fade and more to FF
	ld [Fader], a
	ld [Status], a
	ld [TempoCtrl], a
	ld [ClockL], a			;Clock starts at $FFFF 1st increase to $0000
	ld [ClockH], a
	ld a, %00000111
	;Set volume to maximum
	ld [Volume], a
	;Set master volume to maximum
	ld a, %01110111			;Maximum value for both left and right
	ldh [rNR50], a
	ret


IntMusic:
	;Check status value
	ld a, [Status]
	rla
	ret nc					;Return if not minus

	;Then check fader value
	ld a, [Fader]			;Fade test
	bit 7, a
	jr nz, TempoTest

	or a					;Set flags
	jr z, TrackStop			;If $80 fader value, then stop immediately

	ld hl, FadeCnt			;Otherwise, decrement fade
	dec [hl]
	bit 7, [hl]				;Check if still $80 or more
	jr z, TempoTest

	ld [hl], a				;Save fader value back into fade count
	ld hl, Volume			;End of fade count, so decrease volume
	dec [hl]				;If volume is 0, then stop track
	jr z, TrackStop			;End of fade

	ld a, [hl]				;Otherwise, put into both nibbles of volume control
	ld c, a
	swap a
	or c
	ldh [rNR50], a

TempoTest:
	;Check tempo control for overflow
	ld a, [TempoCtrl]
	ld hl, TempoVal
	add [hl]
	ld [TempoCtrl], a
	jr nc, .Tempo3			;If no overflow, then set flag to FF

	ld hl, ClockL			;Otherwise, update tempo clock...
	inc [hl]
	jp nz, .Tempo2			;And set flag to 0

	inc hl
	inc [hl]

.Tempo2
	xor a
	jr .Tempo4

.Tempo3
	ld a, $FF

.Tempo4
	ld [TempoFlag], a
	
Music1:
	;Set channel and channel address (to add) to 0
	xor a
	ld d, a
	ld e, a
	ld [CurChan], a

MusicLoop:
	ld hl, C1SFXHold
	add hl, de
	ld a, [hl]			;Check if SFX are playing on channel
	and a
	jr z, .Music1B		;Past critical portion/no effect

	ld hl, C1VoiceMute
	add hl, de
	ld [hl], $FF		;Mute music channel during sound effect

.Music1B
	ld a, [TempoFlag]
	and a
	jp nz, Treatment

	ld hl, C1NoteLen	;Increase current note length
	add hl, de
	inc [hl]
	inc hl
	dec [hl]			;And decrease duration remaining
	jp nz, Treatment	;If not done yet, then...

	ld hl, C1SeqNum		;Otherwise, check next sequence number in track
	add hl, de
	ld a, [hl-]			;HL now holds SeqStep
	cp $FE				;Is it FE (loop)?
	jr c, SeqRead		;If less, then read next sequence value

	jr nz, TrackLoop	;Otherwise, then it is a loop
	
;If higher (FF), then it is a stop command
TrackStop:
	ld a, 0
	ld [Volume], a
	ld a, 0				;Force minimum volume in left and right channel
	ldh [rNR50], a
	
	xor a
	ld [Status], a		;Force status to 0
	ld d, a
	ld e, a
	call Kills			;Kill channel 1
	ld de, ChanRAMSize
	call Kills			;Kill channel 2
	ld de, ChanRAMSize*2

Kills:					;Kill channel 3
	ld hl, C1VoiceMute
	add hl, de
	bit 7, [hl]
	ld [hl], $FF
	ret nz				;Still effects if not 0

	ld hl, C1EnvVal+1
	add hl, de
	xor a
	ld [hl], a			;No effects, so envelope value+1 = 0
	ld hl, C1AttDec
	add hl, de
	ld [hl], a			;And attack/decay value = 0
	ret


TrackLoop:
	ld [hl], 0			;Reset track sequence step to 0
	call ReadTrack		;Then read next value

SeqRead:
	add a				;Multiply A by 2 (word table)
	ld c, a				;A = sequence number
	ld b, 0
	jr nc, .SeqRead2

	ld b, 1				;For sequence 80 or greater

.SeqRead2
	ld a, [SeqOff]		;Get low byte of offset table address
	add c				;Add sequence number * 2
	ld l, a				;Store result, low
	ld a, [SeqOff+1]	;Now get high byte of offset table address
	adc b				;Add carry only
	ld h, a				;HL points to table offset
	ld a, [SeqDat]		;Get low byte of sequence data address
	add [hl]			;Add offset for this sequence
	ld c, a
	ld a, [SeqDat+1]
	inc hl
	adc [hl]
	ld b, a				;BC is now the address of 1st byte in sequence

	ld hl, C1SeqStep
	add hl, de
	ld a, [hl]			;Get sequence step for this channel
	cp 0
	jr nz, .SeqRead3

	ld hl, C1Threshold
	add hl, de
	ld [hl], $FF

.SeqRead3
	add c
	ld c, a
	adc b
	sub c
	ld b, a				;BC is now the address of the sequence
	
	ld a, $FF			;Set voice temp variable to FF
	ld [VoiceTemp], a
	ld hl, C1GateMask
	add hl, de
	ld [hl], a			;Set gate mask to FF
	ld hl, C1BendByte
	add hl, de
	ld [hl], 0			;Set bend byte status to 0
	ld hl, C1AtkEnd
	add hl, de
	ld [hl], 0			;Set attack end status to 0
	ld hl, C1TiedNote
	add hl, de
	ld [hl], 0			;Set tied note status to 0

NewPair:
	ld a, [bc]			;Get next sequence byte
	bit 7, a			;Is it 80 or more?
	;If not, then it is a note
	jr z, NoteRead
	
	;Otherwise, it is a VCMD
	inc bc
	
EventVoice:
;80 = Change to new voice (instrument)
;Parameters: xxxxxxxx (X = voice (instrument) number)
	;Is this the command?
	cp $80
	;If not, then check for next command
	jr nz, EventRest

	ld a, [bc]
	ld [VoiceTemp], a			;VoiceTemp was FF
	jp ParamExit


EventRest:
;81 = Key off the channel for a duration
;Parameters: xxxxxxxx (length)
	;Is this the command?
	cp $81
	;If not, then check for next command
	jr nz, EventBend

	;Turn off gate mask
	ld hl, C1GateMask
	add hl, de
	ld [hl], %11111110				;Release and fade
	;Turn on tied note status
	ld hl, C1TiedNote
	add hl, de
	ld [hl], $FF
	jp GetLen


EventBend:
;82 = Perform a pitch bend/portamento effect
;Parameters: xxxxxxxx (X = bend value (signed))
	;Is this the command?
	cp $82
	;If not, then check for next command
	jr nz, EventTempo

	;Load pitch bend value from parameter
	ld a, [bc]
	ld hl, C1BendByte
	add hl, de
	ld [hl], a
	jp ParamExit


EventTempo:
;83 = Set the tempo
;Parameters: xxxxxxxx (value)
	;Is this the command?
	cp $83
	;If not, then check for next command
	jr nz, EventTie

	;Load tempo value from parameter
	ld a, [bc]
	ld hl, TempoVal
	ld [hl], a
	jp ParamExit


EventTie:
;84 = Tie the next two notes together
;Parameters: -------- (- = unused)
	;Is this the command?
	cp $84
	;If not, then check for next command
	jr nz, EventGate

	;Set tied note status to 1
	ld hl, C1TiedNote
	add hl, de
	ld [hl], $FF
	jp ParamExit


EventGate:
;80 = Set new length for note to be gated off (released)
;Parameters: xxxxxxxx (X = length)
	;Is this the command?
	cp $85
	;If not, then check for next command
	jr nz, EventTranspose

	;Load new gate/threshold value from parameter
	ld a, [bc]
	ld hl, C1Threshold
	add hl, de
	ld [hl], a
	jp ParamExit


EventTranspose:
;86 = Transpose all channels
;Parameters: xxxxxxxx (X = value (signed))
	;Is this the command?
	cp $86
	;If not, then return
	jr nz, ParamExit

	;Load transpose value from parameter
	ld a, [bc]
	ld hl, GlobalTranspose
	ld [hl], a

ParamExit:
	;Ready for note - advance the address by 1 and the pointer in RAM by 2
	inc bc
	ld hl, C1SeqStep		;HL = sequence step for this channel
	add hl, de
	inc [hl]
	inc [hl]				;Add 2 to sequence step
	;Then get next sequence byte
	jp NewPair


NoteRead:
	;Load current note byte into RAM
	ld hl, C1NoteVal
	add hl, de
	ld [hl], a				;Save note value
	inc bc

;Get the length of the current note/rest
GetLen:						;Get next sequence byte	
	ld a, [bc]
	ld hl, C1Dur
	add hl, de
	ld [hl-], a				;Set duration to parameter
	ld [hl], 0				;Set note length value to 0
	ld hl, C1SeqStep		;HL = sequence step for this channel
	add hl, de
	inc [hl]
	inc [hl]				;Add 2 to sequence step
	inc bc					;Advance address
	push bc					;Save address for later
	ld hl, C1VoiceMute		;Check for sound effect in this channel
	add hl, de
	bit 7, [hl]
	jr z, NewStart			;If there are no sound effects, then play note

	ld hl, C1SFXHold		;Otherwise, if there are still effects...
	add hl, de				;Check hold
	ld a, [hl]
	and a
	jr nz, NewStart			;If still in critical position, then play note

	ld hl, C1TiedNote		
	add hl, de
	ld [hl], a				;If past critical portion, then force tie off first

;Start a new note
NewStart:
	ld a, [VoiceTemp]		;Get temporary voice from command if present
	bit 7, a
	jr nz, ModRead			;If FF, then no new voice

	ld hl, C1VoiceNum
	add hl, de
	cp [hl]					;Check current channel voice
	jr z, ModRead			;If voice is the same, then ignore

	ld [hl], a				;Otherwise, load new voice
	ld hl, C1TiedNote		;Also force envelope restart
	add hl, de
	ld [hl], a

ModRead:
	ld hl, C1TiedNote		;Get tied note status
	add hl, de
	bit 7, [hl]
	jr nz, ReadEnd			;If tied note, then ignore new mods

	;Get voice number
	ld hl, C1VoiceNum
	add hl, de
	;Get address to add to voice table
	ld l, [hl]
	ld h, 0
	add hl, hl				;16 bytes each voice
	add hl, hl
	add hl, hl
	add hl, hl
	ld c, l
	ld b, h					;Move to BC (0000 to 01F0)
	ld hl, C1VoiceOffset
	add hl, de
	ld [hl], c				;Save offset to this voice
	inc hl
	ld [hl], b
	
	xor a
	;Now load parameters from voice
	call GetVoice			;Byte 1 = attack time (00-0F)/decay time (00-0F)
	ld [ADTemp], a
	inc bc
	ld a, [bc]				;Byte 2 = sustain (00-0F)/release (00-0F)
	ld [SRTemp], a
	inc bc
	ld a, [bc]				;Byte 3 = waveform
	ld hl, C1NoteCtrl
	add hl, de
	ld [hl], a
	inc bc
	ld a, [bc]				;Byte 4 = specials
	ld hl, C1Special
	add hl, de
	ld [hl], a
	inc bc
	ld a, [bc]				;Byte 5 = stereo placement/panning (10 = left, 11 = center, 01 = right)
	ld [StereoTemp], a
	ld hl, C1Transpose
	add hl, de
	inc bc
	ld a, [bc]				;Byte 6 = signed offset to note
	ld [hl], a				;Use as channel transpose value
	inc bc
	ld a, [bc]				;Byte 7 = attack peak level (00-0F) (can be used to set overall volume) - attack volume
	ld [PeakTemp], a
	inc bc
	ld hl, C1SpecNtDn
	add hl, de
	ld a, [bc]				;Byte 8 = used by chord/attack wave/attack note specials - attack count
	ld [hl], a
	ld a, 15				;Vibrato delay
	call GetVoice
	ld hl, C1VibDelay
	add hl, de
	ld [hl], a
	
	ld hl, C1SFXHold		;Check if any sound effects are on
	add hl, de
	ld a, [hl]
	and a
	jr nz, ReadEnd			;If so, then ignore

	ld hl, C1VoiceMute
	add hl, de
	ld [hl], a				;Otherwise, clear any mute
	ld hl, C1EnvAD
	add hl, de
	ld a, [ADTemp]
	ld [hl+], a				;Transfer temporary attack/delay value to channel envelope value
	ld a, [SRTemp]
	ld [hl+], a				;Transfer temporary sustain/release value to channel envelope value
	ld a, [PeakTemp]		;Finalize temporary "peak" value for attack
	swap a
	and %11110000
	or %00001000
	ld [hl], a				;Load it into attack volume
	ld a, [StereoTemp]		;Now get temporary stereo/pan value
	and %00010001			;Get only L/R bits
	ld hl, C1Pan			;Load it into channel pan value
	add hl, de
	ld [hl], a

ReadEnd:
	ld hl, C1NoteVal		;Get note value
	add hl, de
	ld a, [hl]
	push hl
	ld hl, C1Transpose		;Add to transpose from voice
	add hl, de
	add [hl]
	
	ld hl, C1Special		;Now get special value from voice to add
	add hl, de
	ld c, [hl]
	bit 7, c				;(fixed)
	jr nz, .ReadEnd2

	ld hl, GlobalTranspose	;Now add global transpose value
	add [hl]

.ReadEnd2
	pop hl
	ld [hl], a				;Save transposed note value
	
	ld hl, C1Note			;Get frequency value from table for this note
	add hl, de
	inc hl					;High byte of note
	add a					;Word table access
	add LOW(NoteTab)+1
	ld c, a
	adc HIGH(NoteTab)
	sub c
	ld b, a
	ld a, [bc]
	ld [hl-], a				;Save high byte of note
	dec bc
	ld a, [bc]
	ld [hl], a				;Save low byte of note
	pop bc					;Restore sequence offset
	ld a, [bc]				;Look at next byte of sequence
	inc a					;$FF - end of sequence to $00
	jr nz, ReadExit			;If not 0, then continue

	ld hl, C1SeqStep		;End of sequence
	add hl, de
	ld [hl+], a				;Sequence step value is now reset to 0
	inc hl					;Get track sequence repeat
	dec [hl]				;Decrease value
	call z, ReadTrack		;If repeat is 0, then continue track

ReadExit:					;Otherwise, check if sound effect is playing
	ld hl, C1VoiceMute
	add hl, de
	ld a, [hl]
	and a
	jp nz, NextChan			;If sound effect is playing, then skip to next channel

	;Otherwise, set up vibrato
	ld hl, C1SpecNtUp		;Set special note value to 0
	add hl, de
	ld [hl], a
	push hl
	ld hl, C1VibSpeed		;Also set vibrato speed to 0
	add hl, de
	ld [hl], a
	pop hl
	dec hl
	dec hl
	ld c, [hl]				;Now load special value from RAM
	inc hl
	jp Spec40				;And perform effect


Treatment:
	ld hl, C1VoiceMute		;Check if sound effect is playing
	add hl, de
	bit 7, [hl]
	jp nz, NextChan			;If so, then skip to next channel

;Process channel vibrato
Vibrato:
	ld hl, C1VibDelay		;Otherwise, check vibrato
	add hl, de				;Is vibrato delay finished?
	ld a, [hl]
	and a					;If so, then continue
	jr z, .Vibrato2

	dec [hl]				;Otherwise, decrease vibrato and check pitch bend
	jp Bending


.Vibrato2
	ld hl, C1SpecNtDn		;Check if vibrato effect is used
	add hl, de
	or [hl]					;If not, then skip to pitch bending
	jp nz, Bending

	ld a, 14				;Otherwise, then load vibrato parameter
	call GetVoice
	and a					
	jp z, Bending			;If 0, then skip to pitch bending

	ld c, a					;Otherwise, continue
	ld hl, C1VibSpeed		;Get vibrato speed
	add hl, de
	bit 7, [hl]
	jr nz, .Vibrato4

	ld b, 0					;Load vibrato sequence length from table
	ld hl, VibTab1
	add hl, bc
	ld a, [hl]
	ld hl, C1VibLimit
	add hl, de
	ld [hl-], a
	xor a
	ld [hl-], a				;Also clear vibrato step and direction values
	ld [hl-], a
	push hl
	ld hl, VibTab2
	add hl, bc
	ld a, [hl]				;Load current vibrato value from sequence
	pop hl
	ld [hl], a
	
	ld hl, C1NoteVal		;Load current channel note value
	add hl, de
	ld a, [hl]				;Get note frequency from table
	add a
	add LOW(NoteTab)
	ld l, a
	adc HIGH(NoteTab)
	sub l
	ld h, a
	ld c, [hl]
	inc hl
	ld b, [hl]
	inc hl
	push hl
	ld hl, C1Note			;Load this value into RAM
	add hl, de
	ld [hl], c
	inc hl
	ld [hl], b
	pop hl
	ld a, [hl+]				;Then, subtract vibrato from note in table to get vibrato increase amount
	sub c
	ld c, a
	ld a, [hl]
	sbc b
	ld b, a
	ld hl, C1VibInc			;Load that value in vibrato increase area
	add hl, de
	ld [hl], c
	inc hl
	ld [hl], b

.VibLoop1
	ld hl, C1VibSpeed		;Decrease vibrato speed
	add hl, de
	dec [hl]
	bit 7, [hl]				;If not done with speed, then skip to pitch bending
	jr nz, Bending

	ld hl, C1VibInc+1		;Otherwise, continue process vibrato increase
	add hl, de
	srl [hl]
	dec hl
	rr [hl]
	jr .VibLoop1

.Vibrato4
	ld hl, C1FreqDir		;Get channel 1 frequency direction
	add hl, de
	bit 7, [hl]				;Check if positive or negative
	ld hl, C1VibInc			;Load vibrato increase offset in HL
	add hl, de
	jr nz, .Vibrato5		;If negative, then go to negative section

	ld a, [hl+]				;Otherwise, add (positive)
	ld b, [hl]
	inc hl
	add [hl]
	ld [hl+], a
	ld a, b
	adc [hl]
	jr .Vibrato6

.Vibrato5					;Subtract (negative)
	ld c, [hl]
	inc hl
	ld b, [hl]
	inc hl
	ld a, [hl]
	sub c
	ld [hl+], a
	ld a, [hl]
	sbc b

.Vibrato6
	ld [hl], a
	ld hl, C1VibDir			;Check if vibrato direction is positive or negative
	add hl, de
	bit 7, [hl]
	inc hl
	jr nz, .Vibrato7		;If negative, then decrease step

	inc [hl]				;Otherwise, increase step
	ld a, [hl+]				;Then check step value
	cp [hl]					;If less than direction value, then skip to pitch bending
	jr c, Bending

	dec hl					;Otherwise, then reset vibrato delay
	dec hl
	ld [hl], $FF
	dec hl
	dec hl
	dec hl
	ld a, [hl]				;Then check gate value
	cpl
	ld [hl], a				;Invert value
	jr Bending

.Vibrato7
	dec [hl]				;Decrease step
	jr nz, Bending			;If not 0, then skip to pitch bending

	dec hl					;Otherwise, set direction to 0
	ld [hl], 0

Bending:
	ld hl, C1BendByte		;Check bending value
	add hl, de
	ld a, [hl]
	and a					;If 0, then skip to specials
	jr z, Specials

	cp $80					;Otherwise, check if positive or negative
	jr nc, .Bending2

	ld hl, C1Note			;If positive (bend up), then add pitch frequency to note
	add hl, de
	add [hl]
	ld [hl+], a
	jr nc, Specials

	inc [hl]
	jr Specials

.Bending2
	and %01111111			;If negative (bend down), then convert to positive and subtract
	ld c, a
	ld hl, C1Note
	add hl, de
	ld a, [hl]
	sub c
	ld [hl+], a
	jr nc, Specials

	dec [hl]

Specials:
	ld hl, C1Special		;Now get special value
	add hl, de
	ld c, [hl]
	inc hl
	inc hl
	bit 0, c				;First, check for arpeggio
	jr z, Spec02			;If no arpeggio, then look for other values

	ld a, [hl]				;Otherwise, get special note up value
	and %00000111
	rr a
	jp Spec20A


Spec02:
	bit 1, c				;Now check for trill note
	jr z, Spec04			;If no trill, then look for other values

	push bc					;Otherwise, get special note up value
	push hl
	bit 0, [hl]				;Check if bit set
	jr nz, .Spec02B			;If 0, then load note value

	ld hl, C1NoteVal
	add hl, de
	ld a, [hl]
	jr .Spec02C

.Spec02B
	ld a, 13				;Otherwise, get trill note value from voice
	call GetVoice
	bit 7, a				;Check if signed/unsigned
	jr z, .Spec02C

	and %01111111			;If signed (negative), then convert to unsigned and add to note
	ld hl, C1NoteVal
	add hl, de
	add [hl]

.Spec02C
	add a					;Add to note frequency value
	add LOW(NoteTab)
	ld c, a
	adc HIGH(NoteTab)
	sub c
	ld b, a
	ld hl, C1Note
	add hl, de
	ld a, [bc]
	ld [hl+], a
	inc bc
	ld a, [bc]
	ld [hl], a
	pop hl
	pop bc

Spec04:
	bit 2, c				;Now check for drum
	jr z, Spec08			;If no drum, then skip to chord

	push bc					;Otherwise, get special note up value
	push hl
	bit 0, [hl]				;Check if bit set
	jr nz, .Spec04B			;If 0, then load 81

	ld a, 2					;Otherwise, get waveform byte from voice
	call GetVoice
	jr .Spec04C

.Spec04B
	ld a, $81

.Spec04C
	ld hl, C1NoteCtrl		;Switch between noise/normal waveform alternately
	add hl, de
	ld [hl], a
	ld hl, C1NoteLen		;Then, get note length
	add hl, de
	ld a, [hl]
	cp $02					;If length is 2 or more, then gate off
	jr c, .Spec04D

	ld hl, C1GateMask
	add hl, de
	ld [hl], %11111110

.Spec04D
	ld hl, C1Note+1			;Decrease note frequency (frequency decay)
	add hl, de
	dec [hl]
	bit 7, [hl]				;And check trigger bit
	jr z, .Spec04E

	inc [hl]				;If bit set, then increase note by 1

.Spec04E
	pop hl					;Now get special note up value
	pop bc

Spec08:
	bit 3, c				;Now check for chord
	jr z, .Spec08B			;If no chord, then decrease special note value

	ld a, [hl]				;Isolate chord bits
	and %00000011
	jr Spec20A

.Spec08B
	dec hl

Spec40:
	bit 6, c				;Now check for drum bend
	jr z, Spec10			;If no drum bend, then skip to attack bend

	push bc					;Get note 1 value from voice
	push hl
	ld a, 9
	call GetVoice
	ld hl, C1BendByte		;Set the channel 1 bend value to it
	add hl, de
	ld [hl], a
	pop hl
	pop bc

Spec10:
	bit 4, c				;Now check for attack bend
	jr z, Spec20			;If no attack bend, then skip to attack note

	push bc					;Get special note down value
	push hl
	ld a, [hl]				;If not 0, then get attack wave value from voice
	and a
	jr z, Spec10B

	ld a, $08
	jr Spec10C

Spec10B:
	ld hl, C1AtkEnd			;Otherwise, check attack end value - 1 frame after attack
	add hl, de
	bit 7, [hl]				;If positive, then get waveform byte from voice
	jr nz, Spec10D

	ld a, 2

Spec10C:
	call GetVoice
	ld hl, C1NoteCtrl
	add hl, de
	ld [hl], a

Spec10D:
	pop hl
	pop bc

Spec20:
	bit 5, c				;Now check for attack note
	jr z, FinalBit			;If no attack note, then go to final bit

	ld a, [hl+]				;Otherwise, get special note up
	and a
	jr z, Spec20C			;If special note up is not 0, then also get special note down

	ld a, [hl]

Spec20A:
	add 9					;Get chord note to note value from voice
	call GetVoice
	ld hl, C1NoteVal
	add hl, de
	bit 7, a				;If high bit not set, then skip process
	jr z, Spec20D

	and %01111111			;Otherwise, get lower 7 bits
	cp $40					;Check if positive/negative value and add/subtract accordingly
	jr nc, Spec20B

	add [hl]
	jr Spec20D

Spec20B:
	and %00111111
	ld c, a
	ld a, [hl]
	sub c
	jr Spec20D

Spec20C:
	ld hl, C1AtkEnd			;1 frame after attack
	add hl, de
	bit 7, [hl]
	jr nz, FinalBit

	ld hl, C1NoteVal		;If bit is 0, then restore proper note
	add hl, de
	ld a, [hl]

Spec20D:
	add a					;Now add value to note frequency
	add LOW(NoteTab)
	ld l, a
	adc HIGH(NoteTab)
	sub l
	ld h, a
	ld c, [hl]
	inc hl
	ld b, [hl]
	ld hl, C1Note
	add hl, de
	ld [hl], c
	inc hl
	ld [hl], b

FinalBit:					;Final part: check if note is tied (compare notes)
	ld hl, C1NoteLen
	add hl, de
	ld a, [hl]
	ld hl, C1Threshold
	add hl, de
	cp [hl]
	jr nz, .FinalBit2		;If at threshold, then gate off

	ld hl, C1GateMask
	add hl, de
	ld [hl], %11111110

.FinalBit2
	ld hl, C1TiedNote		;Check if channel is tied
	add hl, de
	bit 7, [hl]
	jr nz, .FinalBit3		;If not tied, then ignore gate

	ld hl, C1SpecNtUp		;Otherwise, load special note up value
	add hl, de
	ld a, [hl]
	and a					;Set channel flags only
	jr nz, .FinalBit3		;If not 0, then all channels are masked on

	ld a, [CurChan]			;Increase channel value by 1
	inc a
	ld c, a					;C = channel (1-3)
	ld hl, C1Pan			;Set stereo/panning for the matching channel
	add hl, de
	ld a, [hl]
	ld b, %11101110
	dec c
	jr z, .FinalBit4		;If channel 1

	add a
	ld b, %11011101	
	dec c
	jr z, .FinalBit4		;If channel 2

	add a
	ld b, %10111011

.FinalBit4					;If channel 3
	ld c, a					;OR stereo value with master stereo value
	ldh a, [rNR51]
	and b
	or c
	ldh [rNR51], a
	ld a, %11111110
	jr .FinalBit5

.FinalBit3
	ld a, $FF

.FinalBit5
	ld hl, C1NoteCtrl		;Mask value with note control and gate mask
	add hl, de
	and [hl]
	ld hl, C1GateMask
	add hl, de
	and [hl]
	ld hl, C1AttDec
	add hl, de
	ld [hl], a
	
	ld hl, C1Note			;Transfer note (music data)...
	add hl, de
	ld c, [hl]
	inc hl
	ld b, [hl]
	ld hl, C1Freq			;...to frequency (overwrites sound effects data)
	add hl, de
	ld [hl], c
	inc hl
	ld [hl], b
	
	ld hl, C1SpecNtDn		;Also mask value with special note down value
	add hl, de
	ld a, [hl]
	and a
	jr nz, .FinalBit6		;If not 0, then decrease value first

	push hl					;Otherwise, turn on attack end
	ld hl, C1AtkEnd
	add hl, de
	ld [hl], $FF
	pop hl
	jr .FinalBit7

.FinalBit6
	dec [hl]

.FinalBit7					;Increase special note up value
	inc hl
	inc [hl]

NextChan:
	ld hl, ChanRAMSize		;Get next channel's RAM
	add hl, de
	ld d, h
	ld e, l
	ld hl, CurChan
	inc [hl]				;Increase channel number
	ld a, [hl]
	cp 3					;If less than maximum channels, then process next channel
	jp c, MusicLoop

	ret


ReadTrack:
	;Get current track data pointer
	ld hl, C1Track
	add hl, de
	ld a, [TrackDat]
	add [hl]
	ld c, a
	inc hl
	ld a, [TrackDat+1]
	adc [hl]
	ld b, a
	;Now add track step
	push bc
	ld hl, C1TrackStep
	add hl, de
	inc [hl]
	ld a, [hl]
	add c
	ld c, a
	adc b
	sub c
	ld b, a

ReadTrack2:
	;Check next byte of track
	ld a, [bc]
	;Is it a fade command (FD)?
	cp $FD
	;If less, then continue to read
	jr c, ReadTrack4

	;If equal, then it is a fade
	jr z, ReadFade

	;Otherwise, load byte into sequence number
	push hl
	ld hl, C1SeqNum
	add hl, de
	ld [hl], a
	pop hl
	;Then get next byte of track
	inc bc
	ld a, [bc]
	;Decrement the value and set to step value (FE/FF = stop/loop, see above)
	dec a
	ld [hl], a
	inc a
	pop bc
	ret


ReadFade:
	;Increase step value and get next byte
	inc [hl]
	inc bc
	ld a, [bc]
	;Load fade value from parameter
	ld [Fader], a

ReadTrack3:
	;Advance step value and pointer
	inc [hl]
	inc bc
	jr ReadTrack2

ReadTrack4:
	;Is it 40 or more?
	bit 6, a
	;If 40, then is loop end
	jr z, ReadTrack6

	;Otherwise, then is loop start (with number)
	push hl
	ld hl, C1LoopFlag
	add hl, de
	;Check if loop bit is set
	bit 7, [hl]
	;If so, then get loop amount
	jr nz, ReadLoop

	;Otherwise, then process information
	ld [hl], $FF
	;Get loop times from lower 6 bits
	and %00111111
	inc hl
	;Load into times remaining in RAM
	ld [hl], a
	pop hl
	inc [hl]
	ld a, [hl]
	;Advance pointer
	inc bc
	push hl
	;Then load number of times (total)
	ld hl, C1LoopMem
	add hl, de
	ld [hl], a
	pop hl
	jr ReadTrack5

ReadLoop:
	;Decrease loop times
	inc hl
	dec [hl]
	;If not 0, then go to loop
	jr nz, ReadLoop2

	dec hl
	ld [hl], 0
	pop hl
	jr ReadTrack3

ReadLoop2:
	inc hl
	ld a, [hl]
	pop hl
	;Load new times remaining in RAM
	ld [hl], a
	pop bc
	;Go to track position in loop
	push bc
	add c
	ld c, a
	adc b
	sub c
	ld b, a

ReadTrack5:
	;Then read next byte from track
	ld a, [bc]

ReadTrack6:
	;Increase track step
	inc [hl]
	ld hl, C1SeqRepeat
	add hl, de
	ld [hl], a
	
	;Advance pointer and get next byte
	inc bc
	ld a, [bc]
	;Also load new sequence number
	dec hl
	ld [hl], a
	pop bc
	ret


;Get parameter from voice
;Enter with A = parameter - 00-0F
;Exit with A = voice data byte required
;BC = address of voice data byte
GetVoice:
	ld hl, C1VoiceOffset
	add hl, de
	add [hl]			;Offset for current voice 0000-01F0
	inc hl
	ld b, [hl]			;Save high byte for later
	ld hl, VoiceBank	;Point to voice bank data
	add [hl]
	ld c, a				;C = Low byte of address required
	inc hl
	ld a, b				;Now retrieve high byte of address
	adc [hl]
	ld b, a				;B = High byte of address required
	ld a, [bc]			;Load required voice byte into A
	ret

;Envelope times
ADRTab:
	dw 61440, 61440, 30720, 15360
	dw 10240, 7680, 6144, 5120
	dw 4096, 1661, 842, 526
	dw 418, 140, 84, 53

VibTab1:
	db 0, 1, 1, 1, 1, 4, 3, 2
	db 4, 3, 2, 1, 3, 2, 1, 3
	db 2, 2, 1
	
VibTab2:
	db 0, 5, 4, 3, 2, 5, 5, 4
	db 4, 4, 3, 1, 3, 2, 0, 1
	db 1, 0, 0
	
NoteTab:
	dw $0000, $0000, $0000, $0000
	dw $0000, $0000, $0000, $0000
	dw $0000, $0000, $0000, $0000
	dw $0000, $0000, $0000, $0000
	dw $0000, $0000, $0000, $0000
	dw $0000, $0000, $0000, $0000
	dw $0000, $0000, $0000, $0000
	dw $0000, $0000, $0000, $0000
	dw $0000, $0000, $0000, $0000
	dw $002C, $009C, $0107, $016B
	dw $01C9, $0223, $0277, $02C7
	dw $0312, $0358, $039B, $03DA
	dw $0416, $044E, $0483, $04B5
	dw $04E5, $0511, $053B, $0563
	dw $0589, $05AC, $05CE, $05ED
	dw $060B, $0627, $0642, $065B
	dw $0672, $0689, $069E, $06B2
	dw $06C4, $06D6, $06E7, $06F7
	dw $0706, $0714, $0721, $072D
	dw $0739, $0744, $074F, $0759
	dw $0762, $076B, $0773, $077B
	dw $0783, $078A, $0790, $0797
	dw $079D, $07A2, $07A7, $07AC
	dw $07B1, $07B6, $07BA, $07BE
	dw $07C1, $07C5, $07C8, $07CB
	dw $07CE, $07D1, $07D4, $07D6
	dw $07D9, $07DB, $07DD, $07DF
	dw $07E1, $07E2, $07E4, $07E6
	dw $07E7, $07E9, $07EA, $07EB
	dw $07EC, $07ED, $07EE, $07EF
	dw $07F0, $07F1, $07F2, $07F3
	dw $07F4, $07F4, $07F5, $07F6

;Music and sound effects data
GameDat1:
	incbin "EWJ.SND"
	
SECTION "Audio RAM", WRAM0[AudioRAM]

SFXNum:			ds 1	;$C500
MusNum:			ds 1	;$C501
Status:			ds 1	;$C502

C1SFX:			ds 1	;$C503
C1PriorTest:	ds 1	;$C504
C1SFXHold:		ds 1	;$C505
C1SFXChop:		ds 1	;$C506
C1AttDec:		ds 1	;$C507
C1SusRel:		ds 1	;$C508
C1Freq:			ds 2	;$C509
C1BendType:		ds 1	;$C50B
C1Bend:			ds 2	;$C50C
C1SFXExtra:		ds 1	;$C50E
C1Countdown:	ds 1	;$C50F
C1CountVal:		ds 1	;$C510
C1NewVal:		ds 1	;$C511
C1NewVal2:		ds 1	;$C512
C1Priority:		ds 1	;$C513
C1DirFlag:		ds 1	;$C514
C1EnvAD:		ds 1	;$C515
C1EnvSR:		ds 1	;$C516
C1AtkVol:		ds 1	;$C517
C1AtkHold:		ds 1	;$C518
C1EnvSeq:		ds 1	;$C519
C1EnvVal:		ds 2	;$C51A
C1FreqOff:		ds 1	;$C51C
C1Track:		ds 2	;$C51D
C1VoiceOffset:	ds 2	;$C51F
C1TrackStep:	ds 1	;$C521
C1LoopFlag:		ds 1	;$C522
C1LoopCtrl:		ds 1	;$C523
C1LoopMem:		ds 1	;$C524
C1SeqStep:		ds 1	;$C525
C1SeqNum:		ds 1	;$C526
C1SeqRepeat:	ds 1	;$C527
C1NoteLen:		ds 1	;$C528
C1Dur:			ds 1	;$C529
C1NoteCtrl:		ds 1	;$C52A
C1NoteVal:		ds 1	;$C52B
C1AtkEnd:		ds 1	;$C52C
C1VoiceNum:		ds 1	;$C52D
C1GateMask:		ds 1	;$C52E
C1BendByte:		ds 1	;$C52F
C1FreqDir:		ds 1	;$C530
C1VibDelay:		ds 1	;$C531
C1VibSpeed:		ds 1	;$C532
C1VibDir:		ds 1	;$C533
C1VibStep:		ds 1	;$C534
C1VibLimit:		ds 1	;$C535
C1VibInc:		ds 2	;$C536
C1Note:			ds 2	;$C538
C1TiedNote:		ds 1	;$C53A
C1Special:		ds 1	;$C53B
C1SpecNtDn:		ds 1	;$C53C
C1SpecNtUp:		ds 1	;$C53D
C1Pan:			ds 1	;$C53E
C1Transpose:	ds 1	;$C53F
C1Threshold:	ds 1	;$C540		;Sets length before gate off (init to $FF)
C1VoiceMute:	ds 1	;$C541

C2SFX:			ds 1	;$C542
C2PriorTest:	ds 1	;$C543
C2SFXHold:		ds 1	;$C544
C2SFXChop:		ds 1	;$C545
C2AttDec:		ds 1	;$C546
C2SusRel:		ds 1	;$C547
C2Freq:			ds 2	;$C548
C2BendType:		ds 1	;$C54A
C2Bend:			ds 2	;$C54B
C2SFXExtra:		ds 1	;$C54D
C2Countdown:	ds 1	;$C54E
C2CountVal:		ds 1	;$C54F
C2NewVal:		ds 1	;$C550
C2NewVal2:		ds 1	;$C551
C2Priority:		ds 1	;$C552
C2DirFlag:		ds 1	;$C553
C2EnvAD:		ds 1	;$C554
C2EnvSR:		ds 1	;$C555
C2AtkVol:		ds 1	;$C556
C2AtkHold:		ds 1	;$C557
C2EnvSeq:		ds 1	;$C558
C2EnvVal:		ds 2	;$C559
C2FreqOff:		ds 1	;$C55B
C2Track:		ds 2	;$C55C
C2VoiceOffset:	ds 2	;$C55E
C2TrackStep:	ds 1	;$C560
C2LoopFlag:		ds 1	;$C561
C2LoopCtrl:		ds 1	;$C562
C2LoopMem:		ds 1	;$C563
C2SeqStep:		ds 1	;$C564
C2SeqNum:		ds 1	;$C565
C2SeqRepeat:	ds 1	;$C566
C2NoteLen:		ds 1	;$C567
C2Dur:			ds 1	;$C568
C2NoteCtrl:		ds 1	;$C569
C2NoteVal:		ds 1	;$C56A
C2AtkEnd:		ds 1	;$C56B
C2VoiceNum:		ds 1	;$C56C
C2GateMask:		ds 1	;$C56D
C2BendByte:		ds 1	;$C56E
C2FreqDir:		ds 1	;$C56F
C2VibDelay:		ds 1	;$C570
C2VibSpeed:		ds 1	;$C571
C2VibDir:		ds 1	;$C572
C2VibStep:		ds 1	;$C573
C2VibLimit:		ds 1	;$C574
C2VibInc:		ds 2	;$C575
C2Note:			ds 2	;$C577
C2TiedNote:		ds 1	;$C579
C2Special:		ds 1	;$C57A
C2SpecNtDn:		ds 1	;$C57B
C2SpecNtUp:		ds 1	;$C57C
C2Pan:			ds 1	;$C57D
C2Transpose:	ds 1	;$C57E
C2Threshold:	ds 1	;$C57F		;Sets length before gate off (init to $FF)
C2VoiceMute:	ds 1	;$C580

C3SFX:			ds 1	;$C581
C3PriorTest:	ds 1	;$C582
C3SFXHold:		ds 1	;$C583
C3SFXChop:		ds 1	;$C584
C3AttDec:		ds 1	;$C585
C3SusRel:		ds 1	;$C586
C3Freq:			ds 2	;$C587
C3BendType:		ds 1	;$C589
C3Bend:			ds 2	;$C58A
C3SFXExtra:		ds 1	;$C58C
C3Countdown:	ds 1	;$C58D
C3CountVal:		ds 1	;$C58E
C3NewVal:		ds 1	;$C58F
C3NewVal2:		ds 1	;$C590
C3Priority:		ds 1	;$C591
C3DirFlag:		ds 1	;$C592
C3EnvAD:		ds 1	;$C593
C3EnvSR:		ds 1	;$C594
C3AtkVol:		ds 1	;$C595
C3AtkHold:		ds 1	;$C596
C3EnvSeq:		ds 1	;$C597
C3EnvVal:		ds 2	;$C598
C3FreqOff:		ds 1	;$C59A
C3Track:		ds 2	;$C59B
C3VoiceOffset:	ds 2	;$C59D
C3TrackStep:	ds 1	;$C59F
C3LoopFlag:		ds 1	;$C5A0
C3LoopCtrl:		ds 1	;$C5A1
C3LoopMem:		ds 1	;$C5A2
C3SeqStep:		ds 1	;$C5A3
C3SeqNum:		ds 1	;$C5A4
C3SeqRepeat:	ds 1	;$C5A5
C3NoteLen:		ds 1	;$C5A6
C3Dur:			ds 1	;$C5A7
C3NoteCtrl:		ds 1	;$C5A8
C3NoteVal:		ds 1	;$C5A9
C3AtkEnd:		ds 1	;$C5AA
C3VoiceNum:		ds 1	;$C5AB
C3GateMask:		ds 1	;$C5AC
C3BendByte:		ds 1	;$C5AD
C3FreqDir:		ds 1	;$C5AE
C3VibDelay:		ds 1	;$C5AF
C3VibSpeed:		ds 1	;$C5B0
C3VibDir:		ds 1	;$C5B1
C3VibStep:		ds 1	;$C5B2
C3VibLimit:		ds 1	;$C5B3
C3VibInc:		ds 2	;$C5B4
C3Note:			ds 2	;$C5B6
C3TiedNote:		ds 1	;$C5B8
C3Special:		ds 1	;$C5B9
C3SpecNtDn:		ds 1	;$C5BA
C3SpecNtUp:		ds 1	;$C5BB
C3Pan:			ds 1	;$C5BC
C3Transpose:	ds 1	;$C5BD
C3Threshold:	ds 1	;$C5BE		;Sets length before gate off (init to $FF)
C3VoiceMute:	ds 1	;$C5BF

Fader:			ds 1	;$C5C0
Volume:			ds 1	;$C5C1
FadeCnt:		ds 1	;$C5C2
TempoVal:		ds 1	;$C5C3
TempoFlag:		ds 1	;$C5C4
TempoCtrl:		ds 1	;$C5C5
VoiceTemp:		ds 1	;$C5C6
ADTemp:			ds 1	;$C5C7
SRTemp:			ds 1	;$C5C8
PeakTemp:		ds 1	;$C5C9
StereoTemp:		ds 1	;$C5CA
GlobalTranspose:ds 1	;$C5CB
ClockL:			ds 1	;$C5CC
ClockH:			ds 1	;$C5CD

NoiseChan:		ds 1	;$C5CE
CurChan:		ds 1	;$C5CF
Seed:			ds 1	;$C5D0
EnvC3:			ds 1	;$C5D1
MaxVol:			ds 1	;$C5D2
EffSnd:			ds 1	;$C5D3

SFXBank:		ds 2 	;$C5D4 - address of 1st byte of effects
SFXTab:			ds 2	;$C5D6 - address of 1st byte of call table
VoiceBank:		ds 2	;$C5D8
SeqOff:			ds 2	;$C5DA
SeqDat:			ds 2	;$C5DC
TrackOff:		ds 2	;$C5DE
TrackDat:		ds 2	;$C5E0