; Colin McRae Rally - PCM samples played by the timer interrupt (see ColinMcRae_Home.asm)
; 4-bit unsigned, two samples per byte (high nibble first), 16-byte blocks,
; 8192 Hz (one 32-sample wave-RAM load per timer interrupt, 256 Hz in double speed).
; Each file holds the bytes from the sample start to the next sample start; the
; table rounds lengths up to whole blocks, so a sample plays into the start of the next.

SECTION "CMR PCM bank $7D", ROMX[$57AE], BANK[$7D]
Pcm00:: INCBIN "pcm/Pcm00.bin" ; 16 bytes, 1 blocks
Pcm01:: INCBIN "pcm/Pcm01.bin" ; 4434 bytes, 278 blocks (plays 14 bytes into the next sample)
Pcm02:: INCBIN "pcm/Pcm02.bin" ; 2924 bytes, 183 blocks (plays 4 bytes into the next sample)
Pcm03:: INCBIN "pcm/Pcm03.bin" ; 1600 bytes, 100 blocks

SECTION "CMR PCM bank $7E", ROMX[$4000], BANK[$7E]
Pcm04:: INCBIN "pcm/Pcm04.bin" ; 1526 bytes, 96 blocks (plays 10 bytes into the next sample)
Pcm05:: INCBIN "pcm/Pcm05.bin" ; 1796 bytes, 113 blocks (plays 12 bytes into the next sample)
Pcm06:: INCBIN "pcm/Pcm06.bin" ; 1879 bytes, 118 blocks (plays 9 bytes into the next sample)
Pcm07:: INCBIN "pcm/Pcm07.bin" ; 1440 bytes, 91 blocks (plays 16 bytes into the next sample)
Pcm08:: INCBIN "pcm/Pcm08.bin" ; 1732 bytes, 109 blocks (plays 12 bytes into the next sample)
Pcm09:: INCBIN "pcm/Pcm09.bin" ; 983 bytes, 62 blocks (plays 9 bytes into the next sample)
Pcm0A:: INCBIN "pcm/Pcm0A.bin" ; 830 bytes, 52 blocks (plays 2 bytes into the next sample)
Pcm0B:: INCBIN "pcm/Pcm0B.bin" ; 1643 bytes, 103 blocks (plays 5 bytes into the next sample)
Pcm0C:: INCBIN "pcm/Pcm0C.bin" ; 1413 bytes, 89 blocks (plays 11 bytes into the next sample)
Pcm0D:: INCBIN "pcm/Pcm0D.bin" ; 2096 bytes, 131 blocks

SECTION "CMR PCM bank $7F", ROMX[$4000], BANK[$7F]
Pcm0E:: INCBIN "pcm/Pcm0E.bin" ; 2 bytes, 1 blocks (plays 14 bytes into the next sample)
Pcm0F:: INCBIN "pcm/Pcm0F.bin" ; 2 bytes, 1 blocks (plays 14 bytes into the next sample)
Pcm10:: INCBIN "pcm/Pcm10.bin" ; 690 bytes, 44 blocks (plays 14 bytes into the next sample)
Pcm11:: INCBIN "pcm/Pcm11.bin" ; 314 bytes, 20 blocks (plays 6 bytes into the next sample)
Pcm12:: INCBIN "pcm/Pcm12.bin" ; 362 bytes, 23 blocks (plays 6 bytes into the next sample)
Pcm13:: INCBIN "pcm/Pcm13.bin" ; 723 bytes, 46 blocks (plays 13 bytes into the next sample)
Pcm14:: INCBIN "pcm/Pcm14.bin" ; 354 bytes, 23 blocks (plays 14 bytes into the next sample)
Pcm15:: INCBIN "pcm/Pcm15.bin" ; 297 bytes, 19 blocks (plays 7 bytes into the next sample)
Pcm16:: INCBIN "pcm/Pcm16.bin" ; 354 bytes, 23 blocks (plays 14 bytes into the next sample)
Pcm17:: INCBIN "pcm/Pcm17.bin" ; 179 bytes, 12 blocks (plays 13 bytes into the next sample)
Pcm18:: INCBIN "pcm/Pcm18.bin" ; 310 bytes, 20 blocks (plays 10 bytes into the next sample)
Pcm19:: INCBIN "pcm/Pcm19.bin" ; 382 bytes, 24 blocks (plays 2 bytes into the next sample)
Pcm1A:: INCBIN "pcm/Pcm1A.bin" ; 295 bytes, 19 blocks (plays 9 bytes into the next sample)
Pcm1B:: INCBIN "pcm/Pcm1B.bin" ; 1796 bytes, 113 blocks (plays 12 bytes into the next sample)
Pcm1C:: INCBIN "pcm/Pcm1C.bin" ; 2719 bytes, 170 blocks (plays 1 bytes into the next sample)
Pcm1D:: INCBIN "pcm/Pcm1D.bin" ; 3600 bytes, 226 blocks (plays 16 bytes into the next sample)
Pcm1E:: INCBIN "pcm/Pcm1E.bin" ; 3360 bytes, 210 blocks
