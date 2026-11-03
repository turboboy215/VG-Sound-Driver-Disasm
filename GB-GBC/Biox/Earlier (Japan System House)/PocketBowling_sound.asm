; Pocket Bowling (U) - sound driver A, bank $1F $4000-$79DC
; Biox / Japan System House. Disassembled for GBAudioLab\Biox.

INCLUDE "hardware.inc"
INCLUDE "bioxA_sound.inc"

; ---- RAM (identical in Noobow and Pocket Bowling) ----
DEF hSndPtrCh1    EQU $FFC0   ; track pointers, $FFFF = channel off
DEF hSndPtrCh2    EQU $FFC2
DEF hSndPtrCh3    EQU $FFC4
DEF hSndPtrCh4    EQU $FFC6
DEF hSndPtrSfx2   EQU $FFC8   ; SFX track on hardware ch2
DEF hSndPtrSfx4   EQU $FFCA   ; SFX track on hardware ch4
DEF hSndTempo     EQU $FFCC   ; TMA value for the music timer
DEF hSndUnusedCD  EQU $FFCD   ; written by $E6, never read
DEF hSndUnusedCE  EQU $FFCE   ; word written by $E6/$E7/$E8, never read
DEF hSndLastNote  EQU $FFD0   ; [6] last note byte per track (index c = 0-5)
DEF hSndLastLen   EQU $FFD6   ; [6] last length in ticks
DEF hSndLenCount  EQU $FFDC   ; [6] ticks left on the current row
DEF hSndInst      EQU $FFE2   ; [6] $E2 value (envelope sequence / wave)
DEF hSndCurMusic  EQU $FFED   ; last music id started
DEF hSndCurSfx    EQU $FFEE   ; last SFX id started
DEF wSndCh1       EQU $DE00   ; 6 track structs of $1E bytes
DEF wSndCh2       EQU $DE1E
DEF wSndCh3       EQU $DE3C
DEF wSndCh4       EQU $DE5A
DEF wSndSfx2      EQU $DE78
DEF wSndSfx4      EQU $DE96
DEF wSndLastByte  EQU $DEC8   ; last track byte parsed (checked for $F3)
DEF wSndSfxOwns   EQU $DEC9   ; $FF while the SFX track owns the channel being updated
DEF wSndSlur      EQU $DECA   ; set by $F5
DEF wSndVibNew    EQU $DECB   ; set by $E4
DEF wSndInstNew   EQU $DECC   ; set by $E2
DEF wSndChanOfs   EQU $DECD   ; word: offset of current struct from wSndCh1
DEF wSndRegOfs    EQU $DECF   ; NRx0 offset of current channel (0/5/10/15)
DEF wSndProfStart EQU $DED0   ; LY at start of the timer update
DEF wSndProfEnd   EQU $DED1   ; LY at end
DEF wSndProfAvg   EQU $DED2   ; running average of lines used
DEF wSndProfValid EQU $DED3   ; 0 until the first measurement
DEF wSndProfMax   EQU $DED4   ; maximum lines used
DEF wSndEnvPtr    EQU $DED5   ; [6 words] envelope-sequence pointers
DEF wSndEnvCount  EQU $DEE1   ; [6] envelope-sequence step counters
DEF wSndTrigger   EQU $DEE7   ; $80 when the envelope stepper rewrote NRx2
DEF wSndNewRow    EQU $DEE8   ; $FF when a new row was parsed this tick

SECTION "Sound Driver A (Pocket Bowling)", ROMX[$4000], BANK[$1F]

SndEntry_Play:
	jp Snd_Play
SndEntry_TimerUpdate:
	jp Snd_TimerUpdate
SndEntry_FrameUpdate:
	jp Snd_FrameUpdate
SndEntry_Init:
	jp Snd_Init
SndEntry_IsSfxIdle:
	jp Snd_IsSfxIdle
Snd_IsSfxIdle:
	push hl
	ld hl,hSndPtrSfx2
	ld a,[hli]
	and [hl]
	inc hl
	and [hl]
	inc hl
	and [hl]
	cp $FF
	pop hl
	ret
Snd_Play:
	di
	push af
	push hl
	push de
	push bc
	cp $0E
	jr nc,Snd_PlaySfx
	ldh [hSndCurMusic],a
	sla a
	sla a
	sla a
	ld l,a
	ld h,$00
	ld de,SndMusicTable
	add hl,de
	ld a,[hli]
	ldh [hSndPtrCh1],a
	ld a,[hli]
	ldh [hSndPtrCh1+1],a
	ld a,[hli]
	ldh [hSndPtrCh2],a
	ld a,[hli]
	ldh [hSndPtrCh2+1],a
	ld a,[hli]
	ldh [hSndPtrCh3],a
	ld a,[hli]
	ldh [hSndPtrCh3+1],a
	ld a,[hli]
	ldh [hSndPtrCh4],a
	ld a,[hli]
	ldh [hSndPtrCh4+1],a
	ld hl,hSndLenCount
	xor a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld hl,wSndCh1+$11
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld hl,wSndCh2+$11
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld hl,wSndCh3+$11
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld hl,wSndCh4+$11
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld a,$77
	ldh [rNR50],a
	ld a,$FF
	ldh [rNR51],a
	ldh [rNR52],a
	xor a
	ld [wSndProfValid],a
	ld [wSndProfMax],a
	pop bc
	pop de
	pop hl
	pop af
	ei
	ret
Snd_PlaySfx:
	ldh [hSndCurSfx],a
	sub $0E
	ld l,a
	ld h,$00
	add hl,hl
	add hl,hl
	ld de,SndSfxTable
	add hl,de
	ld a,[hli]
	ldh [hSndPtrSfx2],a
	ld a,[hli]
	ldh [hSndPtrSfx2+1],a
	ld a,[hli]
	ldh [hSndPtrSfx4],a
	ld a,[hli]
	ldh [hSndPtrSfx4+1],a
	xor a
	ldh [hSndLenCount+4],a
	ldh [hSndLenCount+5],a
	ld hl,wSndSfx2+$11
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld hl,wSndSfx4+$11
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld a,$77
	ldh [rNR50],a
	ld a,$FF
	ldh [rNR51],a
	ldh [rNR52],a
	pop bc
	pop de
	pop hl
	pop af
	ei
	ret
Snd_Unused40CC:
	push af
	push hl
	push de
	push bc
	pop bc
	pop de
	pop hl
	pop af
	ret
Snd_Init:
	di
	push af
	push hl
	push de
	push bc
	ld hl,hSndPtrCh1
	ld a,$FF
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld hl,hSndLenCount
	xor a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld a,$FF
	ldh [rNR31],a
	ld a,$00
	ldh [rNR32],a
	ld a,$40
	ldh [rNR34],a
	ld a,$40
	ldh [rTIMA],a
	ldh [rTMA],a
	ld a,$04
	ldh [rTAC],a
	ldh a,[rIE]
	or $04
	ldh [rIE],a
	pop bc
	pop de
	pop hl
	pop af
	ei
	ret
Snd_TimerUpdate:
	push af
	push hl
	push de
	push bc
	ldh a,[rLY]
	cp $70
	jr nc,Snd_TimerDefer
	ld [wSndProfStart],a
	ldh a,[hSndTempo]
	ldh [rTIMA],a
	ldh [rTMA],a
	call Snd_UpdateCh1
	call Snd_UpdateCh2
	call Snd_UpdateCh3
	call Snd_UpdateCh4
	ld a,[wSndProfStart]
	ld b,a
	ldh a,[rLY]
	ld [wSndProfEnd],a
	sub b
	ld b,a
	ld a,[wSndProfValid]
	or a
	jr z,Snd_415B
	ld a,[wSndProfAvg]
	add a,b
	srl a
	ld c,b
	ld b,a
	ld a,[wSndProfMax]
	cp c
	jr nc,Snd_4157
	ld a,c
	ld [wSndProfMax],a
Snd_4157:
	ld a,b
	ld [wSndProfAvg],a
Snd_415B:
	ld a,$FF
	ld [wSndProfValid],a
	pop bc
	pop de
	pop hl
	pop af
	ret
Snd_TimerDefer:
	ld a,$E6
	ldh [rTIMA],a
	ldh [rTMA],a
	pop bc
	pop de
	pop hl
	pop af
	ret
Snd_FrameUpdate:
	push af
	push hl
	push de
	push bc
	call Snd_UpdateSfx2
	call Snd_UpdateSfx4
	pop bc
	pop de
	pop hl
	pop af
	ret
Snd_UpdateSfx2:
	xor a
	ld [wSndSfxOwns],a
	ldh a,[hSndPtrSfx2]
	ld l,a
	ldh a,[hSndPtrSfx2+1]
	ld h,a
	and l
	cp $FF
	jr z,Snd_41BE
	ld a,$78
	ld [wSndChanOfs],a
	ld a,$00
	ld [wSndChanOfs+1],a
	ld a,$05
	ld [wSndRegOfs],a
	ld c,$04
	call Snd_ParseTrack
	ld a,l
	ldh [hSndPtrSfx2],a
	ld a,h
	ldh [hSndPtrSfx2+1],a
	and l
	cp $FF
	jr z,Snd_41BE
	ldh a,[hSndLastNote+4]
	and $0F
	cp $0D
	jr nc,Snd_41BE
	call Snd_EnvStep
	call Snd_VibratoStep
	call Snd_FreqOut
Snd_41BE:
	ret
Snd_UpdateSfx4:
	xor a
	ld [wSndSfxOwns],a
	ldh a,[hSndPtrSfx4]
	ld l,a
	ldh a,[hSndPtrSfx4+1]
	ld h,a
	and l
	cp $FF
	jr z,Snd_41F5
	ld a,$96
	ld [wSndChanOfs],a
	ld a,$00
	ld [wSndChanOfs+1],a
	ld a,$0F
	ld [wSndRegOfs],a
	ld c,$05
	call Snd_ParseTrack
	ld a,l
	ldh [hSndPtrSfx4],a
	ld a,h
	ldh [hSndPtrSfx4+1],a
	and l
	cp $FF
	jr z,Snd_41F5
	ldh a,[hSndLastNote+5]
	and $0F
	cp $0D
	jr nc,Snd_41F5
Snd_41F5:
	ret
Snd_UpdateCh1:
	xor a
	ld [wSndSfxOwns],a
	ldh a,[hSndPtrCh1]
	ld l,a
	ldh a,[hSndPtrCh1+1]
	ld h,a
	and l
	cp $FF
	jr z,Snd_423C
	ld a,$00
	ld [wSndChanOfs],a
	ld a,$00
	ld [wSndChanOfs+1],a
	ld a,$00
	ld [wSndRegOfs],a
	ld c,$00
	call Snd_ParseTrack
	ld a,l
	ldh [hSndPtrCh1],a
	ld a,h
	ldh [hSndPtrCh1+1],a
	and l
	cp $FF
	jr z,Snd_423C
	ldh a,[hSndLastNote]
	and $0F
	cp $0D
	jr nc,Snd_423C
	ld a,[wSndNewRow]
	or a
	jr nz,Snd_423B
	call Snd_EnvStep
	call Snd_VibratoStep
	call Snd_FreqOut
Snd_423B:
	ret
Snd_423C:
	xor a
	ldh [rNR12],a
	ret
Snd_UpdateCh2:
	xor a
	ld [wSndSfxOwns],a
	ldh a,[hSndPtrSfx2]
	ld l,a
	ldh a,[hSndPtrSfx2+1]
	and l
	cp $FF
	jr z,Snd_4253
	ld a,$FF
	ld [wSndSfxOwns],a
Snd_4253:
	ldh a,[hSndPtrCh2]
	ld l,a
	ldh a,[hSndPtrCh2+1]
	ld h,a
	and l
	cp $FF
	jr z,Snd_4295
	ld a,$1E
	ld [wSndChanOfs],a
	ld a,$00
	ld [wSndChanOfs+1],a
	ld a,$05
	ld [wSndRegOfs],a
	ld c,$01
	call Snd_ParseTrack
	ld a,l
	ldh [hSndPtrCh2],a
	ld a,h
	ldh [hSndPtrCh2+1],a
	and l
	cp $FF
	jr z,Snd_4295
	ldh a,[hSndLastNote+1]
	and $0F
	cp $0D
	jr nc,Snd_4295
	ld a,[wSndNewRow]
	or a
	jr nz,Snd_4294
	call Snd_EnvStep
	call Snd_VibratoStep
	call Snd_FreqOut
Snd_4294:
	ret
Snd_4295:
	ld a,[wSndSfxOwns]
	or a
	jr nz,Snd_429E
	xor a
	ldh [rNR22],a
Snd_429E:
	ret
Snd_UpdateCh3:
	xor a
	ld [wSndSfxOwns],a
	ldh a,[hSndPtrCh3]
	ld l,a
	ldh a,[hSndPtrCh3+1]
	ld h,a
	and l
	cp $FF
	jr z,Snd_42E8
	ld a,$3C
	ld [wSndChanOfs],a
	ld a,$00
	ld [wSndChanOfs+1],a
	ld a,$0A
	ld [wSndRegOfs],a
	ld c,$02
	call Snd_ParseTrack
	ld a,l
	ldh [hSndPtrCh3],a
	ld a,h
	ldh [hSndPtrCh3+1],a
	and l
	cp $FF
	jr z,Snd_42E8
	ldh a,[hSndLastNote+2]
	and $0F
	cp $0D
	jr nc,Snd_42E8
	ldh a,[hSndLenCount+2]
	cp $00
	jr z,Snd_42E8
	ld a,[wSndNewRow]
	or a
	jr nz,Snd_42E7
	call Snd_VibratoStep
	call Snd_FreqOut
Snd_42E7:
	ret
Snd_42E8:
	xor a
	ldh [rNR32],a
	ret
Snd_UpdateCh4:
	xor a
	ld [wSndSfxOwns],a
	ldh a,[hSndPtrSfx4]
	ld l,a
	ldh a,[hSndPtrSfx4+1]
	and l
	cp $FF
	jr z,Snd_42FF
	ld a,$FF
	ld [wSndSfxOwns],a
Snd_42FF:
	ldh a,[hSndPtrCh4]
	ld l,a
	ldh a,[hSndPtrCh4+1]
	ld h,a
	and l
	cp $FF
	jr z,Snd_4332
	ld a,$5A
	ld [wSndChanOfs],a
	ld a,$00
	ld [wSndChanOfs+1],a
	ld a,$0F
	ld [wSndRegOfs],a
	ld c,$03
	call Snd_ParseTrack
	ld a,l
	ldh [hSndPtrCh4],a
	ld a,h
	ldh [hSndPtrCh4+1],a
	and l
	cp $FF
	jr z,Snd_4332
	ldh a,[hSndLastNote+3]
	and $0F
	cp $0D
	jr nc,Snd_4332
	ret
Snd_4332:
	ld a,[wSndSfxOwns]
	or a
	jr nz,Snd_433B
	xor a
	ldh [rNR42],a
Snd_433B:
	ret
Snd_ParseTrack:
	xor a
	ld [wSndSlur],a
	ld [wSndVibNew],a
	ld [wSndInstNew],a
	ld [wSndTrigger],a
	ld [wSndNewRow],a
	ld a,c
	add a,$DC
	ld e,a
	ld a,$00
	adc a,$FF
	ld d,a
	ld a,[de]
	or a
	jp nz,Snd_ParseDone
	ld a,$FF
	ld [wSndNewRow],a
Snd_ParseLoop:
	ld a,l
	and h
	cp $FF
	jp z,Snd_TrackEnd
	ld a,[hl]
	cp $A0
	jr nc,Snd_439B
	ld [wSndLastByte],a
Snd_436E:
	call Snd_NoteEnvelope
	ld a,[hl]
	inc hl
	push hl
	ld b,$00
	ld hl,hSndLastNote
	add hl,bc
	ld [hl],a
	pop hl
	call Snd_NoteFreq
	call Snd_NoteVibrato
	ld a,[hl]
	cp $A0
	jr c,Snd_438B
	cp $B0
	jr c,Snd_43B9
Snd_438B:
	push hl
	ld b,$00
	ld hl,hSndLastLen
	add hl,bc
	ld a,[hl]
	ld hl,hSndLenCount
	add hl,bc
	ld [hl],a
	pop hl
	jr Snd_ParseDone
Snd_439B:
	ld a,[hl]
	cp $B0
	jr nc,Snd_43D8
	ld a,[wSndLastByte]
	cp $F3
	jr z,Snd_43B9
	call Snd_NoteEnvelope
	push hl
	ld b,$00
	ld hl,hSndLastNote
	add hl,bc
	ld a,[hl]
	pop hl
	call Snd_NoteFreq
	call Snd_NoteVibrato
Snd_43B9:
	ld a,[hl]
	ld [wSndLastByte],a
	inc hl
	push hl
	ld hl,SndLengthTable
	and $0F
	ld e,a
	ld d,$00
	add hl,de
	ld d,[hl]
	ld b,$00
	ld hl,hSndLenCount
	add hl,bc
	ld [hl],d
	ld hl,hSndLastLen
	add hl,bc
	ld [hl],d
	pop hl
	jr Snd_ParseDone
Snd_43D8:
	ld a,[hl]
	cp $E0
	jr c,Snd_TrackEnd
	inc hl
	ld [wSndLastByte],a
	push hl
	pop de
	sub $E0
	call Snd_RunCommand
	push de
	pop hl
	jp Snd_ParseLoop
Snd_ParseDone:
	push hl
	ld b,$00
	ld hl,hSndLenCount
	add hl,bc
	dec [hl]
	pop hl
	ret
Snd_TrackEnd:
	ld hl,$FFFF
	ret
Snd_RunCommand:
	ld l,a
	sla l
	ld h,$00
	push de
	ld de,SndCommandTable
	add hl,de
	ld e,[hl]
	inc hl
	ld d,[hl]
	push de
	pop hl
	pop de
	jp hl
SndCommandTable:
	dw SndCmd_End, SndCmd_Sweep, SndCmd_Inst, SndCmd_Duty
	dw SndCmd_Vibrato, SndCmd_Env, SndCmd_Tempo, SndCmd_UnusedE7
	dw SndCmd_UnusedE8, SndCmd_End, SndCmd_End, SndCmd_Pan
	dw SndCmd_End, SndCmd_End, SndCmd_Call, SndCmd_Ret
	dw SndCmd_Loop, SndCmd_Jump, SndCmd_MasterVol, SndCmd_Tie
	dw SndCmd_RawNote, SndCmd_Slur, SndCmd_End, SndCmd_End
	dw SndCmd_End, SndCmd_End, SndCmd_End, SndCmd_End
	dw SndCmd_End, SndCmd_End, SndCmd_Length, SndCmd_EndFF
SndCmd_End:
	ld de,$FFFF
	ret
SndCmd_EndFF:
	ld de,$FFFF
	ret
Snd_AddChanOfs:
	push af
	ld a,[wSndChanOfs]
	add a,l
	ld l,a
	ld a,[wSndChanOfs+1]
	adc a,h
	ld h,a
	pop af
	ret
Snd_GetReg:
	push de
	ld e,a
	ld a,[wSndRegOfs]
	add a,e
	ld c,a
	pop de
	ret
SndCmd_Sweep:
	ld a,c
	cp $00
	jr nz,Snd_4472
	ld a,[de]
	ldh [rNR10],a
Snd_4472:
	inc de
	ret
SndCmd_Inst:
	push bc
	ld a,$E2
	add a,c
	ld c,a
	ld a,[de]
	ldh [c],a
	ld a,$FF
	ld [wSndInstNew],a
	inc de
	pop bc
	ret
SndCmd_Duty:
	ld a,c
	cp $00
	jr nz,Snd_448B
	ld a,[de]
	ldh [rNR11],a
Snd_448B:
	inc de
	ret
SndCmd_Vibrato:
	ld hl,wSndCh1+$07
	call Snd_AddChanOfs
	ld a,[de]
	ld [hl],a
	inc de
	ld a,$FF
	ld [wSndVibNew],a
	ret
SndCmd_Env:
	ld hl,wSndCh1+$05
	call Snd_AddChanOfs
	ld a,[de]
	ld [hl],a
	inc de
	ret
SndCmd_Tempo:
	ld a,[de]
	or a
	jr z,Snd_44B1
	ldh [hSndTempo],a
	ldh [rTIMA],a
	ldh [rTMA],a
	xor a
Snd_44B1:
	ldh [hSndUnusedCD],a
	ldh [hSndUnusedCE],a
	ldh [hSndUnusedCE+1],a
	inc de
	ret
SndCmd_UnusedE7:
	push de
	pop hl
	xor a
	sub [hl]
	ldh [hSndUnusedCE],a
	inc hl
	ld a,$00
	sbc a,[hl]
	ldh [hSndUnusedCE+1],a
	inc de
	inc de
	ret
SndCmd_UnusedE8:
	ld a,[de]
	ldh [hSndUnusedCE],a
	inc de
	ld a,[de]
	ldh [hSndUnusedCE+1],a
	inc de
	ret
SndCmd_Pan:
	ld a,[de]
	inc de
	push de
	push bc
	ld l,a
	ld h,$00
	ld de,SndPanTable
	add hl,de
	ld d,[hl]
	ld e,$77
	ld a,c
	cp $04
	jr nz,Snd_44E6
	ld a,$01
Snd_44E6:
	cp $05
	jr nz,Snd_44EC
	ld a,$03
Snd_44EC:
	rlc e
	rlc d
	sub $01
	jr nc,Snd_44EC
	ldh a,[rNR51]
	and e
	or d
	ldh [rNR51],a
	pop bc
	pop de
	ret
SndPanTable:
	db $00, $80, $08, $88
SndCmd_Call:
	ld hl,wSndCh1+$15
	call Snd_AddChanOfs
	ld a,[hl]
	cp $04
	jp nc,SndCmd_End
	inc [hl]
	inc hl
	sla a
	add a,l
	ld l,a
	ld a,$00
	adc a,h
	ld h,a
	ld a,e
	add a,$02
	ld [hli],a
	ld a,$00
	adc a,d
	ld [hl],a
	ld a,[de]
	ld l,a
	inc de
	ld a,[de]
	ld h,a
	push hl
	pop de
	ret
SndCmd_Ret:
	ld hl,wSndCh1+$15
	call Snd_AddChanOfs
	ld a,[hl]
	or a
	jp z,SndCmd_End
	dec [hl]
	inc hl
	dec a
	sla a
	add a,l
	ld l,a
	ld a,$00
	adc a,h
	ld h,a
	ld e,[hl]
	inc hl
	ld d,[hl]
	ret
SndCmd_Loop:
	ld hl,wSndCh1+$11
	call Snd_AddChanOfs
	ld a,[de]
	inc de
	ld b,a
	ld a,[de]
	inc de
	add a,l
	ld l,a
	ld a,$00
	adc a,h
	ld h,a
	ld a,b
	cp [hl]
	jr z,Snd_455F
	inc [hl]
	ld a,[de]
	ld l,a
	inc de
	ld a,[de]
	ld h,a
	push hl
	pop de
	ret
Snd_455F:
	ld [hl],$00
	inc de
	inc de
	ret
SndCmd_Jump:
	push de
	pop hl
	ld e,[hl]
	inc hl
	ld d,[hl]
	ret
SndCmd_MasterVol:
	ld a,[de]
	inc de
	and $77
	ldh [rNR50],a
	ret
SndCmd_Tie:
	ret
SndCmd_RawNote:
	pop af
	ld a,[de]
	push de
	pop hl
	jp Snd_436E
SndCmd_Slur:
	ld [wSndSlur],a
	ret
SndCmd_Length:
	push bc
	push hl
	ld a,[de]
	ld b,$00
	ld hl,hSndLenCount
	add hl,bc
	ld [hl],a
	ld hl,hSndLastLen
	add hl,bc
	ld [hl],a
	pop hl
	pop bc
	inc de
	ret
Snd_NoteEnvelope:
	push af
	push hl
	push de
	push bc
	ld a,[wSndSfxOwns]
	ld b,a
	ld a,[wSndSlur]
	or b
	jr nz,Snd_45EE
	ld a,c
	cp $02
	jr z,Snd_NoteWave
	ld a,[wSndLastByte]
	and $0F
	cp $0D
	jr z,Snd_45EE
	ld b,$00
	ld hl,hSndInst
	add hl,bc
	ld a,[hl]
	or a
	jr z,Snd_45E1
	add a,a
	ld hl,SndEnvTable
	add a,l
	ld l,a
	ld a,$00
	adc a,h
	ld h,a
	ld e,[hl]
	inc hl
	ld d,[hl]
	inc de
	inc de
	ld hl,wSndEnvPtr
	add hl,bc
	add hl,bc
	ld [hl],e
	inc hl
	ld [hl],d
	dec de
	dec de
	ld hl,wSndEnvCount
	add hl,bc
	ld a,[de]
	ld [hl],a
	inc de
	ld a,[de]
	ld hl,wSndCh1+$05
	call Snd_AddChanOfs
	ld [hl],a
	jp Snd_45E7
Snd_45E1:
	ld hl,wSndCh1+$05
	call Snd_AddChanOfs
Snd_45E7:
	ld a,$12
	call Snd_GetReg
	ld a,[hl]
	ldh [c],a
Snd_45EE:
	pop bc
	pop de
	pop hl
	pop af
	ret
Snd_NoteWave:
	ld a,$7F
	ldh [rNR30],a
	ld a,[wSndInstNew]
	or a
	jr z,Snd_461B
	ldh a,[hSndInst+2]
	sla a
	sla a
	sla a
	sla a
	ld l,a
	ld h,$00
	ld de,SndWaveTable
	add hl,de
	ld c,$30
	ld a,$0F
Snd_4612:
	push af
	ld a,[hli]
	ldh [c],a
	inc c
	pop af
	sub $01
	jr nc,Snd_4612
Snd_461B:
	ld a,[wSndCh3+$05]
	ldh [rNR32],a
	pop bc
	pop de
	pop hl
	pop af
	ret
Snd_NoteVibrato:
	push af
	push hl
	push de
	push bc
	ld a,c
	cp $03
	jr z,Snd_467A
	cp $05
	jr z,Snd_467A
	ld a,[wSndSlur]
	or a
	jr nz,Snd_4667
	ld a,[wSndVibNew]
	or a
	jr z,Snd_466C
	ld hl,wSndCh1+$07
	call Snd_AddChanOfs
	ld a,[hl]
	sla a
	sla a
	ld e,a
	ld d,$00
	push hl
	ld hl,SndVibratoTable
	add hl,de
	pop de
	inc de
	ld a,[hli]
	ld [de],a
	inc de
	inc de
	inc de
	ld a,[hli]
	ld [de],a
	inc de
	ld [de],a
	inc de
	ld a,[hli]
	ld [de],a
	inc de
	ld a,[hli]
	ld [de],a
	xor a
	inc de
	ld [de],a
	inc de
	ld [de],a
Snd_4667:
	pop bc
	pop de
	pop hl
	pop af
	ret
Snd_466C:
	ld hl,wSndCh1+$0F
	call Snd_AddChanOfs
	xor a
	ld [hli],a
	ld [hli],a
	pop bc
	pop de
	pop hl
	pop af
	ret
Snd_467A:
	pop bc
	pop de
	pop hl
	pop af
	ret
