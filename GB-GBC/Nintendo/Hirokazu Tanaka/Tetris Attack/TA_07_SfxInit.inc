; Tetris Attack SFX and music, bank $07: SFX init routines and stream player, $4255-$4FC1

Sfx_01:
	call Sfx_MuteAll
	call TakeCh1
	call TakeCh2
	call TakeCh3
	call TakeCh4
	ld hl, Sfx_01_Ch1
	call SetStreamCh1
	ld bc, Sfx_01_Ch2
	call SetStreamCh2
	ld de, Sfx_01_Ch4
	call SetStreamCh4
	ld hl, Sfx_01_Ch3
	ld a, h
	ld [wSfxPtrCh3], a
	ld a, l
	ld [wSfxPtrCh3+1], a
	ld hl, WaveStream_6743
	ld a, h
	ld [wSfxWavePtr], a
	ld a, l
	ld [wSfxWavePtr+1], a
	ld a, $10
	ld [wSfxMode], a
	xor a
	ld [wSfxPriority], a
	ld [wSfx3Request], a
	ld [wSfx4Request], a
	ld [wSfx3Playing], a
	ld [wSfx4Playing], a
	ld a, $0f
	ld [wSfxChannels], a
	jp Sfx_Update.play

Sfx_02:
	call Sfx_MuteAll
	call TakeCh1
	call TakeCh2
	call TakeCh3
	call TakeCh4
	ld hl, Sfx_02_Ch1
	call SetStreamCh1
	ld bc, Sfx_02_Ch2
	call SetStreamCh2
	ld de, Sfx_02_Ch4
	call SetStreamCh4
	ld hl, Sfx_02_Ch3
	ld a, h
	ld [wSfxPtrCh3], a
	ld a, l
	ld [wSfxPtrCh3+1], a
	ld hl, WaveStream_6743
	ld a, h
	ld [wSfxWavePtr], a
	ld a, l
	ld [wSfxWavePtr+1], a
	ld a, $10
	ld [wSfxMode], a
	xor a
	ld [wSfxPriority], a
	ld [wSfx3Request], a
	ld [wSfx4Request], a
	ld [wSfx3Playing], a
	ld [wSfx4Playing], a
	ld a, $0f
	ld [wSfxChannels], a
	jp Sfx_Update.play

Sfx_03:
	call Sfx_MuteAll
	call TakeCh1
	call TakeCh2
	call TakeCh3
	call TakeCh4
	ld hl, Sfx_03_Ch1
	call SetStreamCh1
	ld bc, Sfx_03_Ch2
	call SetStreamCh2
	ld de, Sfx_03_Ch4
	call SetStreamCh4
	ld hl, Sfx_03_Ch3
	ld a, h
	ld [wSfxPtrCh3], a
	ld a, l
	ld [wSfxPtrCh3+1], a
	ld hl, WaveStream_6743
	ld a, h
	ld [wSfxWavePtr], a
	ld a, l
	ld [wSfxWavePtr+1], a
	ld a, $10
	ld [wSfxMode], a
	xor a
	ld [wSfxPriority], a
	ld [wSfx3Request], a
	ld [wSfx4Request], a
	ld [wSfx3Playing], a
	ld [wSfx4Playing], a
	ld a, $0f
	ld [wSfxChannels], a
	jp Sfx_Update.play

Sfx_04:
	call TakeCh2
	ld bc, Sfx_04_Ch2
	call SetStreamCh2
	ld a, $03
	ld [wSfxPriority], a
	ld a, $04
	ld [wSfxChannels], a
	jp Sfx_Update.play

Sfx_05:
	call TakeCh1
	ld hl, Sfx_05_Ch1
	call SetStreamCh1
	xor a
	ld [wSfxMode], a
	ld a, $08
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_06:
	call TakeCh1
	ld hl, Sfx_06_Ch1
	call SetStreamCh1
	xor a
	ld [wSfxMode], a
	ld a, $08
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_07:
	call TakeCh1
	ld hl, Sfx_07_Ch1
	call SetStreamCh1
	xor a
	ld [wSfxMode], a
	ld a, $08
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_08:
	call TakeCh1
	ld hl, Sfx_08_Ch1
	call SetStreamCh1
	xor a
	ld [wSfxMode], a
	ld a, $08
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

; unreachable
	ret

