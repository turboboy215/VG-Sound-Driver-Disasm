;Speedball 2: Brutal Deluxe audio disassembly
;Original audio & code by Martin Walker
;Disassembly by Will Trowbridge
;Referenced from Martin Walker 1994 sound engine source code.

include "HARDWARE.INC"

def AudioROM equ $4000
def AudioRAM equ $DE00
def WaveRAM equ $FF30
def RAMSize equ $100
def ChanRAMSize equ $38

SECTION "Audio", ROMX[AudioROM], BANK[$1]

	jp InitSound


	jp SendSFX


	jp SendMus


	jp IntSound


;Initialize audio
InitSound:
	ld a, %10000000
	ldh [rNR52], a
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

	ld a, %00001000
	ldh [rNR10], a			;Channel 1 mode - sweep off
	ld a, %10000000
	ldh [rNR11], a			;Set up duty
	ldh [rNR21], a
	ld a, %00100000
	ldh [rNR32], a			;Set sound 3 output
	xor a
	ldh [rNR31], a			;Clear channel 3 & 4 length timer
	ldh [rNR41], a
	ld a, %01110111
	ldh [rNR50], a			;Set master volume
	ld a, %11111111
	ldh [rNR51], a			;Set panning to all
	ld a, %10001111
	ldh [rNR52], a			;Turn on all sound channels
	ret


InVec:
	bit 0, e				;If E is 1, then use second song data
	ld de, GameData_Title	;Otherwise, use first song data
	ld hl, GameTable_Title
	jr z, .InVec2

	ld de, GameData_Ingame
	ld hl, GameTable_Ingame

.InVec2
	;Load SFX data start into RAM
	ld a, e
	ld [SFXBank], a
	ld a, d
	ld [SFXBank+1], a
	
	;Then, load chunk table start address
	ld a, [hl+]				;Calculate number of sound effects from first pointer
	ld c, a					;(16 bytes per effect)
	ld a, [hl-]
	ld b, a
	ld a, c
	xor b
	and %11110000
	xor b
	swap a
	ld [NumSFX], a
	
	ld bc, VoiceBank1		;Calculate voice table address
	call StoreVar
	call StoreVar
	dec hl
	dec hl
	call StoreVar			;Calculate sequence offsets (low) address
	call StoreVar			;Calculate sequence offsets (high) address
	dec hl
	dec hl
	call StoreVar			;Calculate sequence base address
	call StoreVar			;Calculate track offsets address
	call StoreVar			;Calculate track data address
							;Calculate end data address

StoreVar:
	;Store addresses in RAM
	ld a, [hl+]
	add e
	ld e, a
	ld [bc], a
	inc bc
	ld a, [hl+]
	adc d
	ld d, a
	ld [bc], a
	inc bc
	ret


;Get SFX number from A = call number
SendSFX:
	;Is effect number greater than $80?
	cp $80
	jr nz, .SendSFX2

	;If so, then set to 0 value
	xor a
	jr .SendSFX3

.SendSFX2
	;Return if exceeds number of total effects
	ld hl, NumSFX
	cp [hl]
	ret nc

	;Check if sound effect is 4
	cp 4
	jr nz, .SendSFX4

	;If effect is 4, then effect number is $18, and channel number is 3
	ld a, $18

.SendSFX3
	ld [C3SFX], a
	xor a

.SendSFX4
	add a					;Add value to table
	ld c, a
	ld b, 0
	ld hl, GameSFX
	add hl, bc
	ld a, [hl+]				;Byte 1 = channel 1 call
	ld [C1SFX], a
	ld a, [hl]				;Byte 2 = channel 2 call
	ld [C2SFX], a
	ret


IntSound:
	call IntSFX
	call IntMusic
	ld a, [Status]
	and %10000000
	ld de, 0
	ld bc, $0100			;Channel 1
	call ExSound
	ld de, ChanRAMSize
	ld bc, $0201			;Channel 2
	call ExSound
	ld de, ChanRAMSize*2
	ld bc, $0402			;Channel 3

ExSound:
	ld hl, C1SFXChop
	add hl, de
	ld l, [hl]
	inc l
	dec l
	jr z, .ExSound2

	or b

.ExSound2
	push af
	ld a, c
	ld [CurChan], a
	call OutSound
	pop af
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
	
	add LOW(PriorTest)
	ld l, a
	adc HIGH(PriorTest)
	sub l
	ld h, a
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
	jr z, LoadSFX		;frames past

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
	ld hl, SFXBank
	ld a, b				;Get SFX number
	push af				;4 bytes each effect (part 1)
	add a
	add a
	add [hl]
	ld c, a
	inc hl
	adc [hl]
	sub c
	ld b, a
	
	ld hl, C1EnvAD
	add hl, de
	ld a, [bc]
	ld [hl+], a			;Byte 1 = envelope attack/decay - save (overwrite music)
	
	inc bc
	ld a, [bc]
	ld [hl+], a			;Byte 2 = envelope sustain/release - save (overwrite music)
	
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
	
	ld [hl], 40			;Set hold time to 40 frames
	dec hl
	ld [hl], $FF		;Set SFX channel 1 flag to FF (busy)
	
	;Now get the next 4 values from effect
	ld a, [NumSFX]
	ld l, a
	ld h, 0
	add hl, hl			;4 bytes each effect (part 2)
	add hl, hl
	push hl
	add hl, bc
	ld b, h
	ld c, l
	
	ld hl, C1Freq
	add hl, de
	ld a, [bc]			;Byte 5-6 = start frequency
	ld [hl+], a			;(load in reverse order)
	dec bc
	ld a, [bc]
	ld [hl-], a
	
	dec hl
	dec bc
	ld a, [bc]			;Byte 7 = wave suspend/release		
	ld [hl-], a
	
	dec bc
	ld a, [bc]			;Byte 8 = wave attack/decay
	ld [hl], a
	
	;And now go to the next section...
	pop hl
	push hl
	add hl, bc
	ld b, h
	ld c, l
	ld hl, C1BendType
	add hl, de
	ld a, [bc]			;Byte 9 = bend type (0-9)
	ld [hl+], a
	
	inc bc
	inc hl
	ld a, [bc]			;Byte 10-11 = bend
	ld [hl-], a			;(load in reverse order)
	inc bc
	ld a, [bc]
	ld [hl], a
	
	;And the next and last section...
	pop hl
	add hl, bc
	ld b, h
	ld c, l
	dec bc
	ld hl, C1SFXExtra
	add hl, de
	ld a, [bc]			;Byte 12 = special event
	ld [hl+], a
	
	inc bc
	ld a, [bc]
	ld [hl+], a			;Byte 13 = special counter - save to Countdown
	ld [hl+], a			;And to CountVal
	
	inc bc				;Byte 14 = special frequency
	ld a, [bc]
	ld [hl+], a
	inc hl				;Skip Priority (RAM value)
	ld [hl], $FF		;Set direction flag to FF
	
	pop af				;Check if effect number is $18
	cp $18
	ret nz

	;If effect number is $18, then set special parameters
	ld hl, C1SFXChop
	add hl, de
	ld [hl], $A0
	inc hl
	inc hl
	res 0, [hl]
	ld hl, C1AtkHold
	add hl, de
	ld [hl], $32
	ld hl, C1EnvSR
	add hl, de
	ld [hl], $0C
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
	dec [hl]

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
	srl c				;(Swap frequency lo/hi)
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
	ret nc

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
	ret


