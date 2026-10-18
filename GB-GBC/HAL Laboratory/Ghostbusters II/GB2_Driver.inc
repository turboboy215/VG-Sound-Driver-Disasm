; bank 7: driver code and tables ($4000-$48C0)


; Sound_StartQueued: pop the oldest queued id (id 0 = nothing) and start every channel in its
; header: [channel, pointer]... terminated by a byte with bit 7 set. Starting a channel
; resets its transpose and attenuation, sets NR10 = $08 and a wait of 1.
Sound_StartQueued:
	ldh a, [hSoundQueueCount]   ; 4000
	and a                       ; 4002
	ret z                       ; 4003
	ldh a, [rIE]                ; 4004
	push af                     ; 4006
	xor a                       ; 4007
	ldh [rIE], a                ; 4008
	ld hl, hSoundQueueCount     ; 400A
	dec [hl]                    ; 400D
	ld hl, hSoundQueueCount     ; 400E
	ld e, [hl]                  ; 4011
	ld d, $00                   ; 4012
	ld hl, hSoundQueue          ; 4014
	add hl, de                  ; 4017
	ld e, $00                   ; 4018
.l_401A:
	ld d, [hl]                  ; 401A
	ld [hl], e                  ; 401B
	ld e, d                     ; 401C
	dec hl                      ; 401D
	ld a, l                     ; 401E
	cp LOW(hSoundQueueCount)    ; 401F
	jr nz, .l_401A              ; 4021
	pop af                      ; 4023
	ldh [rIE], a                ; 4024
	ld a, e                     ; 4026
	add a, a                    ; 4027
	ret z                       ; 4028
	ld c, a                     ; 4029
	ld b, $00                   ; 402A
	ld hl, SoundTable           ; 402C
	add hl, bc                  ; 402F
	ld a, [hl]                  ; 4030
	ldh [hChMask], a            ; 4031
	ld hl, SoundTable + 1       ; 4033
	add hl, bc                  ; 4036
	ld a, [hl]                  ; 4037
	ldh [hCurCh], a             ; 4038
	ld de, $0000                ; 403A
.l_403D:
	ld hl, hChMask              ; 403D
	ld a, [hli]                 ; 4040
	ld h, [hl]                  ; 4041
	ld l, a                     ; 4042
	add hl, de                  ; 4043
	ld a, [hl]                  ; 4044
	bit 7, a                    ; 4045
	ret nz                      ; 4047
	ldh [hCurCh2], a            ; 4048
	ld c, a                     ; 404A
	ld b, $00                   ; 404B
	add a, a                    ; 404D
	ldh [hCurRegOffset], a      ; 404E
	ld hl, ChannelBits          ; 4050
	add hl, bc                  ; 4053
	ld a, [hl]                  ; 4054
	ld hl, hActiveChannels      ; 4055
	or [hl]                     ; 4058
	ldh [hActiveChannels], a    ; 4059
	xor a                       ; 405B
	ld hl, wChTranspose         ; 405C
	add hl, bc                  ; 405F
	ld [hl], a                  ; 4060
	ld hl, wChAttenuation       ; 4061
	add hl, bc                  ; 4064
	ld [hl], a                  ; 4065
	ld a, $08                   ; 4066
	ld hl, wChSweep             ; 4068
	add hl, bc                  ; 406B
	ld [hl], a                  ; 406C
	ld a, $01                   ; 406D
	ld hl, wChWait              ; 406F
	add hl, bc                  ; 4072
	ld [hl], a                  ; 4073
	ld hl, hCurRegOffset        ; 4074
	ld c, [hl]                  ; 4077
	ld b, $00                   ; 4078
	ld hl, hChMask              ; 407A
	inc [hl]                    ; 407D
	jr nz, .l_4082              ; 407E
	inc hl                      ; 4080
	inc [hl]                    ; 4081
.l_4082:
	ld hl, hChMask              ; 4082
	ld a, [hli]                 ; 4085
	ld h, [hl]                  ; 4086
	ld l, a                     ; 4087
	add hl, de                  ; 4088
	ld a, [hl]                  ; 4089
	ldh [hCurCh2], a            ; 408A
	ld hl, hChMask              ; 408C
	inc [hl]                    ; 408F
	jr nz, .l_4094              ; 4090
	inc hl                      ; 4092
	inc [hl]                    ; 4093
.l_4094:
	push de                     ; 4094
	push af                     ; 4095
	ld hl, hChMask              ; 4096
	ld a, [hli]                 ; 4099
	ld h, [hl]                  ; 409A
	ld l, a                     ; 409B
	pop af                      ; 409C
	add hl, de                  ; 409D
	ld d, [hl]                  ; 409E
	ld hl, hCurCh2              ; 409F
	ld e, [hl]                  ; 40A2
	dec de                      ; 40A3
	ld hl, wChPtr               ; 40A4
	add hl, bc                  ; 40A7
	ld [hl], e                  ; 40A8
	ld hl, wChPtr + 1           ; 40A9
	add hl, bc                  ; 40AC
	ld [hl], d                  ; 40AD
	pop de                      ; 40AE
	ld hl, hChMask              ; 40AF
	inc [hl]                    ; 40B2
	jr nz, .l_40B7              ; 40B3
	inc hl                      ; 40B5
	inc [hl]                    ; 40B6
.l_40B7:
	jr .l_403D                  ; 40B7


; Sound_Update (bank 7, called by the game 0, 1 or 2 times per frame): for channels 0-7 with
; their hActiveChannels bit set: count the note wait down (0 -> read the stream), else count
; the envelope step down. Channels 0-3 are music, 4-7 SFX on the same hardware channels
; (channel & 3). hChMask bit 3 is set while the SFX twin of a music channel is active: the
; music channel keeps running but does not write the hardware. Ends in Sound_StartQueued.
Sound_Update:
	ldh a, [hActiveChannels]    ; 40B9
	and a                       ; 40BB
	jp z, Sound_StartQueued     ; 40BC
	ld de, rIE                  ; 40BF
	ld hl, hCurCh               ; 40C2
	ld [hl], e                  ; 40C5
