;Mega Man: Dr. Wily's Revenge audio disassembly (bank 1)
;Disassembly by Will Trowbridge

include "HARDWARE.INC"
include "RAM.INC"

SECTION "Audio1", ROMX[AudioROM], BANK[$1]

	jp Audio1_InitAudio


	jp Audio1_CondSoundOff


	jp Audio1_LoadSound


	jp Audio1_LoadSong


	jp Audio1_GetSlot


	jp Audio1_PlayAudio


	jp Audio1_SFXOff

;Music and SFX pointers
Audio1_SoundTab:
	dw Audio1_SFX_UFO
	dw Audio1_SFX_Explode
	dw Audio1_SFX_Electricity
	dw Audio1_SFX_Shoot
	dw Audio1_SFX_EnemyShoot
	dw Audio1_SFX_PlayerHit
	dw Audio1_SFX_Click
	dw Audio1_SFX_Land
	dw Audio1_SFX_EnemyHit
	dw Audio1_SFX_Deflect
	dw Audio1_SFX_Select
	dw Audio1_SFX_Door1
	dw Audio1_SFX_Door2
	dw Audio1_SFX_CutAttack
	dw Audio1_SFX_PlayerExplode
	dw Audio1_SFX_ExtraLife
	dw Audio1_SFX_Wheel
	dw Audio1_SFX_Health
	dw Audio1_SFX_Empty1
	dw Audio1_SFX_Empty2
	dw Audio1_CutMan
	dw Audio1_IceMan
	dw Audio1_ElecMan
	dw Audio1_FireMan
	dw Audio1_Boss
	dw Audio1_Victory
	dw Audio1_SFX_IceAttack
	dw Audio1_SFX_FireAttack
	dw Audio1_SFX_ElecAttack
	dw Audio1_SFX_Block
	dw Audio1_SFX_BigEye
	dw Audio1_SFX_Empty3
	dw Audio1_SFX_Teleport
	dw Audio1_Wily1
	dw Audio1_WilyUnk
	dw Audio1_DoNotUse23
	dw Audio1_Wily2
	dw Audio1_DoNotUse25
	dw Audio1_WilyIntro
	dw Audio1_DoNotUse27
	dw Audio1_DoNotUse28
	dw Audio1_DoNotUse29
	dw Audio1_SFX_Shing
	dw Audio1_SFX_Empty4
	dw Audio1_DoNotUse2C
	dw Audio1_EndGameAlt
	dw Audio1_SFX_Heat1
	dw Audio1_SFX_Heat2
	dw Audio1_SFX_Heat3

;Clear IDs for current channel
Audio1_ClearChIDs:
	push af

.ClearChIDs2
	ld a, [hl-]
	ld [de], a
	dec de
	dec bc
	ld a, b
	or c
	jr nz, .ClearChIDs2

	pop af
	ret


;Initialize
Audio1_InitAudio:
	call Audio1_InitChan
	ld a, %10000000
	ldh [rNR52], a
	ld a, %01110111
	ldh [rNR50], a
	
	;Clear memory
	ld hl, AudioRAM
	ld de, AudioRAM+1
	ld bc, $0388
	ld [hl], 0
	call JumpFill
	
	;Set conditional flags?
	push af
	ld a, [CondFlag2]
	ld [CondFlag1], a
	pop af
	ret


Audio1_InitChan:
	;Set conditional flags?
	push af
	ld a, [CondFlag1]
	ld [CondFlag2], a
	ld a, $FF
	ld [CondFlag1], a
	
	pop af
	;Initialize audio registers
	ld a, %10000000
	ldh [rNR52], a
	ld a, %11101110
	ldh [rNR51], a
	ld a, %00010000
	ldh [rNR12], a
	ld a, %00001000
	ldh [rNR22], a
	ldh [rNR42], a
	ld a, %10000000
	ldh [rNR14], a
	ldh [rNR24], a
	ldh [rNR44], a
	xor a
	ldh [rNR32], a
	ld a, %10001111
	ldh [rNR52], a
	ret


;Check current sound slot
Audio1_GetSlot:
	ld hl, SoundSlots-1
	ld e, a
	ld d, 0
	add hl, de
	ld a, [hl]
	or a
	ret


;Start to load music/SFX
Audio1_LoadSound:
	ld a, 1

;If loading music, then skip the first part
Audio1_LoadSong:
	or a
	jr nz, .LoadAudio1_SFX2

	dec a

.LoadAudio1_SFX2
	ld a, 1
	ld [PlayFlag], a		;Set "play" flag
	push af
	
	ld a, [CondFlag1]		;Set flags
	ld [CondFlag2], a
	ld a, $FF
	ld [CondFlag1], a
	
	pop af
	ld a, l					;Get song pointer from RAM
	ld [CurStartPtr], a
	ld a, h
	ld [CurStartPtr+1], a
	inc hl					;Then get priority value from song header
	ld a, [hl]
	ld [CurPriority], a
	call Audio1_CheckPriorities
	jr c, Audio1_SetFlags

	call Audio1_CheckSlots			;Get sound "slot"
	jr c, Audio1_SetFlags

	call Audio1_InitSlot1
	ld a, [CurSlot]
	or a

Audio1_SetFlags:
	;Set current flag?
	push af
	ld a, [CondFlag2]
	ld [CondFlag1], a
	pop af
	ret


Audio1_CheckPriorities:
	;First, check priorities, otherwise, return if over highest number
	call Audio1_LoadChPriorityVals
	ret c

	;Load song pointer again
	ld e, 0
	ld d, 4
	ld a, [CurStartPtr]
	ld l, a
	ld a, [CurStartPtr+1]
	ld h, a
	inc hl
	inc hl

.CheckPriorities2
	;Get each pointer and channel number/ID
	ld a, [hl]
	inc hl
	ld b, [hl]
	inc hl
	ld c, [hl]
	inc hl
	;Is it zero?
	or b
	;If so, then skip to next channel
	jr z, .CheckPriorities3

	;Otherwise, check for see if channel is in use
	inc e
	push hl
	ld hl, ChanSlotVals
	ld b, 0
	add hl, bc
	ld a, [hl]
	pop hl
	or a
	;If so, then...
	jr z, .CheckPriorities3

	;Disable all sound
	call Audio1_EndSound
	;Then restart
	jr Audio1_CheckPriorities

.CheckPriorities3
	;Decrease number of channels left
	dec d
	;If not 0, then go to next channel
	jr nz, .CheckPriorities2
	
	;Otherwise, check priority number?
	ld a, e
	or a
	scf
	ret z

	or a
	ret


;Load all the channel pointers
Audio1_LoadChPriorityVals:
	ld a, [CurStartPtr]		;Get start address of song/SFX
	ld l, a
	ld a, [CurStartPtr+1]
	ld h, a
	inc hl
	ld e, [hl]			;Then get priority value
	ld a, e
	ld [CurPriority], a
	inc e
	inc hl
	ld d, 4				;4 channels

.LoadChPriorityVals2
	;Load next pointer - 2 bytes
	ld a, [hl]
	inc hl
	ld b, [hl]
	inc hl
	;Then load channel number byte
	ld c, [hl]
	inc hl
	;Check if pointer is 0 (unused)
	or b
	jr z, .LoadChPriorityVals3

	;If not, then...
	push hl
	;Check if channel is currently busy
	ld hl, ChanSlotVals
	ld b, 0
	add hl, bc
	ld c, [hl]
	;Check "priority" number of channel
	ld hl, SoundPriorities-1
	add hl, bc
	ld a, [hl]
	pop hl
	;If higher number than current channel, then return
	cp e
	ccf
	ret c

;Otherwise, keep checking channels
.LoadChPriorityVals3
	;Decrease number of channels left until done
	dec d
	jr nz, .LoadChPriorityVals2

	or a
	ret


;Initialize "slot" 1
Audio1_InitSlot1:
	;Get current "slot" number
	ld a, [CurSlot]
	ld e, a
	ld d, 0
	;Load "busy" status into slot flag
	ld hl, SoundSlots-1
	add hl, de
	ld [hl], $FF
	
	;Now set channel priority flag from RAM value
	ld hl, SoundPriorities-1
	add hl, de
	ld a, [CurPriority]
	ld [hl], a
	
	ld a, e
	;Get tempo/speed RAM area
	call Audio1_GetSpeedRAM
	;Load the pointer into RAM
	ld a, l
	ld [CurTempoChan], a
	ld a, h
	ld [CurTempoChan+1], a
	
	;Clear RAM area
	ld hl, MasterSlotPlay
	ld de, MasterSlotPlay+1
	ld bc, 2
	ld [hl], 0
	call JumpFill
	
	;Load the "play" flag value into master slot RAM
	ld a, [PlayFlag]
	ld [MasterSlotPlay], a
	
	;Load pointer of current music/SFX
	ld a, [CurStartPtr]
	ld l, a
	ld a, [CurStartPtr+1]
	ld h, a
	
	;Get tempo value from first byte of header
	ld a, [hl+]
	inc a
	ld [MasterSlotTempo], a
	;Also setup beat counter
	ld a, 1
	ld [MasterSlotBeatCounter], a
	
	;Load channel pointers and copy master slot tempo/speed values to current slot
	inc hl
	call Audio1_GetChannelPtrs
	call Audio1_CopySlotSpeedToMaster
	ret

;Load all the channel pointers from header
Audio1_GetChannelPtrs:
	ld b, 4				;4 = 4 channels
	push hl
	pop de

.GetChannelPtrs2
	ld a, [de]			;H,L = Pointer (0 if unused)
	inc de
	ld l, a
	ld a, [de]
	inc de
	ld h, a
	ld a, [de]			;C = Channel number
	inc de
	ld c, a
	ld a, h
	or l
	;If zero (unused), then skip to next channel
	jr z, .GetChannelPtrs3

	;Otherwise, get current channel number for actual hardware channel
	ld a, 5
	sub b
	push de
	push bc
	;Setup channel parameters
	call Audio1_SetupChan
	pop bc
	pop de
	jr c, .GetChannelPtrsRet

.GetChannelPtrs3
	dec b
	jr nz, .GetChannelPtrs2

	or a

.GetChannelPtrsRet
	ret


Audio1_SetupChan:
	;Load actual hardware channel into RAM
	ld [CurChan], a
	
	ld a, c
	;Also load track number (1-8) into RAM
	inc a
	ld [CurTrack], a
	
	;Get main RAM address for current track
	push hl
	call Audio1_GetTrackRAM
	;Load the pointer value into RAM
	ld a, l
	ld [CurTrackRAM], a
	ld a, h
	ld [CurTrackRAM+1], a
	
	ld c, l
	ld b, h
	pop de
	;Load sound pointer into start of track RAM
	ld [hl], e
	inc hl
	ld [hl], d
	
	;Then load current channel number value into track RAM
	ld hl, 4
	add hl, bc
	ld a, [CurChan]
	ld [hl], a
	;Also load to RAM value for channel IDs
	ld [CurTrackCh], a
	
	;Then get current slot values for each channel
	ld a, [CurTrack]
	ld e, a
	ld d, 0
	ld hl, ChanSlotVals-1
	add hl, de
	ld a, [CurSlot]
	ld [hl], a
	
	;Set current track "play" value to 0
	ld hl, ChanPlayVals-1
	add hl, de
	ld [hl], 0
	;Set channel ID values with priorities
	call Audio1_CheckIDs
	ld a, [CurTrack]
	or a
	ret


Audio1_CheckIDs:
	;First, get RAM address
	call Audio1_GetChIDRAM
	;Then, load priority
	push hl
	ld a, [CurPriority]
	ld b, a
	inc b
	ld c, 4

.CheckIDs2
	;Check if ID is used
	ld a, [hl]
	or a
	;If not, then...
	jr z, .CheckIDs3

	;Otherwise, 
	push hl
	ld hl, ChanSlotVals-1
	ld e, a
	ld d, 0
	add hl, de
	ld e, [hl]
	;Then, check to see if less than highest priority
	ld hl, SoundPriorities-1
	add hl, de
	ld a, [hl]
	pop hl
	cp b
	jr c, .CheckIDs3

	;If not, then skip to next ID
	inc hl
	dec c
	jr nz, .CheckIDs2

	;If 0, then return and set carry flag with original RAM value
	pop hl
	scf
	ret


.CheckIDs3
	ld e, l
	ld d, h
	pop hl
	;Advance to next ID
	ld b, 0
	dec c
	;If no IDs left, then get current track value
	jr z, .GetCurTrack

	;Otherwise, clear IDs for current channel
	ld de, 3
	add hl, de
	ld e, l
	ld d, h
	dec hl
	call Audio1_ClearChIDs

.GetCurTrack
	ld a, [CurTrack]
	ld [de], a
	ret


;Get the RAM address to store track IDs for each channel
Audio1_GetChIDRAM:
	ld a, [CurTrackCh]
	add a
	ld hl, Audio1_TrackIDRAM-2
	add l
	ld l, a
	ld a, 0
	adc h
	ld h, a
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ret

Audio1_TrackIDRAM:
	dw Ch1IDRAM
	dw Ch2IDRAM
	dw Ch3IDRAM
	dw Ch4IDRAM


;Load current slot tempo/speed values
Audio1_GetSpeedRAM:
	add a
	ld hl, Audio1_SpeedRAMSlots-2
	add l
	ld l, a
	ld a, 0
	adc h
	ld h, a
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ret


Audio1_SpeedRAMSlots:
	dw Slot1SpeedRAM	;Slot 1
	dw Slot2SpeedRAM	;Slot 2
	dw Slot3SpeedRAM	;Slot 3
	dw Slot4SpeedRAM	;Slot 4
	dw Slot5SpeedRAM	;Slot 5
	dw Slot6SpeedRAM	;Slot 6?
	dw Slot7SpeedRAM	;Slot 7?
	dw Slot8SpeedRAM	;Slot 8?


;Get main RAM address for current track
Audio1_GetTrackRAM:
	add a
	ld hl, Audio1_TrackRAM-2
	add l
	ld l, a
	ld a, 0
	adc h
	ld h, a
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ret

Audio1_TrackRAM:
	dw SFX1RAM	;SFX 1
	dw SFX2RAM	;SFX 2
	dw SFX3RAM	;SFX 3
	dw SFX4RAM	;SFX 4
	dw Mus1RAM	;Music 1
	dw Mus2RAM	;Music 2
	dw Mus3RAM	;Music 3
	dw Mus4RAM	;Music 4
	
Audio1_CheckSlots:
	;Check if sound "slot" is in use
	ld b, 4
	ld hl, SoundSlots

.Audio1_CheckSlots2
	;If 0 (available), then proceed
	ld a, [hl+]
	or a
	jr z, .SetSlot

	;Otherwise, try next slot
	dec b
	jr nz, .Audio1_CheckSlots2

	scf
	ret


;Put current slot number in RAM
.SetSlot
	ld a, 5
	sub b
	ld [CurSlot], a
	ret

;This code isn't reached?
	ld b, 8
	ld hl, ChanSlotVals

Audio1_CheckSlotVals:
	ld a, [hl+]
	or a
	jr z, .Audio1_CheckSlotVals2

	dec b
	jr nz, Audio1_CheckSlotVals

	scf
	ret


.Audio1_CheckSlotVals2
	ld a, 9
	sub b
	ld [CurTrack], a
	ret


;Set tempo/speed values and copy to master slot
Audio1_CopySlotSpeedFromMaster:
	call Audio1_GetSpeedRAM
	ld a, l
	ld [CurTempoChan], a
	ld a, h
	ld [CurTempoChan+1], a
	ld de, MasterSlotPlay
	ld bc, 3
	jp JumpFill


;Copy tempo/speed values from master slot to another slot
Audio1_CopySlotSpeedToMaster:
	ld hl, MasterSlotPlay
	ld a, [CurTempoChan]
	ld e, a
	ld a, [CurTempoChan+1]
	ld d, a
	ld bc, 3
	jp JumpFill


;Turn off sound
Audio1_SFXOff:
	xor a

;Disable all audio
.SoundOff2
	;Repeat for every slot; return if over slot count
	inc a
	cp 5
	ret nc

	push af
	call Audio1_SFXOffFlags
	pop af
	jr .SoundOff2

;Turn off sound (with conditional flag)
Audio1_CondSoundOff:
	ld a, [UnkCC4A]
	or a
	ret z

Audio1_SFXOffFlags:
	;Set conditional flags
	push af
	ld a, [CondFlag1]
	ld [CondFlag2], a
	ld a, $FF
	ld [CondFlag1], a
	pop af
	
	call Audio1_EndSound
	push af
	ld a, [CondFlag2]
	ld [CondFlag1], a
	pop af
	ret


Audio1_EndSound:
	;Turn current music/SFX slot off
	or a
	ret z

	;Return if over slot count
	cp 5
	ret nc

	ld c, a
	ld b, 0
	ld hl, SoundSlots-1
	add hl, bc
	ld [hl], 0
	ld hl, SoundPriorities-1
	add hl, bc
	ld [hl], 0
	ld b, 8
	ld hl, ChanSlotVals
	ld de, ChanPlayVals

.EndAudio1_SFX2
	;Check current value
	ld a, [hl]
	cp c
	;If no match, then skip to next slot
	jr nz, .EndAudio1_SFX3

	;Otherwise, disable value
	xor a
	ld [hl], a
	ld [de], a
	;Get current channel number?
	ld a, 9
	sub b
	push hl
	push de
	push bc
	;Disable/turn off the current track
	call Audio1_ClearTrack
	pop bc
	pop de
	pop hl

.EndAudio1_SFX3:
	inc hl
	inc de
	dec b
	jr nz, .EndAudio1_SFX2

	ret


Audio1_ClearTrack:
	;Disable each track's IDs, otherwise, check if 0 - if so, then return
	ld hl, CurRAMTrack
	ld [hl], 1
	ld hl, Ch1IDRAM
	call Audio1_CheckTrackVar
	jr nc, .CheckVarZero

	ld hl, CurRAMTrack
	ld [hl], 2
	ld hl, Ch2IDRAM
	call Audio1_CheckTrackVar
	jr nc, .CheckVarZero

	ld hl, CurRAMTrack
	ld [hl], 4
	ld hl, Ch4IDRAM
	call Audio1_CheckTrackVar
	jr nc, .CheckVarZero

	ld hl, CurRAMTrack
	ld [hl], 3
	ld hl, Ch3IDRAM
	call Audio1_CheckTrackVar
	ret c

	ld a, [hl]
	or a
	ret z

	;Otherwise, then set waveform from RAM
	push af
	call Audio1_GetTrackRAM
	ld de, 7
	add hl, de
	ld a, [hl]
	call Audio1_SetWaveform
	pop af
	jr .CheckVarZero2

.CheckVarZero
	;Check if value is 0 and return if so
	ld a, [hl]
	or a
	ret z

.CheckVarZero2
	ret


;Keep checking the track RAM variable to see if it matches the current channel number
Audio1_CheckTrackVar:
	push hl
	ld bc, 3
	ld d, 4

.CheckTrackVar2
	;Check if number matches the current track number
	cp [hl]
	;If so, then keep checking IDs until match found
	jr z, .ClearTrackIDs

	inc hl
	dec bc
	dec d
	jr nz, .CheckTrackVar2

	scf
	jr .ClearTrackIDsRet

;Clear all the ID/indexes in the track RAM
.ClearTrackIDs
	;First, disable channel if first ID
	call Audio1_FirstIDChanOff
	;Then, clear all IDs
	ld e, l
	ld d, h
	inc hl
	ld a, b
	or c
	jr z, .ClearTrackIDs2

	call JumpFill

.ClearTrackIDs2
	xor a
	ld [de], a

.ClearTrackIDsRet
	pop hl
	ret


Audio1_FirstIDChanOff:
	;Check if first ID
	push bc
	push de
	push hl
	ld a, c
	cp 3
	;If not first, then skip
	jr nz, .FirstIDChanOffRet

	;Otherwise, load panning value first
	ld a, [CurRAMTrack]
	call Audio1_ChanOff

.FirstIDChanOffRet
	pop hl
	pop de
	pop bc
	ret


;Play audio (music/sound effects)
Audio1_PlayAudio:
	call Audio1_ProcSlots
	call Audio1_ProcEnvSeqs
	jp Audio1_ProcRegs


;Check sound slots until one is in use
Audio1_ProcSlots:
	ld b, 4
	ld hl, SoundSlots

;Check the current slot
.FindTrackSlot
	ld a, [hl+]
	or a
	jr z, .NextSlot

	;If in use, then set current music/SFX slot
	ld a, 5
	sub b
	ld [CurSoundSlot], a
	
	
	push bc
	push hl
	;Copy tempo/speed variables from slot 1
	call Audio1_CopySlotSpeedFromMaster
	call Audio1_ProcTrack
	call Audio1_CopySlotSpeedToMaster
	pop hl
	pop bc

;If current slot is not used, then try next one
.NextSlot
	dec b
	jr nz, .FindTrackSlot

	;Return if none used
	ret


Audio1_ProcTrack:
	;Decrease beat counter (process tempo)
	ld hl, MasterSlotBeatCounter
	dec [hl]
	;Return if not finished at tempo
	ret nz

	;Otherwise,...
	ld a, [MasterSlotTempo]
	ld [hl], a
	call Audio1_CheckChSlots
	ret c

	ld a, [CurSoundSlot]
	ld c, a
	ld b, 8
	ld hl, ChanSlotVals
	ld de, ChanPlayVals

.CheckTrackSlots
	;Check if slot is currently used
	ld a, [hl]
	cp c
	;If not, then skip
	jr nz, .NextTrackSlot

	;Otherwise, then check channel play status
	ld a, [de]
	or a
	;If not playing, then skip
	jr z, .NextTrackSlot
	
	push hl
	push de
	push bc
	ld a, 9
	sub b
	;Load current track index into RAM
	ld [CurTrackIndex], a
	;And get its current RAM pointers
	call Audio1_GetTrackRAM
	ld c, l
	ld b, h
	;Then load pointers into current channel RAM value
	ld a, l
	ld [CurTrackRAM], a
	ld a, h
	ld [CurTrackRAM+1], a
	
	call Audio1_CheckNoteDur
	pop bc
	pop de
	pop hl

;Go to next slot
.NextTrackSlot
	inc hl
	inc de
	dec b
	jr nz, .CheckTrackSlots

	ret


Audio1_CheckNoteDur:
	;Get current track number
	ld a, [CurTrackIndex]
	dec a
	ld e, a
	ld d, 0
	ld hl, $21
	add hl, bc
	ld a, [hl]				;If slur value is not 0, then skip to delay
	or a
	jr nz, Audio1_CheckDelay

	ld hl, $0B
	add hl, bc
	ld a, [hl]				;If note duration remaining is 0, then skip to delay
	or a
	jr z, Audio1_CheckDelay

	dec [hl]				;If note duration is not 0, then skip to delay
	jr nz, Audio1_CheckDelay

	ld hl, $0F				;Otherwise, load previous value of note duration remaining into (F)?
	add hl, bc
	ld [hl], a

Audio1_CheckDelay:
	ld hl, $0C				;Decrease delay value
	add hl, bc
	dec [hl]
	ret nz					;If not 0, then return from function (wait)

	ld hl, TrackTrigVals	;Set track trigger to FF (on)
	add hl, de
	ld [hl], $FF

Audio1_ContTrack:
	ld hl, $06				;Check "random"(?) value
	add hl, bc
	ld a, [hl]
	or a
	call nz, Audio1_DoRNG		;If not 0, then do "random" sequence
	ld a, [CurTrackRAM]
	ld c, a
	ld a, [CurTrackRAM+1]
	ld b, a
	
	;Get current track position
	ld hl, $02
	add hl, bc
	ld a, [hl]
	inc hl
	push hl
	ld h, [hl]
	ld l, a
	push hl
	
	ld hl, $1C						;Check if automatic note length is turned on
	add hl, bc
	ld a, [hl]
	or a
	jr z, Audio1_AdvPointer			;If off, then get new command

	ld hl, $1D						;Otherwise, if on, then load automatic note length 
	add hl, bc
	ld a, [hl]
	ld [CurParameter], a
									
	pop hl							;Then, advance pointer by 1 (rather than 2)
	ld d, [hl]
	inc hl
	jr Audio1_GetCommand			;After that, get new command