Sfx_09:
	call TakeCh1
	ld hl, Sfx_09_Ch1
	call SetStreamCh1
	xor a
	ld [wSfxMode], a
	ld a, $08
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_0A:
	call TakeCh1
	ld hl, Sfx_0A_Ch1
	call SetStreamCh1
	xor a
	ld [wSfxMode], a
	ld a, $08
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_0B:
	call TakeCh1
	ld hl, Sfx_0B_Ch1
	call SetStreamCh1
	xor a
	ld [wSfxMode], a
	ld a, $08
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_0C:
	call TakeCh1
	ld hl, Sfx_0C_Ch1
	call SetStreamCh1
	xor a
	ld [wSfxMode], a
	ld a, $08
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_0D:
	call TakeCh1
	ld hl, Sfx_0D_Ch1
	call SetStreamCh1
	xor a
	ld [wSfxMode], a
	ld a, $08
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_0E:
	call TakeCh1
	ld hl, Sfx_0E_Ch1
	call SetStreamCh1
	xor a
	ld [wSfxMode], a
	ld a, $08
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_0F:
	call TakeCh1
	ld hl, Sfx_0F_Ch1
	call SetStreamCh1
	xor a
	ld [wSfxMode], a
	ld a, $08
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_10:
	call TakeCh1
	ld hl, Sfx_10_Ch1
	call SetStreamCh1
	xor a
	ld [wSfxMode], a
	ld a, $08
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_11:
	call TakeCh1
	ld hl, Sfx_11_Ch1
	call SetStreamCh1
	xor a
	ld [wSfxMode], a
	ld a, $08
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_12:
	call TakeCh1
	ld hl, Sfx_12_Ch1
	call SetStreamCh1
	xor a
	ld [wSfxMode], a
	ld a, $08
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_13:
	call TakeCh1
	ld hl, Sfx_13_Ch1
	call SetStreamCh1
	xor a
	ld [wSfxMode], a
	ld a, $08
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_14:
	call TakeCh1
	ld hl, Sfx_14_Ch1
	call SetStreamCh1
	xor a
	ld [wSfxMode], a
	ld a, $08
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_15:
	call TakeCh1
	ld hl, Sfx_15_Ch1
	call SetStreamCh1
	xor a
	ld [wSfxMode], a
	ld a, $08
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_16:
	call TakeCh1
	ld hl, Sfx_16_Ch1
	call SetStreamCh1
	xor a
	ld [wSfxMode], a
	ld a, $08
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_17:
	call TakeCh1
	ld hl, Sfx_17_Ch1
	call SetStreamCh1
	xor a
	ld [wSfxMode], a
	ld a, $08
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_18:
	call TakeCh1
	ld hl, Sfx_18_Ch1
	call SetStreamCh1
	xor a
	ld [wSfxMode], a
	ld a, $08
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_19:
	call TakeCh1
	call TakeCh4
	ld hl, Sfx_19_Ch1
	call SetStreamCh1
	ld de, Sfx_19_Ch4
	call SetStreamCh4
	ld a, $10
	ld [wSfxMode], a
	ld a, $09
	ld [wSfxChannels], a
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_1A:
	call TakeCh1
	call TakeCh4
	ld hl, Sfx_1A_Ch1
	call SetStreamCh1
	ld de, Sfx_19_Ch4
	call SetStreamCh4
	ld a, $10
	ld [wSfxMode], a
	ld a, $09
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_1B:
	call TakeCh1
	call TakeCh4
	ld hl, Sfx_1B_Ch1
	call SetStreamCh1
	ld de, Sfx_19_Ch4
	call SetStreamCh4
	ld a, $10
	ld [wSfxMode], a
	ld a, $09
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_1C:
	call TakeCh1
	call TakeCh4
	ld hl, Sfx_1C_Ch1
	call SetStreamCh1
	ld de, Sfx_19_Ch4
	call SetStreamCh4
	ld a, $10
	ld [wSfxMode], a
	ld a, $09
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_1D:
	call TakeCh1
	call TakeCh4
	ld hl, Sfx_1D_Ch1
	call SetStreamCh1
	ld de, Sfx_19_Ch4
	call SetStreamCh4
	ld a, $10
	ld [wSfxMode], a
	ld a, $09
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_1E:
	call TakeCh1
	call TakeCh4
	ld hl, Sfx_1E_Ch1
	call SetStreamCh1
	ld de, Sfx_19_Ch4
	call SetStreamCh4
	ld a, $10
	ld [wSfxMode], a
	ld a, $09
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_1F:
	call TakeCh1
	call TakeCh4
	ld hl, Sfx_1F_Ch1
	call SetStreamCh1
	ld de, Sfx_1F_Ch4
	call SetStreamCh4
	ld a, $10
	ld [wSfxMode], a
	ld a, $09
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_20:
	call TakeCh1
	call TakeCh4
	ld hl, Sfx_20_Ch1
	call SetStreamCh1
	ld de, Sfx_1F_Ch4
	call SetStreamCh4
	ld a, $10
	ld [wSfxMode], a
	ld a, $09
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_21:
	call TakeCh1
	call TakeCh4
	ld hl, Sfx_21_Ch1
	call SetStreamCh1
	ld de, Sfx_1F_Ch4
	call SetStreamCh4
	ld a, $10
	ld [wSfxMode], a
	ld a, $09
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_22:
	call TakeCh1
	call TakeCh4
	ld hl, Sfx_22_Ch1
	call SetStreamCh1
	ld de, Sfx_1F_Ch4
	call SetStreamCh4
	ld a, $10
	ld [wSfxMode], a
	ld a, $09
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_23:
	call TakeCh1
	call TakeCh3
	ld hl, Sfx_23_Ch3
	ld a, h
	ld [wSfxPtrCh3], a
	ld a, l
	ld [wSfxPtrCh3+1], a
	ld hl, WaveStream_6783
	ld a, h
	ld [wSfxWavePtr], a
	ld a, l
	ld [wSfxWavePtr+1], a
	ld hl, Sfx_23_Ch1
	call SetStreamCh1
	ld a, $00
	ld [wSfxMode], a
	ld a, $0a
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_24:
	call TakeCh1
	call TakeCh3
	ld hl, Sfx_24_Ch3
	ld a, h
	ld [wSfxPtrCh3], a
	ld a, l
	ld [wSfxPtrCh3+1], a
	ld hl, WaveStream_6783
	ld a, h
	ld [wSfxWavePtr], a
	ld a, l
	ld [wSfxWavePtr+1], a
	ld hl, Sfx_24_Ch1
	call SetStreamCh1
	ld a, $00
	ld [wSfxMode], a
	ld a, $0a
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_25:
	call TakeCh1
	call TakeCh3
	ld hl, Sfx_25_Ch3
	ld a, h
	ld [wSfxPtrCh3], a
	ld a, l
	ld [wSfxPtrCh3+1], a
	ld hl, WaveStream_6783
	ld a, h
	ld [wSfxWavePtr], a
	ld a, l
	ld [wSfxWavePtr+1], a
	ld hl, Sfx_25_Ch1
	call SetStreamCh1
	ld a, $00
	ld [wSfxMode], a
	ld a, $0a
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_26:
	call TakeCh1
	call TakeCh3
	ld hl, Sfx_26_Ch3
	ld a, h
	ld [wSfxPtrCh3], a
	ld a, l
	ld [wSfxPtrCh3+1], a
	ld hl, WaveStream_6783
	ld a, h
	ld [wSfxWavePtr], a
	ld a, l
	ld [wSfxWavePtr+1], a
	ld hl, Sfx_26_Ch1
	call SetStreamCh1
	ld a, $00
	ld [wSfxMode], a
	ld a, $0a
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_27:
	call TakeCh1
	call TakeCh3
	ld hl, Sfx_27_Ch3
	ld a, h
	ld [wSfxPtrCh3], a
	ld a, l
	ld [wSfxPtrCh3+1], a
	ld hl, WaveStream_6783
	ld a, h
	ld [wSfxWavePtr], a
	ld a, l
	ld [wSfxWavePtr+1], a
	ld hl, Sfx_27_Ch1
	call SetStreamCh1
	ld a, $00
	ld [wSfxMode], a
	ld a, $0a
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_28:
	call TakeCh1
	call TakeCh3
	ld hl, Sfx_28_Ch3
	ld a, h
	ld [wSfxPtrCh3], a
	ld a, l
	ld [wSfxPtrCh3+1], a
	ld hl, WaveStream_6783
	ld a, h
	ld [wSfxWavePtr], a
	ld a, l
	ld [wSfxWavePtr+1], a
	ld hl, Sfx_28_Ch1
	call SetStreamCh1
	ld a, $00
	ld [wSfxMode], a
	ld a, $0a
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_29:
	call TakeCh1
	call TakeCh3
	ld hl, Sfx_29_Ch3
	ld a, h
	ld [wSfxPtrCh3], a
	ld a, l
	ld [wSfxPtrCh3+1], a
	ld hl, WaveStream_6783
	ld a, h
	ld [wSfxWavePtr], a
	ld a, l
	ld [wSfxWavePtr+1], a
	ld hl, Sfx_29_Ch1
	call SetStreamCh1
	ld a, $00
	ld [wSfxMode], a
	ld a, $0a
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_2A:
	call TakeCh1
	call TakeCh3
	ld hl, Sfx_2A_Ch3
	ld a, h
	ld [wSfxPtrCh3], a
	ld a, l
	ld [wSfxPtrCh3+1], a
	ld hl, WaveStream_6783
	ld a, h
	ld [wSfxWavePtr], a
	ld a, l
	ld [wSfxWavePtr+1], a
	ld hl, Sfx_2A_Ch1
	call SetStreamCh1
	ld a, $00
	ld [wSfxMode], a
	ld a, $0a
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_2B:
	call TakeCh1
	call TakeCh3
	ld hl, Sfx_2B_Ch3
	ld a, h
	ld [wSfxPtrCh3], a
	ld a, l
	ld [wSfxPtrCh3+1], a
	ld hl, WaveStream_6783
	ld a, h
	ld [wSfxWavePtr], a
	ld a, l
	ld [wSfxWavePtr+1], a
	ld hl, Sfx_2B_Ch1
	call SetStreamCh1
	ld a, $00
	ld [wSfxMode], a
	ld a, $0a
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_2C:
	call TakeCh1
	call TakeCh3
	ld hl, Sfx_2C_Ch3
	ld a, h
	ld [wSfxPtrCh3], a
	ld a, l
	ld [wSfxPtrCh3+1], a
	ld hl, WaveStream_6783
	ld a, h
	ld [wSfxWavePtr], a
	ld a, l
	ld [wSfxWavePtr+1], a
	ld hl, Sfx_2C_Ch1
	call SetStreamCh1
	ld a, $00
	ld [wSfxMode], a
	ld a, $0a
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_2D:
	call TakeCh1
	call TakeCh3
	call TakeCh4
	ld hl, Sfx_2D_Ch1
	call SetStreamCh1
	ld de, Sfx_2D_Ch4
	call SetStreamCh4
	ld hl, Sfx_2D_Ch3
	ld a, h
	ld [wSfxPtrCh3], a
	ld a, l
	ld [wSfxPtrCh3+1], a
	ld hl, WaveStream_6743
	ld a, h
	ld [wSfxWavePtr], a
	ld a, l
	ld [wSfxWavePtr+1], a
	ld a, $10
	ld [wSfxMode], a
	ld a, $0b
	ld [wSfxChannels], a
	ld a, $01
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_35:
	call TakeCh1
	call TakeCh3
	ld hl, Sfx_35_Ch1
	call SetStreamCh1
	ld hl, Sfx_35_Ch3
	ld a, h
	ld [wSfxPtrCh3], a
	ld a, l
	ld [wSfxPtrCh3+1], a
	ld hl, WaveStream_6743
	ld a, h
	ld [wSfxWavePtr], a
	ld a, l
	ld [wSfxWavePtr+1], a
	xor a
	ld [wSfxMode], a
	ld a, $0a
	ld [wSfxChannels], a
	ld a, $02
	ld [wSfxPriority], a
	jp Sfx_Update.play