Sound_NextChannel:
	ld hl, hCurCh               ; 40C6
	inc [hl]                    ; 40C9
	srl a                       ; 40CA
	ldh [hChMask], a            ; 40CC
	jr nc, .l_40E5              ; 40CE
	ld hl, hCurCh               ; 40D0
	ld c, [hl]                  ; 40D3
	ld b, $00                   ; 40D4
	ld hl, wChWait              ; 40D6
	add hl, bc                  ; 40D9
	dec [hl]                    ; 40DA
	jp z, Ch_ReadStream         ; 40DB
	ld hl, wChEnvWait           ; 40DE
	add hl, bc                  ; 40E1
	dec [hl]                    ; 40E2
	jr z, Ch_EnvelopeStep       ; 40E3
.l_40E5:
	jr nz, Sound_NextChannel    ; 40E5
	jp Sound_StartQueued        ; 40E7

Ch_EnvelopeStep:
	ld hl, RegOffsetTable       ; 40EA
	add hl, bc                  ; 40ED
	ld a, [hl]                  ; 40EE
	ldh [hCurRegOffset], a      ; 40EF
	ld a, c                     ; 40F1
	add a, a                    ; 40F2
	ld c, a                     ; 40F3
	ld b, $00                   ; 40F4
	ldh [hCurCh2], a            ; 40F6
	ld hl, wChEnvPtr            ; 40F8
	add hl, bc                  ; 40FB
	ld a, [hl]                  ; 40FC
	ldh [hTemp], a              ; 40FD
	ld hl, wChEnvPtr + 1        ; 40FF
	add hl, bc                  ; 4102
	ld a, [hl]                  ; 4103
	ldh [$FFC6], a              ; 4104
	ld hl, hCurCh               ; 4106
	ld c, [hl]                  ; 4109
	ld b, $00                   ; 410A
	ld hl, wChEnvIndex          ; 410C
	add hl, bc                  ; 410F
	ld e, [hl]                  ; 4110
	ld d, $00                   ; 4111
	inc e                       ; 4113
	call Ch_ApplyEnvelope       ; 4114
	ldh a, [hChMask]            ; 4117
	jr Sound_NextChannel        ; 4119


; envelope step de: wChEnvWait = env[de], volume = env[de+1]; NRx2 = (volume - attenuation) << 4
; | 8 and NRx4 = wChNRx4 (retrigger). CH3 uses NR32 = $40 and clears the trigger bit.
Ch_ApplyEnvelope:
	ld hl, hCurCh               ; 411B
	ld c, [hl]                  ; 411E
	ld b, $00                   ; 411F
	ld hl, hTemp                ; 4121
	ld a, [hli]                 ; 4124
	ld h, [hl]                  ; 4125
	ld l, a                     ; 4126
	add hl, de                  ; 4127
	ld a, [hl]                  ; 4128
	ld hl, wChEnvWait           ; 4129
	add hl, bc                  ; 412C
	ld [hl], a                  ; 412D
	inc e                       ; 412E
	ld a, e                     ; 412F
	ld hl, wChEnvIndex          ; 4130
	add hl, bc                  ; 4133
	ld [hl], a                  ; 4134
	ld hl, hTemp                ; 4135
	ld a, [hli]                 ; 4138
	ld h, [hl]                  ; 4139
	ld l, a                     ; 413A
	add hl, de                  ; 413B
	ld a, [hl]                  ; 413C
	ld e, a                     ; 413D
	ldh a, [hChMask]            ; 413E
	and $08                     ; 4140
	jr nz, .l_418E              ; 4142
	ldh a, [hCurCh]             ; 4144
	and $03                     ; 4146
	cp $02                      ; 4148
	jr nz, .l_415C              ; 414A
	ld hl, hCurCh               ; 414C
	ld c, [hl]                  ; 414F
	ld b, $00                   ; 4150
	ld hl, wChNRx4              ; 4152
	add hl, bc                  ; 4155
	res 7, [hl]                 ; 4156
	ld a, $40                   ; 4158
	jr .l_4171                  ; 415A

.l_415C:
	ld a, e                     ; 415C
	ld hl, hCurCh               ; 415D
	ld c, [hl]                  ; 4160
	ld b, $00                   ; 4161
	ld hl, wChAttenuation       ; 4163
	add hl, bc                  ; 4166
	sub [hl]                    ; 4167
	jr nc, .l_416B              ; 4168
	xor a                       ; 416A
.l_416B:
	swap a                      ; 416B
	and $F0                     ; 416D
	or $08                      ; 416F
.l_4171:
	ld hl, hCurRegOffset        ; 4171
	ld c, [hl]                  ; 4174
	ld b, $00                   ; 4175
	ld hl, rNR12                ; 4177
	add hl, bc                  ; 417A
	ld [hl], a                  ; 417B
	push bc                     ; 417C
	ld hl, hCurCh               ; 417D
	ld c, [hl]                  ; 4180
	ld b, $00                   ; 4181
	ld hl, wChNRx4              ; 4183
	add hl, bc                  ; 4186
	ld a, [hl]                  ; 4187
	pop bc                      ; 4188
	ld hl, rNR14                ; 4189
	add hl, bc                  ; 418C
	ld [hl], a                  ; 418D
.l_418E:
	ret                         ; 418E

Ch_ReadStream:
	ld hl, RegOffsetTable       ; 418F
	add hl, bc                  ; 4192
	ld a, [hl]                  ; 4193
	ldh [hCurRegOffset], a      ; 4194
	ld a, c                     ; 4196
	add a, a                    ; 4197
	ld c, a                     ; 4198
	ld b, $00                   ; 4199
	ldh [hCurCh2], a            ; 419B
	ld hl, wChPtr               ; 419D
	add hl, bc                  ; 41A0
	ld a, [hl]                  ; 41A1
	ldh [hStreamPtr], a         ; 41A2
	ld hl, wChPtr + 1           ; 41A4
	add hl, bc                  ; 41A7
	ld a, [hl]                  ; 41A8
	ldh [$FFC4], a              ; 41A9
Ch_NextByte:
	ld hl, hStreamPtr           ; 41AB
	inc [hl]                    ; 41AE
	jr nz, Ch_ReadByte          ; 41AF
	inc hl                      ; 41B1
	inc [hl]                    ; 41B2