OutSound:
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
	ld e, [hl]			;Now add and load frequency low/high values into DE
	inc hl
	add [hl]
	ld d, a
	
	ld a, b				;Load current waveform into A
	ld bc, $0F			;Now load envelope value into HL
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

	cp $FF				;Check for any other noise
	jr nz, .Noise2		;If so, then leave noise channel alone

.Noise_Eff				;No noise used so far...
	ld a, c				;So this channel will use noise.
	ld [NoiseChan], a

.Noise2					;Check if this channel is used for noise
	cp c
	jr nz, .Pulse		;If not, then skip to pulse

	;Otherwise, there is noise
	ld a, d				;A = Multiply upper frequency by 1.5
	srl a
	add d
	
	push bc
	push de
	push hl				;H was attack/decay value (current waveform)/L was envelope value
	ld b, l
	;H = maximum multiplies, L = minimum value with trigger
	ld hl, $0A40
	jr .Noise4

.Noise3
	;Keep multiplying A, increasing frequency until carry
	inc l
	add a

.Noise4
	jr c, .Noise5

	dec h
	jr nz, .Noise3

.Noise5
	;Swap nybbles of L to get final frequency
	swap l
	;Set channel = 4
	ld c, 3
	ld h, 0
	;Output noise frequency
	call SetFreq
	jr .EndNoise

.NoNoise
	cp c				;If noise bit is off in this channel
	jr nz, .Pulse		;But noise in another channel

	push bc				;No noise and this was noise channel
	push de
	push hl
	call NoiseSwitchOff	;So switch off noise

.EndNoise				;Restore previous register values
	pop hl
	pop de
	pop bc

.Pulse
	ld a, h				;Load current waveform into A
	and %01110000		;Check for pulse wave
	jr z, FreqOff		;No other waveforms (set frequency to 0)

	push bc				;Otherwise, calculate frequency
	push hl
	ld bc, $8DEF		;Starting value/fixed-point scaling/bias
	ld hl, $21			;Minimum threshold
	ld a, l
	sub e
	ld a, h
	sbc d
	jr nc, .Pulse2		;If silence (zero/negative value)

	sla c				;Divide by 2
	rl b
	call FreqDiv		;Divide threshold by frequency
	ld e, c
	ld a, 8
	add b				;Add 8 to high byte of frequency value (trigger on)
	ld d, a
	jr c, .Pulse3

	ld de, 0			;If frequency is negative, then set to 0

.Pulse3
	pop hl				;Restore original noise values
	pop bc
	ld b, l				;Copy upper envelope value to B and frequency to HL
	ld l, e
	ld h, d
	jr SetFreq			;Output the frequencies

.Pulse2
	pop hl
	pop bc

.NoVolume:
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
	ld a, [bc]			;Otherwise, get NRx2 envelope
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
	
	ldh [WaveRAM], a	;Initialize waveform
	ldh [WaveRAM+1], a
	ldh [WaveRAM+2], a
	ldh [WaveRAM+3], a
	ldh [WaveRAM+8], a
	ldh [WaveRAM+9], a
	ldh [WaveRAM+10], a
	ldh [WaveRAM+11], a
	ld a, %10000000
	ldh [rNR30], a		;Turn sound 3 on
	jr SetInit			;Now restart sound

FreqDiv:
	ld a, 16			;Bit-by-bit division
	rl l				;Divide HL value by DE - scale by about 2 first
	rl h

.FreqDiv2
	push af
	ld a, l
	sub e
	ld l, a
	ld a, h
	sbc d
	ld h, a
	jr nc, .FreqDiv3

	add hl, de

.FreqDiv3				;BC = quotient, HL = remainder
	rl c
	rl b
	rl l
	rl h
	pop af
	dec a
	jr nz, .FreqDiv2

	ld a, l
	sub e
	ld a, h
	sbc d
	ret c

	dec bc
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
	
	cp $F8				;Maximum volume for this voice (248)
	ret c				;Return if not reached peak yet

.Env_Atk2
	ld hl, $F800		;Set to maximum volume
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


;A = Envelope attack/decay (gate on) OR envelope sustain/release (gate off)
ExEnvF:
	push de				;Save channel offset
	ld hl, C1EnvVal
	add hl, de
	push hl
	ld e, [hl]			;Get envelope value
	inc hl
	ld h, [hl]
	ld l, e			;Set HL to envelope value (word)
	
	call ExEnv
	pop de
	ld a, l
	ld [de], a
	inc de
	ld a, h
	ld [de], a
	pop de
	ret


