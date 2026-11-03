; Daiku no Gensan - Kachikachi no Tonkachi ga Kachi (J): sound driver B v2
; Common part, byte-identical in banks $3C, $3D and $3E ($4000-$5310):
; driver code, tables, waves, envelopes and all sound effects.
; (bank-0 helpers used: rst $10 = a = [hl+a], rst $20 = hl = [hl+2a], rst $28 = inline jump table)
; INCLUDEd at the top of each Daiku_sound_bankXX.asm (labels stay file-local).

SndEntry_Update:
	jp Snd_Update
SndEntry_Init:
	jp Snd_Init
SndEntry_Request:
	jp Snd_Request
Snd_Init:
	call Snd_Off
	ld a,$FF
	ldh [hSndCurMusic],a
	ldh [hSndCurSfx],a
	ld a,$3C
	ldh [hCurRomBank],a
	ld a,$FF
	ld [wSndFadeMode],a
	ld a,$14
	ld [wSndQueuePtr],a
	ld a,$D5
	ld [wSndQueuePtr+1],a
	xor a
	ld [wSndQueueCount],a
	ld a,$78
	ldh [hSndTempo],a
	call Snd_CalcTempo
	ld a,l
	ldh [hSndTempoStep],a
	ld a,h
	ldh [hSndTempoStep+1],a
	xor a
	ldh [hSndTempoAcc],a
	ldh [hSndTempoAcc+1],a
	ld a,$BC
	ldh [rTIMA],a
	ldh [rTMA],a
	call Snd_On
Snd_ResetRegs:
	ld a,$FF
	ldh [rNR51],a
	ld a,$08
	ldh [rNR10],a
	ld a,$80
	ldh [rNR30],a
	xor a
	ldh [rNR32],a
	ld a,$00
	ldh [rNR31],a
	ret
Snd_On:
	ld a,$80
	ldh [rNR52],a
	ld a,$FF
	ldh [rNR51],a
	ld a,$77
	ldh [rNR50],a
	ret
Snd_Off:
	xor a
	ldh [rNR50],a
	ldh [rNR52],a
	ld a,$FF
	ld [wSndFadeMode],a
	ret
Snd_Request:
	ld b,a
	ld a,[wSndQueueCount]
	cp $08
	jr nc,Snd_RequestFull
	ld a,[wSndQueuePtr]
	ld l,a
	ld a,[wSndQueuePtr+1]
	ld h,a
	ld a,b
	ld [hli],a
	ld a,l
	ld [wSndQueuePtr],a
	ld a,h
	ld [wSndQueuePtr+1],a
	ld hl,wSndQueueCount
	inc [hl]
	or a
	ret
Snd_RequestFull:
	scf
	ret
Snd_Update:
	ldh a,[hSndPause]
	and a
	jr nz,Snd_409F
	call Snd_UpdateMusic
	call Snd_Fade
	jr c,Snd_40A2
Snd_409F:
	call Snd_ProcessQueue
Snd_40A2:
	call Snd_UpdateSfx
	ld hl,wSndSfx1
	ld c,$D1
	call Snd_CheckSetActive
	ld hl,wSndMus1
	ld c,$D0
Snd_CheckSetActive:
	ld de,$0019
	ld b,$04
	xor a
Snd_40B8:
	or [hl]
	add hl,de
	dec b
	jr nz,Snd_40B8
	and $80
	ret nz
	ld a,$FF
	ldh [c],a
	ret
Snd_UpdateSfx:
	ldh a,[hSndCurSfx]
	and $80
	ret nz
	ld hl,wSndSfx4
	ld a,$07
	call Snd_UpdateSfxChan
	ld hl,wSndSfx3
	ld a,$06
	call Snd_UpdateSfxChan
	ld hl,wSndSfx2
	ld a,$05
	call Snd_UpdateSfxChan
	ld hl,wSndSfx1
	ld a,$04
Snd_UpdateSfxChan:
	bit 7,[hl]
	ret z
	call Snd_LoadChan
	call Snd_Tick
	jp Snd_SaveChan
Snd_UpdateMusic:
	ldh a,[hSndCurMusic]
	and $80
	ret nz
	ldh a,[hSndTempoAcc]
	ld l,a
	ldh a,[hSndTempoAcc+1]
	ld h,a
	ld d,h
	ldh a,[hSndTempoStep]
	ld c,a
	ldh a,[hSndTempoStep+1]
	ld b,a
	add hl,bc
	ld a,l
	ldh [hSndTempoAcc],a
	ld a,h
	ldh [hSndTempoAcc+1],a
	sub d
	ret z
	ldh [hSndTicks],a
	ld hl,wSndMus4
	ld de,wSndSfx4
	ld b,$03
	call Snd_UpdateMusicChan
	ld hl,wSndMus3
	ld de,wSndSfx3
	ld b,$02
	call Snd_UpdateMusicChan
	ld hl,wSndMus2
	ld de,wSndSfx2
	ld b,$01
	call Snd_UpdateMusicChan
	ld hl,wSndMus1
	ld de,wSndSfx1
	ld b,$00
Snd_UpdateMusicChan:
	bit 7,[hl]
	ret z
	ld a,[de]
	bit 7,a
	jr z,Snd_4144
	set 2,[hl]
	jr Snd_4146
Snd_4144:
	res 2,[hl]
Snd_4146:
	ld a,b
	call Snd_LoadChan
	ldh a,[hSndTicks]
	ld b,a
Snd_414D:
	push bc
	call Snd_Tick
	pop bc
	dec b
	jr nz,Snd_414D
	jp Snd_SaveChan
Snd_LoadChan:
	ld [wSndChanIdx],a
	ld hl,SndChanPtrTable
	rst $20
	ld c,$D8
	ld b,$19
Snd_4163:
	ld a,[hli]
	ldh [c],a
	inc c
	dec b
	jr nz,Snd_4163
	ld a,[wSndChanIdx]
	and $03
	ld hl,SndNRx1Table
	rst $10
	ld [wSndNRx1],a
	ret
SndNRx1Table:
	db $11, $16, $1B, $20
Snd_SaveChan:
	ld a,[wSndChanIdx]
	ld hl,SndChanPtrTable
	rst $20
	ld c,$D8
	ld b,$19
Snd_4185:
	ldh a,[c]
	inc c
	ld [hli],a
	dec b
	jr nz,Snd_4185
	ret
SndChanPtrTable:
	dw $D44C, $D465, $D47E, $D497
	dw $D4B0, $D4C9, $D4E2, $D4FB
Snd_Tick:
	ldh a,[hSndFlags]
	bit 3,a
	jr z,Snd_OctEnvStep
	ldh a,[hSndPEnvPtr]
	ld e,a
	ldh a,[hSndPEnvPtr+1]
	ld d,a
Snd_41A8:
	ld a,[de]
	inc de
	cp $80
	jr nz,Snd_41B1
	jp Snd_TickCount
Snd_41B1:
	cp $81
	jr nz,Snd_41BD
	ld a,[de]
	inc de
	ld c,a
	ld a,[de]
	ld d,a
	ld e,c
	jr Snd_41A8
Snd_41BD:
	ld c,a
	ld a,e
	ldh [hSndPEnvPtr],a
	ld a,d
	ldh [hSndPEnvPtr+1],a
	ldh a,[hSndFreq]
	ld l,a
	ldh a,[hSndFreq+1]
	ld h,a
	ld b,$00
	bit 7,c
	jr z,Snd_41D1
	dec b
Snd_41D1:
	add hl,bc
	ld a,l
	ldh [hSndFreq],a
	ld a,h
	ldh [hSndFreq+1],a
	ldh a,[hSndFlags]
	bit 2,a
	jr nz,Snd_TickCount
	ld a,[wSndNRx1]
	ld c,a
	inc c
	inc c
	ldh a,[hSndFreq]
	ldh [c],a
	inc c
	ldh a,[hSndFreq+1]
	and $07
	ldh [c],a
	jr Snd_TickCount
Snd_OctEnvStep:
	ldh a,[hSndFlags]
	bit 1,a
	jr z,Snd_TickCount
	ldh a,[hSndPEnvPtr]
	ld e,a
	ldh a,[hSndPEnvPtr+1]
	ld d,a
Snd_41FB:
	ld a,[de]
	inc de
	cp $80
	jr nz,Snd_4203
	jr Snd_TickCount
Snd_4203:
	cp $81
	jr nz,Snd_420F
	ld a,[de]
	inc de
	ld c,a
	ld a,[de]
	ld d,a
	ld e,c
	jr Snd_41FB
Snd_420F:
	ld b,a
	ld a,e
	ldh [hSndPEnvPtr],a
	ld a,d
	ldh [hSndPEnvPtr+1],a
	ldh a,[hSndFreq]
	ld l,a
	ldh a,[hSndFreq+1]
	ld h,a
	ld a,b
	and a
	jr z,Snd_423B
	bit 7,b
	jr z,Snd_4234
	xor a
	sub b
	ld b,a
Snd_4227:
	ld a,$08
	or h
	ld h,a
	srl h
	rr l
	dec b
	jr nz,Snd_4227
	jr Snd_423B
Snd_4234:
	sla l
	rl h
	dec b
	jr nz,Snd_4234
Snd_423B:
	ldh a,[hSndFlags]
	bit 2,a
	jr nz,Snd_TickCount
	ld a,[wSndNRx1]
	ld c,a
	inc c
	inc c
	ld a,l
	ldh [c],a
	inc c
	ld a,h
	and $07
	ldh [c],a