Ch_ReadByte:
	ld de, $0000                ; 41B3
	ld hl, hStreamPtr           ; 41B6
	ld a, [hli]                 ; 41B9
	ld h, [hl]                  ; 41BA
	ld l, a                     ; 41BB
	add hl, de                  ; 41BC
	ld a, [hl]                  ; 41BD
	bit 7, a                    ; 41BE
	jr z, Ch_Note               ; 41C0
	and $40                     ; 41C2
	jr z, Ch_SetLength          ; 41C4
	ld hl, hStreamPtr           ; 41C6
	ld a, [hli]                 ; 41C9
	ld h, [hl]                  ; 41CA
	ld l, a                     ; 41CB
	add hl, de                  ; 41CC
	ld a, [hl]                  ; 41CD
	and $0F                     ; 41CE
	add a, a                    ; 41D0
	ld c, a                     ; 41D1
	ld b, $00                   ; 41D2
	ld hl, CommandTable         ; 41D4
	add hl, bc                  ; 41D7
	ld a, [hl]                  ; 41D8
	push af                     ; 41D9
	ld hl, CommandTable + 1     ; 41DA
	add hl, bc                  ; 41DD
	ld a, [hl]                  ; 41DE
	ld h, a                     ; 41DF
	pop af                      ; 41E0
	ld l, a                     ; 41E1
	jp hl                       ; 41E2


; $80-$BF: note length = LengthTable[n & $3F]; music channels add 16 to n < 32 while
; wFastMusic is set.
Ch_SetLength:
	ld hl, hStreamPtr           ; 41E3
	ld a, [hli]                 ; 41E6
	ld h, [hl]                  ; 41E7
	ld l, a                     ; 41E8
	add hl, de                  ; 41E9
	ld a, [hl]                  ; 41EA
	ld hl, hCurCh               ; 41EB
	ld c, [hl]                  ; 41EE
	ld b, $00                   ; 41EF
	and $3F                     ; 41F1
	ld e, a                     ; 41F3
	ld d, $00                   ; 41F4
	ld a, c                     ; 41F6
	cp $04                      ; 41F7
	jr nc, .l_4209              ; 41F9
	ld a, [wFastMusic]          ; 41FB
	and a                       ; 41FE
	jr z, .l_4209               ; 41FF
	ld a, e                     ; 4201
	cp $20                      ; 4202
	jr nc, .l_4209              ; 4204
	add a, $10                  ; 4206
	ld e, a                     ; 4208
.l_4209:
	ld hl, LengthTable          ; 4209
	add hl, de                  ; 420C
	ld a, [hl]                  ; 420D
	ld hl, wChLength            ; 420E
	add hl, bc                  ; 4211
	ld [hl], a                  ; 4212
	jr Ch_NextByte              ; 4213


; $00-$7B note (high nibble = octave via OctaveTable, low nibble = semitone, + transpose),
; $7C rest. CH4: the byte indexes NoiseTable directly. Music channels remember the period in
; wChPeriod for Ch_RestoreMusic.
Ch_Note:
	ldh [hTemp], a              ; 4215
	ld hl, hCurCh               ; 4217
	ld c, [hl]                  ; 421A
	ld b, $00                   ; 421B
	ld hl, wChLastNote          ; 421D
	add hl, bc                  ; 4220
	ld [hl], a                  ; 4221
	cp $7C                      ; 4222
	jp z, Ch_Rest               ; 4224
	and $0F                     ; 4227
	ldh [$FFC6], a              ; 4229
	ldh a, [hCurCh]             ; 422B
	and $03                     ; 422D
	xor $03                     ; 422F
	jr nz, Ch_ToneNote          ; 4231
	ldh a, [hTemp]              ; 4233
	ld hl, hCurCh               ; 4235
	ld c, [hl]                  ; 4238
	ld b, $00                   ; 4239
	ld b, a                     ; 423B
	ld a, c                     ; 423C
	cp $07                      ; 423D
	ld a, b                     ; 423F
	jr z, .l_4259               ; 4240
	ld hl, hCurCh2              ; 4242
	ld c, [hl]                  ; 4245
	ld b, $00                   ; 4246
	ld hl, wChPeriod            ; 4248
	add hl, bc                  ; 424B
	ld [hl], a                  ; 424C
	ldh a, [hChMask]            ; 424D
	and $08                     ; 424F
	jp nz, Ch_ToneNote.l_42EC   ; 4251
	ld hl, wChPeriod            ; 4254
	add hl, bc                  ; 4257
	ld a, [hl]                  ; 4258
.l_4259:
	ld c, a                     ; 4259
	ld b, $00                   ; 425A
	ld hl, NoiseTable           ; 425C
	add hl, bc                  ; 425F
	ld a, [hl]                  ; 4260
	ld hl, hCurRegOffset        ; 4261
	ld c, [hl]                  ; 4264
	ld b, $00                   ; 4265
	jr Ch_ToneNote.l_42D5       ; 4267

Ch_ToneNote:
	ldh a, [hTemp]              ; 4269
	srl a                       ; 426B
	srl a                       ; 426D
	srl a                       ; 426F
	srl a                       ; 4271
	ld e, a                     ; 4273
	ld d, $00                   ; 4274
	ld hl, OctaveTable          ; 4276
	add hl, de                  ; 4279
	ld a, [hl]                  ; 427A
	ld hl, $FFC6                ; 427B
	add a, [hl]                 ; 427E
	ld hl, hCurCh               ; 427F
	ld c, [hl]                  ; 4282
	ld b, $00                   ; 4283
	ld hl, wChTranspose         ; 4285
	add hl, bc                  ; 4288
	add a, [hl]                 ; 4289
	add a, a                    ; 428A
	ld e, a                     ; 428B
	ld d, $00                   ; 428C
	ld a, c                     ; 428E
	cp $04                      ; 428F
	jr nc, .l_42B3              ; 4291
	ld hl, PeriodTable          ; 4293
	add hl, de                  ; 4296
	ld a, [hl]                  ; 4297
	ld hl, hCurCh2              ; 4298
	ld c, [hl]                  ; 429B
	ld b, $00                   ; 429C
	ld hl, wChPeriod            ; 429E
	add hl, bc                  ; 42A1
	ld [hl], a                  ; 42A2
	ld hl, PeriodTable + 1      ; 42A3
	add hl, de                  ; 42A6
	ld a, [hl]                  ; 42A7
	ld hl, wChPeriod + 1        ; 42A8
	add hl, bc                  ; 42AB
	ld [hl], a                  ; 42AC
	ldh a, [hChMask]            ; 42AD
	and $08                     ; 42AF
	jr nz, Ch_NoteDone          ; 42B1
