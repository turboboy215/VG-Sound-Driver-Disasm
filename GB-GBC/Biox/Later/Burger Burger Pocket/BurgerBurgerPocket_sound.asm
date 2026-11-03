; Burger Burger Pocket (J) - sound driver B v1, bank $02 $4000-$659F
; Biox. Disassembled for GBAudioLab\Biox.
; Bank-0 helpers used: rst $18 = a = [hl+a] (and a), rst $20 = hl = [hl+2a], rst $00 = inline jump table

DEF BIOXB_VER EQU 1
INCLUDE "hardware.inc"
INCLUDE "bioxB_sound.inc"

; ---- RAM ----
DEF wSndMus1        EQU $C001
DEF wSndMus2        EQU $C019
DEF wSndMus3        EQU $C031
DEF wSndMus4        EQU $C049
DEF wSndSfx1        EQU $C061
DEF wSndSfx2        EQU $C079
DEF wSndSfx3        EQU $C091
DEF wSndSfx4        EQU $C0A9
DEF wSndQueue       EQU $C0C1
DEF wSndQueuePtr    EQU $C0C9
DEF wSndQueueCount  EQU $C0CB
DEF wSndNRx1        EQU $C0CC
DEF wSndChanIdx     EQU $C0CD
DEF wSndFadeMode    EQU $C0CE
DEF wSndFadeUnused  EQU $C0CF
DEF wSndFadeTimer   EQU $C0D0
DEF hSndPause       EQU $FFBA
DEF hSndCurMusic    EQU $FFD0
DEF hSndCurSfx      EQU $FFD1
DEF hSndTempo       EQU $FFD2
DEF hSndTempoStep   EQU $FFD3
DEF hSndTempoAcc    EQU $FFD5
DEF hSndTicks       EQU $FFD7
DEF hSndFlags       EQU $FFD8
DEF hSndPtr         EQU $FFD9
DEF hSndCount       EQU $FFDB
DEF hSndLength      EQU $FFDC
DEF hSndLoopCount   EQU $FFDD
DEF hSndLoopPtr     EQU $FFDE
DEF hSndRetPtr      EQU $FFE0
DEF hSndUnusedE2    EQU $FFE2
DEF hSndPEnvPtr     EQU $FFE8
DEF hSndFreq        EQU $FFEA
DEF hSndEnv         EQU $FFEC
DEF hSndDuty        EQU $FFED
DEF hSndTranspose   EQU $FFEE
DEF hSndUnusedEF    EQU $FFEF


SECTION "Sound Driver B (Burger Burger Pocket)", ROMX[$4000], BANK[$2]

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
	ld a,$FF
	ld [wSndFadeMode],a
	ld a,$C1
	ld [wSndQueuePtr],a
	ld a,$C0
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
	jr nz,Snd_4097
	call Snd_UpdateMusic
	call Snd_Fade
	jr c,Snd_409A
Snd_4097:
	call Snd_ProcessQueue
Snd_409A:
	call Snd_UpdateSfx
	ld hl,wSndSfx1
	ld c,$D1
	call Snd_CheckSetActive
	ld hl,wSndMus1
	ld c,$D0
Snd_CheckSetActive:
	ld de,$0018
	ld b,$04
	xor a
Snd_40B0:
	or [hl]
	add hl,de
	dec b
	jr nz,Snd_40B0
	and $80
	ret nz
	ld a,$FF
	ldh [c],a
	ret
Snd_UpdateSfx:
	ldh a,[hSndCurSfx]
	and $80
	ret nz
	call Snd_40DF
	call Snd_40D8
	call Snd_40D1
	ld hl,wSndSfx4
	ld a,$07
	jr Snd_UpdateSfxChan
Snd_40D1:
	ld hl,wSndSfx3
	ld a,$06
	jr Snd_UpdateSfxChan
Snd_40D8:
	ld hl,wSndSfx2
	ld a,$05
	jr Snd_UpdateSfxChan
Snd_40DF:
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
	call Snd_4134
	call Snd_412A
	call Snd_4120
	ld hl,wSndMus4
	ld de,wSndSfx4
	ld b,$03
	jr Snd_UpdateMusicChan
Snd_4120:
	ld hl,wSndMus3
	ld de,wSndSfx3
	ld b,$02
	jr Snd_UpdateMusicChan
Snd_412A:
	ld hl,wSndMus2
	ld de,wSndSfx2
	ld b,$01
	jr Snd_UpdateMusicChan
Snd_4134:
	ld hl,wSndMus1
	ld de,wSndSfx1
	ld b,$00
Snd_UpdateMusicChan:
	bit 7,[hl]
	ret z
	ld a,[de]
	bit 7,a
	jr z,Snd_4148
	set 3,[hl]
	jr Snd_414A
Snd_4148:
	res 3,[hl]
Snd_414A:
	ld a,b
	call Snd_LoadChan
	ldh a,[hSndTicks]
	ld b,a
Snd_4151:
	push bc
	call Snd_Tick
	pop bc
	dec b
	jr nz,Snd_4151
	jp Snd_SaveChan
Snd_LoadChan:
	ld [wSndChanIdx],a
	ld hl,SndChanPtrTable
	rst $20
	ld c,$D8
	ld b,$18
Snd_4167:
	ld a,[hli]
	ldh [c],a
	inc c
	dec b
	jr nz,Snd_4167
	ld a,[wSndChanIdx]
	and $03
	ld hl,SndNRx1Table
	rst $18
	ld [wSndNRx1],a
	ret
SndNRx1Table:
	db $11, $16, $1B, $20
Snd_SaveChan:
	ld a,[wSndChanIdx]
	ld hl,SndChanPtrTable
	rst $20
	ld c,$D8
	ld b,$18
Snd_4189:
	ldh a,[c]
	inc c
	ld [hli],a
	dec b
	jr nz,Snd_4189
	ret
SndChanPtrTable:
	dw $C001, $C019, $C031, $C049
	dw $C061, $C079, $C091, $C0A9
Snd_Tick:
	call Snd_PitchEnvStep
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
	cp $32
	jp c,Snd_SetLength
	cp $90
	jp c,Snd_Note
	cp $ED
	jp c,Snd_Drum
	jp z,SndCmd_Noise
	cp $EF
	jp z,SndCmd_Off
	cp $EE
	jp z,SndCmd_Rest
	jp Snd_Command
SndCmd_Off:
	call Snd_SilenceChan
	jp Snd_RowDone
Snd_SilenceChan:
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
	sub $90
	ld hl,SndDrumFreqTable
	rst $18
	ld c,a
	ld a,b
	sub $90
	ld hl,SndDrumEnvTable
	rst $18
	ldh [hSndEnv],a
	ld l,c
	ld h,$00
	jp Snd_NoteOut
Snd_Note:
	sub $32
	ld hl,hSndTranspose
	add a,[hl]
	ld hl,SndFreqTable
	rst $20
Snd_NoteOut:
	ldh a,[hSndFlags]
	bit 3,a
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
	jr nz,Snd_427E
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
	or $C0
	inc c
	ldh [c],a
	jr Snd_RowDone
Snd_427E:
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
	sub $F0
	rst $00
SndCommandTable:
	dw SndCmd_End, SndCmd_Jump, SndCmd_Call, SndCmd_Ret
	dw SndCmd_Loop, SndCmd_EndLoop, SndCmd_Tempo, SndCmd_Env
	dw SndCmd_PitchEnv, SndCmd_Nop, SndCmd_Duty, SndCmd_Pan
	dw SndCmd_Transpose
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
	jr z,Snd_42FE
	ldh a,[hSndLoopPtr]
	ld e,a
	ldh a,[hSndLoopPtr+1]
	ld d,a
Snd_42FE:
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
	set 4,[hl]
	ld a,[de]
	inc de
	ldh [hSndPEnvPtr],a
	ld a,[de]
	inc de
	ldh [hSndPEnvPtr+1],a
	jp Snd_ParseLoop
SndCmd_Nop:
	jp Snd_ParseLoop
SndCmd_Duty:
	ldh a,[hSndFlags]
	bit 3,a
	jr z,Snd_4336
	ld a,[de]
	jr Snd_433C
Snd_4336:
	ld a,[wSndNRx1]
	ld c,a
	ld a,[de]
	ldh [c],a
Snd_433C:
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
Snd_PitchEnvStep:
	ldh a,[hSndFlags]
	bit 4,a
	ret z
	ldh a,[hSndPEnvPtr]
	ld e,a
	ldh a,[hSndPEnvPtr+1]
	ld d,a
Snd_435B:
	ld a,[de]
	inc de
	cp $80
	jr nz,Snd_4367
	ld hl,hSndFlags
	res 4,[hl]
	ret
Snd_4367:
	cp $81
	jr nz,Snd_4373
	ld a,[de]
	inc de
	ld c,a
	ld a,[de]
	ld d,a
	ld e,c
	jr Snd_435B
Snd_4373:
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
	jr z,Snd_4387
	dec b
Snd_4387:
	add hl,bc
	ld a,l
	ldh [hSndFreq],a
	ld a,h
	ldh [hSndFreq+1],a
	ldh a,[hSndFlags]
	bit 3,a
	ret nz
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
	ret
Snd_Fade:
	ld a,[wSndFadeMode]
	and $80
	ret nz
	ld a,[wSndFadeTimer]
	and a
	jr nz,Snd_43DA
	ld a,$0A
	ld [wSndFadeTimer],a
	ld a,[wSndFadeMode]
	and a
	ldh a,[rNR50]
	jr z,Snd_43CB
	and $77
	jr nz,Snd_43C5
	call SndSys_StopAll
	jr Snd_43D5
Snd_43C5:
	sub $11
	ldh [rNR50],a
	jr Snd_43DA
Snd_43CB:
	add a,$11
	and $77
	ldh [rNR50],a
	cp $77
	jr nz,Snd_43DA
Snd_43D5:
	ld a,$FF
	ld [wSndFadeMode],a
Snd_43DA:
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
Snd_43EE:
	dec hl
	push hl
	push bc
	call Snd_HandleRequest
	pop bc
	pop hl
	dec b
	jr nz,Snd_43EE
	ld a,l
	ld [wSndQueuePtr],a
	ld a,h
	ld [wSndQueuePtr+1],a
	xor a
	ld [wSndQueueCount],a
	ret
Snd_HandleRequest:
	ld a,[hl]
	bit 7,a
	jp z,Snd_StartMusic
	bit 6,a
	jp z,Snd_4416
	cp $C0
	jp nc,Snd_SysCommand
Snd_4416:
	and $3F
	ld c,a
	ldh a,[hSndCurSfx]
	bit 7,a
	jr nz,Snd_StartSfx
	ld hl,SndSfxPriority
	rst $18
	ld b,a
	ld a,c
	ld hl,SndSfxPriority
	rst $18
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
	ld [wSndSfx1+$16],a
	ld [wSndSfx2+$16],a
	ld [wSndSfx3+$16],a
	ld [wSndSfx4+$16],a
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
Snd_StartMusic:
	ldh [hSndCurMusic],a
	ld c,a
	call Snd_Off
	call Snd_SetMusicFlags
	xor a
	ld [wSndMus1+$03],a
	ld [wSndMus2+$03],a
	ld [wSndMus3+$03],a
	ld [wSndMus4+$03],a
	ld [wSndMus1+$16],a
	ld [wSndMus2+$16],a
	ld [wSndMus3+$16],a
	ld [wSndMus4+$16],a
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
	ld bc,$1030
Snd_44D8:
	ld a,[hli]
	ldh [c],a
	inc c
	dec b
	jr nz,Snd_44D8
	jp Snd_ResetRegs
Snd_SetMusicFlags:
	ld [wSndMus1],a
	ld [wSndMus2],a
	ld [wSndMus3],a
	ld [wSndMus4],a
	ret
Snd_SetPointers:
	ld a,c
	ld b,$04
Snd_44F1:
	rra
	push af
	jr nc,Snd_44FB
	ld a,[hli]
	ld [de],a
	inc de
	ld a,[hli]
	ld [de],a
	dec de
Snd_44FB:
	push hl
	ld hl,$0018
	add hl,de
	ld e,l
	ld d,h
	pop hl
	pop af
	dec b
	jr nz,Snd_44F1
	ret
Snd_SetActive:
	ld de,$0018
	ld b,$04
	ld a,c
Snd_450E:
	rra
	jr nc,Snd_4513
	set 7,[hl]
Snd_4513:
	add hl,de
	dec b
	jr nz,Snd_450E
	ret
Snd_SysCommand:
	sub $C0
	rst $00
SndSysCmdTable:
	dw SndSys_StopAll, SndSys_StopMusic, SndSys_StopSfx, SndSys_FadeIn
	dw SndSys_FadeOut, SndSys_VolLow, SndSys_VolFull, SndSys_SilenceAll
SndSys_StopAll:
	call Snd_ClearSfx
	call Snd_SetMusicFlags
	ld a,$FF
	ldh [hSndCurMusic],a
	ldh [hSndCurSfx],a
	jp Snd_Off
SndSys_StopMusic:
	call Snd_SetMusicFlags
	ld a,$FF
	ldh [hSndCurMusic],a
	jp Snd_Off
Snd_Unused4544:
	ret
SndSys_StopSfx:
	call Snd_ClearSfx
	ld a,$FF
	ldh [hSndCurSfx],a
	jp Snd_Off
SndSys_FadeIn:
	xor a
	ldh [rNR50],a
Snd_4552:
	ld [wSndFadeMode],a
	xor a
	ld [wSndFadeUnused],a
	ld a,$0A
	ld [wSndFadeTimer],a
	ret
SndSys_FadeOut:
	ld a,$01
	jr Snd_4552
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
	srl h
	rr l
	ret
Snd_Div16x8:
	xor a
	ld b,$10
Snd_4589:
	sla e
	rl d
	rla
	jr c,Snd_459D
	sub c
	jr nc,Snd_4594
	add a,c
Snd_4594:
	ccf
Snd_4595:
	rl l
	rl h
	dec b
	jr nz,Snd_4589
	ret
Snd_459D:
	sub c
	scf
	jp Snd_4595
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
SndDrumFreqTable:
	db $01, $01, $79, $89, $50, $6D
SndDrumEnvTable:
	db $61, $75, $61, $61, $71, $51
SndMusicWaveTable:
	dw SndWave00, SndWave06, SndWave00, SndWave06
	dw SndWave02, SndWave06, SndWave05, SndWave05
	dw SndWave05, SndWave05, SndWave05, SndWave05
	dw SndWave05, SndWave05, SndWave05, SndWave05
	dw SndWave05, SndWave05, SndWave05
SndWave00:
	db $00, $55, $AA, $FF, $00, $55, $AA, $FF, $00, $55, $AA, $FF, $00, $55, $AA, $FF
SndWave01:
	db $00, $55, $AA, $FF, $AA, $55, $00, $55, $AA, $FF, $AA, $55, $00, $55, $AA, $FF
SndWave02:
	db $00, $22, $44, $66, $88, $AA, $CC, $EE, $FF, $DD, $BB, $99, $77, $55, $33, $11
SndWave03:
	db $00, $ED, $FE, $C6, $00, $F5, $F3, $D5, $00, $F5, $FB, $D7, $00, $F5, $03, $C9
SndWave04:
	db $80, $FF, $FF, $FF, $80, $00, $00, $00, $80, $FF, $FF, $FF, $80, $00, $00, $00
SndWave05:
	db $80, $80, $FF, $FF, $80, $80, $FF, $FF, $80, $80, $FF, $FF, $80, $80, $FF, $FF
SndWave06:
	db $FE, $BA, $76, $32, $23, $67, $AB, $EF, $FE, $BA, $76, $32, $23, $67, $AB, $EF
SndWave07:
	db $08, $40, $08, $80, $08, $C0, $08, $FF, $08, $40, $08, $80, $08, $C0, $08, $FF
SndWave08:
	db $F6, $46, $F6, $26, $F6, $46, $F6, $26, $F6, $46, $F6, $26, $F6, $46, $F6, $26
SndWave09:
	db $20, $40, $60, $80, $A0, $C0, $E0, $FF, $FF, $E0, $C0, $A0, $80, $60, $40, $20
SndWave0A:
	db $80, $60, $A0, $40, $C0, $20, $E0, $00, $FF, $20, $E0, $40, $C0, $60, $A0, $80