Snd_EnvStep:
	ld b,$00
	ld hl,hSndInst
	add hl,bc
	ld a,[hl]
	or a
	jr z,Snd_46C1
	ld hl,wSndEnvCount
	add hl,bc
	ld a,[hl]
	or a
	jr nz,Snd_46BA
	ld hl,wSndEnvPtr
	add hl,bc
	add hl,bc
	ld e,[hl]
	inc hl
	ld d,[hl]
	ld a,[de]
	or a
	jr z,Snd_46C1
	ld hl,wSndEnvCount
	add hl,bc
	ld [hl],a
	inc de
	push bc
	ld a,$12
	call Snd_GetReg
	ld a,[de]
	ldh [c],a
	pop bc
	inc de
	ld hl,wSndEnvPtr
	add hl,bc
	add hl,bc
	ld [hl],e
	inc hl
	ld [hl],d
	ld a,$80
	ld [wSndTrigger],a
Snd_46BA:
	ld b,$00
	ld hl,wSndEnvCount
	add hl,bc
	dec [hl]
Snd_46C1:
	ret
Snd_VibratoStep:
	ld a,c
	cp $03
	jp z,Snd_4741
	cp $05
	jp z,Snd_4741
	ld hl,wSndCh1+$08
	call Snd_AddChanOfs
	ld a,[hl]
	or a
	jr z,Snd_46D9
	dec [hl]
	ret
Snd_46D9:
	ld de,$0003
	add hl,de
	ld a,[hli]
	or a
	jr z,Snd_46F2
	ld a,[hl]
	or a
	jr nz,Snd_46F2
	dec hl
	ld a,[hli]
	ld [hli],a
	ld a,[hli]
	cpl
	ld e,a
	ld a,[hl]
	cpl
	ld d,a
	inc de
	ld [hl],d
	dec hl
	ld [hl],e
Snd_46F2:
	ld hl,wSndCh1+$0D
	call Snd_AddChanOfs
	ld e,[hl]
	inc hl
	ld d,[hl]
	inc hl
	ld a,[hl]
	add a,e
	ld [hli],a
	ld e,a
	ld a,[hl]
	adc a,d
	ld [hl],a
	ld d,a
	sra d
	rr e
	sra d
	rr e
	sra d
	rr e
	ld hl,wSndCh1+$09
	call Snd_AddChanOfs
	ld a,e
	add a,[hl]
	ld e,a
	inc hl
	ld a,d
	adc a,[hl]
	ld d,a
	ld a,c
	ld hl,wSndCh1+$03
	cp $00
	jr z,Snd_4736
	ld hl,wSndCh2+$03
	cp $01
	jr z,Snd_4736
	ld hl,wSndCh3+$03
	cp $02
	jr z,Snd_4736
	ld hl,wSndSfx2+$03
Snd_4736:
	ld [hl],e
	inc hl
	ld [hl],d
	ld hl,wSndCh1+$0C
	call Snd_AddChanOfs
	dec [hl]
	ret
Snd_4741:
	ret
Snd_NoteFreq:
	push af
	push hl
	push de
	push bc
	ld b,a
	ld a,c
	cp $05
	jr z,Snd_4764
	cp $03
	jr nz,Snd_4772
	ld a,[wSndSfxOwns]
	or a
	jr nz,Snd_475F
	ld a,b
	swap a
	ldh [rNR43],a
	ld a,$80
	ldh [rNR44],a
Snd_475F:
	pop bc
	pop de
	pop hl
	pop af
	ret
Snd_4764:
	ld a,b
	swap a
	ldh [rNR43],a
	ld a,$80
	ldh [rNR44],a
	pop bc
	pop de
	pop hl
	pop af
	ret
Snd_4772:
	ld a,b
	sub $10
	ld b,a
	and $0F
	cp $0D
	jr nc,Snd_47DB
	ld a,b
	and $7F
	sla a
	ld l,a
	ld h,$00
	ld de,SndFreqTable
	add hl,de
	ld e,[hl]
	inc hl
	ld d,[hl]
	ld hl,wSndCh1+$09
	call Snd_AddChanOfs
	ld [hl],e
	inc hl
	ld [hl],d
	ld a,d
	and $07
	or $80
	ld d,a
	ld a,[wSndSlur]
	or a
	jr z,Snd_47A4
	ld a,d
	and $7F
	ld d,a
Snd_47A4:
	ld a,[wSndSfxOwns]
	or a
	jr nz,Snd_47BF
	ld a,c
	cp $02
	jr nz,Snd_47B3
	ld a,$FF
	ldh [rNR30],a
Snd_47B3:
	push bc
	ld a,$13
	call Snd_GetReg
	ld a,e
	ldh [c],a
	inc c
	ld a,d
	ldh [c],a
	pop bc
Snd_47BF:
	ld a,c
	ld hl,wSndCh1+$03
	cp $00
	jr z,Snd_47D8
	ld hl,wSndCh2+$03
	cp $01
	jr z,Snd_47D8
	ld hl,wSndCh3+$03
	cp $02
	jr z,Snd_47D8
	ld hl,wSndSfx2+$03
Snd_47D8:
	ld [hl],e
	inc hl
	ld [hl],d
Snd_47DB:
	pop bc
	pop de
	pop hl
	pop af
	ret
Snd_FreqOut:
	push af
	push hl
	push de
	push bc
	ld a,[wSndSfxOwns]
	or a
	jr nz,Snd_4823
	ld a,c
	ld de,wSndCh1+$03
	cp $00
	jr z,Snd_4803
	ld de,wSndCh2+$03
	cp $01
	jr z,Snd_4803
	ld de,wSndCh3+$03
	cp $02
	jr z,Snd_4803
	ld de,wSndSfx2+$03
Snd_4803:
	ld a,[de]
	ld l,a
	inc de
	ld a,[de]
	ld h,a
	cp $08
	jr c,Snd_4816
	ld hl,$07FF
	cp $80
	jr c,Snd_4816
	ld hl,$0000
Snd_4816:
	ld a,$13
	call Snd_GetReg
	ld a,l
	ldh [c],a
	inc c
	ld a,[wSndTrigger]
	or h
	ldh [c],a
Snd_4823:
	pop bc
	pop de
	pop hl
	pop af
	ret
SndFreqTable:
	dw $002C, $009D, $0107, $016B, $01CA, $0223, $0277, $02C7, $0312, $0359, $039B, $03DA, $0416, $0000, $0000, $0000
	dw $0416, $044E, $0483, $04B5, $04E5, $0511, $053B, $0563, $0589, $05AC, $05CD, $05ED, $060B, $0000, $0000, $0000
	dw $060B, $0627, $0641, $065A, $0672, $0688, $069D, $06B1, $06C4, $06D6, $06E6, $06F6, $0705, $0000, $0000, $0000
	dw $0705, $0713, $0720, $072D, $0739, $0744, $074E, $0758, $0762, $076B, $0773, $077B, $0782, $0000, $0000, $0000
	dw $0782, $0789, $0790, $0796, $079C, $07A2, $07A7, $07AC, $07B1, $07B5, $07B9, $07BD, $07C1, $0000, $0000, $0000
	dw $07C1, $07C4, $07C8, $07CB, $07CE, $07D1, $07D3, $07D6, $07D8, $07DA, $07DC, $07DE, $07E0, $0000, $0000, $0000
	dw $07E0, $07E2, $07E4
SndLengthTable:
	db $02, $03, $04, $06, $09, $08, $0C, $12, $10, $18, $24, $20, $30, $48, $40, $60
SndWaveTable:
	db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88	; wave $00
	db $88, $88, $77, $77, $66, $66, $55, $55, $44, $44, $33, $33, $22, $21, $11, $00	; wave $01
SndSfxTable:
	dw Sfx0E_Ch2, Sfx0E_Ch4	; Sfx0E
	dw Sfx0F_Ch2, Sfx0F_Ch4	; Sfx0F
	dw Sfx10_Ch2, Sfx10_Ch4	; Sfx10
	dw Sfx11_Ch2, Sfx11_Ch4	; Sfx11
	dw Sfx12_Ch2, Sfx12_Ch4	; Sfx12
	dw Sfx13_Ch2, Sfx13_Ch4	; Sfx13
	dw Sfx14_Ch2, Sfx14_Ch4	; Sfx14
	dw Sfx15_Ch2, Sfx15_Ch4	; Sfx15
	dw Sfx16_Ch2, Sfx16_Ch4	; Sfx16
	dw Sfx17_Ch2, Sfx17_Ch4	; Sfx17
	dw Sfx18_Ch2, Sfx18_Ch4	; Sfx18
	dw Sfx19_Ch2, Sfx19_Ch4	; Sfx19
	dw Sfx1A_Ch2, Sfx1A_Ch4	; Sfx1A
	dw Sfx1B_Ch2, Sfx1B_Ch4	; Sfx1B
	dw Sfx1C_Ch2, Sfx1C_Ch4	; Sfx1C
	dw Sfx1D_Ch2, Sfx1D_Ch4	; Sfx1D
	dw Sfx1E_Ch2, Sfx1E_Ch4	; Sfx1E
	dw Sfx1F_Ch2, Sfx1F_Ch4	; Sfx1F
	dw Sfx20_Ch2, Sfx20_Ch4	; Sfx20
	dw Sfx21_Ch2, Sfx21_Ch4	; Sfx21
	dw Sfx22_Ch2, Sfx22_Ch4	; Sfx22
	dw Sfx23_Ch2, Sfx23_Ch4	; Sfx23
	dw Sfx24_Ch2, Sfx24_Ch4	; Sfx24
	dw Sfx25_Ch2, Sfx25_Ch4	; Sfx25
	dw Sfx26_Ch2, Sfx26_Ch4	; Sfx26
	dw Sfx27_Ch2, Sfx27_Ch4	; Sfx27
	dw Sfx28_Ch2, Sfx28_Ch4	; Sfx28
	dw Sfx29_Ch2, Sfx29_Ch4	; Sfx29
	dw Sfx2A_Ch2, Sfx2A_Ch4	; Sfx2A
	dw Sfx2B_Ch2, Sfx2B_Ch4	; Sfx2B
	dw Sfx2C_Ch2, Sfx2C_Ch4	; Sfx2C
	dw Sfx2D_Ch2, Sfx2D_Ch4	; Sfx2D
	dw Sfx2E_Ch2, Sfx2E_Ch4	; Sfx2E
	dw Sfx2F_Ch2, Sfx2F_Ch4	; Sfx2F
	dw Sfx30_Ch2, Sfx30_Ch4	; Sfx30
	dw Sfx31_Ch2, Sfx31_Ch4	; Sfx31
	dw Sfx32_Ch2, Sfx32_Ch4	; Sfx32
	dw Sfx33_Ch2, Sfx33_Ch4	; Sfx33
	dw Sfx34_Ch2, Sfx34_Ch4	; Sfx34
	dw Sfx35_Ch2, Sfx35_Ch4	; Sfx35
	dw Sfx36_Ch2, Sfx36_Ch4	; Sfx36
	dw Sfx37_Ch2, Sfx37_Ch4	; Sfx37
	dw Sfx38_Ch2, Sfx38_Ch4	; Sfx38
	dw Sfx39_Ch2, Sfx39_Ch4	; Sfx39
	dw Sfx3A_Ch2, Sfx3A_Ch4	; Sfx3A
	dw Sfx3B_Ch2, Sfx3B_Ch4	; Sfx3B
	dw Sfx3C_Ch2, Sfx3C_Ch4	; Sfx3C
	dw Sfx3D_Ch2, Sfx3D_Ch4	; Sfx3D
	dw Sfx3E_Ch2, Sfx3E_Ch4	; Sfx3E
	dw Sfx3F_Ch2, Sfx3F_Ch4	; Sfx3F
	dw Sfx40_Ch2, Sfx40_Ch4	; Sfx40
	dw Sfx41_Ch2, Sfx41_Ch4	; Sfx41
	dw Sfx42_Ch2, Mus00_Ch1	; Sfx42
	dw Sfx43_Ch2, Sfx43_Ch4	; Sfx43
	dw Sfx44_Ch2, Sfx44_Ch4	; Sfx44
	dw Sfx45_Ch2, Sfx45_Ch4	; Sfx45
	dw Sfx46_Ch2, Sfx46_Ch4	; Sfx46
	dw Sfx47_Ch2, Sfx47_Ch4	; Sfx47
	dw Sfx48_Ch2, Sfx48_Ch4	; Sfx48
	dw Sfx49_Ch2, Sfx49_Ch4	; Sfx49
	dw Sfx4A_Ch2, Sfx4A_Ch4	; Sfx4A
	dw Sfx4B_Ch2, Sfx4B_Ch4	; Sfx4B
	dw Sfx4C_Ch2, Sfx4C_Ch4	; Sfx4C
	dw Sfx4D_Ch2, Sfx4D_Ch4	; Sfx4D
	dw Sfx4E_Ch2, Sfx4E_Ch4	; Sfx4E
	dw Sfx4F_Ch2, Sfx4F_Ch4	; Sfx4F
	dw Sfx50_Ch2, Sfx50_Ch4	; Sfx50
	dw Sfx51_Ch2, Sfx51_Ch4	; Sfx51
	dw Sfx52_Ch2, Sfx52_Ch4	; Sfx52
	dw Sfx53_Ch2, Sfx53_Ch4	; Sfx53
	dw Sfx54_Ch2, Sfx54_Ch4	; Sfx54
	dw Sfx55_Ch2, Sfx55_Ch4	; Sfx55
	dw Sfx56_Ch2, Sfx56_Ch4	; Sfx56
	dw Sfx57_Ch2, Sfx57_Ch4	; Sfx57
	dw Sfx58_Ch2, Sfx58_Ch4	; Sfx58
	dw Sfx59_Ch2, Sfx59_Ch4	; Sfx59
	dw Sfx5A_Ch2, Sfx5A_Ch4	; Sfx5A
	dw Sfx5B_Ch2, Sfx5B_Ch4	; Sfx5B
	dw Sfx5C_Ch2, Sfx5C_Ch4	; Sfx5C
	dw Sfx5D_Ch2, Sfx5D_Ch4	; Sfx5D
	dw Sfx5E_Ch2, Sfx5E_Ch4	; Sfx5E
	dw Sfx5F_Ch2, Sfx5F_Ch4	; Sfx5F
	dw Sfx60_Ch2, Sfx60_Ch4	; Sfx60
	dw Sfx61_Ch2, Sfx60_Ch4	; Sfx61
	dw Sfx62_Ch2, Sfx62_Ch4	; Sfx62
	dw Sfx63_Ch2, Sfx63_Ch4	; Sfx63
	dw Sfx64_Ch2, Sfx64_Ch4	; Sfx64
	dw Sfx65_Ch2, Sfx65_Ch4	; Sfx65
	dw Sfx66_Ch2, Sfx66_Ch4	; Sfx66
	dw Sfx67_Ch2, Sfx67_Ch4	; Sfx67
	dw Sfx68_Ch2, Sfx68_Ch4	; Sfx68
	dw Sfx69_Ch2, Sfx69_Ch4	; Sfx69
	dw Sfx60_Ch2, Sfx60_Ch4	; Sfx6A
	dw Sfx61_Ch2, Sfx60_Ch4	; Sfx6B
	dw Sfx62_Ch2, Sfx62_Ch4	; Sfx6C
	dw Sfx6D_Ch2, Sfx6D_Ch4	; Sfx6D
Sfx42_Ch2:
	snd_env $E1
	snd_note E_4, 3
	snd_note E_5
	snd_note B_4
	snd_note E_5
	snd_note E_4, 6
Mus00_Ch1:
	snd_end
Sfx43_Ch2:
	snd_env $30
	snd_note E_4, 0
	snd_env $50
	snd_note Fs_4
	snd_env $80
	snd_note Gs_4
	snd_note As_4
	snd_note C_5
	snd_note D_5
	snd_env $50
	snd_note E_5
	snd_env $30
	snd_note Fs_5
	snd_env $20
	snd_note Gs_5
Sfx43_Ch4:
	snd_end
Sfx44_Ch4:
	snd_env $30
	snd_rawnote $03, 0
	snd_env $80
	snd_rawnote $03
	snd_env $E0
	snd_rawnote $03
Sfx44_Ch2:
	snd_end
Sfx45_Ch2:
	snd_env $C7
	snd_note C_5, 1
	snd_note Cs_5
	snd_call Trk_4AE0
	snd_env $87
	snd_call Trk_4AE0
	snd_env $27
	snd_call Trk_4AE0
Sfx45_Ch4:
	snd_end
Trk_4AE0:
	snd_note D_5
	snd_note Ds_5
	snd_note Cs_5
	snd_note B_4
	snd_note A_4
	snd_ret
Sfx46_Ch4:
	snd_env $80
	snd_rawnote $07, 3
	snd_note $0D, 0
	snd_env $E3
	snd_rawnote $06, 10
Sfx46_Ch2:
	snd_end
Sfx47_Ch4:
	snd_env $E1
	snd_rawnote $15, 0
	snd_note $0D
	snd_env $80
	snd_rawnote $05
	snd_env $E1
	snd_rawnote $05, 2
Sfx47_Ch2:
	snd_end
Sfx48_Ch2:
	snd_env $E3
	snd_note D_2, 0
	snd_note A_3
	snd_note D_3
	snd_note D_4
	snd_note E_3
	snd_note E_4
	snd_note Fs_3
	snd_note Fs_4
	snd_call Trk_4B21
	snd_env $62
	snd_call Trk_4B21
	snd_env $32
	snd_call Trk_4B21
	snd_env $22
	snd_call Trk_4B21
Sfx48_Ch4:
	snd_end
Trk_4B21:
	snd_note Gs_3
	snd_note Gs_4
	snd_note Fs_3
	snd_note Fs_4
	snd_ret
Sfx49_Ch2:
	snd_env $E3
	snd_note G_4, 3
	snd_note G_3
	snd_note F_4
	snd_note E_4
	snd_note E_3
	snd_note D_4
	snd_call Trk_4B4C
	snd_env $C3
	snd_call Trk_4B4C
	snd_env $A3
	snd_call Trk_4B4C
	snd_env $83
	snd_call Trk_4B4C
	snd_env $63
	snd_call Trk_4B4C
	snd_env $43
	snd_call Trk_4B4C
Sfx49_Ch4:
	snd_end
Trk_4B4C:
	snd_note Cs_4, 0
	snd_note Cs_3
	snd_note D_4
	snd_note D_3
	snd_ret
Sfx4A_Ch2:
	snd_env $A0
Trk_4B54:
	snd_note E_7, 0
	snd_note F_7
	snd_note Fs_7
	snd_note G_7
	snd_note Gs_7
	snd_note A_7
	snd_note As_7
	snd_env $60
	snd_loop 1, 0, Trk_4B54
Sfx4A_Ch4:
	snd_end
Sfx4B_Ch2:
	snd_env $A0
	snd_note G_7, 0
	snd_note Gs_7
	snd_note A_7
	snd_note As_7
	snd_note G_7
	snd_note E_7
	snd_env $70
	snd_note Cs_7
	snd_note As_6
Sfx4B_Ch4:
	snd_end
Sfx4C_Ch2:
	snd_env $D1
	snd_note C_6, 2
	snd_note C_7, 0
	snd_note E_6, 2
	snd_note E_7, 0
	snd_note C_6, 3
Sfx4C_Ch4:
	snd_end
Sfx4D_Ch2:
	snd_env $F0
	snd_note G_2, 0
	snd_note A_2, 0
	snd_note G_2, 0
	snd_note B_2, 0
	snd_end
Sfx4D_Ch4:
	snd_env $F0
	snd_rawnote $67, 0
	snd_rawnote $66, 0
	snd_env $C0
	snd_rawnote $65, 0
	snd_rawnote $64, 0
	snd_env $80
	snd_rawnote $63, 0
	snd_rawnote $62, 0
	snd_end
Sfx4E_Ch2:
	snd_env $F0
Trk_4BA5:
	snd_note C_3, 0
	snd_note Gs_2
	snd_note Cs_3
	snd_note A_2
	snd_note D_3
	snd_note As_2
	snd_env $70
	snd_loop 1, 0, Trk_4BA5
Sfx4E_Ch4:
	snd_end
Sfx4F_Ch4:
	snd_env $80
	snd_rawnote $06, 2
	snd_note $0D, 0
	snd_env $D2
	snd_rawnote $04, 7
Sfx4F_Ch2:
	snd_end
Sfx50_Ch4:
	snd_env $F1
	snd_rawnote $16, 0
	snd_rawnote $F7
	snd_rawnote $16
	snd_rawnote $F7
Sfx50_Ch2:
	snd_end
Sfx51_Ch2:
	snd_env $E0
	snd_note F_2, 0
	snd_note F_3
	snd_note B_2
	snd_note B_3
	snd_note G_2
	snd_note G_3
	snd_note Cs_3
	snd_note Cs_4
	snd_note A_2
	snd_note A_3
	snd_note Ds_3
	snd_note Ds_4
	snd_note B_2
	snd_note B_3
	snd_note F_3
	snd_note F_4
Sfx51_Ch4:
	snd_end
Sfx52_Ch4:
	snd_env $F0
	snd_rawnote $36, 0
	snd_rawnote $34
	snd_rawnote $35
	snd_rawnote $34
	snd_rawnote $36
	snd_rawnote $35
	snd_env $A0
	snd_rawnote $62, 1
	snd_rawnote $63
	snd_env $80
	snd_rawnote $62
	snd_rawnote $63
	snd_env $60
	snd_rawnote $62
	snd_rawnote $63
Sfx52_Ch2:
	snd_end
Sfx53_Ch2:
	snd_env $F0
	snd_call Trk_4C1E
	snd_env $C0
	snd_call Trk_4C1E
	snd_env $80
	snd_call Trk_4C1E
	snd_env $40
	snd_call Trk_4C1E
	snd_env $20
	snd_call Trk_4C1E
Sfx53_Ch4:
	snd_end
Trk_4C1E:
	snd_note Ds_6, 0
	snd_note B_5
	snd_note G_5
	snd_note Ds_5
	snd_note B_4
	snd_note G_4
	snd_note Ds_4
	snd_ret
Sfx54_Ch4:
	snd_env $F1
	snd_rawnote $65, 1
	snd_rawnote $F7, 1
	snd_env $F2
	snd_rawnote $36, 9
Sfx54_Ch2:
	snd_end
Sfx55_Ch2:
	snd_env $C0
	snd_note G_2, 0
	snd_note A_2
	snd_env $90
	snd_note As_2
	snd_note B_2
	snd_env $60
	snd_note C_3
	snd_note Cs_3
	snd_env $40
	snd_note D_3
	snd_note Ds_3
	snd_env $20
	snd_note E_3
	snd_note F_3
Sfx55_Ch4:
	snd_end
Sfx56_Ch4:
	snd_env $F0
	snd_rawnote $35, 0
	snd_note $0D
	snd_env $F2
	snd_rawnote $35, 9
Sfx56_Ch2:
	snd_end
Sfx57_Ch4:
	snd_env $82
	snd_rawnote $24, 0
	snd_rawnote $34, 6
	snd_end
Sfx57_Ch2:
	snd_end
SndUnused_4C61:
	snd_env $E4
	snd_note $24, 9
	snd_end
Sfx58_Ch2:
	snd_env $C0
	snd_call Trk_4C76
	snd_env $60
	snd_call Trk_4C76
	snd_env $30
	snd_call Trk_4C76
Sfx58_Ch4:
	snd_end
Trk_4C76:
	snd_note E_3, 0
	snd_note E_2
	snd_note Gs_3
	snd_note Gs_2
	snd_note As_3
	snd_note As_2
	snd_note E_4
	snd_note E_3
	snd_note As_3
	snd_note As_2
	snd_note Gs_3
	snd_note Gs_2
	snd_ret
Sfx59_Ch2:
	snd_env $20
	snd_note As_5, 0
	snd_env $20
	snd_note B_5
	snd_env $40
	snd_note C_6
	snd_env $60
	snd_note Cs_6
	snd_env $80
	snd_note D_6
	snd_env $A0
	snd_note Ds_6
	snd_note E_6
	snd_env $80
	snd_note F_6
	snd_env $60
	snd_note Fs_6
	snd_env $40
	snd_note G_6
	snd_env $20
	snd_note Gs_6
	snd_env $50
	snd_note F_6
	snd_note Fs_6
	snd_env $30
	snd_note G_6
	snd_note Gs_6
	snd_note F_6
	snd_note Fs_6
	snd_env $20
	snd_note G_6
	snd_note Gs_6
Sfx59_Ch4:
	snd_end
Sfx5A_Ch4:
	snd_env $80
	snd_rawnote $06, 2
	snd_note $0D, 3
	snd_env $D2
	snd_rawnote $04, 9
Sfx5A_Ch2:
	snd_end
Sfx5B_Ch4:
	snd_env $74
	snd_rawnote $C1, 1
	snd_rawnote $61, 6
	snd_jump Sfx5B_Ch4
Sfx5B_Ch2:
	snd_end
Sfx5C_Ch4:
	snd_env $82
	snd_rawnote $64, 4
	snd_rawnote $34, 9
Sfx5C_Ch2:
	snd_end
Sfx5D_Ch4:
	snd_env $82
	snd_rawnote $03, 4
	snd_rawnote $03, 9
Sfx5D_Ch2:
	snd_end
Sfx5E_Ch2:
	snd_env $F0
	snd_note G_2, 0
	snd_note A_2, 0
	snd_note G_2, 0
	snd_note B_2, 0
	snd_note G_2, 0
	snd_note C_3, 0
	snd_end
Sfx5E_Ch4:
	snd_env $F0
	snd_rawnote $67, 1
	snd_rawnote $66, 1
	snd_env $C0
	snd_rawnote $65, 1
	snd_rawnote $64, 1
	snd_env $80
	snd_rawnote $63, 1
	snd_rawnote $62, 1
	snd_end
Sfx5F_Ch2:
	snd_env $E1
	snd_note E_5, 3
	snd_note C_5
Sfx5F_Ch4:
	snd_end
Sfx60_Ch2:
	snd_env $E2
	snd_note G_4, 0
	snd_note A_4
	snd_note B_4
	snd_note C_5, 3
	snd_note G_4
	snd_note C_5
	snd_note E_5
	snd_note C_5
	snd_note E_5
	snd_note G_5
	snd_note E_5
	snd_jump Trk_4D23
Sfx61_Ch2:
	snd_env $E2
	snd_note C_5, 3
	snd_note G_4
Trk_4D23:
	snd_note C_5
	snd_note E_5
	snd_note C_5
	snd_note E_5
	snd_note G_5
	snd_env $01
	snd_note G_5
	snd_env $E2
	snd_note G_5
	snd_note G_5, 6
Sfx60_Ch4:
	snd_end
Sfx62_Ch2:
	snd_env $E2
	snd_note G_5, 3
	snd_note E_5
	snd_note Cs_5
	snd_note B_4
	snd_note As_4, 6
Sfx62_Ch4:
	snd_end
Sfx63_Ch4:
	snd_env $D1
	snd_rawnote $34, 7
Sfx63_Ch2:
	snd_end
Sfx64_Ch2:
	snd_env $E2
	snd_note G_4, 3
	snd_note C_5
	snd_note E_5
	snd_note G_5
	snd_end
Sfx64_Ch4:
	snd_env $D1
	snd_rawnote $34, 7
Sfx65_Ch4:
	snd_end
Sfx65_Ch2:
	snd_env $42
Trk_4D51:
	snd_note C_2, 0
	snd_note Cs_2
	snd_note D_2
	snd_note Ds_2
	snd_note E_2
	snd_jump Trk_4D51
Sfx66_Ch2:
	snd_env $E1
	snd_note F_5, 0
	snd_note F_6, 4