SendMus:
	bit 7, a			;Enter with A = song number or ($80 + fader count)
	jr z, .SendMus2

	and %01111111		;Negative value = fade  value
	ld [Fader], a
	ret					;Nothing this time, so return


;Load song pointers from offset
.SendMus2
	add a
	add a
	add a
	add a				;Multiply by 16 - 16 bytes per track
	ld hl, TrackOff		;Get pointer for this music data
	add [hl]			;Add low byte of track offset
	ld e, a				;Save low byte of final address
	inc hl
	adc [hl]			;Add carry to high byte
	sub e				;Subtract low byte
	ld h, a				;Save high byte of final address
	ld l, e
	ld a, [hl+]
	ld [C1Track], a
	ld a, [hl+]
	ld [C2Track], a
	ld a, [hl+]
	ld [C3Track], a
	ld a, [hl+]
	ld [C1Track+1], a
	ld a, [hl+]
	ld [C2Track+1], a
	ld a, [hl+]
	ld [C3Track+1], a
						;Skip 2 bytes
	inc hl
	inc hl
	
	;Copy tick speed step values to RAM
	ld de, Ticks
	ld b, 8

.SendMus3
	ld a, [hl+]
	ld [de], a
	inc de
	dec b
	jr nz, .SendMus3

	ld de, 0
	ld b, 3				;3 channels

.SendMus4
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
	ld hl, C1VoiceNum
	add hl, de
	ld [hl], $FF
	;Also track step
	ld hl, C1TrackStep
	add hl, de
	ld [hl], $FF
	;Now read track
	call ReadTrack
	;Repeat for all 3 channels
	ld hl, ChanRAMSize
	add hl, de
	ld d, h
	ld e, l
	pop bc
	dec b
	jr nz, .SendMus4

	;Set fade count and global transpose to 0
	xor a
	ld [TempoFlag], a
	ld [FadeCnt], a
	dec a
	;Set fade and more to FF
	ld [Fader], a
	ld [Status], a
	ld a, %00010000
	;Set volume
	ld [Volume], a
	;Set master volume to maximum
	ld a, %01110111			;Maximum value for both left and right
	ldh [rNR50], a
	ret


;Get parameter from voice
;Enter with A = parameter - 00-0F
;Exit with A = voice data byte required
;BC = address of voice data byte
GetVoice:
	push hl
	ld hl, C1VoiceOffset
	add hl, de
	add [hl]			;Offset for current voice 0000-01F0
	pop hl				;Point to voice bank data
	add [hl]
	ld c, a				;C = Low byte of address required
	inc hl
	adc [hl]
	sub c
	ld b, a				;B = High byte of address required
	ld a, [bc]			;Load required voice byte into A
	ret


IntMusic:
	;Check status value
	ld a, [Status]
	rla
	ret nc

	;Then check fader value
	ld a, [Fader]
	bit 7, a
	jr nz, Music1

	ld hl, FadeCnt			;Decrement fade
	dec [hl]
	bit 7, [hl]				;Check if still $80 or more
	jr z, Music1

	ld [hl], a				;Save fader value back into fade count
	ld hl, Volume			;End of fade count, so decrease volume
	dec [hl]				;If volume is 0, then stop track
	jr z, TrackStop			;End of fade

	ld a, [hl]				;Otherwise, put into volume control
	srl a
	cp $08					;If left nybble is above 8, then set to 7
	jr c, .IntMusic2

	ld a, $07

.IntMusic2
	ld c, a
	swap a
	or c
	ldh [rNR50], a

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

	ld hl, C1Dur		;Decrease duration remaining
	add hl, de
	dec [hl]
	jp nz, Treatment	;If not done yet, then...

	ld hl, C1SeqNum		;Otherwise, check next sequence number in track
	add hl, de
	ld a, [hl-]			;HL now holds SeqStep
	cp $FE				;Is it FE (loop)?
	jr c, SeqRead		;If less, then read next sequence value

	jr nz, TrackLoop

;If higher (FF), then it is a stop command
TrackStop:
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
	ld c, a				;A = sequence number
	ld b, 0
	ld a, [SeqOffLo]	;Get low byte of offset (low bytes) table address
	add c				;Add sequence number * 2
	ld l, a				;Store result, low
	ld a, [SeqOffLo+1]	;Now get high byte of offset (low bytes) table address
	adc b				;Add carry only
	ld h, a				;HL points to table (low bytes) offset
	ld a, [SeqDat]		;Get low byte of sequence data address
	add [hl]			;Add low byte offset for this sequence
	push af				;Save final low value
	ld a, [SeqOffHi]	;Now get low byte of offset (high bytes) table address
	add c				;Add sequence number * 2
	ld l, a				;Store result, low
	ld a, [SeqOffHi+1]	;Now get high byte of offset (high bytes) table address
	adc b				;Add carry only
	ld h, a				;HL points to table (high bytes) offset
	pop af				;Restore low value
	ld c, a				;And store in C
	ld a, [SeqDat+1]	;Get high value of sequence data address
	adc [hl]			;And add carry only
	ld b, a				;BC is now the address of 1st byte in sequence
	
	ld hl, C1SeqStep
	add hl, de
	ld a, [hl]			;Get sequence step for this channel
	add c
	ld c, a
	adc b
	sub c
	ld b, a				;BC is now the address of the sequence
	
	ld a, $FF			;Set voice temp variable to FF
	ld [VoiceTemp], a
	push hl
	ld hl, C1GateMask
	add hl, de
	ld [hl], a			;Set gate mask to FF
	ld a, [bc]			;Get next sequence byte
	ld hl, C1NoteLen	;Store in RAM
	add hl, de
	ld [hl+], a
	push af
	and %00111111		;Lower 6 bits = duration
	ld [hl], a			;Store in duration variable
	ld hl, C1BendByte	;Set bend and attack end to 0
	add hl, de
	ld [hl], 0
	ld hl, C1AtkEnd
	add hl, de
	ld [hl], 0
	