.l_42B3:
	push de                     ; 42B3
	ld hl, hCurCh               ; 42B4
	ld e, [hl]                  ; 42B7
	ld d, $00                   ; 42B8
	ld a, e                     ; 42BA
	and $03                     ; 42BB
	ld hl, hCurRegOffset        ; 42BD
	ld c, [hl]                  ; 42C0
	ld b, $00                   ; 42C1
	jr nz, .l_42CF              ; 42C3
	ld hl, wChSweep             ; 42C5
	add hl, de                  ; 42C8
	ld a, [hl]                  ; 42C9
	ld hl, rNR10                ; 42CA
	add hl, bc                  ; 42CD
	ld [hl], a                  ; 42CE
.l_42CF:
	pop de                      ; 42CF
	ld hl, PeriodTable          ; 42D0
	add hl, de                  ; 42D3
	ld a, [hl]                  ; 42D4
.l_42D5:
	ld hl, rNR13                ; 42D5
	add hl, bc                  ; 42D8
	ld [hl], a                  ; 42D9
	ld hl, PeriodTable + 1      ; 42DA
	add hl, de                  ; 42DD
	ld a, [hl]                  ; 42DE
	ld hl, hCurCh               ; 42DF
	ld c, [hl]                  ; 42E2
	ld b, $00                   ; 42E3
	set 7, a                    ; 42E5
	ld hl, wChNRx4              ; 42E7
	add hl, bc                  ; 42EA
	ld [hl], a                  ; 42EB
.l_42EC:
	ld hl, hCurCh2              ; 42EC
	ld c, [hl]                  ; 42EF
	ld b, $00                   ; 42F0
	ld hl, wChEnvPtr            ; 42F2
	add hl, bc                  ; 42F5
	ld a, [hl]                  ; 42F6
	ldh [hTemp], a              ; 42F7
	ld hl, wChEnvPtr + 1        ; 42F9
	add hl, bc                  ; 42FC
	ld a, [hl]                  ; 42FD
	ldh [$FFC6], a              ; 42FE
	ld de, $0000                ; 4300
	call Ch_ApplyEnvelope       ; 4303
Ch_NoteDone:
	ld hl, hCurCh               ; 4306
	ld c, [hl]                  ; 4309
	ld b, $00                   ; 430A
	ld hl, wChLength            ; 430C
	add hl, bc                  ; 430F
	ld a, [hl]                  ; 4310
	ld hl, wChWait              ; 4311
	add hl, bc                  ; 4314
	ld [hl], a                  ; 4315
	ld hl, hCurCh2              ; 4316
	ld c, [hl]                  ; 4319
	ld b, $00                   ; 431A
	ldh a, [hStreamPtr]         ; 431C
	ld hl, wChPtr               ; 431E
	add hl, bc                  ; 4321
	ld [hl], a                  ; 4322
	ldh a, [$FFC4]              ; 4323
	ld hl, wChPtr + 1           ; 4325
	add hl, bc                  ; 4328
	ld [hl], a                  ; 4329
	ldh a, [hChMask]            ; 432A
	jp Sound_NextChannel        ; 432C

Ch_Rest:
	ld hl, hCurCh               ; 432F
	ld c, [hl]                  ; 4332
	ld b, $00                   ; 4333
	ld a, $FF                   ; 4335
	ld hl, wChEnvWait           ; 4337
	add hl, bc                  ; 433A
	ld [hl], a                  ; 433B
	ld a, c                     ; 433C
	cp $04                      ; 433D
	jr nc, .l_4359              ; 433F
	ld hl, hCurCh2              ; 4341
	ld c, [hl]                  ; 4344
	ld b, $00                   ; 4345
	xor a                       ; 4347
	ld hl, wChPeriod            ; 4348
	add hl, bc                  ; 434B
	ld [hl], a                  ; 434C
	ldh a, [hChMask]            ; 434D
	and $08                     ; 434F
	jr nz, Ch_NoteDone          ; 4351
	ld hl, hCurCh               ; 4353
	ld c, [hl]                  ; 4356
	ld b, $00                   ; 4357
.l_4359:
	ld a, $08                   ; 4359
	ld hl, hCurRegOffset        ; 435B
	ld c, [hl]                  ; 435E
	ld b, $00                   ; 435F
	ld hl, rNR12                ; 4361
	add hl, bc                  ; 4364
	ld [hl], a                  ; 4365
	call Ch_WriteNRx4           ; 4366
	jr Ch_NoteDone              ; 4369

Ch_WriteNRx4:
	push de                     ; 436B
	ld e, a                     ; 436C
	ldh a, [hCurCh]             ; 436D
	and $03                     ; 436F
	cp $02                      ; 4371
	ld a, e                     ; 4373
	jr z, .l_4378               ; 4374
	set 7, a                    ; 4376
.l_4378:
	ld hl, rNR14                ; 4378
	add hl, bc                  ; 437B
	ld [hl], a                  ; 437C
	pop de                      ; 437D
	ret                         ; 437E

CommandTable:
	dw Cmd_Envelope  ; command $F0 (and $C0/$D0/$E0)
	dw Cmd_Duty  ; command $F1 (and $C1/$D1/$E1)
	dw Cmd_Attenuate  ; command $F2 (and $C2/$D2/$E2)
	dw Cmd_Transpose  ; command $F3 (and $C3/$D3/$E3)
	dw Cmd_Loop  ; command $F4 (and $C4/$D4/$E4)
	dw Cmd_EndLoop  ; command $F5 (and $C5/$D5/$E5)
	dw Cmd_Call  ; command $F6 (and $C6/$D6/$E6)
	dw Cmd_Ret  ; command $F7 (and $C7/$D7/$E7)
	dw Cmd_Sweep  ; command $F8 (and $C8/$D8/$E8)
	dw Cmd_SweepOff  ; command $F9 (and $C9/$D9/$E9)
	dw Cmd_TransposeUp  ; command $FA (and $CA/$DA/$EA)
	dw Cmd_Jump  ; command $FB (and $CB/$DB/$EB)
	dw Cmd_Nop  ; command $FC (and $CC/$DC/$EC)
	dw Cmd_PlaySound  ; command $FD (and $CD/$DD/$ED)
	dw Cmd_EndCount  ; command $FE (and $CE/$DE/$EE)
	dw Cmd_End  ; command $FF (and $CF/$DF/$EF)