Sfx66_Ch4:
	snd_end
Sfx67_Ch2:
	snd_env $E0
	snd_note E_5, 3
	snd_note C_5
	snd_env $00
	snd_note E_5, 0
Sfx67_Ch4:
	snd_end
Sfx68_Ch2:
	snd_env $E0
	snd_note E_2, 0
	snd_note E_3
	snd_note Fs_2
	snd_note Fs_3
	snd_note Gs_2
	snd_note Gs_3
Sfx68_Ch4:
	snd_end
Sfx69_Ch4:
	snd_env $56
	snd_rawnote $02, 7
	snd_env $30
	snd_rawnote $03, 12
	snd_env $20
	snd_rawnote $03, 12
	snd_jump Sfx69_Ch4
Sfx69_Ch2:
	snd_end
Sfx6D_Ch2:
	snd_env $E0
	snd_note C_4, 1
	snd_note Ds_4
	snd_note C_4
	snd_note F_4
	snd_note C_4
	snd_note Fs_4
	snd_note C_4
	snd_note F_4
	snd_note C_4
	snd_note Fs_4
Sfx6D_Ch4:
	snd_end
Sfx0E_Ch2:
	snd_end
Sfx0E_Ch4:
	snd_env $7F
	snd_note $35, 1
	snd_note $40
	snd_note $29
	snd_note $34
	snd_note $0D, 6
	snd_note $31, 1
	snd_note $35
	snd_note $25
	snd_note $3B
	snd_end
Sfx0F_Ch4:
	snd_end
Sfx0F_Ch2:
	snd_env $7F
	snd_note F_4, 1
	snd_note G_3
	snd_note REST
	snd_note G_3
	snd_note A_3
	snd_note REST
	snd_note Gs_3
	snd_note A_3
	snd_note REST
	snd_note G_3
	snd_end
Sfx10_Ch4:
	snd_end
Sfx10_Ch2:
	snd_env $50
	snd_note Cs_5, 3
	snd_note Gs_5
	snd_note F_5
	snd_note Cs_6
	snd_note F_6
	snd_note Cs_6
	snd_note Gs_6, 6
	snd_end
Sfx11_Ch4:
	snd_end
Sfx11_Ch2:
	snd_env $50
	snd_note G_4, 3
	snd_note E_4
	snd_note Cs_4
	snd_note REST
	snd_note G_3
	snd_note REST
	snd_note G_3, 4
	snd_end
Sfx12_Ch4:
	snd_end
Sfx12_Ch2:
	snd_env $50
	snd_note G_4, 5
	snd_note Cs_5, 2
	snd_note G_5
	snd_note C_4, 5
	snd_end
Sfx13_Ch4:
	snd_end
Sfx13_Ch2:
	snd_env $50
	snd_note D_5, 2
	snd_note D_4
	snd_note D_5, 3
	snd_note D_4, 2
	snd_note D_5
	snd_note D_4
	snd_note D_5
	snd_note D_4
	snd_note D_5, 1
	snd_note D_4, 0
	snd_note D_5, 1
	snd_note D_4
	snd_note D_5, 0
	snd_note D_4
	snd_note D_5
	snd_note D_4
	snd_note D_5
	snd_note D_4
	snd_note D_5, 1
	snd_note D_4, 2
	snd_note D_5
	snd_note D_4
	snd_note D_5
	snd_note D_4, 3
	snd_note D_5
	snd_note D_4, 2
	snd_end
Sfx14_Ch4:
	snd_end
Sfx14_Ch2:
	snd_env $50
	snd_note Fs_4, 1
	snd_note As_4
	snd_note Fs_4
	snd_note As_4
	snd_note Fs_4
	snd_note Cs_5
	snd_note Fs_4
	snd_note Ds_5
	snd_note Fs_4
	snd_note Fs_5
	snd_note Fs_4
	snd_note B_5
	snd_note Fs_4
	snd_note Fs_6
	snd_note Fs_4
	snd_note Cs_7
	snd_end
Sfx15_Ch4:
	snd_end
Sfx15_Ch2:
	snd_env $50
	snd_note Fs_4, 1
	snd_note Cs_7
	snd_note Fs_4
	snd_note Fs_6
	snd_note Fs_4
	snd_note B_5
	snd_note Fs_4
	snd_note Fs_5
	snd_note Fs_4
	snd_note Ds_5
	snd_note Fs_4
	snd_note Cs_5
	snd_note Fs_4
	snd_note As_4
	snd_note Fs_4
	snd_note As_4
	snd_end
Sfx16_Ch4:
	snd_end
Sfx16_Ch2:
	snd_env $7F
	snd_note C_4, 4
	snd_note Cs_4, 1
	snd_note D_4
	snd_note Ds_4
	snd_note F_4
	snd_note Cs_5
	snd_note E_5, 3
	snd_note REST, 4
	snd_note B_3, 1
	snd_note Gs_3
	snd_note F_3
	snd_note D_4
	snd_note REST, 3
	snd_note B_3, 1
	snd_note D_4
	snd_note Gs_3
	snd_note REST
	snd_note B_3
	snd_note Cs_4
	snd_note REST
	snd_note C_4
	snd_end
Sfx17_Ch2:
	snd_end
Sfx17_Ch4:
	snd_env $7F
	snd_note $31, 3
	snd_note $26
	snd_note $24
	snd_note $31
	snd_note $26
	snd_note $24, 4
	snd_note $30, 3
	snd_note $26
	snd_note $24, 4
	snd_note $30, 3
	snd_note $26
	snd_note $24, 6
	snd_note $2B, 3
	snd_note $25
	snd_note $24, 6
	snd_note $2B, 3
	snd_note $25
	snd_note $23, 6
	snd_tie
	snd_len 1
	snd_note $2A, 3
	snd_note $25
	snd_note $23, 6
	snd_tie
	snd_len 1
	snd_note $2A, 3
	snd_note $24
	snd_note $23, 7
	snd_note $29, 3
	snd_note $24
	snd_note $22, 7
	snd_note $29, 3
	snd_note $23
	snd_note $22, 7
	snd_note $0D, 1
	snd_note $28, 3
	snd_note $23
	snd_note $21, 7
	snd_note $0D, 1
	snd_note $28, 3
	snd_note $23
	snd_note $21, 7
	snd_note $0D, 3
	snd_note $27, 4
	snd_note $23
	snd_note $21, 9
	snd_note $27, 4
	snd_note $23
	snd_tie
	snd_note $23, 1
	snd_note $20, 9
	snd_tie
	snd_len 1
	snd_note $26, 4
	snd_note $23, 6
	snd_note $20, 9
	snd_tie
	snd_len 1
	snd_note $26, 4
	snd_note $23
	snd_tie
	snd_note $23, 1
	snd_note $20, 13
	snd_tie
	snd_len 7
	snd_end
Sfx18_Ch4:
	snd_end
Sfx18_Ch2:
	snd_env $7F
	snd_note C_5, 1
	snd_note E_4, 3
	snd_note As_4, 1
	snd_note REST
	snd_note Cs_5, 3
	snd_end
Sfx19_Ch2:
	snd_end
Sfx19_Ch4:
	snd_env $7F
	snd_note $21, 1
	snd_note $26
	snd_note $33, 3
	snd_note $1A, 1
	snd_note $23
	snd_note $38
	snd_note $32, 4
	snd_note $21, 1
	snd_note $39
	snd_note $30, 4
	snd_note $23, 1
	snd_note $2A
	snd_note $31, 4
	snd_note $23, 1
	snd_note $22
	snd_note $3A
	snd_note $31, 6
	snd_note $23, 1
	snd_note $3B
	snd_note $30, 4
	snd_tie
	snd_len 3
	snd_note $0D, 1
	snd_note $23
	snd_note $30, 4
	snd_note $0D, 1
	snd_note $23
	snd_note $38
	snd_note $22
	snd_note $0D, 6
	snd_note $30, 9
	snd_note $0D, 3
	snd_note $21, 1
	snd_note $20
	snd_note $0D, 3
	snd_note $30, 4
	snd_tie
	snd_len 9
	snd_tie
	snd_len 3
	snd_end
Sfx1A_Ch2:
	snd_end
Sfx1A_Ch4:
	snd_env $7F
	snd_note $21, 1
	snd_note $26
	snd_note $32, 4
	snd_note $21, 1
	snd_note $26
	snd_note $40
	snd_note $32, 6
	snd_note $21, 1
	snd_note $41
	snd_note $33, 6
	snd_tie
	snd_len 1
	snd_note $1A
	snd_note $1B
	snd_note $0D, 3
	snd_note $33, 6
	snd_note $0D, 3
	snd_note $22, 1
	snd_note $25
	snd_note $0D
	snd_note $40
	snd_note $0D
	snd_note $31, 3
	snd_note $0D, 4
	snd_note $34, 1
	snd_note $35
	snd_note $0D, 3
	snd_note $30, 9
	snd_note $0D, 3
	snd_note $22, 1
	snd_note $0D, 4
	snd_note $2B, 7
	snd_tie
	snd_len 1
	snd_tie
	snd_len 7
	snd_end
Sfx1B_Ch2:
	snd_end
Sfx1B_Ch4:
	snd_env $7F
	snd_note $27, 1
	snd_note $2B
	snd_note $28
	snd_note $20
	snd_note $0D
	snd_note $33, 6
	snd_note $0D, 3
	snd_note $29, 1
	snd_note $2A
	snd_note $24
	snd_note $25
	snd_note $22
	snd_note $37, 9
	snd_note $0D, 6
	snd_note $25, 1
	snd_note $26
	snd_note $2A
	snd_note $2B
	snd_note $27
	snd_note $28
	snd_note $33, 10
	snd_end
Sfx1C_Ch2:
	snd_end
Sfx1C_Ch4:
	snd_env $7F
	snd_note $27, 1
	snd_note $2B
	snd_note $28
	snd_note $23
	snd_note $20
	snd_note $0D
	snd_note $34, 9
	snd_tie
	snd_len 1
	snd_end
Sfx1D_Ch4:
	snd_end
Sfx1D_Ch2:
	snd_env $7F
	snd_note D_5, 1
	snd_note C_5
	snd_note Cs_5
	snd_note REST
	snd_note B_5
	snd_note C_6
	snd_end
Sfx1E_Ch4:
	snd_end
Sfx1E_Ch2:
	snd_env $7F
	snd_note D_4, 1
	snd_note Ds_4
	snd_note C_4
	snd_note REST, 3
	snd_note Fs_4, 1
	snd_note F_4, 3
	snd_note REST
	snd_note As_3, 1
	snd_note A_3, 3
	snd_note Gs_3, 1
	snd_note G_3, 3
	snd_end
Sfx1F_Ch2:
	snd_end
Sfx1F_Ch4:
	snd_env $7F
	snd_note $33, 1
	snd_note $35
	snd_note $2B
	snd_note $28
	snd_note $0D, 4
	snd_note $33, 1
	snd_note $34
	snd_note $29
	snd_note $26
	snd_note $0D, 6
	snd_note $31, 1
	snd_note $32
	snd_note $28
	snd_note $29
	snd_note $25
	snd_note $0D, 7
	snd_note $30, 1
	snd_note $31
	snd_note $29
	snd_note $27
	snd_note $24, 3
	snd_tie
	snd_len 1
	snd_tie
	snd_len 1
	snd_note $0D, 6
	snd_note $2B, 1
	snd_note $30
	snd_note $28
	snd_note $26
	snd_note $23, 4
	snd_tie
	snd_len 1
	snd_note $0D, 7
	snd_note $2A, 1
	snd_note $2B
	snd_note $27
	snd_note $25
	snd_note $22, 4
	snd_tie
	snd_len 1
	snd_note $0D, 6
	snd_note $0D
	snd_note $28, 1
	snd_note $29
	snd_note $25
	snd_note $23
	snd_note $20, 6
	snd_note $0D, 7
	snd_note $26, 1
	snd_note $28
	snd_note $24
	snd_note $22
	snd_note $1B, 6
	snd_note $0D, 7
	snd_note $0D, 4
	snd_note $26, 1
	snd_note $28
	snd_note $24
	snd_note $22, 3
	snd_note $1B, 7
	snd_tie
	snd_len 3
	snd_note $0D, 9
	snd_note $26, 1
	snd_note $28
	snd_note $24, 3
	snd_note $22
	snd_note $1B
	snd_tie
	snd_note $1B, 6
	snd_note $0D, 10
	snd_note $25, 3
	snd_note $28
	snd_note $24
	snd_note $22
	snd_note $1B, 9
	snd_tie
	snd_len 1
	snd_tie
	snd_len 1
	snd_note $0D, 10
	snd_note $26, 3
	snd_note $28
	snd_note $24
	snd_note $22
	snd_note $1B, 9
	snd_tie
	snd_len 1
	snd_end
Sfx20_Ch4:
	snd_end
Sfx20_Ch2:
	snd_env $50
	snd_note C_4, 1
	snd_note E_4
	snd_note C_5
	snd_note E_5
	snd_note C_6
	snd_note E_6, 3
	snd_note Cs_4, 1
	snd_note F_4
	snd_note Cs_5
	snd_note F_5
	snd_note Cs_6
	snd_note F_6, 3
	snd_note D_4, 1
	snd_note Fs_4
	snd_note D_5
	snd_note Fs_5
	snd_note D_6
	snd_note Fs_6, 4
	snd_end
Sfx21_Ch4:
	snd_end
Sfx21_Ch2:
	snd_env $50
	snd_note C_5, 3
	snd_note Ds_4
	snd_note REST
	snd_note Ds_5, 1
	snd_note F_5
	snd_note G_5
	snd_note As_5
	snd_note D_6
	snd_end
Sfx22_Ch4:
	snd_end
Sfx22_Ch2:
	snd_env $50
	snd_note D_4, 1
	snd_note Fs_4
	snd_end
Sfx23_Ch4:
	snd_end
Sfx23_Ch2:
	snd_env $50
	snd_note E_4, 1
	snd_note Fs_4
	snd_end
Sfx24_Ch4:
	snd_end
Sfx24_Ch2:
	snd_env $50
	snd_note D_4, 1
	snd_note G_4
	snd_end
Sfx25_Ch4:
	snd_end
Sfx25_Ch2:
	snd_env $50
	snd_note E_4, 1
	snd_note G_4
	snd_end
Sfx26_Ch4:
	snd_end
Sfx26_Ch2:
	snd_env $50
	snd_note D_4, 1
	snd_note G_4
	snd_end
Sfx27_Ch4:
	snd_end
Sfx27_Ch2:
	snd_env $50
	snd_note E_4, 1
	snd_note G_4
	snd_end
Sfx28_Ch4:
	snd_end
Sfx28_Ch2:
	snd_env $50
	snd_note D_4, 1
	snd_note Gs_4
	snd_end
Sfx29_Ch4:
	snd_end
Sfx29_Ch2:
	snd_env $50
	snd_note E_4, 1
	snd_note A_4
	snd_end
Sfx2A_Ch4:
	snd_end
Sfx2A_Ch2:
	snd_env $50
	snd_note D_4, 1
	snd_note As_4
	snd_end
Sfx2B_Ch4:
	snd_end
Sfx2B_Ch2:
	snd_env $50
	snd_note E_4, 1
	snd_note C_5
	snd_end
Sfx2C_Ch4:
	snd_end
Sfx2C_Ch2:
	snd_env $50
	snd_note D_4, 1
	snd_note D_5
	snd_end
Sfx2D_Ch4:
	snd_end
Sfx2D_Ch2:
	snd_env $50
	snd_note E_4, 1
	snd_note E_5
	snd_end
Sfx2E_Ch4:
	snd_end
Sfx2E_Ch2:
	snd_env $50
	snd_note D_4, 1
	snd_note Fs_5
	snd_end
Sfx2F_Ch4:
	snd_end
Sfx2F_Ch2:
	snd_env $50
	snd_note E_4, 1
	snd_note Gs_5
	snd_end
Sfx30_Ch4:
	snd_end
Sfx30_Ch2:
	snd_env $50
	snd_note D_4, 1
	snd_note C_6
	snd_end
Sfx31_Ch4:
	snd_end
Sfx31_Ch2:
	snd_env $50
	snd_note E_4, 1
	snd_note E_6
	snd_end
Sfx32_Ch4:
	snd_end
Sfx32_Ch2:
	snd_env $50
	snd_note C_5, 4
	snd_note Cs_5, 1
	snd_end
Sfx33_Ch4:
	snd_end
Sfx33_Ch2:
	snd_env $50
	snd_note D_5, 1
	snd_note E_5
	snd_note Fs_5
	snd_note C_6
	snd_end
Sfx34_Ch4:
	snd_end
Sfx34_Ch2:
	snd_env $50
	snd_note C_5, 3
	snd_note Cs_5, 1
	snd_note D_5
	snd_end
Sfx35_Ch4:
	snd_end
Sfx35_Ch2:
	snd_env $50
	snd_note Ds_5, 1
	snd_note F_5
	snd_note G_5
	snd_note C_6
	snd_end
Sfx36_Ch4:
	snd_end
Sfx36_Ch2:
	snd_env $50
	snd_note C_5, 1
	snd_note Cs_5
	snd_note D_5
	snd_note Ds_5
	snd_end
Sfx37_Ch4:
	snd_end
Sfx37_Ch2:
	snd_env $50
	snd_note E_5, 1
	snd_note Fs_5
	snd_note Gs_5
	snd_note C_6
	snd_end
Sfx38_Ch4:
	snd_end
Sfx38_Ch2:
	snd_env $50
	snd_note C_5, 1
	snd_note Cs_5
	snd_note D_5
	snd_note E_5
	snd_end
Sfx39_Ch4:
	snd_end
Sfx39_Ch2:
	snd_env $50
	snd_note Fs_5, 1
	snd_note G_5
	snd_note A_5
	snd_note C_6
	snd_end
Sfx3A_Ch4:
	snd_end
Sfx3A_Ch2:
	snd_env $50
	snd_note C_5, 1
	snd_note D_5
	snd_note E_5
	snd_note F_5
	snd_end
Sfx3B_Ch4:
	snd_end
Sfx3B_Ch2:
	snd_env $50
	snd_note G_5, 1
	snd_note A_5
	snd_note As_5
	snd_note C_6
	snd_end
Sfx3C_Ch4:
	snd_end
Sfx3C_Ch2:
	snd_env $50
	snd_note C_5, 1
	snd_note D_5
	snd_note E_5
	snd_note Fs_5
	snd_end
Sfx3D_Ch4:
	snd_end
Sfx3D_Ch2:
	snd_env $50
	snd_note A_5, 1
	snd_note As_5
	snd_note B_5
	snd_note C_6
	snd_end
Sfx3E_Ch4:
	snd_end
Sfx3E_Ch2:
	snd_env $50
	snd_note C_5, 1
	snd_note E_5
	snd_note Fs_5
	snd_note G_5
	snd_end
Sfx3F_Ch4:
	snd_end
Sfx3F_Ch2:
	snd_env $50
	snd_note As_5, 1
	snd_note B_5
	snd_note C_6
	snd_note Cs_6
	snd_end
Sfx40_Ch4:
	snd_end
Sfx40_Ch2:
	snd_env $50
	snd_note C_5, 1
	snd_note F_5
	snd_note G_5
	snd_note A_5
	snd_end
Sfx41_Ch4:
	snd_end
Sfx41_Ch2:
	snd_env $50
	snd_note B_5, 1
	snd_note C_6
	snd_note Cs_6
	snd_note D_6
	snd_end
SndEnvTable::	; (empty - Pocket Bowling has no envelope sequences)
SndVibratoTable::	; (empty - Pocket Bowling has no vibrato table)
SndMusicTable:
	dw Mus00_Ch1, Mus00_Ch1, Mus00_Ch1, Mus00_Ch1	; Mus00
	dw Mus01_Ch1, Mus01_Ch2, Mus01_Ch3, Mus01_Ch4	; Mus01
	dw Mus02_Ch1, Mus02_Ch2, Mus02_Ch3, Mus02_Ch4	; Mus02
	dw Mus03_Ch1, Mus03_Ch2, Mus00_Ch1, Mus00_Ch1	; Mus03
	dw Mus04_Ch1, Mus04_Ch2, Mus04_Ch3, Mus04_Ch4	; Mus04
	dw Mus05_Ch1, Mus05_Ch2, Mus05_Ch3, Mus00_Ch1	; Mus05
	dw Mus06_Ch1, Mus06_Ch2, Mus06_Ch3, Mus06_Ch4	; Mus06
	dw Mus07_Ch1, Mus07_Ch2, Mus07_Ch3, Mus00_Ch1	; Mus07
	dw Mus08_Ch1, Mus08_Ch2, Mus00_Ch1, Mus00_Ch1	; Mus08
	dw Mus09_Ch1, Mus09_Ch2, Mus09_Ch3, Mus00_Ch1	; Mus09
	dw Mus0A_Ch1, Mus0A_Ch2, Mus0A_Ch3, Mus0A_Ch4	; Mus0A
	dw Mus0B_Ch1, Mus0B_Ch2, Mus0B_Ch3, Mus0B_Ch4	; Mus0B
	dw Mus0C_Ch1, Mus0C_Ch2, Mus0C_Ch3, Mus0C_Ch4	; Mus0C
	dw Mus0D_Ch1, Mus0D_Ch2, Mus0D_Ch3, Mus0D_Ch4	; Mus0D
Mus01_Ch1:
	snd_tempo $D8
	snd_duty $40
	snd_jump Trk_5269
Mus01_Ch2:
	snd_jump Trk_5393
Mus01_Ch3:
	snd_jump Trk_54F5
Mus01_Ch4:
	snd_jump Trk_5788
Mus02_Ch1:
	snd_tempo $D8
	snd_duty $40
	snd_jump Trk_58CC
Mus02_Ch2:
	snd_jump Trk_599D
Mus02_Ch3:
	snd_jump Trk_5A91
Mus02_Ch4:
	snd_jump Trk_5BA3
Mus03_Ch1:
	snd_tempo $9E
	snd_duty $40
	snd_jump Trk_5CC1
Mus03_Ch2:
	snd_jump Trk_5DCC
	dw Mus00_Ch1, Mus00_Ch1	; orphan header bytes (unreferenced)
Mus04_Ch1:
	snd_tempo $D8
	snd_duty $40
	snd_jump Trk_5E57
Mus04_Ch2:
	snd_jump Trk_5EAA
Mus04_Ch3:
	snd_jump Trk_5ED9
Mus04_Ch4:
	snd_jump Trk_5EF7
Mus05_Ch1:
	snd_tempo $D8
	snd_duty $40
	snd_jump Trk_5F72
Mus05_Ch2:
	snd_jump Trk_5FC0
Mus05_Ch3:
	snd_jump Trk_6032
Mus06_Ch1:
	snd_tempo $D8
	snd_duty $40
	snd_jump Trk_606A
Mus06_Ch2:
	snd_jump Trk_61B0
Mus06_Ch3:
	snd_jump Trk_62B2
Mus06_Ch4:
	snd_jump Trk_641D
Mus07_Ch1:
	snd_tempo $D8
	snd_duty $40
	snd_jump Trk_6535
Mus07_Ch2:
	snd_jump Trk_655D
Mus07_Ch3:
	snd_jump Trk_6581
Mus08_Ch1:
	snd_tempo $D8
	snd_duty $40
	snd_jump Trk_65A8
Mus08_Ch2:
	snd_jump Trk_65E6
Mus09_Ch1:
	snd_tempo $D8
	snd_duty $40
	snd_jump Trk_661D
Mus09_Ch2:
	snd_jump Trk_664B
Mus09_Ch3:
	snd_jump Trk_666D
Mus0A_Ch1:
	snd_tempo $D8
	snd_duty $40
	snd_jump Trk_667C
Mus0A_Ch2:
	snd_jump Trk_66AB
Mus0A_Ch3:
	snd_jump Trk_66D5
Mus0A_Ch4:
	snd_jump Trk_6702
Mus0B_Ch1:
	snd_tempo $D8
	snd_duty $40
	snd_jump Trk_672E
Mus0B_Ch2:
	snd_jump Trk_6766
Mus0B_Ch3:
	snd_jump Trk_679C
Mus0B_Ch4:
	snd_jump Trk_67BA
Mus0C_Ch1:
	snd_tempo $D8
	snd_duty $40
	snd_jump Trk_67EF
Mus0C_Ch2:
	snd_jump Trk_682C
Mus0C_Ch3:
	snd_jump Trk_6859
Mus0C_Ch4:
	snd_jump Trk_6895
Mus0D_Ch1:
	snd_tempo $D8
	snd_duty $40
	snd_jump Trk_68F4
Mus0D_Ch2:
	snd_jump Trk_699F
Mus0D_Ch3:
	snd_jump Trk_6ABD
Mus0D_Ch4:
	snd_jump Trk_6B84
Trk_5269:
	snd_tempo $C6
	snd_env $00
	snd_note C_4, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_env $66
	snd_note E_4
	snd_note Gs_4, 9
	snd_note A_4, 6
	snd_note B_4
	snd_note Gs_4
	snd_note A_4
	snd_note Fs_4
	snd_note D_4
	snd_note D_5, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note Cs_5, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note A_4
	snd_note B_4
	snd_note Gs_4
	snd_note B_4
	snd_note E_5, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note Gs_5, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note B_5
	snd_note A_5
	snd_note Fs_5
	snd_note D_5
	snd_note Fs_5, 9
	snd_note D_5, 6
	snd_note G_5
	snd_note Fs_5
	snd_note E_5, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note Gs_4, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note A_4, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note B_4
	snd_note A_4
	snd_tie
	snd_note A_4
	snd_note Fs_4, 4
	snd_note REST, 1
	snd_note Fs_4, 9
	snd_note REST, 6
	snd_note D_5
	snd_note Cs_5
	snd_note A_4
	snd_note B_4, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note Gs_4, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note B_4, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note E_5
	snd_note Fs_5
	snd_tie
	snd_note Fs_5
	snd_note D_5, 4
	snd_note REST, 1
	snd_note D_5, 9
	snd_note REST, 6
	snd_note A_5
	snd_note Gs_5
	snd_note Fs_5
	snd_note E_5, 10
	snd_note C_5, 6
	snd_note REST
	snd_note C_5
	snd_note D_5
	snd_note E_5
	snd_note Fs_5, 9
	snd_note A_4
	snd_note D_5
	snd_note C_5, 7
	snd_note REST, 3
	snd_note C_5, 10
	snd_note B_4
	snd_note A_4, 9
	snd_note B_4, 12
	snd_note REST, 6
	snd_note B_4
	snd_note G_4
	snd_note D_5
	snd_note E_5, 10
	snd_note Fs_5
	snd_note G_5, 9
	snd_note A_5, 6
	snd_note Fs_5
	snd_note A_5
	snd_note D_5, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note C_5, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note D_5
	snd_note B_4, 10
	snd_note E_5, 12
	snd_tie
	snd_len 6
	snd_tie
	snd_len 13
	snd_note REST, 9
	snd_note D_5, 6
	snd_note Cs_5
	snd_note D_5
	snd_note B_4, 9
	snd_note Fs_4
	snd_note Gs_4, 6
	snd_tie
	snd_len 6
	snd_note A_4
	snd_note B_4
	snd_note Ds_4, 9
	snd_note A_4, 6
	snd_note D_5
	snd_note Cs_5
	snd_note B_4, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note Gs_4, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note A_4, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note B_4
	snd_note Gs_4
	snd_tie
	snd_note Gs_4, 4
	snd_note REST, 1
	snd_note Gs_4, 6
	snd_note A_4, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note B_4, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note Gs_4, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note A_4
	snd_note Gs_4
	snd_note E_4
	snd_note A_4, 9
	snd_note B_4
	snd_note Cs_5, 6
	snd_note Ds_5
	snd_note Cs_5
	snd_note B_4
	snd_note Fs_4, 9
	snd_note A_4, 6
	snd_note B_4
	snd_note Ds_5
	snd_note G_5
	snd_note E_5
	snd_note C_5
	snd_note G_5, 9
	snd_note Fs_5
	snd_note G_5, 6
	snd_note A_5
	snd_note Fs_5
	snd_note D_5
	snd_note A_5, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note As_5, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note B_5, 4
	snd_note REST, 1
	snd_jump Trk_5269
	snd_end	; unreachable