SndWave0B:
	db $FF, $00, $EE, $00, $DD, $00, $CC, $00, $BB, $00, $AA, $00, $88, $00, $77, $00
SndWave0C:
	db $80, $90, $70, $A0, $60, $B0, $C0, $50, $D0, $40, $E0, $30, $F0, $20, $FF, $10
SndPitchEnv_4766:
	db 0, 0, 0, 0, 0, 0
SndEnv_476C:
	db -1, 1, -1, 1
	env_jump SndEnv_476C
SndEnvUnused_4773:
	db 0, 0, 0, 0, 0, 0, 0
SndEnv_477A:
	db 1, 0, -1, -1, 0, 1
	env_jump SndEnv_477A
SndEnvUnused_4783:
	db 0, 0, 0, 0
SndEnv_4787:
	db -1, -1, 1, 1, 1, 1, -1, -1
	env_jump SndEnv_4787
SndEnvUnused_4792:
	db 0, 0
SndEnv_4794:
	db -4, -3, 3, 4, 3, -3
	env_jump SndEnv_4794
SndEnvUnused_479D:
	db 5, 4, -4, -5, -4, 4
	env_jump SndEnvUnused_479D
SndPitchEnv_47A6:
	db 0, 1, 0, -1, 0, -1, 0, 1
	env_jump SndPitchEnv_47A6
SndEnvUnused_47B1:
	db -3, -2, -1, 0, 0, 1, 2, 3, -3, -2, -1, 0, 0, 1, 2, 3
	env_jump SndEnvUnused_47B1
SndPitchEnv_47C4:
	db 0, 0, 0, 0, 0, 0, 0, 0
	env_jump SndPitchEnv_47C4
SndEnvUnused_47CF:
	db -4, 4, 4, -4
	env_jump SndEnvUnused_47CF
SndEnvUnused_47D6:
	db -3, 3, 3, -3
	env_jump SndEnvUnused_47D6
SndEnvUnused_47DD:
	db 0, -1, 0, 1
	env_jump SndEnvUnused_47DD
SndEnvUnused_47E4:
	db -1, 1, -1, 1
	env_jump SndEnvUnused_47E4
SndEnvUnused_47EB:
	db 1, -1, 1, -1
	env_jump SndEnvUnused_47EB
SndEnvUnused_47F2:
	db 0, 0, 0, 0, 0, 0, 0, 0, 0
SndEnv_47FB:
	db 2, -2, 2, -2
	env_jump SndEnv_47FB
SndEnvUnused_4802:
	db 0, 0, 0, 0, 0, 0
	env_jump SndEnvUnused_4802
SndEnvUnused_480B:
	env_stop
SndMusicTable:
	dw Mus00, Mus01, Mus02, Mus03
	dw Mus04, Mus05, Mus06, Mus07
	dw Mus08, Mus09, Mus0A, Mus0B
	dw Mus0C, Mus0D, Mus0E, Mus0F
	dw Mus10, Mus11, Mus12
SndSfxPriority:
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00	; SFX $80-$8F
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00	; SFX $90-$9F
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00	; SFX $A0-$AF
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00	; SFX $B0-$BF
	db $00, $00, $00, $00, $00, $00, $00, $00	; SFX $C0-$C7
SndSfxTable:
	dw Sfx80, Sfx81, Sfx82, Sfx83, Sfx84, Sfx85, Sfx86, Sfx87
	dw Sfx88, Sfx89, Sfx8A, Sfx8B, Sfx8C, Sfx8D, Sfx8E, Sfx8F
	dw Sfx90, Sfx91, Sfx92, Sfx93, Sfx94, Sfx95, Sfx96, Sfx97
	dw Sfx98, Sfx99, Sfx9A, Sfx9B, Sfx9C, Sfx9D, Sfx9E, Sfx9F
	dw SfxA0, SfxA1, SfxA2, SfxA3, SfxA4, SfxA5, SfxA6, SfxA7
	dw SfxA8, SfxA9, SfxAA, SfxAB, SfxAC, SfxAD, SfxAE, SfxAF
	dw SfxB0, SfxB1, SfxB2, SfxB3
SndNullTrack:
	snd_end
Sfx80:
	db $02	; channel mask
	dw Sfx80_Ch2
Sfx80_Ch2:
	snd_duty $80
	snd_len 1
	snd_env $80
	snd_note E_4
	snd_env $C0
	snd_note E_6
	snd_env $80
	snd_note F_6
	snd_env $40
	snd_note Fs_6
	snd_end
Sfx81:
	db $02	; channel mask
	dw Sfx81_Ch2
Sfx81_Ch2:
	snd_duty $80
	snd_env $C1
	snd_note G_6, 6
	snd_note E_6
	snd_note G_6
	snd_note E_6, 18
	snd_end
Sfx82:
	db $02	; channel mask
	dw Sfx82_Ch2
Sfx82_Ch2:
	snd_duty $80
	snd_env $51
	snd_note Ds_6, 1
	snd_note E_6
	snd_note F_6
	snd_note G_6
	snd_note A_6
	snd_note B_6
	snd_end
Sfx83:
	db $02	; channel mask
	dw Sfx83_Ch2
Sfx83_Ch2:
	snd_duty $80
	snd_len 1
	snd_env $82
	snd_note E_5
	snd_note F_5
	snd_note Fs_5
	snd_note E_7, 32
	snd_end
Sfx84:
	db $02	; channel mask
	dw Sfx84_Ch2
Sfx84_Ch2:
	snd_env $A0
	snd_note F_6, 2
	snd_note B_5
	snd_off
	snd_env $80
	snd_note A_8
	snd_note D_7
	snd_end
Sfx85:
	db $02	; channel mask
	dw Sfx85_Ch2
Sfx85_Ch2:
	snd_duty $80
	snd_len 1
	snd_env $A0
	snd_note Fs_6
	snd_note D_6
	snd_note B_5
	snd_note A_5
	snd_note G_5
	snd_note F_5
	snd_note E_5
	snd_note Ds_5
	snd_note Ds_5
	snd_note E_5
	snd_note F_5
	snd_note G_5
	snd_note A_5
	snd_note B_5
	snd_note D_6
	snd_note Fs_6
	snd_env $80
	snd_note Fs_6
	snd_note D_6
	snd_note B_5
	snd_note A_5
	snd_note G_5
	snd_note F_5
	snd_note E_5
	snd_note Ds_5
	snd_note Ds_5
	snd_note E_5
	snd_note F_5
	snd_note G_5
	snd_note A_5
	snd_note B_5
	snd_note D_6
	snd_note Fs_6
	snd_end
Sfx86:
	db $02	; channel mask
	dw Sfx86_Ch2
Sfx86_Ch2:
	snd_duty $80
	snd_env $80
	snd_note Ds_6, 1
	snd_note D_6
	snd_note Cs_6
	snd_note C_6
	snd_note C_7
	snd_note Cs_7
	snd_end
Sfx87:
	db $02	; channel mask
	dw Sfx87_Ch2
Sfx87_Ch2:
	snd_duty $80
	snd_len 1
	snd_env $20
	snd_note G_2
	snd_note B_2
	snd_note D_3
	snd_env $40
	snd_note G_3
	snd_note B_3
	snd_note D_4
	snd_env $60
	snd_note G_4
	snd_note B_4
	snd_note D_5
	snd_env $80
	snd_note G_5
	snd_note B_5
	snd_note D_6
	snd_len 2
	snd_env $A0
	snd_note G_7
	snd_note D_7
	snd_note B_6
	snd_env $40
	snd_note G_7
	snd_note D_7
	snd_note B_6
	snd_end
Sfx93:
	db $02	; channel mask
	dw Sfx93_Ch2
Sfx93_Ch2:
	snd_duty $80
	snd_len 1
	snd_env $20
	snd_note C_7
	snd_note B_6
	snd_note As_6
	snd_note A_6
	snd_note Gs_6
	snd_note G_6
	snd_note Fs_6
	snd_note F_6
	snd_note E_6
	snd_note Ds_6
	snd_note D_6
	snd_note Cs_6
	snd_note C_6
	snd_note B_5
	snd_note As_5
	snd_note A_5
	snd_note Gs_5
	snd_note G_5
	snd_note Fs_5
	snd_note F_5
	snd_note E_5
	snd_note Ds_5
	snd_note D_5
	snd_note Cs_5
	snd_note C_5
	snd_note B_4
	snd_note As_4
	snd_note A_4
	snd_note Gs_4
	snd_note G_4
	snd_note Fs_4
	snd_note F_4
	snd_note E_4
	snd_note Ds_4
	snd_note D_4
	snd_note Cs_4
	snd_note C_4
	snd_note B_3
	snd_note As_3
	snd_note A_3
	snd_note Gs_3
	snd_note G_3
	snd_note Fs_3
	snd_note F_3
	snd_note E_3
	snd_note Ds_3
	snd_note D_3
	snd_note Cs_3
	snd_end
Sfx94:
	db $02	; channel mask
	dw Sfx94_Ch2
Sfx94_Ch2:
	snd_duty $80
	snd_len 3
	snd_env $40
	snd_note G_6
	snd_off
	snd_note E_6
	snd_off
	snd_env $30
	snd_note Cs_6
	snd_off
	snd_note As_5
	snd_off
	snd_env $20
	snd_note G_5
	snd_off
	snd_note E_5
	snd_off
	snd_env $10
	snd_note Cs_5
	snd_off
	snd_note As_4
	snd_off
	snd_end
Sfx95:
	db $02	; channel mask
	dw Sfx95_Ch2
Sfx95_Ch2:
	snd_duty $80
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
	snd_note Ds_6
	snd_note E_6
	snd_note D_6
	snd_note Ds_6
	snd_env $10
	snd_note Cs_6
	snd_note D_6
	snd_note C_6
	snd_note Cs_6
	snd_end
Sfx89:
	db $02	; channel mask
	dw Sfx89_Ch2
Sfx89_Ch2:
	snd_duty $80
	snd_len 8
	snd_env $81
	snd_note E_6
	snd_note G_5
	snd_note C_6
	snd_note E_6
	snd_len 24
	snd_env $83
	snd_note G_6
	snd_end
Sfx8A:
	db $02	; channel mask
	dw Sfx8A_Ch2
Sfx8A_Ch2:
	snd_duty $00
	snd_env $F1
	snd_note C_3, 6
	snd_off
	snd_env $F0
	snd_note C_3, 24
	snd_end
Sfx96:
	db $03	; channel mask
	dw Sfx87_Ch2, Sfx96_Ch2
Sfx96_Ch2:
	snd_len 1
	snd_off
	snd_jump Sfx93_Ch2
Sfx8B:
	db $02	; channel mask
	dw Sfx8B_Ch2
Sfx8B_Ch2:
	snd_duty $80
	snd_env $87
	snd_note E_5, 12
	snd_note A_5, 6
	snd_note Cs_6
	snd_note E_6, 12
	snd_end
Sfx8C:
	db $02	; channel mask
	dw Sfx8C_Ch2
Sfx8C_Ch2:
	snd_duty $80
	snd_env $87
	snd_note E_6, 6
	snd_note Ds_6
	snd_note D_6
	snd_note Cs_6
	snd_note C_6, 12
	snd_end
Sfx8D:
	db $02	; channel mask
	dw Sfx8D_Ch2
Sfx8D_Ch2:
	snd_duty $80
	snd_env $43
	snd_note Ds_5, 1
	snd_note D_5
	snd_note Cs_5
	snd_note C_5
	snd_env $80
	snd_note C_6
	snd_note Cs_6
	snd_note D_6
	snd_note Ds_6
	snd_note E_6
	snd_end
Sfx97:
	db $02	; channel mask
	dw Sfx97_Ch2
Sfx97_Ch2:
	snd_duty $80
	snd_env $A0
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
	snd_note B_7
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
	snd_note B_6
	snd_note As_6
	snd_note A_6
	snd_note Gs_6
	snd_note G_6
	snd_note Fs_6
	snd_note F_6
	snd_note E_6
	snd_note Ds_6
	snd_note D_6
	snd_note Cs_6
	snd_note C_6
	snd_end
Sfx8E:
	db $02	; channel mask
	dw Sfx8E_Ch2
Sfx8E_Ch2:
	snd_duty $80
	snd_env $A0
	snd_note C_6, 1
	snd_note Cs_6
	snd_note D_6
	snd_note Ds_6
	snd_note E_6
	snd_note F_6
	snd_note Fs_6
	snd_note G_6
	snd_note Gs_6
	snd_note A_6
	snd_note As_6
	snd_note B_6
	snd_end
Sfx8F:
	db $03	; channel mask
	dw Sfx8F_Ch1, Sfx8F_Ch2
Sfx8F_Ch1:
	snd_duty $80
	snd_env $C3
	snd_note G_6, 6
	snd_note E_6
	snd_note G_6
	snd_note E_6, 18
	snd_end
Sfx8F_Ch2:
	snd_len 1
	snd_off
	snd_jump Sfx8F_Ch1
Sfx98:
	db $02	; channel mask
	dw Sfx98_Ch2
Sfx98_Ch2:
	snd_duty $80
	snd_env $80
	snd_note G_6, 1
	snd_note Gs_6
	snd_note G_6
	snd_note Fs_6
	snd_note F_6
	snd_note E_6
	snd_note Ds_6
	snd_end
Sfx90:
	db $02	; channel mask
	dw Sfx90_Ch2
Sfx90_Ch2:
	snd_duty $80
	snd_env $E2
	snd_note B_6, 6
	snd_note G_6
	snd_env $42
	snd_note Ds_7, 12
	snd_end
Sfx99:
	db $02	; channel mask
	dw Sfx99_Ch2
Sfx99_Ch2:
	snd_duty $80
	snd_len 1
	snd_env $87
	snd_note Fs_6
	snd_note D_6
	snd_note B_5
	snd_note A_5
	snd_note G_5
	snd_note F_5
	snd_note E_5
	snd_note Ds_5
	snd_note Ds_5
	snd_note E_5
	snd_note F_5
	snd_note G_5
	snd_note A_5
	snd_note B_5
	snd_note D_6
	snd_note Fs_6
	snd_env $62
	snd_note Ds_6
	snd_note E_6
	snd_note F_6
	snd_note G_6
	snd_note A_6
	snd_note B_6
	snd_note D_7
	snd_note Fs_7
	snd_end
Sfx9A:
	db $02	; channel mask
	dw Sfx9A_Ch2
Sfx9A_Ch2:
	snd_duty $80
	snd_env $87
	snd_note Fs_6, 1
	snd_note D_6
	snd_note B_5
	snd_note A_5
	snd_note Fs_6
	snd_note D_6
	snd_note B_5
	snd_note A_5
	snd_note Fs_6
	snd_note D_6
	snd_note B_5
	snd_note A_5
	snd_note G_5
	snd_note F_5
	snd_note E_5
	snd_note Ds_5
	snd_env $61
	snd_note G_5
	snd_note F_5
	snd_note E_5
	snd_note Ds_5
	snd_end
Sfx9B:
	db $02	; channel mask
	dw Sfx9B_Ch2
Sfx9B_Ch2:
	snd_duty $80
	snd_env $87
	snd_note E_5, 1
	snd_note C_5
	snd_note G_4
	snd_note C_4
	snd_note E_5
	snd_note C_5
	snd_note G_4
	snd_note C_4
	snd_note C_4
	snd_note G_4
	snd_note C_5
	snd_note E_5
	snd_note G_5
	snd_note A_5
	snd_note As_5
	snd_note B_5
	snd_env $61
	snd_note C_4
	snd_note G_4
	snd_note C_5
	snd_note E_5
	snd_note G_5
	snd_note A_5
	snd_note As_5
	snd_note B_5
	snd_end
Sfx9C:
	db $02	; channel mask
	dw Sfx9C_Ch2
Sfx9C_Ch2:
	snd_duty $80
	snd_env $A0
	snd_note E_5, 1
	snd_note C_5
	snd_note G_4
	snd_note C_4
	snd_note E_5
	snd_note C_5
	snd_note G_4
	snd_note C_4
	snd_end
Sfx91:
	db $02	; channel mask
	dw Sfx91_Ch2
Sfx91_Ch2:
	snd_duty $80
	snd_env $80
	snd_len 2
	snd_env $A0
	snd_note B_3
	snd_note D_4
	snd_note F_4
	snd_note Gs_4
	snd_env $67
	snd_note B_3
	snd_note D_4
	snd_note F_4
	snd_note Gs_4
	snd_end