Cmd_Nop:
	jp Ch_NextByte              ; 439F

Ch_ReadArg:
	ld hl, hStreamPtr           ; 43A2
	inc [hl]                    ; 43A5
	jr nz, .l_43AA              ; 43A6
	inc hl                      ; 43A8
	inc [hl]                    ; 43A9
.l_43AA:
	ld hl, hStreamPtr           ; 43AA
	ld a, [hli]                 ; 43AD
	ld h, [hl]                  ; 43AE
	ld l, a                     ; 43AF
	add hl, de                  ; 43B0
	ld a, [hl]                  ; 43B1
	ret                         ; 43B2

Cmd_Envelope:
	call Ch_ReadArg             ; 43B3
	add a, a                    ; 43B6
	ld e, a                     ; 43B7
	ld d, $00                   ; 43B8
	ld hl, hCurCh2              ; 43BA
	ld c, [hl]                  ; 43BD
	ld b, $00                   ; 43BE
	ld hl, EnvelopeTable        ; 43C0
	add hl, de                  ; 43C3
	ld a, [hl]                  ; 43C4
	ld hl, wChEnvPtr            ; 43C5
	add hl, bc                  ; 43C8
	ld [hl], a                  ; 43C9
	ld hl, EnvelopeTable + 1    ; 43CA
	add hl, de                  ; 43CD
	ld a, [hl]                  ; 43CE
	ld hl, wChEnvPtr + 1        ; 43CF
	add hl, bc                  ; 43D2
	ld [hl], a                  ; 43D3
	jp Ch_NextByte              ; 43D4

Cmd_Duty:
	call Ch_ReadArg             ; 43D7
	ld hl, hCurCh               ; 43DA
	ld c, [hl]                  ; 43DD
	ld b, $00                   ; 43DE
	or $3F                      ; 43E0
	ld hl, wChDuty              ; 43E2
	add hl, bc                  ; 43E5
	ld [hl], a                  ; 43E6
	ld hl, hCurRegOffset        ; 43E7
	ld c, [hl]                  ; 43EA
	ld b, $00                   ; 43EB
	ld hl, rNR11                ; 43ED
	add hl, bc                  ; 43F0
	ld [hl], a                  ; 43F1
	jp Ch_NextByte              ; 43F2

Cmd_Attenuate:
	call Ch_ReadArg             ; 43F5
	ld hl, hCurCh               ; 43F8
	ld c, [hl]                  ; 43FB
	ld b, $00                   ; 43FC
	ld hl, wChAttenuation       ; 43FE
	add hl, bc                  ; 4401
	ld [hl], a                  ; 4402
	jp Ch_NextByte              ; 4403

Cmd_Transpose:
	call Ch_ReadArg             ; 4406
	ld hl, hCurCh               ; 4409
	ld c, [hl]                  ; 440C
	ld b, $00                   ; 440D
	ld hl, wChTranspose         ; 440F
	add hl, bc                  ; 4412
	ld [hl], a                  ; 4413
	jp Ch_NextByte              ; 4414

Cmd_Loop:
	call Ch_ReadArg             ; 4417
	ld hl, hCurCh               ; 441A
	ld c, [hl]                  ; 441D
	ld b, $00                   ; 441E
	ld hl, wChLoopCount         ; 4420
	add hl, bc                  ; 4423
	ld [hl], a                  ; 4424
	ld hl, hCurCh2              ; 4425
	ld c, [hl]                  ; 4428
	ld b, $00                   ; 4429
	ldh a, [hStreamPtr]         ; 442B
	ld hl, wChLoopPtr           ; 442D
	add hl, bc                  ; 4430
	ld [hl], a                  ; 4431
	ldh a, [$FFC4]              ; 4432
	ld hl, wChLoopPtr + 1       ; 4434
	add hl, bc                  ; 4437
	ld [hl], a                  ; 4438
	jp Ch_NextByte              ; 4439

Cmd_EndLoop:
	ld hl, hCurCh               ; 443C
	ld c, [hl]                  ; 443F
	ld b, $00                   ; 4440
	ld hl, wChLoopCount         ; 4442
	add hl, bc                  ; 4445
	dec [hl]                    ; 4446
	jr z, .l_445D               ; 4447
	ld hl, hCurCh2              ; 4449
	ld c, [hl]                  ; 444C
	ld b, $00                   ; 444D
	ld hl, wChLoopPtr           ; 444F
	add hl, bc                  ; 4452
	ld a, [hl]                  ; 4453
	ldh [hStreamPtr], a         ; 4454
	ld hl, wChLoopPtr + 1       ; 4456
	add hl, bc                  ; 4459
	ld a, [hl]                  ; 445A
	ldh [$FFC4], a              ; 445B
.l_445D:
	jp Ch_NextByte              ; 445D

Cmd_Call:
	call Ch_ReadArg             ; 4460
	ldh [hTemp], a              ; 4463
	call Ch_ReadArg             ; 4465
	ldh [$FFC6], a              ; 4468
	ld hl, hCurCh2              ; 446A
	ld c, [hl]                  ; 446D
	ld b, $00                   ; 446E
	ldh a, [hStreamPtr]         ; 4470
	ld hl, wChReturnPtr         ; 4472
	add hl, bc                  ; 4475
	ld [hl], a                  ; 4476
	ldh a, [$FFC4]              ; 4477
	ld hl, wChReturnPtr + 1     ; 4479
	add hl, bc                  ; 447C
	ld [hl], a                  ; 447D
	ld hl, hTemp                ; 447E
	ld a, [hli]                 ; 4481
	ld h, [hl]                  ; 4482
	ld l, a                     ; 4483
	ld a, l                     ; 4484
	ldh [hStreamPtr], a         ; 4485
	ld a, h                     ; 4487
	ldh [$FFC4], a              ; 4488
	jp Ch_ReadByte              ; 448A