Trk_5393:
	snd_env $66
	snd_note B_3, 5
	snd_note REST, 2
	snd_note B_3, 5
	snd_tie
	snd_len 2
	snd_note REST, 10
	snd_note B_3, 5
	snd_note REST, 8
	snd_note B_3, 5
	snd_note REST, 2
	snd_note D_4, 5
	snd_note REST, 2
	snd_note D_4, 5
	snd_tie
	snd_len 2
	snd_note REST, 10
	snd_note D_4, 5
	snd_note REST, 8
	snd_note D_4, 5
	snd_note REST, 2
	snd_note B_3, 5
	snd_note REST, 2
	snd_note B_3, 5
	snd_note REST, 2
	snd_note E_4, 6
	snd_note Gs_4, 5
	snd_note REST, 8
	snd_note B_3, 5
	snd_note REST, 8
	snd_note E_4, 5
	snd_note REST, 2
	snd_note D_5, 6
	snd_note A_4
	snd_note Fs_4
	snd_note A_4, 9
	snd_note Fs_4, 6
	snd_note A_4
	snd_note Ds_4
	snd_note REST, 9
	snd_note B_3, 5
	snd_tie
	snd_len 2
	snd_note REST, 9
	snd_note B_3, 6
	snd_note Cs_4
	snd_note D_4
	snd_tie
	snd_note D_4
	snd_note REST
	snd_note D_4, 5
	snd_tie
	snd_len 2
	snd_note REST, 9
	snd_note D_4, 5
	snd_note REST, 8
	snd_note D_4, 5
	snd_note REST, 2
	snd_note REST, 9
	snd_note B_3, 5
	snd_tie
	snd_len 2
	snd_note REST, 9
	snd_note B_3, 6
	snd_note Cs_4
	snd_note D_4
	snd_tie
	snd_note D_4
	snd_note REST
	snd_note A_3, 5
	snd_tie
	snd_len 2
	snd_note REST, 9
	snd_note D_4, 6
	snd_note Cs_4
	snd_note A_3
	snd_note G_3
	snd_note G_4
	snd_note G_3
	snd_note E_4, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note G_3, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note G_3
	snd_note A_3
	snd_note D_4
	snd_note Fs_4
	snd_note A_3
	snd_note REST
	snd_note Fs_4, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note A_3
	snd_note D_4
	snd_note G_4
	snd_note A_4
	snd_note D_4, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note D_4, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note D_4, 4
	snd_note REST, 1
	snd_note D_4, 6
	snd_note G_4
	snd_note F_4
	snd_note D_4, 7
	snd_note REST, 3
	snd_note D_4, 6
	snd_note B_3
	snd_note G_3, 4
	snd_note REST, 1
	snd_note G_3, 6
	snd_note G_4
	snd_note G_3
	snd_note E_4, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note G_3, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note G_3
	snd_note A_3
	snd_note D_4
	snd_note Fs_4
	snd_note A_3
	snd_note REST
	snd_note Fs_4, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note A_3
	snd_note REST, 9
	snd_note E_4, 5
	snd_note REST, 8
	snd_note D_4, 5
	snd_note REST, 8
	snd_note G_4, 6
	snd_note Gs_4
	snd_tie
	snd_note Gs_4
	snd_note D_4
	snd_note E_4
	snd_note B_3
	snd_note Gs_3
	snd_note A_3
	snd_note As_3
	snd_note B_3
	snd_note REST, 9
	snd_note Fs_3, 5
	snd_tie
	snd_len 2
	snd_note REST, 9
	snd_note A_3, 6
	snd_note Gs_3
	snd_note Fs_3, 5
	snd_note REST, 2
	snd_note REST, 6
	snd_note Fs_3, 5
	snd_note REST, 8
	snd_note Fs_3, 9
	snd_note B_3, 6
	snd_note A_3
	snd_note Ds_4
	snd_note B_3, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note B_3, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note Cs_4, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note Ds_4
	snd_note B_3
	snd_tie
	snd_note B_3, 4
	snd_note REST, 1
	snd_note B_3, 6
	snd_note Cs_4, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note E_4, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note B_3, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note Cs_4, 15
	snd_note B_3, 10
	snd_note Ds_4, 12
	snd_tie
	snd_len 6
	snd_note C_4, 10
	snd_note REST, 6
	snd_note G_3, 3
	snd_note C_4
	snd_note E_4
	snd_note G_4
	snd_note C_4
	snd_note E_4
	snd_note G_4
	snd_note C_5
	snd_note D_5, 6
	snd_note A_4
	snd_note Fs_4
	snd_note D_5, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note G_4, 4
	snd_tie
	snd_len 1
	snd_note REST, 6
	snd_note Fs_4, 4
	snd_note REST, 1
	snd_jump Trk_5393
	snd_end	; unreachable
Trk_54F5:
	snd_env $66
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_tie
	snd_len 2
	snd_note REST, 10
	snd_note E_3, 5
	snd_note REST, 8
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_tie
	snd_len 2
	snd_note REST, 10
	snd_note E_3, 5
	snd_note REST, 8
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_tie
	snd_len 2
	snd_note REST, 10
	snd_note E_3, 5
	snd_note REST, 8
	snd_note Gs_3, 5
	snd_note REST, 2
	snd_note D_4, 9
	snd_note REST, 6
	snd_note A_3, 3
	snd_note Fs_3
	snd_note D_3, 6
	snd_note A_3
	snd_note D_4
	snd_note B_3
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 3
	snd_len 3
	snd_len 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 3
	snd_len 3
	snd_note D_3, 5
	snd_note REST, 2
	snd_note D_3, 5
	snd_note REST, 2
	snd_note D_3, 5
	snd_note REST, 2
	snd_note D_3, 5
	snd_note REST, 2
	snd_note D_3, 5
	snd_note REST, 2
	snd_note Fs_3, 6
	snd_note E_3
	snd_note D_3
	snd_note C_3, 5
	snd_note REST, 2
	snd_note C_3, 5
	snd_note REST, 2
	snd_note C_3, 5
	snd_note REST, 2
	snd_note C_3, 5
	snd_note REST, 2
	snd_note C_3, 5
	snd_note REST, 2
	snd_note C_3, 5
	snd_note REST, 2
	snd_note C_3, 5
	snd_note REST, 2
	snd_note C_3, 5
	snd_note REST, 2
	snd_note D_3, 5
	snd_note REST, 2
	snd_note D_3, 5
	snd_note REST, 2
	snd_note D_3, 5
	snd_note REST, 2
	snd_note D_3, 5
	snd_note REST, 2
	snd_note D_3, 5
	snd_note REST, 2
	snd_note D_3, 6
	snd_note E_3
	snd_note Fs_3
	snd_note G_3, 5
	snd_note REST, 2
	snd_note G_3, 5
	snd_note REST, 2
	snd_note G_3, 5
	snd_note REST, 2
	snd_note G_3, 5
	snd_note REST, 2
	snd_note G_3, 5
	snd_note REST, 2
	snd_note G_3, 5
	snd_note REST, 2
	snd_note G_3, 5
	snd_note REST, 2
	snd_note G_3, 5
	snd_note REST, 2
	snd_note F_3, 5
	snd_note REST, 2
	snd_note F_3, 5
	snd_note REST, 2
	snd_note F_3, 5
	snd_note REST, 2
	snd_note F_3, 5
	snd_note REST, 2
	snd_note F_3, 3
	snd_len 3
	snd_len 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note D_3, 5
	snd_note REST, 2
	snd_note C_3, 5
	snd_note REST, 2
	snd_note C_3, 5
	snd_note REST, 2
	snd_note C_3, 5
	snd_note REST, 2
	snd_note C_3, 5
	snd_note REST, 2
	snd_note C_3, 5
	snd_note REST, 2
	snd_note C_3, 5
	snd_note REST, 2
	snd_note C_3, 5
	snd_note REST, 2
	snd_note C_3, 5
	snd_note REST, 2
	snd_note D_3, 5
	snd_note REST, 2
	snd_note D_3, 5
	snd_note REST, 2
	snd_note D_3, 5
	snd_note REST, 2
	snd_note D_3, 5
	snd_note REST, 2
	snd_note D_3, 5
	snd_note REST, 2
	snd_note D_3, 5
	snd_note REST, 2
	snd_note D_3, 6
	snd_note Fs_3
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 3
	snd_len 3
	snd_len 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note B_2, 5
	snd_note REST, 2
	snd_note B_2, 5
	snd_note REST, 2
	snd_note B_2, 5
	snd_note REST, 2
	snd_note B_2, 5
	snd_note REST, 2
	snd_note B_2, 5
	snd_note REST, 2
	snd_note B_2, 5
	snd_note REST, 2
	snd_note B_2, 5
	snd_note REST, 2
	snd_note B_2, 5
	snd_note REST, 2
	snd_note B_2, 5
	snd_note REST, 2
	snd_note B_2, 5
	snd_note REST, 2
	snd_note B_2, 5
	snd_note REST, 2
	snd_note B_2, 5
	snd_note REST, 2
	snd_note B_2, 5
	snd_note REST, 2
	snd_note B_2, 5
	snd_note REST, 2
	snd_note B_2, 5
	snd_note REST, 2
	snd_note B_2, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 3
	snd_len 3
	snd_len 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 6
	snd_note Gs_3
	snd_note A_3, 5
	snd_note REST, 2
	snd_note A_3, 5
	snd_note REST, 2
	snd_note A_3, 5
	snd_note REST, 2
	snd_note A_3, 5
	snd_note REST, 2
	snd_note A_3, 5
	snd_note REST, 2
	snd_note A_3, 5
	snd_note REST, 2
	snd_note A_3, 5
	snd_note REST, 2
	snd_note A_3, 5
	snd_note REST, 2
	snd_note Fs_3, 5
	snd_note REST, 2
	snd_note Fs_3, 5
	snd_note REST, 2
	snd_note Fs_3, 5
	snd_note REST, 2
	snd_note Fs_3, 5
	snd_note REST, 2
	snd_note Fs_3, 5
	snd_note REST, 2
	snd_note Fs_3, 5
	snd_note REST, 2
	snd_note Fs_3, 5
	snd_note REST, 2
	snd_note Fs_3, 3
	snd_len 3
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 5
	snd_note REST, 2
	snd_note E_3, 3
	snd_len 3
	snd_note D_3, 6
	snd_note Fs_3
	snd_note A_3
	snd_note D_4, 5
	snd_note REST, 8
	snd_note Ds_4, 5
	snd_note REST, 8
	snd_note B_3, 5
	snd_note REST, 2
	snd_jump Trk_54F5
	snd_end	; unreachable
Trk_5788:
	snd_env $62
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D
	snd_note $12
	snd_note $0D, 7
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 9
	snd_note $12, 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_note $0D, 9
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $0D, 9
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $0D, 9
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $0D, 9
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 9
	snd_note $12, 3
	snd_note $0D
	snd_note $12
	snd_note $0D
	snd_note $12
	snd_note $0D
	snd_note $0D, 9
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $0D, 9
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $0D, 9
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $0D, 9
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_note $0D
	snd_note $12
	snd_note $0D
	snd_note $0D, 9
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $0D, 9
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $0D, 9
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $0D, 9
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_len 3
	snd_len 3
	snd_note $0D
	snd_note $12
	snd_note $0D
	snd_note $12
	snd_note $12
	snd_note $0D, 9
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $0D, 9
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $0D, 9
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $0D, 9
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_note $0D
	snd_note $12
	snd_note $0D
	snd_note $0D, 9
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $0D, 9
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $0D, 9
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 9
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D
	snd_jump Trk_5788
	snd_end	; unreachable
Trk_58CC:
	snd_tempo $B7
	snd_env $66
	snd_note G_5, 6
	snd_note G_4
	snd_note B_4
	snd_note D_5
	snd_note E_5, 1
	snd_note F_5, 4
	snd_note E_5, 6
	snd_note F_5
	snd_note G_5
	snd_tie
	snd_note G_5, 3
	snd_note REST
	snd_note G_5, 6
	snd_note D_6
	snd_note G_5
	snd_note F_5
	snd_note E_5
	snd_note F_5
	snd_note D_5
	snd_note G_5
	snd_note G_4
	snd_note B_4
	snd_note D_5
	snd_note E_5, 1
	snd_note F_5, 4
	snd_note E_5, 6
	snd_note F_5
	snd_note G_5
	snd_tie
	snd_note G_5, 3
	snd_note REST
	snd_note G_5, 6
	snd_note D_6
	snd_note B_5
	snd_note C_6
	snd_note B_5
	snd_note G_5
	snd_note F_5
	snd_note D_5, 3
	snd_note REST
	snd_note D_5, 6
	snd_note F_5
	snd_note Fs_5
	snd_note A_5
	snd_note Fs_5
	snd_note G_5
	snd_note A_5
	snd_tie
	snd_note A_5, 3
	snd_note REST
	snd_note A_5, 6
	snd_note C_6
	snd_note B_5
	snd_note A_5
	snd_note F_5
	snd_note Fs_5
	snd_note D_5
	snd_note E_5
	snd_note G_4
	snd_note C_5
	snd_note E_5
	snd_note Fs_5, 1
	snd_note G_5, 4
	snd_note Fs_5, 6
	snd_note G_5
	snd_note C_6
	snd_tie
	snd_note C_6, 3
	snd_note REST
	snd_note C_6, 6
	snd_note As_5
	snd_note C_6
	snd_note As_5
	snd_note G_5
	snd_note F_5
	snd_note E_5
	snd_note G_5
	snd_note G_4
	snd_note B_4
	snd_note D_5
	snd_note F_5
	snd_note E_5
	snd_note F_5
	snd_note G_5
	snd_tie
	snd_note G_5, 3
	snd_note REST
	snd_note Fs_5, 1
	snd_note G_5, 4
	snd_note F_5, 6
	snd_note D_5
	snd_note C_5
	snd_note As_4
	snd_note G_4
	snd_note F_4
	snd_note G_4, 15
	snd_note REST, 6
	snd_note B_4
	snd_note C_5
	snd_note D_5, 7
	snd_note REST, 3
	snd_note D_5, 6
	snd_note F_5
	snd_note G_5
	snd_note B_5, 1
	snd_note C_6, 4
	snd_note B_5, 6
	snd_note G_5, 3
	snd_note REST
	snd_note C_6, 6
	snd_note B_5
	snd_note G_5
	snd_note F_5
	snd_note D_5
	snd_tie
	snd_note D_5, 13
	snd_note REST, 9
	snd_note C_5, 3
	snd_note REST
	snd_note C_5, 6
	snd_note As_4
	snd_note C_5, 9
	snd_note G_4, 6
	snd_note As_4
	snd_note C_5
	snd_note REST
	snd_note D_5, 1
	snd_note Ds_5, 3
	snd_note REST, 1
	snd_note Ds_5, 6
	snd_note C_5
	snd_note G_5
	snd_note Ds_5
	snd_note C_5
	snd_note Ds_5
	snd_note D_5
	snd_note C_5
	snd_note D_5
	snd_note Fs_5, 9
	snd_note A_5, 6
	snd_note G_5
	snd_note Fs_5
	snd_note REST
	snd_note D_6
	snd_note C_6
	snd_note A_5, 1
	snd_note As_5, 7
	snd_note REST, 1
	snd_note As_5, 6
	snd_note G_5
	snd_note F_5
	snd_jump Trk_58CC
	snd_end	; unreachable
Trk_599D:
	snd_env $66
	snd_note B_4, 6
	snd_note B_3
	snd_note D_4
	snd_note G_4
	snd_note C_5
	snd_note B_4
	snd_note C_5
	snd_note B_4
	snd_tie
	snd_note B_4, 3
	snd_note REST
	snd_note D_5, 6
	snd_note B_5
	snd_note B_4
	snd_note D_5
	snd_note C_5
	snd_note D_5
	snd_note B_4
	snd_note B_4
	snd_note B_3
	snd_note D_4
	snd_note G_4
	snd_note C_5
	snd_note B_4
	snd_note C_5
	snd_note B_4
	snd_tie
	snd_note B_4, 3
	snd_note REST
	snd_note B_4, 6
	snd_note B_5
	snd_note G_5
	snd_note E_5
	snd_note D_5
	snd_note B_4
	snd_note A_4
	snd_note Fs_4, 3
	snd_note REST
	snd_note Fs_4, 6
	snd_note Gs_4
	snd_note A_4
	snd_note D_5
	snd_note A_4
	snd_note B_4
	snd_note C_5
	snd_tie
	snd_note C_5, 3
	snd_note REST
	snd_note D_5, 6
	snd_note Fs_5
	snd_note D_5
	snd_note C_5
	snd_note Gs_4
	snd_note A_4
	snd_note Fs_4
	snd_note G_4
	snd_note E_4
	snd_note G_4
	snd_note C_5
	snd_note E_5
	snd_note Ds_5
	snd_note E_5
	snd_note E_5
	snd_tie
	snd_note E_5, 3
	snd_note REST
	snd_note G_5, 6
	snd_note E_5
	snd_note G_5
	snd_note E_5
	snd_note C_5
	snd_note As_4
	snd_note G_4
	snd_note B_4
	snd_note B_3
	snd_note D_4
	snd_note G_4
	snd_note C_5
	snd_note B_4
	snd_note C_5
	snd_note B_4
	snd_tie
	snd_note B_4, 3
	snd_note REST
	snd_note Cs_5, 1
	snd_note D_5, 4
	snd_note C_5, 6
	snd_note A_4
	snd_note G_4
	snd_note F_4
	snd_note D_4
	snd_note C_4
	snd_note D_4, 5
	snd_tie
	snd_len 2
	snd_note REST, 9
	snd_note D_4, 5
	snd_note REST, 8
	snd_note C_4, 6
	snd_note Cs_4
	snd_note D_4, 5
	snd_note REST, 2
	snd_note REST, 6
	snd_note D_4, 5
	snd_note REST, 8
	snd_note D_4, 5
	snd_tie
	snd_len 2
	snd_note REST, 10
	snd_note D_4, 3
	snd_len 3
	snd_len 5
	snd_tie
	snd_len 2
	snd_note REST, 9
	snd_note D_4, 5
	snd_note REST, 8
	snd_note C_4, 6
	snd_note Cs_4
	snd_note D_4, 5
	snd_note REST, 2
	snd_note REST, 6
	snd_note F_4, 3
	snd_note REST
	snd_note F_4
	snd_note REST
	snd_note E_4, 9
	snd_note F_4, 2
	snd_note REST, 5
	snd_note E_4
	snd_note REST, 2
	snd_note D_4, 5
	snd_note REST, 2
	snd_note C_4, 5
	snd_tie
	snd_len 2
	snd_note REST, 9
	snd_note C_4, 5
	snd_note REST, 8
	snd_note As_3, 6
	snd_note B_3
	snd_note C_4, 5
	snd_note REST, 2
	snd_note REST, 6
	snd_note C_4, 5
	snd_note REST, 8
	snd_note Ds_4, 5
	snd_note REST, 2
	snd_note Ds_4, 6
	snd_note C_4
	snd_note Ds_4
	snd_note G_4
	snd_note A_3, 5
	snd_tie
	snd_len 2
	snd_note REST, 9
	snd_note A_3, 5
	snd_note REST, 8
	snd_note G_3, 6
	snd_note Gs_3
	snd_note A_3, 5
	snd_note REST, 2
	snd_note D_5, 3
	snd_note A_4
	snd_note Fs_4
	snd_note REST, 7
	snd_note Fs_4, 3
	snd_note REST, 7
	snd_note D_5, 6
	snd_note As_4
	snd_note A_4
	snd_jump Trk_599D
	snd_end	; unreachable
Trk_5A91:
	snd_env $66
	snd_note G_3, 5
	snd_tie
	snd_len 2
	snd_note REST, 9
	snd_note G_3, 5
	snd_note REST, 8
	snd_note F_3, 6
	snd_note Fs_3
	snd_note G_3, 5
	snd_note REST, 2
	snd_note REST, 6
	snd_note G_3, 5
	snd_note REST, 8
	snd_note G_3, 5
	snd_tie
	snd_len 2
	snd_note REST, 12
	snd_note G_3, 3
	snd_note D_4
	snd_note G_3, 5
	snd_note REST, 8
	snd_note G_3, 5
	snd_note REST, 8
	snd_note F_3, 6
	snd_note Fs_3
	snd_note G_3, 5
	snd_note REST, 2
	snd_note REST, 6
	snd_note G_3, 5
	snd_note REST, 8
	snd_note G_3, 5
	snd_note REST, 8
	snd_note B_2, 6
	snd_note C_3
	snd_note Cs_3
	snd_note D_3, 5
	snd_tie
	snd_len 2
	snd_note REST, 9
	snd_note D_3, 5
	snd_note REST, 8
	snd_note C_3, 6
	snd_note Cs_3
	snd_note D_3, 5
	snd_note REST, 2
	snd_note REST, 6
	snd_note D_3, 5
	snd_note REST, 8
	snd_note D_3, 5
	snd_tie
	snd_len 2
	snd_note REST, 10
	snd_note Cs_3, 6
	snd_note C_3, 5
	snd_tie
	snd_len 2
	snd_note REST, 9
	snd_note C_3, 5
	snd_note REST, 8
	snd_note As_2, 6
	snd_note B_2
	snd_note C_3, 5
	snd_note REST, 2
	snd_note E_3, 3
	snd_note G_3
	snd_note C_3, 5
	snd_note REST, 8
	snd_note C_3, 3
	snd_note REST
	snd_note C_3, 6
	snd_note G_3
	snd_note C_3
	snd_note E_3
	snd_note G_3, 5
	snd_tie
	snd_len 2
	snd_note REST, 9
	snd_note G_3, 5
	snd_note REST, 8
	snd_note F_3, 6
	snd_note Fs_3
	snd_note G_3
	snd_tie
	snd_note G_3, 3
	snd_note REST
	snd_note G_4, 6
	snd_note F_4
	snd_note D_4
	snd_note C_4
	snd_note As_3
	snd_note G_3
	snd_note F_3
	snd_note G_3, 5
	snd_tie
	snd_len 2
	snd_note REST, 9
	snd_note G_3, 5
	snd_note REST, 8
	snd_note F_3, 6
	snd_note Fs_3
	snd_note G_3, 5
	snd_note REST, 2
	snd_note REST, 6
	snd_note G_3, 5
	snd_note REST, 8
	snd_note G_3, 5
	snd_tie
	snd_len 2
	snd_note REST, 12
	snd_note G_3, 5
	snd_tie
	snd_len 2
	snd_note REST, 9
	snd_note G_3, 5
	snd_note REST, 8
	snd_note F_3, 6
	snd_note Fs_3
	snd_note G_3, 5
	snd_note REST, 2
	snd_note REST, 6
	snd_note G_3, 5
	snd_note REST, 8
	snd_note G_3, 5
	snd_tie
	snd_len 2
	snd_note REST, 12
	snd_note G_3, 5
	snd_tie
	snd_len 2
	snd_note REST, 9
	snd_note G_3, 5
	snd_note REST, 8
	snd_note F_3, 6
	snd_note Fs_3
	snd_note G_3, 5
	snd_note REST, 2
	snd_note REST, 6
	snd_note G_3, 5
	snd_note REST, 8
	snd_note G_3, 5
	snd_tie
	snd_len 2
	snd_note REST, 12
	snd_note D_3, 5
	snd_tie
	snd_len 2
	snd_note REST, 9
	snd_note D_3, 5
	snd_note REST, 8
	snd_note C_3, 6
	snd_note Cs_3
	snd_note D_3, 5
	snd_note REST, 2
	snd_note REST, 6
	snd_note D_3, 5
	snd_note REST, 8
	snd_note D_3, 5
	snd_note REST, 8
	snd_note As_3, 6
	snd_note G_3
	snd_note F_3
	snd_jump Trk_5A91
	snd_end	; unreachable
Trk_5BA3:
	snd_env $62
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D
	snd_note $12
	snd_note $0D
	snd_note $12
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_len 3
	snd_len 3
	snd_note $0D
	snd_note $12
	snd_note $12
	snd_note $12
	snd_note $12
	snd_note $12
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D
	snd_note $12
	snd_note $0D
	snd_note $0D, 13
	snd_note $12, 3
	snd_note $0D
	snd_note $12
	snd_note $0D
	snd_note $12
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D
	snd_note $12
	snd_note $0D
	snd_note $12
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_jump Trk_5BA3
	snd_end	; unreachable
Trk_5CC1:
	snd_tempo $56
Trk_5CC3:
	snd_env $66
	snd_note Gs_4, 2
	snd_note D_4, 0
	snd_note A_3, 2
	snd_note A_4, 1
	snd_note REST, 2
	snd_note D_4
	snd_note REST, 4
	snd_note Gs_4, 1
	snd_note REST, 3
	snd_note A_4, 1
	snd_note D_4, 0
	snd_note REST, 2
	snd_note Gs_4
	snd_note D_4, 0
	snd_note A_3, 2
	snd_note A_4, 1
	snd_note REST
	snd_note F_4, 0
	snd_note REST, 2
	snd_note D_4, 0
	snd_note A_4, 2
	snd_note REST, 0
	snd_note G_4, 2
	snd_note REST, 0
	snd_note Fs_4, 2
	snd_note A_4, 0
	snd_note D_4, 2
	snd_note A_4, 0
	snd_note Cs_5, 2
	snd_note G_4, 0
	snd_note D_4, 2
	snd_note D_5, 1
	snd_note REST, 2
	snd_note G_4
	snd_note REST, 4
	snd_note Cs_5, 1
	snd_note REST, 3
	snd_note D_5, 1
	snd_note REST, 2
	snd_note D_4, 0
	snd_note Cs_5, 2
	snd_note G_4, 0
	snd_note D_4, 2
	snd_note D_5, 1
	snd_note REST, 2
	snd_note G_4
	snd_note REST, 1
	snd_note A_4, 2
	snd_note As_4, 0
	snd_note A_4, 2
	snd_note As_4, 0
	snd_note A_4, 2
	snd_note As_4, 0
	snd_note A_4, 2
	snd_note As_4, 0
	snd_note Gs_4, 2
	snd_note D_4, 0
	snd_note A_3, 2
	snd_note A_4, 1
	snd_note REST, 2
	snd_note D_4
	snd_note REST, 4
	snd_note Gs_4, 1
	snd_note REST, 3
	snd_note A_4, 1
	snd_note D_4, 0
	snd_note REST, 2
	snd_note Gs_4
	snd_note D_4, 0
	snd_note A_3, 2
	snd_note A_4, 1
	snd_note REST
	snd_note F_4, 0
	snd_note REST, 2
	snd_note Fs_4, 0
	snd_note REST, 3
	snd_note Gs_4, 1
	snd_note REST, 3
	snd_note A_4, 1
	snd_note Fs_4, 2
	snd_note A_4, 0
	snd_note Cs_5, 2
	snd_note F_4, 0
	snd_note G_4, 2
	snd_note D_5, 1
	snd_note REST, 2
	snd_note G_4
	snd_note REST, 3
	snd_note B_4, 1
	snd_note Cs_5
	snd_note REST, 3
	snd_note D_5, 1
	snd_note REST, 2
	snd_note G_4, 0
	snd_note Ds_5, 2
	snd_note G_4, 0
	snd_note A_4, 2
	snd_note E_5, 1
	snd_note REST, 2
	snd_note A_4
	snd_note REST, 1
	snd_note Gs_4, 2
	snd_note A_4, 0
	snd_note Fs_4, 2
	snd_note G_4, 0
	snd_note Ds_4, 2
	snd_note E_4, 0
	snd_note C_4, 2
	snd_note Cs_4, 0
	snd_note Gs_4, 2
	snd_note D_4, 0
	snd_note A_3, 2
	snd_note A_4, 1
	snd_note REST
	snd_note F_4, 0
	snd_note Fs_4, 2
	snd_note D_4, 0
	snd_note REST, 3
	snd_note Gs_4, 1
	snd_note REST, 3
	snd_note A_4, 1
	snd_note D_4, 0
	snd_note REST, 2
	snd_note D_4
	snd_note A_4, 0
	snd_note D_5, 2
	snd_note D_4, 0
	snd_note REST, 2
	snd_note F_4, 0
	snd_note REST, 2
	snd_note D_4, 0
	snd_note REST, 6
	snd_note E_4, 2
	snd_note F_4, 0
	snd_note Fs_4, 2
	snd_note G_4, 0
	snd_jump Trk_5CC3
	snd_end	; unreachable