Snd_TickCount:
	ldh a,[hSndCount]
	and a
	call z,Snd_ParseRow
	ld hl,hSndCount
	dec [hl]
	ret
Snd_ParseRow:
	ldh a,[hSndPtr]
	ld e,a
	ldh a,[hSndPtr+1]
	ld d,a
Snd_ParseLoop:
	ld a,[de]
	inc de
	cp $80
	jp c,Snd_SetLength
	cp $D4
	jp c,Snd_Note
	cp $E4
	jp c,Snd_Drum
	jp z,SndCmd_Noise
	cp $E6
	jp z,SndCmd_Off
	cp $E5
	jp z,SndCmd_Rest
	jp Snd_Command
SndCmd_Off:
	call Snd_SilenceChan
	jp Snd_RowDone
Snd_SilenceChan:
	ldh a,[hSndFlags]
	bit 2,a
	ret nz
	ld a,[wSndChanIdx]
	and $03
	jr z,Snd_SilenceCh1
	dec a
	jr z,Snd_SilenceCh2
	dec a
	jr z,Snd_SilenceCh3
Snd_SilenceCh4:
	ld a,$08
	ldh [rNR42],a
	ld a,$80
	ldh [rNR44],a
	ret
Snd_SilenceCh3:
	ld a,$7F
	ldh [rNR30],a
	xor a
	ldh [rNR32],a
	ret
Snd_SilenceCh2:
	ld a,$08
	ldh [rNR22],a
	ld a,$80
	ldh [rNR24],a
	ret
Snd_SilenceCh1:
	ld a,$08
	ldh [rNR12],a
	ld a,$80
	ldh [rNR14],a
	ret
SndCmd_Rest:
	inc de
	jp Snd_RowDone
SndCmd_Noise:
	ld a,[de]
	inc de
	ld b,a
	ldh [hSndLength],a
	ldh [hSndCount],a
	and $3F
	ldh [rNR41],a
	ld a,[de]
	inc de
	ldh [rNR42],a
	ld a,[de]
	inc de
	ldh [rNR43],a
	ld a,$80
	ldh [rNR44],a
	jp Snd_SavePtr
Snd_Drum:
	ld b,a
	sub $D4
	ld hl,SndDrumFreqTable
	rst $10
	ld c,a
	ld a,b
	sub $D4
	ld hl,SndDrumEnvTable
	rst $10
	ldh [hSndEnv],a
	ld l,c
	ld h,$00
	jp Snd_NoteOut
Snd_Note:
	sub $80
	ld hl,hSndTranspose
	add a,[hl]
	ld hl,SndFreqTable
	rst $20
Snd_NoteOut:
	ldh a,[hSndFlags]
	bit 2,a
	jr nz,Snd_RowDone
	ld a,l
	ldh [hSndFreq],a
	ld a,h
	ldh [hSndFreq+1],a
	ld a,[wSndNRx1]
	ld c,a
	ld a,[wSndChanIdx]
	and $03
	cp $02
	jr nz,Snd_4334
	ldh a,[hSndFlags]
	and $40
	or $80
	ld b,a
	ld a,$7F
	ldh [rNR30],a
	ld a,$80
	ldh [rNR30],a
	ldh a,[hSndDuty]
	ldh [c],a
	ldh a,[hSndEnv]
	inc c
	ldh [c],a
	ldh a,[hSndFreq]
	inc c
	ldh [c],a
	ldh a,[hSndFreq+1]
	or b
	inc c
	ldh [c],a
	jr Snd_RowDone
Snd_4334:
	ldh a,[hSndDuty]
	ldh [c],a
	ldh a,[hSndEnv]
	inc c
	ldh [c],a
	ldh a,[hSndFreq]
	inc c
	ldh [c],a
	ldh a,[hSndFreq+1]
	or $80
	inc c
	ldh [c],a
Snd_RowDone:
	ldh a,[hSndLength]
	ldh [hSndCount],a
	ldh a,[hSndPEnvStart]
	ldh [hSndPEnvPtr],a
	ldh a,[hSndPEnvStart+1]
	ldh [hSndPEnvPtr+1],a
Snd_SavePtr:
	ld a,e
	ldh [hSndPtr],a
	ld a,d
	ldh [hSndPtr+1],a
	ret
Snd_SetLength:
	ldh [hSndLength],a
	jp Snd_ParseLoop
Snd_Command:
	sub $E7
	rst $28
SndCommandTable:
	dw SndCmd_End, SndCmd_Jump, SndCmd_Call, SndCmd_Ret
	dw SndCmd_Loop, SndCmd_EndLoop, SndCmd_Tempo, SndCmd_Env
	dw SndCmd_PitchEnv, SndCmd_Nop, SndCmd_Duty, SndCmd_Pan
	dw SndCmd_Transpose, SndCmd_Vol, SndCmd_EnvLo, SndCmd_OctEnv
	dw SndCmd_Wave, SndCmd_WaveRestore, SndCmd_Env2, SndCmd_Ch3Len
SndCmd_End:
	xor a
	ldh [hSndFlags],a
	jp Snd_SilenceChan
SndCmd_Jump:
	ld a,[de]
	inc de
	ld l,a
	ld a,[de]
	ld d,a
	ld e,l
	jp Snd_ParseLoop
SndCmd_Call:
	ld a,[de]
	inc de
	ld c,a
	ld a,[de]
	inc de
	ld b,a
	ld a,e
	ldh [hSndRetPtr],a
	ld a,d
	ldh [hSndRetPtr+1],a
	ld e,c
	ld d,b
	jp Snd_ParseLoop
SndCmd_Ret:
	ldh a,[hSndRetPtr]
	ld e,a
	ldh a,[hSndRetPtr+1]
	ld d,a
	jp Snd_ParseLoop
SndCmd_Loop:
	ld a,[de]
	inc de
	ldh [hSndLoopCount],a
	ld a,e
	ldh [hSndLoopPtr],a
	ld a,d
	ldh [hSndLoopPtr+1],a
	jp Snd_ParseLoop
SndCmd_EndLoop:
	ld hl,hSndLoopCount
	dec [hl]
	jr z,Snd_43CA
	ldh a,[hSndLoopPtr]
	ld e,a
	ldh a,[hSndLoopPtr+1]
	ld d,a
Snd_43CA:
	jp Snd_ParseLoop
SndCmd_Tempo:
	ld a,[de]
	inc de
	ldh [hSndTempo],a
	push de
	call Snd_CalcTempo
	pop de
	ld a,l
	ldh [hSndTempoStep],a
	ld a,h
	ldh [hSndTempoStep+1],a
	jp Snd_ParseLoop
SndCmd_Env:
	ld a,[de]
	inc de
	ldh [hSndEnv],a
	jp Snd_ParseLoop
SndCmd_PitchEnv:
	ld hl,hSndFlags
	res 1,[hl]
	set 3,[hl]
	ld a,[de]
	inc de
	ld c,a
	ldh [hSndPEnvStart],a
	ldh [hSndPEnvPtr],a
	ld a,[de]
	inc de
	ldh [hSndPEnvStart+1],a
	ldh [hSndPEnvPtr+1],a
	or c
	jp nz,Snd_ParseLoop
	res 3,[hl]
	jp Snd_ParseLoop
SndCmd_Nop:
	jp Snd_ParseLoop
SndCmd_Duty:
	ldh a,[hSndFlags]
	bit 2,a
	jr z,Snd_440F
	ld a,[de]
	jr Snd_4415
Snd_440F:
	ld a,[wSndNRx1]
	ld c,a
	ld a,[de]
	ldh [c],a
Snd_4415:
	ldh [hSndDuty],a
	inc de
	jp Snd_ParseLoop
SndCmd_Pan:
	ld a,[de]
	inc de
	ldh [rNR51],a
	jp Snd_ParseLoop
SndCmd_Transpose:
	ld a,[de]
	inc de
	ldh [hSndTranspose],a
	jp Snd_ParseLoop
SndCmd_Vol:
	ldh a,[hSndEnv]
	and $0F
	ld c,a
	ld a,[de]
	inc de
	or c
	ldh [hSndEnv],a
	jp Snd_ParseLoop
SndCmd_EnvLo:
	ldh a,[hSndEnv]
	and $F0
	ld c,a
	ld a,[de]
	inc de
	or c
	ldh [hSndEnv],a
	jp Snd_ParseLoop
SndCmd_OctEnv:
	ld hl,hSndFlags
	set 1,[hl]
	res 3,[hl]
	ld a,[de]
	inc de
	ld c,a
	ldh [hSndPEnvStart],a
	ldh [hSndPEnvPtr],a
	ld a,[de]
	inc de
	ldh [hSndPEnvStart+1],a
	ldh [hSndPEnvPtr+1],a
	or c
	jp nz,Snd_ParseLoop
	res 1,[hl]
	jp Snd_ParseLoop
SndCmd_Wave:
	ld a,[wSndWavePtr]
	ld [wSndWaveSaved],a
	ld a,[wSndWavePtr+1]
	ld [wSndWaveSaved+1],a
	ld a,$00
	ldh [rNR30],a
	ld a,[de]
	ld [wSndWavePtr],a
	ld l,a
	inc de
	ld a,[de]
	ld [wSndWavePtr+1],a
	ld h,a
	inc de
	push bc
	ld bc,$1030
Snd_4480:
	ld a,[hli]
	ldh [c],a
	inc c
	dec b
	jr nz,Snd_4480
	pop bc
	ld a,$80
	ldh [rNR30],a
	jp Snd_ParseLoop