EventRest:
	pop af
	bit 6, a			;Check for bit 6 = rest
	jr z, EventVoice

	;Turn off gate mask
	inc hl
	inc hl
	ld [hl], %11111110	;Release and fade

EventVoice:
	pop hl
	bit 7, a			
	jr z, NoteRead	;Check for bit 7

	;Increment sequence step and get parameter (next byte)
	inc bc
	inc [hl]
	ld a, [bc]
	;If bit 7 of parameter is off, then is voice change
	bit 7, a
	;Otherwise, is a pitch bend
	jr nz, EventBend

	;Set temporary voice variable to parameter
	ld [VoiceTemp], a
	jr NoteRead

EventBend:
	;Load parameter into pitch bend byte variable
	push hl
	ld hl, C1BendByte
	add hl, de
	ld [hl], a
	pop hl

NoteRead:
	;Read note value
	inc bc		
	inc [hl]			;Get note value from next byte
	ld a, [bc]
	ld hl, C1TiedNote
	add hl, de
	ld [hl-], a			;High byte of note
	and %01111111
	push hl
	ld hl, C1NoteVal	;Get frequency value from table for this note
	add hl, de
	ld [hl], a
	pop hl				;Restore C1Note address
	push bc
	add a				;Get high byte
	add LOW(NoteTab+1)
	ld c, a
	adc HIGH(NoteTab+1)
	sub c
	ld b, a
	ld a, [bc]
	ld [hl-], a			;Save high byte of note frequency
	dec bc
	ld a, [bc]
	ld [hl], a			;Save low byte of note
	
	ld hl, C1VoiceMute
	add hl, de
	bit 7, [hl]
	jr z, NewStart		;If there are no sound effects, then play note

	ld hl, C1SFXHold	;Otherwise, if there are still effects...
	add hl, de			;Check hold
	ld a, [hl]
	and a
	jr nz, NewStart		;If still in critical position, then play note

	ld hl, C1TiedNote	;If past critical portion, then force tie off first
	add hl, de
	ld [hl], a

;Start a new note
NewStart:
	ld a, [VoiceTemp]	;Get temporary voice from command if present
	bit 7, a
	jr nz, ModRead		;If FF, then no new voice

	ld hl, C1VoiceNum
	add hl, de
	cp [hl]				;Check current channel voice
	jr z, ModRead		;If voice is the same, then ignore

	ld [hl], a			;Otherwise, load new voice
	ld hl, C1TiedNote	;Also force envelope restart
	add hl, de
	ld [hl], a

ModRead:
	ld hl, C1TiedNote	;Get tied note status
	add hl, de
	bit 7, [hl]
	jr nz, ReadEnd		;If tied note, then ignore new mods

	;Get voice number
	ld hl, C1VoiceNum
	add hl, de
	;Get address to add to voice table
	ld a, [hl]
	add a				;8 bytes each voice
	add a
	add a
	ld hl, C1VoiceOffset
	add hl, de
	ld [hl], a			;Save offset to this voice
	ld hl, VoiceBank1
	
	xor a
	;Now load parameters from voice
	call GetVoice		;Byte 1 = attack time (00-0F)/decay time (00-0F)
	ld [ADTemp], a
	inc bc
	ld a, [bc]			;Byte 2 = sustain (00-0F)/release (00-0F)
	ld [SRTemp], a
	inc bc
	ld a, [bc]			;Byte 3 = waveform
	ld hl, C1NoteCtrl
	add hl, de
	ld [hl], a
	inc bc
	ld a, [bc]			;Byte 4 = specials
	ld hl, C1Special
	add hl, de
	ld [hl+], a
	inc bc				;Byte 5-7 = (unused)
	inc bc
	inc bc
	inc bc
	ld a, [bc]			;Byte 8 = used by chord/attack wave/attack note specials - attack count
	ld [hl], a
	ld hl, VoiceBank2
	ld a, 7				;Vibrato delay
	call GetVoice
	ld hl, C1VibDelay
	add hl, de
	ld [hl], a

	ld hl, C1SFXHold	;Check if any sound effects are on
	add hl, de
	ld a, [hl]
	and a
	jr nz, ReadEnd		;If so, then ignore

	ld hl, C1VoiceMute
	add hl, de
	ld [hl], a			;Otherwise, clear any mute
	ld hl, C1EnvAD
	add hl, de
	ld a, [ADTemp]
	ld [hl+], a			;Transfer temporary attack/delay value to channel envelope value
	ld a, [SRTemp]
	ld [hl], a			;Transfer temporary sustain/release value to channel envelope value

ReadEnd:
	pop bc
	inc bc
	ld hl, C1SeqStep	;End of sequence
	add hl, de			;Increase sequence step
	inc [hl]
	ld a, [bc]			;Look at next byte of sequence
	inc a				;$FF - end of sequence to $00
	jr nz, ReadExit		;If not 0, then continue

	ld [hl+], a			;Sequence step value is now reset to 0
	inc hl				;Get track sequence repeat
	dec [hl]			;Decrease value
	call z, ReadTrack	;If repeat is 0, then continue track

ReadExit:				;Otherwise, check if sound effect is playing
	ld hl, C1VoiceMute
	add hl, de
	ld a, [hl]
	and a
	jp nz, NextChan		;If sound effect is playing, then skip to next channel

	;Otherwise, set up vibrato
	ld hl, C1SpecNtUp		;Set special note value to 0
	add hl, de
	ld [hl], a
	push hl
	ld hl, C1VibSpeed	;Also set vibrato speed to 0
	add hl, de
	ld [hl], a
	pop hl
	dec hl
	dec hl
	ld c, [hl]			;Now load special value from RAM
	inc hl
	jp Spec10			;And perform effect


Treatment:
	ld hl, C1VoiceMute	;Check if sound effect is playing
	add hl, de
	bit 7, [hl]
	jp nz, NextChan		;If so, then skip to next channel