; unreachable
	ret

Sfx_33:
	call TakeCh1
	call TakeCh2
	call TakeCh3
	ld hl, Sfx_33_Ch1
	call SetStreamCh1
	ld bc, Sfx_33_Ch2
	call SetStreamCh2
	ld hl, Sfx_33_Ch3
	ld a, h
	ld [wSfxPtrCh3], a
	ld a, l
	ld [wSfxPtrCh3+1], a
	ld hl, WaveStream_5DAE
	ld a, h
	ld [wSfxWavePtr], a
	ld a, l
	ld [wSfxWavePtr+1], a
	xor a
	ld [wSfxMode], a
	ld a, $0e
	ld [wSfxChannels], a
	ld a, $01
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_31:
	call TakeCh3
	ld hl, Sfx_31_Ch3
	ld a, h
	ld [wSfxPtrCh3], a
	ld a, l
	ld [wSfxPtrCh3+1], a
	ld hl, WaveStream_5DFC
	ld a, h
	ld [wSfxWavePtr], a
	ld a, l
	ld [wSfxWavePtr+1], a
	xor a
	ld [wSfxMode], a
	ld a, $02
	ld [wSfxChannels], a
	ld a, $01
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_2F:
	call TakeCh1
	call TakeCh4
	ld hl, Sfx_2F_Ch1
	call SetStreamCh1
	ld de, Sfx_2F_Ch4
	call SetStreamCh4
	ld a, $10
	ld [wSfxMode], a
	ld a, $09
	ld [wSfxChannels], a
	ld a, $01
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_30:
	call TakeCh1
	ld hl, Sfx_30_Ch1
	call SetStreamCh1
	xor a
	ld [wSfxMode], a
	ld a, $08
	ld [wSfxChannels], a
	ld a, $01
	ld [wSfxPriority], a
	jp Sfx_Update.play