;Advance pointer
Audio1_AdvPointer:
	pop hl
	ld a, [hl+]
	ld d, a
	ld a, [hl+]
	;Get current note length (if note) from second byte
	ld [CurParameter], a

;Restore previous pointer value
Audio1_GetCommand:
	ld a, h
	ld e, l
	pop hl
	ld [hl-], a
	ld [hl], e
	;Load command value in A
	ld a, d
	
	;Check for note/VCMD value
	cp $C0						;Cx+
	jp nc, Audio1_GetHighVCMD

	cp $B0						;Bx = Jump (relative position) and repeat (1)
	jp nc, Audio1_JumpBx

	cp $A0						;Ax = Jump (relative position) and repeat (2) (nested)
	jp nc, Audio1_JumpAx

	cp $90						;9x = Jump (relative position) and repeat (3)
	jp nc, Audio1_Jump9x

	;If none of the ebove, then is a note or rest
	
	;Set "trigger" bit for NRx4
	ld e, %10000000
	ld hl, $21
	add hl, bc
	;Check if "slur" is on
	ld a, [hl]
	or a
	;If so, then set "trigger" and highest length bits
	jr z, .GetCommand2

	ld e, %11000000

;Load and OR NR14 value
.GetCommand2
	ld hl, $57
	add hl, bc
	ld a, [hl]
	and %00000111
	or e
	ld [hl], a
	
	;Then check track channel number
	ld hl, $04
	add hl, bc
	ld a, [hl]
	;If channel 4 (noise)
	cp 4
	jr z, Audio1_GetNoiseFreq

	;Otherwise (channel 1-3), check current command once again
	ld a, d
	;Mask out lower 4 bits
	and %11110000
	;If 0x, then is a rest
	jr z, Audio1_ProcRest

	;Otherwise, is a note (10-7F) - get frequency first
	;(Format (Ch1-3): xxxxyyyy, Parameters: zzzzzzzz (x = octave (starting with 1, 0 = rest), y = note, z = length)
	call Audio1_Note2Freq
	;Then, get bytes from frequency table
	ld a, [hl+]
	push hl
	;Process as NRx3-NRx4 values
	ld hl, $56
	add hl, bc
	ld [hl+], a
	ld a, [hl]
	and %11111000
	pop hl
	or [hl]
	ld hl, $57
	add hl, bc
	ld [hl], a
	;Then load envelope and store in RAM value
	ld hl, $08
	add hl, bc
	ld a, [hl]
	ld [CurEnv], a
	jr Audio1_ProcNoteParams

;Convert note value to frequency from table
Audio1_Note2Freq:
	;First, get command (note) value from D
	ld a, d
	;Find pointer value from note
	swap a
	;Get octave number from upper 4 bits
	and %00001111
	dec a
	add a
	add a
	ld e, a
	add a
	add e
	ld e, a
	ld a, d
	;Get note number from lower 4 bits and add to current value
	and %00001111
	add e
	ld e, a
	ld a, 0
	adc 0
	ld d, a
	;Also add transpose - increase or decrease note depending on signed/unsigned value
	ld hl, $05
	add hl, bc
	ld l, [hl]
	ld h, 0
	ld a, l
	and %10000000
	jr z, .Note2Freq2

	dec h

.Note2Freq2
	add hl, de
	add hl, hl
	ld de, Audio1_FreqTab
	add hl, de
	ret


Audio1_ProcRest:
	;Set "second" envelope
	ld hl, $09
	add hl, bc
	ld a, [hl]
	ld [CurEnv], a
	
	;Set remaining duration to 0
	ld hl, $0B
	add hl, bc
	ld [hl], 0
	
	;Set previous note duration to 1
	ld a, 1
	ld hl, $0F
	add hl, bc
	ld [hl], a
	
	jp Audio1_ProcNoteParamsB


Audio1_GetNoiseFreq:
	;(Format (Ch4): xxxxxxxx (x = note (0 = rest))
	;Check if noise command is 0
	ld a, d
	and %11111111
	;If so, then is a rest
	jr z, Audio1_ProcRest

	;Get noise value from table
	ld hl, Audio1_NoiseVals-1
	add l
	ld l, a
	ld a, 0
	adc h
	ld h, a
	ld a, [hl]
	;If E0 or more, then set to 0
	cp $E0
	jr c, .GetNoiseFreq2

	xor a

.GetNoiseFreq2
	;Set NR14 value
	ld hl, $56
	add hl, bc
	ld [hl], a
	
	;Set vibrato number to 0 (unused)
	ld hl, $15
	add hl, bc
	ld [hl], 0
	
	;Get track envelope
	ld hl, $08
	add hl, bc
	ld a, [hl]
	
	ld [CurEnv], a

;Now process note length
Audio1_ProcNoteParams:
	;First, get note duration
	ld hl, $0A
	add hl, bc
	ld h, [hl]
	;Then, get current note length
	ld a, [CurParameter]
	;Subtract duration from length to get total remaining
	sub h
	;If 0 (or exceed value), then set to 1
	jr z, .ProcNoteParams2

	;Otherwise, load value in RAM
	jr nc, .ProcNoteParams3

;Set remaining duration to 1 (if necessary)
.ProcNoteParams2
	ld a, 1

.ProcNoteParams3
	;Set the remaining duration
	ld hl, $0B
	add hl, bc
	ld [hl], a
	
	;Set envelope sequence speed counter to 1
	ld a, 1
	ld hl, $0F
	add hl, bc
	ld [hl], a
	
	;Also set vibrato delay remaining to 1
	ld hl, $19	
	add hl, bc
	ld [hl], a
	
	;Load vibrato speed into RAM value
	ld hl, $16
	add hl, bc
	ld a, [hl]
	
	;Load this value into the vibrato speed counter value
	ld hl, $17
	add hl, bc
	ld [hl], a
	
	;Set envelope sequence index and unknown value to 0
	xor a
	ld hl, $10
	add hl, bc
	ld [hl], a
	
	ld hl, $13
	add hl, bc
	ld [hl], a
	
	;Get vibrato value (index for table)
	ld hl, $15
	add hl, bc
	ld a, [hl]
	
	;Load values from vibrato sequence table into RAM 
	add a
	ld hl, Audio1_VibTab-2
	add l
	ld l, a
	ld a, 0
	adc h
	ld h, a
	;First, delay and then frequency change
	ld a, [hl+]
	ld e, [hl]
	ld hl, $1A
	add hl, bc
	ld [hl+], a
	ld [hl], e

Audio1_ProcNoteParamsB:
	;Set delay to current note length
	ld a, [CurParameter]
	ld hl, $0C
	add hl, bc
	ld [hl], a
	
	;Also set automatic note length variable
	ld hl, $1D
	add hl, bc
	ld [hl], a
	
	;Get track channel number
	push bc
	ld hl, $04
	add hl, bc
	ld c, [hl]	
	;And current envelope
	ld a, [CurEnv]
	;Now get initial volume of envelope
	call Audio1_GetEnvVol
	
	;Get envelope sequence
	ld e, b
	pop bc
	ld hl, $0D
	add hl, bc
	ld a, [hl]
	
	;Get current envelope value from sequence
	or a
	ld a, e
	jr nz, .ProcNoteParamsB2

	;If not 0, then set envelope sweep pace
	ld hl, $14
	add hl, bc
	ld a, [hl]
	or e

;Set NRx1 (envelope value)
.ProcNoteParamsB2
	ld hl, $55
	add hl, bc
	ld [hl], a
	ret


Audio1_GetEnvVol:
	;Get initial volume from envelope
	swap a
	and %11110000
	ld b, a
	ld a, c
	;Check if channel is 4 (noise)
	cp 3

.GetEnvVol2
	jr nz, .GetEnvVolRet

	;If so, then get noise envelope value from table
	ld a, b
	rlca
	rlca
	and %00000011
	push hl
	ld hl, Audio1_NoiseEnvs
	add l
	ld l, a
	ld a, 0
	adc h
	ld h, a
	ld b, [hl]
	pop hl

.GetEnvVolRet
	ld a, b
	ret

Audio1_NoiseEnvs:
	db %00000000
	db %01100000
	db %01000000
	db %00100000

;Bx yy = Jump position with relative amount (1)
;Parameters: X = Number of times, Y = Position (relative, signed)
Audio1_JumpBx:
	;Mask out upper 4 bits
	and a, %00001111
	;If 0, then infinite repeat
	jp z, .JumpBx_3

	;Otherwise, check repeat amount in RAM variable
	ld e, a
	ld hl, $22
	add hl, bc
	ld a, [hl]
	or a
	;If 0 (not set), then load variable in RAM
	jr z, .JumpBx_2

	;Otherwise, decrease repeat number
	dec [hl]
	;If not 0, then go to repeat point
	jr nz, .JumpBx_3

	;Otherwise, then continue as normal (done repeating)
	jp Audio1_ContTrack


;Load repeat variable in RAM
.JumpBx_2
	ld [hl], e

;Check second byte
.JumpBx_3
	ld a, [CurParameter]
	ld l, a
	ld h, 0
	;If positive, then increase jump amount; otherwise, decrease
	cp $80
	jr c, .JumpBx_4

	dec h

.JumpBx_4
	;Add jump amount (x2) to current position
	add hl, hl
	ld e, l
	ld d, h
	ld hl, $02
	add hl, bc
	ld a, [hl+]
	push hl
	ld h, [hl]
	ld l, a
	dec hl
	dec hl
	add hl, de
	ld a, h
	ld e, l
	pop hl
	ld [hl-], a
	ld [hl], e
	jp Audio1_ContTrack


;Ax yy = Jump position with relative amount (2)
;Parameters: X = Number of times, Y = Position (relative, signed)
;Supports multiple "nested" repeats, unlike Bx.
Audio1_JumpAx:
	;Mask out upper 4 bits
	and %00001111
	;If 0, then infinite repeat
	jp z, .JumpAx_6

	;Otherwise, load repeat value in variable
	ld [CurRepeatAmt], a
	
	;Get current position
	ld hl, $02
	add hl, bc
	ld e, [hl]
	inc hl
	ld d, [hl]
	
	;Then, get current repeat position from command Ax if available
	ld hl, $23
	add hl, bc
	ld c, 0

;Check if stored position in RAM is equal to current position
.JumpAx_2
	ld a, [hl+]
	cp e
	;If not, then increase position index and slot number
	jr nz, .JumpAx_3

	ld a, [hl]
	cp d
	;If so, then decrease repeats left for position
	jr z, .JumpAxDec

.JumpAx_3
	;Increase position index and slot number
	inc hl
	inc c
	ld a, c
	;If slot is less than 8, then find if the next slot is used
	cp 8
	jr c, .JumpAx_2

	;When all slots checked, go back to start of repeat position index
	ld a, [CurTrackRAM]
	ld e, a
	ld a, [CurTrackRAM+1]
	ld d, a
	ld hl, $23
	add hl, de
	ld c, 0

;See if current slot is in use
.JumpAx_4
	ld a, [hl+]
	or [hl]
	;If so, then proceed
	jr z, .JumpAx_5

;Keep repeating until empty slot is found
	inc hl
	inc c
	ld a, c
	cp 8
	jr c, .JumpAx_4

;If no slot is found, then skip
	jp Audio1_ContTrack


.JumpAx_5
	push hl
	;If slot is found, then get current position
	ld hl, $02
	add hl, de
	ld a, [hl+]
	ld b, [hl]
	pop hl
	;Then load this position into the empty slot
	ld [hl], b
	dec hl
	ld [hl], a
	
	;Then load repeat amounts into position in RAM
	ld b, 0
	ld hl, $33
	add hl, de
	add hl, bc
	ld a, [CurRepeatAmt]
	ld [hl], a
	jr .JumpAx_6

;If matching existing slot still has repeats, then decrease number of repeats
.JumpAxDec
	ld b, 0
	ld a, [CurTrackRAM]
	ld e, a
	ld a, [CurTrackRAM+1]
	ld d, a
	ld hl, $33
	add hl, de
	add hl, bc
	dec [hl]
	;If done repeating, then clear pointer in slot
	jr z, .JumpAxClear

;Check second byte
.JumpAx_6
	ld a, [CurParameter]
	ld l, a
	ld h, 0
	;If positive, then increase jump amount; otherwise, decrease
	cp $80
	jr c, .JumpAx_7

	dec h

.JumpAx_7
	;Add jump amount (x2) to current position
	ld a, [CurTrackRAM]
	ld c, a
	ld a, [CurTrackRAM+1]
	ld b, a
	add hl, hl
	ld e, l
	ld d, h
	ld hl, $02
	add hl, bc
	ld a, [hl+]
	push hl
	ld h, [hl]
	ld l, a
	dec hl
	dec hl
	add hl, de
	ld a, h
	ld e, l
	pop hl
	ld [hl-], a
	ld [hl], e
	jp Audio1_ContTrack


;Clear the track pointer from the repeat slot
.JumpAxClear
	ld a, c
	add a
	ld c, a
	ld b, 0
	ld hl, $23
	add hl, de
	add hl, bc
	ld [hl], 0
	inc hl
	ld [hl], 0
	jp Audio1_ContTrack


;9x yy = Jump position with relative amount (3)
;Parameters: X = Number of times, Y = Position (relative, signed)
;Works similar to Ax, but does not actually jump unless infinite times are specified.
Audio1_Jump9x:
	;Mask out upper 4 bits
	and %00001111
	;If 0, then infinite repeat
	jp z, .Jump9x_6

	;Otherwise, load repeat value in variable
	ld [CurRepeatAmt], a
	
	;Get current position
	ld hl, $02
	add hl, bc
	ld e, [hl]
	inc hl
	ld d, [hl]
	
	;Then, get current repeat position from command 9x if available
	ld hl, $3B
	add hl, bc
	ld c, 0

;Check if stored position in RAM is equal to current position
.Jump9x_2
	ld a, [hl+]
	cp e
	;If not, then increase position and slot number
	jr nz, .Jump9x_3

	ld a, [hl]
	cp d
	;If so, then decrease repeats left for position
	jr z, .Jump9xDec

.Jump9x_3
	;Increase position index and slot number
	inc hl
	inc c
	ld a, c
	;If slot is less than 8, then find if the next slot is used
	cp 8
	jr c, .Jump9x_2

	;When all slots checked, go back to start of repeat position index
	ld a, [CurTrackRAM]
	ld e, a
	ld a, [CurTrackRAM+1]
	ld d, a
	ld hl, $3B
	add hl, de
	ld c, 0

;See if current slot is in use
.Jump9x_4
	ld a, [hl+]
	or [hl]
	;If so, then proceed
	jr z, .Jump9x_5

;Keep repeating until empty slot is found
	inc hl
	inc c
	ld a, c
	cp $08
	jr c, .Jump9x_4

	;If no slot is found, then skip
	jp Audio1_ContTrack


.Jump9x_5
	push hl
	;If slot is found, then get current position
	ld hl, $02
	add hl, de
	ld a, [hl+]
	ld b, [hl]
	pop hl
	;Then load this position into the empty slot
	ld [hl], b
	dec hl
	ld [hl], a
	
	;Then load repeat amounts into position in RAM
	ld b, 0
	ld hl, $4B
	add hl, de
	add hl, bc
	ld a, [CurRepeatAmt]
	ld [hl], a
	jr .Jump9xCont

;If matching existing slot still has repeats, then decrease number of repeats
.Jump9xDec
	ld b, 0
	ld a, [CurTrackRAM]
	ld e, a
	ld a, [CurTrackRAM+1]
	ld d, a
	ld hl, $4B
	add hl, de
	add hl, bc
	dec [hl]
	;If done repeating, then clear pointer in slot
	;Otherwise, keep going
	jr nz, .Jump9xCont

;Clear the track pointer from the repeat slot
.Jump9xClear
	ld a, c
	add a
	ld c, a
	ld b, 0
	ld hl, $3B
	add hl, de
	add hl, bc
	ld [hl], 0
	inc hl
	ld [hl], 0

;Check second byte
.Jump9x_6
	ld a, [CurParameter]
	ld l, a
	ld h, 0
	;If positive, then increase jump amount; otherwise, decrease
	cp $80
	jr c, .Jump9x_7

	dec h

.Jump9x_7
	;Add jump amount (x2) to current position
	ld a, [CurTrackRAM]
	ld c, a
	ld a, [CurTrackRAM+1]
	ld b, a
	add hl, hl
	ld e, l
	ld d, h
	ld hl, $02
	add hl, bc
	ld a, [hl+]
	push hl
	ld h, [hl]
	ld l, a
	dec hl
	dec hl
	add hl, de
	ld a, h
	ld e, l
	pop hl
	ld [hl-], a
	ld [hl], e
	jp Audio1_ContTrack


.Jump9xCont
	jp Audio1_ContTrack


;VCMDs C0 or above
Audio1_GetHighVCMD:
	ld hl, Audio1_ContTrack
	push hl
	cp $E6
	;If VCMD is less than E6, then return (not valid)
	ret c

	;Otherwise, get track channel number
	ld hl, $04
	add hl, bc
	ld a, [hl]
	
	;Use it to get pointer of channel VCMD table
	add a
	ld hl, Audio1_VCMDChanTab-2
	add l
	ld l, a
	ld a, 0
	adc h
	ld h, a
	ld a, [hl+]
	ld h, [hl]
	;Then use command to find VCMD in the corresponding table
	ld l, a
	ld a, d
	;Invert command, since the tables count backwards
	cpl
	add a
	add l
	ld l, a
	ld a, 0
	adc h
	ld h, a
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	or h
	;Return if zero pointer (invalid command)
	ret z

	;Then, get parameter from second byte
	ld a, [CurParameter]
	ld d, a
	;Go to the VCMD pointer
	jp hl


Audio1_VCMDChanTab:
	dw Audio1_VCMDCh1Tab
	dw Audio1_VCMDCh2Tab
	dw Audio1_VCMDCh3Tab
	dw Audio1_VCMDCh4Tab
	
Audio1_VCMDCh1Tab:
	dw Audio1_EventStop			;FF
	dw Audio1_EventEnv			;FE
	dw Audio1_EventEnvRest		;FD
	dw Audio1_EventEnvSeq		;FC
	dw Audio1_EventEnvSweep		;FB
	dw Audio1_EventEnvSpeed		;FA
	dw Audio1_EventChanLen		;F9
	dw Audio1_EventNoteDur		;F8
	dw Audio1_EventVibrato		;F7
	dw Audio1_EventVibSpeed		;F6
	dw Audio1_EventSweep		;F5
	dw Audio1_EventDuty			;F4
	dw 0						;F3
	dw 0						;F2
	dw Audio1_EventMasterVol	;F1
	dw Audio1_EventPan			;F0
	dw Audio1_EventVibDelay		;EF
	dw Audio1_EventSlur			;EE
	dw Audio1_EventTranspose	;ED
	dw Audio1_EventAutoLenOn	;EC
	dw Audio1_EventAutoLenOff	;EB
	dw Audio1_EventDecTrackPtr	;EA
	dw Audio1_EventMacro		;E9
	dw Audio1_EventMacroRet		;E8
	dw Audio1_EventRNG			;E7
	dw Audio1_EventRNGVal		;E6
Audio1_VCMDCh2Tab:
	dw Audio1_EventStop			;FF
	dw Audio1_EventEnv			;FE
	dw Audio1_EventEnvRest		;FD
	dw Audio1_EventEnvSeq		;FC
	dw Audio1_EventEnvSweep		;FB
	dw Audio1_EventEnvSpeed		;FA
	dw Audio1_EventChanLen		;F9
	dw Audio1_EventNoteDur		;F8
	dw Audio1_EventVibrato		;F7
	dw Audio1_EventVibSpeed		;F6
	dw 0						;F5
	dw Audio1_EventDuty			;F4
	dw 0						;F3
	dw 0						;F2
	dw Audio1_EventMasterVol	;F1
	dw Audio1_EventPan			;F0
	dw Audio1_EventVibDelay		;EF
	dw Audio1_EventSlur			;EE
	dw Audio1_EventTranspose	;ED
	dw Audio1_EventAutoLenOn	;EC
	dw Audio1_EventAutoLenOff	;EB
	dw Audio1_EventDecTrackPtr	;EA
	dw Audio1_EventMacro		;E9
	dw Audio1_EventMacroRet		;E8
	dw Audio1_EventRNG			;E7
	dw Audio1_EventRNGVal		;E6
Audio1_VCMDCh3Tab:
	dw Audio1_EventStop			;FF
	dw Audio1_EventEnv			;FE
	dw Audio1_EventEnvRest		;FD
	dw Audio1_EventEnvSeq		;FC
	dw 0						;FB
	dw Audio1_EventEnvSpeed		;FA
	dw Audio1_EventChanLen		;F9
	dw Audio1_EventNoteDur		;F8
	dw Audio1_EventVibrato		;F7
	dw Audio1_EventVibSpeed		;F6
	dw 0						;F5
	dw 0						;F4
	dw 0						;F3
	dw Audio1_EventWaveform		;F2
	dw Audio1_EventMasterVol	;F1
	dw Audio1_EventPan			;F0
	dw Audio1_EventVibDelay		;EF
	dw Audio1_EventSlur			;EE
	dw Audio1_EventTranspose	;ED
	dw Audio1_EventAutoLenOn	;EC
	dw Audio1_EventAutoLenOff	;EB
	dw Audio1_EventDecTrackPtr	;EA
	dw Audio1_EventMacro		;E9
	dw Audio1_EventMacroRet		;E8
	dw Audio1_EventRNG			;E7
	dw Audio1_EventRNGVal		;E6
Audio1_VCMDCh4Tab:
	dw Audio1_EventStop			;FF
	dw Audio1_EventEnv			;FE
	dw Audio1_EventEnvRest		;FD
	dw Audio1_EventEnvSeq		;FC
	dw Audio1_EventEnvSweep		;FB
	dw Audio1_EventEnvSpeed		;FA
	dw Audio1_EventChanLen		;F9
	dw Audio1_EventNoteDur		;F8
	dw 0						;F7
	dw 0						;F6
	dw 0						;F5
	dw 0						;F4
	dw 0						;F3
	dw 0						;F2
	dw Audio1_EventMasterVol	;F1
	dw Audio1_EventPan			;F0
	dw 0						;EF
	dw Audio1_EventSlur			;EE
	dw 0						;ED
	dw Audio1_EventAutoLenOn	;EC
	dw Audio1_EventAutoLenOff	;EB
	dw Audio1_EventDecTrackPtr	;EA
	dw Audio1_EventMacro		;E9
	dw Audio1_EventMacroRet		;E8
	dw 0						;E7
	dw Audio1_EventRNGVal		;E6

Audio1_EventStop:
;Stop the channel
	pop hl
	;Set the channel play status to 0
	ld a, [CurTrackIndex]
	ld e, a
	ld d, 0
	ld hl, ChanPlayVals-1
	add hl, de
	ld [hl], 0
	
	;Also turn track "trigger" flag off
	ld hl, TrackTrigVals-1
	add hl, de
	ld [hl], 0
	;Get current track position
	call Audio1_GetCurPos
	xor a
	
	;Clear track envelope
	ld hl, $08
	add hl, bc
	ld [hl], a
	ret


Audio1_EventEnv:
;Set channel envelope/volume
;Parameters: ----xxxx (- = unused, x = envelope)
	;Mask out the upper 4 bits
	and %00001111
	ld hl, $08
	add hl, bc
	ld [hl], a
	ret


Audio1_EventEnvRest:
;Set secondary channel envelope/volume (for rest, can be used for echo)
;Parameters: ----xxxx (- = unused, x = envelope)
	;Mask out the upper 4 bits
	and %00001111
	ld hl, $09
	add hl, bc
	ld [hl], a
	ret


Audio1_EventEnvSeq:
;Set up track envelope sequence (0 = unused)
;Parameters: ----xxxx (- = unused, x = envelope sequence number)
	;Mask out the upper 4 bits
	and %00001111
	ld hl, $0D
	add hl, bc
	ld [hl], a
	ret z

	;If not 0, set envelope sequence pointer to table value
	add a
	add a
	add a
	ld de, Audio1_EnvSeqs
	add e
	ld e, a
	ld a, 0
	adc d
	ld d, a
	;Load the pointer value itself into track RAM
	ld hl, $11
	add hl, bc
	ld [hl], e
	inc hl
	ld [hl], d
	ret


Audio1_EventEnvSweep:
;Set up envelope sweep pace
;Parameters: ----xxxx (- = unused, x = envelope sweep pace)
	;Mask out the upper 4 bits
	and %00001111
	ld hl, $14
	add hl, bc
	ld [hl], a
	ret


Audio1_EventEnvSpeed:
;Set up envelope sequence speed
;Parameters: xxxxxxxx (x = envelope sequence speed)
	ld hl, $0E
	add hl, bc
	ld [hl], a
	ret


Audio1_EventChanLen:
;Set up channel length timer
;Parameters: (CH1-3) --xxxxxx (- = unused, x = channel length timer)
;			 (CH4) xxxxxxxx (x = channel length timer)
	;Get track channel number
	ld hl, $04
	add hl, bc
	ld a, [hl]
	;Check if channel is 4 (noise)
	cp 3
	ld a, d
	;If so, then load direct value
	jr z, .EventChanLen2

	;If channel 1-3, then set initial channel length timer
	;Mask out upper 3 bits (only use initial length timer bits)
	and %00111111
	ld d, a
	;Get NRx1 register value
	ld hl, $54
	add hl, bc
	ld a, [hl]
	;Combine new value with old
	and %11000000
	or d

.EventChanLen2
	;Load value into NRx1 register
	ld [hl], a
	ret


Audio1_EventNoteDur:
;Set note duration
;Parameters: xxxxxxxx (x = duration)
	ld hl, $0A
	add hl, bc
	ld [hl], a
	ret


Audio1_EventVibrato:
;Set vibrato sequence number (0 = unused)
;Parameters: ----xxxx (- = unused, x = number)
	and %00001111
	ld hl, $15
	add hl, bc
	ld [hl], a
	ret


Audio1_EventVibDelay:
;Set vibrato delay
;Parameters: ----xxxx (- = unused, x = delay in ticks)
	and %00001111
	ld hl, $18
	add hl, bc
	ld [hl], a
	ret


Audio1_EventVibSpeed:
;Set vibrato speed
;Parameters: xxxxxxxx (x = speed value)
	ld hl, $16
	add hl, bc
	ld [hl], a
	ret


Audio1_EventSweep:
;Set channel 1 sweep (NR10)
;Parameters: xxxxxxxx (x = sweep value)
	ld hl, $53
	add hl, bc
	ld [hl], a
	ret


Audio1_EventDuty:
;Set channel duty
;Parameters: xx------ (- = unused, x = duty value)
	;Mask out lower 6 bits (only use duty for NRx1)
	and %11000000
	ld d, a
	;Load current NRx1 value)
	ld hl, $54
	add hl, bc
	ld a, [hl]
	;Combine new value with old (channel length timer)
	and %00111111
	or d
	ld [hl], a
	ret


Audio1_EventWaveform:
;Set waveform for channel 3 using a number of waveform from a table
;Parameters: ----xxxx (- = unused, x = number for table)
	and %00001111
	ld hl, $07
	add hl, bc
	ld [hl], a

;Load channel waveform into wave RAM
Audio1_SetWaveform:
	swap a
	ld hl, Audio1_Waveforms
	add l
	ld l, a
	ld a, 0
	adc h
	ld h, a
	ld de, WaveRAM
	ld bc, 16
	jp JumpFill


Audio1_EventMasterVol:
;Set master volume
;Parameters: xxxxxxxx (x = value for NR50)
	;Load the value directly to NR50
	ldh [rNR50], a
	ret


Audio1_EventPan:
;Set panning
;Parameters: xxxxxxxx (x = pan value)
	ld hl, $04
	add hl, bc
	ld e, [hl]
	jp Audio1_InitPan


Audio1_EventSlur:
;Toggle slur with value
;Parameters: xxxxxxxx (x = slur value - 0 = off, other = on)
	ld hl, $21
	add hl, bc
	ld [hl], a
	ret


Audio1_EventTranspose:
;Set transpose for track
;Parameters: xxxxxxxx (x = transpose value, signed) 
	ld hl, $05
	add hl, bc
	ld [hl], a
	ret


Audio1_EventAutoLenOn:
;Enable automatic length
;(Note: This command seems useless since the automatic length is never actually set, and is thus always 0.)
	ld hl, $1C
	add hl, bc
	ld [hl], 1
	jr Audio1_EventDecTrackPtr


Audio1_EventAutoLenOff:
;Disable automatic length
;Parameters: -------- (- = unused)
	ld hl, $1C
	add hl, bc
	ld [hl], 0
	ret


Audio1_EventDecTrackPtr:
;Decrement track pointer
	ld hl, $02
	add hl, bc
	ld a, [hl]
	sub 1
	ld [hl], a
	inc hl
	ld a, [hl]
	sbc 0
	ld [hl], a
	ret


Audio1_EventMacro:
;Go to macro/sub-routine (1 level only)
;Parameters: xxxxxxxx xxxxxxxx (x = position (little-endian))
	;Get track pointer
	ld hl, $02
	add hl, bc
	ld e, [hl]
	inc hl
	ld d, [hl]
	;Store position from next two bytes
	ld a, [de]
	inc de
	push de
	ld [hl], a
	dec hl
	ld a, [CurParameter]
	ld [hl], a
	ld hl, $1E
	add hl, bc
	;Load macro return position in RAM
	pop de
	ld [hl], e
	inc hl
	ld [hl], d
	ret


Audio1_EventMacroRet:
;Return from macro
	;Get macro return position
	ld hl, $1E
	add hl, bc
	ld e, [hl]
	inc hl
	ld d, [hl]
	;Set current position to macro return
	ld hl, $02
	add hl, bc
	ld [hl], e
	inc hl
	ld [hl], d
	ret


Audio1_EventRNG:
;Toggle conditional RNG parameter and then execute RNG routine if on
;Parameters: xxxxxxxxx (x = value - 0 = off, other = on)
	ld hl, $06
	add hl, bc
	ld [hl], a
	or a
	ret z

Audio1_DoRNG:
;Execute RNG sequence
;Parameters: ----xxxx (- = unused, x = value)
;(This function affects the transpose and envelope values.)
	;Generate RNG
	call JumpRNG
	;Mask out upper 4 bits of result
	and %00001111
	;Set the final number based on the result
	cp 10
	jr nc, .DoRNGResult1

	cp 7
	jr nc, .DoRNGResult2

	cp 4
	jr z, .DoRNGResult2

	jr nc, .DoRNGResult3

	cp 3
	jr z, .DoRNGResult4

	cp 2
	jr z, .DoRNGResult5

	dec a
	jr z, .DoRNGResult6

	jr .DoRNGResult1

.DoRNGResult1
	ld d, 15
	ld a, 12
	jr .DoRNG2

.DoRNGResult3
	ld d, 12
	ld a, 24
	jr .DoRNG2

.DoRNGResult4
	ld d, 10
	ld a, 36
	jr .DoRNG2

.DoRNGResult5
	ld d, 8
	ld a, 48
	jr .DoRNG2

.DoRNGResult6
	ld d, 8
	ld a, 3
	jr .DoRNG2

.DoRNGResult2
	ld d, 15
	xor a

;Perform random function?
.DoRNG2
	;Set transpose
	ld hl, $05
	add hl, bc
	ld [hl], a
	;Set envelope
	ld hl, $08
	add hl, bc
	ld [hl], d
	ret


Audio1_EventRNGVal:
;Set parameter for RNG function
;Parameters: xxxxxxxx (x = value)
	ld hl, CurRNG
	ld [hl], a
	ret


;Process each track's envelope sequences
;Get values of first track (SFX channel 1)
Audio1_ProcEnvSeqs:
	ld c, 0
	ld hl, SFX1RAM+$0D
	ld de, ChanPlayVals

.ProcEnvSeqs2
	push de
	push hl
	ld a, [de]
	ld e, a
	;Check envelope sequence number
	ld a, [hl+]
	or a
	;If 0, then is unused - check next track
	jr z, .NextTrack

	;Check counter for envelope sequence speed
	ld b, a
	ld a, [hl+]
	;Decrease the counter
	dec [hl]
	;If not 0, then check next track
	jr nz, .NextTrack

	;Otherwise, reset counter
	ld [hl], a
	;Also load current track number into variable
	push bc
	ld a, c
	ld [CurEnvIndexTrack], a
	call .ProcEnvSeqs3
	pop bc

.NextTrack
	;Check next track
	pop hl
	ld de, $59
	add hl, de
	pop de
	inc de
	inc c
	ld a, c
	;If checked all tracks, then return
	cp 8
	jr c, .ProcEnvSeqs2

	ret


.ProcEnvSeqs3
	;Check if track is currently playing
	ld a, e
	ld e, l
	ld d, h
	or a
	;If not, then don't look for new value
	jr z, .ProcEnvSeqs6

	;Otherwise, get track envelope (rest)
	ld hl, -6
	add hl, de
	ld c, [hl]
	
	;Also get note duration remaining
	ld hl, -4
	add hl, de
	ld a, [hl]
	
	;Check if note is still playing
	or a
	ld a, c
	;Skip loading new value if not
	jr z, .ProcEnvSeqs6

	;If so, then get envelope sequence index
	ld hl, 1
	add hl, de
	ld a, [hl]
	;If 16 or more, then set to 15
	cp 16
	jr c, .ProcEnvSeqs4

	ld a, 15

.ProcEnvSeqs4
	;Increase envelope sequence index
	ld c, a
	inc a
	ld [hl], a
	;Get pointer for envelope sequence
	inc hl
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	;Divide by 2 to find index in sequence
	ld a, c
	srl a
	add l
	ld l, a
	ld a, 0
	adc h
	ld h, a
	ld a, [hl]
	;If index is over 80, then swap nybbles
	bit 0, c
	jr nz, .ProcEnvSeqs5

	swap a

.ProcEnvSeqs5
	;Mask out upper 4 bits of envelope
	and %00001111

.ProcEnvSeqs6
	;Get current envelope value
	ld c, a
	ld hl, -7
	add hl, de
	ld a, [hl]
	;Mask out upper 4 bits of current envelope
	and %00001111
	
	;Add the resulting index value and then subtract $0F
	add c
	sub $0F
	ld b, 0
	;If subtraction resulted in a negative value, then skip getting volume
	jr c, .ProcEnvSeqs7

	;Get current channel number
	ld hl, -11
	add hl, de
	ld c, [hl]
	;Then get initial volume from envelope
	call Audio1_GetEnvVol

.ProcEnvSeqs7
	;Get NRx2 value
	ld hl, $46
	add hl, de
	ld a, [hl]
	;And mask off upper 4 bits
	and %00001111
	or b
	push hl
	;Load new value in NRx2 variable
	ld hl, $46
	add hl, de
	cp [hl]
	ld [hl], a
	
	pop hl
	;If value is the same, then return
	ret z

	;Otherwise, set trigger for NRx4 value
	ld [hl], a
	inc hl
	inc hl
	set 7, [hl]
	
	;Then, set "trigger" value for current track
	ld a, [CurEnvIndexTrack]
	ld c, a
	ld b, 0
	ld hl, TrackTrigVals
	add hl, bc
	ld [hl], $FF
	ret

;These values do not appear to be used...
Audio1_UnkVals:
	db $FE,$FD,$FB,$F7

;Process vibrato (This code is not actually reached, so vibrato is unused)
;Get values of first track (SFX channel 1)
Audio1_ProcVibSeqs:
	ld c, 0
	ld hl, SFX1RAM+$15
	ld de, ChanPlayVals

;Check if channel is currently playing
.ProcVibSeqs2
	push de
	push hl
	ld a, [de]
	or a
	;If not, then check next track
	jr z, .NextTrack

	;Otherwise, check vibrato number
	ld a, [hl+]
	or a
	;If 0 (unused), then check next track
	jr z, .NextTrack

	;Otherwise, check counter of vibrato
	inc hl
	ld a, [hl]
	or a
	;If 0, then check delay
	jr z, .ProcVibSeqs3

	;Otherwise, decrement counter
	dec [hl]
	jr .NextTrack

.ProcVibSeqs3
	;If counter is 0, then get delay
	inc hl
	ld a, [hl+]
	;And then decrease delay remaining
	dec [hl]
	;If delay is not done, then check next track
	jr nz, .NextTrack

	;Reset the counter
	ld [hl], a
	push bc
	;Load the current track number into RAM variable
	ld a, c
	ld [CurEnvIndexTrack], a
	call .ProcVibSeqs4
	pop bc

.NextTrack
	;Check next track
	pop hl
	ld de, $59
	add hl, de
	pop de
	inc de
	inc c
	ld a, c
	cp 8
	;If checked all tracks, then return
	jr c, .ProcVibSeqs2

	ret


.ProcVibSeqs4
	;Get pointer of vibrato
	inc hl
	ld e, l
	ld d, h
	ld l, e
	ld h, d
	ld c, [hl]
	inc hl
	ld b, [hl]

.ProcVibSeqs5
	;Get value of current pointer
	ld a, [bc]
	;Then advance pointer
	inc bc
	ld [hl], b
	dec hl
	ld [hl], c
	;Check if vibrato sequence has reached end (80)
	cp $80
	;If not, then continue processing value
	jr nz, .ProcVibSeqs6

	;Otherwise, go back to start of vibrato sequence - get pointer value from table
	push hl
	ld hl, -5
	add hl, de
	ld a, [hl]
	add a
	ld hl, Audio1_VibTab-2
	add l
	ld l, a
	ld a, 0
	adc h
	ld h, a
	ld c, [hl]
	inc hl
	ld b, [hl]
	pop hl
	inc hl
	jr .ProcVibSeqs5

.ProcVibSeqs6
	;Check if byte is 0 (no change)
	or a
	;Return if so
	ret z

	;Otherwise, get current NR13 value
	ld hl, $3C
	add hl, de
	ld b, 0
	;Check if value is negative - if so, then subtract
	cp $80
	jr c, .ProcVibSeqs7

	dec b

.ProcVibSeqs7
	;Add the total to NRx3
	add [hl]
	ld [hl], a
	;In NRx4 register, add signed/unsigned change value
	inc hl
	ld a, b
	adc [hl]
	;Mask out upper 7 bits of NRx4 (get period values)
	and %00000111
	ld b, a
	;Get NRx4 value again and mask out lower 6 bits (get trigger and length enable)
	ld a, [hl]
	and %11000000
	or b
	;Load the final values into NRx4 RAM variable
	ld [hl], a
	dec hl
	push hl
	;Now get current track
	ld a, [CurEnvIndexTrack]
	add a
	ld hl, Audio1_PerAddrs
	add l
	ld l, a
	ld a, 0
	adc h
	ld h, a
	ld c, [hl]
	inc hl
	ld b, [hl]
	pop hl
	ld a, [hl]
	ld [bc], a
	inc bc
	inc hl
	ld a, [hl]
	ld [bc], a
	ret


Audio1_PerAddrs:
	dw rNR13		;Channel 1
	dw rNR23		;Channel 2
	dw rNR33		;Channel 3
	dw rNR43		;Channel 4

;Process the register values for output
Audio1_ProcRegs:
	;Set panning to all
	ld a, %11111111
	ld [CurPan], a
	;Also set panning value to 0
	xor a
	ld [ChanPanVal], a
	ld c, 0
	ld hl, Ch1IDRAM

.ProcRegs2
	;Check if track is playing?
	ld a, [hl]
	or a
	;If not, then...
	jr z, .ProcRegs4

	;Otherwise, get current track's pan value
	ld b, a
	push hl
	ld hl, TrackPanVals-1
	add l
	ld l, a
	ld a, 0
	adc h
	ld h, a
	;OR with current panning value
	ld a, [ChanPanVal]
	or [hl]
	ld [ChanPanVal], a
	;Then get current track's trigger values
	ld a, b
	ld hl, TrackTrigVals-1
	add l
	ld l, a
	ld a, 0
	adc h
	ld h, a
	ld a, [hl]
	;Check if trigger is on
	or a
	;If not, then...
	jr z, .ProcRegs3

	;Otherwise, clear trigger
	ld [hl], 0
	push bc
	;Get current track RAM address
	ld a, b
	call Audio1_GetTrackRAM
	push hl
	;Get sweep value? (doesn't seem to be loaded)
	ld de, $53
	add hl, de
	ld a, c
	;Output the audio registers
	call Audio1_OutputAudio
	pop hl
	;Reset period trigger
	ld de, $57
	add hl, de
	res 7, [hl]
	pop bc

.ProcRegs3
	pop hl

.ProcRegs4
	;Increase channel number
	ld de, $04
	add hl, de
	inc c
	ld a, c
	cp 4
	;If less than 4, then repeat for every channel
	jr c, .ProcRegs2
	
	;Otherwise, set panning values
	ld a, [ChanPanVal]
	ld c, a
	ld a, [CurPan]
	and c
	ldh [rNR51], a
	ret


Audio1_OutputAudio:
;Prepare to output the audio registers
	push bc
	push af
	;If channel value is 1, then skip
	or a
	jr nz, .OutputAudio2

	;Otherwise, 
	ld c, a
	;Mask out the lower 4 bits of unknown value
	ld a, [UnkD9DD]
	and %11110000
	;Check channel value again
	ld a, c
	;If channel value is 0, then keep checking?
	jr nz, .OutputAudio2

	;Otherwise, disable channel 1
	ld a, %11101110
	ld [CurPan], a
	;Set bits of unknown value
	ld a, [UnkD9DD]
	and %00001111
	or %00010000
	ld [UnkD9DD], a
	ld a, c

.OutputAudio2
	;Check if channel is 3 (wave)
	cp 2
	jr nz, .OutputAudio3

	;If so, then turn off DAC
	push af
	ldh a, [rNR30]
	and %01111111
	ldh [rNR30], a
	pop af

.OutputAudio3
	;Get current channel's NRx0 or NRx1 register address and its RAM variable
	push hl
	and %00000011
	ld c, a
	add a
	add c
	ld hl, Audio1_NRx0x1Vals
	add l
	ld l, a
	ld a, 0
	adc h
	ld h, a
	ld e, [hl]
	inc hl
	ld d, [hl]
	inc hl
	ld c, [hl]
	ld b, 0
	pop hl
	ld a, c
	;If not 5 (4), then is NRx1
	cp 4
	jr nz, .OutputAudio4

	inc hl

;Ready to output audio!
.OutputAudio4
	;Write to the direct registers using the values from RAM
	call JumpFill
	pop af
	;If channel 3 (wave), then also turn on channel 3 and its DAC
	cp 2
	jr nz, .OutputAudio5

	ldh a, [rNR52]
	or %00000100
	ld a, %10000000
	ldh [rNR30], a

.OutputAudio5
	pop bc
	ret

Audio1_NRx0x1Vals:
	dw rNR10
	db 5
	dw rNR21
	db 4
	dw rNR30
	db 5
	dw rNR41
	db 4

Audio1_CheckChSlots:
	;Check for current sound slot
	ld a, [CurSoundSlot]
	ld c, a
	ld b, 8
	ld hl, ChanSlotVals
	ld de, ChanPlayVals

.CheckChSlots2
	;Check if the current number matches A
	ld a, [hl+]
	cp c
	;If not, then check next slot
	jr nz, .CheckChSlots3

	;Otherwise, check if slot is playing/in use
	ld a, [de]
	or a
	;Return if not
	ret nz

;If slot is in use, then check next slot
.CheckChSlots3
	inc de
	dec b
	jr nz, .CheckChSlots2

;When all slots complete checking, then see if master slot is in use
	ld a, [MasterSlotPlay]
	;If not, then disable channel
	or a
	jr z, .DisableSlot

	;Otherwise, check if slot is full?
	cp $FF
	jr z, .CheckChSlotsProc

	;Otherwise, decrease slot
	dec a
	ld [MasterSlotPlay], a

.CheckChSlotsProc
	call Audio1_CheckSlotTrack
	or a
	ret


.DisableSlot
	ld a, [CurSoundSlot]
	call Audio1_EndSound
	scf
	ret


Audio1_CheckSlotTrack:
	;Check for tracks using current slot
	ld a, [CurSoundSlot]
	ld c, a
	ld b, 8
	ld hl, ChanSlotVals

.CheckSlotTrack2
	;If track is not current slot, then skip to next track
	ld a, [hl]
	cp c
	jr nz, .CheckSlotTrack3

	ld a, 9
	sub b
	push hl
	push bc
	;Initialize track RAM variables
	call Audio1_InitTrackVars
	pop bc
	pop hl

.CheckSlotTrack3
	inc hl
	dec b
	jr nz, .CheckSlotTrack2

	ret


Audio1_InitTrackVars:
	;Load current track number in RAM
	ld [CurTrackIndex], a
	;Then get RAM for current track
	call Audio1_GetTrackRAM
	ld a, l
	ld [CurTrackRAM], a
	ld a, h
	ld [CurTrackRAM+1], a
	ld c, l
	ld b, h
	
	;Initialize default RAM values
	ld e, [hl]
	inc hl
	ld d, [hl]
	inc hl
	ld [hl], e
	inc hl
	ld [hl], d
	;Set transpose to 0
	ld hl, $05
	add hl, bc
	ld [hl], 0
	
	;Set note duration to 0
	ld hl, $0A
	add hl, bc
	ld [hl], 0
	
	;Set ? to 2
	ld hl, $0E
	add hl, bc
	ld [hl], 2
	
	;Set vibrato delay to 2
	ld hl, $18
	add hl, bc
	ld [hl], 2
	
	;Set vibrato speed to 40
	ld hl, $16
	add hl, bc
	ld [hl], 40
	
	;Set envelope
	ld hl, $08
	add hl, bc
	ld [hl], %00001111
	
	;Set delay to 1
	ld hl, $0C
	add hl, bc
	ld [hl], 1
	
	;Set previous note duration to 1
	ld hl, $0F
	add hl, bc
	ld [hl], 1
	
	;Set track channel number
	ld hl, $04
	add hl, bc
	ld e, [hl]
	
	;Initialize panning of channel
	ld a, $03
	call Audio1_InitPan
	
	;Set track envelope sequence to 0
	xor a
	call Audio1_EventEnvSeq
	
	;Set track channel number
	ld hl, $04
	add hl, bc
	ld e, [hl]
	
	;Set sweep
	ld hl, $53
	add hl, bc
	ld [hl], %00001000
	
	;If channel is 4 (noise), then set to other value
	ld a, e
	cp 3
	jr nz, .InitTrackVars2

	ld [hl], %10000000

.InitTrackVars2
	;Get track channel number again
	ld hl, $04
	add hl, bc
	ld a, [hl]
	
	;Load the envelope register address pointer from table
	add a
	ld hl, Audio1_EnvAddrs-2
	add l
	ld l, a
	ld a, 0
	adc h
	ld h, a
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	;Set envelope direction
	ld [hl], %00001000
	;Set channel play value to FF (busy)
	ld a, [CurTrackIndex]
	ld hl, ChanPlayVals-1
	add l
	ld l, a
	ld a, 0
	adc h
	ld h, a
	ld [hl], $FF
	ret

Audio1_EnvAddrs:
	dw rNR12		;Channel 1
	dw rNR22		;Channel 2
	dw rNR32		;Channel 3
	dw rNR42		;Channel 4


;Initialize pan value for track
Audio1_InitPan:
	and %00000011
	ld d, a
	rrca
	swap a
	or d
	and %00010001
	ld d, a
	ld a, e

.InitPan2
	dec a
	jr z, .InitPan3

	rlc d
	jr .InitPan2

;Load initialized value into RAM
.InitPan3:
	ld a, [CurTrackIndex]
	ld hl, TrackPanVals-1
	add l
	ld l, a
	ld a, 0
	adc h
	ld h, a
	ld [hl], d
	ret


;Get current track position
Audio1_GetCurPos:
	ld hl, $04
	add hl, bc
	ld a, [hl]

;Clear the current channel volume
Audio1_ChanOff:
	;Load channel "off" values from table
	ld hl, Audio1_ChanOffVals-1
	add l
	ld l, a
	ld a, 0
	adc h
	ld h, a
	;Mask out the current pan value
	ldh a, [rNR51]
	and [hl]
	ldh [rNR51], a
	ret


;These aren't used?
Audio1_NRx2Vals:
	dw rNR12
	dw rNR22
	dw rNR32
	dw rNR42
	
Audio1_NRx4Vals:
	dw rNR14
	dw rNR24
	dw rNR34
	dw rNR44
	
Audio1_ChanOffVals:
	db %11101110	;Channel 1 off
	db %11011101	;Channel 2 off
	db %10111011	;Channel 3 off
	db %01110111	;Channel 4 off

Audio1_Waveforms:
.Waveform0
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $ED, $CB, $A9, $87, $65, $43, $21, $00
.Waveform1
	db $9B, $E0, $BA, $98, $76, $54, $32, $10, $9B, $E0, $BA, $98, $76, $54, $32, $10
.Waveform2
	db $FE, $DC, $BA, $98, $76, $54, $32, $10, $FE, $DC, $BA, $98, $76, $54, $32, $10
.Waveform3
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $F0
.Waveform4
	db $9B, $E0, $BA, $98, $76, $54, $32, $10, $9B, $E0, $BA, $98, $76, $54, $32, $10
.Waveform5
	db $FD, $B9, $75, $31, $EC, $A8, $64, $20, $FD, $B9, $75, $31, $EC, $A8, $64, $20
.Waveform6
	db $FE, $DC, $CD, $ED, $CA, $86, $42, $10, $FE, $DC, $CD, $ED, $CA, $86, $42, $10
.Waveform7
	db $FD, $B9, $AB, $97, $65, $43, $21, $10, $FD, $B9, $AB, $97, $65, $43, $21, $10
.Waveform8
	db $44, $44, $44, $46, $67, $8A, $CF, $B8, $44, $44, $44, $46, $67, $8A, $CF, $B8
.Waveform9
	db $FF, $A8, $FF, $A8, $77, $66, $55, $42, $FF, $A8, $FF, $A8, $77, $66, $55, $42
.WaveformA
	db $FF, $AA, $88, $88, $88, $88, $88, $88, $FF, $AA, $88, $88, $88, $88, $88, $88
.WaveformB
	db $FF, $AA, $88, $88, $88, $88, $88, $88, $FF, $AA, $88, $88, $88, $88, $88, $88
.WaveformC
	db $FF, $AA, $88, $88, $88, $88, $88, $88, $FF, $AA, $88, $88, $88, $88, $88, $88
.WaveformD
	db $FF, $AA, $88, $88, $88, $88, $88, $88, $FF, $AA, $88, $88, $88, $88, $88, $88
.WaveformE
	db $FF, $AA, $88, $88, $88, $88, $88, $88, $FF, $AA, $88, $88, $88, $88, $88, $88
.WaveformF
	db $FF, $AA, $88, $88, $88, $88, $88, $88
Audio1_EnvSeqs:
.EnvSeq0
	db $FF, $AA, $88, $88, $88, $88, $88, $88, $FF, $CC, $AA, $AA, $AA, $88, $88, $77
.EnvSeq1
	db $FF, $55, $77, $99, $AA, $BB, $DD, $FF, $FE, $DC, $BA, $98, $89, $AB, $CD, $EF
.EnvSeq2
	db $89, $AB, $CD, $EF, $FE, $DC, $BA, $98, $FD, $B9, $75, $31, $EC, $A8, $64, $20
.EnvSeq3
	db $FE, $DC, $CD, $ED, $CA, $86, $42, $10, $FD, $B9, $AB, $97, $65, $43, $21, $10
.EnvSeq4
	db $44, $44, $44, $46, $67, $8A, $CF, $B8, $FF, $A8, $FF, $A8, $77, $66, $55, $42
.EnvSeq5
	db $FF, $11, $11, $11, $11, $11, $11, $11, $FF, $CC, $88, $88, $66, $44, $22, $11
.EnvSeq6
	db $FF, $AA, $88, $88, $88, $77, $66, $66, $BB, $AA, $66, $66, $44, $44, $22, $22
.EnvSeq7
	db $FF, $FF, $88, $AA, $88, $77, $66, $55, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	
Audio1_VibSeq00:
	db $00, $FF, $00, $00, $01, $00, $00, $FF, $00, $01, $00, $80
Audio1_VibSeq01:
	db $01, $FF, $01, $FF, $01, $FF, $01, $FF, $01, $FF, $80
Audio1_VibSeq02:
	db $01, $FF, $01, $FF, $01, $FF, $01, $FF, $01, $80
Audio1_VibSeq03:
	db $00, $FF, $00, $01, $00, $80
Audio1_VibSeq04:
	db $00, $FF, $00, $01, $00, $FF, $80
Audio1_VibSeq05:
	db $00, $FF, $00, $00, $01, $00, $00, $FF, $00, $80
Audio1_VibSeq06:
	db $00, $FF, $00, $00, $01, $00, $00, $FF, $00, $80
Audio1_VibSeq07:
	db $00, $FF, $00, $00, $01, $00, $00, $FF, $00, $80
Audio1_VibSeq08:
	db $00, $FF, $00, $00, $01, $00, $00, $FF, $00, $80
Audio1_VibSeq09:
	db $00, $FF, $00, $00, $01, $00, $00, $FF, $00, $80
Audio1_VibSeq0A:
	db $00, $FF, $00, $00, $01, $00, $00, $FF, $00, $80
Audio1_VibSeq0B:
	db $00, $FF, $00, $00, $01, $00, $00, $FF, $00, $80
Audio1_VibSeq0C:
	db $00, $FF, $00, $00, $01, $00, $00, $FF, $00, $80
Audio1_VibSeq0D:
	db $00, $FF, $00, $00, $01, $00, $00, $FF, $00, $80
Audio1_VibSeq0E:
	db $00, $FF, $00, $00, $01, $00, $00, $FF, $00, $80
	
Audio1_VibTab:
	dw Audio1_VibSeq00
	dw Audio1_VibSeq01
	dw Audio1_VibSeq02
	dw Audio1_VibSeq03
	dw Audio1_VibSeq04
	dw Audio1_VibSeq05
	dw Audio1_VibSeq06
	dw Audio1_VibSeq07
	dw Audio1_VibSeq08
	dw Audio1_VibSeq09
	dw Audio1_VibSeq0A
	dw Audio1_VibSeq0B
	dw Audio1_VibSeq0C
	dw Audio1_VibSeq0D
	dw Audio1_VibSeq0E
	
Audio1_NoiseVals:
	db $00, $11, $22, $33, $44, $55, $37, $70
	db $65, $8A, $8F, $D0, $D4, $60, $64, $65
	db $87, $83, $75, $8B, $8A, $89, $7A, $7B
	db $6D, $6E, $60, $63, $D4, $D8, $DF, $78
	db $45, $40, $45, $30, $70, $25, $23, $21
	db $87, $45, $44, $43, $42, $55, $54, $53
	db $52
	
Audio1_FreqTab:
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
	
Audio1_SFX_UFO:
	db $02, $01
	dw Audio1_SFX_UFOC1
	db SFX1
	dw 0
	db SFX2
	dw 0
	db SFX3
	dw 0
	db SFX4
	
Audio1_SFX_UFOC1:
	db $FE, $0A
	db $F5, $00
	db $F4, $40
	db $FC, $0F
	db $F8, $00
	db $FA, $05
	db $F0, $01
	db $50, $01
	db $51, $01
	db $52, $01
	db $53, $01
	db $54, $01
	db $F0, $02
	db $50, $01
	db $51, $01
	db $52, $01
	db $53, $01
	db $54, $01
	db $B0, $EE
	
Audio1_SFX_Empty3:
	db $02, $01
	dw Audio1_SFX_Empty2C2
	db SFX1
	dw 0
	db SFX2
	dw 0
	db SFX3
	dw 0
	db SFX4

Audio1_SFX_Explode:
	db $01, $03
	dw Audio1_SFX_ExplodeC1
	db SFX1
	dw Audio1_SFX_ExplodeC2
	db SFX2
	dw 0
	db SFX3
	dw 0
	db SFX4
Audio1_SFX_ExplodeC1:
	db $FE, $00
	db $F4, $40
	db $FC, $0F
	db $F8, $00
	db $FA, $05
	db $F5, $2C
	db $FD, $00
	db $00, $01
	db $FE, $0C
	db $60, $0C
	db $F5, $08
	db $10, $01
	db $F5, $2B
	db $FE, $08
	db $38, $02
	db $FF
Audio1_SFX_ExplodeC2:
	db $FC, $0D
	db $F4, $40
	db $F8, $00
	db $FA, $03
	db $FE, $00
	db $00, $01
	db $FE, $0A
	db $46, $01
	db $39, $01
	db $30, $01
	db $29, $01
	db $26, $01
	db $24, $01
	db $23, $01
	db $22, $01
	db $00, $01
	db $00, $01
	db $FF
	
Audio1_SFX_Electricity:
	db $01, $02
	dw Audio1_SFX_ElectricityC1
	db SFX1
	dw 0
	db SFX2
	dw 0
	db SFX3
	dw 0
	db SFX4
Audio1_SFX_ElectricityC1:
	db $FE, $0A
	db $F5, $00
	db $F4, $C0
	db $FC, $0F
	db $F8, $00
	db $FA, $05
	db $38, $01
	db $39, $01
	db $A8, $F8
	db $B1, $F7
	db $FF
	
Audio1_SFX_Shoot:
	db $01, $02
	dw Audio1_SFX_ShootC1
	db SFX1
	dw 0
	db SFX2
	dw 0
	db SFX3
	dw 0
	db SFX4
Audio1_SFX_ShootC1:
	db $FE, $0A
	db $F5, $17
	db $F4, $80
	db $FC, $0F
	db $F8, $00
	db $FA, $05
	db $41, $04
	db $FF

Audio1_SFX_EnemyShoot:
	db $01, $01
	dw Audio1_SFX_EnemyShootC1
	db SFX1
	dw 0
	db SFX2
	dw 0
	db SFX3
	dw 0
	db SFX4
Audio1_SFX_EnemyShootC1:
	db $FE, $0A
	db $F5, $1E
	db $F4, $80
	db $FC, $00
	db $F8, $00
	db $FB, $02
	db $50, $03
	db $FF
	
Audio1_SFX_Click:
	db $01, $05
	dw Audio1_SFX_ClickC1
	db SFX1
	dw 0
	db SFX2
	dw 0
	db SFX3
	dw 0
	db SFX4
Audio1_SFX_ClickC1:
	db $FE, $0A
	db $F4, $40
	db $FC, $05
	db $F8, $01
	db $FD, $00
	db $FB, $05
	db $F5, $08
	db $4B, $02
	db $FF
	
Audio1_SFX_Health:
	db $01, $05
	dw Audio1_SFX_HealthC1
	db SFX1
	dw 0
	db SFX2
	dw 0
	db SFX3
	dw 0
	db SFX4
Audio1_SFX_HealthC1:
	db $FE, $0A
	db $F4, $40
	db $FC, $05
	db $F8, $01
	db $FD, $00
	db $FB, $05
	db $F5, $08
	db $51, $02
	db $FF

Audio1_SFX_Land:
	db $01, $02
	dw Audio1_SFX_LandC1
	db SFX1
	dw 0
	db SFX2
	dw 0
	db SFX3
	dw 0
	db SFX4
Audio1_SFX_LandC1:
	db $FE, $0A
	db $F4, $40
	db $FC, $05
	db $F8, $01
	db $FB, $05
	db $F5, $08
	db $48, $03
	db $49, $03
	db $FF

Audio1_SFXUnk:
	db $01, $05
	dw Audio1_SFXUnkC1
	db SFX1
	dw 0
	db SFX2
	dw 0
	db SFX3
	dw 0
	db SFX4
Audio1_SFXUnkC1:
	db $FE, $0A
	db $F4, $40
	db $FC, $05
	db $F8, $00
	db $FB, $05
	db $F5, $08
	db $47, $02
	db $48, $02
	db $49, $02
	db $47, $02
	db $48, $02
	db $49, $02
	db $FF
	
Audio1_SFX_EnemyHit:
	db $01, $03
	dw Audio1_SFX_EnemyHitC1
	db SFX1
	dw 0
	db SFX2
	dw 0
	db SFX3
	dw Audio1_SFX_EnemyHitC2
	db SFX4
Audio1_SFX_EnemyHitC1:
	db $FE, $0F
	db $F4, $40
	db $FC, $0F
	db $F8, $00
	db $FA, $05
	db $FE, $00
	db $FD, $00
	db $00, $04
	db $F5, $14
	db $47, $04
	db $FE, $0F
	db $F5, $1B
	db $52, $03
	db $FF
Audio1_SFX_EnemyHitC2:
	db $FE, $05
	db $FB, $06
	db $F9, $10
	db $24, $01
	db $24, $01
	db $25, $01
	db $FF
	
Audio1_SFX_Deflect:
	db $00, $03
	dw Audio1_SFX_DeflectC1
	db SFX1
	dw 0
	db SFX2
	dw 0
	db SFX3
	dw 0
	db SFX4
Audio1_SFX_DeflectC1:
	db $FE, $0C
	db $F4, $40
	db $FC, $0F
	db $F8, $00
	db $FA, $05
	db $F5, $26
	db $5A, $02
	db $FF

Audio1_SFX_Select:
	db $00, $05
	dw Audio1_SFX_SelectC1
	db SFX1
	dw 0
	db SFX2
	dw 0
	db SFX3
	dw 0
	db SFX4
Audio1_SFX_SelectC1:
	db $FE, $08
	db $F4, $40
	db $FC, $0F
	db $F8, $00
	db $FA, $05
	db $47, $04
	db $42, $08
	db $FE, $00
	db $FF

Audio1_SFX_Door1:
	db $00, $05
	dw Audio1_SFX_Door1C1
	db SFX1
	dw 0
	db SFX2
	dw 0
	db SFX3
	dw 0
	db SFX4
Audio1_SFX_Door1C1:
	db $FE, $0D
	db $F4, $80
	db $FC, $0F
	db $F8, $00
	db $FA, $05
	db $F5, $34
	db $40, $04
	db $F5, $34
	db $50, $08
	db $FF
	
Audio1_SFX_Door2:
	db $00, $05
	dw Audio1_SFX_Door2C1
	db SFX3
	dw 0
	db SFX4
	dw 0
	db SFX1
	dw 0
	db SFX2
Audio1_SFX_Door2C1:
	db $FE, $08
	db $F4, $40
	db $FC, $00
	db $F8, $00
	db $FB, $05
	db $F5, $24
	db $37, $06
	db $FF
	
Audio1_SFX_Empty2:
	db $00, $03
	dw 0
	db SFX3
	dw 0
	db SFX4
	dw 0
	db SFX1
	dw Audio1_SFX_Empty2C2
	db SFX2
Audio1_SFX_Empty2C2:
	db $FE, $00
	db $FD, $00
	db $00, $01
	db $FF
	
Audio1_SFX_CutAttack:
	db $00, $03
	dw Audio1_SFX_CutAttackC1
	db SFX3
	dw 0
	db SFX4
	dw 0
	db SFX1
	dw Audio1_SFX_CutAttackC2
	db SFX2
Audio1_SFX_CutAttackC1:
	db $FE, $07
	db $F4, $40
	db $FC, $0E
	db $F8, $00
	db $F5, $25
	db $40, $02
	db $46, $02
	db $00, $02
	db $F5, $00
	db $30, $02
	db $FE, $04
	db $F5, $25
	db $40, $02
	db $46, $02
	db $00, $02
	db $F5, $00
	db $30, $02
	db $FE, $06
	db $F5, $25
	db $40, $02
	db $46, $02
	db $00, $02
	db $F5, $00
	db $30, $02
	db $FE, $03
	db $F5, $25
	db $3A, $02
	db $46, $06
	db $00, $10
	db $B3, $E3
	db $FF
Audio1_SFX_CutAttackC2:
	db $FE, $04
	db $FB, $02
	db $26, $02
	db $FE, $02
	db $26, $02
	db $FE, $03
	db $27, $02
	db $FE, $01
	db $27, $02
	db $FE, $02
	db $28, $02
	db $FE, $01
	db $28, $02
	db $FE, $01
	db $26, $02
	db $FE, $01
	db $26, $02
	db $A1, $EF
	db $FE, $02
	db $28, $02
	db $FE, $01
	db $28, $03
	db $FE, $01
	db $26, $02
	db $FE, $01
	db $26, $02
	db $FE, $01
	db $28, $02
	db $FE, $01
	db $28, $03
	db $FE, $01
	db $26, $02
	db $FE, $01
	db $26, $02
	db $A3, $DE
	db $FF

Audio1_SFX_PlayerExplode:
	db $00, $0B
	dw Audio1_SFX_PlayerExplodeC1
	db SFX1
	dw 0
	db SFX2
	dw 0
	db SFX3
	dw 0
	db SFX4
Audio1_SFX_PlayerExplodeC1:
	db $F4, $40
	db $FC, $00
	db $F8, $00
	db $FB, $06
	db $F5, $1F
	db $FD, $00
	db $00, $01
	db $FE, $0C
	db $70, $12
	db $FE, $0A
	db $70, $12
	db $FE, $08
	db $70, $12
	db $FE, $06
	db $70, $12
	db $FE, $04
	db $70, $12
	db $FE, $02
	db $70, $12
	db $FF

Audio1_SFX_ExtraLife:
	db $01, $07
	dw Audio1_SFX_ExtraLifeC1
	db SFX1
	dw 0
	db SFX2
	dw 0
	db SFX3
	dw 0
	db SFX4
Audio1_SFX_ExtraLifeC1:
	db $FE, $06
	db $F4, $40
	db $FC, $00
	db $F8, $00
	db $FB, $06
	db $FE, $08
	db $44, $01
	db $FE, $04
	db $44, $01
	db $FE, $08
	db $47, $01
	db $FE, $04
	db $47, $01
	db $FE, $08
	db $50, $01
	db $FE, $04
	db $50, $01
	db $FE, $08
	db $52, $01
	db $FE, $04
	db $52, $01
	db $FE, $08
	db $54, $01
	db $FE, $04
	db $54, $01
	db $FE, $08
	db $57, $01
	db $FE, $04
	db $57, $01
	db $FE, $08
	db $60, $01
	db $FE, $04
	db $60, $01
	db $FE, $08
	db $62, $01
	db $FE, $04
	db $62, $01
	db $FE, $08
	db $64, $01
	db $FE, $04
	db $64, $01
	db $FE, $06
	db $47, $01
	db $FE, $02
	db $47, $01
	db $FE, $06
	db $50, $01
	db $FE, $02
	db $50, $01
	db $FE, $06
	db $52, $01
	db $FE, $02
	db $52, $01
	db $FE, $06
	db $54, $01
	db $FE, $02
	db $54, $01
	db $FE, $06
	db $57, $01
	db $FE, $02
	db $57, $01
	db $FE, $06
	db $60, $01
	db $FE, $02
	db $60, $01
	db $FE, $06
	db $62, $01
	db $FE, $02
	db $62, $01
	db $FE, $06
	db $64, $01
	db $FE, $02
	db $64, $01
	db $FF

Audio1_SFX_Empty1:
	db $00, $02
	dw Audio1_SFX_Empty1C4
	db SFX4
	dw 0
	db SFX3
	dw 0
	db SFX1
	dw 0
	db SFX2
Audio1_SFX_Empty1C4:
	db $FE, $00
	db $F4, $40
	db $FC, $00
	db $F8, $00
	db $FB, $06
	db $FD, $00
	db $00, $01
	db $FF
	
Audio1_SFX_Wheel:
	db $00, $03
	dw Audio1_SFX_WheelC1
	db SFX4
	dw 0
	db SFX3
	dw 0
	db SFX1
	dw 0
	db SFX2
Audio1_SFX_WheelC1:
	db $FE, $06
	db $F4, $40
	db $FC, $00
	db $F8, $00
	db $FB, $06
	db $F5, $25
	db $40, $01
	db $3B, $01
	db $40, $01
	db $41, $01
	db $40, $01
	db $41, $01
	db $42, $01
	db $41, $01
	db $42, $01
	db $43, $01
	db $42, $01
	db $43, $01
	db $44, $01
	db $43, $01
	db $44, $01
	db $45, $01
	db $44, $01
	db $45, $01
	db $46, $01
	db $45, $01
	db $46, $01
	db $47, $01
	db $46, $01
	db $47, $01
	db $48, $01
	db $47, $01
	db $48, $01
	db $49, $01
	db $48, $01
	db $49, $01
	db $4A, $01
	db $49, $01
	db $4A, $01
	db $4B, $01
	db $4A, $01
	db $4B, $01
	db $50, $01
	db $4B, $01
	db $50, $01
	db $50, $01
	db $4B, $01
	db $50, $01
	db $51, $01
	db $50, $01
	db $51, $01
	db $52, $01
	db $51, $01
	db $52, $01
	db $53, $01
	db $52, $01
	db $53, $01
	db $54, $01
	db $53, $01
	db $54, $01
	db $55, $01
	db $54, $01
	db $55, $01
	db $56, $01
	db $55, $01
	db $56, $01
	db $57, $01
	db $56, $01
	db $57, $01
	db $58, $01
	db $57, $01
	db $58, $01
	db $59, $01
	db $58, $01
	db $59, $01
	db $5A, $01
	db $59, $01
	db $5A, $01
	db $5B, $01
	db $5A, $01
	db $5B, $01
	db $60, $01
	db $5B, $01
	db $60, $01
	db $50, $01
	db $4B, $01
	db $51, $01
	db $50, $01
	db $52, $01
	db $51, $01
	db $53, $01
	db $52, $01
	db $54, $01
	db $53, $01
	db $55, $01
	db $54, $01
	db $56, $01
	db $55, $01
	db $57, $01
	db $56, $01
	db $58, $01
	db $57, $01
	db $59, $01
	db $58, $01
	db $5A, $01
	db $59, $01
	db $5B, $01
	db $5A, $01
	db $60, $01
	db $5B, $01
	db $60, $01
	db $B2, $E5
	db $FF
	
Audio1_Boss:
	db $05, $00
	dw Audio1_BossC1
	db Mus1
	dw Audio1_BossC2
	db Mus2
	dw Audio1_BossC3
	db Mus3
	dw Audio1_BossC4
	db Mus4
Audio1_BossC1:
	db $F4, $40
	db $FC, $0D
	db $F8, $01
	db $FA, $08
	db $FE, $00
	db $F5, $00
	db $00, $10
	db $FE, $0A
	db $30, $10
	db $31, $10
	db $32, $10
	db $33, $10
	db $FE, $06
	db $F8, $01
	db $F4, $80
	db $FC, $00
	db $FB, $03
	db $34, $02
	db $34, $02
	db $32, $01
	db $34, $02
	db $00, $01
	db $34, $02
	db $34, $02
	db $32, $01
	db $32, $02
	db $34, $01
	db $34, $02
	db $34, $02
	db $32, $01
	db $34, $02
	db $00, $01
	db $37, $02
	db $37, $02
	db $39, $02
	db $3B, $02
	db $32, $02
	db $32, $02
	db $30, $01
	db $32, $02
	db $00, $01
	db $32, $02
	db $32, $02
	db $30, $01
	db $30, $02
	db $32, $01
	db $32, $02
	db $32, $02
	db $30, $01
	db $32, $02
	db $00, $01
	db $37, $02
	db $37, $02
	db $39, $02
	db $3B, $02
	db $31, $02
	db $31, $02
	db $30, $01
	db $31, $02
	db $00, $01
	db $31, $02
	db $31, $02
	db $30, $01
	db $30, $02
	db $31, $01
	db $31, $02
	db $31, $02
	db $30, $01
	db $31, $02
	db $00, $01
	db $37, $02
	db $37, $02
	db $39, $02
	db $3B, $02
	db $30, $02
	db $30, $02
	db $30, $01
	db $30, $02
	db $00, $01
	db $30, $02
	db $30, $02
	db $30, $01
	db $30, $02
	db $30, $01
	db $34, $02
	db $FE, $03
	db $44, $02
	db $FE, $06
	db $36, $02
	db $FE, $03
	db $46, $02
	db $FE, $06
	db $37, $02
	db $FE, $03
	db $47, $02
	db $FE, $06
	db $39, $02
	db $FE, $03
	db $49, $02
	db $FE, $06
	db $B0, $A8
	db $FF
Audio1_BossC2:
	db $F4, $40
	db $FC, $0D
	db $F8, $01
	db $FA, $08
	db $FE, $00
	db $00, $10
	db $FE, $0A
	db $35, $10
	db $36, $10
	db $37, $10
	db $38, $10
	db $F8, $01
	db $F4, $80
	db $FC, $00
	db $FB, $03
	db $FE, $07
	db $39, $02
	db $39, $02
	db $37, $01
	db $39, $02
	db $00, $01
	db $39, $02
	db $39, $02
	db $37, $01
	db $37, $02
	db $39, $01
	db $39, $02
	db $39, $02
	db $37, $01
	db $39, $02
	db $00, $01
	db $40, $02
	db $40, $02
	db $42, $02
	db $44, $02
	db $37, $02
	db $37, $02
	db $35, $01
	db $37, $02
	db $00, $01
	db $37, $02
	db $37, $02
	db $35, $01
	db $35, $02
	db $37, $01
	db $37, $02
	db $37, $02
	db $35, $01
	db $37, $02
	db $00, $01
	db $40, $02
	db $40, $02
	db $42, $02
	db $44, $02
	db $36, $02
	db $36, $02
	db $35, $01
	db $36, $02
	db $00, $01
	db $36, $02
	db $36, $02
	db $35, $01
	db $35, $02
	db $36, $01
	db $36, $02
	db $36, $02
	db $35, $01
	db $36, $02
	db $00, $01
	db $40, $02
	db $40, $02
	db $42, $02
	db $44, $02
	db $35, $02
	db $35, $02
	db $34, $01
	db $35, $02
	db $00, $01
	db $35, $02
	db $35, $02
	db $34, $01
	db $34, $02
	db $35, $01
	db $39, $02
	db $FE, $03
	db $49, $02
	db $FE, $06
	db $3B, $02
	db $FE, $03
	db $4B, $02
	db $FE, $06
	db $40, $02
	db $FE, $03
	db $50, $02
	db $FE, $06
	db $42, $02
	db $FE, $03
	db $52, $02
	db $FE, $06
	db $B0, $A8
	db $FF
Audio1_BossC3:
	db $F2, $01
	db $FC, $0D
	db $F8, $01
	db $FD, $01
	db $FA, $06
	db $F0, $03
	db $FE, $0F
	db $19, $02
	db $A7, $FF
	db $A4, $FE
	db $F8, $01
	db $FA, $06
	db $19, $01
	db $00, $01
	db $24, $02
	db $17, $01
	db $18, $03
	db $19, $01
	db $00, $01
	db $24, $02
	db $24, $01
	db $17, $02
	db $18, $01
	db $19, $01
	db $00, $01
	db $24, $02
	db $17, $01
	db $18, $03
	db $19, $02
	db $14, $02
	db $17, $02
	db $19, $02
	db $17, $01
	db $00, $01
	db $22, $02
	db $15, $01
	db $17, $03
	db $17, $01
	db $00, $01
	db $22, $02
	db $22, $01
	db $15, $02
	db $17, $01
	db $17, $01
	db $00, $01
	db $22, $02
	db $15, $01
	db $17, $03
	db $19, $02
	db $14, $02
	db $17, $02
	db $19, $02
	db $16, $01
	db $00, $01
	db $21, $02
	db $15, $01
	db $16, $03
	db $16, $01
	db $00, $01
	db $21, $02
	db $21, $01
	db $15, $02
	db $16, $01
	db $16, $01
	db $00, $01
	db $21, $02
	db $15, $01
	db $16, $03
	db $19, $02
	db $14, $02
	db $17, $02
	db $19, $02
	db $15, $01
	db $00, $01
	db $20, $02
	db $15, $01
	db $15, $03
	db $15, $01
	db $00, $01
	db $20, $02
	db $20, $01
	db $15, $02
	db $15, $01
	db $19, $02
	db $29, $01
	db $29, $01
	db $1B, $02
	db $2B, $01
	db $2B, $01
	db $20, $02
	db $30, $01
	db $30, $01
	db $22, $02
	db $32, $01
	db $32, $01
	db $B0, $AB
	db $FF
Audio1_BossC4:
	db $F8, $01
	db $FD, $00
	db $00, $10
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $01
	db $00, $01
	db $A6, $FB
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $A2, $F6
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $01
	db $00, $01
	db $A3, $FB
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $20, $01
	db $20, $01
	db $00, $02
	db $20, $01
	db $00, $01
	db $20, $01
	db $20, $01
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $01
	db $03, $01
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $01
	db $03, $01
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $01
	db $03, $01
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $01
	db $03, $01
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $FE, $08
	db $20, $01
	db $20, $01
	db $20, $01
	db $00, $01
	db $20, $01
	db $00, $01
	db $20, $01
	db $20, $01
	db $A2, $C3
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $01
	db $03, $01
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $01
	db $03, $01
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $01
	db $03, $01
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $01
	db $03, $01
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $FE, $08
	db $20, $01
	db $20, $01
	db $20, $01
	db $00, $01
	db $20, $01
	db $20, $01
	db $20, $01
	db $20, $01
	db $B0, $85
	db $FF

Audio1_Victory:
	db $04, $00
	dw Audio1_VictoryC1
	db Mus1
	dw Audio1_VictoryC2
	db Mus2
	dw Audio1_VictoryC3
	db Mus3
	dw Audio1_VictoryC4
	db Mus4
Audio1_VictoryC1:
	db $F4, $80
	db $FC, $00
	db $F8, $01
	db $FA, $06
	db $FD, $04
	db $F5, $00
	db $FE, $0A
	db $00, $08
	db $29, $01
	db $2B, $01
	db $32, $01
	db $34, $01
	db $39, $01
	db $3B, $01
	db $42, $01
	db $44, $01
	db $49, $01
	db $4B, $01
	db $52, $01
	db $54, $01
	db $59, $01
	db $5B, $01
	db $62, $01
	db $64, $01
	db $39, $01
	db $3B, $01
	db $42, $01
	db $44, $01
	db $49, $01
	db $4B, $01
	db $52, $01
	db $54, $01
	db $44, $02
	db $44, $02
	db $00, $02
	db $46, $02
	db $46, $02
	db $00, $02
	db $47, $02
	db $47, $02
	db $00, $02
	db $49, $02
	db $47, $02
	db $49, $02
	db $4B, $0C
	db $FE, $00
	db $FD, $00
	db $00, $01
	db $FF
Audio1_VictoryC2:
	db $F4, $80
	db $FC, $00
	db $F8, $01
	db $FB, $06
	db $FD, $04
	db $FE, $0A
	db $19, $01
	db $1B, $01
	db $22, $01
	db $24, $01
	db $29, $01
	db $2B, $01
	db $32, $01
	db $34, $01
	db $39, $01
	db $3B, $01
	db $42, $01
	db $44, $01
	db $49, $01
	db $4B, $01
	db $52, $01
	db $54, $01
	db $29, $01
	db $2B, $01
	db $32, $01
	db $34, $01
	db $39, $01
	db $3B, $01
	db $42, $01
	db $44, $01
	db $49, $01
	db $4B, $01
	db $52, $01
	db $54, $01
	db $59, $01
	db $5B, $01
	db $62, $01
	db $64, $01
	db $41, $02
	db $41, $02
	db $00, $02
	db $43, $02
	db $43, $02
	db $00, $02
	db $44, $02
	db $44, $02
	db $00, $02
	db $46, $02
	db $44, $02
	db $46, $02
	db $48, $0C
	db $FE, $00
	db $FD, $00
	db $00, $01
	db $FF
Audio1_VictoryC3:
	db $F2, $01
	db $FC, $0C
	db $F8, $01
	db $FA, $06
	db $FD, $04
	db $FE, $0E
	db $00, $20
	db $19, $02
	db $19, $02
	db $00, $02
	db $1B, $02
	db $1B, $02
	db $00, $02
	db $20, $02
	db $20, $02
	db $00, $02
	db $22, $02
	db $20, $02
	db $22, $02
	db $24, $0C
	db $FE, $00
	db $FD, $00
	db $00, $01
	db $FF
Audio1_VictoryC4:
	db $F8, $01
	db $FD, $00
	db $00, $10
	db $00, $10
	db $FE, $07
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $20, $02
	db $20, $02
	db $FE, $08
	db $20, $02
	db $20, $02
	db $20, $02
	db $FE, $09
	db $20, $02
	db $20, $02
	db $20, $02
	db $FE, $0A
	db $20, $02
	db $20, $02
	db $20, $02
	db $20, $01
	db $20, $01
	db $20, $01
	db $20, $01
	db $20, $01
	db $20, $01
	db $20, $01
	db $20, $01
	db $20, $02
	db $00, $02
	db $20, $02
	db $00, $10
	db $E6, $E1
	db $FF
	
Audio1_SFX_IceAttack:
	db $00, $03
	dw Audio1_SFX_IceAttackC1
	db SFX1
	dw Audio1_SFX_IceAttackC2
	db SFX2
	dw 0
	db SFX3
	dw 0
	db SFX4
Audio1_SFX_IceAttackC1:
	db $FE, $0A
	db $F4, $00
	db $FC, $05
	db $F8, $01
	db $FD, $00
	db $FB, $05
	db $F5, $08
	db $55, $03
	db $5B, $03
	db $55, $03
	db $5B, $03
	db $FF
Audio1_SFX_IceAttackC2:
	db $FE, $0A
	db $F4, $00
	db $FC, $05
	db $F8, $01
	db $FD, $00
	db $FB, $05
	db $50, $03
	db $54, $03
	db $50, $03
	db $54, $03
	db $FF

Audio1_SFX_BigEye:
	db $00, $03
	dw Audio1_SFX_BigEyeC1
	db SFX1
	dw Audio1_SFX_BigEyeC2
	db SFX2
	dw 0
	db SFX3
	dw 0
	db SFX4
Audio1_SFX_BigEyeC1:
	db $FE, $0A
	db $F4, $00
	db $FC, $05
	db $F8, $01
	db $FD, $00
	db $FB, $05
	db $F5, $08
	db $51, $03
	db $57, $03
	db $51, $03
	db $57, $03
	db $FF
Audio1_SFX_BigEyeC2:
	db $FE, $0A
	db $F4, $00
	db $FC, $05
	db $F8, $01
	db $FD, $00
	db $FB, $05
	db $50, $03
	db $56, $03
	db $50, $03
	db $56, $03
	db $FF

Audio1_SFX_Block:
	db $00, $03
	dw Audio1_SFX_BlockC1
	db SFX1
	dw 0
	db SFX2
	dw 0
	db SFX3
	dw 0
	db SFX4
Audio1_SFX_BlockC1:
	db $FE, $0A
	db $F4, $00
	db $FC, $0C
	db $F8, $00
	db $FD, $00
	db $FA, $05
	db $F5, $08
	db $40, $12
	db $41, $03
	db $42, $03
	db $43, $03
	db $FC, $0D
	db $44, $06
	db $FF

Audio1_SFX_PlayerHit:
	db $00, $04
	dw 0
	db SFX1
	dw 0
	db SFX2
	dw 0
	db SFX3
	dw Audio1_SFX_PlayerHitC4
	db SFX4
Audio1_SFX_PlayerHitC4:
	db $F8, $00
	db $FD, $00
	db $FE, $08
	db $FB, $00
	db $F9, $00
	db $2A, $06
	db $FE, $07
	db $2B, $06
	db $FE, $04
	db $2C, $04
	db $FE, $02
	db $2D, $02
	db $FF
	
Audio1_SFX_FireAttack:
	db $00, $03
	dw Audio1_SFX_Empty2C2
	db SFX1
	dw 0
	db SFX2
	dw 0
	db SFX3
	dw Audio1_SFX_FireAttackC4
	db SFX4
Audio1_SFX_FireAttackC4:
	db $F8, $00
	db $FD, $00
	db $FE, $08
	db $2E, $12
	db $FE, $07
	db $2F, $06
	db $FE, $04
	db $30, $03
	db $FE, $02
	db $31, $01
	db $FF
	
Audio1_SFX_ElecAttack:
	db $01, $03
	dw Audio1_SFX_ElecAttackC1
	db SFX1
	dw 0
	db SFX2
	dw 0
	db SFX3
	dw 0
	db SFX4
Audio1_SFX_ElecAttackC1:
	db $FE, $08
	db $F4, $40
	db $FC, $0C
	db $F8, $00
	db $FD, $00
	db $FA, $05
	db $F5, $08
	db $48, $01
	db $39, $01
	db $48, $01
	db $39, $01
	db $4B, $01
	db $40, $01
	db $4B, $01
	db $40, $01
	db $40, $01
	db $41, $01
	db $40, $01
	db $41, $01
	db $40, $01
	db $41, $01
	db $40, $01
	db $41, $01
	db $FF

Audio1_SFX_Teleport:
	db $03, $03
	dw Audio1_SFX_TeleportC1
	db SFX1
	dw 0
	db SFX2
	dw 0
	db SFX3
	dw 0
	db SFX4
Audio1_SFX_TeleportC1:
	db $FE, $08
	db $F4, $40
	db $FC, $00
	db $F8, $00
	db $FB, $06
	db $F5, $25
	db $4B, $01
	db $48, $01
	db $43, $01
	db $51, $01
	db $FF

Audio1_SFX_Shing:
	db $01, $03
	dw Audio1_SFX_ShingC1
	db SFX1
	dw 0
	db SFX2
	dw 0
	db SFX3
	dw 0
	db SFX4
Audio1_SFX_ShingC1:
	db $FE, $0C
	db $F5, $08
	db $F4, $80
	db $FC, $00
	db $FB, $05
	db $FD, $03
	db $F8, $00
	db $69, $02
	db $72, $40
	db $FF
	
Audio1_SFX_Empty4:
	db $05, $00
	dw Audio1_SFX_Empty4C1
	db SFX1
	dw Audio1_SFX_Empty4C1
	db SFX2
	dw Audio1_SFX_Empty4C1
	db SFX3
	dw Audio1_SFX_Empty4C1
	db SFX4
Audio1_SFX_Empty4C1:
	db $FE, $00
	db $FF
	
Audio1_SFX_Heat1:
	db $01, $03
	dw Audio1_SFX_Heat1C1
	db SFX1
	dw 0
	db SFX2
	dw 0
	db SFX3
	dw 0
	db SFX4
Audio1_SFX_Heat1C1:
	db $FE, $0A
	db $F5, $08
	db $F4, $00
	db $FC, $00
	db $FB, $05
	db $FD, $04
	db $F8, $01
	db $45, $01
	db $46, $01
	db $45, $01
	db $46, $01
	db $45, $01
	db $46, $01
	db $45, $01
	db $46, $01
	db $FF
	
Audio1_SFX_Heat2:
	db $01, $03
	dw Audio1_SFX_Heat2C1
	db SFX1
	dw 0
	db SFX2
	dw 0
	db SFX3
	dw 0
	db SFX4
Audio1_SFX_Heat2C1:
	db $FE, $0A
	db $F5, $08
	db $F4, $00
	db $FC, $00
	db $FB, $05
	db $FD, $04
	db $F8, $01
	db $48, $01
	db $49, $01
	db $48, $01
	db $49, $01
	db $48, $01
	db $49, $01
	db $48, $01
	db $49, $01
	db $FF
	
Audio1_SFX_Heat3:
	db $01, $03
	dw Audio1_SFX_Heat3C1
	db SFX1
	dw 0
	db SFX2
	dw 0
	db SFX3
	dw 0
	db SFX4
Audio1_SFX_Heat3C1:
	db $FE, $0A
	db $F5, $08
	db $F4, $00
	db $FC, $00
	db $FB, $05
	db $FD, $04
	db $F8, $01
	db $50, $01
	db $51, $01
	db $50, $01
	db $51, $01
	db $50, $01
	db $51, $01
	db $50, $01
	db $51, $01
	db $FF

Audio1_CutMan:
	db $05, $00
	dw Audio1_CutManC1
	db Mus1
	dw Audio1_CutManC2
	db Mus2
	dw Audio1_CutManC3
	db Mus3
	dw Audio1_CutManC4
	db Mus4
Audio1_CutManC1:
	db $F0, $03
	db $FE, $0A
	db $F5, $00
	db $F4, $40
	db $FC, $00
	db $FB, $02
	db $F8, $01
	db $FD, $03
	db $34, $01
	db $34, $01
	db $32, $01
	db $34, $01
	db $00, $02
	db $2B, $04
	db $32, $02
	db $34, $02
	db $00, $04
	db $2B, $06
	db $2B, $02
	db $32, $06
	db $34, $01
	db $34, $01
	db $32, $01
	db $34, $01
	db $00, $02
	db $2B, $06
	db $33, $04
	db $34, $04
	db $34, $04
	db $33, $04
	db $2B, $04
	db $F0, $03
	db $FE, $08
	db $F0, $01
	db $59, $02
	db $59, $02
	db $F0, $02
	db $49, $01
	db $49, $03
	db $59, $02
	db $59, $02
	db $F0, $01
	db $49, $01
	db $49, $02
	db $49, $01
	db $A3, $F3
	db $55, $02
	db $55, $02
	db $F0, $02
	db $45, $01
	db $45, $03
	db $55, $02
	db $55, $02
	db $F0, $01
	db $45, $01
	db $45, $02
	db $45, $01
	db $54, $02
	db $54, $02
	db $F0, $02
	db $44, $01
	db $44, $03
	db $54, $02
	db $54, $02
	db $F0, $01
	db $44, $01
	db $44, $02
	db $44, $01
	db $53, $02
	db $53, $02
	db $F0, $02
	db $43, $01
	db $43, $03
	db $53, $02
	db $53, $02
	db $43, $01
	db $43, $02
	db $43, $01
	db $54, $02
	db $54, $02
	db $F0, $01
	db $44, $01
	db $44, $03
	db $54, $02
	db $54, $02
	db $54, $01
	db $F0, $02
	db $44, $01
	db $54, $01
	db $54, $01
	db $A1, $C6
	db $B0, $02
	db $B0, $A4
	db $FE, $08
	db $F4, $80
	db $FC, $0E
	db $FA, $06
	db $F8, $00
	db $FD, $06
	db $F0, $01
	db $45, $02
	db $39, $02
	db $40, $02
	db $45, $04
	db $F0, $02
	db $39, $02
	db $40, $02
	db $45, $02
	db $F0, $01
	db $44, $02
	db $37, $02
	db $40, $02
	db $44, $04
	db $F0, $02
	db $37, $02
	db $40, $02
	db $44, $02
	db $F0, $01
	db $42, $02
	db $35, $02
	db $39, $02
	db $42, $04
	db $F0, $02
	db $35, $02
	db $39, $02
	db $42, $02
	db $F0, $01
	db $44, $02
	db $40, $02
	db $44, $02
	db $F0, $02
	db $47, $02
	db $40, $02
	db $44, $02
	db $F0, $01
	db $47, $02
	db $40, $02
	db $F0, $02
	db $45, $02
	db $39, $02
	db $40, $02
	db $45, $04
	db $F0, $01
	db $39, $02
	db $40, $02
	db $45, $02
	db $F0, $02
	db $44, $02
	db $37, $02
	db $40, $02
	db $44, $04
	db $F0, $01
	db $37, $02
	db $40, $02
	db $44, $02
	db $42, $02
	db $35, $02
	db $39, $02
	db $42, $04
	db $F0, $02
	db $35, $02
	db $39, $02
	db $42, $02
	db $F0, $01
	db $49, $02
	db $3B, $02
	db $44, $02
	db $49, $02
	db $F0, $02
	db $3B, $02
	db $44, $02
	db $49, $02
	db $3B, $02
	db $F0, $01
	db $48, $02
	db $3B, $02
	db $44, $02
	db $48, $02
	db $F0, $02
	db $3B, $02
	db $44, $02
	db $48, $02
	db $3B, $02
	db $F0, $03
	db $B0, $A4
	db $FF
Audio1_CutManC2:
	db $FE, $0A
	db $F4, $40
	db $FC, $00
	db $FB, $04
	db $F8, $01
	db $FD, $03
	db $39, $01
	db $39, $01
	db $37, $01
	db $39, $01
	db $00, $02
	db $34, $04
	db $37, $02
	db $39, $02
	db $00, $04
	db $34, $06
	db $34, $02
	db $37, $06
	db $39, $01
	db $39, $01
	db $37, $01
	db $39, $01
	db $00, $02
	db $34, $06
	db $38, $04
	db $39, $04
	db $39, $04
	db $38, $04
	db $34, $04
	db $FE, $0A
	db $F4, $40
	db $FC, $00
	db $FB, $04
	db $F8, $01
	db $FD, $03
	db $39, $01
	db $39, $01
	db $00, $04
	db $3B, $02
	db $40, $02
	db $42, $02
	db $40, $02
	db $3B, $02
	db $39, $02
	db $39, $01
	db $34, $0D
	db $39, $01
	db $39, $01
	db $00, $04
	db $3B, $02
	db $40, $02
	db $42, $02
	db $40, $02
	db $3B, $02
	db $39, $02
	db $39, $01
	db $44, $0D
	db $45, $04
	db $00, $02
	db $45, $02
	db $47, $02
	db $45, $02
	db $44, $01
	db $42, $03
	db $44, $04
	db $00, $02
	db $44, $02
	db $45, $02
	db $44, $02
	db $42, $01
	db $40, $03
	db $43, $04
	db $00, $02
	db $3B, $04
	db $3B, $02
	db $41, $01
	db $43, $03
	db $44, $10
	db $B0, $02
	db $B0, $B1
	db $39, $01
	db $39, $01
	db $00, $04
	db $3B, $02
	db $40, $02
	db $42, $02
	db $40, $02
	db $3B, $02
	db $39, $02
	db $39, $01
	db $34, $0D
	db $39, $01
	db $39, $01
	db $00, $04
	db $3B, $02
	db $40, $02
	db $42, $02
	db $40, $02
	db $3B, $02
	db $39, $02
	db $39, $01
	db $44, $0D
	db $45, $04
	db $00, $02
	db $45, $02
	db $47, $02
	db $45, $02
	db $44, $01
	db $42, $03
	db $44, $04
	db $00, $02
	db $44, $02
	db $45, $02
	db $44, $02
	db $42, $01
	db $40, $03
	db $43, $04
	db $00, $02
	db $3B, $04
	db $38, $02
	db $36, $01
	db $38, $03
	db $39, $10
	db $F4, $80
	db $FC, $0E
	db $FA, $06
	db $FD, $08
	db $49, $0A
	db $4B, $04
	db $49, $02
	db $47, $10
	db $45, $0A
	db $47, $04
	db $45, $02
	db $44, $02
	db $45, $02
	db $46, $02
	db $47, $0A
	db $49, $0A
	db $4B, $04
	db $49, $02
	db $47, $04
	db $51, $01
	db $52, $01
	db $50, $0A
	db $49, $0A
	db $4A, $01
	db $4B, $03
	db $49, $02
	db $49, $10
	db $48, $10
	db $B0, $B8
	db $FF
Audio1_CutManC3:
	db $FE, $0F
	db $F2, $01
	db $FD, $01
	db $F8, $01
	db $FC, $0D
	db $FA, $02
	db $19, $01
	db $19, $01
	db $17, $01
	db $19, $01
	db $00, $02
	db $14, $04
	db $17, $02
	db $19, $02
	db $00, $04
	db $14, $06
	db $14, $02
	db $17, $06
	db $19, $01
	db $19, $01
	db $17, $01
	db $19, $01
	db $00, $02
	db $14, $06
	db $18, $04
	db $19, $04
	db $19, $04
	db $18, $04
	db $14, $04
	db $19, $01
	db $19, $01
	db $17, $01
	db $19, $01
	db $00, $02
	db $1B, $02
	db $20, $02
	db $20, $02
	db $22, $02
	db $22, $02
	db $19, $01
	db $19, $01
	db $17, $01
	db $19, $01
	db $00, $02
	db $1B, $02
	db $20, $02
	db $20, $02
	db $17, $02
	db $17, $02
	db $A1, $EC
	db $25, $01
	db $25, $01
	db $24, $01
	db $25, $01
	db $00, $02
	db $25, $02
	db $27, $02
	db $27, $02
	db $25, $02
	db $25, $02
	db $24, $01
	db $24, $01
	db $22, $01
	db $24, $01
	db $00, $02
	db $24, $02
	db $25, $02
	db $25, $02
	db $24, $02
	db $24, $02
	db $23, $01
	db $23, $01
	db $1B, $01
	db $1B, $01
	db $00, $02
	db $1B, $02
	db $1B, $02
	db $1B, $02
	db $21, $02
	db $23, $02
	db $24, $02
	db $24, $02
	db $24, $02
	db $24, $02
	db $24, $02
	db $1B, $02
	db $18, $02
	db $14, $02
	db $19, $01
	db $19, $01
	db $17, $01
	db $19, $01
	db $00, $02
	db $1B, $02
	db $20, $02
	db $20, $02
	db $22, $02
	db $22, $02
	db $19, $01
	db $19, $01
	db $17, $01
	db $19, $01
	db $00, $02
	db $1B, $02
	db $20, $02
	db $20, $02
	db $17, $02
	db $17, $02
	db $A1, $EC
	db $B0, $02
	db $B0, $98
	db $25, $01
	db $25, $01
	db $24, $01
	db $25, $01
	db $00, $02
	db $25, $02
	db $27, $02
	db $27, $02
	db $25, $02
	db $25, $02
	db $24, $01
	db $24, $01
	db $22, $01
	db $24, $01
	db $00, $02
	db $24, $02
	db $25, $02
	db $25, $02
	db $24, $02
	db $24, $02
	db $1B, $01
	db $1B, $01
	db $00, $01
	db $1B, $01
	db $00, $02
	db $1B, $02
	db $1B, $02
	db $1B, $02
	db $16, $02
	db $18, $02
	db $19, $02
	db $19, $02
	db $19, $02
	db $19, $02
	db $19, $01
	db $19, $02
	db $19, $01
	db $19, $02
	db $19, $01
	db $19, $01
	db $B0, $02
	db $B0, $D6
	db $15, $02
	db $20, $01
	db $20, $01
	db $15, $02
	db $20, $01
	db $20, $01
	db $15, $02
	db $20, $01
	db $20, $01
	db $15, $02
	db $20, $01
	db $20, $01
	db $14, $02
	db $20, $01
	db $20, $01
	db $14, $02
	db $20, $01
	db $20, $01
	db $14, $02
	db $20, $01
	db $20, $01
	db $14, $02
	db $20, $01
	db $20, $01
	db $12, $02
	db $19, $01
	db $19, $01
	db $12, $02
	db $19, $01
	db $19, $01
	db $12, $02
	db $19, $01
	db $19, $01
	db $12, $02
	db $19, $01
	db $19, $01
	db $10, $02
	db $17, $01
	db $17, $01
	db $10, $02
	db $17, $01
	db $17, $01
	db $10, $02
	db $17, $01
	db $17, $01
	db $10, $02
	db $17, $01
	db $17, $01
	db $B0, $02
	db $B0, $CE
	db $15, $02
	db $20, $01
	db $20, $01
	db $15, $02
	db $20, $01
	db $20, $01
	db $15, $02
	db $20, $01
	db $20, $01
	db $15, $02
	db $20, $01
	db $20, $01
	db $14, $02
	db $1B, $01
	db $1B, $01
	db $14, $02
	db $1B, $01
	db $1B, $01
	db $14, $02
	db $1B, $01
	db $1B, $01
	db $14, $02
	db $1B, $01
	db $1B, $01
	db $12, $02
	db $19, $01
	db $19, $01
	db $12, $02
	db $19, $01
	db $19, $01
	db $12, $02
	db $19, $01
	db $19, $01
	db $12, $02
	db $19, $01
	db $19, $01
	db $14, $02
	db $19, $01
	db $19, $01
	db $14, $02
	db $19, $01
	db $19, $01
	db $14, $02
	db $19, $01
	db $19, $01
	db $14, $02
	db $19, $01
	db $19, $01
	db $14, $01
	db $14, $01
	db $00, $01
	db $14, $01
	db $14, $01
	db $00, $01
	db $14, $01
	db $14, $01
	db $00, $01
	db $14, $01
	db $14, $01
	db $00, $01
	db $14, $02
	db $14, $02
	db $B0, $C1
	db $FF
Audio1_CutManC4:
	db $F8, $00
	db $FD, $00
	db $FE, $07
	db $FB, $01
	db $F9, $30
	db $02, $01
	db $02, $01
	db $02, $01
	db $02, $01
	db $00, $02
	db $02, $02
	db $00, $02
	db $02, $02
	db $02, $02
	db $00, $04
	db $02, $02
	db $00, $04
	db $FE, $02
	db $02, $01
	db $FE, $03
	db $02, $01
	db $FE, $04
	db $02, $01
	db $FE, $05
	db $02, $01
	db $FE, $06
	db $02, $01
	db $FE, $07
	db $02, $01
	db $FE, $08
	db $02, $01
	db $FE, $09
	db $02, $01
	db $FE, $0A
	db $02, $01
	db $02, $01
	db $02, $01
	db $02, $01
	db $00, $02
	db $02, $02
	db $00, $04
	db $02, $02
	db $00, $02
	db $02, $02
	db $02, $02
	db $02, $02
	db $02, $02
	db $02, $02
	db $02, $01
	db $FE, $0A
	db $02, $01
	db $02, $01
	db $02, $01
	db $02, $01
	db $02, $01
	db $B0, $02
	db $B0, $CA
	db $FE, $03
	db $FB, $02
	db $F9, $50
	db $03, $01
	db $00, $01
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $02, $02
	db $FE, $03
	db $FB, $02
	db $F9, $50
	db $03, $01
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $02, $02
	db $00, $01
	db $FE, $03
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $00, $01
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $02, $02
	db $FE, $05
	db $FB, $02
	db $F9, $50
	db $03, $01
	db $FE, $0D
	db $FB, $01
	db $F9, $30
	db $02, $02
	db $A6, $DD
	db $FE, $03
	db $FB, $02
	db $F9, $50
	db $03, $01
	db $00, $01
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $02, $02
	db $FE, $03
	db $FB, $02
	db $F9, $50
	db $03, $01
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $02, $02
	db $00, $01
	db $FE, $03
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $02, $01
	db $02, $01
	db $02, $01
	db $02, $01
	db $02, $01
	db $02, $01
	db $A1, $BD
	db $FE, $03
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $03, $01
	db $03, $01
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $02, $02
	db $FE, $03
	db $FB, $02
	db $F9, $50
	db $03, $01
	db $03, $01
	db $A2, $F1
	db $FE, $03
	db $03, $02
	db $03, $01
	db $03, $01
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $02, $02
	db $02, $01
	db $02, $01
	db $A2, $E6
	db $B0, $02
	db $B0, $9F
	db $FE, $08
	db $02, $02
	db $02, $01
	db $02, $01
	db $02, $02
	db $02, $01
	db $02, $01
	db $A1, $F9
	db $FE, $08
	db $02, $02
	db $02, $01
	db $02, $01
	db $02, $02
	db $02, $01
	db $02, $01
	db $A1, $F9
	db $FE, $08
	db $02, $02
	db $02, $01
	db $02, $01
	db $02, $01
	db $02, $01
	db $02, $01
	db $02, $01
	db $02, $01
	db $00, $01
	db $02, $01
	db $02, $01
	db $02, $01
	db $02, $01
	db $02, $01
	db $02, $01
	db $B0, $DF
	db $FF
	
Audio1_ElecMan:
	db $01, $00
	dw Audio1_ElecManC1
	db Mus1
	dw Audio1_ElecManC2
	db Mus2
	dw Audio1_ElecManC3
	db Mus3
	dw Audio1_ElecManC4
	db Mus4
Audio1_ElecManC1:
	db $F5, $00
	db $FE, $08
	db $F4, $80
	db $FC, $0E
	db $FA, $06
	db $F8, $01
	db $FD, $06
	db $F0, $03
	db $26, $03
	db $28, $03
	db $2B, $03
	db $34, $03
	db $36, $03
	db $38, $03
	db $3B, $03
	db $44, $03
	db $46, $03
	db $48, $03
	db $4B, $03
	db $54, $03
	db $56, $03
	db $58, $03
	db $5B, $03
	db $64, $03
	db $F0, $03
	db $FC, $00
	db $FE, $06
	db $F4, $80
	db $FB, $03
	db $F0, $01
	db $24, $03
	db $28, $03
	db $2B, $03
	db $34, $03
	db $34, $03
	db $38, $03
	db $3B, $03
	db $44, $03
	db $F0, $02
	db $54, $03
	db $4B, $03
	db $48, $03
	db $44, $03
	db $44, $03
	db $3B, $03
	db $38, $03
	db $34, $03
	db $A1, $E9
	db $F0, $01
	db $22, $03
	db $28, $03
	db $2B, $03
	db $32, $03
	db $32, $03
	db $38, $03
	db $3B, $03
	db $42, $03
	db $F0, $02
	db $52, $03
	db $4B, $03
	db $48, $03
	db $42, $03
	db $42, $03
	db $3B, $03
	db $38, $03
	db $32, $03
	db $A1, $EE
	db $F0, $01
	db $21, $03
	db $24, $03
	db $28, $03
	db $31, $03
	db $31, $03
	db $34, $03
	db $38, $03
	db $41, $03
	db $F0, $02
	db $51, $03
	db $48, $03
	db $44, $03
	db $41, $03
	db $41, $03
	db $38, $03
	db $34, $03
	db $31, $03
	db $A1, $EE
	db $F0, $01
	db $29, $03
	db $21, $03
	db $24, $03
	db $29, $03
	db $29, $03
	db $31, $03
	db $34, $03
	db $39, $03
	db $F0, $02
	db $39, $03
	db $41, $03
	db $44, $03
	db $49, $03
	db $49, $03
	db $51, $03
	db $54, $03
	db $59, $03
	db $2B, $03
	db $23, $03
	db $26, $03
	db $2B, $03
	db $2B, $03
	db $33, $03
	db $36, $03
	db $3B, $03
	db $F0, $01
	db $3B, $03
	db $43, $03
	db $46, $03
	db $4B, $03
	db $4B, $03
	db $53, $03
	db $56, $03
	db $5B, $03
	db $A1, $9F
	db $B0, $02
	db $B0, $9D
	db $F0, $03
	db $29, $06
	db $24, $06
	db $29, $06
	db $24, $0C
	db $29, $0C
	db $27, $12
	db $26, $06
	db $27, $12
	db $26, $06
	db $27, $06
	db $29, $06
	db $24, $06
	db $29, $06
	db $24, $0C
	db $29, $0C
	db $27, $12
	db $26, $06
	db $27, $12
	db $26, $0C
	db $A1, $EC
	db $2B, $06
	db $26, $06
	db $2B, $06
	db $26, $0C
	db $2B, $0C
	db $29, $12
	db $28, $06
	db $29, $12
	db $28, $06
	db $29, $06
	db $2B, $06
	db $26, $06
	db $2B, $06
	db $26, $0C
	db $2B, $0C
	db $29, $12
	db $28, $06
	db $29, $12
	db $28, $06
	db $29, $06
	db $2B, $06
	db $26, $06
	db $2B, $06
	db $21, $0C
	db $33, $0C
	db $34, $06
	db $FE, $08
	db $F4, $80
	db $FC, $0E
	db $F0, $01
	db $FA, $06
	db $28, $03
	db $2B, $03
	db $34, $03
	db $36, $03
	db $38, $03
	db $3B, $03
	db $2B, $03
	db $24, $03
	db $26, $03
	db $28, $03
	db $3B, $03
	db $34, $03
	db $36, $03
	db $38, $03
	db $3B, $03
	db $44, $03
	db $F0, $03
	db $B0, $BA
	db $FF
Audio1_ElecManC2:
	db $FE, $08
	db $F4, $80
	db $FC, $0E
	db $FA, $06
	db $F8, $01
	db $FD, $07
	db $F8, $01
	db $F0, $03
	db $1B, $03
	db $24, $03
	db $26, $03
	db $28, $03
	db $2B, $03
	db $34, $03
	db $36, $03
	db $38, $03
	db $3B, $03
	db $44, $03
	db $46, $03
	db $48, $03
	db $4B, $03
	db $54, $03
	db $56, $03
	db $58, $03
	db $F0, $03
	db $FC, $0E
	db $F4, $40
	db $FA, $0A
	db $FE, $09
	db $FD, $06
	db $00, $01
	db $00, $0C
	db $48, $12
	db $46, $12
	db $49, $12
	db $48, $1E
	db $00, $0C
	db $48, $12
	db $46, $12
	db $49, $12
	db $48, $1E
	db $00, $0C
	db $48, $12
	db $46, $12
	db $49, $12
	db $48, $12
	db $46, $0C
	db $44, $30
	db $44, $12
	db $43, $0C
	db $41, $06
	db $3B, $0B
	db $00, $0C
	db $48, $12
	db $46, $12
	db $49, $12
	db $48, $1E
	db $00, $0C
	db $48, $12
	db $46, $12
	db $49, $12
	db $48, $1E
	db $00, $0C
	db $48, $12
	db $46, $12
	db $49, $12
	db $48, $12
	db $46, $0C
	db $44, $30
	db $FC, $0F
	db $44, $01
	db $45, $01
	db $46, $01
	db $47, $01
	db $48, $01
	db $49, $01
	db $4A, $01
	db $4B, $01
	db $50, $01
	db $51, $01
	db $52, $01
	db $53, $01
	db $FC, $0C
	db $54, $24
	db $FE, $08
	db $FC, $0E
	db $FA, $06
	db $B0, $02
	db $B0, $C0
	db $FD, $08
	db $FC, $00
	db $FB, $03
	db $44, $06
	db $34, $06
	db $34, $06
	db $42, $06
	db $34, $06
	db $34, $06
	db $44, $06
	db $34, $06
	db $34, $06
	db $42, $06
	db $34, $06
	db $34, $06
	db $44, $06
	db $34, $06
	db $42, $06
	db $34, $06
	db $A3, $ED
	db $4B, $06
	db $3B, $06
	db $3B, $06
	db $49, $06
	db $3B, $06
	db $3B, $06
	db $4B, $06
	db $3B, $06
	db $3B, $06
	db $49, $06
	db $3B, $06
	db $3B, $06
	db $4B, $06
	db $3B, $06
	db $49, $06
	db $3B, $06
	db $A1, $F0
	db $F4, $80
	db $FC, $0E
	db $FA, $06
	db $FE, $0A
	db $FD, $08
	db $24, $03
	db $26, $03
	db $28, $03
	db $2B, $03
	db $34, $03
	db $36, $03
	db $38, $03
	db $3B, $03
	db $2B, $03
	db $24, $03
	db $26, $03
	db $28, $03
	db $3B, $03
	db $34, $03
	db $36, $03
	db $38, $03
	db $F0, $02
	db $34, $03
	db $36, $03
	db $38, $03
	db $3B, $03
	db $44, $03
	db $46, $03
	db $48, $03
	db $4B, $03
	db $3B, $03
	db $44, $03
	db $46, $03
	db $48, $03
	db $4B, $03
	db $54, $03
	db $56, $03
	db $58, $03
	db $F0, $03
	db $FE, $08
	db $B0, $B2
	db $FF
Audio1_ElecManC3:
	db $FE, $0F
	db $F2, $01
	db $FD, $01
	db $F8, $01
	db $FC, $0D
	db $FA, $04
	db $16, $03
	db $18, $03
	db $1B, $03
	db $24, $03
	db $26, $03
	db $28, $03
	db $2B, $03
	db $34, $03
	db $36, $03
	db $38, $03
	db $3B, $03
	db $44, $03
	db $46, $03
	db $48, $03
	db $4B, $03
	db $54, $03
	db $14, $06
	db $24, $06
	db $A7, $FE
	db $12, $06
	db $22, $06
	db $A7, $FE
	db $11, $06
	db $21, $06
	db $A7, $FE
	db $19, $06
	db $29, $06
	db $A3, $FE
	db $1B, $06
	db $2B, $06
	db $A3, $FE
	db $A1, $F1
	db $19, $06
	db $14, $06
	db $19, $06
	db $14, $0C
	db $19, $0C
	db $17, $12
	db $16, $06
	db $17, $12
	db $16, $06
	db $17, $06
	db $19, $06
	db $14, $06
	db $19, $06
	db $14, $0C
	db $19, $0C
	db $17, $12
	db $16, $06
	db $17, $12
	db $16, $0C
	db $A1, $ED
	db $1B, $06
	db $16, $06
	db $1B, $06
	db $16, $0C
	db $1B, $0C
	db $19, $12
	db $18, $06
	db $19, $12
	db $18, $06
	db $19, $06
	db $1B, $06
	db $16, $06
	db $1B, $06
	db $16, $0C
	db $1B, $0C
	db $19, $12
	db $18, $06
	db $19, $12
	db $18, $06
	db $19, $06
	db $1B, $06
	db $16, $06
	db $1B, $06
	db $21, $0C
	db $23, $0C
	db $24, $06
	db $24, $03
	db $26, $03
	db $28, $03
	db $2B, $03
	db $34, $03
	db $36, $03
	db $38, $03
	db $3B, $03
	db $2B, $03
	db $24, $03
	db $26, $03
	db $28, $03
	db $3B, $03
	db $34, $03
	db $36, $03
	db $38, $03
	db $B0, $B2
	db $FF
Audio1_ElecManC4:
	db $F8, $00
	db $FD, $00
	db $FE, $05
	db $FB, $01
	db $F9, $30
	db $02, $03
	db $A3, $FC
	db $FE, $08
	db $02, $03
	db $A3, $FE
	db $FE, $0B
	db $02, $03
	db $A3, $FE
	db $FE, $0D
	db $02, $03
	db $A3, $FE
	db $FE, $05
	db $02, $03
	db $00, $01
	db $FE, $07
	db $02, $03
	db $00, $01
	db $FE, $09
	db $02, $03
	db $00, $01
	db $FE, $0B
	db $02, $04
	db $00, $08
	db $A2, $F4
	db $FE, $05
	db $02, $03
	db $00, $01
	db $FE, $07
	db $02, $03
	db $00, $01
	db $FE, $09
	db $02, $03
	db $00, $01
	db $FE, $0B
	db $02, $04
	db $00, $02
	db $02, $02
	db $00, $01
	db $02, $02
	db $00, $01
	db $A2, $E3
	db $FE, $09
	db $02, $03
	db $00, $01
	db $AB, $FD
	db $FE, $09
	db $02, $02
	db $00, $01
	db $AF, $FD
	db $A1, $DA
	db $FE, $03
	db $FB, $02
	db $F9, $50
	db $03, $04
	db $00, $02
	db $03, $04
	db $00, $02
	db $FE, $09
	db $FB, $01
	db $F9, $30
	db $02, $04
	db $00, $02
	db $FE, $03
	db $FB, $02
	db $F9, $50
	db $03, $04
	db $00, $02
	db $FE, $09
	db $FB, $01
	db $F9, $30
	db $02, $04
	db $00, $02
	db $FE, $03
	db $FB, $02
	db $F9, $50
	db $03, $04
	db $00, $02
	db $03, $04
	db $00, $02
	db $FE, $09
	db $FB, $01
	db $F9, $30
	db $02, $04
	db $00, $02
	db $AB, $DE
	db $02, $04
	db $00, $02
	db $A7, $FE
	db $B0, $A5
	
Audio1_IceMan:
	db $05, $00
	dw Audio1_IceManC1
	db Mus1
	dw Audio1_IceManC2
	db Mus2
	dw Audio1_IceManC3
	db Mus3
	dw Audio1_IceManC4
	db Mus4
Audio1_IceManC2:
	db $FE, $08
	db $F4, $40
	db $FC, $0E
	db $FA, $08
	db $F8, $01
	db $FD, $06
	db $F0, $03
	db $00, $10
	db $37, $01
	db $37, $01
	db $00, $06
	db $37, $01
	db $37, $02
	db $00, $01
	db $35, $14
	db $37, $01
	db $37, $01
	db $00, $06
	db $37, $01
	db $37, $02
	db $00, $01
	db $3A, $14
	db $A1, $F2
	db $37, $02
	db $38, $06
	db $39, $02
	db $3A, $06
	db $3B, $02
	db $40, $02
	db $41, $02
	db $42, $02
	db $43, $02
	db $44, $02
	db $45, $02
	db $46, $02
	db $FE, $09
	db $47, $04
	db $47, $02
	db $45, $02
	db $47, $02
	db $44, $02
	db $47, $02
	db $50, $04
	db $45, $02
	db $4A, $02
	db $50, $02
	db $52, $02
	db $4A, $04
	db $45, $02
	db $47, $04
	db $47, $02
	db $45, $02
	db $44, $02
	db $47, $02
	db $50, $02
	db $4A, $12
	db $4A, $04
	db $4A, $02
	db $48, $02
	db $4A, $02
	db $47, $02
	db $4A, $02
	db $53, $04
	db $48, $02
	db $51, $02
	db $53, $02
	db $55, $02
	db $51, $04
	db $48, $02
	db $4A, $04
	db $4A, $02
	db $48, $02
	db $47, $02
	db $4A, $02
	db $53, $02
	db $55, $02
	db $55, $08
	db $57, $08
	db $FE, $08
	db $47, $01
	db $47, $01
	db $00, $06
	db $47, $01
	db $47, $02
	db $00, $01
	db $45, $14
	db $47, $01
	db $47, $01
	db $00, $06
	db $47, $01
	db $47, $02
	db $00, $01
	db $4A, $14
	db $A1, $F2
	db $B0, $C5
	db $FF
Audio1_IceManC1:
	db $FE, $08
	db $F4, $80
	db $FC, $0E
	db $FA, $08
	db $F8, $01
	db $F5, $00
	db $FD, $06
	db $F0, $03
	db $00, $10
	db $32, $01
	db $32, $01
	db $00, $06
	db $32, $01
	db $32, $02
	db $00, $01
	db $30, $0C
	db $17, $01
	db $1B, $01
	db $22, $01
	db $27, $01
	db $27, $01
	db $2B, $01
	db $32, $01
	db $37, $01
	db $32, $01
	db $32, $01
	db $00, $06
	db $32, $01
	db $32, $02
	db $00, $01
	db $35, $0C
	db $1A, $01
	db $22, $01
	db $25, $01
	db $2A, $01
	db $2A, $01
	db $32, $01
	db $35, $01
	db $3A, $01
	db $A1, $E2
	db $30, $02
	db $31, $06
	db $32, $02
	db $33, $06
	db $34, $02
	db $35, $02
	db $36, $02
	db $37, $02
	db $38, $02
	db $39, $02
	db $3A, $02
	db $3B, $02
	db $FE, $06
	db $00, $01
	db $47, $04
	db $47, $01
	db $47, $01
	db $45, $02
	db $47, $02
	db $44, $02
	db $47, $02
	db $50, $04
	db $45, $02
	db $4A, $02
	db $50, $02
	db $52, $02
	db $4A, $04
	db $45, $02
	db $47, $04
	db $47, $02
	db $45, $01
	db $45, $01
	db $44, $02
	db $47, $02
	db $50, $02
	db $4A, $11
	db $00, $01
	db $4A, $04
	db $4A, $01
	db $4A, $01
	db $48, $02
	db $4A, $02
	db $47, $02
	db $4A, $02
	db $53, $04
	db $48, $02
	db $51, $02
	db $53, $02
	db $55, $02
	db $51, $04
	db $48, $02
	db $4A, $04
	db $4A, $01
	db $4A, $01
	db $48, $02
	db $47, $02
	db $4A, $02
	db $53, $02
	db $55, $01
	db $FE, $08
	db $25, $01
	db $29, $01
	db $30, $01
	db $35, $01
	db $35, $01
	db $39, $01
	db $40, $01
	db $45, $01
	db $27, $01
	db $2B, $01
	db $32, $01
	db $37, $01
	db $37, $01
	db $3B, $01
	db $42, $01
	db $47, $01
	db $42, $01
	db $42, $01
	db $00, $06
	db $42, $01
	db $42, $02
	db $00, $01
	db $40, $0C
	db $27, $01
	db $2B, $01
	db $32, $01
	db $37, $01
	db $37, $01
	db $3B, $01
	db $42, $01
	db $47, $01
	db $42, $01
	db $42, $01
	db $00, $06
	db $42, $01
	db $42, $02
	db $00, $01
	db $45, $0C
	db $2A, $01
	db $32, $01
	db $35, $01
	db $3A, $01
	db $3A, $01
	db $42, $01
	db $45, $01
	db $4A, $01
	db $A1, $E2
	db $B0, $A1
	db $FF
Audio1_IceManC3:
	db $F2, $01
	db $FC, $0D
	db $F8, $01
	db $FA, $06
	db $FE, $0F
	db $FD, $00
	db $17, $02
	db $A7, $FF
	db $17, $01
	db $17, $01
	db $00, $0E
	db $00, $08
	db $15, $02
	db $10, $02
	db $12, $02
	db $15, $02
	db $17, $01
	db $17, $01
	db $00, $0E
	db $00, $08
	db $1A, $02
	db $15, $02
	db $17, $02
	db $1A, $02
	db $A1, $F0
	db $17, $02
	db $18, $06
	db $19, $02
	db $1A, $06
	db $1B, $02
	db $20, $02
	db $21, $02
	db $22, $02
	db $23, $02
	db $24, $02
	db $25, $02
	db $26, $02
	db $20, $04
	db $20, $01
	db $20, $01
	db $17, $02
	db $1A, $02
	db $17, $02
	db $1A, $02
	db $1B, $02
	db $1A, $04
	db $1A, $01
	db $1A, $01
	db $15, $02
	db $18, $02
	db $15, $02
	db $18, $02
	db $19, $02
	db $20, $04
	db $20, $01
	db $20, $01
	db $17, $02
	db $1A, $02
	db $17, $02
	db $1A, $02
	db $1B, $02
	db $1A, $04
	db $1A, $01
	db $1A, $01
	db $15, $02
	db $18, $02
	db $15, $02
	db $18, $02
	db $19, $02
	db $23, $04
	db $23, $01
	db $23, $01
	db $1A, $02
	db $21, $02
	db $1A, $02
	db $21, $02
	db $22, $02
	db $21, $04
	db $21, $01
	db $21, $01
	db $18, $02
	db $1B, $02
	db $18, $02
	db $1B, $02
	db $20, $02
	db $23, $04
	db $23, $01
	db $23, $01
	db $1A, $02
	db $21, $02
	db $1A, $02
	db $21, $02
	db $22, $02
	db $25, $02
	db $25, $02
	db $25, $02
	db $25, $02
	db $27, $02
	db $27, $02
	db $27, $02
	db $27, $02
	db $17, $02
	db $A7, $FF
	db $15, $02
	db $A7, $FF
	db $17, $02
	db $A7, $FF
	db $1A, $02
	db $A7, $FF
	db $17, $02
	db $A7, $FF
	db $15, $02
	db $A7, $FF
	db $17, $02
	db $A7, $FF
	db $1A, $02
	db $A4, $FF
	db $1A, $04
	db $1A, $02
	db $B0, $AE
	db $FF
Audio1_IceManC4:
	db $F8, $01
	db $FD, $00
	db $FE, $01
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $FE, $02
	db $20, $02
	db $FE, $03
	db $20, $02
	db $FE, $04
	db $20, $02
	db $FE, $05
	db $20, $02
	db $FE, $06
	db $20, $02
	db $FE, $07
	db $20, $02
	db $FE, $08
	db $20, $02
	db $FE, $07
	db $20, $01
	db $20, $01
	db $00, $02
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $04
	db $03, $04
	db $03, $04
	db $03, $04
	db $03, $04
	db $03, $04
	db $FE, $07
	db $FB, $01
	db $F9, $30
	db $20, $01
	db $20, $01
	db $20, $01
	db $00, $01
	db $FE, $07
	db $20, $01
	db $20, $01
	db $00, $02
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $04
	db $03, $04
	db $03, $04
	db $03, $04
	db $03, $04
	db $03, $04
	db $FE, $07
	db $FB, $01
	db $F9, $30
	db $20, $01
	db $20, $01
	db $20, $01
	db $20, $01
	db $A1, $D8
	db $20, $01
	db $20, $01
	db $20, $02
	db $00, $04
	db $20, $01
	db $20, $01
	db $20, $02
	db $00, $04
	db $20, $01
	db $20, $01
	db $20, $01
	db $00, $01
	db $20, $01
	db $20, $01
	db $20, $01
	db $00, $01
	db $20, $01
	db $20, $01
	db $20, $01
	db $00, $01
	db $20, $01
	db $20, $01
	db $20, $01
	db $00, $01
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $03
	db $03, $01
	db $FE, $07
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $03, $02
	db $03, $02
	db $FE, $07
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $FE, $04
	db $03, $02
	db $03, $02
	db $FE, $07
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $00, $02
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $03, $02
	db $FE, $07
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $20, $02
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $03
	db $03, $01
	db $FE, $07
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $03, $02
	db $03, $02
	db $FE, $07
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $FE, $04
	db $03, $02
	db $03, $02
	db $FE, $07
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $00, $02
	db $20, $02
	db $20, $01
	db $20, $01
	db $20, $02
	db $20, $01
	db $20, $01
	db $B0, $02
	db $B0, $B1
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $03
	db $03, $01
	db $FE, $07
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $03, $02
	db $03, $02
	db $FE, $07
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $FE, $04
	db $03, $02
	db $03, $02
	db $FE, $07
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $00, $02
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $03, $02
	db $FE, $07
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $20, $02
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $03
	db $03, $01
	db $FE, $07
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $03, $02
	db $03, $02
	db $FE, $07
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $FE, $07
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $20, $02
	db $20, $02
	db $00, $02
	db $20, $02
	db $20, $01
	db $20, $01
	db $20, $01
	db $20, $01
	db $20, $01
	db $20, $01
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $04
	db $FE, $07
	db $FB, $01
	db $F9, $30
	db $20, $04
	db $A2, $F8
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $03, $01
	db $03, $01
	db $FE, $07
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $20, $01
	db $20, $01
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $04
	db $FE, $07
	db $FB, $01
	db $F9, $30
	db $20, $04
	db $A2, $F8
	db $FE, $07
	db $20, $02
	db $20, $02
	db $20, $02
	db $20, $01
	db $20, $01
	db $A1, $DC
	db $B0, $8C
	db $FF

Audio1_FireMan:
	db $05, $00
	dw Audio1_FireManC1
	db Mus1
	dw Audio1_FireManC2
	db Mus2
	dw Audio1_FireManC3
	db Mus3
	dw Audio1_FireManC4
	db Mus4
Audio1_FireManC2:
	db $FE, $08
	db $F4, $80
	db $FC, $00
	db $FB, $04
	db $F8, $01
	db $FD, $06
	db $F0, $03
	db $44, $04
	db $49, $08
	db $47, $01
	db $49, $02
	db $47, $02
	db $44, $02
	db $42, $01
	db $44, $0C
	db $44, $04
	db $49, $08
	db $47, $01
	db $49, $02
	db $4B, $02
	db $49, $02
	db $47, $01
	db $49, $08
	db $49, $01
	db $4B, $01
	db $50, $01
	db $52, $01
	db $54, $04
	db $59, $08
	db $57, $01
	db $59, $02
	db $57, $02
	db $54, $02
	db $52, $01
	db $54, $0C
	db $54, $04
	db $59, $08
	db $57, $01
	db $59, $02
	db $5B, $02
	db $59, $02
	db $57, $01
	db $59, $10
	db $FC, $0E
	db $FA, $06
	db $55, $06
	db $54, $02
	db $52, $02
	db $4B, $01
	db $50, $02
	db $52, $03
	db $54, $06
	db $52, $02
	db $50, $02
	db $49, $01
	db $4B, $02
	db $50, $03
	db $52, $06
	db $50, $02
	db $4B, $02
	db $48, $01
	db $49, $02
	db $4B, $03
	db $49, $01
	db $4B, $02
	db $50, $04
	db $00, $01
	db $50, $01
	db $52, $02
	db $54, $04
	db $00, $01
	db $55, $06
	db $54, $02
	db $52, $02
	db $4B, $01
	db $57, $02
	db $55, $03
	db $54, $06
	db $52, $02
	db $50, $02
	db $49, $01
	db $55, $02
	db $54, $03
	db $52, $06
	db $50, $02
	db $4B, $02
	db $48, $01
	db $49, $02
	db $4B, $03
	db $49, $08
	db $FC, $00
	db $FB, $04
	db $29, $01
	db $30, $01
	db $34, $01
	db $39, $01
	db $FC, $00
	db $FB, $04
	db $44, $04
	db $B0, $A5
	db $FF
Audio1_FireManC1:
	db $FE, $08
	db $F4, $40
	db $FC, $00
	db $F5, $00
	db $FB, $04
	db $F8, $01
	db $FD, $06
	db $F0, $03
	db $14, $04
	db $FC, $00
	db $FB, $04
	db $29, $02
	db $29, $02
	db $27, $01
	db $29, $02
	db $29, $01
	db $29, $02
	db $FE, $04
	db $50, $03
	db $50, $01
	db $50, $02
	db $FE, $08
	db $29, $02
	db $29, $02
	db $27, $01
	db $29, $02
	db $29, $01
	db $29, $02
	db $FE, $04
	db $54, $03
	db $54, $01
	db $54, $02
	db $FE, $08
	db $A3, $E8
	db $FC, $0E
	db $FA, $06
	db $FE, $04
	db $00, $01
	db $45, $06
	db $44, $02
	db $42, $02
	db $3B, $01
	db $40, $02
	db $42, $03
	db $44, $06
	db $42, $02
	db $40, $02
	db $39, $01
	db $3B, $02
	db $40, $03
	db $42, $06
	db $40, $02
	db $3B, $02
	db $38, $01
	db $39, $02
	db $3B, $03
	db $40, $02
	db $42, $01
	db $44, $04
	db $00, $01
	db $44, $01
	db $45, $02
	db $47, $04
	db $00, $01
	db $45, $06
	db $44, $02
	db $42, $02
	db $3B, $01
	db $47, $02
	db $45, $03
	db $44, $06
	db $42, $02
	db $40, $02
	db $39, $01
	db $45, $02
	db $44, $03
	db $42, $06
	db $40, $02
	db $3B, $02
	db $38, $01
	db $39, $02
	db $3B, $03
	db $39, $08
	db $FC, $00
	db $FB, $04
	db $19, $01
	db $20, $01
	db $24, $01
	db $29, $01
	db $30, $01
	db $34, $01
	db $39, $01
	db $FC, $00
	db $FB, $04
	db $FE, $08
	db $A0, $AA
	db $FF
Audio1_FireManC3:
	db $FE, $0F
	db $F2, $01
	db $FD, $01
	db $F8, $01
	db $FC, $0D
	db $FA, $04
	db $14, $04
	db $19, $02
	db $19, $02
	db $17, $01
	db $19, $02
	db $19, $01
	db $19, $02
	db $20, $03
	db $20, $01
	db $20, $02
	db $19, $02
	db $19, $02
	db $17, $01
	db $19, $02
	db $19, $01
	db $19, $02
	db $24, $03
	db $24, $01
	db $24, $02
	db $A3, $EE
	db $25, $06
	db $20, $02
	db $25, $02
	db $22, $01
	db $25, $02
	db $27, $03
	db $24, $06
	db $1B, $02
	db $24, $02
	db $1B, $01
	db $20, $02
	db $22, $03
	db $22, $06
	db $19, $02
	db $24, $02
	db $1B, $01
	db $20, $02
	db $22, $03
	db $20, $01
	db $22, $02
	db $24, $04
	db $00, $01
	db $24, $01
	db $25, $02
	db $27, $04
	db $00, $01
	db $25, $06
	db $20, $02
	db $25, $02
	db $22, $01
	db $25, $02
	db $27, $03
	db $24, $06
	db $1B, $02
	db $24, $02
	db $1B, $01
	db $20, $02
	db $22, $03
	db $22, $06
	db $19, $02
	db $24, $02
	db $1B, $01
	db $20, $02
	db $22, $03
	db $19, $0C
	db $14, $04
	db $A0, $BF
	db $FF
Audio1_FireManC4:
	db $F8, $01
	db $FD, $00
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $20, $01
	db $20, $01
	db $20, $01
	db $20, $01
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $FE, $06
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $FE, $06
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $20, $03
	db $20, $01
	db $20, $02
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $FE, $06
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $20, $02
	db $20, $02
	db $FE, $08
	db $20, $02
	db $20, $02
	db $00, $02
	db $20, $02
	db $A2, $D7
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $FE, $06
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $20, $02
	db $20, $02
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $20, $03
	db $20, $01
	db $20, $02
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $20, $03
	db $20, $01
	db $20, $02
	db $FE, $08
	db $20, $01
	db $20, $01
	db $20, $01
	db $20, $01
	db $20, $01
	db $00, $01
	db $20, $01
	db $20, $01
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $03, $01
	db $03, $01
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $01
	db $03, $01
	db $FE, $04
	db $03, $02
	db $03, $01
	db $03, $01
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $20, $01
	db $20, $01
	db $A2, $E7
	db $FE, $08
	db $20, $01
	db $20, $02
	db $20, $03
	db $20, $01
	db $20, $01
	db $20, $01
	db $20, $02
	db $20, $03
	db $20, $02
	db $B0, $02
	db $B0, $8A
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $03, $01
	db $03, $01
	db $FE, $06
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $01
	db $03, $01
	db $FE, $04
	db $03, $02
	db $03, $01
	db $03, $01
	db $FE, $06
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $20, $01
	db $20, $01
	db $A2, $E7
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $03, $01
	db $03, $01
	db $FE, $06
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $01
	db $03, $01
	db $FE, $04
	db $03, $02
	db $03, $01
	db $03, $01
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $20, $01
	db $20, $01
	db $20, $01
	db $20, $01
	db $B0, $CB
	db $FF

Audio1_Wily1:
	db $02, $00
	dw Audio1_Wily1C1
	db Mus1
	dw Audio1_Wily1C2
	db Mus2
	dw Audio1_Wily1C3
	db Mus3
	dw Audio1_Wily1C4
	db Mus4
Audio1_Wily1C1:
	db $F0, $03
	db $FE, $0A
	db $F5, $00
	db $F4, $40
	db $FC, $00
	db $FB, $02
	db $F8, $01
	db $FD, $03
	db $19, $02
	db $00, $02
	db $19, $04
	db $17, $02
	db $19, $02
	db $00, $02
	db $14, $02
	db $19, $02
	db $00, $02
	db $19, $02
	db $00, $02
	db $17, $02
	db $19, $02
	db $00, $02
	db $14, $02
	db $20, $02
	db $00, $02
	db $20, $04
	db $17, $02
	db $20, $02
	db $00, $04
	db $22, $02
	db $00, $02
	db $22, $04
	db $19, $02
	db $22, $02
	db $00, $04
	db $19, $04
	db $19, $02
	db $00, $02
	db $17, $02
	db $19, $02
	db $00, $02
	db $14, $02
	db $19, $02
	db $00, $02
	db $19, $04
	db $17, $02
	db $19, $02
	db $00, $02
	db $14, $02
	db $20, $02
	db $00, $02
	db $20, $04
	db $17, $02
	db $20, $02
	db $00, $04
	db $17, $02
	db $00, $02
	db $17, $04
	db $12, $02
	db $17, $02
	db $00, $04
	db $A1, $CB
	db $15, $02
	db $00, $02
	db $15, $02
	db $00, $02
	db $25, $02
	db $15, $02
	db $00, $04
	db $15, $02
	db $00, $02
	db $15, $02
	db $00, $02
	db $20, $02
	db $15, $02
	db $00, $04
	db $17, $02
	db $00, $02
	db $17, $02
	db $00, $02
	db $27, $02
	db $17, $02
	db $00, $04
	db $17, $02
	db $00, $02
	db $17, $02
	db $00, $02
	db $22, $02
	db $17, $02
	db $00, $04
	db $20, $02
	db $00, $02
	db $20, $02
	db $00, $02
	db $27, $02
	db $20, $02
	db $00, $04
	db $20, $02
	db $00, $02
	db $20, $02
	db $00, $02
	db $30, $02
	db $20, $02
	db $00, $04
	db $20, $02
	db $00, $02
	db $20, $02
	db $00, $02
	db $27, $02
	db $20, $02
	db $00, $04
	db $20, $02
	db $00, $02
	db $20, $02
	db $00, $02
	db $30, $02
	db $20, $02
	db $00, $04
	db $15, $02
	db $00, $02
	db $15, $02
	db $00, $02
	db $25, $02
	db $15, $02
	db $00, $04
	db $15, $02
	db $00, $02
	db $15, $02
	db $00, $02
	db $20, $02
	db $15, $02
	db $00, $04
	db $17, $02
	db $00, $02
	db $17, $02
	db $00, $02
	db $27, $02
	db $17, $02
	db $00, $04
	db $17, $02
	db $00, $02
	db $17, $02
	db $00, $02
	db $22, $02
	db $17, $02
	db $00, $04
	db $19, $02
	db $00, $02
	db $19, $02
	db $00, $02
	db $29, $02
	db $19, $02
	db $00, $04
	db $19, $02
	db $00, $02
	db $19, $02
	db $00, $02
	db $29, $02
	db $19, $02
	db $00, $04
	db $19, $02
	db $00, $02
	db $19, $02
	db $00, $02
	db $29, $02
	db $19, $02
	db $00, $04
	db $19, $02
	db $00, $02
	db $19, $02
	db $00, $02
	db $29, $02
	db $19, $02
	db $00, $04
	db $A1, $90
	db $B0, $59
	db $FF
Audio1_Wily1C2:
	db $F0, $03
	db $FE, $0A
	db $F4, $40
	db $FC, $00
	db $FB, $02
	db $F8, $01
	db $FD, $03
	db $44, $08
	db $47, $02
	db $47, $02
	db $42, $02
	db $00, $02
	db $00, $04
	db $44, $02
	db $00, $02
	db $00, $04
	db $00, $04
	db $40, $04
	db $42, $04
	db $44, $04
	db $40, $04
	db $40, $08
	db $3B, $08
	db $00, $04
	db $39, $04
	db $3B, $04
	db $40, $04
	db $39, $04
	db $00, $04
	db $32, $04
	db $00, $04
	db $32, $04
	db $34, $04
	db $37, $04
	db $39, $04
	db $34, $08
	db $32, $06
	db $00, $02
	db $44, $08
	db $47, $02
	db $47, $02
	db $42, $02
	db $00, $02
	db $00, $04
	db $44, $02
	db $00, $02
	db $00, $04
	db $00, $04
	db $40, $04
	db $42, $04
	db $44, $04
	db $40, $04
	db $40, $08
	db $3B, $08
	db $00, $04
	db $39, $04
	db $3B, $04
	db $40, $04
	db $39, $04
	db $00, $04
	db $32, $04
	db $00, $04
	db $32, $04
	db $34, $04
	db $37, $04
	db $39, $04
	db $34, $08
	db $32, $06
	db $00, $02
	db $39, $14
	db $39, $04
	db $3B, $04
	db $40, $04
	db $42, $0C
	db $40, $0C
	db $37, $08
	db $44, $08
	db $37, $04
	db $42, $08
	db $37, $04
	db $40, $08
	db $37, $04
	db $3B, $08
	db $37, $04
	db $40, $04
	db $37, $04
	db $42, $04
	db $37, $04
	db $39, $14
	db $39, $04
	db $3B, $04
	db $40, $04
	db $42, $0C
	db $40, $0C
	db $37, $08
	db $39, $04
	db $3B, $04
	db $40, $04
	db $39, $04
	db $3B, $04
	db $40, $04
	db $39, $04
	db $3B, $04
	db $40, $04
	db $39, $04
	db $3B, $04
	db $40, $04
	db $39, $04
	db $3B, $04
	db $40, $04
	db $39, $04
	db $A1, $D6
	db $B0, $97
	db $FF
Audio1_Wily1C3:
	db $FE, $0F
	db $F2, $01
	db $FD, $01
	db $F8, $01
	db $FC, $0D
	db $FA, $02
	db $19, $02
	db $00, $02
	db $19, $04
	db $17, $02
	db $19, $02
	db $00, $02
	db $14, $02
	db $19, $02
	db $00, $02
	db $19, $02
	db $00, $02
	db $17, $02
	db $19, $02
	db $00, $02
	db $14, $02
	db $20, $02
	db $00, $02
	db $20, $04
	db $17, $02
	db $20, $02
	db $00, $04
	db $22, $02
	db $00, $02
	db $22, $04
	db $19, $02
	db $22, $02
	db $00, $04
	db $19, $04
	db $19, $02
	db $00, $02
	db $17, $02
	db $19, $02
	db $00, $02
	db $14, $02
	db $19, $02
	db $00, $02
	db $19, $04
	db $17, $02
	db $19, $02
	db $00, $02
	db $14, $02
	db $20, $02
	db $00, $02
	db $20, $04
	db $17, $02
	db $20, $02
	db $00, $04
	db $17, $02
	db $00, $02
	db $17, $04
	db $12, $02
	db $17, $02
	db $00, $04
	db $A1, $CB
	db $B0, $02
	db $B0, $C9
	db $15, $02
	db $00, $02
	db $15, $02
	db $00, $02
	db $25, $02
	db $15, $02
	db $00, $04
	db $15, $02
	db $00, $02
	db $15, $02
	db $00, $02
	db $20, $02
	db $15, $02
	db $00, $04
	db $17, $02
	db $00, $02
	db $17, $02
	db $00, $02
	db $27, $02
	db $17, $02
	db $00, $04
	db $17, $02
	db $00, $02
	db $17, $02
	db $00, $02
	db $22, $02
	db $17, $02
	db $00, $04
	db $20, $02
	db $00, $02
	db $20, $02
	db $00, $02
	db $27, $02
	db $20, $02
	db $00, $04
	db $20, $02
	db $00, $02
	db $20, $02
	db $00, $02
	db $30, $02
	db $20, $02
	db $00, $04
	db $20, $02
	db $00, $02
	db $20, $02
	db $00, $02
	db $27, $02
	db $20, $02
	db $00, $04
	db $20, $02
	db $00, $02
	db $20, $02
	db $00, $02
	db $30, $02
	db $20, $02
	db $00, $04
	db $15, $02
	db $00, $02
	db $15, $02
	db $00, $02
	db $25, $02
	db $15, $02
	db $00, $04
	db $15, $02
	db $00, $02
	db $15, $02
	db $00, $02
	db $20, $02
	db $15, $02
	db $00, $04
	db $17, $02
	db $00, $02
	db $17, $02
	db $00, $02
	db $27, $02
	db $17, $02
	db $00, $04
	db $17, $02
	db $00, $02
	db $17, $02
	db $00, $02
	db $22, $02
	db $17, $02
	db $00, $04
	db $19, $02
	db $00, $02
	db $19, $02
	db $00, $02
	db $29, $02
	db $19, $02
	db $00, $04
	db $19, $02
	db $00, $02
	db $19, $02
	db $00, $02
	db $29, $02
	db $19, $02
	db $00, $04
	db $19, $02
	db $00, $02
	db $19, $02
	db $00, $02
	db $29, $02
	db $19, $02
	db $00, $04
	db $19, $02
	db $00, $02
	db $19, $02
	db $00, $02
	db $29, $02
	db $19, $02
	db $00, $04
	db $A1, $90
	db $B0, $8E
	db $FF
Audio1_Wily1C4:
	db $F8, $01
	db $FD, $00
	db $FE, $06
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $00, $02
	db $03, $02
	db $00, $02
	db $FE, $0A
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $00, $02
	db $FE, $06
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $00, $02
	db $A6, $EF
	db $FE, $06
	db $03, $02
	db $00, $02
	db $03, $02
	db $00, $02
	db $FE, $0A
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $00, $02
	db $20, $01
	db $00, $01
	db $20, $01
	db $00, $01
	db $FE, $06
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $00, $02
	db $03, $02
	db $00, $02
	db $FE, $0A
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $00, $02
	db $FE, $06
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $00, $02
	db $A6, $EF
	db $FE, $0A
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $00, $02
	db $20, $02
	db $00, $02
	db $20, $02
	db $00, $02
	db $20, $01
	db $00, $01
	db $20, $01
	db $00, $01
	db $B0, $02
	db $B0, $C0
	db $FE, $06
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $00, $02
	db $03, $01
	db $00, $01
	db $03, $01
	db $00, $01
	db $A2, $F7
	db $FE, $0A
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $00, $02
	db $FE, $06
	db $FB, $02
	db $F9, $50
	db $03, $01
	db $00, $01
	db $03, $01
	db $00, $01
	db $A6, $EA
	db $FE, $06
	db $03, $02
	db $00, $02
	db $03, $01
	db $00, $01
	db $03, $01
	db $00, $01
	db $A2, $F9
	db $FE, $0A
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $00, $02
	db $20, $01
	db $00, $01
	db $20, $01
	db $00, $01
	db $FE, $06
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $00, $02
	db $03, $01
	db $00, $01
	db $03, $01
	db $00, $01
	db $FE, $0A
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $00, $02
	db $FE, $06
	db $FB, $02
	db $F9, $50
	db $03, $01
	db $00, $01
	db $03, $01
	db $00, $01
	db $AD, $EB
	db $FE, $0A
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $00, $02
	db $FE, $06
	db $FB, $02
	db $F9, $50
	db $03, $01
	db $00, $01
	db $03, $01
	db $00, $01
	db $FE, $0A
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $00, $02
	db $20, $01
	db $00, $01
	db $20, $01
	db $00, $01
	db $FE, $0A
	db $20, $02
	db $00, $02
	db $FE, $06
	db $FB, $02
	db $F9, $50
	db $03, $01
	db $00, $01
	db $03, $01
	db $00, $01
	db $FE, $0A
	db $FB, $01
	db $F9, $30
	db $20, $01
	db $00, $01
	db $20, $01
	db $00, $01
	db $20, $01
	db $00, $01
	db $20, $01
	db $00, $01
	db $B0, $97
	db $FF
	
Audio1_WilyUnk:
	db $05, $00
	dw Audio1_WilyUnkC1
	db Mus1
	dw 0
	db SFX2
	dw 0
	db SFX3
	dw 0
	db SFX4
Audio1_WilyUnkC1:
	db $F0, $03
	db $FE, $0A
	db $F5, $00
	db $F4, $40
	db $FC, $00
	db $FB, $02
	db $F8, $01
	db $FD, $03
	db $40, $01
	db $00, $03
	db $37, $01
	db $40, $03
	db $40, $01
	db $00, $03
	db $42, $01
	db $00, $03
	db $44, $01
	db $00, $03
	db $40, $01
	db $00, $01
	db $44, $01
	db $00, $03
	db $47, $01
	db $00, $03
	db $40, $01
	db $00, $01
	db $00, $02
	db $40, $01
	db $00, $03
	db $37, $01
	db $00, $03
	db $40, $01
	db $00, $03
	db $44, $01
	db $00, $03
	db $47, $01
	db $00, $02
	db $44, $01
	db $00, $01
	db $42, $02
	db $40, $01
	db $00, $01
	db $00, $02
	db $A1, $DD
	db $50, $01
	db $00, $03
	db $4B, $01
	db $00, $03
	db $49, $01
	db $00, $03
	db $47, $01
	db $00, $03
	db $45, $01
	db $00, $03
	db $44, $01
	db $00, $01
	db $45, $01
	db $03, $03
	db $47, $01
	db $00, $03
	db $50, $01
	db $50, $01
	db $00, $03
	db $4B, $01
	db $00, $03
	db $49, $01
	db $00, $03
	db $47, $01
	db $00, $03
	db $45, $01
	db $00, $01
	db $44, $01
	db $00, $01
	db $42, $01
	db $00, $01
	db $40, $02
	db $A1, $E0
	db $B0, $BB
	db $FF

Audio1_DoNotUse23:
Audio1_Wily2:
	db $02, $00
	dw Audio1_Wily2C1
	db Mus1
	dw Audio1_Wily2C2
	db Mus2
	dw Audio1_Wily2C3
	db Mus3
	dw Audio1_Wily2C4
	db Mus4
Audio1_Wily2C1:
	db $F0, $03
	db $FE, $0A
	db $F5, $00
	db $F4, $40
	db $FC, $00
	db $FB, $02
	db $F8, $01
	db $FD, $03
	db $00, $08
	db $40, $04
	db $40, $02
	db $40, $02
	db $40, $04
	db $40, $04
	db $00, $04
	db $34, $04
	db $37, $04
	db $37, $02
	db $37, $02
	db $37, $04
	db $37, $08
	db $37, $04
	db $37, $04
	db $34, $04
	db $00, $08
	db $40, $04
	db $40, $02
	db $40, $02
	db $40, $04
	db $40, $04
	db $00, $04
	db $34, $04
	db $39, $04
	db $37, $04
	db $39, $04
	db $40, $08
	db $40, $04
	db $40, $04
	db $34, $04
	db $00, $08
	db $40, $04
	db $40, $02
	db $40, $02
	db $40, $04
	db $40, $04
	db $00, $04
	db $34, $04
	db $37, $04
	db $37, $02
	db $37, $02
	db $37, $04
	db $37, $08
	db $40, $04
	db $37, $04
	db $34, $04
	db $00, $08
	db $40, $04
	db $40, $02
	db $40, $02
	db $40, $04
	db $40, $04
	db $00, $04
	db $34, $04
	db $40, $04
	db $40, $02
	db $40, $02
	db $40, $04
	db $40, $02
	db $40, $02
	db $40, $04
	db $40, $02
	db $40, $02
	db $42, $04
	db $42, $02
	db $42, $02
	db $00, $02
	db $40, $18
	db $3B, $08
	db $40, $08
	db $3B, $08
	db $40, $08
	db $42, $08
	db $44, $0C
	db $42, $0C
	db $40, $08
	db $44, $0C
	db $42, $0C
	db $37, $08
	db $40, $18
	db $3B, $08
	db $40, $08
	db $3B, $08
	db $40, $08
	db $42, $08
	db $47, $18
	db $47, $08
	db $45, $0C
	db $44, $0C
	db $37, $08
	db $40, $18
	db $3B, $08
	db $40, $08
	db $3B, $08
	db $40, $08
	db $42, $08
	db $44, $0C
	db $42, $0C
	db $40, $08
	db $44, $0C
	db $42, $0C
	db $37, $08
	db $40, $18
	db $3B, $08
	db $40, $08
	db $39, $08
	db $40, $08
	db $42, $08
	db $47, $3E
	db $B0, $92
	db $FF
Audio1_Wily2C2:
	db $F0, $03
	db $FE, $0A
	db $F4, $40
	db $FC, $00
	db $FB, $02
	db $F8, $01
	db $FD, $03
	db $00, $08
	db $45, $04
	db $45, $02
	db $45, $02
	db $45, $04
	db $44, $04
	db $00, $04
	db $37, $04
	db $40, $04
	db $40, $02
	db $40, $02
	db $40, $04
	db $42, $08
	db $40, $04
	db $3B, $04
	db $37, $04
	db $00, $08
	db $45, $04
	db $45, $02
	db $45, $02
	db $45, $04
	db $44, $04
	db $00, $04
	db $37, $04
	db $45, $04
	db $44, $04
	db $45, $04
	db $47, $08
	db $45, $04
	db $44, $04
	db $37, $04
	db $00, $08
	db $45, $04
	db $45, $02
	db $45, $02
	db $45, $04
	db $44, $04
	db $00, $04
	db $37, $04
	db $40, $04
	db $40, $02
	db $40, $02
	db $40, $04
	db $44, $08
	db $44, $04
	db $42, $04
	db $37, $04
	db $00, $08
	db $45, $04
	db $45, $02
	db $45, $02
	db $45, $04
	db $44, $04
	db $00, $04
	db $37, $04
	db $45, $04
	db $45, $02
	db $45, $02
	db $44, $04
	db $44, $02
	db $44, $02
	db $45, $04
	db $45, $02
	db $45, $02
	db $47, $04
	db $47, $02
	db $47, $02
	db $40, $18
	db $3B, $08
	db $40, $08
	db $3B, $08
	db $40, $08
	db $42, $08
	db $44, $0C
	db $42, $0C
	db $40, $08
	db $44, $0C
	db $42, $0C
	db $37, $08
	db $40, $18
	db $3B, $08
	db $40, $08
	db $3B, $08
	db $40, $08
	db $42, $08
	db $47, $18
	db $47, $08
	db $45, $0C
	db $44, $0C
	db $37, $08
	db $40, $18
	db $3B, $08
	db $40, $08
	db $3B, $08
	db $40, $08
	db $42, $08
	db $44, $0C
	db $42, $0C
	db $40, $08
	db $44, $0C
	db $42, $0C
	db $37, $08
	db $40, $18
	db $3B, $08
	db $40, $08
	db $39, $08
	db $40, $08
	db $42, $08
	db $47, $40
	db $B0, $93
	db $FF
Audio1_Wily2C3:
	db $FE, $0F
	db $F2, $01
	db $FD, $01
	db $F8, $01
	db $FC, $0D
	db $FA, $02
	db $20, $04
	db $20, $02
	db $20, $02
	db $A3, $FD
	db $A3, $FC
	db $A1, $FB
	db $25, $0C
	db $20, $08
	db $25, $08
	db $20, $04
	db $25, $08
	db $20, $04
	db $25, $08
	db $20, $04
	db $25, $04
	db $20, $04
	db $24, $0C
	db $17, $08
	db $20, $08
	db $22, $04
	db $24, $0C
	db $17, $08
	db $20, $08
	db $22, $04
	db $25, $0C
	db $20, $08
	db $25, $08
	db $20, $04
	db $25, $08
	db $20, $04
	db $25, $08
	db $20, $04
	db $25, $04
	db $20, $04
	db $27, $08
	db $22, $04
	db $27, $08
	db $22, $04
	db $27, $04
	db $22, $04
	db $27, $08
	db $22, $04
	db $27, $08
	db $22, $04
	db $27, $04
	db $22, $04
	db $25, $0C
	db $20, $08
	db $25, $08
	db $20, $04
	db $25, $08
	db $20, $04
	db $25, $08
	db $20, $04
	db $25, $04
	db $20, $04
	db $24, $0C
	db $17, $08
	db $20, $08
	db $22, $04
	db $24, $0C
	db $17, $08
	db $20, $08
	db $22, $04
	db $25, $0C
	db $20, $08
	db $25, $08
	db $20, $04
	db $25, $08
	db $20, $04
	db $25, $08
	db $20, $04
	db $25, $04
	db $20, $04
	db $27, $08
	db $22, $04
	db $27, $08
	db $22, $04
	db $27, $04
	db $22, $04
	db $27, $08
	db $22, $04
	db $27, $08
	db $22, $04
	db $27, $04
	db $22, $04
	db $A0, $AA
Audio1_Wily2C4:
	db $F8, $01
	db $FD, $00
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $00, $02
	db $03, $02
	db $00, $02
	db $FE, $0A
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $00, $02
	db $FE, $04
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $00, $02
	db $A6, $EF
	db $FE, $0A
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $00, $02
	db $20, $02
	db $00, $02
	db $20, $02
	db $00, $02
	db $20, $01
	db $00, $01
	db $20, $01
	db $00, $01
	db $B0, $E1
	db $FF

Audio1_DoNotUse25:
Audio1_WilyIntro:
	db $04, $00
	dw Audio1_WilyIntroC1
	db Mus1
	dw Audio1_WilyIntroC2
	db Mus2
	dw Audio1_WilyIntroC3
	db Mus3
	dw Audio1_WilyIntroC4
	db Mus4
Audio1_WilyIntroC1:
	db $F0, $03
	db $FE, $0A
	db $F5, $00
	db $F4, $40
	db $FC, $00
	db $FB, $02
	db $F8, $01
	db $FD, $03
	db $29, $02
	db $29, $02
	db $30, $02
	db $32, $02
	db $00, $02
	db $34, $02
	db $00, $02
	db $29, $02
	db $00, $02
	db $30, $02
	db $2B, $02
	db $27, $02
	db $29, $02
	db $20, $02
	db $22, $02
	db $24, $02
	db $27, $02
	db $24, $02
	db $27, $02
	db $29, $02
	db $20, $02
	db $24, $02
	db $27, $02
	db $29, $04
	db $FF
Audio1_WilyIntroC2:
	db $F0, $03
	db $FE, $0A
	db $F5, $00
	db $F4, $40
	db $FC, $0E
	db $FA, $08
	db $F8, $01
	db $FD, $03
	db $19, $02
	db $19, $02
	db $20, $02
	db $22, $02
	db $00, $02
	db $24, $02
	db $00, $02
	db $19, $02
	db $00, $02
	db $20, $02
	db $1B, $02
	db $17, $02
	db $19, $02
	db $10, $02
	db $12, $02
	db $14, $02
	db $17, $02
	db $14, $02
	db $17, $02
	db $19, $02
	db $10, $02
	db $14, $02
	db $17, $02
	db $19, $04
	db $FF
Audio1_WilyIntroC3:
	db $FE, $0F
	db $F2, $01
	db $FD, $01
	db $F8, $01
	db $FC, $0D
	db $FA, $02
	db $19, $02
	db $19, $02
	db $20, $02
	db $22, $02
	db $00, $02
	db $24, $02
	db $00, $02
	db $19, $02
	db $00, $02
	db $20, $02
	db $1B, $02
	db $17, $02
	db $19, $02
	db $10, $02
	db $12, $02
	db $14, $02
	db $17, $02
	db $14, $02
	db $17, $02
	db $19, $02
	db $10, $02
	db $14, $02
	db $17, $02
	db $19, $04
	db $FF
Audio1_WilyIntroC4:
	db $F8, $01
	db $FD, $00
	db $FE, $06
	db $FB, $01
	db $F9, $30
	db $20, $02
	db $20, $02
	db $20, $02
	db $20, $02
	db $00, $02
	db $20, $02
	db $00, $02
	db $20, $02
	db $00, $02
	db $20, $02
	db $20, $02
	db $20, $02
	db $20, $02
	db $20, $02
	db $20, $02
	db $20, $02
	db $20, $02
	db $20, $02
	db $20, $02
	db $20, $02
	db $20, $02
	db $20, $02
	db $20, $02
	db $20, $02
	db $FF

Audio1_DoNotUse27:
Audio1_DoNotUse28:
Audio1_DoNotUse29:
Audio1_DoNotUse2C:
Audio1_EndGameAlt:
	db $06, $00
	dw Audio1_EndGameAltC1
	db Mus1
	dw Audio1_EndGameAltC2
	db Mus2
	dw Audio1_EndGameAltC3
	db Mus3
	dw Audio1_EndGameAltC4
	db Mus4
Audio1_EndGameAltC1:
	db $FE, $0C
	db $F5, $08
	db $F4, $80
	db $FC, $0E
	db $FA, $04
	db $FD, $06
	db $F8, $01
	db $39, $08
	db $00, $02
	db $39, $02
	db $3B, $02
	db $40, $02
	db $3B, $06
	db $37, $04
	db $34, $04
	db $37, $02
	db $39, $1C
	db $37, $02
	db $39, $02
	db $39, $0A
	db $39, $02
	db $3B, $02
	db $40, $02
	db $42, $06
	db $40, $04
	db $3B, $02
	db $37, $04
	db $44, $18
	db $44, $04
	db $42, $04
	db $40, $0A
	db $3B, $02
	db $40, $02
	db $42, $02
	db $3B, $06
	db $37, $04
	db $34, $04
	db $37, $02
	db $3B, $04
	db $40, $02
	db $39, $14
	db $3B, $02
	db $40, $02
	db $42, $02
	db $40, $06
	db $3B, $06
	db $37, $0C
	db $34, $04
	db $37, $04
	db $39, $0A
	db $39, $02
	db $3B, $02
	db $40, $02
	db $3B, $06
	db $37, $04
	db $34, $04
	db $37, $02
	db $39, $1C
	db $37, $02
	db $39, $02
	db $39, $0A
	db $39, $02
	db $3B, $02
	db $40, $02
	db $42, $06
	db $40, $04
	db $3B, $02
	db $37, $04
	db $44, $18
	db $44, $04
	db $42, $04
	db $40, $06
	db $40, $04
	db $3B, $02
	db $40, $02
	db $42, $02
	db $3B, $06
	db $37, $04
	db $34, $04
	db $37, $02
	db $3B, $04
	db $40, $02
	db $39, $14
	db $3B, $04
	db $40, $02
	db $40, $06
	db $3B, $06
	db $37, $0C
	db $3B, $04
	db $40, $04
	db $A1, $D7
	db $00, $20
	db $44, $10
	db $42, $08
	db $47, $08
	db $42, $06
	db $39, $06
	db $3B, $02
	db $40, $0A
	db $3B, $08
	db $44, $10
	db $42, $08
	db $47, $08
	db $42, $06
	db $39, $06
	db $3B, $02
	db $40, $0A
	db $42, $08
	db $FE, $08
	db $39, $08
	db $3B, $08
	db $40, $08
	db $42, $08
	db $44, $08
	db $42, $08
	db $40, $08
	db $42, $04
	db $37, $04
	db $39, $08
	db $3B, $08
	db $40, $08
	db $42, $08
	db $44, $08
	db $45, $08
	db $44, $08
	db $42, $04
	db $40, $02
	db $3B, $02
	db $39, $08
	db $3B, $08
	db $40, $08
	db $42, $08
	db $47, $08
	db $45, $08
	db $44, $08
	db $42, $04
	db $40, $02
	db $3B, $02
	db $40, $08
	db $42, $08
	db $44, $08
	db $47, $08
	db $49, $08
	db $4B, $08
	db $50, $08
	db $52, $08
	db $FE, $0A
	db $A1, $C9
	db $B0, $C8
	db $FF
Audio1_EndGameAltC2:
	db $FE, $0A
	db $F4, $40
	db $FC, $0E
	db $FA, $06
	db $FD, $01
	db $F8, $01
	db $00, $10
	db $AD, $FF
	db $49, $10
	db $47, $10
	db $44, $1C
	db $47, $04
	db $49, $10
	db $47, $10
	db $50, $18
	db $54, $04
	db $52, $04
	db $50, $10
	db $52, $14
	db $47, $04
	db $49, $18
	db $47, $20
	db $49, $10
	db $47, $10
	db $44, $1C
	db $47, $04
	db $49, $10
	db $47, $10
	db $50, $18
	db $54, $04
	db $52, $04
	db $50, $10
	db $4B, $10
	db $49, $20
	db $47, $10
	db $47, $10
	db $FC, $00
	db $FE, $06
	db $FB, $04
	db $19, $02
	db $19, $01
	db $19, $01
	db $19, $01
	db $19, $02
	db $19, $01
	db $A3, $F7
	db $19, $02
	db $19, $01
	db $19, $01
	db $19, $01
	db $19, $02
	db $19, $01
	db $A1, $FA
	db $17, $02
	db $17, $01
	db $17, $01
	db $17, $01
	db $17, $02
	db $17, $01
	db $A1, $FA
	db $16, $02
	db $16, $01
	db $16, $01
	db $16, $01
	db $16, $02
	db $16, $01
	db $A1, $FA
	db $15, $02
	db $15, $01
	db $15, $01
	db $15, $01
	db $15, $02
	db $15, $01
	db $17, $02
	db $17, $01
	db $17, $01
	db $17, $01
	db $17, $02
	db $17, $01
	db $A1, $DF
	db $FE, $06
	db $FC, $0E
	db $FA, $08
	db $35, $08
	db $37, $08
	db $39, $08
	db $3B, $08
	db $40, $08
	db $3B, $08
	db $39, $08
	db $3B, $04
	db $32, $04
	db $35, $08
	db $37, $08
	db $39, $08
	db $3B, $08
	db $40, $08
	db $42, $08
	db $40, $08
	db $3B, $04
	db $39, $02
	db $37, $02
	db $35, $08
	db $37, $08
	db $39, $08
	db $3B, $08
	db $40, $08
	db $3B, $08
	db $39, $08
	db $37, $04
	db $35, $02
	db $34, $02
	db $35, $08
	db $37, $08
	db $39, $08
	db $40, $08
	db $42, $08
	db $44, $08
	db $45, $08
	db $47, $08
	db $A1, $B6
	db $B0, $B5
	db $FF
Audio1_EndGameAltC3:
	db $FE, $0D
	db $F2, $01
	db $FC, $0C
	db $FA, $06
	db $FD, $01
	db $F8, $01
	db $25, $10
	db $27, $10
	db $29, $20
	db $25, $10
	db $27, $10
	db $30, $18
	db $30, $04
	db $2B, $04
	db $29, $10
	db $27, $10
	db $25, $20
	db $27, $20
	db $25, $10
	db $27, $10
	db $29, $20
	db $25, $10
	db $27, $10
	db $30, $18
	db $30, $04
	db $2B, $04
	db $29, $10
	db $27, $10
	db $25, $20
	db $27, $10
	db $27, $10
	db $A1, $F3
	db $FC, $0D
	db $FA, $04
	db $19, $02
	db $19, $01
	db $19, $01
	db $19, $01
	db $19, $02
	db $19, $01
	db $A3, $FA
	db $19, $02
	db $19, $01
	db $19, $01
	db $19, $01
	db $19, $02
	db $19, $01
	db $A1, $FA
	db $17, $02
	db $17, $01
	db $17, $01
	db $17, $01
	db $17, $02
	db $17, $01
	db $A1, $FA
	db $16, $02
	db $16, $01
	db $16, $01
	db $16, $01
	db $16, $02
	db $16, $01
	db $A1, $FA
	db $15, $02
	db $15, $01
	db $15, $01
	db $15, $01
	db $15, $02
	db $15, $01
	db $17, $02
	db $17, $01
	db $17, $01
	db $17, $01
	db $17, $02
	db $17, $01
	db $A1, $DF
	db $FE, $0F
	db $B0, $02
	db $B0, $DC
	db $15, $02
	db $15, $02
	db $00, $01
	db $15, $01
	db $15, $01
	db $15, $01
	db $A1, $FA
	db $A3, $F9
	db $17, $02
	db $17, $02
	db $00, $01
	db $17, $01
	db $17, $01
	db $17, $01
	db $A1, $FA
	db $A3, $F9
	db $A1, $F0
	db $B0, $EE
	db $FF
Audio1_EndGameAltC4:
	db $00, $08
	db $00, $08
	db $AD, $FE
	db $A2, $FD
	db $FE, $06
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $03, $01
	db $03, $01
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $02, $01
	db $FE, $06
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $03, $01
	db $A3, $F1
	db $FE, $06
	db $03, $02
	db $03, $01
	db $03, $01
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $02, $01
	db $FE, $06
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $03, $01
	db $A1, $F3
	db $A2, $F2
	db $FE, $06
	db $03, $02
	db $03, $01
	db $03, $01
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $02, $01
	db $02, $02
	db $FE, $06
	db $FB, $02
	db $F9, $50
	db $03, $01
	db $FE, $06
	db $03, $02
	db $03, $01
	db $03, $01
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $02, $01
	db $02, $02
	db $02, $01
	db $A3, $DA
	db $FE, $06
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $03, $01
	db $03, $01
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $02, $02
	db $FE, $06
	db $FB, $02
	db $F9, $50
	db $03, $01
	db $03, $01
	db $A1, $F1
	db $A2, $F0
	db $FE, $06
	db $03, $02
	db $03, $01
	db $03, $01
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $02, $01
	db $02, $01
	db $FE, $06
	db $FB, $02
	db $F9, $50
	db $03, $02
	db $FE, $06
	db $03, $02
	db $03, $01
	db $03, $01
	db $FE, $08
	db $FB, $01
	db $F9, $30
	db $02, $02
	db $FE, $06
	db $02, $01
	db $02, $01
	db $A3, $D7
	db $B0, $AF
	db $FF