;Process channel vibrato
Vibrato:
	ld hl, C1VibDelay	;Otherwise, check vibrato
	add hl, de			;Is vibrato delay finished?
	ld a, [hl]
	and a				;If so, then continue
	jr z, .Vibrato2

	dec [hl]			;Otherwise, decrease vibrato and check pitch bend
	jp Bending


.Vibrato2
	ld hl, C1SpecNtDn		;Check if vibrato effect is used
	add hl, de
	or [hl]				;If not, then skip to pitch bending
	jp nz, Bending

	ld hl, VoiceBank2
	ld a, 6				;Otherwise, then load vibrato parameter
	call GetVoice
	and a
	jp z, Bending		;If 0, then skip to pitch bending

	ld c, a				;Otherwise, continue
	ld hl, C1VibSpeed	;Get vibrato speed
	add hl, de
	bit 7, [hl]
	jr nz, .Vibrato4

	ld b, 0				;Load vibrato sequence length from table
	ld hl, VibTab1
	add hl, bc
	ld a, [hl]
	ld hl, C1VibLimit
	add hl, de
	ld [hl-], a
	xor a
	ld [hl-], a			;Also clear vibrato step and direction values
	ld [hl-], a
	push hl
	ld hl, VibTab2
	add hl, bc
	ld a, [hl]			;Load current vibrato value from sequence
	pop hl
	ld [hl], a

	ld hl, C1NoteVal	;Load current channel note value
	add hl, de
	ld a, [hl]			;Get note frequency from table
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
	ld hl, C1Note		;Load this value into RAM
	add hl, de
	ld [hl], c
	inc hl
	ld [hl], b
	pop hl
	ld a, [hl+]			;Then, subtract vibrato from note in table to get vibrato increase amount
	sub c
	ld c, a
	ld a, [hl]
	sbc b
	ld b, a
	ld hl, C1VibInc		;Load that value in vibrato increase area
	add hl, de
	ld [hl], c
	inc hl
	ld [hl], b

.VibLoop1
	ld hl, C1VibSpeed	;Decrease vibrato speed
	add hl, de
	dec [hl]
	bit 7, [hl]			;If not done with speed, then skip to pitch bending
	jr nz, Bending

	ld hl, C1VibInc+1	;Otherwise, continue process vibrato increase
	add hl, de
	srl [hl]
	dec hl
	rr [hl]
	jr .VibLoop1

.Vibrato4
	ld hl, C1FreqDir	;Get channel 1 frequency direction
	add hl, de
	bit 7, [hl]			;Check if positive or negative
	ld hl, C1VibInc		;Load vibrato increase offset in HL
	add hl, de
	jr nz, .Vibrato5	;If negative, then go to negative section

	ld a, [hl+]			;Otherwise, add (positive)
	ld b, [hl]
	inc hl
	add [hl]
	ld [hl+], a
	ld a, b
	adc [hl]
	jr .Vibrato6

.Vibrato5				;Subtract (negative)
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
	ld hl, C1VibDir		;Check if vibrato direction is positive or negative
	add hl, de
	bit 7, [hl]
	inc hl
	jr nz, .Vibrato7	;If negative, then decrease step

	inc [hl]			;Otherwise, increase step
	ld a, [hl+]			;Then check step value
	cp [hl]				;If less than direction value, then skip to pitch bending
	jr c, Bending

	dec hl				;Otherwise, then reset vibrato delay
	dec hl
	ld [hl], $FF
	dec hl
	dec hl
	dec hl
	ld a, [hl]			;Then check gate value
	cpl
	ld [hl], a			;Invert value
	jr Bending

.Vibrato7
	dec [hl]			;Decrease step
	jr nz, Bending		;If not 0, then skip to pitch bending

	dec hl				;Otherwise, set direction to 0
	ld [hl], 0

Bending:
	ld hl, C1BendByte	;Check bending value
	add hl, de
	ld a, [hl]
	and a				;If 0, then skip to specials
	jr z, Specials

	cp $C0				;Otherwise, check direction
	jr c, .Bending2

	and %00111111		;If bend up, then add pitch frequency from lower 6 bits to note
	ld hl, C1Note
	add hl, de
	add [hl]
	ld [hl+], a
	jr nc, Specials

	inc [hl]
	jr Specials

.Bending2
	and %00111111		;If bend down, then subtract lower 6 bits
	ld c, a
	ld hl, C1Note
	add hl, de
	ld a, [hl]
	sub c
	ld [hl+], a
	jr nc, Specials

	dec [hl]

Specials:
	ld hl, C1Special	;Now get special value
	add hl, de
	ld c, [hl]
	inc hl
	inc hl
	bit 1, c			;First, check for trill note
	jr z, Spec04		;If no trill, then look for other values

	push bc				;Otherwise, get special note up value
	push hl
	bit 0, [hl]			;Check if bit set
	jr nz, .Spec02B

	ld hl, C1NoteVal
	add hl, de
	ld a, [hl]
	jr .Spec02C

.Spec02B
	ld hl, VoiceBank2	;Otherwise, get trill note value from voice
	ld a, 5
	call GetVoice
	bit 7, a			;Check if signed/unsigned
	jr z, .Spec02C

	and %01111111		;If signed (negative), then convert to unsigned and add to note
	ld hl, C1NoteVal
	add hl, de
	add [hl]

.Spec02C
	add a				;Add to note frequency value
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
	bit 2, c			;Now check for drum
	jr z, Spec08		;If no drum, then skip to chord

	push bc				;Otherwise, get special note up value
	push hl
	bit 0, [hl]			;Check if bit set
	jr nz, .Spec04B		;If 0, then load 81

	ld hl, VoiceBank1	;Otherwise, get waveform byte from voice
	ld a, 2
	call GetVoice
	jr .Spec04C

.Spec04B
	ld a, $81