; unreachable
	ret

Sfx_32:
	call TakeCh1
	call TakeCh2
	ld hl, Sfx_32_Ch1
	call SetStreamCh1
	ld bc, Sfx_32_Ch2
	call SetStreamCh2
	xor a
	ld [wSfxMode], a
	ld a, $0c
	ld [wSfxChannels], a
	ld a, $01
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_2E:
	call TakeCh1
	call TakeCh3
	ld hl, Sfx_2E_Ch1
	call SetStreamCh1
	ld hl, Sfx_2E_Ch3
	ld a, h
	ld [wSfxPtrCh3], a
	ld a, l
	ld [wSfxPtrCh3+1], a
	ld hl, WaveStream_6783
	ld a, h
	ld [wSfxWavePtr], a
	ld a, l
	ld [wSfxWavePtr+1], a
	xor a
	ld [wSfxMode], a
	ld a, $0a
	ld [wSfxChannels], a
	ld a, $01
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_34:
	call TakeCh1
	call TakeCh2
	ld hl, Sfx_34_Ch1
	call SetStreamCh1
	ld bc, Sfx_34_Ch2
	call SetStreamCh2
	xor a
	ld [wSfxMode], a
	ld a, $0c
	ld [wSfxChannels], a
	ld a, $01
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_38:
	call TakeCh1
	call TakeCh3
	ld hl, Sfx_38_Ch1
	call SetStreamCh1
	ld hl, Sfx_38_Ch3
	ld a, h
	ld [wSfxPtrCh3], a
	ld a, l
	ld [wSfxPtrCh3+1], a
	ld hl, WaveStream_6783
	ld a, h
	ld [wSfxWavePtr], a
	ld a, l
	ld [wSfxWavePtr+1], a
	xor a
	ld [wSfxMode], a
	ld a, $0a
	ld [wSfxChannels], a
	ld a, $01
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_37:
	call TakeCh1
	call TakeCh3
	call TakeCh4
	ld hl, Sfx_37_Ch1
	call SetStreamCh1
	ld de, Sfx_37_Ch4
	call SetStreamCh4
	ld hl, Sfx_37_Ch3
	ld a, h
	ld [wSfxPtrCh3], a
	ld a, l
	ld [wSfxPtrCh3+1], a
	ld hl, WaveStream_61F7
	ld a, h
	ld [wSfxWavePtr], a
	ld a, l
	ld [wSfxWavePtr+1], a
	ld a, $10
	ld [wSfxMode], a
	ld a, $0b
	ld [wSfxChannels], a
	ld a, $01
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_36:
	call TakeCh1
	ld hl, Sfx_36_Ch1
	call SetStreamCh1
	xor a
	ld [wSfxMode], a
	ld a, $08
	ld [wSfxChannels], a
	ld a, $01
	ld [wSfxPriority], a
	jp Sfx_Update.play