Sfx9D:
	db $02	; channel mask
	dw Sfx9D_Ch2
Sfx9D_Ch2:
	snd_duty $80
	snd_len 2
	snd_env $87
	snd_note E_6
	snd_note F_6
	snd_env $10
	snd_note E_7
	snd_note F_7
	snd_note Fs_7
	snd_note G_7
	snd_note Gs_7
	snd_note A_7
	snd_note As_7
	snd_note B_7
	snd_len 12
	snd_off
	snd_end
Sfx92:
	db $02	; channel mask
	dw Sfx92_Ch2
Sfx92_Ch2:
	snd_duty $80
	snd_len 1
	snd_env $A0
	snd_note E_6
	snd_note F_6
	snd_note G_6
	snd_note A_6
	snd_note B_6
	snd_env $80
	snd_note G_6
	snd_note A_6
	snd_note B_6
	snd_note C_7
	snd_note D_7
	snd_env $60
	snd_note B_6
	snd_note C_7
	snd_note D_7
	snd_note E_7
	snd_note F_7
	snd_note G_7
	snd_note A_7
	snd_note B_7
	snd_note C_8
	snd_len 6
	snd_off
	snd_off
	snd_off
	snd_end
Sfx9E:
	db $02	; channel mask
	dw Sfx9E_Ch2
Sfx9E_Ch2:
	snd_duty $80
	snd_env $40
	snd_note G_6, 3
	snd_off
	snd_note E_6
	snd_off
	snd_note C_6
	snd_off
	snd_note A_5
	snd_off
	snd_note G_5
	snd_off
	snd_end
Sfx9F:
	db $02	; channel mask
	dw Sfx9F_Ch2
Sfx9F_Ch2:
	snd_duty $80
	snd_env $80
	snd_note F_5, 3
	snd_note D_6
	snd_note As_5
	snd_note D_6
	snd_note F_6
	snd_end
SfxA0:
	db $02	; channel mask
	dw SfxA0_Ch2
SfxA0_Ch2:
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
	snd_note Ds_6
	snd_note E_6
	snd_note F_6
	snd_note Fs_6
	snd_end
SfxA1:
	db $02	; channel mask
	dw SfxA1_Ch2
SfxA1_Ch2:
	snd_duty $80
	snd_env $A0
	snd_note E_5, 1
	snd_note C_5
	snd_note G_4
	snd_note C_4
	snd_note E_5
	snd_note C_5
	snd_note G_4
	snd_note C_4
	snd_note C_4
	snd_note G_4
	snd_note C_5
	snd_note E_5
	snd_note G_5
	snd_note A_5
	snd_note As_5
	snd_note B_5
	snd_end
SfxA2:
	db $02	; channel mask
	dw SfxA2_Ch2
SfxA2_Ch2:
	snd_duty $80
	snd_env $A0
	snd_note F_4, 2
	snd_note A_3
	snd_note B_4
	snd_note Ds_4
	snd_env $80
	snd_note As_4
	snd_note Ds_4
	snd_env $60
	snd_note A_4
	snd_note Ds_4
	snd_end
SfxA3:
	db $02	; channel mask
	dw SfxA3_Ch2
SfxA3_Ch2:
	snd_duty $80
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
	snd_note F_6
	snd_note D_7
	snd_note F_6
	snd_note B_5
	snd_env $80
	snd_note F_6
	snd_note D_7
	snd_note F_6
	snd_note B_5
	snd_note F_6
	snd_note D_7
	snd_note F_6
	snd_note B_5
	snd_env $60
	snd_note F_6
	snd_note D_7
	snd_note F_6
	snd_note B_5
	snd_note F_6
	snd_note D_7
	snd_note F_6
	snd_note B_5
	snd_end
SfxA4:
	db $02	; channel mask
	dw SfxA4_Ch2
SfxA4_Ch2:
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
SfxA5:
	db $02	; channel mask
	dw SfxA5_Ch2
SfxA5_Ch2:
	snd_duty $80
	snd_env $A0
	snd_note Fs_8, 1
	snd_hold $13
	snd_note C_8
	snd_env $80
	snd_note C_8, 1
	snd_hold $13
	snd_note A_7
	snd_env $40
	snd_note A_7, 1
	snd_hold $09
	snd_note Fs_7
	snd_end
SfxA6:
	db $02	; channel mask
	dw SfxA6_Ch2
SfxA6_Ch2:
	snd_duty $80
	snd_env $80
	snd_note E_7, 2
	snd_note E_8
	snd_env $A0
	snd_note E_7
	snd_note E_8
	snd_end
SfxA7:
	db $02	; channel mask
	dw SfxA7_Ch2
SfxA7_Ch2:
	snd_duty $80
	snd_env $A0
	snd_note A_7, 1
	snd_note G_7
	snd_note F_7
	snd_note E_7
	snd_note D_7
	snd_env $80
	snd_note F_7
	snd_note E_7
	snd_note D_7
	snd_note C_7
	snd_note B_6
	snd_env $60
	snd_note D_7
	snd_note C_7
	snd_note B_6
	snd_note A_6
	snd_note G_6
	snd_note F_6
	snd_note E_6
	snd_note D_6
	snd_note C_6
	snd_end
SfxA8:
	db $02	; channel mask
	dw SfxA8_Ch2
SfxA8_Ch2:
	snd_duty $80
	snd_env $A0
	snd_note E_6, 1
	snd_note F_6
	snd_note G_6
	snd_note A_6
	snd_note B_6
	snd_env $80
	snd_note G_6
	snd_note A_6
	snd_note B_6
	snd_note C_7
	snd_note D_7
	snd_env $60
	snd_note B_6
	snd_note C_7
	snd_note D_7
	snd_note E_7
	snd_note F_7
	snd_note G_7
	snd_note A_7
	snd_note B_7
	snd_note C_8
	snd_end
SfxA9:
	db $02	; channel mask
	dw SfxA9_Ch2
SfxA9_Ch2:
	snd_duty $80
	snd_env $80
	snd_len 2
	snd_env $A0
	snd_note B_3
	snd_note F_4
	snd_note D_5
	snd_note A_6
	snd_env $80
	snd_note B_3
	snd_note F_4
	snd_note D_5
	snd_note A_6
	snd_env $60
	snd_note B_3
	snd_note F_4
	snd_note D_5
	snd_note A_6
	snd_end
SfxAA:
	db $03	; channel mask
	dw SfxAA_Ch1, SfxAA_Ch2
SfxAA_Ch1:
	snd_duty $00
	snd_env $D1
	snd_note B_5, 3
	snd_note D_6
	snd_note As_5
	snd_note B_5
	snd_end
SfxAA_Ch2:
	snd_duty $00
	snd_env $D1
	snd_note G_5, 6
	snd_note Fs_5, 3
	snd_note G_5
	snd_end
SfxAB:
	db $02	; channel mask
	dw SfxAB_Ch2
SfxAB_Ch2:
	snd_duty $80
	snd_env $A0
	snd_note E_5, 1
	snd_len 4
	snd_hold $5D
	snd_note G_5, 1
	snd_len 4
	snd_hold $5B
	snd_env $80
	snd_note F_5, 1
	snd_len 4
	snd_hold $5E
	snd_note Gs_5, 1
	snd_len 4
	snd_hold $5C
	snd_env $60
	snd_note Fs_5, 1
	snd_len 4
	snd_hold $62
	snd_end
SfxAC:
	db $02	; channel mask
	dw SfxAC_Ch2
SfxAC_Ch2:
	snd_duty $80
	snd_env $A0
	snd_note C_4, 2
	snd_note C_5
	snd_note C_6
	snd_env $80
	snd_note D_6
	snd_note E_6
	snd_env $60
	snd_note F_6
	snd_end
SfxAD:
	db $02	; channel mask
	dw SfxAD_Ch2
SfxAD_Ch2:
	snd_duty $80
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
SfxAE:
	db $03	; channel mask
	dw SfxAE_Ch1, SfxAE_Ch2
SfxAE_Ch1:
	snd_duty $A7
	snd_env $A7
	snd_note Fs_5, 6
	snd_note G_5
	snd_note A_5
	snd_note D_6
	snd_end
SfxAE_Ch2:
	snd_duty $A7
	snd_env $A7
	snd_len 1
	snd_off
	snd_note Fs_5, 6
	snd_note G_5
	snd_note A_5
	snd_note D_6
	snd_end
SfxAF:
	db $02	; channel mask
	dw SfxAF_Ch2
SfxAF_Ch2:
	snd_duty $80
	snd_env $80
	snd_note F_5, 3
	snd_note D_6
	snd_note As_5
	snd_note D_6
	snd_note F_6
	snd_end
SfxB0:
	db $02	; channel mask
	dw SfxB0_Ch2
SfxB0_Ch2:
	snd_duty $80
	snd_env $80
	snd_note Gs_4, 2
	snd_note C_4
	snd_note Gs_6
	snd_note C_6
	snd_note Gs_5
	snd_note C_5
	snd_end
SfxB1:
	db $03	; channel mask
	dw SfxB1_Ch1, SfxB1_Ch2
SfxB1_Ch1:
	snd_duty $00
	snd_env $F1
	snd_note Fs_2, 9
	snd_note Fs_2, 3
	snd_note D_3, 12
	snd_end
SfxB1_Ch2:
	snd_duty $00
	snd_env $F1
	snd_len 1
	snd_off
	snd_note D_2, 9
	snd_note D_2, 3
	snd_note Fs_2, 12
	snd_end
Sfx88:
	db $02	; channel mask
	dw Sfx88_Ch2
Sfx88_Ch2:
	snd_duty $80
	snd_env $60
	snd_note F_6, 2
	snd_note B_5
	snd_note F_6
	snd_note B_5
	snd_env $80
	snd_note F_6
	snd_note B_5
	snd_note F_6
	snd_note B_5
	snd_note F_6
	snd_note B_5
	snd_note F_6
	snd_note B_5
	snd_note F_6
	snd_note B_5
	snd_note F_6
	snd_note B_5
	snd_note F_6
	snd_note B_5
	snd_note F_6
	snd_note B_5
	snd_note F_6
	snd_note B_5
	snd_end
SfxB2:
	db $02	; channel mask
	dw SfxB2_Ch2
SfxB2_Ch2:
	snd_duty $80
	snd_env $60
	snd_note A_8, 2
	snd_note D_7
	snd_note A_8
	snd_note D_7
	snd_env $A0
	snd_note A_8
	snd_note D_7
	snd_env $60
	snd_note A_8
	snd_note D_7
	snd_end
SfxB3:
	db $08	; channel mask
	dw SfxB3_Ch4
SfxB3_Ch4:
	snd_noise 3, $F1, $78
	snd_noise 3, $C1, $01
	snd_noise 3, $F1, $88
	snd_noise 8, $F1, $01
	snd_end
Mus12:
	db $0F	; channel mask
	dw Mus12_Ch1, Mus12_Ch2, Mus12_Ch3, Mus12_Ch4
Mus12_Ch1:
	snd_tempo 100
	snd_duty $80
	snd_env $69
	snd_pitchenv SndPitchEnv_47A6
Trk_4E04:
	snd_note G_5, 6
	snd_note G_5, 3
	snd_note G_5
	snd_note G_5
	snd_note Gs_5
	snd_note G_5
	snd_note Ds_5
	snd_note G_5, 6
	snd_note C_6, 3
	snd_note C_6
	snd_note C_6, 6
	snd_note G_5, 3
	snd_note Gs_5
	snd_note G_5, 6
	snd_note Ds_6, 3
	snd_note Ds_6
	snd_note D_6
	snd_note C_6
	snd_note D_6
	snd_note Ds_6
	snd_note D_6, 12
	snd_note G_5, 6
	snd_note Gs_5
	snd_note C_6, 48
	snd_note Ds_5, 6
	snd_note D_5, 3
	snd_note C_5
	snd_note D_5, 6
	snd_note Ds_5
	snd_note G_5, 12
	snd_note C_6
	snd_note Gs_5, 6
	snd_note G_5, 3
	snd_note F_5
	snd_note F_5, 6
	snd_note Gs_5
	snd_note G_5, 24
	snd_note Ds_5, 6
	snd_note D_5, 3
	snd_note C_5
	snd_note D_5, 6
	snd_note Ds_5
	snd_note G_5, 12
	snd_note Ds_5
	snd_note D_5, 6
	snd_note C_5, 3
	snd_note C_5
	snd_note D_5, 6
	snd_note Ds_5
	snd_note D_5, 24
	snd_note C_5, 12
	snd_note Ds_5, 9
	snd_note F_5, 3
	snd_note G_5, 6
	snd_note C_5
	snd_note Ds_5
	snd_note C_6
	snd_note Gs_5, 18
	snd_note G_5, 3
	snd_note Gs_5
	snd_note C_6, 6
	snd_note F_5
	snd_note Gs_5
	snd_note C_6
	snd_off
	snd_note D_6, 12
	snd_note G_5, 6
	snd_note Ds_6
	snd_note D_6, 3
	snd_note C_6
	snd_note Gs_5, 6
	snd_note G_5, 3
	snd_note Gs_5
	snd_note C_6, 6
	snd_note C_6, 12
	snd_note G_5, 3
	snd_note Gs_5
	snd_note C_6, 12
	snd_off
	snd_jump Trk_4E04
Mus12_Ch2:
	snd_duty $80
	snd_env $D1
Trk_4E85:
	snd_note C_3, 6
	snd_note G_3, 3
	snd_note G_3
	snd_note G_3, 6
	snd_note G_3
	snd_note C_3
	snd_note G_3, 3
	snd_note G_3
	snd_note G_3, 6
	snd_note G_3
	snd_note C_3
	snd_note G_3, 3
	snd_note G_3
	snd_note G_3, 6
	snd_note G_3
	snd_note G_3, 12
	snd_note G_3
	snd_note C_3, 6
	snd_note G_3, 3
	snd_note G_3
	snd_note G_3, 6
	snd_note Ds_3
	snd_note C_3
	snd_note G_3, 3
	snd_note G_3
	snd_note G_3, 6
	snd_note Ds_3
	snd_note C_3
	snd_note G_3, 3
	snd_note G_3
	snd_note G_3, 6
	snd_note Ds_3
	snd_note C_3
	snd_note G_3, 3
	snd_note G_3
	snd_note G_3, 6
	snd_note Ds_3
	snd_note C_3
	snd_note Gs_3, 3
	snd_note Gs_3
	snd_note Gs_3, 6
	snd_note F_3
	snd_note G_3
	snd_note F_3
	snd_note Ds_3
	snd_note D_3
	snd_note C_3
	snd_note G_3, 3
	snd_note G_3
	snd_note G_3, 6
	snd_note Ds_3
	snd_note Gs_2
	snd_note Ds_3, 3
	snd_note Ds_3
	snd_note Ds_3, 6
	snd_note C_3
	snd_note D_3
	snd_note A_3, 3
	snd_note A_3
	snd_note A_3, 6
	snd_note Fs_3
	snd_note G_3
	snd_note F_3
	snd_note Ds_3
	snd_note D_3
	snd_note C_3
	snd_note G_3, 3
	snd_note G_3
	snd_note G_3, 6
	snd_note Ds_3
	snd_note C_3
	snd_note G_3, 3
	snd_note G_3
	snd_note G_3, 6
	snd_note Ds_3
	snd_note C_3
	snd_note Gs_3, 3
	snd_note Gs_3
	snd_note Gs_3, 6
	snd_note F_3
	snd_note C_3
	snd_note Gs_3, 3
	snd_note Gs_3
	snd_note Gs_3, 6
	snd_note F_3
	snd_note B_2
	snd_note G_3, 3
	snd_note G_3
	snd_note G_3, 6
	snd_note D_3
	snd_note B_2
	snd_note G_3, 3
	snd_note G_3
	snd_note G_3, 6
	snd_note D_3
	snd_note C_3
	snd_note G_3, 3
	snd_note G_3
	snd_note G_3, 6
	snd_note Ds_3
	snd_note C_3
	snd_note G_3, 3
	snd_note G_3
	snd_note G_3, 6
	snd_note E_3
	snd_jump Trk_4E85
Mus12_Ch3:
	snd_end
SndUnused_4F1B:
	snd_duty $E0
	snd_env $20
	snd_len 1
	snd_off
	snd_off
	snd_off
	snd_pitchenv SndEnvUnused_47B1