.Spec04C
	ld hl, C1NoteCtrl	;Switch between noise/normal waveform alternately
	add hl, de
	ld [hl], a
	ld hl, C1NoteLen	;Then, get note length from lower 6 bits
	add hl, de
	ld a, [hl]
	and %00111111
	sub $02				;If length is 2 or more, then gate off
	ld hl, C1Dur
	add hl, de
	cp [hl]
	jr c, .Spec04D

	ld hl, C1GateMask
	add hl, de
	ld [hl], %11111110

.Spec04D
	ld hl, C1Note+1		;Decrease note frequency (frequency decay)
	add hl, de
	dec [hl]
	bit 7, [hl]			;And check trigger bit
	jr z, .Spec04E

	inc [hl]			;If bit set, then increase note by 1

.Spec04E
	pop hl				;Now get special note up value
	pop bc

Spec08:
	bit 3, c			;Now check for chord
	jr z, .Spec08B		;If no chord, then decrease special note value

	ld a, [hl]			;Isolate chord bits
	and %00000011
	jr Spec20A

.Spec08B
	dec hl

Spec10:
	bit 4, c			;Now check for attack bend
	jr z, Spec20		;If no attack bend, then skip to attack note

	push bc				;Get special note down value
	push hl
	ld a, [hl]			;If not 0, then get attack wave value from voice
	and a
	jr z, .Spec10B

	xor a
	ld hl, VoiceBank2
	jr .Spec10C

.Spec10B
	ld hl, C1AtkEnd		;Otherwise, check attack end value - 1 frame after attack
	add hl, de
	bit 7, [hl]			;If positive, then get waveform byte from voice
	jr nz, .Spec10D

	ld a, 2
	ld hl, VoiceBank1

.Spec10C
	call GetVoice
	ld hl, C1NoteCtrl
	add hl, de
	ld [hl], a

.Spec10D
	pop hl
	pop bc

Spec20:
	bit 5, c			;Now check for attack note
	jr z, FinalBit		;If no attack note, then go to final bit

	ld a, [hl+]			;Otherwise, get special note up
	and a
	jr z, Spec20C

	ld a, [hl]

Spec20A:
	inc a				;Get chord note to note value from voice
	ld hl, VoiceBank2
	call GetVoice
	ld hl, C1NoteVal
	add hl, de
	bit 7, a			;If high bit not set, then skip process
	jr z, Spec20D

	and %01111111		;Otherwise, get lower 7 bits
	cp $40				;Check if positive/negative value and add/subtract accordingly
	jr nc, Spec20B

	add [hl]
	jr Spec20D

Spec20B:
	and %00111111
	ld c, a
	ld a, [hl]
	sub c
	jr Spec20D

Spec20C:				;1 frame after attack
	ld hl, C1AtkEnd
	add hl, de
	bit 7, [hl]
	jr nz, FinalBit

	ld hl, C1NoteVal	;If bit is 0, then restore proper note
	add hl, de
	ld a, [hl]

Spec20D:
	add a				;Now add value to note frequency
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

FinalBit:				;Final part: check if note is tied
	ld hl, C1TiedNote
	add hl, de
	bit 7, [hl]
	jr nz, .FinalBit2	;If so, then set note control to $FF

	ld hl, C1SpecNtUp		;Otherwise, load special note up value
	add hl, de
	ld a, [hl]
	and a				;Set channel flags only
	jr nz, .FinalBit2	;If not 0, then all channels are masked on

	ld a, $FE			;Otherwise, then set note control to $FE
	jr .FinalBit3

.FinalBit2
	ld a, $FF

.FinalBit3
	ld hl, C1NoteCtrl	;Mask value with note control and gate mask
	add hl, de
	and [hl]
	ld hl, C1GateMask
	add hl, de
	and [hl]
	ld hl, C1AttDec
	add hl, de
	ld [hl], a

	ld hl, C1Note		;Transfer note (music data)...
	add hl, de
	ld c, [hl]
	inc hl
	ld b, [hl]
	ld hl, C1Freq		;...to frequency (overwrites sound effects data)
	add hl, de
	ld [hl], c
	inc hl
	ld [hl], b
	
	ld hl, C1SpecNtDn		;Also mask value with special note down value
	add hl, de
	ld a, [hl]
	and a
	jr nz, .FinalBit4	;If not 0, then decrease value first

	push hl				;Otherwise, turn on attack end
	ld hl, C1AtkEnd
	add hl, de
	ld [hl], $FF
	pop hl
	jr .FinalBit5

.FinalBit4
	dec [hl]

.FinalBit5				;Increase special note up value
	inc hl
	inc [hl]

NextChan:
	ld hl, ChanRAMSize	;Get next channel's RAM
	add hl, de
	ld d, h
	ld e, l
	ld hl, CurChan
	inc [hl]			;Increase channel number
	ld a, [hl]
	cp 3				;If less than maximum channels, then process next channel
	jp c, MusicLoop

	ld hl, TempoFlag	;Now check tempo flag
	dec [hl]			;If above 0, then return
	bit 7, [hl]
	ret z

	inc hl				;Otherwise, then decrease control number
	dec [hl]
	bit 7, [hl]			;If down from 0, then reset to maximum (7)
	jr z, GetTicks

	ld [hl], 7

GetTicks:
	ld a, [hl]			;Get current tempo tick value per 1-8
	add LOW(Ticks)
	ld c, a
	adc HIGH(Ticks)
	sub c
	ld b, a
	ld a, [bc]
	dec hl				;Load value into control flag
	ld [hl], a
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


;Envelope times
ADRTab:
	dw 61440, 61440, 30720, 15360
	dw 10240, 7680, 6144, 5120
	dw 4096, 1661, 842, 526
	dw 418, 140, 84, 53
	
GameTable_Title:
 	dw $0000
	dw $0070
	dw $002B
	dw $04B3
	dw $0020
	dw $00FA

GameTable_Ingame:
	dw $0300
	dw $0030
 	dw $0007
	dw $00CF
	dw $0020
	dw $0018