SndCmd_WaveRestore:
	ld a,$00
	ldh [rNR30],a
	ld a,[wSndWaveSaved]
	ld [wSndWavePtr],a
	ld l,a
	ld a,[wSndWaveSaved+1]
	ld [wSndWavePtr+1],a
	ld h,a
	push bc
	ld bc,$1030
Snd_44A4:
	ld a,[hli]
	ldh [c],a
	inc c
	dec b
	jr nz,Snd_44A4
	pop bc
	ld a,$80
	ldh [rNR30],a
	jp Snd_ParseLoop
SndCmd_Env2:
	ld a,[de]
	inc de
	ldh [hSndEnv],a
	jp Snd_ParseLoop
SndCmd_Ch3Len:
	ld hl,hSndFlags
	ld a,[de]
	inc de
	and a
	jr z,Snd_44C6
	set 6,[hl]
	jp Snd_ParseLoop
Snd_44C6:
	res 6,[hl]
	jp Snd_ParseLoop
Snd_Fade:
	ld a,[wSndFadeMode]
	and $80
	ret nz
	ld a,[wSndFadeTimer]
	and a
	jr nz,Snd_4502
	ld a,$0A
	ld [wSndFadeTimer],a
	ld a,[wSndFadeMode]
	and a
	ldh a,[rNR50]
	jr z,Snd_44F3
	and $77
	jr nz,Snd_44ED
	call SndSys_StopAll
	jr Snd_44FD
Snd_44ED:
	sub $11
	ldh [rNR50],a
	jr Snd_4502
Snd_44F3:
	add a,$11
	and $77
	ldh [rNR50],a
	cp $77
	jr nz,Snd_4502
Snd_44FD:
	ld a,$FF
	ld [wSndFadeMode],a
Snd_4502:
	ld hl,wSndFadeTimer
	dec [hl]
	scf
	ret
Snd_ProcessQueue:
	ld a,[wSndQueueCount]
	and a
	ret z
	ld b,a
	ld a,[wSndQueuePtr]
	ld l,a
	ld a,[wSndQueuePtr+1]
	ld h,a
Snd_4516:
	dec hl
	push hl
	push bc
	call Snd_HandleRequest
	pop bc
	pop hl
	dec b
	jr nz,Snd_4516
	ld a,l
	ld [wSndQueuePtr],a
	ld a,h
	ld [wSndQueuePtr+1],a
	xor a
	ld [wSndQueueCount],a
	ret
Snd_HandleRequest:
	ld a,[hl]
	cp $40
	jp c,Snd_StartMusic
	cp $F0
	jp nc,Snd_SysCommand
	sub $40
	ld c,a
	ldh a,[hSndCurSfx]
	bit 7,a
	jr nz,Snd_StartSfx
	ld hl,SndSfxPriority
	rst $10
	ld b,a
	ld a,c
	ld hl,SndSfxPriority
	rst $10
	cp b
	ret c
	call Snd_SilenceSfxChans
Snd_StartSfx:
	ld a,c
	ldh [hSndCurSfx],a
	call Snd_ClearSfx
	xor a
	ld [wSndSfx1+$03],a
	ld [wSndSfx2+$03],a
	ld [wSndSfx3+$03],a
	ld [wSndSfx4+$03],a
	ld [wSndSfx1+$18],a
	ld [wSndSfx2+$18],a
	ld [wSndSfx3+$18],a
	ld [wSndSfx4+$18],a
	ld a,c
	ld hl,SndSfxTable
	rst $20
	ld a,[hli]
	ld c,a
	ld de,wSndSfx1+$01
	call Snd_SetPointers
	ld hl,wSndSfx1
	call Snd_SetActive
	call Snd_On
	ret
Snd_ClearSfx:
	xor a
	ld [wSndSfx1],a
	ld [wSndSfx2],a
	ld [wSndSfx3],a
	ld [wSndSfx4],a
	ret
Snd_SilenceSfxChans:
	ld hl,Snd_SilenceCh1
	ld a,[wSndSfx1]
	call Snd_JumpIfActive
	ld hl,Snd_SilenceCh2
	ld a,[wSndSfx2]
	call Snd_JumpIfActive
	ld hl,Snd_SilenceCh3
	ld a,[wSndSfx3]
	call Snd_JumpIfActive
	ld hl,Snd_SilenceCh4
	ld a,[wSndSfx4]
Snd_JumpIfActive:
	bit 7,a
	ret z
	jp hl
SndMusicBankTable:
	db $3C, $00	; music $00: bank, index
	db $3C, $01	; music $01: bank, index
	db $3C, $02	; music $02: bank, index
	db $3C, $03	; music $03: bank, index
	db $3C, $04	; music $04: bank, index
	db $3C, $05	; music $05: bank, index
	db $3C, $06	; music $06: bank, index
	db $3C, $07	; music $07: bank, index
	db $3C, $08	; music $08: bank, index
	db $3C, $09	; music $09: bank, index
	db $3C, $0A	; music $0A: bank, index
	db $3C, $0B	; music $0B: bank, index
	db $3D, $00	; music $0C: bank, index
	db $3D, $01	; music $0D: bank, index
	db $3D, $02	; music $0E: bank, index
	db $3D, $03	; music $0F: bank, index
	db $3D, $04	; music $10: bank, index
	db $3D, $05	; music $11: bank, index
	db $3D, $06	; music $12: bank, index
	db $3D, $07	; music $13: bank, index
	db $3D, $08	; music $14: bank, index
	db $3D, $09	; music $15: bank, index
	db $3D, $0A	; music $16: bank, index
	db $3D, $0B	; music $17: bank, index
	db $3D, $0C	; music $18: bank, index
	db $3D, $0D	; music $19: bank, index
	db $3E, $00	; music $1A: bank, index
	db $3E, $01	; music $1B: bank, index
Snd_StartMusic:
	ldh [hSndCurMusic],a
	ld hl,SndMusicBankTable
	rst $20
	ld c,h
	ld a,l
	ldh [hCurRomBank],a
	ldh [hCurRomBank2],a
	ld [rROMB0],a
	call Snd_Off
	call Snd_ClearMusic
	xor a
	ld [wSndMus1+$03],a
	ld [wSndMus2+$03],a
	ld [wSndMus3+$03],a
	ld [wSndMus4+$03],a
	ld [wSndMus1+$18],a
	ld [wSndMus2+$18],a
	ld [wSndMus3+$18],a
	ld [wSndMus4+$18],a
	ld a,c
	ld hl,SndMusicTable
	rst $20
	ld a,[hli]
	ld c,a
	ld de,wSndMus1+$01
	call Snd_SetPointers
	ld hl,wSndMus1
	call Snd_SetActive
	call Snd_On
	ldh a,[hSndCurMusic]
	ld hl,SndMusicWaveTable
	rst $20
	ld a,l
	ld [wSndWavePtr],a
	ld [wSndWaveSaved],a
	ld a,h
	ld [wSndWavePtr+1],a
	ld [wSndWaveSaved+1],a
	ld bc,$1030
Snd_464D:
	ld a,[hli]
	ldh [c],a
	inc c
	dec b
	jr nz,Snd_464D
	jp Snd_ResetRegs
Snd_ClearMusic:
	xor a
	ld [wSndMus1],a
	ld [wSndMus2],a
	ld [wSndMus3],a
	ld [wSndMus4],a
	ret
Snd_SetPointers:
	ld a,c
	ld b,$04
Snd_4667:
	rra
	push af
	jr nc,Snd_4671
	ld a,[hli]
	ld [de],a
	inc de
	ld a,[hli]
	ld [de],a
	dec de
Snd_4671:
	push hl
	ld hl,$0019
	add hl,de
	ld e,l
	ld d,h
	pop hl
	pop af
	dec b
	jr nz,Snd_4667
	ret
Snd_SetActive:
	ld de,$0019
	ld b,$04
	ld a,c
Snd_4684:
	rra
	jr nc,Snd_4689
	set 7,[hl]
Snd_4689:
	add hl,de
	dec b
	jr nz,Snd_4684
	ret
Snd_SysCommand:
	sub $F0
	rst $28
SndSysCmdTable:
	dw SndSys_StopAll, SndSys_StopMusic, SndSys_StopSfx, SndSys_FadeIn
	dw SndSys_FadeOut, SndSys_VolLow, SndSys_VolFull, SndSys_SilenceAll
SndSys_StopAll:
	call Snd_ClearSfx
	call Snd_ClearMusic
	ld a,$FF
	ldh [hSndCurMusic],a
	ldh [hSndCurSfx],a
	jp Snd_Off
SndSys_StopMusic:
	call Snd_ClearMusic
	ld a,$FF
	ldh [hSndCurMusic],a
	jr SndSys_SilenceAll
SndSys_StopSfx:
	call Snd_SilenceSfxChans
	call Snd_ClearSfx
	ld a,$FF
	ldh [hSndCurSfx],a
	ret
SndSys_FadeIn:
	xor a
	ldh [rNR50],a
Snd_46C7:
	ld [wSndFadeMode],a
	xor a
	ld [wSndFadeUnused],a
	ld a,$0A
	ld [wSndFadeTimer],a
	ret
SndSys_FadeOut:
	ld a,$01
	jr Snd_46C7
SndSys_VolLow:
	ld a,$11
	ldh [rNR50],a
	ret
SndSys_VolFull:
	ld a,$77
	ldh [rNR50],a
	ret
SndSys_SilenceAll:
	call Snd_SilenceCh1
	call Snd_SilenceCh2
	call Snd_SilenceCh3
	jp Snd_SilenceCh4