Cmd_Ret:
	ld hl, hCurCh2              ; 448D
	ld c, [hl]                  ; 4490
	ld b, $00                   ; 4491
	ld hl, wChReturnPtr         ; 4493
	add hl, bc                  ; 4496
	ld a, [hl]                  ; 4497
	ldh [hStreamPtr], a         ; 4498
	ld hl, wChReturnPtr + 1     ; 449A
	add hl, bc                  ; 449D
	ld a, [hl]                  ; 449E
	ldh [$FFC4], a              ; 449F
	jp Ch_NextByte              ; 44A1

Cmd_Sweep:
	call Ch_ReadArg             ; 44A4
	ld hl, hCurCh               ; 44A7
	ld c, [hl]                  ; 44AA
	ld b, $00                   ; 44AB
	xor $08                     ; 44AD
	and $7F                     ; 44AF
	ld hl, wChSweep             ; 44B1
	add hl, bc                  ; 44B4
	ld [hl], a                  ; 44B5
	jp Ch_NextByte              ; 44B6

Cmd_SweepOff:
	ld hl, hCurCh               ; 44B9
	ld c, [hl]                  ; 44BC
	ld b, $00                   ; 44BD
	ld a, $08                   ; 44BF
	ld hl, wChSweep             ; 44C1
	add hl, bc                  ; 44C4
	ld [hl], a                  ; 44C5
	jp Ch_NextByte              ; 44C6

Cmd_TransposeUp:
	ld hl, hCurCh               ; 44C9
	ld c, [hl]                  ; 44CC
	ld b, $00                   ; 44CD
	ld hl, wChTranspose         ; 44CF
	add hl, bc                  ; 44D2
	inc [hl]                    ; 44D3
	jp Ch_NextByte              ; 44D4

Cmd_Jump:
	call Ch_ReadArg             ; 44D7
	ld c, a                     ; 44DA
	call Ch_ReadArg             ; 44DB
	ldh [$FFC4], a              ; 44DE
	ld hl, hStreamPtr           ; 44E0
	ld [hl], c                  ; 44E3
	jp Ch_ReadByte              ; 44E4


; $FD n: queue sound n (Sound_Request) - used to chain sounds.
Cmd_PlaySound:
	call Ch_ReadArg             ; 44E7
	call Sound_Request          ; 44EA
	jp Ch_NextByte              ; 44ED


; $FE: like $FF, and counts hChannelsEnded (never read by the game).
Cmd_EndCount:
	ld hl, hChannelsEnded       ; 44F0
	inc [hl]                    ; 44F3

; $FF: channel off. When an SFX channel ends while its music twin is active, the music
; channel's sweep, duty, period and envelope are written back (Ch_RestoreMusic).
Cmd_End:
	ld hl, hCurCh               ; 44F4
	ld c, [hl]                  ; 44F7
	ld b, $00                   ; 44F8
	ld hl, ChannelBits          ; 44FA
	add hl, bc                  ; 44FD
	ld a, [hl]                  ; 44FE
	ld hl, hActiveChannels      ; 44FF
	xor [hl]                    ; 4502
	ldh [hActiveChannels], a    ; 4503
	ld a, $7C                   ; 4505
	ld hl, wChLastNote          ; 4507
	add hl, bc                  ; 450A
	ld [hl], a                  ; 450B
	ld a, c                     ; 450C
	cp $04                      ; 450D
	jr c, .l_4524               ; 450F
	ld hl, ChannelBits          ; 4511
	add hl, bc                  ; 4514
	ld a, [hl]                  ; 4515
	srl a                       ; 4516
	srl a                       ; 4518
	srl a                       ; 451A
	srl a                       ; 451C
	ld hl, hActiveChannels      ; 451E
	and [hl]                    ; 4521
	jr nz, Ch_RestoreMusic      ; 4522
.l_4524:
	ld hl, hCurRegOffset        ; 4524
	ld c, [hl]                  ; 4527
	ld b, $00                   ; 4528
	ldh a, [hChMask]            ; 452A
	and $08                     ; 452C
	jr nz, .l_4540              ; 452E
.l_4530:
	ld a, $08                   ; 4530
	ld hl, hCurRegOffset        ; 4532
	ld c, [hl]                  ; 4535
	ld b, $00                   ; 4536
	ld hl, rNR12                ; 4538
	add hl, bc                  ; 453B
	ld [hl], a                  ; 453C
.l_453D:
	call Ch_WriteNRx4           ; 453D
.l_4540:
	ldh a, [hChMask]            ; 4540
	jp Sound_NextChannel        ; 4542

Ch_RestoreMusic:
	ldh a, [hCurCh]             ; 4545
	and $03                     ; 4547
	ld e, a                     ; 4549
	ld d, $00                   ; 454A
	ld hl, hCurRegOffset        ; 454C
	ld c, [hl]                  ; 454F
	ld b, $00                   ; 4550
	jr nz, .l_455E              ; 4552
	ld hl, wChSweep             ; 4554
	add hl, de                  ; 4557
	ld a, [hl]                  ; 4558
	ld hl, rNR10                ; 4559
	add hl, bc                  ; 455C
	ld [hl], a                  ; 455D
.l_455E:
	ld a, e                     ; 455E
	cp $02                      ; 455F
	jr z, .l_456D               ; 4561
	ld hl, wChDuty              ; 4563
	add hl, de                  ; 4566
	ld a, [hl]                  ; 4567
	ld hl, rNR11                ; 4568
	add hl, bc                  ; 456B
	ld [hl], a                  ; 456C
.l_456D:
	ldh a, [hCurCh2]            ; 456D
	and $07                     ; 456F
	ld e, a                     ; 4571
	ld d, $00                   ; 4572
	ld hl, wChPeriod            ; 4574
	add hl, de                  ; 4577
	ld a, [hl]                  ; 4578
	and a                       ; 4579
	jr nz, .l_457E              ; 457A
	jr Cmd_End.l_4530           ; 457C