Trk_4F26:
	snd_note G_4, 6
	snd_note G_4, 3
	snd_note G_4
	snd_note G_4
	snd_note Gs_4
	snd_note G_4
	snd_note Ds_4
	snd_note G_4, 6
	snd_note C_5, 3
	snd_note C_5
	snd_note C_5, 6
	snd_note G_4, 3
	snd_note Gs_4
	snd_note G_4, 6
	snd_note Ds_5, 3
	snd_note Ds_5
	snd_note D_5
	snd_note C_5
	snd_note D_5
	snd_note Ds_5
	snd_note D_5, 12
	snd_note G_4, 6
	snd_note Gs_4
	snd_note C_5, 48
	snd_note Ds_4, 6
	snd_note D_4, 3
	snd_note C_4
	snd_note D_4, 6
	snd_note Ds_4
	snd_note G_4, 12
	snd_note C_5
	snd_note Gs_4, 6
	snd_note G_4, 3
	snd_note F_4
	snd_note F_4, 6
	snd_note Gs_4
	snd_note G_4, 24
	snd_note Ds_4, 6
	snd_note D_4, 3
	snd_note C_4
	snd_note D_4, 6
	snd_note Ds_4
	snd_note G_4, 12
	snd_note Ds_4
	snd_note D_4, 6
	snd_note C_4, 3
	snd_note C_4
	snd_note D_4, 6
	snd_note Ds_4
	snd_note D_4, 24
	snd_note C_4, 12
	snd_note Ds_4, 9
	snd_note F_4, 3
	snd_note G_4, 6
	snd_note C_4
	snd_note Ds_4
	snd_note C_5
	snd_note Gs_4, 18
	snd_note G_4, 3
	snd_note Gs_4
	snd_note C_5, 6
	snd_note F_4
	snd_note Gs_4
	snd_note C_5
	snd_off
	snd_note D_5, 12
	snd_note G_4, 6
	snd_note Ds_5
	snd_note D_5, 3
	snd_note C_5
	snd_note Gs_4, 6
	snd_note G_4, 3
	snd_note Gs_4
	snd_note C_5, 6
	snd_note C_5, 12
	snd_note G_4, 3
	snd_note Gs_4
	snd_note C_5, 12
	snd_off
	snd_jump Trk_4F26
Mus12_Ch4:
	snd_end
Mus00:
	db $0F	; channel mask
	dw Mus00_Ch1, Mus00_Ch2, Mus00_Ch3, Mus00_Ch4
Mus00_Ch1:
	snd_tempo 130
	snd_duty $80
	snd_env $A4
	snd_pitchenv SndPitchEnv_4766
Trk_4FB6:
	snd_len 8
	snd_off
	snd_note As_5, 4
	snd_note C_6, 11
	snd_note C_6, 1
	snd_note Cs_6, 8
	snd_note As_5, 12
	snd_note As_5, 4
	snd_len 48
	snd_off
	snd_len 8
	snd_off
	snd_note As_5, 4
	snd_note C_6, 11
	snd_note C_6, 1
	snd_note Cs_6, 8
	snd_note As_5, 12
	snd_note As_5, 4
	snd_len 48
	snd_off
	snd_len 8
	snd_off
	snd_note As_5, 4
	snd_note C_6, 11
	snd_note C_6, 1
	snd_note Cs_6, 8
	snd_note As_5, 12
	snd_note As_5, 4
	snd_len 48
	snd_off
	snd_note D_6, 6
	snd_len 2
	snd_off
	snd_note Cs_6, 4
	snd_note C_6, 6
	snd_len 2
	snd_off
	snd_note B_5, 12
	snd_note As_5, 4
	snd_note A_5, 8
	snd_note Gs_5, 4
	snd_len 8
	snd_off
	snd_note G_5, 4
	snd_note Fs_5, 8
	snd_note F_5, 4
	snd_len 8
	snd_off
	snd_note A_5, 4
	snd_len 8
	snd_off
	snd_note As_5, 3
	snd_len 1
	snd_off
	snd_jump Trk_4FB6
Mus00_Ch3:
	snd_duty $E0
	snd_env $40
	snd_pitchenv SndPitchEnv_4766
	snd_transpose $F4
Trk_5016:
	snd_len 7
	snd_off
	snd_note As_4, 2
	snd_len 15
	snd_off
	snd_note As_4, 2
	snd_len 22
	snd_off
	snd_len 7
	snd_off
	snd_note Cs_5, 2
	snd_len 15
	snd_off
	snd_note C_5, 2
	snd_len 22
	snd_off
	snd_len 7
	snd_off
	snd_note As_4, 2
	snd_len 15
	snd_off
	snd_note As_4, 2
	snd_len 22
	snd_off
	snd_len 7
	snd_off
	snd_note B_4, 2
	snd_len 15
	snd_off
	snd_note B_4, 2
	snd_len 22
	snd_off
	snd_len 7
	snd_off
	snd_note As_4, 2
	snd_len 15
	snd_off
	snd_note As_4, 2
	snd_len 22
	snd_off
	snd_len 7
	snd_off
	snd_note Cs_5, 2
	snd_len 15
	snd_off
	snd_note C_5, 2
	snd_len 22
	snd_off
	snd_note F_5, 4
	snd_len 4
	snd_off
	snd_note E_5, 4
	snd_note Ds_5, 4
	snd_len 4
	snd_off
	snd_note D_5, 4
	snd_len 8
	snd_off
	snd_note Ds_5, 4
	snd_note F_5, 4
	snd_len 4
	snd_off
	snd_note Ds_5, 4
	snd_len 8
	snd_off
	snd_note C_5, 4
	snd_note As_4, 8
	snd_note A_4, 4
	snd_len 8
	snd_off
	snd_note Cs_5, 4
	snd_len 8
	snd_off
	snd_note D_5, 3
	snd_len 1
	snd_off
	snd_jump Trk_5016
Mus00_Ch2:
	snd_duty $80
	snd_env $D2
	snd_pitchenv SndPitchEnv_4766
	snd_transpose $F4
Trk_5086:
	snd_note As_3, 12
	snd_note As_3
	snd_note D_4
	snd_note D_4
	snd_note Ds_4
	snd_note Ds_4
	snd_note Gs_3, 8
	snd_note As_3, 4
	snd_note C_4, 12
	snd_note As_3
	snd_note As_3
	snd_note D_4
	snd_note D_4
	snd_note Cs_4
	snd_note Ds_4
	snd_note F_4
	snd_note Cs_4
	snd_note As_3
	snd_note As_3
	snd_note D_4
	snd_note D_4
	snd_note Ds_4
	snd_note Ds_4
	snd_note Gs_3, 8
	snd_note As_3, 4
	snd_note C_4, 12
	snd_note D_4
	snd_note Gs_4
	snd_note G_4
	snd_note B_3
	snd_note C_4
	snd_note E_4
	snd_note F_4
	snd_note B_3, 8
	snd_len 4
	snd_off
	snd_jump Trk_5086
Mus00_Ch4:
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 12
	snd_drum 1
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 12
	snd_drum 1
	snd_len 3
	snd_drum 0
	snd_len 1
	snd_off
	snd_jump Mus00_Ch4
Mus01:
	db $0F	; channel mask
	dw Mus01_Ch1, Mus01_Ch2, Mus01_Ch3, Mus01_Ch4
Mus01_Ch1:
	snd_tempo 130
	snd_duty $80
	snd_env $A4
	snd_pitchenv SndPitchEnv_47C4
Trk_512C:
	snd_note G_6, 24
	snd_note Fs_6, 9
	snd_note G_6
	snd_note A_6, 6
	snd_note G_6
	snd_note E_6, 3
	snd_note C_6, 24
	snd_note C_7, 9
	snd_note B_6, 6
	snd_note B_6, 9
	snd_note A_6, 15
	snd_note F_6, 9
	snd_note G_6
	snd_note A_6, 6
	snd_note G_6, 48
	snd_note A_6, 6
	snd_note F_6, 3
	snd_note D_6, 6
	snd_note C_6
	snd_note B_5
	snd_note A_6, 3
	snd_note Gs_6
	snd_note A_6
	snd_note B_6, 6
	snd_note C_7
	snd_note G_6, 9
	snd_note E_6
	snd_note G_6, 6
	snd_note D_7, 12
	snd_note C_7
	snd_note As_6, 9
	snd_note As_6
	snd_note A_6, 6
	snd_note G_6, 9
	snd_note A_6
	snd_note As_6, 6
	snd_note A_6, 24
	snd_note D_6
	snd_jump Trk_512C
Mus01_Ch3:
	snd_duty $E0
	snd_env $20
	snd_pitchenv SndPitchEnv_4766
Trk_5175:
	snd_note E_6, 24
	snd_note A_5, 9
	snd_note C_6
	snd_note Ds_6, 6
	snd_note E_6
	snd_note C_6, 3
	snd_note G_5, 15
	snd_note C_6, 6
	snd_note G_5, 3
	snd_note E_5, 15
	snd_note G_6, 9
	snd_note F_6, 15
	snd_note A_5, 9
	snd_note B_5
	snd_note C_6, 6
	snd_note B_5, 9
	snd_note C_6
	snd_note D_6, 6
	snd_note C_6, 9
	snd_note D_6
	snd_note E_6, 6
	snd_note C_6
	snd_note A_5, 3
	snd_note F_5, 6
	snd_note E_5
	snd_note D_5
	snd_note F_6, 3
	snd_note E_6
	snd_note F_6
	snd_note G_6, 6
	snd_note A_6
	snd_note E_6, 9
	snd_note C_6
	snd_note E_6, 6
	snd_note B_6, 12
	snd_note A_6
	snd_note G_6, 9
	snd_note G_6
	snd_note Ds_6, 6
	snd_note As_5, 9
	snd_note C_6
	snd_note D_6, 6
	snd_note C_6, 9
	snd_note F_5
	snd_note A_5, 6
	snd_note C_6, 12
	snd_note B_5
	snd_jump Trk_5175
Mus01_Ch2:
	snd_duty $80
	snd_env $D2
	snd_pitchenv SndPitchEnv_4766
	snd_transpose $F4
Trk_51CE:
	snd_note C_4, 9
	snd_note C_4, 6
	snd_note C_4
	snd_note C_4, 3
	snd_note C_4, 6
	snd_note G_4, 3
	snd_note C_4
	snd_note C_5
	snd_note C_4, 6
	snd_note C_4, 3
	snd_note C_4, 9
	snd_note C_4, 6
	snd_note C_4
	snd_note C_4, 3
	snd_note C_4, 6
	snd_note G_4, 3
	snd_note C_4
	snd_note C_5
	snd_note C_4, 6
	snd_note C_4, 3
	snd_note C_4, 9
	snd_note C_4, 6
	snd_note C_4
	snd_note C_4, 3
	snd_note C_4, 6
	snd_note A_4, 3
	snd_note C_4
	snd_note C_5
	snd_note C_4, 6
	snd_note C_4, 3
	snd_note C_4, 9
	snd_note C_4, 6
	snd_note C_4
	snd_note C_4, 3
	snd_note C_4, 6
	snd_note G_4, 3
	snd_note C_4
	snd_note C_5
	snd_note C_4, 6
	snd_note C_4, 3
	snd_note D_4, 9
	snd_note D_4, 6
	snd_note D_4
	snd_note D_4, 3
	snd_note G_4, 6
	snd_note D_5, 3
	snd_note G_4
	snd_note F_5
	snd_note G_4, 6
	snd_note G_4, 3
	snd_note A_4, 9
	snd_note A_4, 6
	snd_note A_4
	snd_note A_4, 3
	snd_note Fs_4, 6
	snd_note C_5, 3
	snd_note Fs_4
	snd_note Ds_5
	snd_note Fs_4, 6
	snd_note D_4, 3
	snd_note Ds_4, 9
	snd_note Ds_4, 6
	snd_note Ds_4
	snd_note Ds_4, 3
	snd_note Ds_4, 9
	snd_note Ds_4, 6
	snd_note Ds_4
	snd_note Ds_4, 3
	snd_note D_4, 9
	snd_note D_4, 6
	snd_note D_4
	snd_note D_4, 3
	snd_note G_3, 6
	snd_note D_4, 3
	snd_note G_3
	snd_note G_4
	snd_note G_3, 6
	snd_note G_3, 2
	snd_len 1
	snd_off
	snd_jump Trk_51CE
Mus01_Ch4:
	snd_len 6
	snd_drum 0
	snd_len 3
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_len 3
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_len 3
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_len 3
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_len 3
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_len 3
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_len 3
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_len 3
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_len 3
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_len 3
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_len 3
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_len 3
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_len 3
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_len 3
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_len 3
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_len 3
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_len 3
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_len 3
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_len 3
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_len 3
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_len 3
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_len 3
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_len 3
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_len 3
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_len 3
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_len 3
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_len 3
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_len 3
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_len 3
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_len 3
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_len 3
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_len 3
	snd_drum 0
	snd_jump Mus01_Ch4
Mus02:
	db $0F	; channel mask
	dw Mus02_Ch1, Mus02_Ch2, Mus02_Ch3, Mus02_Ch4
Mus02_Ch1:
	snd_tempo 140
	snd_duty $80
	snd_env $A4
	snd_pitchenv SndPitchEnv_4766
Trk_530D:
	snd_len 18
	snd_off
	snd_note C_4, 6
	snd_note G_4
	snd_note G_3
	snd_note G_4
	snd_note C_4
	snd_note G_4
	snd_note D_4, 3
	snd_note Ds_4
	snd_note E_4, 6
	snd_note F_4
	snd_note C_5
	snd_note C_4
	snd_note C_5
	snd_note F_4
	snd_note A_3
	snd_note A_3, 3
	snd_note As_3
	snd_note B_3, 6
	snd_note C_4
	snd_note G_4
	snd_note G_3
	snd_note G_4
	snd_note C_4
	snd_note G_4
	snd_note D_4, 3
	snd_note Ds_4
	snd_note E_4, 6
	snd_note D_4
	snd_note G_4
	snd_note A_3
	snd_note As_3
	snd_note B_3
	snd_note G_4
	snd_note G_3, 12
	snd_note C_4, 6
	snd_note G_4
	snd_note G_3
	snd_note G_4
	snd_note C_4
	snd_note G_4
	snd_note D_4, 3
	snd_note Ds_4
	snd_note E_4, 6
	snd_note C_4
	snd_note Cs_4, 3
	snd_note D_4
	snd_note Ds_4, 6
	snd_note E_4
	snd_note F_4
	snd_note C_4
	snd_note F_4, 3
	snd_note E_4
	snd_note Ds_4, 6
	snd_note D_4
	snd_note A_4
	snd_note Gs_4, 3
	snd_note G_4
	snd_note Fs_4, 6
	snd_note F_4
	snd_note C_4
	snd_note Ds_4
	snd_note D_4
	snd_note A_3
	snd_note C_4
	snd_note As_3, 3
	snd_note A_3
	snd_note Gs_3, 6
	snd_note G_3
	snd_jump Trk_530D
Mus02_Ch3:
	snd_duty $E0
	snd_env $30
	snd_pitchenv SndPitchEnv_4766
	snd_transpose $F4
Trk_5372:
	snd_note E_5, 6
	snd_note G_5
	snd_note A_5
	snd_note G_5, 12
	snd_note E_5
	snd_note G_5, 3
	snd_note Gs_5
	snd_note A_5, 6
	snd_note C_6
	snd_note A_5
	snd_note Ds_6
	snd_note D_6
	snd_note C_6, 3
	snd_note C_6
	snd_note A_5, 12
	snd_note E_5, 6
	snd_note G_5
	snd_note A_5
	snd_note G_5, 12
	snd_note E_5
	snd_note G_5, 3
	snd_note Gs_5
	snd_note A_5, 6
	snd_note C_6
	snd_note A_5
	snd_note G_5
	snd_note E_5
	snd_note E_5, 3
	snd_note Ds_5
	snd_note D_5, 12
	snd_note E_5, 6
	snd_note G_5
	snd_note A_5
	snd_note G_5, 12
	snd_note E_5
	snd_note G_5, 3
	snd_note Gs_5
	snd_note A_5, 6
	snd_note C_6
	snd_note A_5
	snd_note C_6
	snd_note G_5
	snd_note As_5
	snd_note A_5, 12
	snd_note Gs_5, 6
	snd_note A_5
	snd_note C_6, 12
	snd_note A_5, 6
	snd_note C_6
	snd_note Ds_6, 12
	snd_note D_6, 6
	snd_note C_6
	snd_note D_6, 24
	snd_len 12
	snd_off
	snd_jump Trk_5372