Snd_CalcTempo:
	ld e,$00
	ld d,a
	ld c,$96
	call Snd_Div16x8
	ret
Snd_Div16x8:
	xor a
	ld b,$10
Snd_46FA:
	sla e
	rl d
	rla
	jr c,Snd_470E
	sub c
	jr nc,Snd_4705
	add a,c
Snd_4705:
	ccf
Snd_4706:
	rl l
	rl h
	dec b
	jr nz,Snd_46FA
	ret
Snd_470E:
	sub c
	scf
	jp Snd_4706
SndFreqTable:
	dw $002C, $009C, $0107, $016B, $01C9, $0223, $0277, $02C7, $0312, $0358, $039B, $03DA
	dw $0416, $044E, $0483, $04B5, $04E5, $0511, $053C, $0563, $0589, $05AC, $05CE, $05ED
	dw $060B, $0628, $0642, $065B, $0672, $0689, $069E, $06B2, $06C4, $06D6, $06E7, $06F7
	dw $0706, $0714, $0721, $072D, $0739, $0744, $074F, $0759, $0762, $076B, $0773, $077B
	dw $0783, $078A, $0790, $0797, $079D, $07A2, $07A7, $07AC, $07B1, $07B6, $07BA, $07BE
	dw $07C1, $07C5, $07C8, $07CB, $07CE, $07D1, $07D4, $07D6, $07D9, $07DB, $07DD, $07DF
	dw $07E1, $07E2, $07E4, $07E6, $07E7, $07E9, $07EA, $07EB, $07EC, $07ED, $07EE, $07EF
	dw $07F0, $07F1, $07F2, $07F3, $07F4, $07F4, $07F5, $07F6, $07F6, $07F7, $07F7, $07F8
	dw $07F8
SndDrumEnvTable:
	db $71, $61, $75, $A1, $A1, $A1, $B1, $F1, $F1, $F1, $75, $76, $74, $61, $61, $61
SndDrumFreqTable:
	db $00, $20, $10, $30, $32, $5C, $6C, $5B, $5D, $5F, $10, $31, $00, $19, $01, $00
SndMusicWaveTable:
	dw SndWave00, SndWave01, SndWave02, SndWave03
	dw SndWave04, SndWave05, SndWave06, SndWave07
	dw SndWave08, SndWave09, SndWave0A, SndWave0B
	dw SndWave0C, SndWave0D, SndWave0E, SndWave0F
	dw SndWave10, SndWave11, SndWave12
SndWave00:
	db $00, $56, $BC, $FF, $CB, $65, $00, $56, $BC, $FF, $CB, $65, $00, $56, $BC, $FF
SndWave01:
	db $00, $ED, $FE, $C6, $00, $F5, $F3, $D5, $00, $F5, $FB, $D7, $00, $F5, $03, $C9
SndWave02:
	db $20, $40, $60, $80, $A0, $C0, $E0, $F0, $F0, $E0, $C0, $A0, $80, $60, $40, $20
SndWave03:
	db $00, $00, $11, $13, $7A, $DD, $EE, $EF, $FF, $FF, $ED, $AA, $83, $31, $10, $00
SndWave04:
	db $FF, $00, $EE, $00, $DD, $00, $CC, $00, $BB, $00, $AA, $00, $88, $00, $77, $00
SndWave05:
	db $00, $22, $44, $66, $88, $AA, $CC, $EE, $FF, $DD, $BB, $99, $77, $55, $33, $11
SndWave06:
	db $FF, $EE, $BB, $AA, $66, $55, $22, $11, $11, $22, $55, $66, $AA, $BB, $EE, $FF
SndWave07:
	db $00, $88, $44, $00, $00, $88, $88, $00, $00, $88, $CC, $00, $00, $88, $FF, $FF
SndWave08:
	db $4A, $EF, $FF, $FE, $ED, $DB, $99, $BC, $B9, $86, $78, $E8, $40, $10, $00, $12
SndWave09:
	db $4A, $CE, $ED, $CE, $FE, $CA, $76, $56, $8A, $BA, $85, $12, $45, $54, $21, $23
SndWave0A:
	db $4A, $2D, $3E, $0D, $2A, $0F, $F1, $53, $C1, $73, $82, $75, $76, $8A, $60, $72
SndWave0B:
	db $49, $DC, $BA, $8F, $DA, $A9, $98, $87, $66, $53, $08, $77, $65, $53, $01, $32
SndWave0C:
	db $45, $DD, $FF, $D9, $9A, $A9, $B9, $77, $9B, $AB, $66, $45, $42, $54, $50, $13
SndWave0D:
	db $5A, $FF, $CA, $CD, $BD, $D9, $9B, $97, $53, $21, $01, $21, $23, $33, $20, $01
SndWave0E:
	db $47, $AC, $CA, $88, $8C, $EF, $FD, $C7, $42, $00, $04, $77, $41, $00, $00, $12
SndWave0F:
	db $49, $DC, $86, $77, $AD, $FF, $EC, $94, $31, $00, $13, $7C, $FA, $63, $20, $02
SndWave10:
	db $68, $CC, $EF, $FF, $FE, $ED, $B8, $43, $42, $00, $00, $13, $44, $32, $22, $23
SndWave11:
	db $8F, $DD, $CC, $BB, $AA, $99, $87, $65, $43, $21, $6B, $99, $98, $76, $54, $35
SndWave12:
	db $8E, $DF, $DC, $CB, $AC, $AC, $A9, $86, $54, $33, $22, $21, $17, $56, $65, $54
SndPitchEnv_494B:
	db -2, 2, 2, -2
	env_jump SndPitchEnv_494B
SndEnvUnused_4952:
	db -4, 4, 4, -4
	env_jump SndEnvUnused_4952
SndPitchEnv_4959:
	db -3, -2, -1, 0, 0, 1, 2, 3, -3, -2, -1, 0, 0, 1, 2, 3
	env_jump SndPitchEnv_4959
SndPitchEnv_496C:
	db 0, 0
SndEnv_496E:
	db -1, -2, 1, 2, 1, -1
	env_jump SndEnv_496E
SndPitchEnv_4977:
	db 5, 4, -4, -5, -4, 4
	env_jump SndPitchEnv_4977
SndEnvUnused_4980:
	db 0, 0, 0, 0, 0, 0
SndEnv_4986:
	db 0, 0, 0, 1, -1
	env_jump SndEnv_4986
SndPitchEnv_498E:
	db 0, 0, 0, 0, 0, 0
SndEnv_4994:
	db 0, 0, -1, 1
	env_jump SndEnv_4994
SndPitchEnv_499B:
	db 0, 0, 0, 0, 0, 0
SndEnv_49A1:
	db -1, 1, 1, -1
	env_jump SndEnv_49A1
SndPitchEnv_49A8:
	db 0, 0, 0, 0, 0, 0, 0, 0
SndEnv_49B0:
	db -1, 1, 0, 1, -1, 0
	env_jump SndEnv_49B0
SndPitchEnv_49B9:
	db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
SndEnv_49C3:
	db -1, 1, 0, 0, 1, -1, 0, 0
	env_jump SndEnv_49C3
SndEnvUnused_49CE:
	db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
SndEnv_49DC:
	db -1, 1, 0, 0, 0, 1, -1, 0, 0, 0
	env_jump SndEnv_49DC
SndPitchEnv_49E9:
	db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
SndEnv_49F3:
	db -1, 0, 1, 0, 0, 0, 0, 1, 0, -1, 0, 0, 0, 0
	env_jump SndEnv_49F3
SndPitchEnv_4A04:
	db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
SndEnv_4A0E:
	db -1, 0, 0, 1, 0, 1, 0, 0, -1, 0
	env_jump SndEnv_4A0E
SndPitchEnv_4A1B:
	db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
SndEnv_4A25:
	db -1, -1, 1, 1, 0, 0, 0, 1, 1, -1, -1, 0, 0, 0
	env_jump SndEnv_4A25
SndPitchEnv_4A36:
	db -1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
SndEnv_4A43:
	db -1, 0, 1, 0, 0, 0, 0, -1, 0, 1, 0, 0, 0, 0, 0
	env_jump SndEnv_4A43
SndPitchEnv_4A55:
	db -2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
SndEnv_4A64:
	db -1, 0, 1, 0, 0, 0, 0, -1, 0, 1, 0, 0, 0
	env_jump SndEnv_4A64
SndPitchEnv_4A74:
	db -3, 4, -1, 0, 0, 0, 0, 0, 0, 0
SndEnv_4A7E:
	db -1, 0, 1, 0, 0, 0, 0, 0, 0, -1, 0, 1, 0, 0, 0, 0
	env_jump SndEnv_4A7E
SndPitchEnv_4A91:
	db -4, 4
	env_stop
SndEnvUnused_4A94:
	db -5, 5
	env_stop
SndEnvUnused_4A97:
	db -6, 6
	env_stop
SndEnvUnused_4A9A:
	db 1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
SndEnv_4AA7:
	db -1, 0, 1, 0, 0, 0, 0, 1, 0, -1, 0, 0, 0, 0, 0
	env_jump SndEnv_4AA7
SndPitchEnv_4AB9:
	db 1
	env_jump SndPitchEnv_4AB9
SndPitchEnv_4ABD:
	db -1
	env_jump SndPitchEnv_4ABD
SndPitchEnv_4AC1:
	db 0, 1
	env_jump SndPitchEnv_4AC1