Sfx_39:
	call TakeCh1
	ld hl, Sfx_39_Ch1
	call SetStreamCh1
	xor a
	ld [wSfxMode], a
	ld a, $04
	ld [wSfxPriority], a
	ld a, $08
	ld [wSfxChannels], a
	jp Sfx_Update.play

Sfx_3A:
	call TakeCh1
	ld hl, Sfx_3A_Ch1
	ld a, h
	ld [wSfxPtrCh1], a
	ld a, l
	ld [wSfxPtrCh1+1], a
	xor a
	ld [wSfxMode], a
	ld a, $03
	ld [wSfxPriority], a
	ld a, $08
	ld [wSfxChannels], a
	jp Sfx_Update.play

Sfx_3B:
	call TakeCh1
	ld hl, Sfx_3B_Ch1
	ld a, h
	ld [wSfxPtrCh1], a
	ld a, l
	ld [wSfxPtrCh1+1], a
	xor a
	ld [wSfxPriority], a
	ld [wSfxMode], a
	ld a, $08
	ld [wSfxChannels], a
	jp Sfx_Update.play

Sfx_3C:
	call TakeCh1
	ld hl, Sfx_3C_Ch1
	ld a, h
	ld [wSfxPtrCh1], a
	ld a, l
	ld [wSfxPtrCh1+1], a
	xor a
	ld [wSfxMode], a
	ld [wSfxPriority], a
	ld a, $08
	ld [wSfxChannels], a
	jp Sfx_Update.play

Sfx_3D:
	call TakeCh1
	ld hl, Sfx_3D_Ch1
	call SetStreamCh1
	xor a
	ld [wSfxMode], a
	ld a, $04
	ld [wSfxPriority], a
	ld a, $08
	ld [wSfxChannels], a
	jp Sfx_Update.play