Mus02_Ch2:
	snd_duty $80
	snd_env $D2
	snd_pitchenv SndPitchEnv_4766
Trk_53CA:
	snd_len 24
	snd_off
	snd_note G_6, 6
	snd_note G_6, 3
	snd_note G_6
	snd_note G_6, 6
	snd_len 6
	snd_off
	snd_len 24
	snd_off
	snd_note A_6, 6
	snd_note Gs_6, 3
	snd_note G_6
	snd_note F_6, 6
	snd_len 6
	snd_off
	snd_len 24
	snd_off
	snd_note G_6, 6
	snd_note G_6, 3
	snd_note G_6
	snd_note G_6, 6
	snd_len 6
	snd_off
	snd_len 24
	snd_off
	snd_note G_6, 6
	snd_note G_6, 3
	snd_note G_6
	snd_note G_6, 6
	snd_note F_6, 3
	snd_note E_6
	snd_note Ds_6, 6
	snd_note D_6, 6
	snd_len 12
	snd_off
	snd_note G_6, 6
	snd_note G_6, 3
	snd_note G_6
	snd_note G_6, 6
	snd_len 6
	snd_off
	snd_len 24
	snd_off
	snd_note G_6, 6
	snd_note G_6, 3
	snd_note Fs_6
	snd_note F_6, 12
	snd_note E_6, 6
	snd_note F_6
	snd_note A_6, 12
	snd_note F_6, 6
	snd_note A_6
	snd_note C_7, 12
	snd_note As_6, 6
	snd_note Gs_6
	snd_note G_6, 24
	snd_len 12
	snd_off
	snd_jump Trk_53CA
Mus02_Ch4:
	snd_len 18
	snd_off
	snd_len 6
	snd_drum 2
	snd_len 3
	snd_drum 2
	snd_drum 2
	snd_len 6
	snd_drum 2
	snd_len 3
	snd_drum 2
	snd_drum 2
	snd_len 6
	snd_drum 2
	snd_len 3
	snd_drum 2
	snd_drum 2
	snd_len 6
	snd_drum 2
	snd_len 3
	snd_drum 2
	snd_drum 2
	snd_len 6
	snd_drum 2
	snd_len 3
	snd_drum 2
	snd_drum 2
	snd_len 6
	snd_drum 2
	snd_len 3
	snd_drum 2
	snd_drum 2
	snd_len 6
	snd_drum 2
	snd_len 3
	snd_drum 2
	snd_drum 2
	snd_len 6
	snd_drum 2
	snd_len 3
	snd_drum 2
	snd_drum 2
	snd_len 6
	snd_drum 2
	snd_len 3
	snd_drum 2
	snd_drum 2
	snd_len 6
	snd_drum 2
	snd_len 3
	snd_drum 2
	snd_drum 2
	snd_len 6
	snd_drum 2
	snd_len 3
	snd_drum 2
	snd_drum 2
	snd_len 6
	snd_drum 2
	snd_len 3
	snd_drum 2
	snd_drum 2
	snd_len 6
	snd_drum 2
	snd_len 3
	snd_drum 2
	snd_drum 2
	snd_len 6
	snd_drum 2
	snd_len 3
	snd_drum 2
	snd_drum 2
	snd_len 6
	snd_drum 2
	snd_len 3
	snd_drum 2
	snd_drum 2
	snd_len 6
	snd_drum 2
	snd_len 3
	snd_drum 2
	snd_drum 2
	snd_len 6
	snd_drum 2
	snd_len 3
	snd_drum 2
	snd_drum 2
	snd_len 6
	snd_drum 2
	snd_len 3
	snd_drum 2
	snd_drum 2
	snd_len 6
	snd_drum 2
	snd_len 3
	snd_drum 2
	snd_drum 2
	snd_len 6
	snd_drum 2
	snd_len 3
	snd_drum 2
	snd_drum 2
	snd_len 6
	snd_drum 2
	snd_len 3
	snd_drum 2
	snd_drum 2
	snd_len 6
	snd_drum 2
	snd_len 3
	snd_drum 2
	snd_drum 2
	snd_len 6
	snd_drum 2
	snd_len 3
	snd_drum 2
	snd_drum 2
	snd_len 6
	snd_drum 2
	snd_len 3
	snd_drum 2
	snd_drum 2
	snd_len 6
	snd_drum 2
	snd_len 3
	snd_drum 2
	snd_drum 2
	snd_len 6
	snd_drum 2
	snd_len 3
	snd_drum 2
	snd_drum 2
	snd_len 6
	snd_drum 2
	snd_len 3
	snd_drum 2
	snd_drum 2
	snd_len 6
	snd_drum 2
	snd_len 3
	snd_drum 2
	snd_drum 2
	snd_len 6
	snd_drum 2
	snd_len 3
	snd_drum 2
	snd_drum 2
	snd_len 6
	snd_drum 2
	snd_len 3
	snd_drum 2
	snd_drum 2
	snd_len 6
	snd_drum 2
	snd_jump Mus02_Ch4
Mus03:
	db $0F	; channel mask
	dw Mus03_Ch1, Mus03_Ch2, Mus03_Ch3, Mus03_Ch4
Mus03_Ch1:
	snd_tempo 110
	snd_duty $00
	snd_env $A4
	snd_pitchenv SndPitchEnv_47C4
Trk_54D2:
	snd_note A_5, 12
	snd_note C_6
	snd_note D_6
	snd_note A_5
	snd_note C_6, 6
	snd_note A_5, 4
	snd_note A_5, 2
	snd_note G_5, 4
	snd_note A_5, 2
	snd_note C_6, 4
	snd_note D_6, 6
	snd_note E_6, 20
	snd_note A_6, 6
	snd_note A_6
	snd_note G_6, 4
	snd_note A_6, 6
	snd_note A_6
	snd_note E_6, 8
	snd_note D_6, 6
	snd_note C_6
	snd_note D_6
	snd_note C_6
	snd_note D_6, 4
	snd_note C_6, 2
	snd_note A_5, 4
	snd_note G_5, 6
	snd_note C_6
	snd_note A_5, 14
	snd_len 4
	snd_off
	snd_note C_6, 2
	snd_note C_6, 4
	snd_note A_5, 2
	snd_note C_6, 6
	snd_note A_5
	snd_note C_6
	snd_note A_5
	snd_note C_6, 4
	snd_note D_6, 6
	snd_note E_6, 2
	snd_len 4
	snd_off
	snd_note C_6, 2
	snd_note C_6, 4
	snd_note A_5, 2
	snd_note C_6, 6
	snd_note A_5
	snd_note C_6, 4
	snd_note D_6, 6
	snd_note A_5, 14
	snd_len 4
	snd_hold $5F
	snd_note C_6, 2
	snd_note C_6, 4
	snd_note A_5, 2
	snd_note C_6, 6
	snd_note A_5
	snd_note C_6
	snd_note A_5
	snd_note C_6, 4
	snd_note D_6, 6
	snd_note E_6, 2
	snd_len 4
	snd_off
	snd_note C_6, 2
	snd_note C_6, 4
	snd_note A_5, 2
	snd_note C_6, 6
	snd_note A_5
	snd_note C_6, 4
	snd_note D_6, 6
	snd_note A_5, 12
	snd_len 2
	snd_off
	snd_jump Trk_54D2
Mus03_Ch3:
	snd_duty $E0
	snd_env $20
	snd_pitchenv SndPitchEnv_4766
Trk_5556:
	snd_len 4
	snd_off
	snd_note E_5, 6
	snd_note E_5
	snd_note E_5
	snd_note E_5
	snd_note E_5, 2
	snd_note D_5, 4
	snd_note Ds_5, 6
	snd_note E_5
	snd_note E_5, 2
	snd_note F_5, 18
	snd_note F_5, 4
	snd_note Fs_5, 2
	snd_note G_5, 24
	snd_len 4
	snd_off
	snd_note A_5, 6
	snd_note A_5
	snd_note A_5, 2
	snd_note G_5, 4
	snd_note Gs_5, 6
	snd_note A_5
	snd_note A_5
	snd_note A_5
	snd_note A_5, 2
	snd_note A_5, 6
	snd_note G_5
	snd_note A_5, 4
	snd_note G_5, 2
	snd_note E_5, 4
	snd_note D_5, 6
	snd_note G_5
	snd_note E_5, 14
	snd_len 4
	snd_off
	snd_note G_5, 6
	snd_note E_5, 2
	snd_note G_5, 6
	snd_note E_5, 4
	snd_note G_5, 6
	snd_note G_5
	snd_note E_5, 2
	snd_note G_5, 4
	snd_note A_5, 6
	snd_note A_5, 2
	snd_len 4
	snd_off
	snd_note G_5, 2
	snd_note G_5, 4
	snd_note E_5, 6
	snd_note G_5
	snd_note E_5, 2
	snd_note G_5, 6
	snd_note E_5
	snd_note D_5, 4
	snd_note E_5, 6
	snd_note E_5, 2
	snd_len 4
	snd_off
	snd_note G_5, 2
	snd_note G_5, 4
	snd_note E_5, 2
	snd_note G_5, 6
	snd_note E_5
	snd_note G_5
	snd_note E_5
	snd_note G_5, 4
	snd_note A_5, 6
	snd_note A_5, 2
	snd_len 4
	snd_off
	snd_note G_5, 2
	snd_note G_5, 4
	snd_note E_5, 2
	snd_note G_5, 6
	snd_note E_5
	snd_note G_5
	snd_note E_5
	snd_note D_5, 4
	snd_note E_5, 8
	snd_jump Trk_5556
Mus03_Ch2:
	snd_duty $80
	snd_env $D2
	snd_pitchenv SndPitchEnv_4766
	snd_transpose $F4
Trk_55E5:
	snd_note A_3, 6
	snd_note A_3
	snd_note A_3, 4
	snd_note A_4, 6
	snd_note A_3, 2
	snd_note A_3, 6
	snd_note A_4, 4
	snd_note A_4, 6
	snd_note A_4
	snd_note As_3, 2
	snd_note As_3, 4
	snd_note As_3, 2
	snd_note As_4, 6
	snd_note As_3, 4
	snd_note As_4, 6
	snd_note As_3, 2
	snd_note G_3, 6
	snd_note G_3
	snd_note G_3, 4
	snd_note D_4, 2
	snd_note G_3, 4
	snd_note Gs_3, 2
	snd_note A_3, 6
	snd_note A_3
	snd_note A_3, 4
	snd_note A_4, 6
	snd_note A_3, 2
	snd_note A_3, 6
	snd_note A_4, 4
	snd_note A_3, 6
	snd_note A_4, 2
	snd_note A_3, 6
	snd_note F_3
	snd_note F_3
	snd_note F_3, 4
	snd_note C_4, 2
	snd_note F_3, 6
	snd_note F_3
	snd_note F_3
	snd_note F_3, 4
	snd_note C_4, 2
	snd_note G_3, 4
	snd_note Gs_3, 2
	snd_note A_3, 6
	snd_note A_3
	snd_note A_3, 4
	snd_note A_3, 6
	snd_note A_3, 2
	snd_note A_3, 4
	snd_note A_4, 2
	snd_note A_3
	snd_note G_3
	snd_note Gs_3
	snd_note A_3, 4
	snd_note A_3, 2
	snd_note A_4, 4
	snd_note A_3, 2
	snd_note D_4, 6
	snd_note D_4
	snd_note D_4, 4
	snd_note D_4, 6
	snd_note D_4
	snd_note D_4
	snd_note D_4, 2
	snd_note E_4, 6
	snd_note E_4
	snd_note A_3
	snd_note A_3
	snd_note A_3
	snd_note A_3, 4
	snd_note A_3, 6
	snd_note A_3
	snd_note A_3, 2
	snd_note A_3, 4
	snd_note A_4, 2
	snd_note A_3, 4
	snd_note A_4, 2
	snd_note D_4, 6
	snd_note D_4
	snd_note D_4, 4
	snd_note C_4, 2
	snd_note D_4, 4
	snd_note E_4, 6
	snd_note E_4
	snd_note E_4, 2
	snd_note E_4, 4
	snd_note E_3, 8
	snd_jump Trk_55E5
Mus03_Ch4:
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_len 4
	snd_drum 0
	snd_len 2
	snd_drum 4
	snd_len 4
	snd_drum 0
	snd_len 2
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_drum 4
	snd_len 4
	snd_drum 0
	snd_len 2
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 2
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_len 4
	snd_drum 0
	snd_len 2
	snd_drum 4
	snd_len 4
	snd_drum 0
	snd_len 2
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_drum 4
	snd_len 4
	snd_drum 0
	snd_len 2
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 2
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_len 4
	snd_drum 0
	snd_len 2
	snd_drum 4
	snd_len 4
	snd_drum 0
	snd_len 2
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_drum 4
	snd_len 4
	snd_drum 0
	snd_len 2
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 2
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_len 4
	snd_drum 0
	snd_len 2
	snd_drum 4
	snd_len 4
	snd_drum 0
	snd_len 2
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_drum 4
	snd_len 4
	snd_drum 0
	snd_len 2
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 4
	snd_drum 4
	snd_len 2
	snd_drum 4
	snd_drum 0
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 2
	snd_drum 4
	snd_jump Mus03_Ch4
Mus04:
	db $0F	; channel mask
	dw Mus04_Ch1, Mus04_Ch2, Mus04_Ch3, Mus04_Ch4
Mus04_Ch1:
	snd_tempo 140
	snd_duty $C0
	snd_env $A4
	snd_pitchenv SndPitchEnv_47C4
Trk_5714:
	snd_note E_6, 6
	snd_note E_6
	snd_note D_6
	snd_note D_6
	snd_note E_6, 3
	snd_note D_6, 6
	snd_note C_6, 9
	snd_note A_5, 6
	snd_note C_6
	snd_note C_6
	snd_note D_6
	snd_note A_5
	snd_note C_6, 3
	snd_note D_6, 6
	snd_note D_6, 15
	snd_note E_6, 6
	snd_note E_6
	snd_note D_6
	snd_note D_6
	snd_note E_6, 3
	snd_note D_6, 6
	snd_note C_6, 9
	snd_note A_5, 6
	snd_note C_6
	snd_note C_6
	snd_note C_6, 3
	snd_note D_6, 6
	snd_note A_5, 27
	snd_note B_5, 24
	snd_note B_5, 9
	snd_note A_5
	snd_note B_5, 6
	snd_note C_6, 9
	snd_note C_6
	snd_note D_6, 6
	snd_note E_6, 24
	snd_note F_6, 30
	snd_note G_6, 6
	snd_note A_6
	snd_note F_6
	snd_note E_6, 9
	snd_note D_6
	snd_note C_6, 6
	snd_note D_6, 3
	snd_note C_6, 6
	snd_note D_6, 9
	snd_note E_6, 3
	snd_off
	snd_jump Trk_5714
Mus04_Ch3:
	snd_duty $E0
	snd_env $20
	snd_pitchenv SndPitchEnv_4766
Trk_576C:
	snd_len 6
	snd_off
	snd_note E_5
	snd_note G_5
	snd_note E_5
	snd_note G_5, 3
	snd_note A_5, 6
	snd_note A_5
	snd_note E_5
	snd_note E_5, 3
	snd_len 6
	snd_off
	snd_note E_5
	snd_note G_5
	snd_note E_5
	snd_note G_5, 3
	snd_note A_5, 6
	snd_note A_5
	snd_note E_5
	snd_note E_5, 3
	snd_len 6
	snd_off
	snd_note E_5
	snd_note G_5
	snd_note E_5
	snd_note G_5, 3
	snd_note A_5, 6
	snd_note A_5
	snd_note E_5
	snd_note E_5, 3
	snd_len 6
	snd_off
	snd_note E_5
	snd_note G_5
	snd_note E_5
	snd_note G_5, 3
	snd_note A_5, 6
	snd_note A_5
	snd_note E_5
	snd_note E_5, 3
	snd_len 6
	snd_off
	snd_note G_5
	snd_note D_5
	snd_note E_5
	snd_note G_5, 3
	snd_note D_5, 6
	snd_note E_5, 9
	snd_note G_5, 6
	snd_off
	snd_note A_5
	snd_note E_5
	snd_note G_5
	snd_note A_5, 3
	snd_note E_5, 6
	snd_note G_5, 9
	snd_note A_5, 6
	snd_off
	snd_note A_5
	snd_note F_5
	snd_note G_5
	snd_note A_5, 3
	snd_note F_5, 6
	snd_note G_5, 9
	snd_note A_5, 6
	snd_note C_6, 9
	snd_note B_5
	snd_note A_5, 6
	snd_note B_5, 3
	snd_note A_5, 6
	snd_note B_5, 9
	snd_note C_6, 3
	snd_off
	snd_jump Trk_576C