SndEnvUnused_4AC6:
	db 0, -1
	env_jump SndEnvUnused_4AC6
SndEnvUnused_4ACB:
	db 0, 0, 1
	env_jump SndEnvUnused_4ACB
SndEnvUnused_4AD1:
	db 0, 0, -1
	env_jump SndEnvUnused_4AD1
SndPitchEnv_4AD7:
	env_stop
SndOctEnv_4AD8:
	db 1
SndEnv_4AD9:
	db 0
	env_jump SndEnv_4AD9
SndEnvUnused_4ADD:
	db 1, 0
	env_jump SndEnvUnused_4ADD
SndEnvUnused_4AE2:
	db 1, 0, 0
	env_jump SndEnvUnused_4AE2
SndOctEnv_4AE8:
	db 1, 1, 0, 0
	env_jump SndOctEnv_4AE8
SndOctEnv_4AEF:
	db -1
SndEnv_4AF0:
	db 0
	env_jump SndEnv_4AF0
SndEnvUnused_4AF4:
	db -1, 0
	env_jump SndEnvUnused_4AF4
SndOctEnv_4AF9:
	db -1, 0, 0
	env_jump SndOctEnv_4AF9
SndOctEnv_4AFF:
	db -1, -1, 0, 0
	env_jump SndOctEnv_4AFF
SndOctEnv_4B06:
	db 0, 1, -1, 0
	env_jump SndOctEnv_4B06
SndNullTrack:
	snd_end
SndSfxPriority:
	db $80, $80, $80, $10, $80, $80, $80, $90, $80, $80, $80, $80, $D0, $E0, $E0, $F0	; SFX $40-$4F
	db $F0, $D0, $D0, $D0, $90, $90, $90, $80, $80, $80, $80, $B0, $B0, $80, $B0, $B0	; SFX $50-$5F
	db $B0, $B0, $E0, $80, $80, $80, $80, $80, $D0, $F0, $F0, $E0, $80, $80, $80, $80	; SFX $60-$6F
	db $80, $80, $80, $B0, $B0, $B0, $B0, $B0, $B0, $C0, $C0, $80, $80, $80, $80, $E0	; SFX $70-$7F
SndSfxTable:
	dw Sfx40, Sfx41, Sfx42, Sfx43, Sfx44, Sfx45, Sfx46, Sfx47
	dw Sfx48, Sfx49, Sfx4A, Sfx4B, Sfx4C, Sfx4D, Sfx4E, Sfx4F
	dw Sfx50, Sfx51, Sfx52, Sfx53, Sfx54, Sfx55, Sfx56, Sfx57
	dw Sfx58, Sfx59, Sfx5A, Sfx5B, Sfx5C, Sfx5D, Sfx5E, Sfx5F
	dw Sfx60, Sfx61, Sfx62, Sfx63, Sfx64, Sfx65, Sfx66, Sfx67
	dw Sfx68, Sfx69, Sfx6A, Sfx6B, Sfx6C, Sfx6D, Sfx6E, Sfx6F
	dw Sfx70, Sfx71, Sfx72, Sfx73, Sfx74, Sfx75, Sfx76, Sfx77
	dw Sfx78, Sfx79, Sfx7A, Sfx7B, Sfx7C, Sfx7D, Sfx7E, Sfx7F
Sfx40:
	db $01	; channel mask
	dw Sfx40_Ch1
Sfx40_Ch1:
	snd_pitchenv SndPitchEnv_496C
	snd_duty $80
	snd_env $40
	snd_note As_4, 1
	snd_note Cs_5
	snd_duty $80
	snd_env $60
	snd_note F_5, 2
	snd_note A_5
	snd_note C_6
	snd_note D_6
	snd_note Ds_6
	snd_note E_6
	snd_note F_6
	snd_note Fs_6
	snd_env $50
	snd_note E_6, 1
	snd_note D_6
	snd_note C_6
	snd_note As_5
	snd_note F_5
	snd_note D_5
	snd_note B_4
	snd_note Gs_4
	snd_end
Sfx41:
	db $01	; channel mask
	dw Sfx41_Ch1
Sfx41_Ch1:
	snd_duty $80
	snd_env $C0
	snd_note F_3, 2
	snd_note B_5, 1
	snd_note As_5
	snd_note Fs_5
	snd_note F_5
	snd_note D_5
	snd_note A_4
	snd_note As_4
	snd_note G_4
	snd_note F_4
	snd_note E_4
	snd_note D_4
	snd_end
Sfx42:
	db $01	; channel mask
	dw Sfx42_Ch1
Sfx42_Ch1:
	snd_duty $80
	snd_env $D0
	snd_note E_4, 2
	snd_note Ds_4, 1
	snd_note C_4
	snd_note Gs_3, 2
	snd_note Ds_5, 1
	snd_note D_5
	snd_note As_4
	snd_note F_4
	snd_note As_3, 2
	snd_note A_3, 1
	snd_note Gs_3
	snd_note Cs_3, 2
	snd_end
Sfx43:
	db $01	; channel mask
	dw Sfx43_Ch1
Sfx43_Ch1:
	snd_duty $80
	snd_len 5
	snd_env $82
	snd_pitchenv SndPitchEnv_4A91
	snd_note E_7
	snd_end
Sfx44:
	db $03	; channel mask
	dw Sfx44_Ch1, Sfx44_Ch2
Sfx44_Ch1:
	snd_duty $80
	snd_env $F0
	snd_note As_2, 1
	snd_note As_3
	snd_note B_2
	snd_note B_3
	snd_duty $00
	snd_env $84
	snd_pitchenv SndPitchEnv_499B
	snd_note G_6, 40
	snd_end
Sfx44_Ch2:
	snd_duty $40
	snd_env $F0
	snd_note D_3, 1
	snd_note C_6
	snd_note Ds_8
	snd_env $F1
	snd_octenv SndOctEnv_4AEF
	snd_note B_4, 15
	snd_end
Sfx45:
	db $01	; channel mask
	dw Sfx45_Ch1
Sfx45_Ch1:
	snd_duty $80
	snd_env $D0
	snd_note Cs_6, 2
	snd_len 1
	snd_off
	snd_env $F0
	snd_note Gs_5, 1
	snd_note Cs_7, 1
	snd_note Cs_8
	snd_end
Sfx46:
	db $08	; channel mask
	dw Sfx46_Ch4
Sfx46_Ch4:
	snd_noise 1, $F0, $6C
	snd_noise 6, $F1, $5A
	snd_end
Sfx47:
	db $01	; channel mask
	dw Sfx47_Ch1
Sfx47_Ch1:
	snd_duty $40
	snd_len 1
	snd_env $80
	snd_note G_5
	snd_note As_5
	snd_note D_6
	snd_len 15
	snd_env $D3
	snd_pitchenv SndPitchEnv_499B
	snd_note Fs_7
	snd_end
Sfx48:
	db $01	; channel mask
	dw Sfx48_Ch1
Sfx48_Ch1:
	snd_duty $80
	snd_env $C0
	snd_note C_5, 1
	snd_off
	snd_duty $00
	snd_note Cs_6
	snd_duty $40
	snd_note C_7
	snd_end
Sfx49:
	db $01	; channel mask
	dw Sfx49_Ch1
Sfx49_Ch1:
	snd_duty $80
	snd_env $41
	snd_note Cs_6, 2
	snd_note D_6
	snd_note Ds_6
	snd_note F_6
	snd_note G_6
	snd_note A_6
	snd_end
Sfx4A:
	db $01	; channel mask
	dw Sfx4A_Ch1
Sfx4A_Ch1:
	snd_duty $00
	snd_len 1
	snd_env $80
	snd_note E_5
	snd_note F_5
	snd_note E_5
	snd_note F_5
	snd_note F_6
	snd_note Fs_6
	snd_note F_6
	snd_note Fs_6
	snd_off
	snd_off
	snd_env $60
	snd_note F_6
	snd_note Fs_6
	snd_note E_6
	snd_note F_6
	snd_env $30
	snd_note D_6
	snd_note Ds_6
	snd_note Cs_6
	snd_note D_6
	snd_end
Sfx4B:
	db $08	; channel mask
	dw Sfx4B_Ch4
Sfx4B_Ch4:
	snd_noise 3, $F2, $42
	snd_end
Sfx4C:
	db $03	; channel mask
	dw Sfx4C_Ch1, Sfx4C_Ch2
Sfx4C_Ch1:
	snd_duty $C0
	snd_len 1
	snd_env $F0
	snd_note E_5
	snd_note F_5
	snd_note E_5
	snd_note F_5
	snd_note F_6
	snd_note Fs_6
	snd_note F_6
	snd_note Fs_6
	snd_off
	snd_off
	snd_env $90
	snd_note F_6
	snd_note Fs_6
	snd_note E_6
	snd_note F_6
	snd_env $50
	snd_note D_6
	snd_note Ds_6
	snd_note Cs_6
	snd_note D_6
	snd_end
Sfx4C_Ch2:
	snd_duty $00
	snd_len 1
	snd_env $F0
	snd_note E_5
	snd_note F_5
	snd_note E_5
	snd_note F_5
	snd_note F_6
	snd_note Fs_6
	snd_note F_6
	snd_note Fs_6
	snd_off
	snd_off
	snd_env $90
	snd_note F_6
	snd_note Fs_6
	snd_note E_6
	snd_note F_6
	snd_env $50
	snd_note D_6
	snd_note Ds_6
	snd_note Cs_6
	snd_note D_6
	snd_end
Sfx4D:
	db $01	; channel mask
	dw Sfx4D_Ch1