Trk_5DCC:
	snd_env $66
	snd_note D_3, 2
	snd_note REST, 3
	snd_note D_3, 5
	snd_note F_3, 3
	snd_note Fs_3
	snd_note A_3
	snd_note D_3
	snd_note C_3
	snd_note D_3, 2
	snd_note REST, 3
	snd_note D_4, 5
	snd_note A_3, 3
	snd_note C_4
	snd_note B_3
	snd_note A_3, 2
	snd_note REST, 0
	snd_note Fs_3, 3
	snd_note G_3, 2
	snd_note REST, 3
	snd_note G_3, 5
	snd_note As_3, 3
	snd_note B_3
	snd_note D_4
	snd_note G_3
	snd_note F_3
	snd_note G_3, 2
	snd_note REST, 3
	snd_note D_3, 5
	snd_note G_3, 3
	snd_note As_3
	snd_note A_3
	snd_note G_3
	snd_note F_3
	snd_note D_3, 2
	snd_note REST, 3
	snd_note D_3, 5
	snd_note F_3, 3
	snd_note Fs_3
	snd_note A_3
	snd_note D_3
	snd_note C_3
	snd_note D_3, 2
	snd_note REST, 3
	snd_note D_4, 5
	snd_note A_3, 3
	snd_note C_4
	snd_note B_3
	snd_note A_3, 2
	snd_note REST, 5
	snd_note G_3, 2
	snd_note REST, 3
	snd_note D_4, 5
	snd_note As_3, 3
	snd_note B_3, 2
	snd_note REST, 0
	snd_note B_3, 3
	snd_note G_3
	snd_note B_3
	snd_note A_3, 2
	snd_note REST, 3
	snd_note E_4, 5
	snd_note C_4, 3
	snd_note Cs_4
	snd_note A_3
	snd_note G_3
	snd_note E_3
	snd_note D_3, 2
	snd_note REST, 3
	snd_note D_4, 5
	snd_note A_3, 3
	snd_note C_4
	snd_note B_3
	snd_note A_3
	snd_note F_3
	snd_note Fs_3
	snd_note D_3, 2
	snd_note REST, 5
	snd_note D_3, 2
	snd_note REST, 3
	snd_note D_3, 0
	snd_note A_2, 3
	snd_note C_3
	snd_note Cs_3
	snd_jump Trk_5DCC
	snd_end	; unreachable
Trk_5E57:
	snd_tempo $AF
	snd_env $00
	snd_note C_4, 4
	snd_note REST, 1
	snd_env $66
	snd_note C_5, 6
	snd_note G_4, 5
	snd_note C_5
	snd_note E_5
	snd_note G_5, 6
	snd_note F_5, 9
	snd_note E_5, 6
	snd_note F_5
	snd_note E_5
	snd_note F_5, 9
	snd_note REST, 6
	snd_note G_5, 9
	snd_note A_5, 6
	snd_note B_5
	snd_note As_5
	snd_note A_5
	snd_note G_5
	snd_note F_5
	snd_note E_5
	snd_note F_5
	snd_note D_5
	snd_note E_5
	snd_note F_5
	snd_note G_5, 12
	snd_note REST, 9
	snd_note A_5, 6
	snd_note B_5, 9
	snd_note C_6
	snd_note D_6, 6
	snd_note B_5
	snd_note A_5
	snd_note G_5
	snd_note F_5
	snd_note E_5
	snd_note D_5
	snd_note Cs_5, 9
	snd_note REST, 6
	snd_note E_5
	snd_note F_5
	snd_note D_5
	snd_note E_5
	snd_note F_5
	snd_note Fs_5
	snd_note A_5
	snd_note D_6
	snd_note C_6, 3
	snd_note REST
	snd_note C_6, 9
	snd_note B_5
	snd_note A_5
	snd_note G_5
	snd_jump Trk_5E57
	snd_end	; unreachable
Trk_5EAA:
	snd_env $66
	snd_note G_4, 9
	snd_note E_4
	snd_note G_4
	snd_note C_5
	snd_note A_4
	snd_note C_5
	snd_note B_4
	snd_note C_5
	snd_note D_5
	snd_note B_4
	snd_note D_5
	snd_note B_4, 7
	snd_note REST, 3
	snd_note C_5, 12
	snd_note B_4, 6
	snd_note A_4
	snd_note G_4
	snd_note B_4
	snd_note C_5, 9
	snd_note A_4
	snd_note B_4
	snd_note D_5
	snd_note B_4
	snd_note G_4
	snd_note A_4
	snd_note G_4
	snd_note A_4
	snd_note C_5
	snd_note A_4
	snd_note Fs_4
	snd_note D_5, 12
	snd_note C_5, 9
	snd_note B_4
	snd_jump Trk_5EAA
	snd_end	; unreachable
Trk_5ED9:
	snd_env $66
	snd_note C_4, 15
	snd_note F_4
	snd_note G_4
	snd_tie
	snd_note G_4, 9
	snd_note E_4
	snd_note D_4, 6
	snd_note C_4
	snd_note B_3
	snd_note D_4
	snd_note F_4, 12
	snd_note G_4
	snd_note E_4, 15
	snd_note D_4
	snd_note G_4, 12
	snd_note F_4, 9
	snd_note D_4
	snd_jump Trk_5ED9
	snd_end	; unreachable
Trk_5EF7:
	snd_env $62
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 9
	snd_note $12, 3
	snd_len 3
	snd_len 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 9
	snd_note $12, 3
	snd_len 3
	snd_len 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 9
	snd_note $12, 3
	snd_len 3
	snd_len 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 9
	snd_note $12, 3
	snd_len 3
	snd_len 3
	snd_note $0D
	snd_note $12
	snd_note $0D
	snd_note $12
	snd_note $0D
	snd_note $12
	snd_note $0D
	snd_note $12
	snd_tie
	snd_len 3
	snd_note $0D, 9
	snd_note $12, 3
	snd_len 3
	snd_len 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 9
	snd_note $12, 3
	snd_len 3
	snd_len 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 9
	snd_note $12, 3
	snd_len 3
	snd_len 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_len 3
	snd_len 3
	snd_note $0D
	snd_note $12
	snd_note $0D
	snd_note $12
	snd_note $0D
	snd_jump Trk_5EF7
	snd_end	; unreachable
Trk_5F72:
	snd_tempo $B5
	snd_env $66
	snd_note As_4, 3
	snd_note REST
	snd_note As_4
	snd_note REST
	snd_note As_4, 6
	snd_note B_4
	snd_note G_4
	snd_note F_4, 3
	snd_note REST, 7
	snd_note As_4, 6
	snd_tie
	snd_len 6
	snd_note B_4
	snd_note As_4
	snd_note B_4
	snd_note D_5
	snd_note G_4, 3
	snd_note REST, 7
	snd_note F_4, 6
	snd_tie
	snd_len 15
	snd_note REST
	snd_note Ds_5, 6
	snd_note E_5
	snd_note Ds_5
	snd_note E_5
	snd_note C_5
	snd_note As_4, 3
	snd_note REST, 7
	snd_note Ds_5, 6
	snd_tie
	snd_len 6
	snd_note E_5
	snd_note Ds_5
	snd_note E_5
	snd_note G_5
	snd_note C_5
	snd_note E_5
	snd_note G_5
	snd_note Fs_5
	snd_note G_5
	snd_note Gs_5
	snd_note A_5, 3
	snd_note REST, 7
	snd_note C_6, 3
	snd_note REST, 7
	snd_note B_5, 6
	snd_note A_5, 3
	snd_tie
	snd_len 7
	snd_note REST, 13
	snd_jump Trk_5F72
	snd_end	; unreachable
Trk_5FC0:
	snd_note REST, 12
	snd_tie
	snd_len 6
	snd_env $66
	snd_note Cs_6, 1
	snd_note D_6
	snd_note REST, 7
	snd_note Cs_6, 1
	snd_note D_6
	snd_note REST, 3
	snd_note REST, 12
	snd_tie
	snd_len 6
	snd_note Cs_6, 1
	snd_note D_6
	snd_note REST, 7
	snd_note Cs_6, 1
	snd_note D_6
	snd_note REST, 3
	snd_note REST, 6
	snd_note As_5, 3
	snd_note REST, 7
	snd_note B_5, 6
	snd_note G_5
	snd_note F_5
	snd_note G_5
	snd_note C_6, 3
	snd_note REST
	snd_note REST, 6
	snd_note B_5
	snd_note As_5
	snd_note B_5
	snd_note D_6, 3
	snd_note F_5
	snd_note G_5
	snd_note REST
	snd_note B_5, 6
	snd_note D_5, 3
	snd_note REST
	snd_note REST, 12
	snd_tie
	snd_len 6
	snd_note B_5, 1
	snd_note C_6
	snd_note REST, 7
	snd_note B_5, 1
	snd_note C_6
	snd_note REST, 3
	snd_note REST, 15
	snd_note REST, 6
	snd_note Cs_5, 3
	snd_note REST, 7
	snd_note D_5, 3
	snd_note REST
	snd_note A_4
	snd_note A_5
	snd_note D_5
	snd_note REST, 7
	snd_note D_5, 4
	snd_note REST, 1
	snd_note D_5, 3
	snd_note REST, 7
	snd_note Gs_5, 3
	snd_note A_5
	snd_note As_5
	snd_note B_5
	snd_note Cs_6
	snd_note D_6
	snd_note Gs_5
	snd_note A_5
	snd_note F_5
	snd_note Fs_5
	snd_note Cs_5
	snd_note D_5
	snd_jump Trk_5FC0
	snd_end	; unreachable
Trk_6032:
	snd_env $66
	snd_note G_3, 9
	snd_note D_4
	snd_note D_3
	snd_note D_4
	snd_note G_3
	snd_note D_4
	snd_note D_3
	snd_note D_4
	snd_note G_3
	snd_note D_4
	snd_note D_3
	snd_note D_4
	snd_note G_3
	snd_note D_4
	snd_note D_3
	snd_note D_4
	snd_note C_4
	snd_note G_4
	snd_note G_3
	snd_note G_4
	snd_note C_4
	snd_note G_4
	snd_note G_3
	snd_note G_4
	snd_note D_4, 6
	snd_note E_4
	snd_note F_4
	snd_note Fs_4, 3
	snd_note REST, 7
	snd_note A_4, 3
	snd_note REST, 7
	snd_note G_4, 6
	snd_note Fs_4, 3
	snd_note REST
	snd_note D_4, 6
	snd_note Cs_4
	snd_note D_4
	snd_note Gs_3
	snd_note A_3
	snd_note D_3
	snd_note Fs_3
	snd_jump Trk_6032
	snd_end	; unreachable
Trk_606A:
	snd_tempo $CB
	snd_env $40
	snd_note C_4, 4
	snd_note REST, 3
	snd_env $66
	snd_note Fs_4
	snd_note REST, 1
	snd_note Fs_4, 8
	snd_note G_4, 9
	snd_note A_4
	snd_note Fs_4, 5
	snd_tie
	snd_len 5
	snd_note REST
	snd_note Fs_4
	snd_note G_4, 8
	snd_note A_4, 5
	snd_note REST, 8
	snd_note D_4, 5
	snd_note Cs_4, 8
	snd_note D_4, 5
	snd_note C_5, 8
	snd_note REST, 5
	snd_note C_5, 8
	snd_note REST, 5
	snd_note C_5, 8
	snd_note B_4, 9
	snd_note A_4, 5
	snd_tie
	snd_len 15
	snd_note REST, 8
	snd_note B_4, 3
	snd_note REST, 0
	snd_note B_4, 8
	snd_note C_5, 9
	snd_note D_5
	snd_note B_4, 5
	snd_tie
	snd_len 5
	snd_note REST
	snd_note B_4
	snd_note C_5, 8
	snd_note D_5
	snd_note REST, 5
	snd_note F_5
	snd_note E_5, 8
	snd_note F_5, 5
	snd_note D_5, 8
	snd_note REST, 5
	snd_note D_5, 8
	snd_note REST, 5
	snd_note D_5, 8
	snd_note C_5, 5
	snd_note D_5, 8
	snd_note A_4, 5
	snd_tie
	snd_len 12
	snd_note REST, 8
	snd_note A_4, 5
	snd_note C_5, 8
	snd_note D_5, 5
	snd_note E_5
	snd_note REST
	snd_note E_5
	snd_note REST, 8
	snd_note E_5
	snd_note REST, 5
	snd_note E_5
	snd_note C_5, 8
	snd_note E_5, 5
	snd_note D_5
	snd_note REST
	snd_note D_5
	snd_note REST, 8
	snd_note F_5
	snd_note REST, 5
	snd_note F_5
	snd_note D_5, 8
	snd_note C_5, 5
	snd_note REST, 8
	snd_note A_4, 5
	snd_len 8
	snd_note G_4, 5
	snd_note A_4, 8
	snd_note D_5, 5
	snd_note C_5
	snd_note REST
	snd_note C_5
	snd_tie
	snd_note C_5, 8
	snd_note A_4, 5
	snd_note G_4, 8
	snd_note A_4, 5
	snd_note G_4, 8
	snd_note F_4, 5
	snd_note D_4, 8
	snd_note C_4, 5
	snd_note REST, 8
	snd_note A_4, 5
	snd_note REST, 8
	snd_note A_4, 5
	snd_note Fs_4, 8
	snd_note G_4, 5
	snd_note A_4, 8
	snd_note C_5, 5
	snd_note REST, 8
	snd_note B_4, 5
	snd_note REST, 8
	snd_note A_4, 12
	snd_tie
	snd_len 5
	snd_note REST, 8
	snd_note A_4, 5
	snd_note REST, 8
	snd_note A_4, 5
	snd_note Fs_4, 8
	snd_note G_4, 5
	snd_note A_4, 8
	snd_note C_5, 5
	snd_note REST, 8
	snd_note B_4, 5
	snd_note REST, 8
	snd_note A_4, 5
	snd_note REST, 8
	snd_note F_4, 5
	snd_note Fs_4, 8
	snd_note D_4, 5
	snd_note REST, 8
	snd_note G_4, 5
	snd_note REST, 8
	snd_note G_4, 5
	snd_note F_4, 8
	snd_note D_4, 5
	snd_note F_4, 8
	snd_note B_4, 5
	snd_note REST, 8
	snd_note G_4, 5
	snd_note REST, 8
	snd_note F_4, 12
	snd_tie
	snd_len 5
	snd_note REST, 8
	snd_note A_4, 5
	snd_note REST, 8
	snd_note A_4, 5
	snd_note Fs_4, 8
	snd_note G_4, 5
	snd_note A_4, 8
	snd_note C_5, 5
	snd_note REST, 8
	snd_note B_4, 5
	snd_note REST, 8
	snd_note A_4, 9
	snd_note A_5, 3
	snd_note REST, 0
	snd_note A_5, 6
	snd_note REST, 2
	snd_note A_5, 5
	snd_note Gs_5, 8
	snd_note A_5, 3
	snd_note REST, 0
	snd_note A_5, 8
	snd_note Gs_5, 5
	snd_note A_5, 6
	snd_note REST, 2
	snd_note A_5, 5
	snd_note Gs_5, 8
	snd_note A_5, 5
	snd_note REST, 8
	snd_note G_5, 3
	snd_note REST, 0
	snd_note G_5, 8
	snd_note F_5, 5
	snd_note A_5, 3
	snd_note G_5
	snd_note F_5, 6
	snd_note D_5, 8
	snd_note C_5, 5
	snd_note D_5, 15
	snd_note REST
	snd_jump Trk_606A
	snd_end	; unreachable
Trk_61B0:
	snd_env $66
	snd_note C_4, 8
	snd_note D_4, 5
	snd_note REST, 9
	snd_note D_4, 5
	snd_tie
	snd_len 2
	snd_note REST, 10
	snd_note D_4, 5
	snd_note REST, 11
	snd_note D_4, 5
	snd_note REST, 12
	snd_note REST, 8
	snd_note Fs_4, 5
	snd_note D_4, 8
	snd_note C_4, 5
	snd_note D_4, 8
	snd_note F_4, 5
	snd_note REST, 9
	snd_note Fs_4, 5
	snd_note REST, 11
	snd_note F_4, 5
	snd_note REST, 9
	snd_note Fs_4, 5
	snd_note REST, 8
	snd_note F_4
	snd_note D_4, 5
	snd_note REST, 8
	snd_note C_4, 5
	snd_note D_4, 8
	snd_note F_4, 5
	snd_note REST, 9
	snd_note G_4, 5
	snd_note REST, 11
	snd_note F_4, 5
	snd_note REST, 8
	snd_note B_3, 5
	snd_note D_4, 8
	snd_note F_4, 5
	snd_note REST, 8
	snd_note Fs_4, 5
	snd_note REST, 8
	snd_note D_4, 5
	snd_note F_4, 8
	snd_note Fs_4, 5
	snd_note REST, 9
	snd_note Fs_4, 5
	snd_note REST, 11
	snd_note Fs_4, 5
	snd_note REST, 9
	snd_note Fs_4, 5
	snd_note REST, 8
	snd_note REST
	snd_note Cs_4, 5
	snd_note REST, 9
	snd_note Cs_4, 5
	snd_tie
	snd_len 2
	snd_note REST, 10
	snd_note B_3, 5
	snd_note REST, 11
	snd_note B_3, 5
	snd_note REST, 8
	snd_note B_4, 5
	snd_note G_4, 8
	snd_note F_4, 5
	snd_note D_4, 8
	snd_tie
	snd_len 5
	snd_note REST, 13
	snd_note REST, 12
	snd_note D_4, 8
	snd_note C_4, 5
	snd_note A_3, 8
	snd_note G_3, 5
	snd_note REST, 15
	snd_note REST, 12
	snd_note F_5, 8
	snd_note D_5, 5
	snd_note C_5, 8
	snd_note D_5, 5
	snd_tie
	snd_len 15
	snd_note REST, 12
	snd_note F_5, 8
	snd_note D_5, 5
	snd_note C_5, 8
	snd_note D_5, 5
	snd_tie
	snd_len 15
	snd_note REST, 12
	snd_note F_5, 8
	snd_note G_5, 5
	snd_note F_5, 8
	snd_note D_5, 5
	snd_tie
	snd_len 15
	snd_note REST, 14
	snd_note C_5, 3
	snd_note REST, 0
	snd_note C_5, 6
	snd_note REST, 2
	snd_note C_5, 3
	snd_note REST, 0
	snd_note C_5, 8
	snd_note Cs_5, 3
	snd_note REST, 0
	snd_note Cs_5, 8
	snd_note C_5, 5
	snd_note Cs_5, 6
	snd_note REST, 2
	snd_note Cs_5, 5
	snd_note C_5, 8
	snd_note Cs_5, 5
	snd_note REST, 15
	snd_note D_6, 3
	snd_note A_5
	snd_note Fs_5
	snd_note A_4
	snd_note C_5, 5
	snd_note REST
	snd_note C_5
	snd_note B_4
	snd_note REST
	snd_note B_4
	snd_note As_4
	snd_note REST
	snd_note As_4
	snd_note A_4, 3
	snd_note REST, 4
	snd_note A_4, 3
	snd_note REST, 1
	snd_note A_4, 6
	snd_note REST, 2
	snd_note G_4, 5
	snd_note A_4, 3
	snd_note C_5
	snd_note D_5, 6
	snd_note G_4, 8
	snd_note F_4, 5
	snd_jump Trk_61B0
	snd_end	; unreachable
Trk_62B2:
	snd_env $66
	snd_note D_3, 8
	snd_note REST, 5
	snd_note Fs_3, 8
	snd_note REST, 5
	snd_note A_3, 8
	snd_note REST, 5
	snd_note B_3, 8
	snd_note REST, 5
	snd_note C_4, 8
	snd_note REST, 5
	snd_note B_3, 8
	snd_note REST, 5
	snd_note A_3, 8
	snd_note REST, 5
	snd_note Fs_3, 8
	snd_note REST, 5
	snd_note D_3, 8
	snd_note REST, 5
	snd_note Fs_3, 8
	snd_note REST, 5
	snd_note A_3, 8
	snd_note REST, 5
	snd_note B_3, 8
	snd_note REST, 5
	snd_note C_4, 8
	snd_note REST, 5
	snd_note A_3, 8
	snd_note REST, 5
	snd_note Fs_3, 8
	snd_note REST, 5
	snd_note D_3, 8
	snd_note REST, 5
	snd_note G_2, 8
	snd_note REST, 5
	snd_note B_2, 8
	snd_note REST, 5
	snd_note D_3, 8
	snd_note REST, 5
	snd_note E_3, 8
	snd_note REST, 5
	snd_note F_3, 8
	snd_note REST, 5
	snd_note E_3, 8
	snd_note REST, 5
	snd_note D_3, 8
	snd_note REST, 5
	snd_note B_2, 8
	snd_note REST, 5
	snd_note D_3, 8
	snd_note REST, 5
	snd_note Fs_3, 8
	snd_note REST, 5
	snd_note A_3, 8
	snd_note REST, 5
	snd_note B_3, 8
	snd_note REST, 5
	snd_note C_4, 8
	snd_note REST, 5
	snd_note B_3, 8
	snd_note REST, 5
	snd_note A_3, 8
	snd_note REST, 5
	snd_note Fs_3, 8
	snd_note REST, 5
	snd_note A_2, 8
	snd_note REST, 5
	snd_note Cs_3, 8
	snd_note REST, 5
	snd_note E_3, 8
	snd_note REST, 5
	snd_note Fs_3, 8
	snd_note REST, 5
	snd_note G_3, 8
	snd_note REST, 5
	snd_note F_3, 8
	snd_note REST, 5
	snd_note D_3, 8
	snd_note REST, 5
	snd_note B_2, 8
	snd_note REST, 5
	snd_note D_3, 8
	snd_tie
	snd_len 5
	snd_note REST, 13
	snd_note REST, 12
	snd_note B_3, 8
	snd_note A_3, 5
	snd_note F_3, 8
	snd_note E_3, 5
	snd_note D_3, 8
	snd_note REST, 5
	snd_note Fs_3, 8
	snd_note REST, 5
	snd_note A_3, 8
	snd_note REST, 5
	snd_note B_3, 8
	snd_note REST, 5
	snd_note C_4, 8
	snd_note REST, 5
	snd_note B_3, 8
	snd_note REST, 5
	snd_note A_3, 8
	snd_note REST, 5
	snd_note Fs_3, 8
	snd_note REST, 5
	snd_note D_3, 8
	snd_note REST, 5
	snd_note Fs_3, 8
	snd_note REST, 5
	snd_note A_3, 8
	snd_note REST, 5
	snd_note B_3, 8
	snd_note REST, 5
	snd_note C_4, 8
	snd_note REST, 5
	snd_note A_3, 8
	snd_note REST, 5
	snd_note Fs_3, 8
	snd_note REST, 5
	snd_note D_3, 8
	snd_note REST, 5
	snd_note G_2, 8
	snd_note REST, 5
	snd_note B_2, 8
	snd_note REST, 5
	snd_note D_3, 8
	snd_note REST, 5
	snd_note E_3, 8
	snd_note REST, 5
	snd_note F_3, 8
	snd_note REST, 5
	snd_note E_3, 8
	snd_note REST, 5
	snd_note D_3, 8
	snd_note REST, 5
	snd_note B_2, 8
	snd_note REST, 5
	snd_note D_3, 8
	snd_note REST, 5
	snd_note Fs_3, 8
	snd_note REST, 5
	snd_note A_3, 8
	snd_note REST, 5
	snd_note B_3, 8
	snd_note REST, 5
	snd_note C_4, 8
	snd_note REST, 5
	snd_note B_3, 8
	snd_note REST, 5
	snd_note A_3, 8
	snd_note REST, 5
	snd_note Fs_3, 8
	snd_note REST, 5
	snd_note A_2, 8
	snd_note REST, 5
	snd_note Cs_3, 8
	snd_note REST, 5
	snd_note E_3, 8
	snd_note REST, 5
	snd_note Fs_3, 8
	snd_note REST, 5
	snd_note G_3
	snd_tie
	snd_len 8
	snd_note REST, 13
	snd_note D_3, 8
	snd_note REST, 5
	snd_note Fs_3, 8
	snd_note REST, 5
	snd_note G_3, 8
	snd_note REST, 5
	snd_note Gs_3, 8
	snd_note REST, 5
	snd_note A_3, 8
	snd_note REST, 5
	snd_note G_3, 8
	snd_note REST, 5
	snd_note E_3, 8
	snd_note REST, 5
	snd_note A_2, 8
	snd_note REST, 5
	snd_jump Trk_62B2
	snd_end	; unreachable