.l_457E:
	ld hl, rNR13                ; 457E
	add hl, bc                  ; 4581
	ld [hl], a                  ; 4582
	push bc                     ; 4583
	push de                     ; 4584
	call Ch_RestoreEnvelope     ; 4585
	pop de                      ; 4588
	pop bc                      ; 4589
	ld hl, wChPeriod + 1        ; 458A
	add hl, de                  ; 458D
	ld a, [hl]                  ; 458E
	set 7, a                    ; 458F
	jr Cmd_End.l_453D           ; 4591

Ch_RestoreEnvelope:
	ld hl, wChEnvPtr            ; 4593
	add hl, de                  ; 4596
	ld a, [hl]                  ; 4597
	ldh [hStreamPtr], a         ; 4598
	ld hl, wChEnvPtr + 1        ; 459A
	add hl, de                  ; 459D
	ld a, [hl]                  ; 459E
	ldh [$FFC4], a              ; 459F
	ldh a, [hCurCh]             ; 45A1
	and $03                     ; 45A3
	ld c, a                     ; 45A5
	ld b, $00                   ; 45A6
	ld hl, wChEnvIndex          ; 45A8
	add hl, bc                  ; 45AB
	ld a, [hl]                  ; 45AC
	ld e, a                     ; 45AD
	ld d, $00                   ; 45AE
	ld hl, hStreamPtr           ; 45B0
	ld a, [hli]                 ; 45B3
	ld h, [hl]                  ; 45B4
	ld l, a                     ; 45B5
	add hl, de                  ; 45B6
	ld a, [hl]                  ; 45B7
	ld e, a                     ; 45B8
	ld a, c                     ; 45B9
	cp $02                      ; 45BA
	jr nz, .l_45C1              ; 45BC
	ld a, e                     ; 45BE
	jr .l_45D0                  ; 45BF

.l_45C1:
	ld a, e                     ; 45C1
	ld hl, wChAttenuation       ; 45C2
	add hl, bc                  ; 45C5
	sub [hl]                    ; 45C6
	jr nc, .l_45CA              ; 45C7
	xor a                       ; 45C9
.l_45CA:
	swap a                      ; 45CA
	and $F0                     ; 45CC
	or $08                      ; 45CE
.l_45D0:
	ld hl, hCurRegOffset        ; 45D0
	ld c, [hl]                  ; 45D3
	ld b, $00                   ; 45D4
	ld hl, rNR12                ; 45D6
	add hl, bc                  ; 45D9
	ld [hl], a                  ; 45DA
	ret                         ; 45DB

ChannelBits:
	db $01, $02, $04, $08, $10, $20, $40, $80
UnusedByte_45E4:
	db $00
OctaveTable:
	db $00, $0C, $18, $24, $30, $3C, $48, $54
RegOffsetTable:
	db $00, $05, $0A, $0F, $00, $05, $0A, $0F
PeriodTable:
	dw $003B  ; C2
	dw $00AA
	dw $0112
	dw $0175
	dw $01D3
	dw $022B
	dw $027E
	dw $02CD
	dw $0317
	dw $035D
	dw $03A0
	dw $03DE
	dw $0419  ; C3
	dw $0451
	dw $0486
	dw $04B8
	dw $04E7
	dw $0513
	dw $053D
	dw $0564
	dw $058A
	dw $05AD
	dw $05CE
	dw $05EE
	dw $060B  ; C4
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
	dw $06F6
	dw $0705  ; C5
	dw $0713
	dw $0721
	dw $072D
	dw $0739
	dw $0744
	dw $074E
	dw $0758
	dw $0762
	dw $076B
	dw $0773
	dw $077B
	dw $0782  ; C6
	dw $0789
	dw $0790
	dw $0796
	dw $079C
	dw $07A2
	dw $07A7
	dw $07AC
	dw $07B1
	dw $07B5
	dw $07B9
	dw $07BD
	dw $07C1  ; C7
	dw $07C4
	dw $07C8
	dw $07CB
	dw $07CE
	dw $07D1
	dw $07D3
	dw $07D6
	dw $07D8
	dw $07DA
	dw $07DC
	dw $07DE
NoiseTable:
	db $00, $10, $20, $30, $07, $23, $50, $33, $60, $43, $70, $45, $47, $55, $65
SoundTable:
	dw Sound00  ; sound 0 (unused: ids start at 1)
	dw Sound01  ; sound 1
	dw Sound02  ; sound 2
	dw Sound03  ; sound 3
	dw Sound04  ; sound 4
	dw Sound05  ; sound 5
	dw Sound06  ; sound 6
	dw Sound07  ; sound 7
	dw Sound08  ; sound 8
	dw Sound09  ; sound 9
	dw Sound10  ; sound 10
	dw Sound11  ; sound 11
	dw Sound12  ; sound 12
	dw Sound13  ; sound 13
	dw Sound14  ; sound 14
	dw Sound15  ; sound 15
	dw Sound16  ; sound 16
	dw Sound17  ; sound 17
	dw Sound18  ; sound 18
	dw Sound19  ; sound 19
	dw Sound20  ; sound 20
	dw Sound21  ; sound 21
	dw Sound22  ; sound 22
	dw Sound23  ; sound 23
	dw Sound24  ; sound 24
	dw Sound25  ; sound 25
	dw Sound26  ; sound 26
	dw Sound27  ; sound 27
	dw Sound28  ; sound 28
	dw Sound29  ; sound 29
	dw Sound30  ; sound 30
	dw Sound31  ; sound 31
	dw Sound32  ; sound 32
	dw Sound33  ; sound 33
	dw Sound34  ; sound 34
	dw Sound35  ; sound 35
	dw Sound36  ; sound 36
	dw Sound37  ; sound 37
	dw Sound38  ; sound 38
	dw Sound39  ; sound 39
	dw Sound40  ; sound 40
	dw Sound41  ; sound 41
	dw Sound42  ; sound 42
	dw Sound43  ; sound 43
	dw Sound44  ; sound 44
	dw Sound00  ; sound 45
	dw Sound46  ; sound 46
NumSounds:
	db 47  ; number of sounds (read by the sound-test screen)