Sfx4D_Ch1:
	snd_env $F0
	snd_duty $40
	snd_note B_4, 1
	snd_off
	snd_note A_5
	snd_note B_4
	snd_note A_5
	snd_note B_4
	snd_note A_5
	snd_note B_4
	snd_note A_5
	snd_note B_4
	snd_note A_5
	snd_note B_4, 1
	snd_note B_4
	snd_note A_5
	snd_note A_5
	snd_note B_4
	snd_note B_4
	snd_note B_4
	snd_note A_5
	snd_note A_5
	snd_note A_5
	snd_end
Sfx4E:
	db $01	; channel mask
	dw Sfx4E_Ch1
Sfx4E_Ch1:
	snd_duty $00
	snd_env $F0
	snd_note G_3, 1
	snd_off
	snd_note Cs_2
	snd_note Cs_2
	snd_note As_2, 2
	snd_note A_2, 1
	snd_note Fs_3
	snd_note F_3
	snd_note Ds_4
	snd_note Fs_4
	snd_note A_3
	snd_note D_3
	snd_note C_4
	snd_end
Sfx4F:
	db $01	; channel mask
	dw Sfx4F_Ch1
Sfx4F_Ch1:
	snd_duty $80
	snd_env $F0
	snd_note B_8, 1
	snd_note As_8
	snd_note A_8
	snd_note Gs_8
	snd_note G_8
	snd_note Fs_8
	snd_note F_8
	snd_note E_8
	snd_note Ds_8
	snd_note D_8
	snd_note Cs_8
	snd_note C_8
	snd_env $A0
	snd_note B_7, 1
	snd_note As_7
	snd_note A_7
	snd_note Gs_7
	snd_note G_7
	snd_note Fs_7
	snd_note F_7
	snd_note E_7
	snd_note Ds_7
	snd_note D_7
	snd_note Cs_7
	snd_note C_7
	snd_env $80
	snd_duty $40
	snd_env $87
	snd_pitchenv SndPitchEnv_4ABD
	snd_note C_7, 50
	snd_end
Sfx50:
	db $03	; channel mask
	dw Sfx50_Ch1, Sfx50_Ch2
Sfx50_Ch1:
	snd_env $09
	snd_duty $40
	snd_note G_5, 2
	snd_env $F7
	snd_note G_7, 40
	snd_len 20
	snd_off
	snd_env $87
	snd_note G_7, 60
	snd_end
Sfx50_Ch2:
	snd_env $09
	snd_duty $40
	snd_note G_6, 5
	snd_len 30
	snd_off
	snd_env $A7
	snd_note G_7, 40
	snd_len 30
	snd_off
	snd_env $47
	snd_note G_7, 60
	snd_end
Sfx51:
	db $01	; channel mask
	dw Sfx51_Ch1
Sfx51_Ch1:
	snd_env $81
	snd_duty $80
	snd_note E_6, 1
	snd_pitchenv SndPitchEnv_49A8
	snd_env $84
	snd_duty $40
	snd_note E_7, 40
	snd_end
Sfx52:
	db $01	; channel mask
	dw Sfx52_Ch1
Sfx52_Ch1:
	snd_duty $80
	snd_env $A0
	snd_note C_6, 2
	snd_off
	snd_note Cs_6
	snd_off
	snd_note D_6
	snd_off
	snd_note Ds_6
	snd_off
	snd_note E_6
	snd_off
	snd_note F_6
	snd_off
	snd_note Fs_6
	snd_off
	snd_note G_6
	snd_off
	snd_note Gs_6
	snd_off
	snd_note A_6
	snd_off
	snd_note As_6
	snd_off
	snd_note B_6
	snd_end
Sfx53:
	db $01	; channel mask
	dw Sfx53_Ch1
Sfx53_Ch1:
	snd_duty $70
	snd_env $A0
	snd_note C_6, 2
	snd_off
	snd_note Cs_6
	snd_off
	snd_note D_6
	snd_off
	snd_note Ds_6
	snd_off
	snd_note E_6
	snd_off
	snd_end
Sfx54:
	db $01	; channel mask
	dw Sfx54_Ch1
Sfx54_Ch1:
	snd_env $F3
	snd_duty $80
	snd_note Cs_3, 1
	snd_note Ds_3
	snd_note F_3
	snd_pitchenv SndPitchEnv_4977
	snd_note G_4, 25
	snd_end
Sfx55:
	db $08	; channel mask
	dw Sfx55_Ch4
Sfx55_Ch4:
	snd_noise 2, $F1, $53
	snd_noise 2, $F0, $52
	snd_noise 2, $F0, $51
	snd_noise 2, $F0, $52
	snd_noise 8, $F1, $53
	snd_end
Sfx56:
	db $01	; channel mask
	dw Sfx56_Ch1
Sfx56_Ch1:
	snd_duty $80
	snd_env $D0
	snd_note Cs_6, 2
	snd_len 1
	snd_off
	snd_env $F0
	snd_note Gs_5, 1
	snd_note Cs_7, 1
	snd_note Cs_8
	snd_duty $00
	snd_env $29
	snd_note F_6, 10
	snd_env $A2
	snd_note Ds_5, 1
	snd_note E_5
	snd_note F_5
	snd_note G_5
	snd_note A_5
	snd_note B_5
	snd_note D_6
	snd_note Fs_6
	snd_note Ds_6
	snd_note E_6
	snd_note F_6
	snd_note G_6
	snd_note A_6
	snd_note B_6
	snd_note D_7
	snd_note Fs_7
	snd_end
Sfx57:
	db $01	; channel mask
	dw Sfx57_Ch1
Sfx57_Ch1:
	snd_duty $40
	snd_env $A0
	snd_octenv SndOctEnv_4AEF
	snd_note F_7, 1
	snd_note F_7
	snd_note F_7
	snd_note E_7
	snd_note F_7
	snd_note E_7
	snd_note F_7
	snd_note E_7
	snd_note F_7
	snd_note Fs_7
	snd_note F_7
	snd_note F_7
	snd_note Fs_7
	snd_note Fs_7
	snd_note F_7
	snd_note E_7
	snd_note F_7
	snd_note Fs_7
	snd_note G_7
	snd_note G_7
	snd_end
Sfx58:
	db $08	; channel mask
	dw Sfx58_Ch4
Sfx58_Ch4:
	snd_len 5
	snd_off
	snd_noise 1, $20, $5F
	snd_noise 6, $A9, $5F
	snd_len 1
	snd_off
	snd_noise 11, $FA, $6F
	snd_len 5
	snd_off
	snd_end
Sfx59:
	db $01	; channel mask
	dw Sfx59_Ch1
Sfx59_Ch1:
	snd_duty $80
	snd_env $A0
	snd_note E_3, 1
	snd_note Cs_3
	snd_note G_3
	snd_note C_4
	snd_note E_6
	snd_note Cs_6
	snd_note D_6
	snd_len 10
	snd_pitchenv SndPitchEnv_4AB9
	snd_note F_6
	snd_end
Sfx5A:
	db $01	; channel mask
	dw Sfx5A_Ch1
Sfx5A_Ch1:
	snd_env $F0
	snd_duty $81
	snd_note G_5, 1
	snd_pitchenv SndPitchEnv_4ABD
	snd_env $D3
	snd_note B_4
	snd_end
Sfx5B:
	db $03	; channel mask
	dw Sfx5B_Ch1, Sfx5B_Ch2
Sfx5B_Ch1:
	snd_duty $80
	snd_env $F0
	snd_len 3
	snd_off
	snd_note A_2
	snd_len 1
	snd_off
	snd_note G_2
	snd_note D_3
	snd_note B_2
	snd_note As_2
	snd_note D_3
	snd_note Cs_4
	snd_note E_3
	snd_note C_3
	snd_note Fs_3
	snd_note C_4
	snd_note Gs_3
	snd_note D_4
	snd_note G_4
	snd_note Ds_4
	snd_note A_4
	snd_off
	snd_off
	snd_off
	snd_off
	snd_end
Sfx5B_Ch2:
	snd_duty $40
	snd_env $F0
	snd_len 3
	snd_off
	snd_note A_2
	snd_len 1
	snd_off
	snd_note G_2
	snd_note D_3
	snd_note B_2
	snd_note As_2
	snd_note D_3
	snd_note Cs_4
	snd_note E_3
	snd_note C_3
	snd_note Fs_3
	snd_note C_4
	snd_note Gs_3
	snd_note D_4
	snd_note G_4
	snd_note Ds_4
	snd_note A_4
	snd_off
	snd_off
	snd_off
	snd_off
	snd_end
Sfx5C:
	db $03	; channel mask
	dw Sfx5C_Ch1, Sfx5C_Ch2
Sfx5C_Ch1:
	snd_duty $80
	snd_env $F0
	snd_len 3
	snd_off
	snd_note Gs_2
	snd_len 1
	snd_off
	snd_note F_4
	snd_note As_3
	snd_note Cs_4
	snd_note D_4
	snd_note As_3
	snd_note B_2
	snd_note Gs_3
	snd_note C_4
	snd_note Fs_3
	snd_note C_3
	snd_note E_3
	snd_note As_2
	snd_note F_2
	snd_note A_2
	snd_note Ds_2
	snd_off
	snd_off
	snd_off
	snd_off
	snd_end