Mus04_Ch2:
	snd_duty $C0
	snd_env $D2
	snd_pitchenv SndPitchEnv_4766
	snd_transpose $F4
Trk_57DF:
	snd_note A_3, 6
	snd_note A_3
	snd_note C_4, 3
	snd_note A_3, 6
	snd_note G_3, 3
	snd_note A_3, 6
	snd_note A_3
	snd_note C_4, 3
	snd_note A_3, 6
	snd_note G_3, 3
	snd_note A_3, 6
	snd_note A_3
	snd_note C_4, 3
	snd_note A_3, 6
	snd_note G_3, 3
	snd_note A_3, 6
	snd_note A_3
	snd_note C_4, 3
	snd_note A_3, 6
	snd_note G_3, 3
	snd_note A_3, 6
	snd_note A_3
	snd_note C_4, 3
	snd_note A_3, 6
	snd_note G_3, 3
	snd_note A_3, 6
	snd_note A_3
	snd_note C_4, 3
	snd_note A_3, 6
	snd_note G_3, 3
	snd_note A_3, 6
	snd_note A_3
	snd_note C_4, 3
	snd_note A_3, 6
	snd_note G_3, 3
	snd_note A_3, 6
	snd_note A_3
	snd_note C_4, 3
	snd_note A_3, 6
	snd_note G_3, 3
	snd_note E_4, 6
	snd_note E_4
	snd_note E_4, 3
	snd_note G_4, 6
	snd_note A_4, 3
	snd_note E_4, 6
	snd_note E_4
	snd_note D_4, 3
	snd_note E_4, 6
	snd_note C_4, 3
	snd_note A_3, 6
	snd_note A_3
	snd_note G_3, 3
	snd_note A_3, 6
	snd_note C_4, 3
	snd_note A_3, 6
	snd_note A_3
	snd_note E_4, 3
	snd_note A_3, 6
	snd_note C_4, 3
	snd_note D_4, 6
	snd_note D_4
	snd_note D_4, 3
	snd_note F_4, 6
	snd_note D_4, 3
	snd_note B_3, 6
	snd_note B_3
	snd_note B_3, 3
	snd_note C_4, 6
	snd_note D_4, 3
	snd_note E_4, 6
	snd_note E_4
	snd_note E_4, 3
	snd_note G_4, 6
	snd_note A_4, 3
	snd_note E_4, 6
	snd_note E_4
	snd_note G_4, 3
	snd_note E_4, 6
	snd_note C_4, 3
	snd_jump Trk_57DF
Mus04_Ch4:
	snd_len 3
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 4
	snd_drum 4
	snd_drum 4
	snd_drum 4
	snd_drum 4
	snd_jump Mus04_Ch4
Mus05:
	db $0F	; channel mask
	dw Mus05_Ch1, Mus05_Ch2, Mus05_Ch3, Mus05_Ch4
Mus05_Ch1:
	snd_tempo 135
	snd_duty $80
	snd_env $A4
	snd_pitchenv SndPitchEnv_4766
Trk_5908:
	snd_note As_5, 1
	snd_note B_5, 17
	snd_note G_5, 18
	snd_note E_5, 5
	snd_note As_5, 1
	snd_note B_5, 6
	snd_len 18
	snd_hold $61
	snd_note G_5, 12
	snd_note G_5, 6
	snd_note E_5, 12
	snd_note As_5, 1
	snd_note B_5, 17
	snd_note G_5, 18
	snd_note F_5, 6
	snd_note As_5, 1
	snd_note B_5, 5
	snd_len 18
	snd_hold $61
	snd_note G_5, 12
	snd_note G_5, 6
	snd_note F_5, 12
	snd_note As_5, 1
	snd_note B_5, 17
	snd_note G_5, 18
	snd_note E_5, 6
	snd_note As_5, 1
	snd_note B_5, 5
	snd_len 18
	snd_hold $61
	snd_note G_5, 12
	snd_note G_5, 6
	snd_note E_5, 12
	snd_note F_5, 18
	snd_note A_5, 12
	snd_note C_6, 6
	snd_note E_6
	snd_note D_6
	snd_len 48
	snd_hold $64
	snd_note Ds_6, 1
	snd_note E_6, 23
	snd_note Cs_6, 12
	snd_note Gs_5, 6
	snd_note Gs_5
	snd_off
	snd_note B_5, 12
	snd_note A_5
	snd_note E_5, 11
	snd_note G_5, 7
	snd_note F_5, 24
	snd_note F_5, 6
	snd_note G_5
	snd_note A_5
	snd_note As_5
	snd_len 24
	snd_hold $60
	snd_note D_6, 6
	snd_note C_6
	snd_note As_5
	snd_note A_5
	snd_len 42
	snd_hold $5F
	snd_note Gs_5, 2
	snd_note G_5
	snd_note Fs_5
	snd_note F_5, 24
	snd_note A_5, 6
	snd_note G_5
	snd_note F_5
	snd_note E_5
	snd_len 44
	snd_hold $5A
	snd_note E_5, 2
	snd_note Ds_5
	snd_note D_5, 36
	snd_len 12
	snd_off
	snd_jump Trk_5908
Mus05_Ch3:
	snd_duty $E0
	snd_env $20
	snd_pitchenv SndPitchEnv_4766
Trk_5994:
	snd_note Fs_5, 1
	snd_note G_5, 17
	snd_note E_5, 18
	snd_note C_5, 6
	snd_note Fs_5, 1
	snd_note G_5, 5
	snd_len 18
	snd_hold $5D
	snd_note E_5, 12
	snd_note E_5, 6
	snd_note C_5, 12
	snd_note Fs_5, 1
	snd_note G_5, 17
	snd_note D_5, 18
	snd_note D_5, 6
	snd_note Fs_5, 1
	snd_note G_5, 5
	snd_len 18
	snd_hold $5D
	snd_note D_5, 12
	snd_note D_5, 6
	snd_note D_5, 12
	snd_note Fs_5, 1
	snd_note G_5, 17
	snd_note E_5, 18
	snd_note C_5, 6
	snd_note Fs_5, 1
	snd_note G_5, 5
	snd_len 18
	snd_hold $5D
	snd_note E_5, 12
	snd_note E_5, 6
	snd_note C_5, 12
	snd_note D_5, 18
	snd_note F_5, 12
	snd_note A_5, 6
	snd_note C_6
	snd_note B_5
	snd_len 18
	snd_hold $61
	snd_note As_5, 3
	snd_note A_5
	snd_note Gs_5, 24
	snd_note Gs_5, 19
	snd_note Fs_5, 2
	snd_note F_5, 3
	snd_note E_5, 24
	snd_len 18
	snd_hold $5A
	snd_note Cs_5
	snd_note A_4, 12
	snd_note C_5, 48
	snd_note D_5
	snd_note C_5
	snd_note A_4
	snd_note A_4, 24
	snd_note F_4, 6
	snd_note G_4
	snd_note A_4
	snd_note Gs_4
	snd_len 30
	snd_hold $52
	snd_len 18
	snd_off
	snd_jump Trk_5994
Mus05_Ch2:
	snd_duty $80
	snd_env $D2
	snd_pitchenv SndPitchEnv_4766
	snd_transpose $F4
Trk_5A0E:
	snd_note C_4, 12
	snd_note G_4, 6
	snd_note G_3
	snd_note G_3, 12
	snd_note G_4, 6
	snd_note C_4
	snd_note C_4, 12
	snd_note G_4, 6
	snd_note G_3
	snd_note G_3, 12
	snd_note G_4, 6
	snd_note C_4
	snd_note D_4, 12
	snd_note G_4, 6
	snd_note G_3
	snd_note G_3, 12
	snd_note G_4, 6
	snd_note D_4
	snd_note D_4, 12
	snd_note G_4, 6
	snd_note G_3
	snd_note G_3, 12
	snd_note G_4, 6
	snd_note D_4
	snd_note C_4, 12
	snd_note G_4, 6
	snd_note G_3
	snd_note G_3, 12
	snd_note G_4, 6
	snd_note C_4
	snd_note C_4, 12
	snd_note G_4, 6
	snd_note G_3
	snd_note G_3, 12
	snd_note G_4, 6
	snd_note G_3
	snd_note B_3, 12
	snd_note A_4, 6
	snd_note B_3
	snd_note B_3, 12
	snd_note A_4, 6
	snd_note B_3
	snd_note E_4, 12
	snd_note Gs_4, 6
	snd_note E_4
	snd_note E_4
	snd_note Gs_4, 12
	snd_note E_4, 6
	snd_note A_3, 12
	snd_note A_4, 6
	snd_note E_4
	snd_note E_4
	snd_note A_4, 12
	snd_note A_3, 6
	snd_note A_3, 12
	snd_note A_4, 6
	snd_note E_4
	snd_note E_4
	snd_note A_4, 12
	snd_note A_3, 6
	snd_note D_4, 12
	snd_note A_4, 6
	snd_note D_4
	snd_note D_4
	snd_note A_4, 12
	snd_note D_4, 6
	snd_note Ds_4, 12
	snd_note As_4, 6
	snd_note Ds_4
	snd_note Ds_4
	snd_note As_4, 12
	snd_note Ds_4, 6
	snd_note As_3, 12
	snd_note F_4, 6
	snd_note As_3
	snd_note As_3
	snd_note F_4, 12
	snd_note As_3, 6
	snd_note As_3, 12
	snd_note F_4, 6
	snd_note As_3
	snd_note As_3
	snd_note F_4, 12
	snd_note As_3, 6
	snd_note B_3, 12
	snd_note F_4, 6
	snd_note B_3
	snd_note B_3
	snd_note F_4, 12
	snd_note B_3, 6
	snd_note B_3, 12
	snd_note F_4, 6
	snd_note B_3
	snd_note B_3
	snd_note F_4, 12
	snd_note B_3, 3
	snd_off
	snd_jump Trk_5A0E
Mus05_Ch4:
	snd_len 12
	snd_drum 0
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_off
	snd_len 12
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_off
	snd_len 12
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_off
	snd_len 12
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_off
	snd_len 12
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_off
	snd_len 12
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_off
	snd_len 12
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_off
	snd_len 12
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_off
	snd_len 12
	snd_drum 0
	snd_len 6
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 9
	snd_drum 0
	snd_len 3
	snd_off
	snd_jump Mus05_Ch4
Mus06:
	db $0F	; channel mask
	dw Mus06_Ch1, Mus06_Ch2, Mus06_Ch3, Mus06_Ch4
Mus06_Ch1:
	snd_tempo 150
	snd_duty $80
	snd_env $A4
	snd_pitchenv SndPitchEnv_4766
	snd_note G_5, 4
	snd_note Fs_5
	snd_note A_5
	snd_note G_5, 36
	snd_note G_5, 4
	snd_note Fs_5
	snd_note A_5
	snd_note G_5, 36
	snd_note G_5, 6
	snd_note G_5, 2
	snd_note G_5, 4
	snd_note G_5
	snd_note Fs_5
	snd_note A_5
	snd_note G_5
	snd_note E_5
	snd_note C_5
	snd_note A_4
	snd_note C_5
	snd_note E_5
	snd_note G_5, 8
	snd_note Fs_5, 2
	snd_note A_5
	snd_note G_5, 8
	snd_note Fs_5, 2
	snd_note A_5
	snd_note G_5, 8
	snd_note C_6, 4
	snd_note B_5, 8
	snd_note C_6, 4
	snd_note G_5, 8
	snd_note G_5, 4
	snd_note E_6
	snd_note Ds_6
	snd_note E_6
	snd_note G_5, 8
	snd_note G_5, 4
	snd_note E_6
	snd_note C_6
	snd_note A_6
	snd_note G_6, 8
	snd_note E_6, 4
	snd_note C_6, 20
	snd_note C_6, 4
	snd_note B_5, 8
	snd_note C_6, 4
	snd_note G_5, 8
	snd_note G_5, 4
	snd_note C_6
	snd_note B_5
	snd_note C_6
	snd_note G_5, 8
	snd_note G_5, 4
	snd_note C_6
	snd_note G_5
	snd_note E_6
	snd_note D_6, 32
	snd_note D_6, 4
	snd_note Cs_6, 8
	snd_note D_6, 4
	snd_note A_5, 8
	snd_note A_5, 4
	snd_note D_6
	snd_note Cs_6
	snd_note D_6
	snd_note A_5, 8
	snd_note A_5, 4
	snd_note F_6
	snd_note D_6
	snd_note As_6
	snd_note A_6, 8
	snd_note D_6, 4
	snd_note A_5, 20
	snd_note Cs_6, 4
	snd_note D_6, 8
	snd_note E_6, 4
	snd_note F_6, 8
	snd_note D_6, 4
	snd_note A_5, 8
	snd_note C_6, 4
	snd_note B_5, 12
	snd_note A_5
	snd_note A_5, 8
	snd_note Gs_5, 4
	snd_note G_5, 20
	snd_note C_6, 4
	snd_note B_5, 8
	snd_note C_6, 4
	snd_note G_5, 8
	snd_note G_5, 4
	snd_note E_6
	snd_note Ds_6
	snd_note E_6
	snd_note G_5, 8
	snd_note G_5, 4
	snd_note E_6
	snd_note C_6
	snd_note A_6
	snd_note G_6, 8
	snd_note E_6, 4
	snd_note C_6, 20
	snd_note C_6, 4
	snd_note B_5, 8
	snd_note C_6, 4
	snd_note G_5, 8
	snd_note G_5, 4
	snd_note C_6, 20
	snd_note F_6, 4
	snd_note E_6, 8
	snd_note Ds_6, 4
	snd_note D_6, 32
	snd_note C_6, 4
	snd_note B_5, 8
	snd_note As_5, 4
	snd_note A_5, 12
	snd_note A_5
	snd_note B_5
	snd_note E_5
	snd_note A_5, 8
	snd_note Gs_5, 4
	snd_note A_5, 8
	snd_note B_5, 4
	snd_note Cs_6, 8
	snd_note A_5, 4
	snd_note D_6, 8
	snd_note E_6, 4
	snd_note F_6, 8
	snd_note Gs_5, 4
	snd_note A_5, 8
	snd_note C_6, 4
	snd_note B_5, 12
	snd_note G_5
	snd_note C_6, 9
	snd_note G_5, 1
	snd_note A_5
	snd_note B_5
	snd_note C_6, 9
	snd_note G_5, 1
	snd_note A_5
	snd_note B_5
	snd_note C_6, 4
	snd_len 20
	snd_off
	snd_end