LengthTable:
	db   5,   9,  18,  27,  36,  54,  72, 108, 144, 216,  10,  15,  20,  30, 176,   1  ; lengths 0-15 (fast music: +16 for indices 0-31)
	db   4,   8,  16,  24,  32,  48,  64,  96, 128, 224, 255,  20,  49,  81,  92,   2  ; lengths 16-31
	db   3,   7,  14,  21,  28,  42,  56,  84, 112, 168, 224,  17,  52, 140,  15,   3  ; lengths 32-47
	db   3,   6,  12,  18,  24,  36,  48,  72,  96, 144, 192,  70,   0,   0,   0,   4  ; lengths 48-63
EnvelopeTable:
	dw Envelope00  ; envelope 0
	dw Envelope01  ; envelope 1
	dw Envelope02  ; envelope 2
	dw Envelope03  ; envelope 3
	dw Envelope04  ; envelope 4 (not selected by any stream)
	dw Envelope05  ; envelope 5
	dw Envelope06  ; envelope 6
	dw Envelope07  ; envelope 7
	dw Envelope08  ; envelope 8 (not selected by any stream)
	dw Envelope09  ; envelope 9
	dw Envelope10  ; envelope 10 (not selected by any stream)
	dw Envelope11  ; envelope 11
	dw Envelope12  ; envelope 12 (not selected by any stream)
	dw Envelope13  ; envelope 13
	dw Envelope14  ; envelope 14
	dw Envelope15  ; envelope 15
	dw Envelope16  ; envelope 16
	dw Envelope17  ; envelope 17
	dw Envelope18  ; envelope 18
	dw Envelope19  ; envelope 19
Envelope00:
	env_hold 15
Envelope01:
	env_hold 255
Envelope02:
	env_step 1, 15
	env_hold 0
Envelope03:
	env_step 1, 15
	env_step 1, 11
	env_hold 0
Envelope04:
	env_step 1, 15
	env_step 2, 11
	env_step 2, 10
	env_step 2, 9
	env_step 2, 8
	env_step 2, 7
	env_hold 0
Envelope05:
	env_step 1, 15
	env_step 2, 11
	env_step 2, 10
	env_step 2, 9
	env_step 2, 8
	env_step 2, 7
	env_step 2, 6
	env_step 2, 5
	env_step 2, 4
	env_step 2, 3
	env_step 2, 2
	env_step 2, 1
	env_hold 0
Envelope06:
	env_step 2, 15
	env_step 1, 14
	env_step 1, 12
	env_step 1, 10
	env_step 1, 8
	env_step 1, 6
	env_step 1, 5
	env_step 1, 4
	env_step 1, 3
	env_step 1, 2
	env_step 1, 1
	env_hold 0
Envelope07:
	env_step 1, 14
	env_step 1, 14
	env_step 1, 12
	env_step 1, 10
	env_step 1, 8
	env_step 1, 6
	env_step 1, 5
	env_step 1, 4
	env_step 1, 3
	env_step 1, 2
	env_step 1, 1
	env_hold 0
Envelope08:
	env_step 0, 0
	env_step 6, 1
	env_step 6, 2
	env_step 6, 3
	env_step 6, 4
	env_step 6, 5
	env_step 6, 6
	env_step 5, 7
	env_step 5, 8
	env_step 5, 9
	env_step 5, 10
	env_step 4, 11
	env_step 4, 12
	env_step 3, 13
	env_step 3, 14
	env_step 2, 15
	env_hold 0
Envelope09:
	env_step 1, 15
	env_step 3, 14
	env_step 3, 13
	env_step 4, 12
	env_step 4, 11
	env_step 8, 10
	env_step 9, 9
	env_step 10, 8
	env_step 10, 7
	env_step 10, 6
	env_step 10, 5
	env_step 10, 4
	env_step 10, 3
	env_step 10, 2
	env_step 10, 1
	env_hold 0
Envelope10:
	env_step 1, 10
	env_hold 15
Envelope11:
	env_step 2, 15
	env_step 3, 14
	env_step 4, 13
	env_step 6, 12
	env_step 6, 11
	env_step 6, 10
	env_step 6, 9
	env_step 6, 8
	env_step 6, 7
	env_step 6, 6
	env_step 6, 5
	env_step 6, 4
	env_step 7, 3
	env_step 7, 2
	env_step 7, 1
	env_hold 0
Envelope12:
	env_step 2, 15
	env_step 2, 13
	env_step 3, 10
	env_step 4, 9
	env_step 5, 6
	env_step 6, 3
	env_step 7, 1
	env_hold 0
Envelope13:
	env_step 1, 15
	env_step 1, 12
	env_step 2, 10
	env_hold 9
Envelope14:
	env_step 2, 15
	env_step 1, 11
	env_step 1, 9
	env_step 1, 8
	env_step 1, 7
	env_step 1, 5
	env_step 1, 3
	env_hold 0
Envelope15:
	env_hold 20
Envelope16:
	env_step 5, 15
	env_step 5, 14
	env_step 5, 13
	env_step 5, 12
	env_step 5, 11
	env_step 5, 10
	env_step 5, 9
	env_step 5, 8
	env_step 5, 7
	env_step 6, 6
	env_step 6, 5
	env_step 8, 4
	env_step 8, 3
	env_step 8, 2
	env_step 8, 1
	env_hold 0
Envelope17:
	env_step 9, 15
	env_step 9, 14
	env_step 9, 13
	env_step 10, 12
	env_step 10, 11
	env_step 10, 10
	env_step 11, 9
	env_step 11, 8
	env_step 12, 7
	env_step 13, 6
	env_step 14, 5
	env_step 16, 4
	env_step 18, 3
	env_step 20, 2
	env_step 30, 1
	env_hold 0
Envelope18:
	env_step 2, 15
	env_step 1, 11
	env_step 6, 9
	env_step 6, 8
	env_step 6, 7
	env_step 7, 5
	env_step 7, 3
	env_hold 0
Envelope19:
	env_step 1, 0
	env_step 12, 1
	env_step 11, 2
	env_step 11, 3
	env_step 10, 4
	env_step 10, 5
	env_step 10, 6
	env_step 10, 7
	env_step 10, 8
	env_step 10, 9
	env_step 9, 10
	env_step 8, 11
	env_step 7, 12
	env_step 7, 13
	env_step 7, 14
	env_step 7, 15