Sfx_3E:
	call Sfx_MuteAll
	call TakeCh1
	call TakeCh2
	call TakeCh3
	call TakeCh4
	ld hl, Sfx_3E_Ch1
	call SetStreamCh1
	ld bc, Sfx_3E_Ch2
	call SetStreamCh2
	ld de, Sfx_3E_Ch4
	call SetStreamCh4
	ld hl, Sfx_3E_Ch3
	ld a, h
	ld [wSfxPtrCh3], a
	ld a, l
	ld [wSfxPtrCh3+1], a
	ld hl, WaveStream_6723
	ld a, h
	ld [wSfxWavePtr], a
	ld a, l
	ld [wSfxWavePtr+1], a
	xor a
	ld [wSfxMode], a
	ld [wSfxPriority], a
	ld a, $0f
	ld [wSfxChannels], a
	jp Sfx_Update.play

Sfx_3F:
	call TakeCh1
	ld hl, Sfx_3F_Ch1
	call SetStreamCh1
	xor a
	ld [wSfxMode], a
	ld [wSfxPriority], a
	ld a, $08
	ld [wSfxChannels], a
	jp Sfx_Update.play

Sfx_40:
	call TakeCh4
	ld de, Sfx_40_Ch4
	call SetStreamCh4
	ld a, $10
	ld [wSfxMode], a
	ld a, $04
	ld [wSfxPriority], a
	ld a, $01
	ld [wSfxChannels], a
	jp Sfx_Update.play

Sfx_41:
	call TakeCh4
	ld de, Sfx_41_Ch4
	call SetStreamCh4
	ld a, $10
	ld [wSfxMode], a
	ld a, $01
	ld [wSfxPriority], a
	ld a, $01
	ld [wSfxChannels], a
	jp Sfx_Update.play

; unreachable
	ret

Sfx_42:
	call TakeCh4
	ld de, Sfx_42_Ch4
	call SetStreamCh4
	ld a, $10
	ld [wSfxMode], a
	ld a, $01
	ld [wSfxPriority], a
	ld a, $01
	ld [wSfxChannels], a
	jp Sfx_Update.play

; unreachable
	ret

Sfx_43:
	call TakeCh4
	ld de, Sfx_43_Ch4
	call SetStreamCh4
	ld a, $10
	ld [wSfxMode], a
	ld a, $01
	ld [wSfxPriority], a
	ld a, $01
	ld [wSfxChannels], a
	jp Sfx_Update.play

; unreachable
	ret

Sfx_44:
	call TakeCh1
	call TakeCh2
	ld hl, Sfx_44_Ch1
	call SetStreamCh1
	ld bc, Sfx_44_Ch2
	call SetStreamCh2
	ld a, $00
	ld [wSfxMode], a
	ld a, $02
	ld [wSfxPriority], a
	ld a, $0c
	ld [wSfxChannels], a
	jp Sfx_Update.play

Sfx_45:
	call TakeCh1
	ld hl, Sfx_45_Ch1
	call SetStreamCh1
	ld a, $00
	ld [wSfxPriority], a
	ld a, $08
	ld [wSfxChannels], a
	ld a, $00
	ld [wSfxMode], a
	jp Sfx_Update.play

; unreachable
	ret

; also effect $47
Sfx_46:
	call TakeCh4
	ld de, Sfx_46_Ch4
	call SetStreamCh4
	xor a
	ld [wSfxPriority], a
	ld a, $01
	ld [wSfxChannels], a
	jp Sfx_Update.play

Sfx_48:
	call TakeCh1
	ld hl, Sfx_48_Ch1
	call SetStreamCh1
	xor a
	ld [wSfxPriority], a
	ld a, $08
	ld [wSfxChannels], a
	jp Sfx_Update.play

Sfx_49:
	call TakeCh1
	ld hl, Sfx_49_Ch1
	call SetStreamCh1
	xor a
	ld [wSfxPriority], a
	ld a, $08
	ld [wSfxChannels], a
	jp Sfx_Update.play

Sfx_4A:
	call TakeCh4
	ld de, Sfx_4A_Ch4
	call SetStreamCh4
	xor a
	ld [wSfxPriority], a
	ld a, $01
	ld [wSfxChannels], a
	jp Sfx_Update.play

Sfx_4B:
	call TakeCh1
	ld hl, Sfx_4B_Ch1
	call SetStreamCh1
	xor a
	ld [wSfxPriority], a
	ld a, $08
	ld [wSfxChannels], a
	jp Sfx_Update.play

Sfx_4C:
	call TakeCh1
	ld hl, Sfx_4C_Ch1
	call SetStreamCh1
	ld bc, Sfx_4C_Ch2
	call SetStreamCh2
	xor a
	ld [wSfxPriority], a
	ld a, $0c
	ld [wSfxChannels], a
	jp Sfx_Update.play