GameSFX:
	db $00, $00
	db $14, $15
	db $0C, $0D
	db $09, $00
	db $00, $00
	db $01, $02
	db $1B, $00
	db $10, $11
	db $2E, $2F
	db $19, $00
	db $29, $2B
	db $05, $00
	db $29, $2A
	db $29, $2B
	db $23, $00
	db $1C, $00
	db $1D, $00
	db $00, $00
	db $24, $00
	db $1F, $00
	db $20, $00
	db $21, $00
	db $1A, $00
	db $25, $00
	db $28, $00
	db $26, $00
	db $05, $00
	db $16, $17
	db $22, $00
	db $0E, $0F
	db $27, $00
	db $05, $00
	db $03, $00
	db $04, $00
	db $05, $00
	db $27, $00
	db $05, $00
	db $1E, $00
	db $12, $13
	db $07, $08

VibTab1:
	db 0, 1, 1, 1, 1, 4, 3, 2
	db 4, 3, 2, 1, 3, 2, 1, 3
	db 2, 2, 1

VibTab2:
	db 0, 5, 4, 3, 2, 5, 5, 4
	db 4, 4, 3, 1, 3, 2, 0, 1
	db 1, 0, 0

NoteTab:
	dw $0116
	dw $0126
	dw $0138
	dw $014A
	dw $015D
	dw $0173
	dw $0189
	dw $01A0
	dw $01B9
 	dw $01D4
	dw $01EF
	dw $020D
	dw $022C
	dw $024D
	dw $0270
	dw $0295
	dw $02BC
 	dw $02E7
	dw $0312
	dw $0341
	dw $0373
	dw $03A8
	dw $03DF
	dw $041A
	dw $0458
 	dw $049B
	dw $04E1
	dw $052B
	dw $057A
	dw $05CE
	dw $0626
	dw $0684
	dw $06E7
 	dw $0750
	dw $07BF
	dw $0836
	dw $08B2
	dw $0937
	dw $09C3
	dw $0A58
	dw $0AF5
 	dw $0B9C
	dw $0C4D
	dw $0D09
	dw $0DCF
	dw $0EA1
	dw $0F80
	dw $106C
	dw $1166
 	dw $126F
	dw $1388
	dw $14B1
	dw $15EC
	dw $1739
	dw $189B
	dw $1A12
	dw $1B9F
 	dw $1D43
	dw $1F01
	dw $20D9
	dw $22CD
	dw $24DF
	dw $2710
	dw $2963
	dw $2BD9
 	dw $2E74
	dw $3138
	dw $3425
	dw $373F
	dw $3A88
	dw $3E03
	dw $41B3
	dw $459C
 	dw $49BF
	dw $4E21
	dw $52C7
	dw $57B3
	dw $5CEA
	dw $6271
	dw $684B
	dw $6E7F
 	dw $7511
	dw $7C07
	dw $8367
	dw $8B38
	dw $937F
	dw $9C45
	dw $A58F
	dw $AF67
 	dw $B9D5
	dw $C4E3
	dw $D097
	dw $DCFF
	dw $EA23
	dw $F80F
	dw $FFCF

GameData_Title:
	incbin "TITLE.SND"

GameData_Ingame:
	incbin "INGAME.SND"

SECTION "Audio RAM", WRAMX[AudioRAM]

C1SFX:			ds 1	;$DE00
C1SFXHold:		ds 1	;$DE01
C1SFXChop:		ds 1	;$DE02
C1AttDec:		ds 1	;$DE03
C1SusRel:		ds 1	;$DE04
C1Freq:			ds 2	;$DE05
C1BendType:		ds 1	;$DE07
C1Bend:			ds 2	;$DE08
C1SFXExtra:		ds 1	;$DE0A
C1Countdown:	ds 1	;$DE0B
C1CountVal:		ds 1	;$DE0C
C1NewVal:		ds 1	;$DE0D
C1Priority:		ds 1	;$DE0E
C1DirFlag:		ds 1	;$DE0F
C1EnvAD:		ds 1	;$DE10
C1EnvSR:		ds 1	;$DE11
C1AtkHold:		ds 1	;$DE12
C1EnvSeq:		ds 1	;$DE13
C1EnvVal:		ds 2	;$DE14
C1FreqOff:		ds 1	;$DE16
C1Track:		ds 2	;$DE17
C1VoiceOffset:	ds 1	;$DE19
C1TrackStep:	ds 1	;$DE1A
C1LoopFlag:		ds 1	;$DE1B
C1LoopCtrl:		ds 1	;$DE1C
C1LoopMem:		ds 1	;$DE1D
C1SeqStep:		ds 1	;$DE1E
C1SeqNum:		ds 1	;$DE1F
C1SeqRepeat:	ds 1	;$DE20
C1NoteLen:		ds 1	;$DE21
C1Dur:			ds 1	;$DE22
C1NoteCtrl:		ds 1	;$DE23
C1NoteVal:		ds 1	;$DE24
C1AtkEnd:		ds 1	;$DE25
C1VoiceNum:		ds 1	;$DE26
C1GateMask:		ds 1	;$DE27
C1BendByte:		ds 1	;$DE28
C1FreqDir:		ds 1	;$DE29
C1VibDelay:		ds 1	;$DE2A
C1VibSpeed:		ds 1	;$DE2B
C1VibDir:		ds 1	;$DE2C
C1VibStep:		ds 1	;$DE2D
C1VibLimit:		ds 1	;$DE2E
C1VibInc:		ds 2	;$DE2F
C1Note:			ds 2	;$DE31
C1TiedNote:		ds 1	;$DE33
C1Special:		ds 1	;$DE34
C1SpecNtDn:		ds 1	;$DE35
C1SpecNtUp:		ds 1	;$DE36
C1VoiceMute:	ds 1	;$DE37