Sfx5C_Ch2:
	snd_duty $40
	snd_env $F0
	snd_len 3
	snd_off
	snd_note Gs_2
	snd_len 1
	snd_off
	snd_note F_4
	snd_note As_3
	snd_note Cs_4
	snd_note D_4
	snd_note As_3
	snd_note B_2
	snd_note Gs_3
	snd_note C_4
	snd_note Fs_3
	snd_note C_3
	snd_note E_3
	snd_note As_2
	snd_note F_2
	snd_note A_2
	snd_note Ds_2
	snd_off
	snd_off
	snd_off
	snd_off
	snd_end
Sfx5D:
	db $01	; channel mask
	dw Sfx5D_Ch1
Sfx5D_Ch1:
	snd_duty $80
	snd_env $A0
	snd_note C_4, 1
	snd_note Cs_4
	snd_note Ds_4
	snd_note Fs_4
	snd_note As_4
	snd_note D_5
	snd_note F_5
	snd_note G_5
	snd_note Gs_5
	snd_note A_5
	snd_note As_5
	snd_note A_5
	snd_note Gs_5
	snd_env $80
	snd_note G_5
	snd_note Gs_5
	snd_note A_5
	snd_note As_5
	snd_note A_5
	snd_note Gs_5
	snd_env $60
	snd_note G_5
	snd_note Gs_5
	snd_note A_5
	snd_note As_5
	snd_end
Sfx5E:
	db $01	; channel mask
	dw Sfx5E_Ch1
Sfx5E_Ch1:
	snd_duty $80
	snd_env $80
	snd_pitchenv SndPitchEnv_4ABD
	snd_note A_6, 8
	snd_pitchenv SndPitchEnv_4AC1
	snd_note D_6, 50
	snd_end
Sfx5F:
	db $01	; channel mask
	dw Sfx5F_Ch1
Sfx5F_Ch1:
	snd_duty $80
	snd_env $43
	snd_note G_4, 1
	snd_note Gs_4
	snd_note As_4
	snd_note Cs_5
	snd_env $80
	snd_note F_5
	snd_note A_5
	snd_note C_6
	snd_note D_6
	snd_end
Sfx60:
	db $08	; channel mask
	dw Sfx60_Ch4
Sfx60_Ch4:
	snd_noise 13, $49, $11
	snd_end
Sfx61:
	db $01	; channel mask
	dw Sfx61_Ch1
Sfx61_Ch1:
	snd_duty $40
	snd_env $F6
	snd_pitchenv SndPitchEnv_4ABD
	snd_note G_8, 40
	snd_end
Sfx62:
	db $08	; channel mask
	dw Sfx62_Ch4
Sfx62_Ch4:
	snd_noise 2, $F0, $59
	snd_noise 3, $F7, $5A
	snd_noise 3, $F7, $5D
	snd_noise 21, $F7, $5F
	snd_end
Sfx63:
	db $01	; channel mask
	dw Sfx63_Ch1
Sfx63_Ch1:
	snd_duty $80
	snd_env $80
	snd_octenv SndOctEnv_4AEF
	snd_note E_4, 1
	snd_note E_6
	snd_duty $80
	snd_env $A0
	snd_note E_6
	snd_end
Sfx64:
	db $01	; channel mask
	dw Sfx64_Ch1
Sfx64_Ch1:
	snd_pitchenv SndPitchEnv_4977
	snd_duty $C0
	snd_env $80
	snd_note A_8, 1
	snd_note D_7
	snd_off
	snd_note A_8
	snd_note D_7
	snd_off
	snd_note A_8
	snd_note D_7
	snd_off
	snd_note A_8
	snd_note D_7
	snd_off
	snd_len 2
	snd_env $A0
	snd_note F_6
	snd_note D_7
	snd_note F_6
	snd_note B_5
	snd_env $90
	snd_note F_6
	snd_note D_7
	snd_note F_6
	snd_note B_5
	snd_env $70
	snd_note F_6
	snd_note D_7
	snd_note F_6
	snd_note B_5
	snd_env $50
	snd_note F_6
	snd_note D_7
	snd_note F_6
	snd_note B_5
	snd_env $30
	snd_note F_6
	snd_note D_7
	snd_note F_6
	snd_note B_5
	snd_end
Sfx65:
	db $01	; channel mask
	dw Sfx65_Ch1
Sfx65_Ch1:
	snd_duty $80
	snd_env $A0
	snd_note D_6, 2
	snd_env $A7
	snd_pitchenv SndPitchEnv_4ABD
	snd_note G_7, 15
	snd_end
Sfx66:
	db $08	; channel mask
	dw Sfx66_Ch4
Sfx66_Ch4:
	snd_len 5
	snd_off
	snd_noise 11, $F1, $4F
	snd_len 5
	snd_off
	snd_end
Sfx67:
	db $08	; channel mask
	dw Sfx67_Ch4
Sfx67_Ch4:
	snd_len 5
	snd_off
	snd_noise 2, $F0, $69
	snd_noise 3, $F1, $6A
	snd_noise 3, $F1, $6D
	snd_noise 21, $F5, $6F
	snd_len 5
	snd_off
	snd_end
Sfx68:
	db $08	; channel mask
	dw Sfx68_Ch4
Sfx68_Ch4:
	snd_loop 3
	snd_noise 1, $F0, $8F
	snd_noise 3, $F9, $4D
	snd_noise 3, $F0, $4E
	snd_noise 2, $F0, $5F
	snd_noise 5, $F9, $4D
	snd_noise 3, $F1, $4E
	snd_noise 2, $F0, $5F
	snd_noise 4, $F9, $7D
	snd_noise 3, $F3, $6F
	snd_endloop
	snd_end
Sfx69:
	db $0B	; channel mask
	dw Sfx69_Ch1, Sfx69_Ch2, Sfx69_Ch4
Sfx69_Ch1:
	snd_duty $00
	snd_env $F5
	snd_pitchenv SndPitchEnv_4977
	snd_note Fs_2, 60
	snd_note Gs_2
	snd_end
Sfx69_Ch2:
	snd_duty $C0
	snd_env $F5
	snd_octenv SndOctEnv_4B06
	snd_note G_2, 50
	snd_note E_2
	snd_end
Sfx69_Ch4:
	snd_noise 2, $F0, $46
	snd_noise 2, $F0, $48
	snd_noise 21, $F0, $44
	snd_noise 2, $F0, $46
	snd_noise 2, $F0, $48
	snd_noise 37, $F0, $46
	snd_noise 37, $F0, $45
	snd_noise 37, $F3, $44
	snd_end
Sfx6A:
	db $08	; channel mask
	dw Sfx6A_Ch4
Sfx6A_Ch4:
	snd_noise 16, $F0, $4A
	snd_len 20
	snd_off
	snd_end
Sfx6B:
	db $03	; channel mask
	dw Sfx6B_Ch1, Sfx6B_Ch2
Sfx6B_Ch1:
	snd_duty $80
	snd_env $B0
	snd_note G_5, 2
	snd_note G_5
	snd_off
	snd_off
	snd_note G_5
	snd_off
	snd_note G_5
	snd_off
	snd_env $B7
	snd_note G_5, 24
	snd_end
Sfx6B_Ch2:
	snd_duty $80
	snd_env $B0
	snd_note E_5, 2
	snd_note E_5
	snd_off
	snd_off
	snd_note E_5
	snd_off
	snd_note E_5
	snd_off
	snd_env $B7
	snd_note E_5, 24
	snd_end
Sfx6C:
	db $01	; channel mask
	dw Sfx6C_Ch1
Sfx6C_Ch1:
	snd_duty $00
	snd_env $A0
	snd_note C_4, 1
	snd_note C_5
	snd_note C_6
	snd_note Fs_6
	snd_note C_7
	snd_note Ds_7
	snd_note F_7
	snd_note Fs_7
	snd_note G_7
	snd_note Fs_7
	snd_note F_7
	snd_note Fs_7
	snd_env $80
	snd_note Fs_7
	snd_env $60
	snd_note Fs_7
	snd_end
Sfx6D:
	db $03	; channel mask
	dw Sfx6D_Ch1, Sfx6D_Ch2
Sfx6D_Ch1:
	snd_duty $00
	snd_env $C0
	snd_note A_3, 6
	snd_note Gs_3
	snd_note F_3
	snd_note Ds_3
	snd_note E_3, 16
	snd_end
Sfx6D_Ch2:
	snd_duty $C0
	snd_env $A0
	snd_len 2
	snd_off
	snd_note A_4, 6
	snd_note Gs_4
	snd_note F_4
	snd_note Ds_4
	snd_note E_4, 16
	snd_end
Sfx6E:
	db $01	; channel mask
	dw Sfx6E_Ch1
Sfx6E_Ch1:
	snd_duty $80
	snd_env $72
	snd_note G_4, 1
	snd_len 2
	snd_pitchenv SndPitchEnv_4A74
	snd_note G_5
	snd_end
Sfx6F:
	db $01	; channel mask
	dw Sfx6F_Ch1
Sfx6F_Ch1:
	snd_duty $80
	snd_env $D4
	snd_note C_5, 1
	snd_env $A4
	snd_len 5
	snd_pitchenv SndPitchEnv_4A36
	snd_note C_6
	snd_end
Sfx70:
	db $01	; channel mask
	dw Sfx70_Ch1
Sfx70_Ch1:
	snd_duty $80
	snd_env $F1
	snd_octenv SndOctEnv_4AD8
	snd_note E_6, 2
	snd_env $F1
	snd_pitchenv SndPitchEnv_4ABD
	snd_note E_6, 10
	snd_end
Sfx71:
	db $01	; channel mask
	dw Sfx71_Ch1