Trk_641D:
	snd_note $0D, 9
	snd_env $62
	snd_note $12, 5
	snd_tie
	snd_len 2
	snd_note $0D, 10
	snd_note $12, 5
	snd_note $0D, 8
	snd_note $0D, 9
	snd_note $12, 5
	snd_note $0D, 11
	snd_note $12, 5
	snd_len 5
	snd_note $0D, 8
	snd_note $0D, 9
	snd_note $12, 5
	snd_tie
	snd_len 2
	snd_note $0D, 10
	snd_note $12, 5
	snd_note $0D, 8
	snd_note $0D, 9
	snd_note $12, 5
	snd_note $0D, 11
	snd_note $12, 5
	snd_len 5
	snd_note $0D, 8
	snd_note $0D, 9
	snd_note $12, 5
	snd_tie
	snd_len 2
	snd_note $0D, 10
	snd_note $12, 5
	snd_note $0D, 8
	snd_note $0D, 9
	snd_note $12, 5
	snd_note $0D, 11
	snd_note $12, 5
	snd_len 5
	snd_note $0D, 8
	snd_note $0D, 9
	snd_note $12, 5
	snd_tie
	snd_len 2
	snd_note $0D, 10
	snd_note $12, 5
	snd_note $0D, 8
	snd_note $0D, 9
	snd_note $12, 5
	snd_note $0D, 11
	snd_note $12, 5
	snd_len 5
	snd_note $0D, 8
	snd_note $0D, 9
	snd_note $12, 5
	snd_tie
	snd_len 2
	snd_note $0D, 10
	snd_note $12, 5
	snd_note $0D, 8
	snd_note $0D, 9
	snd_note $12, 5
	snd_note $0D, 11
	snd_note $12, 5
	snd_len 5
	snd_note $0D, 8
	snd_note $12, 5
	snd_tie
	snd_len 8
	snd_note $0D, 13
	snd_note $0D, 12
	snd_note $12, 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_note $0D, 9
	snd_note $12, 5
	snd_tie
	snd_len 2
	snd_note $0D, 10
	snd_note $12, 5
	snd_note $0D, 8
	snd_note $0D, 9
	snd_note $12, 5
	snd_note $0D, 11
	snd_note $12, 5
	snd_len 5
	snd_note $0D, 8
	snd_note $0D, 9
	snd_note $12, 5
	snd_tie
	snd_len 2
	snd_note $0D, 10
	snd_note $12, 5
	snd_note $0D, 8
	snd_note $0D, 9
	snd_note $12, 5
	snd_note $0D, 11
	snd_note $12, 5
	snd_len 5
	snd_note $0D, 8
	snd_note $0D, 9
	snd_note $12, 5
	snd_tie
	snd_len 2
	snd_note $0D, 10
	snd_note $12, 5
	snd_note $0D, 8
	snd_note $0D, 9
	snd_note $12, 5
	snd_note $0D, 11
	snd_note $12, 5
	snd_len 5
	snd_note $0D, 8
	snd_note $0D, 9
	snd_note $12, 5
	snd_tie
	snd_len 2
	snd_note $0D, 10
	snd_note $12, 5
	snd_note $0D, 8
	snd_note $0D, 9
	snd_note $12, 5
	snd_note $0D, 11
	snd_note $12, 5
	snd_len 5
	snd_note $0D, 8
	snd_note $0D, 9
	snd_note $12, 5
	snd_tie
	snd_len 2
	snd_note $0D, 10
	snd_note $12, 5
	snd_note $0D, 8
	snd_note $12, 5
	snd_tie
	snd_len 5
	snd_note $0D, 12
	snd_note $12, 5
	snd_len 5
	snd_note $0D
	snd_note $12
	snd_note $0D, 9
	snd_note $12, 5
	snd_tie
	snd_len 2
	snd_note $0D, 10
	snd_note $12, 5
	snd_note $0D, 8
	snd_note $12, 5
	snd_note $0D, 8
	snd_note $12, 5
	snd_note $0D, 8
	snd_note $12, 5
	snd_len 5
	snd_len 5
	snd_len 5
	snd_len 5
	snd_len 5
	snd_jump Trk_641D
	snd_end	; unreachable
Trk_6535:
	snd_tempo $BE
	snd_env $66
	snd_note G_5, 6
	snd_note Fs_5
	snd_note E_5
	snd_note B_4, 9
	snd_note Cs_5, 6
	snd_note D_5
	snd_note B_4
	snd_note Cs_5
	snd_note D_5
	snd_note E_5
	snd_note A_4, 9
	snd_note Cs_5, 6
	snd_note E_5
	snd_note Ds_5
	snd_note D_5, 3
	snd_note REST
	snd_note D_5
	snd_note REST, 7
	snd_note D_5, 3
	snd_note REST, 7
	snd_note D_5, 3
	snd_note REST, 7
	snd_note D_5, 3
	snd_end
Trk_655D:
	snd_env $66
	snd_note B_4, 6
	snd_note A_4
	snd_note G_4, 3
	snd_note REST
	snd_note G_4, 10
	snd_note REST, 9
	snd_note A_4
	snd_note REST, 6
	snd_note G_4, 10
	snd_note REST, 9
	snd_note B_4, 3
	snd_note REST
	snd_note As_4
	snd_note REST, 7
	snd_note A_4, 3
	snd_note REST, 7
	snd_note Gs_4, 3
	snd_note REST, 7
	snd_note Fs_4, 3
	snd_end
Trk_6581:
	snd_env $66
	snd_note E_3, 6
	snd_note B_3
	snd_note E_4, 3
	snd_note REST
	snd_note E_4, 10
	snd_note REST, 9
	snd_note E_3, 6
	snd_note A_3
	snd_note E_4, 3
	snd_note REST
	snd_note E_4, 10
	snd_note REST, 9
	snd_note G_4, 3
	snd_note REST
	snd_note Fs_4
	snd_note REST, 7
	snd_note F_4, 3
	snd_note REST, 7
	snd_note E_4, 3
	snd_note REST, 7
	snd_note D_4, 3
	snd_end
Trk_65A8:
	snd_tempo $AF
	snd_env $66
	snd_note A_4, 2
	snd_note As_4
	snd_note A_4
	snd_note As_4
	snd_note A_4
	snd_note As_4
	snd_note A_4
	snd_note As_4
	snd_note A_4
	snd_note As_4
	snd_note A_4
	snd_note As_4
	snd_note Ds_5
	snd_note E_5
	snd_note Ds_5
	snd_note E_5
	snd_note Ds_5
	snd_note E_5
	snd_note Ds_5
	snd_note E_5
	snd_note Ds_5
	snd_note E_5
	snd_note Ds_5
	snd_note E_5
	snd_note REST, 6
	snd_note F_5, 1
	snd_note E_5
	snd_note Ds_5
	snd_note D_5
	snd_note Cs_5, 3
	snd_note D_5
	snd_note Cs_5
	snd_note C_5
	snd_note B_4
	snd_note C_5
	snd_note B_4
	snd_note As_4
	snd_note A_4
	snd_note As_4
	snd_note A_4
	snd_note Gs_4
	snd_note G_4
	snd_note Gs_4
	snd_note G_4
	snd_note Fs_4
	snd_note F_4
	snd_note Fs_4
	snd_note G_4
	snd_note Gs_4
	snd_note A_4
	snd_note F_4
	snd_note Fs_4
	snd_note D_4
	snd_end
Trk_65E6:
	snd_env $66
	snd_note Ds_4, 2
	snd_note E_4
	snd_note Ds_4
	snd_note E_4
	snd_note Ds_4
	snd_note E_4
	snd_note Ds_4
	snd_note E_4
	snd_note Ds_4
	snd_note E_4
	snd_note Ds_4
	snd_note E_4
	snd_note A_4
	snd_note As_4
	snd_note A_4
	snd_note As_4
	snd_note A_4
	snd_note As_4
	snd_note A_4
	snd_note As_4
	snd_note A_4
	snd_note As_4
	snd_note A_4
	snd_note As_4
	snd_note REST, 9
	snd_note A_4, 3
	snd_note As_4
	snd_note A_4
	snd_note Gs_4
	snd_note G_4
	snd_note Gs_4
	snd_note G_4
	snd_note Fs_4
	snd_note F_4
	snd_note Fs_4
	snd_note F_4
	snd_note E_4
	snd_note Ds_4
	snd_note E_4
	snd_note Ds_4
	snd_note D_4
	snd_note Gs_3
	snd_note A_3
	snd_note As_3
	snd_note B_3
	snd_note C_4
	snd_note Gs_3
	snd_note A_3
	snd_note Fs_3
	snd_end
Trk_661D:
	snd_tempo $AF
	snd_env $66
	snd_note Fs_3, 3
	snd_note Fs_4
	snd_note Fs_3
	snd_note Fs_4
	snd_note G_3
	snd_note G_4
	snd_note G_3
	snd_note G_4
	snd_note Gs_3
	snd_note Gs_4
	snd_note Gs_3
	snd_note Gs_4
	snd_note A_3
	snd_note A_4
	snd_note A_3
	snd_note A_4
	snd_note B_4
	snd_note G_4
	snd_note D_4
	snd_note G_4
	snd_note B_4
	snd_note G_4
	snd_note B_4
	snd_note D_5
	snd_note Cs_5
	snd_note A_4
	snd_note E_4
	snd_note A_4
	snd_note Cs_5
	snd_note A_4
	snd_note Cs_5
	snd_note E_5
	snd_note Fs_5
	snd_note Fs_5
	snd_note REST
	snd_note G_5
	snd_note REST
	snd_note Gs_5
	snd_note REST
	snd_note A_5
	snd_end
Trk_664B:
	snd_note REST, 13
	snd_env $66
	snd_note D_4, 3
	snd_note Fs_4
	snd_note D_5
	snd_note C_5
	snd_note D_4
	snd_note B_3
	snd_note G_3
	snd_note B_3
	snd_note D_4
	snd_note B_3
	snd_note D_4
	snd_note G_4
	snd_note E_4
	snd_note Cs_4
	snd_note A_3
	snd_note Cs_4
	snd_note E_4
	snd_note Cs_4
	snd_note E_4
	snd_note A_4
	snd_note B_4
	snd_note B_4
	snd_note REST
	snd_note C_5
	snd_note REST
	snd_note Cs_5
	snd_note REST
	snd_note D_5
	snd_end
Trk_666D:
	snd_note REST, 15
	snd_note REST
	snd_env $66
	snd_note Ds_4, 3
	snd_len 3
	snd_note REST
	snd_note E_4
	snd_note REST
	snd_note F_4
	snd_note REST
	snd_note Fs_4
	snd_end
Trk_667C:
	snd_tempo $CF
	snd_env $00
	snd_note C_4, 4
	snd_note REST, 1
	snd_env $66
	snd_note E_4, 7
	snd_note E_5
	snd_note A_4, 6
	snd_note D_5
	snd_note Fs_5
	snd_note D_5
	snd_note A_5
	snd_note Fs_5
	snd_note D_5
	snd_note Fs_5
	snd_note As_4
	snd_note Ds_5
	snd_note G_5
	snd_note Ds_5
	snd_note As_5
	snd_note G_5
	snd_note Ds_5
	snd_note G_5
	snd_note E_5
	snd_note G_5
	snd_note B_5, 3
	snd_note REST
	snd_note G_5
	snd_note Gs_5
	snd_note A_5, 6
	snd_note E_5
	snd_note A_5
	snd_note Cs_6
	snd_note D_6, 3
	snd_note REST
	snd_note D_6
	snd_end
Trk_66AB:
	snd_note REST, 3
	snd_env $66
	snd_note Cs_4, 7
	snd_note Cs_5
	snd_note Cs_6, 3
	snd_note D_4, 6
	snd_note Fs_4
	snd_note A_4
	snd_note Fs_4
	snd_note D_5
	snd_note A_4
	snd_note Fs_4
	snd_note A_4
	snd_note Ds_4
	snd_note G_4
	snd_note As_4
	snd_note G_4
	snd_note Ds_5
	snd_note As_4
	snd_note G_4
	snd_note As_4
	snd_note G_4
	snd_note REST, 9
	snd_note A_4, 6
	snd_note REST, 9
	snd_note Cs_5, 3
	snd_note A_4
	snd_note Cs_5
	snd_note E_5
	snd_note Fs_5
	snd_note REST
	snd_note Fs_5
	snd_end
Trk_66D5:
	snd_env $66
	snd_note A_3, 7
	snd_note A_4
	snd_note A_5, 6
	snd_note REST
	snd_note D_4, 3
	snd_tie
	snd_len 3
	snd_note REST, 9
	snd_note REST, 12
	snd_note REST, 6
	snd_note Ds_4, 3
	snd_tie
	snd_len 3
	snd_note REST, 9
	snd_note REST
	snd_note Ds_3, 3
	snd_note As_3
	snd_note Ds_4
	snd_note G_4
	snd_note E_4, 6
	snd_note REST, 9
	snd_note E_4, 6
	snd_note REST
	snd_note A_3
	snd_note Cs_4
	snd_note E_4
	snd_note D_4, 3
	snd_note REST
	snd_note D_4
	snd_end
Trk_6702:
	snd_note $0D, 12
	snd_env $62
	snd_note $12, 3
	snd_note $0D
	snd_note $12
	snd_tie
	snd_len 3
	snd_note $0D, 9
	snd_note $0D, 12
	snd_note $12, 3
	snd_note $0D
	snd_note $12
	snd_tie
	snd_len 3
	snd_note $0D, 9
	snd_note $0D, 12
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 9
	snd_note $12, 3
	snd_note $0D
	snd_note $0D, 9
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D
	snd_note $12
	snd_end
Trk_672E:
	snd_tempo $C6
	snd_env $66
	snd_note Fs_4, 3
	snd_note A_3
	snd_note D_4
	snd_note Fs_4
	snd_note A_4
	snd_note D_4
	snd_note Fs_4
	snd_note A_4
	snd_note D_5
	snd_note Fs_4
	snd_note A_4
	snd_note D_5
	snd_note Fs_5
	snd_note A_4
	snd_note D_5
	snd_note Fs_5
	snd_note G_4
	snd_note As_3
	snd_note Ds_4
	snd_note G_4
	snd_note As_4
	snd_note Ds_4
	snd_note G_4
	snd_note As_4
	snd_note Ds_5
	snd_note G_4
	snd_note As_4
	snd_note Ds_5
	snd_note G_5
	snd_note As_4
	snd_note Ds_5
	snd_note G_5
	snd_note A_5
	snd_note A_3
	snd_note Cs_4
	snd_note E_4
	snd_note A_4
	snd_note E_4
	snd_note A_4
	snd_note Cs_5
	snd_note E_5
	snd_note Cs_5
	snd_note E_5
	snd_note A_5
	snd_note Cs_6
	snd_note E_5
	snd_note A_5
	snd_note Cs_6
	snd_note D_6, 12
	snd_end
Trk_6766:
	snd_env $66
	snd_note A_3, 3
	snd_note D_3
	snd_note Fs_3
	snd_note A_3
	snd_note D_4
	snd_note Fs_3
	snd_note A_3
	snd_note D_4
	snd_note Fs_4
	snd_note A_3
	snd_note D_4
	snd_note Fs_4
	snd_note A_4
	snd_note D_4
	snd_note Fs_4
	snd_note A_4
	snd_note As_3
	snd_note Ds_3
	snd_note G_3
	snd_note As_3
	snd_note Ds_4
	snd_note G_3
	snd_note As_3
	snd_note Ds_4
	snd_note G_4
	snd_note As_3
	snd_note Ds_4
	snd_note G_4
	snd_note As_4
	snd_note Ds_4
	snd_note G_4
	snd_note As_4
	snd_note Cs_4
	snd_note E_3
	snd_note A_3
	snd_note Cs_4
	snd_note E_4
	snd_note A_3
	snd_note Cs_4
	snd_note E_4
	snd_note A_4
	snd_note E_4
	snd_note A_4
	snd_note Cs_5
	snd_note E_5
	snd_note A_4
	snd_note Cs_5
	snd_note E_5
	snd_note Fs_5, 12
	snd_end
Trk_679C:
	snd_note REST, 12
	snd_env $66
	snd_note D_3, 6
	snd_note Fs_3
	snd_note A_3
	snd_note D_4
	snd_note REST, 12
	snd_note Ds_3, 6
	snd_note G_3
	snd_note As_3
	snd_note Ds_4
	snd_note REST, 12
	snd_note A_2, 3
	snd_note Cs_3
	snd_note E_3
	snd_note A_3
	snd_note Cs_4
	snd_note E_4
	snd_note A_4
	snd_note Cs_5
	snd_note D_5, 12
	snd_end
Trk_67BA:
	snd_env $62
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_note $0D
	snd_note $12
	snd_note $0D
	snd_note $12
	snd_note $0D
	snd_note $12
	snd_note $0D
	snd_note $12
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_note $0D
	snd_note $12
	snd_note $0D
	snd_note $12
	snd_note $0D
	snd_note $12
	snd_note $0D
	snd_note $12
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D
	snd_note $12
	snd_note $0D
	snd_note $12
	snd_note $12
	snd_note $12
	snd_note $12
	snd_note $12
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_end
Trk_67EF:
	snd_tempo $AF
	snd_env $66
	snd_note B_5, 3
	snd_note G_5
	snd_note D_5
	snd_note B_4
	snd_note G_4, 9
	snd_note B_4
	snd_note D_5
	snd_note C_5, 6
	snd_note B_4
	snd_note C_5, 9
	snd_note REST, 6
	snd_note C_5
	snd_note B_4
	snd_note C_5
	snd_note D_5
	snd_note REST
	snd_note B_4, 9
	snd_note D_5
	snd_note G_5
	snd_note F_5, 6
	snd_note E_5
	snd_note F_5, 10
	snd_note A_5, 6
	snd_note G_5
	snd_note F_5
	snd_note E_5
	snd_note REST
	snd_note C_5, 5
	snd_note D_5
	snd_note E_5
	snd_note Fs_5, 6
	snd_note D_5
	snd_note A_5
	snd_note Fs_5
	snd_note Gs_5
	snd_note A_5
	snd_note B_5
	snd_note Gs_5
	snd_note A_5
	snd_note F_5
	snd_note C_6
	snd_note A_5
	snd_jump Trk_67EF
	snd_end	; unreachable
Trk_682C:
	snd_note REST, 9
	snd_env $66
	snd_note B_3
	snd_note D_4
	snd_note G_4
	snd_note F_4, 6
	snd_note D_4
	snd_note F_4, 9
	snd_note REST, 6
	snd_note F_4
	snd_note D_4
	snd_note F_4
	snd_note G_4
	snd_note REST
	snd_note D_4, 9
	snd_note G_4
	snd_note B_4
	snd_note A_4, 6
	snd_note G_4
	snd_note A_4, 10
	snd_note C_5, 6
	snd_note B_4
	snd_note A_4
	snd_note G_4, 12
	snd_note A_4
	snd_note B_4
	snd_note C_5, 6
	snd_note A_4
	snd_note F_4
	snd_note C_4
	snd_jump Trk_682C
	snd_end	; unreachable
Trk_6859:
	snd_env $66
	snd_note G_3, 13
	snd_note REST, 6
	snd_note G_3, 3
	snd_len 3
	snd_len 13
	snd_note REST, 9
	snd_note G_3, 13
	snd_note REST, 6
	snd_note G_3, 3
	snd_len 3
	snd_note D_4, 10
	snd_note REST, 6
	snd_note D_4, 10
	snd_note REST, 6
	snd_note C_4, 7
	snd_note REST, 3
	snd_note C_4, 7
	snd_note REST, 3
	snd_note D_4, 7
	snd_note REST, 3
	snd_note D_4, 7
	snd_note REST, 3
	snd_note E_4, 7
	snd_note REST, 3
	snd_note E_4, 7
	snd_note REST, 3
	snd_note F_4, 6
	snd_note C_4
	snd_note A_3
	snd_note F_3
	snd_jump Trk_6859
	snd_end	; unreachable
Trk_6895:
	snd_env $62
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 9
	snd_note $12, 3
	snd_len 3
	snd_len 3
	snd_tie
	snd_len 3
	snd_note $0D, 9
	snd_note $12, 3
	snd_len 3
	snd_len 3
	snd_note $0D
	snd_note $12
	snd_note $0D
	snd_note $12
	snd_note $0D
	snd_note $12
	snd_note $0D
	snd_note $12
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 9
	snd_note $12, 3
	snd_len 3
	snd_len 3
	snd_tie
	snd_len 3
	snd_note $0D, 9
	snd_note $12, 3
	snd_len 3
	snd_len 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D
	snd_note $12
	snd_note $12
	snd_note $12
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_note $0D
	snd_note $12
	snd_note $12
	snd_jump Trk_6895
	snd_end	; unreachable
Trk_68F4:
	snd_tempo $BA
	snd_env $00
	snd_note C_4, 4
	snd_tie
	snd_len 1
	snd_note REST, 9
	snd_env $66
	snd_note G_4
	snd_note A_4, 6
	snd_note As_4
	snd_note B_4
	snd_note C_5, 3
	snd_note G_4
	snd_note C_4
	snd_note REST, 7
	snd_note G_4, 3
	snd_note C_5
	snd_note E_5, 6
	snd_note G_4, 3
	snd_note REST
	snd_note E_4
	snd_note G_4
	snd_note C_5
	snd_note E_5
	snd_note F_5, 10
	snd_note REST, 6
	snd_note F_5, 7
	snd_note G_5
	snd_note A_5, 6
	snd_note E_5, 10
	snd_note REST, 6
	snd_note G_5, 7
	snd_note F_5
	snd_note E_5, 6
	snd_note F_5, 10
	snd_note REST, 6
	snd_note Gs_5, 1
	snd_note A_5, 6
	snd_tie
	snd_len 1
	snd_note G_5, 7
	snd_note F_5, 6
	snd_note E_5
	snd_note F_5
	snd_note G_5
	snd_note E_5, 9
	snd_note D_5, 6
	snd_note C_5, 7
	snd_note REST, 3
	snd_note F_5, 10
	snd_note REST, 6
	snd_note F_5, 7
	snd_note G_5
	snd_note A_5, 6
	snd_note E_5, 10
	snd_note REST, 3
	snd_note Gs_5, 1
	snd_note A_5
	snd_note As_5, 7
	snd_note A_5
	snd_note G_5, 6
	snd_note F_5, 10
	snd_note REST, 6
	snd_note D_5, 7
	snd_note E_5
	snd_note F_5, 6
	snd_note G_5, 9
	snd_note A_5
	snd_note As_5
	snd_note E_5
	snd_note F_5, 10
	snd_note REST, 3
	snd_note A_5, 1
	snd_note As_5
	snd_note C_6, 7
	snd_note As_5
	snd_note A_5, 4
	snd_note REST, 1
	snd_note A_5, 9
	snd_note G_5
	snd_note As_5
	snd_note E_5
	snd_note F_5, 12
	snd_note G_5
	snd_note A_5, 10
	snd_note REST, 4
	snd_note Gs_5, 1
	snd_note A_5, 7
	snd_note As_5
	snd_note C_6, 6
	snd_note As_5, 10
	snd_note D_5, 3
	snd_note REST
	snd_note D_5, 9
	snd_note REST, 6
	snd_note C_5, 3
	snd_note D_5
	snd_note E_5, 9
	snd_note F_5
	snd_note G_5
	snd_note E_5
	snd_note F_5, 15
	snd_tie
	snd_len 15
	snd_jump Trk_68F4
	snd_end	; unreachable
Trk_699F:
	snd_env $66
	snd_note C_6, 6
	snd_note C_5, 3
	snd_note REST, 7
	snd_note C_6, 9
	snd_note A_5, 6
	snd_note As_5
	snd_note B_5
	snd_note C_6
	snd_note C_5, 3
	snd_note REST, 7
	snd_note C_6, 12
	snd_note REST, 6
	snd_note A_4, 3
	snd_note REST
	snd_note F_4
	snd_note REST
	snd_note C_5
	snd_note REST
	snd_note F_4
	snd_note REST
	snd_note A_4
	snd_note F_4
	snd_note C_5
	snd_note REST
	snd_note A_4
	snd_note REST
	snd_note F_4
	snd_note REST
	snd_note G_4
	snd_note REST
	snd_note E_4
	snd_note REST
	snd_note C_5
	snd_note REST
	snd_note E_4
	snd_note REST
	snd_note G_4
	snd_note E_4
	snd_note C_5
	snd_note REST
	snd_note G_4
	snd_note REST
	snd_note E_4
	snd_note REST
	snd_note F_4
	snd_note REST
	snd_note D_4
	snd_note REST
	snd_note A_4
	snd_note REST
	snd_note D_4
	snd_note REST
	snd_note F_4
	snd_note D_4
	snd_note A_4
	snd_note REST
	snd_note F_4
	snd_note REST
	snd_note D_4
	snd_note REST
	snd_note E_4
	snd_note REST
	snd_note C_4
	snd_note REST
	snd_note G_4
	snd_note REST
	snd_note C_4
	snd_note REST
	snd_note E_4
	snd_note C_4
	snd_note As_4
	snd_note REST
	snd_note G_4
	snd_note REST
	snd_note E_4
	snd_note REST
	snd_note A_4
	snd_note REST
	snd_note F_4
	snd_note REST
	snd_note C_5
	snd_note REST
	snd_note F_4
	snd_note REST
	snd_note A_4
	snd_note F_4
	snd_note C_5
	snd_note REST
	snd_note A_4
	snd_note REST
	snd_note F_4
	snd_note REST
	snd_note G_4
	snd_note REST
	snd_note E_4
	snd_note REST
	snd_note C_5
	snd_note REST
	snd_note E_4
	snd_note REST
	snd_note G_4
	snd_note E_4
	snd_note C_5
	snd_note REST
	snd_note G_4
	snd_note REST
	snd_note E_4
	snd_note REST
	snd_note F_4
	snd_note REST
	snd_note D_4
	snd_note REST
	snd_note A_4
	snd_note REST
	snd_note D_4
	snd_note REST
	snd_note F_4
	snd_note D_4
	snd_note A_4
	snd_note REST
	snd_note F_4
	snd_note REST
	snd_note D_4
	snd_note REST
	snd_note G_4
	snd_note REST
	snd_note E_4
	snd_note REST
	snd_note C_5
	snd_note REST
	snd_note G_4
	snd_note REST
	snd_note E_5
	snd_note G_4
	snd_note D_5, 6
	snd_note C_5, 3
	snd_note E_4
	snd_note As_4, 6
	snd_note A_4, 3
	snd_note REST
	snd_note F_4
	snd_note REST
	snd_note D_5
	snd_note REST
	snd_note F_4
	snd_note REST
	snd_note A_4
	snd_note F_4
	snd_note D_5
	snd_note REST
	snd_note A_4
	snd_note REST
	snd_note F_4
	snd_note REST
	snd_note G_4
	snd_note REST
	snd_note E_4
	snd_note REST
	snd_note C_5
	snd_note REST
	snd_note E_4
	snd_note REST
	snd_note G_4
	snd_note E_4
	snd_note C_5
	snd_note REST
	snd_note G_4
	snd_note REST
	snd_note As_4
	snd_note REST
	snd_note A_4
	snd_note REST
	snd_note F_4
	snd_note REST
	snd_note D_5
	snd_note REST
	snd_note F_4
	snd_note REST
	snd_note As_4
	snd_note E_4
	snd_note Cs_5
	snd_note REST
	snd_note G_4
	snd_note Cs_4
	snd_note G_4
	snd_note As_4
	snd_note A_4
	snd_note REST
	snd_note Fs_4
	snd_note REST
	snd_note C_5
	snd_note REST
	snd_note Fs_4
	snd_note REST
	snd_note A_4
	snd_note Fs_4
	snd_note C_5
	snd_note REST
	snd_note A_4
	snd_note REST
	snd_note Fs_4
	snd_note REST
	snd_note G_4
	snd_note REST
	snd_note D_4
	snd_note REST
	snd_note As_4
	snd_note REST
	snd_note D_4
	snd_note REST
	snd_note G_4
	snd_note D_4
	snd_note As_4
	snd_note REST
	snd_note G_4
	snd_note REST
	snd_note D_4
	snd_note REST
	snd_note G_4
	snd_note REST
	snd_note E_4
	snd_note REST
	snd_note C_5
	snd_note REST
	snd_note E_4
	snd_note REST
	snd_note G_4
	snd_note E_4
	snd_note C_5
	snd_note REST
	snd_note G_4
	snd_note REST
	snd_note E_4
	snd_note REST
	snd_note As_3
	snd_note D_4
	snd_note F_4
	snd_note A_4
	snd_note C_5
	snd_note REST
	snd_note D_6
	snd_note D_5
	snd_note C_6
	snd_note As_4
	snd_note F_4
	snd_note As_5
	snd_note As_4
	snd_note F_4
	snd_note A_5
	snd_note As_4
	snd_note Gs_5
	snd_note D_4
	snd_note F_4
	snd_note Gs_4
	snd_note B_4
	snd_note F_4
	snd_note Gs_4
	snd_note B_4
	snd_note D_5
	snd_note F_5
	snd_note Gs_5
	snd_note B_5
	snd_note D_6
	snd_note C_6
	snd_note B_5, 6
	snd_jump Trk_699F
	snd_end	; unreachable