C2SFX:			ds 1	;$DE38
C2SFXHold:		ds 1	;$DE39
C2SFXChop:		ds 1	;$DE3A
C2AttDec:		ds 1	;$DE3B
C2SusRel:		ds 1	;$DE3C
C2Freq:			ds 2	;$DE3D
C2BendType:		ds 1	;$DE3F
C2Bend:			ds 2	;$DE40
C2SFXExtra:		ds 1	;$DE42
C2Countdown:	ds 1	;$DE43
C2CountVal:		ds 1	;$DE44
C2NewVal:		ds 1	;$DE45
C2Priority:		ds 1	;$DE46
C2DirFlag:		ds 1	;$DE47
C2EnvAD:		ds 1	;$DE48
C2EnvSR:		ds 1	;$DE49
C2AtkHold:		ds 1	;$DE4A
C2EnvSeq:		ds 1	;$DE4B
C2EnvVal:		ds 2	;$DE4C
C2FreqOff:		ds 1	;$DE4E
C2Track:		ds 2	;$DE4F
C2VoiceOffset:	ds 1	;$DE51
C2TrackStep:	ds 1	;$DE52
C2LoopFlag:		ds 1	;$DE53
C2LoopCtrl:		ds 1	;$DE54
C2LoopMem:		ds 1	;$DE55
C2SeqStep:		ds 1	;$DE56
C2SeqNum:		ds 1	;$DE57
C2SeqRepeat:	ds 1	;$DE58
C2NoteLen:		ds 1	;$DE59
C2Dur:			ds 1	;$DE5A
C2NoteCtrl:		ds 1	;$DE5B
C2NoteVal:		ds 1	;$DE5C
C2AtkEnd:		ds 1	;$DE5D
C2VoiceNum:		ds 1	;$DE5E
C2GateMask:		ds 1	;$DE5F
C2BendByte:		ds 1	;$DE60
C2FreqDir:		ds 1	;$DE61
C2VibDelay:		ds 1	;$DE62
C2VibSpeed:		ds 1	;$DE63
C2VibDir:		ds 1	;$DE64
C2VibStep:		ds 1	;$DE65
C2VibLimit:		ds 1	;$DE66
C2VibInc:		ds 2	;$DE67
C2Note:			ds 2	;$DE69
C2TiedNote:		ds 1	;$DE6B
C2Special:		ds 1	;$DE6C
C2SpecNtDn:		ds 1	;$DE6D
C2SpecNtUp:		ds 1	;$DE6E
C2VoiceMute:	ds 1	;$DE6F

C3SFX:			ds 1	;$DE70
C3SFXHold:		ds 1	;$DE71
C3SFXChop:		ds 1	;$DE72
C3AttDec:		ds 1	;$DE73
C3SusRel:		ds 1	;$DE74
C3Freq:			ds 2	;$DE75
C3BendType:		ds 1	;$DE77
C3Bend:			ds 2	;$DE78
C3SFXExtra:		ds 1	;$DE7A
C3Countdown:	ds 1	;$DE7B
C3CountVal:		ds 1	;$DE7C
C3NewVal:		ds 1	;$DE7D
C3Priority:		ds 1	;$DE7E
C3DirFlag:		ds 1	;$DE7F
C3EnvAD:		ds 1	;$DE80
C3EnvSR:		ds 1	;$DE81
C3AtkHold:		ds 1	;$DE82
C3EnvSeq:		ds 1	;$DE83
C3EnvVal:		ds 2	;$DE84
C3FreqOff:		ds 1	;$DE86
C3Track:		ds 2	;$DE87
C3VoiceOffset:	ds 1	;$DE89
C3TrackStep:	ds 1	;$DE8A
C3LoopFlag:		ds 1	;$DE8B
C3LoopCtrl:		ds 1	;$DE8C
C3LoopMem:		ds 1	;$DE8D
C3SeqStep:		ds 1	;$DE8E
C3SeqNum:		ds 1	;$DE8F
C3SeqRepeat:	ds 1	;$DE90
C3NoteLen:		ds 1	;$DE91
C3Dur:			ds 1	;$DE92
C3NoteCtrl:		ds 1	;$DE93
C3NoteVal:		ds 1	;$DE94
C3AtkEnd:		ds 1	;$DE95
C3VoiceNum:		ds 1	;$DE96
C3GateMask:		ds 1	;$DE97
C3BendByte:		ds 1	;$DE98
C3FreqDir:		ds 1	;$DE99
C3VibDelay:		ds 1	;$DE9A
C3VibSpeed:		ds 1	;$DE9B
C3VibDir:		ds 1	;$DE9C
C3VibStep:		ds 1	;$DE9D
C3VibLimit:		ds 1	;$DE9E
C3VibInc:		ds 2	;$DE9F
C3Note:			ds 2	;$DEA1
C3TiedNote:		ds 1	;$DEA3
C3Special:		ds 1	;$DEA4
C3SpecNtDn:		ds 1	;$DEA5
C3SpecNtUp:		ds 1	;$DEA6
C3VoiceMute:	ds 1	;$DEA7

PriorTest:		ds 48	;$DEA8

Ticks:			ds 8	;$DED8

Fader:			ds 1	;$DEE0
Status:			ds 1	;$DEE1
Volume:			ds 1	;$DEE2
FadeCnt:		ds 1	;$DEE3
TempoFlag:		ds 1	;$DEE4
TempCtrl:		ds 1	;$DEE5
VoiceTemp:		ds 1	;$DEE6
ADTemp:			ds 1	;$DEE7
SRTemp:			ds 1	;$DEE8
NoiseChan:		ds 1	;$DEE9
CurChan:		ds 1	;$DEEA
Seed:			ds 1	;$DEEB
EnvC3:			ds 1	;$DEEC
NumSFX:			ds 1	;$DEED
SFXBank:		ds 2	;$DEEE
VoiceBank1:		ds 2	;$DEF0
VoiceBank2:		ds 2	;$DEF2
SeqOffLo:		ds 2	;$DEF4
SeqOffHi:		ds 2	;$DEF6
SeqDat:			ds 2	;$DEF8
TrackOff:		ds 2	;$DEFA
TrackDat:		ds 2	;$DEFC
EndDat:			ds 2	;$DEFE