Sfx71_Ch1:
	snd_duty $40
	snd_env $C4
	snd_len 5
	snd_off
	snd_note E_4
	snd_note F_4
	snd_note A_4
	snd_note B_4
	snd_note D_5
	snd_note E_5, 20
	snd_end
Sfx72:
	db $08	; channel mask
	dw Sfx72_Ch4
Sfx72_Ch4:
	snd_noise 13, $F0, $49
	snd_end
Sfx73:
	db $03	; channel mask
	dw Sfx73_Ch1, Sfx73_Ch2
Sfx73_Ch1:
	snd_duty $80
	snd_env $C1
	snd_note E_6, 3
	snd_note G_6
	snd_note E_6
	snd_note G_6, 10
	snd_end
Sfx73_Ch2:
	snd_duty $40
	snd_env $C1
	snd_note E_6, 3
	snd_note G_6
	snd_note E_6
	snd_note G_6, 10
	snd_end
Sfx74:
	db $03	; channel mask
	dw Sfx74_Ch1, Sfx74_Ch2
Sfx74_Ch1:
	snd_duty $40
	snd_env $C1
	snd_note E_6, 3
	snd_note C_6
	snd_note E_6
	snd_note C_6, 10
	snd_end
Sfx74_Ch2:
	snd_duty $00
	snd_env $C1
	snd_note E_6, 3
	snd_note C_6
	snd_note E_6
	snd_note C_6, 10
	snd_end
Sfx75:
	db $03	; channel mask
	dw Sfx75_Ch1, Sfx75_Ch2
Sfx75_Ch1:
	snd_duty $80
	snd_env $C1
	snd_note E_6, 3
	snd_note G_6
	snd_note A_6, 10
	snd_end
Sfx75_Ch2:
	snd_duty $40
	snd_env $C1
	snd_note E_6, 3
	snd_note G_6
	snd_note A_6, 10
	snd_end
Sfx76:
	db $03	; channel mask
	dw Sfx76_Ch1, Sfx76_Ch2
Sfx76_Ch1:
	snd_duty $40
	snd_env $C1
	snd_note G_6, 3
	snd_note E_6
	snd_note D_6, 8
	snd_end
Sfx76_Ch2:
	snd_duty $00
	snd_env $C1
	snd_note G_6, 3
	snd_note E_6
	snd_note D_6, 8
	snd_end
Sfx77:
	db $03	; channel mask
	dw Sfx77_Ch1, Sfx77_Ch2
Sfx77_Ch1:
	snd_duty $80
	snd_env $C1
	snd_note E_6, 3
	snd_note G_6, 8
	snd_end
Sfx77_Ch2:
	snd_duty $40
	snd_env $C1
	snd_note E_6, 3
	snd_note G_6, 8
	snd_end
Sfx78:
	db $03	; channel mask
	dw Sfx78_Ch1, Sfx78_Ch2
Sfx78_Ch1:
	snd_duty $80
	snd_env $C1
	snd_note G_6, 3
	snd_note E_6, 8
	snd_end
Sfx78_Ch2:
	snd_duty $00
	snd_env $C1
	snd_note G_6, 3
	snd_note E_6, 8
	snd_end
Sfx79:
	db $01	; channel mask
	dw Sfx79_Ch1
Sfx79_Ch1:
	snd_duty $80
	snd_env $E9
	snd_octenv SndOctEnv_4B06
	snd_loop 5
	snd_note A_2, 3
	snd_note Fs_2, 1
	snd_note As_3
	snd_note E_3
	snd_note Fs_3
	snd_note Gs_3
	snd_note B_3
	snd_note E_4
	snd_note C_4
	snd_note Fs_4
	snd_note Cs_4
	snd_note A_4
	snd_note Cs_4
	snd_note C_4
	snd_note As_4
	snd_note Cs_4
	snd_note Gs_4
	snd_note Ds_4
	snd_endloop
	snd_note A_2, 3
	snd_note Fs_2, 1
	snd_note Gs_3
	snd_note Cs_3
	snd_note E_3
	snd_note Fs_3
	snd_note As_3
	snd_note C_4
	snd_note Gs_3
	snd_note Ds_4
	snd_note A_3
	snd_note E_4
	snd_note A_3
	snd_note Gs_3
	snd_note D_4
	snd_note A_3
	snd_note C_4
	snd_note Gs_3
	snd_note As_3, 2
	snd_note F_3, 1
	snd_note G_3
	snd_end
Sfx7A:
	db $01	; channel mask
	dw Sfx7A_Ch1
Sfx7A_Ch1:
	snd_duty $80
	snd_env $4B
	snd_pitchenv SndPitchEnv_4959
	snd_note A_6, 12
	snd_env $0B
	snd_pitchenv SndPitchEnv_4ABD
	snd_note A_6, 15
	snd_pitchenv SndPitchEnv_4AB9
	snd_note G_5, 19
	snd_pitchenv SndPitchEnv_4ABD
	snd_note E_6, 25
	snd_pitchenv SndPitchEnv_4959
	snd_note G_5, 10
	snd_duty $00
	snd_env $3A
	snd_note F_5, 6
	snd_note Ds_5
	snd_note C_5
	snd_note A_4
	snd_end
Sfx7B:
	db $08	; channel mask
	dw Sfx7B_Ch4
Sfx7B_Ch4:
	snd_noise 1, $A0, $88
	snd_noise 2, $A9, $8E
	snd_noise 3, $D0, $4D
	snd_end
Sfx7C:
	db $08	; channel mask
	dw Sfx7C_Ch4
Sfx7C_Ch4:
	snd_noise 1, $A0, $88
	snd_noise 1, $A9, $8E
	snd_noise 3, $D0, $8E
	snd_noise 3, $D0, $7E
	snd_noise 3, $D0, $6E
	snd_noise 3, $D0, $5E
	snd_noise 3, $D0, $4E
	snd_noise 3, $D0, $3E
	snd_loop 3
	snd_noise 26, $E9, $22
	snd_endloop
	snd_end
Sfx7D:
	db $08	; channel mask
	dw Sfx7D_Ch4
Sfx7D_Ch4:
	snd_noise 56, $2B, $52
	snd_noise 101, $D7, $52
	snd_end
Sfx7E:
	db $01	; channel mask
	dw Sfx7E_Ch1
Sfx7E_Ch1:
	snd_duty $00
	snd_len 1
	snd_env $90
	snd_transpose $E4
	snd_off
	snd_off
	snd_off
	snd_off
	snd_off
	snd_note E_6
	snd_off
	snd_note F_6
	snd_off
	snd_note G_6
	snd_off
	snd_note A_6
	snd_off
	snd_note B_6
	snd_off
	snd_note E_6
	snd_note F_6
	snd_note G_6
	snd_note A_6
	snd_note B_6
	snd_note G_6
	snd_off
	snd_note A_6
	snd_off
	snd_note B_6
	snd_off
	snd_note C_7
	snd_off
	snd_note D_7
	snd_off
	snd_note G_6
	snd_note A_6
	snd_note B_6
	snd_note C_7
	snd_note D_7
	snd_end
Sfx7F:
	db $0F	; channel mask
	dw Sfx7F_Ch1, Sfx7F_Ch2, Sfx7F_Ch3, Sfx7F_Ch4
Sfx7F_Ch1:
	snd_duty $40
	snd_env $80
	snd_loop 4
	snd_note A_3, 3
	snd_note D_4
	snd_note Fs_4
	snd_note A_4
	snd_note B_4
	snd_note D_5
	snd_note Fs_5
	snd_note A_5
	snd_note B_5
	snd_note A_5
	snd_note Fs_5
	snd_note D_5
	snd_note B_4
	snd_note A_4
	snd_note Fs_4
	snd_note D_4
	snd_endloop
	snd_len 10
	snd_off
	snd_end
Sfx7F_Ch2:
	snd_duty $80
	snd_env $90
	snd_loop 2
	snd_note A_7, 3
	snd_note A_5
	snd_note A_6
	snd_note D_6
	snd_note A_7
	snd_note Fs_6
	snd_note A_6
	snd_note D_7
	snd_note B_7
	snd_note D_7
	snd_note B_6
	snd_note Fs_6
	snd_note Fs_7
	snd_note D_6
	snd_note Fs_6
	snd_note A_5
	snd_note B_7
	snd_note A_5
	snd_note B_6
	snd_note D_6
	snd_note Fs_6
	snd_note A_6
	snd_note B_6
	snd_note D_7
	snd_note A_7
	snd_note D_7
	snd_note A_6
	snd_note Fs_6
	snd_note Fs_7
	snd_note D_6
	snd_note B_5
	snd_note A_5
	snd_endloop
	snd_len 10
	snd_off
	snd_end
Sfx7F_Ch3:
	snd_wave SndWave07
	snd_env2 $20
	snd_loop 4
	snd_note D_3, 6
	snd_note B_3, 3
	snd_note D_4
	snd_note Fs_4
	snd_note A_4
	snd_note B_4
	snd_note D_5
	snd_note Fs_5
	snd_note D_5
	snd_note B_4
	snd_note A_4
	snd_note Fs_4
	snd_note D_4
	snd_note B_3
	snd_note A_3
	snd_endloop
	snd_len 10
	snd_off
	snd_end
Sfx7F_Ch4:
	snd_loop 2
	snd_len 12
	snd_drum 4
	snd_len 6
	snd_drum 3
	snd_drum 3
	snd_len 24
	snd_drum 9
	snd_drum 11
	snd_drum 11
	snd_endloop
	snd_end