Mus06_Ch3:
	snd_duty $E0
	snd_env $40
	snd_pitchenv SndPitchEnv_4766
	snd_transpose $F4
	snd_note B_4, 4
	snd_note As_4
	snd_note C_5
	snd_note B_4, 12
	snd_note B_4, 4
	snd_note C_5
	snd_note Cs_5
	snd_note D_5, 12
	snd_note B_4, 4
	snd_note As_4
	snd_note C_5
	snd_note B_4, 12
	snd_note B_4, 4
	snd_note C_5
	snd_note Cs_5
	snd_note D_5, 12
	snd_note B_4, 6
	snd_note B_4, 2
	snd_note B_4, 4
	snd_note B_4
	snd_note C_5
	snd_note D_5
	snd_note E_5
	snd_note C_5
	snd_note A_4
	snd_note F_4
	snd_note A_4
	snd_note C_5
	snd_note B_4, 8
	snd_note As_4, 2
	snd_note C_5
	snd_note B_4, 8
	snd_note As_4, 2
	snd_note C_5
	snd_note B_4, 8
	snd_note E_5, 4
	snd_note Ds_5, 8
	snd_note E_5, 4
	snd_note E_5
	snd_note C_5
	snd_note G_4
	snd_note C_5, 12
	snd_note E_5, 4
	snd_note C_5
	snd_note G_4
	snd_note C_5, 8
	snd_note E_5, 4
	snd_note E_6, 8
	snd_note C_6, 4
	snd_note G_5, 8
	snd_note E_5, 4
	snd_note A_5, 8
	snd_note G_5, 4
	snd_note E_5, 8
	snd_note C_5, 4
	snd_note E_5
	snd_note C_5
	snd_note G_4
	snd_note E_4, 12
	snd_note E_5, 4
	snd_note C_5
	snd_note G_4
	snd_note E_4, 12
	snd_note F_5, 8
	snd_note E_5, 4
	snd_note D_5, 8
	snd_note Cs_5, 4
	snd_note D_5, 8
	snd_note F_5, 4
	snd_note E_5, 8
	snd_note F_5, 4
	snd_note F_5
	snd_note D_5
	snd_note A_4
	snd_note D_5, 12
	snd_note F_5, 4
	snd_note D_5
	snd_note A_4
	snd_note D_5, 8
	snd_note G_5, 4
	snd_note D_6, 8
	snd_note A_5, 4
	snd_note F_5, 8
	snd_note D_5, 4
	snd_note A_5, 8
	snd_note F_5, 4
	snd_note D_5, 8
	snd_note A_4, 4
	snd_note D_6, 8
	snd_note A_5, 4
	snd_note F_5, 8
	snd_note Fs_5, 4
	snd_note G_5, 12
	snd_note F_5
	snd_note D_5, 8
	snd_note Ds_5, 4
	snd_note E_5, 20
	snd_note E_5, 4
	snd_note Ds_5, 8
	snd_note E_5, 4
	snd_note E_5
	snd_note C_5
	snd_note G_4
	snd_note C_5, 12
	snd_note E_5, 4
	snd_note C_5
	snd_note G_4
	snd_note C_5, 8
	snd_note E_5, 4
	snd_note E_6, 8
	snd_note C_6, 4
	snd_note G_5, 8
	snd_note E_5, 4
	snd_note A_5, 8
	snd_note G_5, 4
	snd_note E_5, 8
	snd_note C_5, 4
	snd_note E_5
	snd_note C_5
	snd_note G_4
	snd_note E_4, 8
	snd_note G_4, 4
	snd_note E_4, 8
	snd_note G_4, 4
	snd_note Cs_5, 8
	snd_note G_5, 4
	snd_note F_5, 8
	snd_note E_5, 4
	snd_note F_5, 8
	snd_note G_5, 4
	snd_note A_5, 8
	snd_note A_5, 4
	snd_note G_5, 8
	snd_note Fs_5, 4
	snd_note F_5, 12
	snd_note F_5, 8
	snd_note E_5, 4
	snd_note D_5, 8
	snd_note C_5, 4
	snd_note B_4, 8
	snd_note Gs_4, 4
	snd_note E_5, 8
	snd_note D_5, 4
	snd_note C_5, 8
	snd_note D_5, 4
	snd_note E_5, 8
	snd_note F_5, 4
	snd_note G_5, 8
	snd_note Cs_5, 4
	snd_note D_5, 8
	snd_note E_5, 4
	snd_note F_5, 8
	snd_note A_5, 4
	snd_note G_5, 12
	snd_note B_4, 4
	snd_note C_5
	snd_note D_5
	snd_note C_5, 9
	snd_note C_5, 1
	snd_note D_5
	snd_note Ds_5
	snd_note E_5, 9
	snd_note C_5, 1
	snd_note D_5
	snd_note Ds_5
	snd_note E_5, 4
	snd_len 20
	snd_off
	snd_end
Mus06_Ch2:
	snd_duty $80
	snd_env $D2
	snd_pitchenv SndPitchEnv_4766
	snd_transpose $F4
	snd_note G_4, 24
	snd_note G_3, 4
	snd_note Fs_3
	snd_note A_3
	snd_note G_3, 12
	snd_note G_4, 24
	snd_note G_3, 4
	snd_note Fs_3
	snd_note A_3
	snd_note G_3, 12
	snd_note G_3, 24
	snd_note G_3
	snd_note G_3, 12
	snd_note G_3
	snd_note G_3, 24
	snd_note C_4, 12
	snd_note G_3
	snd_note C_4
	snd_note G_3
	snd_note C_4
	snd_note G_3
	snd_note C_4
	snd_note G_3
	snd_note C_4
	snd_note G_3
	snd_note C_4
	snd_note G_3
	snd_note D_4
	snd_note A_3
	snd_note D_4
	snd_note A_3
	snd_note D_4
	snd_note A_3
	snd_note D_4
	snd_note A_3
	snd_note D_4
	snd_note A_3
	snd_note D_4
	snd_note A_3
	snd_note D_4
	snd_note A_3
	snd_note G_3
	snd_note B_3
	snd_note C_4
	snd_note G_3
	snd_note C_4
	snd_note G_3
	snd_note C_4
	snd_note G_3
	snd_note C_4
	snd_note G_3
	snd_note C_4
	snd_note G_3
	snd_note C_4
	snd_note G_3
	snd_note C_4
	snd_note G_3
	snd_note C_4
	snd_note A_3
	snd_note D_4
	snd_note A_3
	snd_note D_4, 8
	snd_note Cs_4, 4
	snd_note D_4, 8
	snd_note E_4, 4
	snd_note F_4, 8
	snd_note E_4, 4
	snd_note D_4, 8
	snd_note C_4, 4
	snd_note D_4, 12
	snd_note C_4, 8
	snd_note B_3, 4
	snd_note C_4, 8
	snd_note B_3, 4
	snd_note A_3, 12
	snd_note G_4, 8
	snd_note G_4, 4
	snd_note F_4, 8
	snd_note E_4, 4
	snd_note D_4, 12
	snd_note D_4
	snd_note G_4
	snd_note G_3
	snd_note C_4
	snd_note C_4
	snd_note C_4, 4
	snd_len 20
	snd_off
	snd_end
Mus06_Ch4:
	snd_len 24
	snd_drum 1
	snd_len 4
	snd_drum 4
	snd_drum 4
	snd_drum 4
	snd_len 12
	snd_drum 4
	snd_len 24
	snd_drum 1
	snd_len 4
	snd_drum 4
	snd_drum 4
	snd_drum 4
	snd_len 12
	snd_drum 4
	snd_len 24
	snd_drum 1
	snd_drum 1
	snd_len 12
	snd_drum 1
	snd_drum 1
	snd_len 24
	snd_drum 1
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_drum 4
	snd_drum 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 2
	snd_drum 4
	snd_drum 4
	snd_drum 4
	snd_drum 4
	snd_drum 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_drum 4
	snd_drum 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_drum 4
	snd_drum 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 2
	snd_drum 4
	snd_drum 4
	snd_drum 4
	snd_drum 4
	snd_drum 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_drum 4
	snd_drum 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_drum 4
	snd_drum 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 2
	snd_drum 4
	snd_drum 4
	snd_drum 4
	snd_drum 4
	snd_drum 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_drum 4
	snd_drum 4
	snd_drum 4
	snd_len 8
	snd_drum 1
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 1
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 1
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 1
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 1
	snd_len 4
	snd_drum 4
	snd_drum 4
	snd_drum 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 9
	snd_drum 1
	snd_len 1
	snd_drum 4
	snd_drum 4
	snd_drum 4
	snd_len 9
	snd_drum 4
	snd_len 1
	snd_drum 4
	snd_drum 4
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_end
Mus07:
	db $0F	; channel mask
	dw Mus07_Ch1, Mus07_Ch2, Mus07_Ch3, Mus07_Ch4
Mus07_Ch1:
	snd_tempo 160
	snd_duty $80
	snd_env $A4
	snd_pitchenv SndPitchEnv_4766
Trk_5F0A:
	snd_note D_5, 12
	snd_note Ds_5
	snd_note F_5
	snd_note As_5
	snd_len 24
	snd_hold $60
	snd_note F_5, 12
	snd_note F_5
	snd_note G_5
	snd_note A_5
	snd_note As_5
	snd_note F_5
	snd_len 24
	snd_hold $5B
	snd_note D_5, 12
	snd_note F_5
	snd_note F_5
	snd_note D_5
	snd_note F_5
	snd_note F_5
	snd_hold $5B
	snd_note G_5
	snd_note D_5, 8
	snd_note C_5, 4
	snd_note As_4, 12
	snd_note C_5
	snd_note C_5, 8
	snd_note As_4, 4
	snd_note C_5, 12
	snd_note G_5
	snd_note F_5, 24
	snd_note C_6, 8
	snd_note F_5, 12
	snd_len 4
	snd_off
	snd_jump Trk_5F0A
Mus07_Ch3:
	snd_duty $E0
	snd_env $40
	snd_pitchenv SndPitchEnv_4766
	snd_transpose $F4
Trk_5F48:
	snd_len 8
	snd_off
	snd_note F_4, 4
	snd_note As_4, 8
	snd_note F_4, 4
	snd_note As_4, 8
	snd_note F_4, 4
	snd_note D_5, 8
	snd_note F_4, 4
	snd_len 8
	snd_off
	snd_note F_4, 4
	snd_note As_4, 8
	snd_note F_4, 4
	snd_note As_4, 8
	snd_note F_4, 4
	snd_note D_5, 8
	snd_note F_4, 4
	snd_len 8
	snd_off
	snd_note G_4, 4
	snd_note As_4, 8
	snd_note G_4, 4
	snd_note As_4, 8
	snd_note G_4, 4
	snd_note Ds_5, 8
	snd_note G_4, 4
	snd_len 8
	snd_off
	snd_note F_4, 4
	snd_note As_4, 8
	snd_note F_4, 4
	snd_note As_4, 8
	snd_note F_4, 4
	snd_note D_5, 8
	snd_note F_4, 4
	snd_len 8
	snd_off
	snd_note F_4, 4
	snd_note A_4, 8
	snd_note F_4, 4
	snd_note A_4, 8
	snd_note F_4, 4
	snd_note D_5, 8
	snd_note A_4, 4
	snd_len 8
	snd_off
	snd_note A_4, 4
	snd_note As_4, 12
	snd_note A_4
	snd_note G_4
	snd_note Ds_4
	snd_note Ds_4, 8
	snd_note D_4, 4
	snd_note Ds_4, 12
	snd_note C_5, 8
	snd_note As_4, 4
	snd_note A_4, 12
	snd_note A_4, 8
	snd_note G_4, 4
	snd_note A_4, 12
	snd_note F_4, 6
	snd_off
	snd_jump Trk_5F48
Mus07_Ch2:
	snd_duty $80
	snd_env $D2
	snd_pitchenv SndPitchEnv_4766
	snd_transpose $F4
Trk_5FC2:
	snd_note As_3, 12
	snd_note As_3
	snd_note As_3, 20
	snd_note As_3, 4
	snd_len 8
	snd_off
	snd_note As_3, 12
	snd_note As_3, 4
	snd_note As_3, 24
	snd_note Ds_4, 12
	snd_note Ds_4
	snd_note Ds_4, 20
	snd_note As_3, 4
	snd_len 8
	snd_off
	snd_note As_3, 12
	snd_note As_3, 4
	snd_note As_3, 24
	snd_note D_4, 12
	snd_note D_4
	snd_note D_4, 20
	snd_note G_4, 4
	snd_len 8
	snd_off
	snd_note G_4, 12
	snd_note G_4, 4
	snd_note G_4, 24
	snd_note C_4, 12
	snd_note C_4
	snd_note C_4, 20
	snd_note F_4, 4
	snd_len 8
	snd_off
	snd_note F_4, 12
	snd_note F_4, 4
	snd_note F_4, 18
	snd_len 6
	snd_off
	snd_jump Trk_5FC2
Mus07_Ch4:
	snd_len 12
	snd_drum 5
	snd_drum 4
	snd_drum 5
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 5
	snd_len 8
	snd_off
	snd_len 4
	snd_drum 5
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 5
	snd_len 12
	snd_drum 5
	snd_drum 4
	snd_drum 5
	snd_drum 4
	snd_drum 5
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 5
	snd_len 8
	snd_off
	snd_len 4
	snd_drum 5
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 5
	snd_len 12
	snd_drum 5
	snd_drum 4
	snd_drum 5
	snd_drum 4
	snd_drum 5
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 5
	snd_len 8
	snd_off
	snd_len 4
	snd_drum 5
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 5
	snd_len 12
	snd_drum 5
	snd_drum 4
	snd_drum 5
	snd_drum 4
	snd_drum 5
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 5
	snd_len 8
	snd_off
	snd_len 4
	snd_drum 5
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 5
	snd_len 12
	snd_drum 5
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_off
	snd_jump Mus07_Ch4
Mus08:
	db $0F	; channel mask
	dw Mus08_Ch1, Mus08_Ch2, Mus08_Ch3, Mus08_Ch4
Mus08_Ch1:
	snd_tempo 140
	snd_duty $80
	snd_env $A4
	snd_pitchenv SndPitchEnv_4766
	snd_note F_6, 24
	snd_note E_6
	snd_note Ds_6, 8
	snd_note C_6, 12
	snd_note G_5, 4
	snd_note As_5, 12
	snd_note C_6
	snd_note Cs_6, 24
	snd_note C_6
	snd_note As_5, 8
	snd_note Cs_6, 40
	snd_len 8
	snd_off
	snd_note G_5, 4
	snd_note As_5, 8
	snd_note C_6, 4
	snd_note Cs_6, 8
	snd_note As_5, 12
	snd_note C_6, 4
	snd_note Cs_6, 12
	snd_note C_6, 8
	snd_note As_5, 12
	snd_note G_6
	snd_note F_6, 4
	snd_len 8
	snd_off
	snd_note C_6, 16
	snd_note Cs_6, 19
	snd_note D_6, 5
	snd_len 48
	snd_hold $64
	snd_note E_6, 12
	snd_note Ds_6, 8
	snd_note D_6, 12
	snd_note Cs_6
	snd_note C_6, 4
	snd_len 8
	snd_off
	snd_note G_6, 16
	snd_note A_6, 12
	snd_note G_6
	snd_note F_6, 8
	snd_note F_5, 4
	snd_note Fs_5, 8
	snd_note G_5, 4
	snd_note As_5, 12
	snd_note A_5, 8
	snd_note G_5, 4
	snd_len 48
	snd_hold $5D
	snd_len 8
	snd_off
	snd_note Ds_6, 16
	snd_note C_6, 12
	snd_note G_5
	snd_note As_5, 24
	snd_note C_6, 20
	snd_note As_5, 4
	snd_len 44
	snd_hold $60
	snd_len 4
	snd_off
	snd_len 48
	snd_off
	snd_end
Mus08_Ch3:
	snd_duty $E0
	snd_env $40
	snd_pitchenv SndPitchEnv_4766
	snd_transpose $F4
	snd_note Gs_5, 24
	snd_note Gs_5
	snd_note G_5, 8
	snd_note Cs_5, 12
	snd_note Ds_5, 4
	snd_note Cs_5, 12
	snd_note G_5
	snd_note Gs_5, 24
	snd_note Gs_5
	snd_note D_5, 8
	snd_note F_5, 40
	snd_len 8
	snd_off
	snd_note Ds_5, 4
	snd_note G_5, 8
	snd_note A_5, 4
	snd_note As_5, 8
	snd_note G_5, 12
	snd_note A_5, 4
	snd_note As_5, 12
	snd_note Gs_5, 8
	snd_note G_5, 12
	snd_note Cs_6
	snd_note D_6, 4
	snd_len 8
	snd_off
	snd_note Gs_5, 16
	snd_note E_5, 20
	snd_note F_5, 4
	snd_len 12
	snd_hold $5B
	snd_note G_5, 8
	snd_note Gs_5, 12
	snd_note F_5
	snd_note F_5, 4
	snd_note C_6, 12
	snd_note A_5, 8
	snd_note As_5, 12
	snd_note G_5
	snd_note A_5, 4
	snd_len 8
	snd_off
	snd_note Ds_6, 16
	snd_note C_6, 12
	snd_note Ds_6
	snd_note D_6, 8
	snd_note D_5, 4
	snd_note Cs_5, 8
	snd_note D_5, 4
	snd_note F_5, 12
	snd_note C_5, 8
	snd_note B_4, 4
	snd_len 12
	snd_hold $55
	snd_note C_5, 8
	snd_note D_5, 12
	snd_note B_4
	snd_note B_4, 4
	snd_len 8
	snd_off
	snd_note As_5, 4
	snd_note Ds_5, 8
	snd_note G_5, 4
	snd_note Ds_5, 12
	snd_note C_5
	snd_note Ds_5, 24
	snd_note Ds_5, 20
	snd_note D_5, 4
	snd_len 44
	snd_hold $58
	snd_len 4
	snd_off
	snd_len 48
	snd_off
	snd_end