Sfx_4D:
	call TakeCh1
	ld hl, Sfx_4D_Ch1
	call SetStreamCh1
	xor a
	ld [wSfxMode], a
	ld [wSfxPriority], a
	ld a, $08
	ld [wSfxChannels], a
	jp Sfx_Update.play

Sfx_4E:
	call TakeCh1
	call TakeCh2
	ld hl, Sfx_4E_Ch1
	call SetStreamCh1
	ld bc, Sfx_4E_Ch2
	call SetStreamCh2
	xor a
	ld [wSfxMode], a
	ld [wSfxPriority], a
	ld a, $0c
	ld [wSfxChannels], a
	jp Sfx_Update.play

Sfx_4F:
	call TakeCh3
	ld hl, Sfx_4F_Ch3
	ld a, h
	ld [wSfxPtrCh3], a
	ld a, l
	ld [wSfxPtrCh3+1], a
	ld hl, WaveStream_6723
	ld a, h
	ld [wSfxWavePtr], a
	ld a, l
	ld [wSfxWavePtr+1], a
	xor a
	ld [wSfxMode], a
	ld [wSfxPriority], a
	ld a, $02
	ld [wSfxChannels], a
	jp Sfx_Update.play

Sfx_50:
	call TakeCh1
	ld hl, Sfx_3E_Ch1
	call SetStreamCh1
	xor a
	ld [wSfxMode], a
	ld [wSfxPriority], a
	ld a, $08
	ld [wSfxChannels], a
	jp Sfx_Update.play

; Slot 2: wSfx3Request = 1 plays the noise stream NoiseStream_6300 on ch4 (2 registers + frames).
Noise_Update:
	ld a, [wSfx3Request]
	cp $01
	jp nz, .playing
	ld [wSfx3Playing], a
	ld a, $01
	ld hl, wNoiseFrames
	ld [hl], a
	call TakeCh4
	ld de, NoiseStream_6300
	call SetNoiseStream
	ld a, $04
	ld [wSfxPriority], a
.playing:
	ld a, [wSfx3Playing]
	and a
	ret z
	ld hl, wNoiseFrames
	dec [hl]
	jr nz, .done
	ld a, [wNoisePtr]
	ld h, a
	ld a, [wNoisePtr+1]
	ld l, a
	xor a
	ldh [rNR41], a
	ld c, $21
	ld b, $02
	call WriteRegs
	ld a, $80
	ldh [rNR44], a
	ld a, [hl]
	cp $ff
	jp nz, .next
	xor a
	ld [wSfx3Playing], a
	ld a, $ff
	ld [wSfxPriority], a
	jp .done

.next:
	ld [wNoiseFrames], a
	inc hl
	ld a, h
	ld [wNoisePtr], a
	ld a, l
	ld [wNoisePtr+1], a
	jr .done

.done:
	ret

; Play every active stream (wSfxActive bits 3-0 = ch1-ch4). wSfxChannels holds the channels a
; new effect starts; while ch4 plays wSfxMode = $10 (short ch4 rows). A stream that ends gives
; its channel back to the music unless the game is paused (wPaused).
Sfx_PlayStreams:
	ld a, [wSfxActive]
	and a
	jr z, .active
	ld a, [wSfxChannels]
	ld c, a
	ld a, $01
	bit 3, c
	jr z, .ch2
	ld [wSfxFramesCh1], a
.ch2:
	bit 2, c
	jr z, .ch3
	ld [wSfxFramesCh2], a
.ch3:
	bit 1, c
	jr z, .ch4
	ld [wSfxFramesCh3], a
.ch4:
	bit 0, c
	jr z, .active
	ld [wSfxFramesCh4], a
.active:
	ld a, [wSfxChannels]
	ld hl, wSfxActive
	or [hl]
	ret z
	ld [wSfxActive], a
	bit 0, a
	jr z, .ch1
	ld a, $10
	ld [wSfxMode], a
.ch1:
	ld a, [wSfxActive]
	bit 3, a
	jr z, .ch2Play
	ld hl, wSfxFramesCh1
	dec [hl]
	jr nz, .ch2Play
	ld a, [wSfxPtrCh1]
	ld h, a
	ld a, [wSfxPtrCh1+1]
	ld l, a
	ld a, [wSfxMode]
	bit 0, a
	jr nz, .ch1NoSweep
	ld c, $10
	ld b, $05
	call WriteRegs
.ch1End:
	ld a, [hl]
	cp $ff
	jp nz, .ch1Next
	ld a, [wSfxActive]
	res 3, a
	ld [wSfxActive], a
	xor a
	ldh [rNR10], a
	ld a, [wPaused]
	cp $01
	jp z, .ch2Play
	call ReleaseCh1
	jp .ch2Play