Trk_6ABD:
	snd_env $66
	snd_note C_2, 6
	snd_note G_2
	snd_note C_3
	snd_note E_3, 9
	snd_note F_3, 6
	snd_note Fs_3
	snd_note G_3
	snd_note C_2
	snd_note G_2
	snd_note E_3
	snd_note C_3, 9
	snd_note As_2, 6
	snd_note A_2
	snd_note G_2
	snd_note F_3, 9
	snd_note REST, 6
	snd_note F_3, 3
	snd_note REST
	snd_note F_3, 9
	snd_note REST
	snd_note E_3
	snd_note REST, 6
	snd_note E_3, 3
	snd_note REST
	snd_note E_3, 9
	snd_note REST
	snd_note D_3
	snd_note REST, 6
	snd_note D_3, 3
	snd_note REST
	snd_note D_3, 9
	snd_note REST
	snd_note C_3
	snd_note REST, 6
	snd_note C_3, 3
	snd_note REST
	snd_note C_3
	snd_note REST
	snd_note C_3, 6
	snd_note D_3
	snd_note E_3
	snd_note F_3, 9
	snd_note REST, 6
	snd_note F_3, 3
	snd_note REST
	snd_note F_3, 9
	snd_note REST
	snd_note E_3
	snd_note REST, 6
	snd_note E_3, 3
	snd_note REST
	snd_note E_3, 9
	snd_note REST
	snd_note D_3
	snd_note REST, 6
	snd_note D_3, 3
	snd_note REST
	snd_note D_3, 9
	snd_note REST
	snd_note C_3
	snd_note REST, 6
	snd_note C_3, 3
	snd_note REST
	snd_note C_3, 1
	snd_note REST
	snd_note C_3, 3
	snd_note G_3, 6
	snd_note E_3
	snd_note C_3
	snd_note As_2, 9
	snd_note REST, 6
	snd_note As_2, 3
	snd_note REST
	snd_note As_2, 9
	snd_note REST
	snd_note C_3
	snd_note REST, 6
	snd_note C_3
Trk_6B33:
	snd_len 3
	snd_note REST
	snd_note C_3, 9
	snd_note REST, 6
	snd_note Cs_3
	snd_note D_3, 9
	snd_note REST, 6
	snd_note D_3
	snd_note E_3, 9
	snd_note REST, 6
	snd_note E_3
	snd_note Fs_3, 9
	snd_note REST, 6
	snd_note Fs_3, 3
	snd_note REST
	snd_note Fs_3, 9
	snd_note C_3, 6
	snd_note Fs_3
	snd_note G_3, 9
	snd_note REST, 6
	snd_note G_3, 3
	snd_note REST
	snd_note G_3, 9
	snd_note REST, 6
	snd_note D_3
	snd_note C_3, 9
	snd_note REST, 6
	snd_note C_3, 3
	snd_note REST
	snd_note C_3, 9
	snd_note REST, 6
	snd_note B_2
	snd_note As_2, 9
	snd_note REST, 6
	snd_note As_2, 3
	snd_note REST
	snd_note As_2, 9
	snd_note F_3, 6
	snd_note As_2
	snd_note B_2, 9
	snd_note REST, 6
	snd_note B_2, 3
	snd_note REST
	snd_note B_2, 6
	snd_note Gs_3
	snd_note F_3
	snd_note D_3
	snd_jump Trk_6ABD
	snd_end	; unreachable
Trk_6B84:
	snd_env $62
	snd_note $12, 3
	snd_note $0D
	snd_note $12
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D
	snd_note $12
	snd_note $0D
	snd_note $12
	snd_note $0D
	snd_note $12
	snd_note $0D
	snd_note $12
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D
	snd_note $12
	snd_note $12
	snd_note $12
	snd_note $12
	snd_note $0D, 9
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $0D, 9
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $0D, 9
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $0D, 9
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_note $0D
	snd_note $12
	snd_note $0D
	snd_note $0D, 9
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $0D, 9
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $0D, 9
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $0D, 9
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 9
	snd_note $12, 3
	snd_note $0D
	snd_note $12
	snd_note $12
	snd_note $12
	snd_note $0D
	snd_note $0D, 9
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $0D, 9
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $0D, 9
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $0D, 9
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 9
	snd_note $12, 3
	snd_note $0D
	snd_note $12
	snd_note $0D
	snd_note $12
	snd_note $12
	snd_note $0D, 9
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $0D, 9
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $0D, 9
	snd_note $12, 3
	snd_tie
	snd_len 3
	snd_note $0D, 10
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_note $0D, 7
	snd_note $12, 3
	snd_len 3
	snd_len 3
	snd_note $0D
	snd_jump Trk_6B84
	snd_end	; unreachable
SndUnused_6C77:
	snd_note $0D, 5
	snd_note $4A, 2
	snd_note $0D, 12
	snd_note $0D, 5
	snd_note $46, 2
	snd_note $43, 5
	snd_note $46, 6
	snd_note $48, 2
	snd_note $49, 5
	snd_note $48, 2
	snd_note $49, 5
	snd_note $4A, 2
	snd_note $53, 5
	snd_note $49, 6
	snd_note $48, 2
	snd_note $46, 5
	snd_note $43, 2
	snd_note $0D, 5
	snd_note $4A, 2
	snd_note $0D, 5
	snd_note $51, 2
	snd_note $0D, 5
	snd_note $48, 2
	snd_note $0D, 5
	snd_note $4A, 2
	snd_note $0D, 12
	snd_jump Trk_6B33
	snd_end	; unreachable
SndUnused_6CAF:
	snd_note $0D, 5
	snd_env $73
	snd_note $3A, 2
	snd_note $4A
	snd_note $0D, 5
	snd_note $48, 2
	snd_note $0D, 5
	snd_note $46, 2
	snd_note $0D, 8
	snd_note $41
	snd_note $42, 2
	snd_note $0D, 5
	snd_note $43, 2
	snd_note $0D, 5
	snd_env $69
	snd_note $46
	snd_note $43, 2
	snd_note $41, 5
	snd_note $46, 8
	snd_note $43, 2
	snd_note $0D, 8
	snd_note $41
	snd_note $40, 2
	snd_note $0D, 5
	snd_note $3A, 2
	snd_note $0D, 5
	snd_note $0D
	snd_env $73
	snd_note $3A, 2
	snd_note $4A
	snd_note $0D, 5
	snd_note $48, 2
	snd_note $0D, 5
	snd_note $46, 2
	snd_note $0D, 8
	snd_note $41
	snd_note $42, 2
	snd_note $0D, 5
	snd_note $43, 2
	snd_note $0D, 5
	snd_note $0D
	snd_env $69
	snd_note $53, 2
	snd_note $51, 6
	snd_note $53
	snd_note $51, 5
	snd_note $4A, 6
	snd_note $48, 2
	snd_note $46, 5
	snd_note $44, 2
	snd_note $43, 5
	snd_note $41, 2
	snd_note $43, 5
	snd_note $41, 2
	snd_note $0D, 5
	snd_env $73
	snd_note $3A, 2
	snd_note $4A
	snd_note $0D, 5
	snd_note $48, 2
	snd_note $0D, 5
	snd_note $46, 2
	snd_note $0D, 8
	snd_note $41
	snd_note $42, 2
	snd_note $0D, 5
	snd_note $43, 2
	snd_note $0D, 5
	snd_env $69
	snd_note $46
	snd_note $43, 2
	snd_note $41, 5
	snd_note $46, 8
	snd_note $43, 2
	snd_note $0D, 8
	snd_note $41
	snd_note $40, 2
	snd_note $0D, 5
	snd_note $3A, 2
	snd_note $0D, 5
	snd_note $0D
	snd_env $73
	snd_note $3A, 2
	snd_note $4A
	snd_note $0D, 5
	snd_note $48, 2
	snd_note $0D, 5
	snd_note $46, 2
	snd_note $0D, 8
	snd_note $41
	snd_note $42, 2
	snd_note $0D, 5
	snd_note $43, 2
	snd_note $0D, 5
	snd_env $69
	snd_note $46
	snd_note $43, 2
	snd_note $41, 5
	snd_note $43, 2
	snd_note $46, 5
	snd_note $48
	snd_note $0D, 8
	snd_env $73
	snd_note $3A
	snd_note $39, 2
	snd_note $0D, 5
	snd_note $38, 2
	snd_note $0D, 5
	snd_note $0D, 15
	snd_note $0D, 5
	snd_note $31, 2
	snd_note $33
	snd_note $0D, 5
	snd_note $36
	snd_note $33, 2
	snd_note $36, 5
	snd_note $41, 6
	snd_note $36, 2
	snd_note $31, 5
	snd_note $32, 2
	snd_note $33
	snd_note $0D
	snd_note $39, 6
	snd_note $3A, 2
	snd_note $0D, 15
	snd_note $0D, 5
	snd_note $45, 2
	snd_note $3A
	snd_note $0D, 5
	snd_note $42
	snd_note $48, 2
	snd_tie
	snd_len 0
	snd_note $0D, 7
	snd_note $32, 2
	snd_note $0D, 5
	snd_note $36, 2
	snd_note $35
	snd_note $34
	snd_note $33
	snd_note $32
	snd_note $0D, 5
	snd_note $0D, 15
	snd_note $46, 5
	snd_note $43, 2
	snd_note $3A, 5
	snd_note $41, 2
	snd_note $0D, 5
	snd_note $42, 2
	snd_note $0D, 5
	snd_note $43, 2
	snd_note $0D, 5
	snd_note $36, 2
	snd_note $33, 5
	snd_note $31, 2
	snd_note $33, 5
	snd_note $36, 2
	snd_note $38, 5
	snd_note $3A, 2
	snd_note $0D, 5
	snd_note $43, 2
	snd_note $3B, 5
	snd_note $43, 6
	snd_note $45, 2
	snd_note $46, 5
	snd_note $45, 2
	snd_note $46
	snd_note $43
	snd_note $46
	snd_note $4A, 5
	snd_note $46, 6
	snd_note $45, 2
	snd_note $43, 5
	snd_note $3B, 2
	snd_note $0D, 5
	snd_note $45, 2
	snd_note $0D, 5
	snd_note $48, 2
	snd_note $0D, 5
	snd_note $43, 2
	snd_note $0D, 5
	snd_note $45, 2
	snd_note $0D, 12
	snd_jump SndUnused_6CAF
	snd_end	; unreachable
SndUnused_6DFF:
	snd_env $6D
	snd_note $23, 5
	snd_note $0D, 2
	snd_note $23, 5
	snd_note $26, 8
	snd_note $27, 6
	snd_note $28
	snd_note $26
	snd_note $23
	snd_note $21
	snd_note $23, 5
	snd_note $0D, 2
	snd_note $23, 5
	snd_note $26, 8
	snd_note $27, 6
	snd_note $28
	snd_note $29
	snd_note $2A
	snd_note $31
	snd_note $23, 5
	snd_note $0D, 2
	snd_note $23, 5
	snd_note $26, 8
	snd_note $27, 6
	snd_note $28
	snd_note $26
	snd_note $23
	snd_note $21
	snd_note $23, 5
	snd_note $0D, 2
	snd_note $23, 5
	snd_note $26, 8
	snd_note $27, 6
	snd_note $28
	snd_note $29
	snd_note $2A
	snd_note $21, 5
	snd_note $22, 2
	snd_note $23, 5
	snd_note $0D, 2
	snd_note $23, 5
	snd_note $26, 8
	snd_note $27, 6
	snd_note $28
	snd_note $26
	snd_note $23
	snd_note $21
	snd_note $23, 5
	snd_note $0D, 2
	snd_note $23, 5
	snd_note $26, 8
	snd_note $27, 6
	snd_note $28
	snd_note $29
	snd_note $2A
	snd_note $31
	snd_note $23, 5
	snd_note $0D, 2
	snd_note $23, 5
	snd_note $26, 8
	snd_note $27, 6
	snd_note $28
	snd_note $26
	snd_note $23
	snd_note $21
	snd_note $23, 5
	snd_note $0D, 2
	snd_note $23, 5
	snd_note $26, 8
	snd_note $27, 6
	snd_note $28, 5
	snd_note $26, 8
	snd_note $25, 2
	snd_note $0D, 5
	snd_note $24, 2
	snd_note $26
	snd_note $27
	snd_note $28, 5
	snd_note $0D, 2
	snd_note $28, 5
	snd_note $26, 8
	snd_note $2A, 6
	snd_note $28
	snd_note $26
	snd_note $23
	snd_note $21
	snd_note $23, 5
	snd_note $0D, 2
	snd_note $23, 5
	snd_note $26, 8
	snd_note $27, 6
	snd_note $28
	snd_note $29
	snd_note $2A
	snd_note $31
	snd_note $2B, 5
	snd_note $0D, 2
	snd_note $1B, 5
	snd_note $26, 8
	snd_note $1B, 6
	snd_note $22
	snd_note $23
	snd_note $21
	snd_note $1B
	snd_note $1A, 5
	snd_note $0D, 2
	snd_note $2A, 5
	snd_note $21, 8
	snd_note $22, 6
	snd_note $25
	snd_note $28
	snd_note $29
	snd_note $2A
	snd_note $28, 5
	snd_note $0D, 2
	snd_note $28, 5
	snd_note $26, 8
	snd_note $2A, 6
	snd_note $28
	snd_note $26
	snd_note $23
	snd_note $21
	snd_note $23, 5
	snd_note $0D, 2
	snd_note $23, 5
	snd_note $26, 8
	snd_note $27, 6
	snd_note $28
	snd_note $29
	snd_note $2A
	snd_note $31
	snd_note $28, 5
	snd_note $0D, 2
	snd_note $28, 5
	snd_note $26, 8
	snd_note $23, 6
	snd_note $28
	snd_note $26
	snd_note $23
	snd_note $1B
	snd_note $1A, 5
	snd_note $2A, 2
	snd_note $0D, 5
	snd_note $2A, 2
	snd_note $0D, 5
	snd_note $29, 2
	snd_note $0D, 5
	snd_note $2A, 2
	snd_note $0D, 5
	snd_note $21, 2
	snd_note $22, 6
	snd_note $25
	snd_note $1A
	snd_jump SndUnused_6DFF
	snd_end	; unreachable
SndUnused_6EFA:
	snd_env $55
	snd_note $30, 2
	snd_note $0D, 5
	snd_env $41
	snd_note $30, 2
	snd_note $0D, 5
	snd_env $7D
	snd_note $30, 2
	snd_note $0D, 8
	snd_env $69
	snd_note $30, 2
	snd_note $0D, 5
	snd_note $30, 2
	snd_note $0D, 6
	snd_env $7D
	snd_note $30, 2
	snd_note $0D, 8
	snd_env $41
	snd_note $30, 2
	snd_env $55
	snd_len 2
	snd_note $0D, 5
	snd_env $41
	snd_note $30, 2
	snd_note $0D, 5
	snd_env $7D
	snd_note $30, 2
	snd_note $0D, 8
	snd_env $69
	snd_note $30, 2
	snd_note $0D, 5
	snd_note $30, 2
	snd_note $0D, 6
	snd_env $7D
	snd_note $30, 2
	snd_note $0D, 5
	snd_env $69
	snd_note $30, 2
	snd_note $0D
	snd_env $41
	snd_note $30
	snd_env $55
	snd_note $30
	snd_note $0D, 5
	snd_env $41
	snd_note $30, 2
	snd_note $0D, 5
	snd_env $7D
	snd_note $30, 2
	snd_note $0D, 8
	snd_env $69
	snd_note $30, 2
	snd_note $0D, 5
	snd_note $30, 2
	snd_note $0D, 6
	snd_env $7D
	snd_note $30, 2
	snd_note $0D, 8
	snd_env $41
	snd_note $30, 2
	snd_env $55
	snd_len 2
	snd_note $0D, 5
	snd_env $41
	snd_note $30, 2
	snd_note $0D, 5
	snd_env $7D
	snd_note $30, 2
	snd_note $0D, 8
	snd_env $69
	snd_note $30, 2
	snd_note $0D, 5
	snd_note $30, 2
	snd_note $0D, 6
	snd_env $7D
	snd_note $30, 2
	snd_note $0D, 5
	snd_env $69
	snd_note $30, 2
	snd_note $0D
	snd_env $41
	snd_note $30
	snd_env $55
	snd_note $30
	snd_note $0D, 5
	snd_env $41
	snd_note $30, 2
	snd_note $0D, 5
	snd_env $7D
	snd_note $30, 2
	snd_note $0D, 8
	snd_env $69
	snd_note $30, 2
	snd_note $0D, 5
	snd_note $30, 2
	snd_note $0D, 6
	snd_env $7D
	snd_note $30, 2
	snd_note $0D, 8
	snd_env $41
	snd_note $30, 2
	snd_env $55
	snd_len 2
	snd_note $0D, 5
	snd_env $41
	snd_note $30, 2
	snd_note $0D, 5
	snd_env $7D
	snd_note $30, 2
	snd_note $0D, 8
	snd_env $69
	snd_note $30, 2
	snd_note $0D, 5
	snd_note $30, 2
	snd_note $0D, 6
	snd_env $7D
	snd_note $30, 2
	snd_note $0D, 5
	snd_env $69
	snd_note $30, 2
	snd_note $0D
	snd_env $41
	snd_note $30
	snd_env $55
	snd_note $30
	snd_note $0D, 5
	snd_env $41
	snd_note $30, 2
	snd_note $0D, 5
	snd_env $7D
	snd_note $30, 2
	snd_note $0D, 8
	snd_env $69
	snd_note $30, 2
	snd_note $0D, 5
	snd_note $30, 2
	snd_note $0D, 6
	snd_env $7D
	snd_note $30, 2
	snd_note $0D, 8
	snd_env $41
	snd_note $30, 2
	snd_env $55
	snd_len 2
	snd_note $0D, 5
	snd_env $41
	snd_note $30, 2
	snd_note $0D, 5
	snd_env $7D
	snd_note $30, 2
	snd_note $0D, 8
	snd_env $69
	snd_note $30, 2
	snd_note $0D, 5
	snd_env $7D
	snd_note $30, 2
	snd_note $0D, 6
	snd_note $30, 2
	snd_note $0D, 5
	snd_env $69
	snd_note $30, 2
	snd_note $0D
	snd_env $41
	snd_note $30
	snd_env $55
	snd_note $30
	snd_note $0D, 5
	snd_env $41
	snd_note $30, 2
	snd_note $0D, 5
	snd_env $7D
	snd_note $30, 2
	snd_note $0D, 8
	snd_env $69
	snd_note $30, 2
	snd_note $0D, 5
	snd_note $30, 2
	snd_note $0D, 6
	snd_env $7D
	snd_note $30, 2
	snd_note $0D, 8
	snd_env $41
	snd_note $30, 2
	snd_env $55
	snd_len 2
	snd_note $0D, 5
	snd_env $41
	snd_note $30, 2
	snd_note $0D, 5
	snd_env $7D
	snd_note $30, 2
	snd_note $0D, 8
	snd_env $69
	snd_note $30, 2
	snd_note $0D, 5
	snd_note $30, 2
	snd_note $0D, 6
	snd_env $7D
	snd_note $30, 2
	snd_note $0D, 5
	snd_env $69
	snd_note $30, 2
	snd_note $0D
	snd_env $41
	snd_note $30
	snd_env $55
	snd_note $30
	snd_note $0D, 5
	snd_env $41
	snd_note $30, 2
	snd_note $0D, 5
	snd_env $7D
	snd_note $30, 2
	snd_note $0D, 8
	snd_env $69
	snd_note $30, 2
	snd_note $0D, 5
	snd_note $30, 2
	snd_note $0D, 6
	snd_env $7D
	snd_note $30, 2
	snd_note $0D, 8
	snd_env $41
	snd_note $30, 2
	snd_env $55
	snd_len 2
	snd_note $0D, 5
	snd_env $41
	snd_note $30, 2
	snd_note $0D, 5
	snd_env $7D
	snd_note $30, 2
	snd_note $0D, 8
	snd_env $69
	snd_note $30, 2
	snd_note $0D, 5
	snd_note $30, 2
	snd_note $0D, 6
	snd_env $7D
	snd_note $30, 2
	snd_note $0D, 5
	snd_env $69
	snd_note $30, 2
	snd_note $0D
	snd_env $41
	snd_note $30
	snd_env $55
	snd_note $30
	snd_note $0D, 5
	snd_env $41
	snd_note $30, 2
	snd_note $0D, 5
	snd_env $7D
	snd_note $30, 2
	snd_note $0D, 8
	snd_env $69
	snd_note $30, 2
	snd_note $0D, 5
	snd_note $30, 2
	snd_note $0D, 6
	snd_env $7D
	snd_note $30, 2
	snd_note $0D, 8
	snd_env $41
	snd_note $30, 2
	snd_env $55
	snd_len 2
	snd_note $0D, 5
	snd_env $41
	snd_note $30, 2
	snd_note $0D, 5
	snd_env $7D
	snd_note $30, 2
	snd_note $0D, 8
	snd_env $69
	snd_note $30, 2
	snd_note $0D, 5
	snd_note $30, 2
	snd_note $0D, 6
	snd_env $7D
	snd_note $30, 2
	snd_note $0D, 5
	snd_env $69
	snd_note $30, 2
	snd_note $0D
	snd_env $41
	snd_note $30
	snd_env $55
	snd_note $30
	snd_note $0D, 5
	snd_env $41
	snd_note $30, 2
	snd_note $0D, 5
	snd_env $7D
	snd_note $30, 2
	snd_note $0D, 8
	snd_env $69
	snd_note $30, 2
	snd_note $0D, 5
	snd_note $30, 2
	snd_note $0D, 6
	snd_env $7D
	snd_note $30, 2
	snd_note $0D, 8
	snd_env $41
	snd_note $30, 2
	snd_env $55
	snd_len 2
	snd_note $0D
	snd_env $7D
	snd_note $30
	snd_note $0D, 5
	snd_note $30, 2
	snd_note $0D, 5
	snd_note $30, 2
	snd_note $0D, 5
	snd_note $30, 2
	snd_note $0D, 5
	snd_env $41
	snd_note $30, 2
	snd_env $7D
	snd_len 2
	snd_env $55
	snd_len 2
	snd_env $41
	snd_len 2
	snd_env $7D
	snd_len 2
	snd_note $0D
	snd_env $55
	snd_note $30
	snd_env $69
	snd_note $30
	snd_note $0D
	snd_env $7D
	snd_note $30
	snd_jump SndUnused_6EFA
	snd_end	; unreachable
SndUnused_7176:
	snd_tempo $80
Trk_7178:
	snd_note $0D, 6
	snd_env $7D
	snd_note $34, 5
	snd_note $37, 2
	snd_note $0D, 5
	snd_note $36, 2
	snd_note $35
	snd_note $0D, 5
	snd_note $34, 2
	snd_tie
	snd_len 5
	snd_note $0D, 10
	snd_note $0D, 6
	snd_note $34, 5
	snd_note $37, 2
	snd_note $0D, 5
	snd_note $36, 2
	snd_note $35
	snd_note $0D, 5
	snd_note $34, 2
	snd_note $0D, 5
	snd_env $69
	snd_note $50
	snd_note $47, 9
	snd_tie
	snd_len 2
	snd_note $0D, 6
	snd_env $7D
	snd_note $39, 5
	snd_note $40, 2
	snd_note $0D, 5
	snd_note $3B, 2
	snd_note $3A
	snd_note $0D, 5
	snd_note $39, 2
	snd_tie
	snd_len 5
	snd_note $0D, 10
	snd_note $0D, 6
	snd_note $3B, 5
	snd_note $42, 2
	snd_note $0D, 5
	snd_note $37, 2
	snd_note $3B, 5
	snd_note $42, 2
	snd_note $45, 5
	snd_note $0D, 2
	snd_note $44, 5
	snd_note $0D, 2
	snd_note $43, 5
	snd_note $0D, 2
	snd_note $42, 5
	snd_note $0D, 2
	snd_note $0D, 6
	snd_note $39, 5
	snd_note $40, 2
	snd_note $0D, 5
	snd_note $42, 2
	snd_note $44, 5
	snd_note $40, 2
	snd_note $3B, 5
	snd_note $40, 2
	snd_note $0D, 5
	snd_note $3B, 6
	snd_note $42, 2
	snd_note $44, 5
	snd_note $45, 2
	snd_note $44, 5
	snd_note $40, 2
	snd_note $0D, 5
	snd_note $37, 8
	snd_note $0D, 5
	snd_note $43, 2
	snd_note $44, 5
	snd_note $0D, 2
	snd_note $45, 5
	snd_note $0D, 2
	snd_note $46, 5
	snd_note $0D, 2
	snd_note $47, 5
	snd_note $0D, 2
	snd_note $0D, 5
	snd_note $49, 2
	snd_note $0D, 5
	snd_note $48, 2
	snd_note $49, 5
	snd_note $45, 2
	snd_note $0D, 5
	snd_note $42, 2
	snd_note $47, 5
	snd_note $0D, 2
	snd_note $3B, 5
	snd_note $0D, 2
	snd_note $40, 5
	snd_note $0D, 2
	snd_note $42, 5
	snd_note $0D, 2
	snd_note $44, 5
	snd_note $40, 2
	snd_note $39
	snd_note $0D
	snd_note $43, 6
	snd_note $39, 2
	snd_note $40, 5
	snd_note $43, 2
	snd_note $0D, 5
	snd_note $42, 2
	snd_note $0D, 5
	snd_note $47, 2
	snd_note $0D, 5
	snd_note $46, 2
	snd_note $45, 5
	snd_note $42, 2
	snd_note $0D, 12
	snd_env $73
	snd_note $47, 5
	snd_note $46, 2
	snd_note $45, 5
	snd_note $44, 9
	snd_tie
	snd_len 2
	snd_note $0D, 12
	snd_note $47, 5
	snd_note $46, 2
	snd_note $45, 5
	snd_note $42, 2
	snd_note $0D, 5
	snd_note $3B, 2
	snd_note $0D, 5
	snd_note $37, 2
	snd_jump Trk_7178
	snd_end	; unreachable