Mus08_Ch2:
	snd_duty $80
	snd_env $D2
	snd_pitchenv SndPitchEnv_4766
	snd_transpose $F4
	snd_note As_3, 12
	snd_note As_3
	snd_note D_4
	snd_note D_4
	snd_note Ds_4
	snd_note Ds_4
	snd_note Ds_4, 8
	snd_note F_4, 4
	snd_note G_4, 8
	snd_note Cs_4, 4
	snd_note As_3, 12
	snd_note As_3
	snd_note As_3, 8
	snd_note As_4, 4
	snd_note As_3, 12
	snd_note As_3, 8
	snd_note As_4, 4
	snd_note Gs_4, 12
	snd_note G_4
	snd_note F_4
	snd_note Ds_4
	snd_note Ds_4
	snd_note F_4
	snd_note F_4
	snd_note G_4, 8
	snd_note Fs_4, 4
	snd_note F_4, 12
	snd_note Ds_4
	snd_note Cs_4
	snd_note As_3
	snd_note As_3
	snd_note Gs_3
	snd_note Gs_3
	snd_note As_3
	snd_note C_4
	snd_note D_4
	snd_note As_3
	snd_note C_4
	snd_note D_4
	snd_note E_4
	snd_note C_4
	snd_note F_4
	snd_note F_3
	snd_note G_3
	snd_note A_3
	snd_note As_3
	snd_note As_3
	snd_note Gs_3
	snd_note Gs_3
	snd_note G_3, 8
	snd_note G_4, 4
	snd_note G_3, 12
	snd_note F_4
	snd_note Ds_4, 8
	snd_note D_4, 4
	snd_note C_4, 12
	snd_note C_4
	snd_note D_4
	snd_note Ds_4
	snd_note F_4
	snd_note F_3
	snd_note F_3, 8
	snd_note G_3, 4
	snd_note A_3, 12
	snd_note As_3
	snd_note As_3
	snd_note Gs_3
	snd_note Gs_3
	snd_note G_3
	snd_note G_3
	snd_note F_3, 8
	snd_note F_4, 4
	snd_note Gs_3, 12
	snd_end
Mus08_Ch4:
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 7
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 13
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 7
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 1
	snd_drum 0
	snd_len 12
	snd_hold $90
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 3
	snd_len 4
	snd_drum 1
	snd_end
Mus09:
	db $0F	; channel mask
	dw Mus09_Ch1, Mus09_Ch2, Mus09_Ch3, SndNullTrack
Mus09_Ch1:
	snd_tempo 128
	snd_duty $80
	snd_env $A4
	snd_pitchenv SndPitchEnv_4766
	snd_note G_5, 6
	snd_note G_5, 2
	snd_note G_5, 4
	snd_note As_5
	snd_note G_5
	snd_note As_5
	snd_note D_6, 6
	snd_note D_6, 2
	snd_note D_6, 4
	snd_note F_6
	snd_note D_6
	snd_note F_6
	snd_note E_6
	snd_note F_6
	snd_note Fs_6
	snd_note G_6, 36
	snd_len 48
	snd_off
	snd_end
Mus09_Ch3:
	snd_duty $F0
	snd_env $40
	snd_pitchenv SndPitchEnv_4766
	snd_transpose $F4
	snd_note C_5, 6
	snd_note C_5, 2
	snd_note C_5, 4
	snd_note G_5
	snd_note C_5
	snd_note G_5
	snd_note F_5, 6
	snd_note F_5, 2
	snd_note F_5, 4
	snd_note As_5
	snd_note F_5
	snd_note As_5
	snd_note C_6
	snd_note D_6
	snd_note Ds_6
	snd_note E_6, 36
	snd_len 48
	snd_off
	snd_end
Mus09_Ch2:
	snd_duty $80
	snd_env $D2
	snd_pitchenv SndPitchEnv_4766
	snd_transpose $F4
	snd_note C_4, 6
	snd_note C_4, 2
	snd_note C_4, 4
	snd_note C_4
	snd_note C_4
	snd_note C_4
	snd_note C_4, 6
	snd_note C_4, 2
	snd_note C_4, 4
	snd_note C_4
	snd_note C_4
	snd_note C_4
	snd_note C_4
	snd_note G_4
	snd_note C_5
	snd_note C_4, 36
	snd_len 48
	snd_off
	snd_end
Mus0A:
	db $0F	; channel mask
	dw Mus0A_Ch1, Mus0A_Ch2, Mus0A_Ch3, SndNullTrack
Mus0A_Ch1:
	snd_tempo 100
	snd_duty $80
	snd_env $A4
	snd_pitchenv SndPitchEnv_4766
	snd_note E_6, 18
	snd_note Ds_6, 2
	snd_note E_6
	snd_note Ds_6
	snd_note B_5, 12
	snd_note D_6, 4
	snd_note C_6
	snd_note B_5
	snd_note A_5, 9
	snd_note A_4, 3
	snd_note A_4
	snd_len 33
	snd_off
	snd_end
Mus0A_Ch3:
	snd_duty $E0
	snd_env $40
	snd_pitchenv SndPitchEnv_4766
	snd_transpose $F4
	snd_len 36
	snd_off
	snd_note Gs_5, 4
	snd_note A_5
	snd_note E_5
	snd_note C_5, 6
	snd_len 42
	snd_off
	snd_end
Mus0A_Ch2:
	snd_duty $80
	snd_env $D2
	snd_pitchenv SndPitchEnv_4766
	snd_transpose $F4
	snd_note E_5, 18
	snd_note Ds_5, 2
	snd_note E_5
	snd_note Ds_5
	snd_note B_4, 12
	snd_note E_4, 4
	snd_note F_4
	snd_note Gs_4
	snd_note A_4, 9
	snd_note A_3, 3
	snd_note A_3
	snd_len 33
	snd_off
	snd_end
Mus0B:
	db $0F	; channel mask
	dw Mus0B_Ch1, Mus0B_Ch2, Mus0B_Ch3, SndNullTrack
Mus0B_Ch1:
	snd_tempo 80
	snd_duty $80
	snd_env $A4
	snd_pitchenv SndPitchEnv_4766
	snd_note E_5, 6
	snd_note G_5, 3
	snd_note F_5
	snd_note E_5, 6
	snd_note D_5
	snd_note E_5, 24
	snd_len 48
	snd_off
	snd_end
Mus0B_Ch3:
	snd_duty $E0
	snd_env $40
	snd_pitchenv SndPitchEnv_4766
	snd_transpose $F4
	snd_note C_5, 6
	snd_note E_5, 3
	snd_note D_5
	snd_note C_5, 6
	snd_note B_4
	snd_note B_4, 12
	snd_off
	snd_end
Mus0B_Ch2:
	snd_duty $80
	snd_env $D2
	snd_pitchenv SndPitchEnv_4766
	snd_transpose $F4
	snd_note A_4, 24
	snd_note Gs_4, 12
	snd_off
	snd_end
Mus0C:
	db $0F	; channel mask
	dw Mus0C_Ch1, Mus0C_Ch2, SndNullTrack	; mask has 4 channels: the last 1 pointer(s) are read from the track bytes below ($82F6)
Mus0C_Ch1:
	snd_tempo 130
	snd_duty $80
	snd_env $A4
	snd_pitchenv SndPitchEnv_4766
	snd_note A_5, 12
	snd_note Gs_5, 8
	snd_note A_5, 12
	snd_note C_6
	snd_note A_5, 4
	snd_note E_6, 12
	snd_note A_5, 4
	snd_len 32
	snd_off
	snd_end
Mus0C_Ch2:
	snd_duty $80
	snd_env $D2
	snd_pitchenv SndPitchEnv_4766
	snd_transpose $F4
	snd_note A_4, 8
	snd_note A_4, 4
	snd_note Gs_4, 12
	snd_note F_4
	snd_note E_4
	snd_note D_4, 4
	snd_note Ds_4
	snd_note E_4
	snd_note A_3
	snd_len 32
	snd_off
	snd_end
Mus0D:
	db $0F	; channel mask
	dw Mus0D_Ch1, Mus0D_Ch2, Mus0D_Ch3, SndNullTrack
Mus0D_Ch1:
	snd_tempo 137
	snd_duty $80
	snd_env $A4
	snd_pitchenv SndPitchEnv_4766
	snd_note G_6, 18
	snd_note E_6, 6
	snd_note F_6, 18
	snd_note A_6, 6
	snd_note G_6
	snd_note C_7
	snd_note G_6, 24
	snd_len 12
	snd_off
	snd_end
Mus0D_Ch3:
	snd_duty $E0
	snd_env $40
	snd_pitchenv SndPitchEnv_4766
	snd_transpose $F4
	snd_note E_6, 3
	snd_note C_6
	snd_note G_5
	snd_note E_5
	snd_note C_6
	snd_note G_5
	snd_note E_5
	snd_note C_5
	snd_note C_6
	snd_note F_5
	snd_note A_5
	snd_note F_5
	snd_note A_5
	snd_note C_6
	snd_note D_6
	snd_note F_6
	snd_note E_6, 6
	snd_note G_6
	snd_note E_6, 24
	snd_len 12
	snd_off
	snd_end
Mus0D_Ch2:
	snd_duty $80
	snd_env $D2
	snd_pitchenv SndPitchEnv_4766
	snd_transpose $F4
	snd_note C_4, 3
	snd_note C_5
	snd_note G_4
	snd_note C_5
	snd_note E_5
	snd_note C_5
	snd_note G_4
	snd_note E_4
	snd_note C_4
	snd_note A_4
	snd_note F_4
	snd_note A_4
	snd_note F_5
	snd_note C_5
	snd_note A_4
	snd_note F_4
	snd_note C_4
	snd_note E_4
	snd_note G_4
	snd_note C_5
	snd_note G_4
	snd_note C_5
	snd_note G_4
	snd_note E_4
	snd_note C_4, 6
	snd_len 18
	snd_off
	snd_end
Mus0E:
	db $0F	; channel mask
	dw Mus0E_Ch1, Mus0E_Ch2, SndNullTrack, SndNullTrack
Mus0E_Ch1:
	snd_tempo 130
	snd_duty $80
	snd_env $A4
	snd_pitchenv SndPitchEnv_4766
	snd_len 12
	snd_off
	snd_note As_5
	snd_note D_5
	snd_note G_5, 8
	snd_note F_5, 4
	snd_len 8
	snd_off
	snd_note As_4, 4
	snd_len 36
	snd_off
	snd_end
Mus0E_Ch2:
	snd_duty $80
	snd_env $D2
	snd_pitchenv SndPitchEnv_4766
	snd_transpose $F4
	snd_note As_3, 8
	snd_note As_3, 4
	snd_note D_4, 8
	snd_note As_3, 4
	snd_note G_4, 12
	snd_note E_4, 8
	snd_note F_4, 4
	snd_len 8
	snd_off
	snd_note As_3, 3
	snd_len 37
	snd_off
	snd_end
Mus0F:
	db $0F	; channel mask
	dw Mus0F_Ch1, Mus0F_Ch2, Mus0F_Ch3, SndNullTrack
Mus0F_Ch1:
	snd_tempo 150
	snd_duty $80
	snd_env $A4
	snd_pitchenv SndPitchEnv_4766
	snd_note D_6, 12
	snd_note Cs_6
	snd_note B_5
	snd_note B_5
	snd_note B_5, 9
	snd_note B_5, 3
	snd_note A_5, 24
	snd_len 12
	snd_off
	snd_end
Mus0F_Ch3:
	snd_duty $E0
	snd_env $40
	snd_pitchenv SndPitchEnv_4766
	snd_transpose $F4
	snd_note Fs_5, 12
	snd_note E_5
	snd_note D_5
	snd_note D_5
	snd_note D_5, 9
	snd_note D_5, 3
	snd_note Cs_5, 24
	snd_len 12
	snd_off
	snd_end
Mus0F_Ch2:
	snd_duty $80
	snd_env $D2
	snd_pitchenv SndPitchEnv_4766
	snd_transpose $F4
	snd_note D_4, 6
	snd_note A_4, 3
	snd_note A_4
	snd_note D_4, 6
	snd_note A_4, 3
	snd_note A_4
	snd_note D_4, 6
	snd_note A_4, 3
	snd_note A_4
	snd_note Gs_3, 6
	snd_note Gs_4, 3
	snd_note Gs_4
	snd_note A_3, 9
	snd_note A_4, 3
	snd_note A_3, 24
	snd_len 12
	snd_off
	snd_end
Mus10:
	db $0F	; channel mask
	dw Mus10_Ch1, Mus10_Ch2, Mus10_Ch3, SndNullTrack
Mus10_Ch1:
	snd_tempo 130
	snd_duty $80
	snd_env $A4
	snd_pitchenv SndPitchEnv_4766
	snd_note E_5, 18
	snd_note A_5, 6
	snd_note Cs_6
	snd_note A_5
	snd_note Fs_5, 18
	snd_note A_5, 6
	snd_note D_6
	snd_note B_5
	snd_note Cs_6
	snd_note E_6
	snd_note A_5, 24
	snd_len 36
	snd_off
	snd_end
Mus10_Ch3:
	snd_duty $E0
	snd_env $40
	snd_pitchenv SndPitchEnv_4766
	snd_transpose $F4
	snd_note Cs_5, 12
	snd_note E_5, 24
	snd_note D_5, 12
	snd_note Fs_5, 24
	snd_note E_5, 12
	snd_note Cs_5, 24
	snd_len 36
	snd_off
	snd_end
Mus10_Ch2:
	snd_duty $80
	snd_env $D2
	snd_pitchenv SndPitchEnv_4766
	snd_transpose $F4
	snd_note A_3, 6
	snd_note E_4
	snd_note Cs_5, 24
	snd_note A_3, 6
	snd_note Fs_4
	snd_note D_5, 24
	snd_note A_3, 12
	snd_note A_3, 24
	snd_len 36
	snd_off
	snd_end
Mus11:
	db $0F	; channel mask
	dw Mus11_Ch1, Mus11_Ch2, Mus11_Ch3, SndNullTrack
Mus11_Ch1:
	snd_tempo 100
	snd_duty $80
	snd_env $A4
	snd_pitchenv SndPitchEnv_4766
	snd_note D_6, 4
	snd_note A_5, 2
	snd_note D_6, 4
	snd_note A_5, 2
	snd_note Fs_6, 6
	snd_note Fs_6, 4
	snd_note Fs_5, 2
	snd_note G_5, 6
	snd_note G_5, 4
	snd_note B_5, 2
	snd_note A_5, 6
	snd_note A_5, 4
	snd_note D_6, 2
	snd_len 1
	snd_hold $64
	snd_len 47
	snd_off
	snd_end
Mus11_Ch3:
	snd_duty $E0
	snd_env $40
	snd_pitchenv SndPitchEnv_4766
	snd_transpose $F4
	snd_len 4
	snd_off
	snd_note D_5, 2
	snd_note Fs_5, 4
	snd_note D_5, 2
	snd_note A_4, 4
	snd_note D_5, 6
	snd_note A_4
	snd_note E_4, 2
	snd_note G_4, 4
	snd_note E_4, 2
	snd_note C_5, 6
	snd_note Cs_5, 4
	snd_note D_5, 2
	snd_len 1
	snd_hold $58
	snd_len 47
	snd_off
	snd_end
Mus11_Ch2:
	snd_duty $80
	snd_env $D2
	snd_pitchenv SndPitchEnv_4766
	snd_transpose $F4
	snd_note D_4, 6
	snd_note D_4
	snd_note C_4
	snd_note C_4
	snd_note B_3
	snd_note B_3
	snd_note A_3
	snd_note A_4, 4
	snd_note D_4, 2
	snd_len 1
	snd_hold $4C
	snd_len 47
	snd_off
	snd_end