.ch1Next:
	ld [wSfxFramesCh1], a
	inc hl
	ld a, h
	ld [wSfxPtrCh1], a
	ld a, l
	ld [wSfxPtrCh1+1], a
	jr .ch2Play

.ch1NoSweep:
	xor a
	ldh [rNR10], a
	ld c, $11
	ld b, $04
	call WriteRegs
	jr .ch1End

.ch2Play:
	ld a, [wSfxActive]
	bit 2, a
	jr z, .ch3Play
	ld hl, wSfxFramesCh2
	dec [hl]
	jr nz, .ch3Play
	ld a, [wSfxPtrCh2]
	ld h, a
	ld a, [wSfxPtrCh2+1]
	ld l, a
	ld c, $16
	ld b, $04
	call WriteRegs
	ld a, [hl]
	cp $ff
	jp nz, .ch2Next
	ld a, [wSfxActive]
	res 2, a
	ld [wSfxActive], a
	ld a, [wPaused]
	cp $01
	jp z, .ch3Play
	call ReleaseCh2
	jp .ch3Play

.ch2Next:
	ld [wSfxFramesCh2], a
	inc hl
	ld a, h
	ld [wSfxPtrCh2], a
	ld a, l
	ld [wSfxPtrCh2+1], a
	jr .ch3Play

.ch3Play:
	ld a, [wSfxActive]
	bit 1, a
	jp z, .ch4Play
	ld hl, wSfxFramesCh3
	dec [hl]
	jp nz, .ch4Play
	ld a, [wSfxPtrCh3]
	ld h, a
	ld a, [wSfxPtrCh3+1]
	ld l, a
	ld a, [hl+]
	push hl
	cp $ff
	jr z, .ch3Wave
.ch3Regs:
	pop hl
	ld a, $80
	ldh [rNR30], a
	ld c, $1b
	ld b, $04
	call WriteRegs
	ld a, [hl]
	cp $ff
	jr nz, .ch3Next
	ld a, [wSfxActive]
	res 1, a
	ld [wSfxActive], a
	ld a, [wPaused]
	cp $01
	jp z, .ch3End
	call ReleaseCh3
; ch3 stream end: restore the music's wave.
.ch3End:
	ld a, $00
	ldh [rNR30], a
	ldh [rNR31], a
	ld hl, wWaveCopy
	ld c, $30
	ld b, $10
	call WriteRegs
	jr .ch4Play

.ch3Next:
	ld [wSfxFramesCh3], a
	inc hl
	ld a, h
	ld [wSfxPtrCh3], a
	ld a, l
	ld [wSfxPtrCh3+1], a
	jr .ch4Play

; ch3 row with flag $FF: switch ch3 off, load the next 16 bytes of the wave stream.
.ch3Wave:
	ld a, $00
	ldh [rNR30], a
	xor a
	ldh [rNR31], a
	ld a, [wSfxWavePtr]
	ld h, a
	ld a, [wSfxWavePtr+1]
	ld l, a
	ld c, $30
	ld b, $10
	call WriteRegs
	ld a, h
	ld [wSfxWavePtr], a
	ld a, l
	ld [wSfxWavePtr+1], a
	jr .ch3Regs

.ch4Play:
	ld a, [wSfxActive]
	bit 0, a
	jr z, .done
	ld hl, wSfxFramesCh4
	dec [hl]
	jr nz, .done
	ld a, [wSfxPtrCh4]
	ld h, a
	ld a, [wSfxPtrCh4+1]
	ld l, a
	ld a, [wSfxMode]
	bit 4, a
	jr nz, .ch4Short
	ld c, $20
	ld b, $04
	call WriteRegs
.ch4End:
	ld a, [hl]
	cp $ff
	jp nz, .ch4Next
	ld a, [wSfxActive]
	res 0, a
	ld [wSfxActive], a
	ld a, [wPaused]
	cp $01
	jp z, .done
	call ReleaseCh4
	jp .done

.ch4Next:
	ld [wSfxFramesCh4], a
	inc hl
	ld a, h
	ld [wSfxPtrCh4], a
	ld a, l
	ld [wSfxPtrCh4+1], a
	jr .done

.ch4Short:
	xor a
	ldh [rNR41], a
	ld c, $21
	ld b, $02
	call WriteRegs
	ld a, $80
	ldh [rNR44], a
	jr .ch4End

.done:
	ld hl, wSfxActive
	ld a, [hl]
	cp $00
	ret nz
	xor a
	ld [wSfx1Playing], a
	ld [wSfxMode], a
	ld [wSfxChannels], a
	ld a, $ff
	ld [wSfxPriority], a
	ret