SndUnused_7272:
	snd_note $0D, 6
	snd_env $73
	snd_note $30, 5
	snd_note $34, 2
	snd_note $0D, 5
	snd_note $33, 2
	snd_note $32
	snd_note $0D, 5
	snd_note $30, 2
	snd_tie
	snd_len 5
	snd_note $0D, 10
	snd_note $0D, 6
	snd_note $30, 5
	snd_note $34, 2
	snd_note $0D, 5
	snd_note $33, 2
	snd_note $32
	snd_note $0D, 5
	snd_note $30, 2
	snd_note $0D, 5
	snd_env $5F
	snd_note $47
	snd_note $44, 9
	snd_tie
	snd_len 2
	snd_note $0D, 6
	snd_env $73
	snd_note $35, 5
	snd_note $39, 2
	snd_note $0D, 5
	snd_note $38, 2
	snd_note $37
	snd_note $0D, 5
	snd_note $35, 2
	snd_tie
	snd_len 5
	snd_note $0D, 10
	snd_note $0D, 6
	snd_note $37, 5
	snd_note $3B, 2
	snd_note $0D, 5
	snd_note $32, 2
	snd_note $35, 5
	snd_note $37, 2
	snd_note $3B, 5
	snd_note $0D, 2
	snd_note $40, 5
	snd_note $0D, 2
	snd_note $3B, 5
	snd_note $0D, 2
	snd_note $37, 5
	snd_note $0D, 2
	snd_note $0D, 6
	snd_note $35, 5
	snd_note $39, 2
	snd_note $0D, 5
	snd_note $39, 2
	snd_note $40, 5
	snd_note $39, 2
	snd_note $35, 5
	snd_note $37, 2
	snd_note $0D, 5
	snd_note $37, 6
	snd_note $3B, 2
	snd_note $42, 5
	snd_note $3B, 2
	snd_note $40, 5
	snd_note $37, 2
	snd_note $0D, 5
	snd_note $34, 8
	snd_note $0D, 5
	snd_note $3B, 2
	snd_note $40, 5
	snd_note $0D, 2
	snd_note $42, 5
	snd_note $0D, 2
	snd_note $43, 5
	snd_note $0D, 2
	snd_note $44, 5
	snd_note $0D, 2
	snd_note $0D, 5
	snd_note $45, 2
	snd_note $0D, 5
	snd_note $44, 2
	snd_note $45, 5
	snd_note $40, 2
	snd_note $0D, 5
	snd_note $3B, 2
	snd_note $42, 5
	snd_note $0D, 2
	snd_note $37, 5
	snd_note $0D, 2
	snd_note $39, 5
	snd_note $0D, 2
	snd_note $3B, 5
	snd_note $0D, 2
	snd_note $40, 5
	snd_note $39, 2
	snd_note $35
	snd_note $0D
	snd_note $40, 6
	snd_note $36, 2
	snd_note $39, 5
	snd_note $40, 2
	snd_note $0D, 5
	snd_note $3B, 2
	snd_note $0D, 5
	snd_note $42, 2
	snd_note $0D, 5
	snd_note $43, 2
	snd_note $42, 5
	snd_note $3B, 2
	snd_note $0D, 7
	snd_tie
	snd_len 0
	snd_note $34, 6
	snd_note $2B, 2
	snd_note $30, 5
	snd_note $24, 2
	snd_note $44, 5
	snd_note $43, 2
	snd_note $42, 5
	snd_note $40, 9
	snd_tie
	snd_len 2
	snd_note $0D, 7
	snd_tie
	snd_len 0
	snd_note $34, 6
	snd_note $2B, 2
	snd_note $30, 5
	snd_note $24, 2
	snd_note $44, 5
	snd_note $43, 2
	snd_note $42, 5
	snd_note $3B, 2
	snd_note $0D, 5
	snd_note $37, 2
	snd_note $0D, 5
	snd_note $32, 2
	snd_jump SndUnused_7272
	snd_end	; unreachable
SndUnused_737E:
	snd_env $7D
	snd_note $20, 5
	snd_note $27, 2
	snd_note $0D, 12
	snd_note $27, 5
	snd_note $17, 6
	snd_note $19, 2
	snd_note $1B, 6
	snd_note $20, 5
	snd_note $27, 2
	snd_tie
	snd_len 2
	snd_note $0D, 14
	snd_note $20, 2
	snd_note $22, 5
	snd_note $24, 2
	snd_note $25, 5
	snd_note $30, 2
	snd_note $0D, 12
	snd_note $25, 2
	snd_note $0D
	snd_note $20, 6
	snd_note $22, 2
	snd_note $24, 5
	snd_note $25, 2
	snd_note $27, 5
	snd_note $17, 2
	snd_tie
	snd_len 0
	snd_note $0D, 7
	snd_note $1B, 2
	snd_note $22, 5
	snd_note $25, 2
	snd_note $27, 5
	snd_note $0D, 2
	snd_note $17, 5
	snd_note $0D, 2
	snd_note $27, 5
	snd_note $22, 2
	snd_note $27, 5
	snd_note $26, 2
	snd_note $25, 5
	snd_note $30, 2
	snd_note $0D, 5
	snd_note $29, 2
	snd_note $0D, 5
	snd_note $25, 2
	snd_note $0D, 5
	snd_note $26, 2
	snd_note $27, 5
	snd_note $0D, 2
	snd_note $22, 5
	snd_note $0D, 2
	snd_note $1B
	snd_note $0D
	snd_note $26
	snd_note $27, 5
	snd_note $22, 2
	snd_note $20, 5
	snd_note $30, 2
	snd_note $0D, 5
	snd_note $24, 6
	snd_note $25, 2
	snd_note $26, 5
	snd_note $27, 2
	snd_note $20, 5
	snd_note $30, 2
	snd_note $22, 5
	snd_note $32, 2
	snd_note $23, 5
	snd_note $33, 2
	snd_note $24, 5
	snd_note $34, 2
	snd_note $22, 5
	snd_note $32, 2
	snd_note $0D, 5
	snd_note $29, 6
	snd_note $25, 2
	snd_note $22, 5
	snd_note $29, 2
	snd_note $27
	snd_note $0D
	snd_note $17, 6
	snd_note $21, 2
	snd_note $22, 5
	snd_note $0D, 2
	snd_note $27, 5
	snd_note $0D, 2
	snd_note $25, 5
	snd_note $30, 6
	snd_note $25, 2
	snd_note $26, 5
	snd_note $30, 6
	snd_note $26, 2
	snd_note $27, 6
	snd_note $17
	snd_note $27
	snd_note $17
	snd_note $20, 5
	snd_note $27, 2
	snd_note $30, 5
	snd_note $37, 6
	snd_note $33, 2
	snd_note $34, 5
	snd_note $30, 2
	snd_note $0D, 11
	snd_note $17, 2
	snd_note $18
	snd_note $19
	snd_note $1B
	snd_note $20, 5
	snd_note $27, 2
	snd_note $30, 5
	snd_note $37, 6
	snd_note $33, 2
	snd_note $34, 5
	snd_note $30, 2
	snd_note $0D, 12
	snd_jump SndUnused_737E
	snd_end	; unreachable
SndUnused_745E:
	snd_note $0D, 6
	snd_env $70
	snd_note $30, 2
	snd_note $0D, 8
	snd_note $30, 2
	snd_note $0D, 5
	snd_env $60
	snd_note $30, 2
	snd_env $70
	snd_len 2
	snd_tie
	snd_len 5
	snd_note $0D, 10
	snd_note $0D, 6
	snd_note $30, 2
	snd_note $0D, 8
	snd_note $30, 2
	snd_note $0D, 5
	snd_env $60
	snd_note $30, 2
	snd_env $70
	snd_len 2
	snd_tie
	snd_len 5
	snd_note $0D, 10
	snd_note $0D, 6
	snd_note $30, 2
	snd_note $0D, 8
	snd_note $30, 2
	snd_note $0D, 5
	snd_env $60
	snd_note $30, 2
	snd_env $70
	snd_len 2
	snd_tie
	snd_len 5
	snd_note $0D, 10
	snd_note $0D, 6
	snd_note $30, 2
	snd_note $0D, 8
	snd_note $30, 2
	snd_note $0D, 5
	snd_env $60
	snd_note $30, 2
	snd_env $70
	snd_len 2
	snd_note $0D, 5
	snd_note $30, 2
	snd_note $0D, 5
	snd_note $30, 2
	snd_env $60
	snd_len 2
	snd_len 2
	snd_env $70
	snd_len 2
	snd_len 2
	snd_len 2
	snd_note $0D, 6
	snd_note $30, 2
	snd_tie
	snd_len 0
	snd_note $0D, 7
	snd_note $30, 2
	snd_tie
	snd_len 0
	snd_note $0D, 7
	snd_note $30, 2
	snd_tie
	snd_len 0
	snd_note $0D, 7
	snd_note $30, 2
	snd_note $0D
	snd_note $30
	snd_note $0D, 6
	snd_note $30, 2
	snd_tie
	snd_len 0
	snd_note $0D, 7
	snd_note $30, 2
	snd_tie
	snd_len 0
	snd_note $0D, 7
	snd_note $30, 2
	snd_tie
	snd_len 0
	snd_note $0D, 7
	snd_note $30, 2
	snd_note $0D
	snd_note $30
	snd_note $0D, 6
	snd_note $30, 2
	snd_tie
	snd_len 0
	snd_note $0D, 7
	snd_note $30, 2
	snd_tie
	snd_len 0
	snd_note $0D, 7
	snd_note $30, 2
	snd_tie
	snd_len 0
	snd_note $0D, 7
	snd_note $30, 2
	snd_note $0D
	snd_note $30
	snd_note $0D, 6
	snd_note $30, 2
	snd_tie
	snd_len 0
	snd_note $0D, 7
	snd_note $30, 2
	snd_note $0D, 5
	snd_note $30, 2
	snd_note $0D, 8
	snd_note $30, 2
	snd_note $0D, 5
	snd_note $30, 2
	snd_env $60
	snd_len 2
	snd_len 2
	snd_env $70
	snd_len 2
	snd_len 2
	snd_note $0D, 5
	snd_note $30, 2
	snd_tie
	snd_len 0
	snd_note $0D, 7
	snd_note $30, 2
	snd_tie
	snd_len 0
	snd_note $0D, 7
	snd_note $30, 2
	snd_note $0D, 8
	snd_note $30, 2
	snd_len 2
	snd_note $0D, 5
	snd_note $0D, 6
	snd_note $30, 2
	snd_tie
	snd_len 0
	snd_note $0D, 7
	snd_note $30, 2
	snd_tie
	snd_len 0
	snd_note $0D, 7
	snd_note $30, 2
	snd_note $0D, 8
	snd_note $30, 2
	snd_note $0D, 5
	snd_note $30, 2
	snd_jump SndUnused_745E
	snd_end	; unreachable
SndUnused_755A:
	snd_tempo $D0
Trk_755C:
	snd_env $7D
	snd_note $42, 8
	snd_note $4A, 5
	snd_note $0D, 8
	snd_note $45, 11
	snd_note $42, 6
	snd_note $0D
	snd_note $43, 8
	snd_note $45, 5
	snd_note $0D, 8
	snd_note $47, 12
	snd_note $0D, 5
	snd_note $49, 8
	snd_note $48, 5
	snd_note $49, 8
	snd_note $45, 5
	snd_note $50, 8
	snd_note $4B, 5
	snd_note $50, 8
	snd_note $45, 5
	snd_note $0D, 15
	snd_note $0D, 8
	snd_note $4A, 11
	snd_note $45, 5
	snd_note $0D, 8
	snd_note $42, 5
	snd_note $0D, 8
	snd_note $43
	snd_note $45, 5
	snd_note $0D, 8
	snd_note $47, 12
	snd_note $0D, 5
	snd_note $44, 8
	snd_note $47, 5
	snd_note $52, 8
	snd_note $51, 5
	snd_note $0D, 8
	snd_note $50, 5
	snd_note $0D, 8
	snd_note $4A, 5
	snd_note $49, 9
	snd_note $4A
	snd_note $4B
	snd_note $50
	snd_note $0D, 8
	snd_note $43, 5
	snd_note $47, 8
	snd_note $4A, 5
	snd_note $52, 8
	snd_note $50, 5
	snd_note $0D, 8
	snd_note $55, 5
	snd_note $0D, 8
	snd_note $55, 5
	snd_note $0D, 8
	snd_note $52, 5
	snd_note $50
	snd_note $52
	snd_note $51
	snd_note $50, 8
	snd_note $47, 5
	snd_note $49
	snd_note $48
	snd_note $47
	snd_note $45, 12
	snd_note $0D, 9
	snd_note $0D, 14
	snd_note $48, 5
	snd_note $47, 8
	snd_note $45, 5
	snd_note $43, 8
	snd_note $42, 5
	snd_note $43, 8
	snd_note $47, 5
	snd_note $52, 8
	snd_note $4A, 5
	snd_note $0D, 8
	snd_note $55, 5
	snd_tie
	snd_len 8
	snd_note $50, 5
	snd_note $51, 8
	snd_note $52, 5
	snd_note $50, 8
	snd_note $48, 5
	snd_note $47, 8
	snd_note $45, 5
	snd_note $42, 8
	snd_note $45, 5
	snd_note $0D, 8
	snd_note $40, 5
	snd_note $41
	snd_note $42
	snd_note $45
	snd_note $0D, 8
	snd_note $42, 5
	snd_note $40, 8
	snd_note $44, 5
	snd_note $4A, 8
	snd_note $49, 5
	snd_note $0D, 8
	snd_note $45, 5
	snd_note $0D, 8
	snd_note $40, 5
	snd_note $43
	snd_note $44
	snd_note $45
	snd_note $47, 8
	snd_note $4A, 5
	snd_note $52, 8
	snd_note $50, 5
	snd_note $0D, 8
	snd_note $55, 5
	snd_note $0D, 8
	snd_note $55, 5
	snd_note $0D, 8
	snd_note $52, 5
	snd_note $50
	snd_note $51
	snd_note $52
	snd_note $55, 8
	snd_note $47, 5
	snd_note $49
	snd_note $48
	snd_note $47
	snd_note $45, 13
	snd_note $0D, 14
	snd_note $42, 5
	snd_note $43, 8
	snd_note $45, 5
	snd_note $47, 8
	snd_note $43, 5
	snd_note $47, 8
	snd_note $52
	snd_note $51, 5
	snd_note $50
	snd_note $49, 8
	snd_note $50, 5
	snd_note $45, 6
	snd_note $0D, 2
	snd_note $45, 5
	snd_note $0D, 8
	snd_note $42, 9
	snd_note $49, 5
	snd_note $0D, 8
	snd_note $47, 5
	snd_note $0D, 8
	snd_note $4A, 9
	snd_note $0D, 5
	snd_note $4A
	snd_note $0D, 8
	snd_note $4A, 5
	snd_note $0D, 8
	snd_note $4A, 5
	snd_note $0D, 8
	snd_note $4A
	snd_note $49, 5
	snd_note $0D, 8
	snd_note $45, 5
	snd_note $47, 8
	snd_note $49, 5
	snd_jump Trk_755C
	snd_end	; unreachable
SndUnused_7685:
	snd_env $73
	snd_note $3A, 8
	snd_note $42, 5
	snd_note $0D, 8
	snd_note $3A, 11
	snd_note $35, 6
	snd_note $0D
	snd_note $37, 8
	snd_note $39, 5
	snd_note $0D, 8
	snd_note $3A, 12
	snd_note $0D, 5
	snd_note $40, 8
	snd_note $3B, 5
	snd_note $40, 8
	snd_note $39, 5
	snd_note $45, 8
	snd_note $44, 5
	snd_note $45, 8
	snd_note $40, 5
	snd_note $0D, 8
	snd_env $7D
	snd_note $30, 11
	snd_note $32, 5
	snd_note $0D, 8
	snd_note $33, 5
	snd_note $0D, 8
	snd_env $73
	snd_note $32
	snd_note $42, 11
	snd_note $3A, 5
	snd_note $0D, 8
	snd_note $35, 5
	snd_note $0D, 8
	snd_note $37
	snd_note $39, 5
	snd_note $0D, 8
	snd_note $3A, 12
	snd_note $0D, 5
	snd_note $37, 8
	snd_note $3A, 5
	snd_note $46, 8
	snd_note $45, 5
	snd_note $0D, 8
	snd_note $44, 5
	snd_note $37
	snd_note $3A
	snd_note $44
	snd_note $40, 9
	snd_note $42
	snd_note $44
	snd_note $45
	snd_note $43, 5
	snd_note $3A
	snd_note $37
	snd_note $33
	snd_note $0D
	snd_note $3A, 9
	snd_note $37, 5
	snd_note $36
	snd_note $37
	snd_note $39
	snd_note $40
	snd_note $39
	snd_note $35
	snd_note $30
	snd_note $0D
	snd_note $35
	snd_note $39, 8
	snd_note $35, 5
	snd_note $39, 8
	snd_note $40, 5
	snd_note $42
	snd_note $40
	snd_note $3B
	snd_note $3A, 8
	snd_note $35, 9
	snd_env $7D
	snd_note $32, 5
	snd_note $33, 8
	snd_note $34, 5
	snd_note $35, 6
	snd_note $0D, 2
	snd_note $35, 5
	snd_note $0D, 8
	snd_env $73
	snd_note $37, 9
	snd_note $38, 5
	snd_note $37, 8
	snd_note $35, 5
	snd_note $40
	snd_note $37
	snd_note $33
	snd_note $30
	snd_note $0D
	snd_note $37
	snd_note $3A, 8
	snd_note $37, 5
	snd_note $30
	snd_note $33
	snd_note $39
	snd_tie
	snd_note $39, 6
	snd_note $0D, 2
	snd_note $39, 5
	snd_note $0D, 8
	snd_note $38, 5
	snd_note $39, 8
	snd_note $35, 5
	snd_note $33, 8
	snd_note $30, 5
	snd_note $35, 8
	snd_note $39, 5
	snd_note $40
	snd_note $42
	snd_note $39
	snd_note $38
	snd_note $39
	snd_note $40
	snd_note $39
	snd_note $32
	snd_note $39
	snd_note $34, 8
	snd_note $37, 5
	snd_note $42, 8
	snd_note $40, 5
	snd_note $0D, 8
	snd_note $39, 5
	snd_env $69
	snd_note $38, 2
	snd_note $37
	snd_note $36
	snd_note $35
	snd_env $73
	snd_note $35, 5
	snd_note $37
	snd_note $38
	snd_note $39
	snd_note $3A
	snd_note $0D
	snd_note $3A, 9
	snd_note $37, 5
	snd_note $0D, 8
	snd_note $39, 5
	snd_note $40
	snd_note $39
	snd_note $35
	snd_note $30
	snd_note $0D
	snd_note $35
	snd_note $39, 8
	snd_note $35, 5
	snd_note $39, 8
	snd_note $40, 5
	snd_note $42
	snd_note $40
	snd_note $3B
	snd_note $3A, 8
	snd_note $35, 9
	snd_env $7D
	snd_note $32, 5
	snd_note $33, 8
	snd_note $34, 5
	snd_note $35, 6
	snd_note $0D, 2
	snd_note $35, 5
	snd_env $73
	snd_note $32
	snd_note $35
	snd_note $37, 9
	snd_note $38, 5
	snd_note $37, 8
	snd_note $35, 5
	snd_note $3A, 6
	snd_note $0D, 2
	snd_note $3A, 5
	snd_note $33
	snd_note $37
	snd_note $40
	snd_note $46
	snd_note $39
	snd_note $43
	snd_note $40
	snd_note $33
	snd_note $36
	snd_note $39, 6
	snd_note $0D, 2
	snd_note $39, 5
	snd_note $0D, 8
	snd_note $35, 9
	snd_note $42, 5
	snd_note $0D, 8
	snd_note $3B, 5
	snd_note $43
	snd_note $40
	snd_note $3A
	snd_note $37
	snd_note $3A
	snd_note $40
	snd_note $44
	snd_note $40
	snd_note $3A
	snd_note $37
	snd_note $40
	snd_note $44
	snd_note $45
	snd_note $35
	snd_note $40
	snd_note $47, 8
	snd_note $45, 5
	snd_note $55, 2
	snd_note $45
	snd_note $55
	snd_note $45
	snd_note $39, 5
	snd_note $3A, 8
	snd_note $40, 5
	snd_jump SndUnused_7685
	snd_end	; unreachable
SndUnused_77E1:
	snd_env $7D
	snd_note $1A, 9
	snd_note $25
	snd_note $2A, 8
	snd_note $25, 9
	snd_note $22, 5
	snd_note $23, 9
	snd_note $1A
	snd_note $23
	snd_note $24
	snd_note $25
	snd_note $20
	snd_note $25
	snd_note $29
	snd_note $30, 5
	snd_note $0D
	snd_note $25, 11
	snd_note $27, 5
	snd_note $0D, 8
	snd_note $29, 5
	snd_note $0D, 8
	snd_note $2A
	snd_note $22, 9
	snd_note $23, 5
	snd_note $25, 9
	snd_note $24
	snd_note $23
	snd_note $1A
	snd_note $23, 8
	snd_note $22, 9
	snd_env $69
	snd_note $21, 5
	snd_env $7D
	snd_note $20, 9
	snd_note $24
	snd_note $27
	snd_note $2A
	snd_note $25
	snd_note $27
	snd_note $28
	snd_note $29, 5
	snd_env $73
	snd_note $25
	snd_env $69
	snd_note $24
	snd_env $7D
	snd_note $23, 9
	snd_note $1A
	snd_note $23
	snd_note $27
	snd_note $23
	snd_note $25
	snd_note $23
	snd_note $20, 8
	snd_note $1B, 5
	snd_note $1A, 9
	snd_note $22
	snd_note $23
	snd_note $24
	snd_note $25, 8
	snd_note $1A, 5
	snd_note $28, 9
	snd_note $27
	snd_note $25
	snd_note $20
	snd_note $23
	snd_note $2A
	snd_note $27
	snd_note $25
	snd_note $20
	snd_note $25
	snd_note $23
	snd_note $22
	snd_note $29
	snd_note $25
	snd_note $22, 8
	snd_env $69
	snd_note $21, 5
	snd_env $7D
	snd_note $20, 8
	snd_note $24, 5
	snd_note $2A, 8
	snd_note $29, 5
	snd_note $0D, 8
	snd_note $25, 5
	snd_note $0D, 8
	snd_note $20, 5
	snd_note $23, 9
	snd_note $1A
	snd_note $23
	snd_note $27
	snd_note $23
	snd_note $25
	snd_note $23
	snd_note $20, 8
	snd_env $69
	snd_note $1B, 5
	snd_env $7D
	snd_note $1A, 9
	snd_note $22
	snd_note $23
	snd_note $24
	snd_note $25, 8
	snd_note $1A, 5
	snd_note $28, 9
	snd_note $25
	snd_note $22, 8
	snd_env $69
	snd_note $21, 5
	snd_env $7D
	snd_note $20, 9
	snd_note $27
	snd_note $30
	snd_note $23
	snd_note $22
	snd_note $29
	snd_note $27
	snd_note $22
	snd_note $20
	snd_note $27
	snd_note $30
	snd_note $2A, 8
	snd_env $69
	snd_note $2B, 5
	snd_env $7D
	snd_note $30
	snd_note $0D, 8
	snd_note $30
	snd_note $25, 5
	snd_note $0D, 8
	snd_note $25, 5
	snd_note $24, 8
	snd_note $23, 5
	snd_jump SndUnused_77E1
	snd_end	; unreachable
SndUnused_78AE:
	snd_note $0D, 9
	snd_env $70
	snd_note $30, 5
	snd_note $0D, 11
	snd_note $30, 5
	snd_note $0D, 8
	snd_note $30, 5
	snd_note $0D, 10
	snd_tie
	snd_len 2
	snd_note $30, 5
	snd_note $0D, 9
	snd_note $30, 5
	snd_note $0D
	snd_note $30
	snd_note $0D, 9
	snd_note $30, 5
	snd_tie
	snd_len 2
	snd_note $0D, 10
	snd_note $30, 5
	snd_note $0D
	snd_note $30
	snd_note $30
	snd_tie
	snd_len 2
	snd_note $0D, 10
	snd_note $30, 5
	snd_len 5
	snd_len 5
	snd_len 5
	snd_len 5
	snd_len 5
	snd_note $0D, 9
	snd_note $30, 5
	snd_note $0D, 11
	snd_note $30, 5
	snd_note $0D, 8
	snd_note $30, 5
	snd_note $0D, 10
	snd_tie
	snd_len 2
	snd_note $30, 5
	snd_note $0D, 8
	snd_note $30, 5
	snd_len 5
	snd_note $0D, 8
	snd_note $0D, 9
	snd_note $30, 5
	snd_tie
	snd_len 2
	snd_note $0D, 10
	snd_note $30, 5
	snd_note $0D, 8
	snd_note $30, 5
	snd_note $0D, 8
	snd_note $30, 5
	snd_note $0D, 8
	snd_note $30, 5
	snd_len 5
	snd_len 5
	snd_len 5
	snd_len 5
	snd_len 5
	snd_note $0D, 9
	snd_note $30, 5
	snd_tie
	snd_len 2
	snd_note $0D, 10
	snd_note $30, 5
	snd_note $0D, 8
	snd_note $0D, 9
	snd_note $30, 5
	snd_note $0D
	snd_note $30
	snd_note $0D, 9
	snd_note $30, 5
	snd_note $0D, 8
	snd_note $0D, 9
	snd_note $30, 5
	snd_tie
	snd_len 2
	snd_note $0D, 10
	snd_note $30, 5
	snd_note $0D
	snd_note $30
	snd_note $0D, 9
	snd_note $30, 5
	snd_note $0D
	snd_note $30
	snd_note $0D, 9
	snd_note $30, 5
	snd_note $0D, 8
	snd_note $0D, 9
	snd_note $30, 5
	snd_tie
	snd_len 2
	snd_note $0D, 10
	snd_note $30, 5
	snd_note $0D, 8
	snd_note $0D, 9
	snd_note $30, 5
	snd_tie
	snd_len 2
	snd_note $0D, 10
	snd_note $30, 5
	snd_note $0D, 8
	snd_note $0D, 9
	snd_note $30, 5
	snd_tie
	snd_len 2
	snd_note $0D, 10
	snd_note $30, 5
	snd_note $0D, 8
	snd_note $30, 5
	snd_note $0D
	snd_note $30
	snd_note $30
	snd_note $0D
	snd_note $30
	snd_note $0D, 8
	snd_note $30, 5
	snd_len 5
	snd_len 5
	snd_len 5
	snd_note $0D, 9
	snd_note $30, 5
	snd_note $0D
	snd_note $30
	snd_note $0D, 9
	snd_note $30, 5
	snd_note $0D, 8
	snd_note $0D, 9
	snd_note $30, 5
	snd_tie
	snd_len 2
	snd_note $0D, 10
	snd_note $30, 5
	snd_note $0D
	snd_note $30
	snd_note $0D, 9
	snd_note $30, 5
	snd_tie
	snd_len 2
	snd_note $0D, 10
	snd_note $30, 5
	snd_note $0D, 8
	snd_note $0D, 9
	snd_note $30, 5
	snd_note $0D
	snd_note $30
	snd_note $0D, 9
	snd_note $30, 5
	snd_note $0D, 8
	snd_note $0D, 9
	snd_note $30, 5
	snd_tie
	snd_len 2
	snd_note $0D, 10
	snd_note $30, 5
	snd_note $0D, 8
	snd_note $0D, 9
	snd_note $30, 5
	snd_tie
	snd_len 2
	snd_note $0D, 10
	snd_note $30, 5
	snd_note $0D, 8
	snd_note $30, 5
	snd_note $0D
	snd_note $30
	snd_note $0D, 9
	snd_note $30, 5
	snd_note $0D, 8
	snd_note $30, 5
	snd_note $0D, 8
	snd_note $30, 5
	snd_len 5
	snd_len 5
	snd_len 5
	snd_tie
	snd_len 2
	snd_note $0D, 10
	snd_note $30, 5
	snd_len 5
	snd_len 5
	snd_jump SndUnused_78AE
	snd_end	; unreachable
