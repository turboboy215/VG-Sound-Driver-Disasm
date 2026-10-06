; Battle Zeque Den (SFC) - Arsys Software sound driver (revision of the Prince of Persia driver)
; Annotated SPC700 disassembly of $0480-$15E1, generated from "bzd-01.spc"
; Syntax: SPCdas-style (dp = $xx, abs = !$xxxx). See PoP_Arsys_Driver.md (section 15) for the differences.


Reset:
0480: 20        CLRP
0481: CD CF     MOV X,#CF
0483: BD        MOV SP,X
0484: E8 00     MOV A,#00
0486: 5D        MOV X,A

Reset_ClearZP:
0487: AF        MOV (X)+,A
0488: C8 E0     CMP X,#E0
048A: D0 FB     BNE Reset_ClearZP
048C: 3F FE 14  CALL !IncPort0
048F: 8F 01 CD  MOV $CD,#01
0492: E8 03     MOV A,#03
0494: 3F 26 08  CALL !SetEchoDelay
0497: A2 CF     SET1 $CF.5
0499: 8F F0 F1  MOV $F1,#F0
049C: 8F 21 FA  MOV $FA,#21                 ; T0 target $21 -> 4.125 ms fast tick (key-on delay, auto-pan, tremolo)
049F: 8F 1A FB  MOV $FB,#1A                 ; T1 target $1A -> 3.25 ms (frame + tempo)
04A2: 8F 03 F1  MOV $F1,#03                 ; start timers 0 and 1
04A5: 8F FF C2  MOV $C2,#FF
04A8: 8F 05 1F  MOV $1F,#05
04AB: 8F 00 C3  MOV $C3,#00
04AE: 8D 5D     MOV Y,#5D                   ; DIR = $2D (sample directory @ $2D00)
04B0: E8 2D     MOV A,#2D
04B2: 3F 3E 0A  CALL !WriteDSP
04B5: 3F A3 12  CALL !StopAll
04B8: 8F 00 14  MOV $14,#00                 ; SFX bank header @ $1600
04BB: 8F 16 15  MOV $15,#16
04BE: 8D 00     MOV Y,#00
04C0: E8 12     MOV A,#12
04C2: D7 14     MOV [$14]+Y,A
04C4: FC        INC Y
04C5: E8 03     MOV A,#03
04C7: D7 14     MOV [$14]+Y,A
04C9: FC        INC Y
04CA: 8F 12 C6  MOV $C6,#12
04CD: 8F 00 C7  MOV $C7,#00
04D0: E8 08     MOV A,#08

Reset_SfxSlotPtrs:
04D2: 2D        PUSH A
04D3: E4 C6     MOV A,$C6
04D5: D7 14     MOV [$14]+Y,A
04D7: FC        INC Y
04D8: E4 C7     MOV A,$C7
04DA: D7 14     MOV [$14]+Y,A
04DC: FC        INC Y
04DD: 60        CLRC
04DE: 98 60 C6  ADC $C6,#60
04E1: 98 00 C7  ADC $C7,#00
04E4: AE        POP A
04E5: 9C        DEC A
04E6: D0 EA     BNE Reset_SfxSlotPtrs

MainLoop:
04E8: FA 2E F7  MOV $F7,$2E
04EB: FA 2F F6  MOV $F6,$2F
04EE: 3F 6C 08  CALL !TimerService
04F1: 8F 00 F5  MOV $F5,#00
04F4: 78 01 F5  CMP $F5,#01
04F7: D0 EF     BNE MainLoop
04F9: E4 F4     MOV A,$F4
04FB: 3F 9E 07  CALL !IO_Ack

MainLoop_Dispatch:
04FE: 28 1F     AND A,#1F
0500: 1C        ASL A
0501: FD        MOV Y,A
0502: F6 0C 05  MOV A,!$050C+Y
0505: 2D        PUSH A
0506: F6 0B 05  MOV A,!CmdTable+Y
0509: 2D        PUSH A
050A: 6F        RET

CmdTable:
050B:  dw $063B   ; cmd $00 -> Cmd00_StopAll
050D:  dw $0641   ; cmd $01 -> Cmd01_PlaySong
050F:  dw $0662   ; cmd $02 -> Cmd02_LoadSamples
0511:  dw $0688   ; cmd $03 -> Cmd03_LoadSong
0513:  dw $0779   ; cmd $04 -> Cmd04_FadeOut
0515:  dw $0000   ; cmd $05 (null - jumps to $0000)
0517:  dw $0784   ; cmd $06 -> Cmd06_Nop
0519:  dw $0787   ; cmd $07 -> Cmd07_Nop
051B:  dw $078A   ; cmd $08 -> Cmd08_09_Nop
051D:  dw $078A   ; cmd $09 -> Cmd08_09_Nop
051F:  dw $0638   ; cmd $0A -> Cmd_Nop
0521:  dw $0638   ; cmd $0B -> Cmd_Nop
0523:  dw $06B2   ; cmd $0C -> Cmd0C_LoadSfxBank
0525:  dw $0736   ; cmd $0D -> Cmd0D_LoadAndPlaySfx
0527:  dw $0766   ; cmd $0E -> Cmd0E_StopSfx
0529:  dw $0605   ; cmd $0F -> Cmd0F_HandshakeAndJump
052B:  dw $056F   ; cmd $10 -> Cmd10_PauseMusic
052D:  dw $05BE   ; cmd $11 -> Cmd11_ResumeMusic
052F:  dw $0563   ; cmd $12 -> Cmd12_ReportStatus
0531:  dw $0552   ; cmd $13 -> Cmd13_ReadSyncCounter
0533:  dw $054B   ; cmd $14 -> Cmd14_SetMono
0535:  dw $0000   ; cmd $15 (null - jumps to $0000)
0537:  dw $0784   ; cmd $16 -> Cmd06_Nop
0539:  dw $0787   ; cmd $17 -> Cmd07_Nop
053B:  dw $078A   ; cmd $18 -> Cmd08_09_Nop
053D:  dw $078A   ; cmd $19 -> Cmd08_09_Nop
053F:  dw $0638   ; cmd $1A -> Cmd_Nop
0541:  dw $0638   ; cmd $1B -> Cmd_Nop
0543:  dw $06B2   ; cmd $1C -> Cmd0C_LoadSfxBank
0545:  dw $0736   ; cmd $1D -> Cmd0D_LoadAndPlaySfx
0547:  dw $0766   ; cmd $1E -> Cmd0E_StopSfx
0549:  dw $0605   ; cmd $1F -> Cmd0F_HandshakeAndJump

Cmd14_SetMono:
054B: 3F B2 07  CALL !IO_RecvByte
054E: C4 C3     MOV $C3,A
0550: 2F 1A     BRA Cmd_Return

Cmd13_ReadSyncCounter:
0552: E5 76 04  MOV A,!$0476
0555: 3F BE 07  CALL !IO_SendByte
0558: E5 76 04  MOV A,!$0476
055B: F0 0F     BEQ Cmd_Return
055D: 9C        DEC A
055E: C5 76 04  MOV !$0476,A
0561: 2F 09     BRA Cmd_Return

Cmd12_ReportStatus:
0563: FA 2E F7  MOV $F7,$2E
0566: FA 2F F6  MOV $F6,$2F
0569: 3F B2 07  CALL !IO_RecvByte

Cmd_Return:
056C: 5F E8 04  JMP !MainLoop

Cmd10_PauseMusic:
056F: E4 2E     MOV A,$2E
0571: F0 3F     BEQ $05B2
0573: E4 28     MOV A,$28
0575: D0 3B     BNE $05B2
0577: 3F B5 05  CALL !CalcMusicMask
057A: 48 FF     EOR A,#FF
057C: 8F 5C F2  MOV $F2,#5C
057F: C4 F3     MOV $F3,A
0581: 8F 01 28  MOV $28,#01
0584: 8F 01 1E  MOV $1E,#01
0587: 8D 00     MOV Y,#00
0589: CD 00     MOV X,#00
058B: E4 1E     MOV A,$1E
058D: 24 D6     AND A,$D6
058F: D0 0B     BNE $059C
0591: 6D        PUSH Y
0592: E8 00     MOV A,#00
0594: 3F 3E 0A  CALL !WriteDSP
0597: FC        INC Y
0598: 3F 3E 0A  CALL !WriteDSP
059B: EE        POP Y
059C: 3D        INC X
059D: DD        MOV A,Y
059E: 60        CLRC
059F: 88 10     ADC A,#10
05A1: FD        MOV Y,A
05A2: 0B 1E     ASL $1E
05A4: 90 E5     BCC $058B
05A6: E8 00     MOV A,#00
05A8: 8F 2C F2  MOV $F2,#2C
05AB: C4 F3     MOV $F3,A
05AD: 8F 3C F2  MOV $F2,#3C
05B0: C4 F3     MOV $F3,A
05B2: 5F E8 04  JMP !MainLoop

CalcMusicMask:
05B5: E4 2E     MOV A,$2E
05B7: 48 FF     EOR A,#FF
05B9: 04 2F     OR A,$2F
05BB: C4 D6     MOV $D6,A
05BD: 6F        RET

Cmd11_ResumeMusic:
05BE: E4 28     MOV A,$28
05C0: F0 F0     BEQ $05B2
05C2: 3F B5 05  CALL !CalcMusicMask
05C5: 48 FF     EOR A,#FF
05C7: 8F 5C F2  MOV $F2,#5C
05CA: C4 F3     MOV $F3,A
05CC: 8F 00 28  MOV $28,#00
05CF: 8F 01 1E  MOV $1E,#01
05D2: CD 00     MOV X,#00
05D4: E4 1E     MOV A,$1E
05D6: 24 D6     AND A,$D6
05D8: D0 03     BNE $05DD
05DA: 3F EA 05  CALL !ResumeChannel
05DD: 3D        INC X
05DE: 0B 1E     ASL $1E
05E0: 90 F2     BCC $05D4
05E2: E3 CE 02  BBS $CE.7,$05E7
05E5: 8B CE     DEC $CE
05E7: 5F E8 04  JMP !MainLoop

ResumeChannel:
05EA: F5 50 02  MOV A,!$0250+X
05ED: 1C        ASL A
05EE: 90 01     BCC $05F1
05F0: 6F        RET
05F1: F5 20 02  MOV A,!$0220+X
05F4: 28 10     AND A,#10
05F6: D0 F8     BNE $05F0
05F8: F5 C0 03  MOV A,!$03C0+X
05FB: C4 B2     MOV $B2,A
05FD: F5 B0 03  MOV A,!$03B0+X
0600: C4 B3     MOV $B3,A
0602: 5F 95 10  JMP !Note_ScheduleKeyOn

Cmd0F_HandshakeAndJump:
0605: 8F AA F4  MOV $F4,#AA
0608: 8F BB F5  MOV $F5,#BB
060B: E8 CC     MOV A,#CC
060D: 64 F4     CMP A,$F4
060F: D0 FC     BNE $060D
0611: FA F6 14  MOV $14,$F6
0614: FA F7 15  MOV $15,$F7
0617: 8D 00     MOV Y,#00
0619: C4 F4     MOV $F4,A
061B: 64 F4     CMP A,$F4
061D: F0 FC     BEQ $061B
061F: 3A 14     INCW $14                    ; NB: received bytes are not stored (pointer only advances)
0621: BC        INC A
0622: 64 F4     CMP A,$F4
0624: F0 F3     BEQ $0619
0626: E4 F4     MOV A,$F4
0628: 78 00 F5  CMP $F5,#00
062B: D0 EC     BNE $0619
062D: FA F6 14  MOV $14,$F6
0630: FA F7 15  MOV $15,$F7
0633: CD 00     MOV X,#00
0635: 1F 14 00  JMP [!$0014+X]

Cmd_Nop:
0638: 5F E8 04  JMP !MainLoop

Cmd00_StopAll:
063B: 3F A3 12  CALL !StopAll
063E: 5F E8 04  JMP !MainLoop

Cmd01_PlaySong:
0641: 8F FF F7  MOV $F7,#FF
0644: 3F B2 07  CALL !IO_RecvByte
0647: 68 00     CMP A,#00
0649: F0 08     BEQ $0653
064B: 8F 20 08  MOV $08,#20                 ; buffer B @ $2D20 (overlaps sample dir!)
064E: 8F 2D 09  MOV $09,#2D
0651: 2F 06     BRA $0659
0653: 8F 60 08  MOV $08,#60                 ; buffer A @ $1B60
0656: 8F 1B 09  MOV $09,#1B
0659: 3F 9C 12  CALL !StopMusic
065C: 3F F7 13  CALL !StartSong
065F: 5F E8 04  JMP !MainLoop

Cmd02_LoadSamples:
0662: 3F A3 12  CALL !StopAll
0665: 3F 90 07  CALL !IO_RecvWord
0668: E4 C4     MOV A,$C4
066A: 04 C5     OR A,$C5
066C: F0 17     BEQ $0685
066E: BA C4     MOVW YA,$C4
0670: 8F 00 C6  MOV $C6,#00                 ; dir -> $2D00
0673: 8F 2D C7  MOV $C7,#2D
0676: 3F CA 07  CALL !IO_RecvBlock
0679: 3F 90 07  CALL !IO_RecvWord
067C: 8F 00 C6  MOV $C6,#00                 ; BRR -> $2E00
067F: 8F 2E C7  MOV $C7,#2E
0682: 3F CA 07  CALL !IO_RecvBlock
0685: 5F E8 04  JMP !MainLoop

Cmd03_LoadSong:
0688: 3F B2 07  CALL !IO_RecvByte
068B: 68 00     CMP A,#00
068D: F0 08     BEQ $0697
068F: 8F 20 C6  MOV $C6,#20
0692: 8F 2D C7  MOV $C7,#2D
0695: 2F 06     BRA $069D
0697: 8F 60 C6  MOV $C6,#60
069A: 8F 1B C7  MOV $C7,#1B
069D: E4 2E     MOV A,$2E
069F: F0 08     BEQ $06A9
06A1: 69 09 C7  CMP $C7,$09
06A4: D0 03     BNE $06A9
06A6: 3F 9C 12  CALL !StopMusic
06A9: 3F 90 07  CALL !IO_RecvWord
06AC: 3F CA 07  CALL !IO_RecvBlock
06AF: 5F E8 04  JMP !MainLoop

Cmd0C_LoadSfxBank:
06B2: 3F B2 07  CALL !IO_RecvByte
06B5: C5 77 04  MOV !$0477,A
06B8: 68 00     CMP A,#00
06BA: D0 08     BNE $06C4
06BC: 8F 12 C6  MOV $C6,#12                 ; bank 0 SFX instruments @ $1912
06BF: 8F 19 C7  MOV $C7,#19
06C2: 2F 11     BRA $06D5
06C4: 9C        DEC A
06C5: D0 08     BNE $06CF
06C7: 8F 7D C6  MOV $C6,#7D                 ; bank 1 @ $1A7D
06CA: 8F 1A C7  MOV $C7,#1A
06CD: 2F 06     BRA $06D5
06CF: 8F 01 C6  MOV $C6,#01                 ; bank 2 @ $1B01
06D2: 8F 1B C7  MOV $C7,#1B
06D5: 3F B2 07  CALL !IO_RecvByte
06D8: 2D        PUSH A
06D9: CD 0B     MOV X,#0B
06DB: 3F B2 07  CALL !IO_RecvByte
06DE: 8D 00     MOV Y,#00
06E0: D7 C6     MOV [$C6]+Y,A
06E2: 3A C6     INCW $C6
06E4: 1D        DEC X
06E5: D0 F4     BNE $06DB
06E7: AE        POP A
06E8: 9C        DEC A
06E9: D0 ED     BNE $06D8
06EB: 3F 90 07  CALL !IO_RecvWord
06EE: E4 C4     MOV A,$C4
06F0: 04 C5     OR A,$C5
06F2: F0 91     BEQ $0685
06F4: E5 77 04  MOV A,!$0477
06F7: D0 11     BNE $070A
06F9: 8F 80 C6  MOV $C6,#80                 ; bank 0: dir $2D80 (SRCN $20+), BRR $83F0
06FC: 8F 2D C7  MOV $C7,#2D
06FF: 3F CA 07  CALL !IO_RecvBlock
0702: 8F F0 C6  MOV $C6,#F0
0705: 8F 83 C7  MOV $C7,#83
0708: 2F 23     BRA $072D
070A: 9C        DEC A
070B: D0 11     BNE $071E
070D: 8F C0 C6  MOV $C6,#C0                 ; bank 1: dir $2DC0 (SRCN $30+), BRR $A4D0
0710: 8F 2D C7  MOV $C7,#2D
0713: 3F CA 07  CALL !IO_RecvBlock
0716: 8F D0 C6  MOV $C6,#D0
0719: 8F A4 C7  MOV $C7,#A4
071C: 2F 0F     BRA $072D
071E: 8F E0 C6  MOV $C6,#E0                 ; bank 2: dir $2DE0 (SRCN $38+), BRR $CA20
0721: 8F 2D C7  MOV $C7,#2D
0724: 3F CA 07  CALL !IO_RecvBlock
0727: 8F 20 C6  MOV $C6,#20
072A: 8F CA C7  MOV $C7,#CA
072D: 3F 90 07  CALL !IO_RecvWord
0730: 3F CA 07  CALL !IO_RecvBlock
0733: 5F E8 04  JMP !MainLoop

Cmd0D_LoadAndPlaySfx:
0736: 3F B2 07  CALL !IO_RecvByte
0739: C5 77 04  MOV !$0477,A                ; flags byte -> $0477 ($20/$40 = SFX instrument bank 1/2)
073C: 3F B2 07  CALL !IO_RecvByte
073F: 28 07     AND A,#07
0741: C5 72 04  MOV !$0472,A
0744: 8D 60     MOV Y,#60
0746: CF        MUL YA
0747: 60        CLRC
0748: 88 12     ADC A,#12                   ; slot address = $1612 + n*$60
074A: C4 C6     MOV $C6,A
074C: C5 74 04  MOV !$0474,A
074F: DD        MOV A,Y
0750: 88 16     ADC A,#16
0752: C4 C7     MOV $C7,A
0754: C5 75 04  MOV !$0475,A
0757: 3F 90 07  CALL !IO_RecvWord
075A: 3F CA 07  CALL !IO_RecvBlock
075D: E5 72 04  MOV A,!$0472
0760: 3F 95 14  CALL !Sfx_Start
0763: 5F E8 04  JMP !MainLoop

Cmd0E_StopSfx:
0766: 3F B2 07  CALL !IO_RecvByte
0769: FD        MOV Y,A
076A: 60        CLRC
076B: 88 08     ADC A,#08
076D: 5D        MOV X,A
076E: F6 8D 14  MOV A,!BitTable+Y
0771: C4 1E     MOV $1E,A
0773: 3F 49 0F  CALL !Sfx_Stop
0776: 5F E8 04  JMP !MainLoop

Cmd04_FadeOut:
0779: 3F B2 07  CALL !IO_RecvByte
077C: C4 1F     MOV $1F,A
077E: 3F E9 13  CALL !StartFade
0781: 5F E8 04  JMP !MainLoop

Cmd06_Nop:
0784: 5F E8 04  JMP !MainLoop

Cmd07_Nop:
0787: 5F E8 04  JMP !MainLoop

Cmd08_09_Nop:
078A: 5F E8 04  JMP !MainLoop
078D: 5F E8 04  JMP !MainLoop

IO_RecvWord:
0790: 8F 03 F5  MOV $F5,#03
0793: 78 01 F5  CMP $F5,#01
0796: D0 FB     BNE $0793
0798: FA F6 C4  MOV $C4,$F6
079B: FA F7 C5  MOV $C5,$F7

IO_Ack:
079E: 8F 01 F5  MOV $F5,#01                 ; port1 out = 1, mirror port1 in -> port0 out until CPU sends 3
07A1: FA F5 F4  MOV $F4,$F5
07A4: 78 03 F5  CMP $F5,#03
07A7: D0 F8     BNE $07A1
07A9: 8F FF F5  MOV $F5,#FF                 ; port1 out = FF, wait CPU port1 = 0
07AC: 78 00 F5  CMP $F5,#00
07AF: D0 FB     BNE $07AC
07B1: 6F        RET

IO_RecvByte:
07B2: 8F 02 F5  MOV $F5,#02
07B5: 78 01 F5  CMP $F5,#01
07B8: D0 FB     BNE $07B5
07BA: E4 F4     MOV A,$F4
07BC: 2F E0     BRA IO_Ack

IO_SendByte:
07BE: C4 F4     MOV $F4,A
07C0: 8F 05 F5  MOV $F5,#05
07C3: 78 01 F5  CMP $F5,#01
07C6: D0 FB     BNE $07C3
07C8: 2F D4     BRA IO_Ack

IO_RecvBlock:
07CA: 8F 00 C8  MOV $C8,#00
07CD: 8F 04 F5  MOV $F5,#04
07D0: 8F 00 F4  MOV $F4,#00
07D3: E4 C8     MOV A,$C8
07D5: 28 0F     AND A,#0F
07D7: D0 03     BNE $07DC
07D9: 3F 6C 08  CALL !TimerService
07DC: 8D 40     MOV Y,#40
07DE: E4 C8     MOV A,$C8
07E0: 2E F5 04  CBNE $F5,$07E7
07E3: FE FB     DBNZ Y,$07E0
07E5: 2F F2     BRA $07D9
07E7: 8D 00     MOV Y,#00                   ; stores exactly size bytes (PoP overran to a multiple of 3)
07E9: E4 F4     MOV A,$F4
07EB: D7 C6     MOV [$C6]+Y,A
07ED: 3A C6     INCW $C6
07EF: 1A C4     DECW $C4
07F1: F0 12     BEQ $0805
07F3: E4 F6     MOV A,$F6
07F5: D7 C6     MOV [$C6]+Y,A
07F7: 3A C6     INCW $C6
07F9: 1A C4     DECW $C4
07FB: F0 08     BEQ $0805
07FD: E4 F7     MOV A,$F7
07FF: D7 C6     MOV [$C6]+Y,A
0801: 3A C6     INCW $C6
0803: 1A C4     DECW $C4
0805: FA F5 C8  MOV $C8,$F5
0808: FA C8 F5  MOV $F5,$C8
080B: E4 C4     MOV A,$C4
080D: 04 C5     OR A,$C5
080F: D0 C2     BNE $07D3
0811: 78 01 C8  CMP $C8,#01
0814: D0 08     BNE $081E
0816: 78 04 F5  CMP $F5,#04
0819: D0 FB     BNE $0816
081B: 8F 04 F5  MOV $F5,#04
081E: 78 01 F5  CMP $F5,#01
0821: D0 FB     BNE $081E
0823: 5F 9E 07  JMP !IO_Ack

SetEchoDelay:
0826: 64 CD     CMP A,$CD
0828: D0 01     BNE $082B
082A: 6F        RET
082B: 2D        PUSH A
082C: 60        CLRC
082D: 84 CD     ADC A,$CD
082F: 48 FF     EOR A,#FF
0831: 9C        DEC A
0832: 28 0F     AND A,#0F
0834: 1C        ASL A
0835: 48 FF     EOR A,#FF
0837: 9C        DEC A
0838: F3 CE 03  BBC $CE.7,$083E
083B: 60        CLRC
083C: 84 CE     ADC A,$CE
083E: C4 CE     MOV $CE,A
0840: AE        POP A
0841: C4 CD     MOV $CD,A
0843: 8D 04     MOV Y,#04
0845: F6 D7 15  MOV A,!$15D7+Y
0848: C4 F2     MOV $F2,A
084A: E8 00     MOV A,#00
084C: C4 F3     MOV $F3,A
084E: FE F5     DBNZ Y,$0845
0850: E4 CF     MOV A,$CF
0852: 08 20     OR A,#20
0854: 8D 6C     MOV Y,#6C
0856: 3F 3E 0A  CALL !WriteDSP
0859: E4 CD     MOV A,$CD
085B: 8D 7D     MOV Y,#7D
085D: 3F 3E 0A  CALL !WriteDSP
0860: 1C        ASL A
0861: 1C        ASL A
0862: 1C        ASL A
0863: 48 FF     EOR A,#FF
0865: BC        INC A
0866: 8D 6D     MOV Y,#6D
0868: 3F 3E 0A  CALL !WriteDSP
086B: 6F        RET

TimerService:
086C: E4 FD     MOV A,$FD                   ; $FD = timer0 (4.125 ms) ticks
086E: F0 03     BEQ $0873
0870: 3F A9 09  CALL !FastTick
0873: E4 FE     MOV A,$FE                   ; $FE = timer1 (3.25 ms) ticks
0875: 2D        PUSH A
0876: 60        CLRC
0877: 84 BF     ADC A,$BF
0879: C4 BF     MOV $BF,A
087B: 68 05     CMP A,#05
087D: 90 07     BCC $0886
087F: A8 05     SBC A,#05
0881: C4 BF     MOV $BF,A
0883: 3F 9E 08  CALL !FrameUpdate
0886: AE        POP A
0887: 1C        ASL A
0888: 1C        ASL A
0889: 1C        ASL A
088A: 1C        ASL A
088B: 60        CLRC
088C: 84 C1     ADC A,$C1
088E: B0 06     BCS $0896
0890: C4 C1     MOV $C1,A
0892: 64 25     CMP A,$25
0894: 90 07     BCC $089D
0896: A4 25     SBC A,$25
0898: C4 C1     MOV $C1,A
089A: 3F 16 0A  CALL !MusicTick
089D: 6F        RET

FrameUpdate:
089E: F3 CE 78  BBC $CE.7,Frame_Fade
08A1: AB CE     INC $CE
08A3: D0 74     BNE Frame_Fade
08A5: E4 2F     MOV A,$2F
08A7: 48 FF     EOR A,#FF
08A9: 24 D0     AND A,$D0
08AB: C4 B2     MOV $B2,A
08AD: E4 2F     MOV A,$2F
08AF: 24 D1     AND A,$D1
08B1: 04 B2     OR A,$B2
08B3: F0 04     BEQ $08B9
08B5: B2 CF     CLR1 $CF.5
08B7: 2F 1C     BRA Frame_EchoOn
08B9: A2 CF     SET1 $CF.5
08BB: 8F 6C F2  MOV $F2,#6C
08BE: FA CF F3  MOV $F3,$CF
08C1: 8F 2C F2  MOV $F2,#2C
08C4: 8F 00 F3  MOV $F3,#00
08C7: 8F 3C F2  MOV $F2,#3C
08CA: 8F 00 F3  MOV $F3,#00
08CD: 8F 4D F2  MOV $F2,#4D
08D0: 8F 00 F3  MOV $F3,#00
08D3: 2F 44     BRA Frame_Fade

Frame_EchoOn:
08D5: E4 CF     MOV A,$CF
08D7: 8D 6C     MOV Y,#6C
08D9: 3F 3E 0A  CALL !WriteDSP
08DC: E4 2F     MOV A,$2F
08DE: 48 FF     EOR A,#FF
08E0: 24 D0     AND A,$D0
08E2: 04 D1     OR A,$D1
08E4: 8D 4D     MOV Y,#4D
08E6: 3F 3E 0A  CALL !WriteDSP
08E9: E4 D9     MOV A,$D9
08EB: 8D 0D     MOV Y,#0D
08ED: 3F 3E 0A  CALL !WriteDSP
08F0: E4 2F     MOV A,$2F
08F2: D0 06     BNE $08FA
08F4: EB D7     MOV Y,$D7
08F6: E4 D8     MOV A,$D8
08F8: 2F 04     BRA $08FE
08FA: EB DA     MOV Y,$DA
08FC: E4 DB     MOV A,$DB
08FE: 78 00 C3  CMP $C3,#00
0901: F0 02     BEQ $0905
0903: E8 40     MOV A,#40
0905: 1C        ASL A
0906: 2D        PUSH A
0907: 6D        PUSH Y
0908: CF        MUL YA
0909: 8F 2C F2  MOV $F2,#2C
090C: CB F3     MOV $F3,Y
090E: EE        POP Y
090F: AE        POP A
0910: 48 FF     EOR A,#FF
0912: BC        INC A
0913: CF        MUL YA
0914: 8F 3C F2  MOV $F2,#3C
0917: CB F3     MOV $F3,Y

Frame_Fade:
0919: 8F 00 1D  MOV $1D,#00
091C: FA 08 12  MOV $12,$08
091F: FA 09 13  MOV $13,$09
0922: E4 1A     MOV A,$1A
0924: F0 16     BEQ Frame_MasterVol
0926: AB 1B     INC $1B
0928: 69 1B 1F  CMP $1F,$1B
092B: D0 0F     BNE Frame_MasterVol
092D: 8F 00 1B  MOV $1B,#00
0930: AB 1C     INC $1C
0932: AB 1D     INC $1D
0934: 78 0F 1C  CMP $1C,#0F
0937: D0 03     BNE Frame_MasterVol
0939: 3F A3 12  CALL !StopAll

Frame_MasterVol:
093C: E8 0F     MOV A,#0F
093E: 80        SETC
093F: A4 1C     SBC A,$1C
0941: FD        MOV Y,A
0942: F6 04 15  MOV A,!VolumeTable+Y
0945: 8D 0C     MOV Y,#0C
0947: 3F 3E 0A  CALL !WriteDSP
094A: 8D 1C     MOV Y,#1C
094C: 3F 3E 0A  CALL !WriteDSP

Frame_MusicPitchFX:
094F: E4 28     MOV A,$28
0951: D0 23     BNE Frame_SfxTracks
0953: 8F 5C F2  MOV $F2,#5C                 ; KOF = 0 once per frame
0956: 8F 00 F3  MOV $F3,#00
0959: E4 2E     MOV A,$2E
095B: 48 FF     EOR A,#FF
095D: 04 2F     OR A,$2F
095F: C4 D6     MOV $D6,A
0961: CD 00     MOV X,#00
0963: 8F 01 1E  MOV $1E,#01
0966: 8F 08 BB  MOV $BB,#08
0969: 4B D6     LSR $D6
096B: B0 03     BCS $0970
096D: 3F A7 0A  CALL !FrameFX_PortaVibrato
0970: 3D        INC X
0971: 0B 1E     ASL $1E
0973: 6E BB F3  DBNZ $BB,$0969

Frame_SfxTracks:
0976: 8F 5C F2  MOV $F2,#5C
0979: 8F 00 F3  MOV $F3,#00
097C: 8F 01 1E  MOV $1E,#01
097F: 8F 01 24  MOV $24,#01
0982: 8F 00 12  MOV $12,#00
0985: 8F 16 13  MOV $13,#16
0988: 8F 08 BB  MOV $BB,#08
098B: CD 08     MOV X,#08
098D: E4 1E     MOV A,$1E
098F: 24 2F     AND A,$2F
0991: F0 06     BEQ $0999
0993: 3F A7 0A  CALL !FrameFX_PortaVibrato
0996: 3F 65 0C  CALL !ChannelTick
0999: 3D        INC X
099A: 0B 1E     ASL $1E
099C: 6E BB EE  DBNZ $BB,$098D
099F: 8F 00 24  MOV $24,#00
09A2: FA 08 12  MOV $12,$08
09A5: FA 09 13  MOV $13,$09
09A8: 6F        RET

FastTick:
09A9: FA 08 12  MOV $12,$08
09AC: FA 09 13  MOV $13,$09
09AF: E4 28     MOV A,$28
09B1: D0 0D     BNE $09C0
09B3: E4 2F     MOV A,$2F
09B5: 48 FF     EOR A,#FF
09B7: 24 2E     AND A,$2E
09B9: C4 D6     MOV $D6,A
09BB: CD 00     MOV X,#00
09BD: 3F DB 09  CALL !FastTick_Channels
09C0: 8F 01 24  MOV $24,#01
09C3: 8F 00 12  MOV $12,#00
09C6: 8F 16 13  MOV $13,#16
09C9: FA 2F D6  MOV $D6,$2F
09CC: CD 08     MOV X,#08
09CE: 3F DB 09  CALL !FastTick_Channels
09D1: 8F 00 24  MOV $24,#00
09D4: FA 08 12  MOV $12,$08
09D7: FA 09 13  MOV $13,$09
09DA: 6F        RET

FastTick_Channels:
09DB: 8F 01 1E  MOV $1E,#01
09DE: 8F 08 BB  MOV $BB,#08
09E1: E4 1E     MOV A,$1E
09E3: 24 D6     AND A,$D6
09E5: F0 28     BEQ $0A0F
09E7: F5 20 02  MOV A,!$0220+X
09EA: 28 10     AND A,#10
09EC: D0 21     BNE $0A0F
09EE: F4 90     MOV A,$90+X                 ; $90+X = key-on delay countdown
09F0: F0 1A     BEQ $0A0C
09F2: 9B 90     DEC $90+X
09F4: D0 19     BNE $0A0F
09F6: 3F 80 11  CALL !GetInstrumentPtr
09F9: 3F A7 10  CALL !Note_SetVoiceRegs
09FC: F4 80     MOV A,$80+X                 ; $80+X = key-on pending
09FE: F0 0C     BEQ $0A0C
0A00: 8F 5C F2  MOV $F2,#5C
0A03: 8F 00 F3  MOV $F3,#00
0A06: 8F 4C F2  MOV $F2,#4C
0A09: FA 1E F3  MOV $F3,$1E
0A0C: 3F 43 0A  CALL !FastFX_AutoPanTremolo
0A0F: 3D        INC X
0A10: 0B 1E     ASL $1E
0A12: 6E BB CC  DBNZ $BB,$09E1
0A15: 6F        RET

MusicTick:
0A16: FA 08 12  MOV $12,$08
0A19: FA 09 13  MOV $13,$09
0A1C: E4 28     MOV A,$28
0A1E: D0 BA     BNE $09DA
0A20: 8F 01 1E  MOV $1E,#01
0A23: 8F 00 11  MOV $11,#00
0A26: CD 00     MOV X,#00
0A28: 8F 08 BB  MOV $BB,#08
0A2B: E4 1E     MOV A,$1E
0A2D: 24 2E     AND A,$2E
0A2F: F0 03     BEQ $0A34
0A31: 3F 65 0C  CALL !ChannelTick
0A34: 3D        INC X
0A35: 0B 1E     ASL $1E
0A37: 98 10 11  ADC $11,#10
0A3A: 6E BB EE  DBNZ $BB,$0A2B
0A3D: 6F        RET

WriteDSP:
0A3E: CB F2     MOV $F2,Y
0A40: C4 F3     MOV $F3,A
0A42: 6F        RET

FastFX_AutoPanTremolo:
0A43: F5 40 04  MOV A,!$0440+X
0A46: F0 49     BEQ $0A91
0A48: 9F        XCN A                       ; auto-pan speed as signed 4.4 fixed point per fast tick
0A49: C4 B4     MOV $B4,A
0A4B: 38 F0 B4  AND $B4,#F0
0A4E: 28 0F     AND A,#0F
0A50: 68 08     CMP A,#08
0A52: 90 02     BCC $0A56
0A54: 08 F0     OR A,#F0
0A56: C4 B5     MOV $B5,A
0A58: F5 70 02  MOV A,!$0270+X
0A5B: FD        MOV Y,A
0A5C: F5 20 04  MOV A,!$0420+X
0A5F: 7A B4     ADDW YA,$B4
0A61: C4 B4     MOV $B4,A
0A63: DD        MOV A,Y
0A64: 80        SETC
0A65: A8 40     SBC A,#40
0A67: 10 03     BPL $0A6C
0A69: 48 FF     EOR A,#FF
0A6B: BC        INC A
0A6C: 75 30 04  CMP A,!$0430+X              ; bounce only when |pan-64| > range
0A6F: F0 0D     BEQ $0A7E
0A71: 90 0B     BCC $0A7E
0A73: F5 40 04  MOV A,!$0440+X
0A76: 48 FF     EOR A,#FF
0A78: BC        INC A
0A79: D5 40 04  MOV !$0440+X,A
0A7C: 2F 09     BRA $0A87
0A7E: E4 B4     MOV A,$B4
0A80: D5 20 04  MOV !$0420+X,A
0A83: DD        MOV A,Y
0A84: D5 70 02  MOV !$0270+X,A
0A87: F5 A0 02  MOV A,!$02A0+X
0A8A: F0 17     BEQ $0AA3
0A8C: F5 B0 02  MOV A,!$02B0+X
0A8F: F0 12     BEQ $0AA3
0A91: F5 A0 02  MOV A,!$02A0+X
0A94: F0 10     BEQ $0AA6
0A96: F5 B0 02  MOV A,!$02B0+X
0A99: F0 0B     BEQ $0AA6
0A9B: F5 90 02  MOV A,!$0290+X
0A9E: C4 27     MOV $27,A
0AA0: 3F CC 0B  CALL !LFO_Step
0AA3: 5F 43 12  JMP !WriteVoiceVolume
0AA6: 6F        RET

FrameFX_PortaVibrato:
0AA7: F5 B0 03  MOV A,!$03B0+X
0AAA: FD        MOV Y,A
0AAB: F5 C0 03  MOV A,!$03C0+X
0AAE: DA B2     MOVW $B2,YA
0AB0: F5 F0 03  MOV A,!$03F0+X
0AB3: F0 44     BEQ $0AF9
0AB5: 8D 03     MOV Y,#03
0AB7: F5 40 02  MOV A,!$0240+X
0ABA: F0 0D     BEQ $0AC9
0ABC: 68 06     CMP A,#06
0ABE: 90 02     BCC $0AC2
0AC0: E8 06     MOV A,#06
0AC2: FD        MOV Y,A
0AC3: E8 03     MOV A,#03
0AC5: 1C        ASL A
0AC6: FE FD     DBNZ Y,$0AC5
0AC8: FD        MOV Y,A
0AC9: F5 F0 03  MOV A,!$03F0+X
0ACC: CF        MUL YA
0ACD: DA B0     MOVW $B0,YA
0ACF: F5 D0 03  MOV A,!$03D0+X
0AD2: FD        MOV Y,A
0AD3: F5 E0 03  MOV A,!$03E0+X
0AD6: DA B4     MOVW $B4,YA
0AD8: BA B2     MOVW YA,$B2
0ADA: 5A B4     CMPW YA,$B4
0ADC: F0 1B     BEQ $0AF9
0ADE: B0 08     BCS $0AE8
0AE0: 7A B0     ADDW YA,$B0
0AE2: 5A B4     CMPW YA,$B4
0AE4: 90 0A     BCC $0AF0
0AE6: 2F 06     BRA $0AEE
0AE8: 9A B0     SUBW YA,$B0
0AEA: 5A B4     CMPW YA,$B4
0AEC: B0 02     BCS $0AF0
0AEE: BA B4     MOVW YA,$B4
0AF0: DA B2     MOVW $B2,YA
0AF2: D5 C0 03  MOV !$03C0+X,A
0AF5: DD        MOV A,Y
0AF6: D5 B0 03  MOV !$03B0+X,A
0AF9: F4 A0     MOV A,$A0+X
0AFB: F0 0D     BEQ $0B0A
0AFD: 9B A0     DEC $A0+X
0AFF: 2F 05     BRA $0B06
0B01: F5 F0 03  MOV A,!$03F0+X
0B04: F0 04     BEQ $0B0A
0B06: E8 00     MOV A,#00
0B08: 2F 25     BRA FX_ApplyPitch
0B0A: F5 20 03  MOV A,!$0320+X
0B0D: F0 F7     BEQ $0B06
0B0F: F5 30 03  MOV A,!$0330+X
0B12: F0 F2     BEQ $0B06
0B14: 4D        PUSH X
0B15: 7D        MOV A,X
0B16: 60        CLRC
0B17: 88 80     ADC A,#80
0B19: 5D        MOV X,A
0B1A: 3F CC 0B  CALL !LFO_Step
0B1D: CE        POP X
0B1E: F5 20 03  MOV A,!$0320+X
0B21: 5C        LSR A
0B22: C4 B0     MOV $B0,A
0B24: F5 60 03  MOV A,!$0360+X
0B27: 10 03     BPL $0B2C
0B29: 48 FF     EOR A,#FF
0B2B: BC        INC A
0B2C: 80        SETC
0B2D: A4 B0     SBC A,$B0

FX_ApplyPitch:
0B2F: 8F 00 B5  MOV $B5,#00
0B32: 60        CLRC
0B33: 95 10 02  ADC A,!$0210+X
0B36: C4 B4     MOV $B4,A
0B38: 1C        ASL A
0B39: 90 02     BCC $0B3D
0B3B: 8B B5     DEC $B5
0B3D: E8 00     MOV A,#00
0B3F: C4 0E     MOV $0E,A
0B41: C4 0F     MOV $0F,A
0B43: 3F 80 11  CALL !GetInstrumentPtr
0B46: 8D 09     MOV Y,#09                   ; inst[9..10] = signed fine tune, pitch *= 1 + t/256
0B48: F7 B6     MOV A,[$B6]+Y
0B4A: 60        CLRC
0B4B: 84 B4     ADC A,$B4
0B4D: C4 B4     MOV $B4,A
0B4F: FC        INC Y
0B50: F7 B6     MOV A,[$B6]+Y
0B52: 84 B5     ADC A,$B5
0B54: C4 B5     MOV $B5,A
0B56: C4 B9     MOV $B9,A
0B58: FA B4 B8  MOV $B8,$B4
0B5B: F3 B5 08  BBC $B5.7,$0B66
0B5E: 58 FF B8  EOR $B8,#FF
0B61: 58 FF B9  EOR $B9,#FF
0B64: 3A B8     INCW $B8
0B66: E4 B8     MOV A,$B8
0B68: EB B2     MOV Y,$B2
0B6A: CF        MUL YA
0B6B: DA 0C     MOVW $0C,YA
0B6D: E4 B8     MOV A,$B8
0B6F: EB B3     MOV Y,$B3
0B71: CF        MUL YA
0B72: 7A 0D     ADDW YA,$0D
0B74: DA 0D     MOVW $0D,YA
0B76: 90 02     BCC $0B7A
0B78: AB 0F     INC $0F
0B7A: E4 B9     MOV A,$B9
0B7C: EB B2     MOV Y,$B2
0B7E: CF        MUL YA
0B7F: 7A 0D     ADDW YA,$0D
0B81: DA 0D     MOVW $0D,YA
0B83: 90 02     BCC $0B87
0B85: AB 0F     INC $0F
0B87: E4 B9     MOV A,$B9
0B89: EB B3     MOV Y,$B3
0B8B: CF        MUL YA
0B8C: 7A 0E     ADDW YA,$0E
0B8E: DA 0E     MOVW $0E,YA
0B90: E4 0F     MOV A,$0F
0B92: D0 06     BNE $0B9A
0B94: BA 0D     MOVW YA,$0D
0B96: AD 40     CMP Y,#40
0B98: 90 02     BCC $0B9C
0B9A: 8D 40     MOV Y,#40
0B9C: F3 B5 0D  BBC $B5.7,$0BAC
0B9F: DA 0C     MOVW $0C,YA
0BA1: BA B2     MOVW YA,$B2
0BA3: 9A 0C     SUBW YA,$0C
0BA5: B0 11     BCS $0BB8
0BA7: E8 00     MOV A,#00
0BA9: FD        MOV Y,A
0BAA: 2F 0C     BRA $0BB8
0BAC: 7A B2     ADDW YA,$B2
0BAE: B0 04     BCS $0BB4
0BB0: AD 40     CMP Y,#40
0BB2: 90 04     BCC $0BB8
0BB4: E8 FF     MOV A,#FF
0BB6: 8D 3F     MOV Y,#3F
0BB8: DA B2     MOVW $B2,YA
0BBA: 7D        MOV A,X
0BBB: 28 07     AND A,#07
0BBD: 9F        XCN A
0BBE: 08 02     OR A,#02
0BC0: FD        MOV Y,A
0BC1: E4 B2     MOV A,$B2
0BC3: 3F 3E 0A  CALL !WriteDSP
0BC6: FC        INC Y
0BC7: E4 B3     MOV A,$B3
0BC9: 5F 3E 0A  JMP !WriteDSP

LFO_Step:
0BCC: 23 27 58  BBS $27.1,LFO_StepSquare
0BCF: F5 10 03  MOV A,!$0310+X
0BD2: 60        CLRC
0BD3: 95 E0 02  ADC A,!$02E0+X
0BD6: D5 E0 02  MOV !$02E0+X,A
0BD9: F5 C0 02  MOV A,!$02C0+X
0BDC: 60        CLRC
0BDD: 95 D0 02  ADC A,!$02D0+X
0BE0: D5 D0 02  MOV !$02D0+X,A
0BE3: 90 11     BCC $0BF6
0BE5: F5 E0 02  MOV A,!$02E0+X
0BE8: BC        INC A
0BE9: D5 E0 02  MOV !$02E0+X,A
0BEC: F5 B0 02  MOV A,!$02B0+X
0BEF: 60        CLRC
0BF0: 95 D0 02  ADC A,!$02D0+X
0BF3: D5 D0 02  MOV !$02D0+X,A
0BF6: F5 F0 02  MOV A,!$02F0+X
0BF9: BC        INC A
0BFA: D5 F0 02  MOV !$02F0+X,A
0BFD: 75 B0 02  CMP A,!$02B0+X
0C00: D0 24     BNE $0C26
0C02: 13 27 0D  BBC $27.0,$0C12
0C05: F3 27 05  BBC $27.7,$0C0D
0C08: F5 A0 02  MOV A,!$02A0+X
0C0B: 2F 02     BRA $0C0F
0C0D: E8 00     MOV A,#00
0C0F: D5 E0 02  MOV !$02E0+X,A
0C12: F5 E0 02  MOV A,!$02E0+X
0C15: 48 FF     EOR A,#FF
0C17: BC        INC A
0C18: D5 E0 02  MOV !$02E0+X,A
0C1B: F5 00 03  MOV A,!$0300+X
0C1E: D5 D0 02  MOV !$02D0+X,A
0C21: E8 00     MOV A,#00
0C23: D5 F0 02  MOV !$02F0+X,A
0C26: 6F        RET

LFO_StepSquare:
0C27: F5 F0 02  MOV A,!$02F0+X
0C2A: BC        INC A
0C2B: D5 F0 02  MOV !$02F0+X,A
0C2E: 75 B0 02  CMP A,!$02B0+X
0C31: D0 F3     BNE $0C26
0C33: E8 00     MOV A,#00
0C35: D5 F0 02  MOV !$02F0+X,A
0C38: 03 27 10  BBS $27.0,LFO_Random
0C3B: F5 E0 02  MOV A,!$02E0+X
0C3E: D0 05     BNE $0C45
0C40: F5 A0 02  MOV A,!$02A0+X
0C43: 2F 02     BRA $0C47
0C45: E8 00     MOV A,#00
0C47: D5 E0 02  MOV !$02E0+X,A
0C4A: 6F        RET

LFO_Random:
0C4B: F5 A0 02  MOV A,!$02A0+X
0C4E: FD        MOV Y,A
0C4F: E4 2C     MOV A,$2C
0C51: 7C        ROR A
0C52: 7C        ROR A
0C53: BC        INC A
0C54: 44 2C     EOR A,$2C
0C56: C4 2C     MOV $2C,A
0C58: 60        CLRC
0C59: 84 2D     ADC A,$2D
0C5B: C4 2D     MOV $2D,A
0C5D: AB 2D     INC $2D
0C5F: CF        MUL YA
0C60: DD        MOV A,Y
0C61: D5 E0 02  MOV !$02E0+X,A
0C64: 6F        RET

ChannelTick:
0C65: 9B 30     DEC $30+X
0C67: F0 20     BEQ MML_ReadNext
0C69: F5 10 04  MOV A,!$0410+X
0C6C: F0 1A     BEQ $0C88
0C6E: 9C        DEC A
0C6F: D5 10 04  MOV !$0410+X,A
0C72: D0 14     BNE $0C88
0C74: 03 24 06  BBS $24.0,$0C7D
0C77: E4 1E     MOV A,$1E
0C79: 24 2F     AND A,$2F
0C7B: D0 0B     BNE $0C88
0C7D: F5 20 02  MOV A,!$0220+X
0C80: 08 14     OR A,#14                    ; gate key-off also marks channel as resting (bit4)
0C82: D5 20 02  MOV !$0220+X,A
0C85: 5F A1 13  JMP !KeyOffCurrent
0C88: 6F        RET

MML_ReadNext:
0C89: F4 40     MOV A,$40+X
0C8B: C4 14     MOV $14,A
0C8D: F4 50     MOV A,$50+X
0C8F: C4 15     MOV $15,A

MML_Loop:
0C91: E8 0C     MOV A,#0C
0C93: 2D        PUSH A
0C94: E8 91     MOV A,#91
0C96: 2D        PUSH A
0C97: 8D 00     MOV Y,#00
0C99: F7 14     MOV A,[$14]+Y
0C9B: 3A 14     INCW $14
0C9D: 28 7F     AND A,#7F
0C9F: D0 03     BNE $0CA4
0CA1: 5F 44 0F  JMP !MML_EndOfPhrase
0CA4: 68 21     CMP A,#21
0CA6: F0 5D     BEQ MML_Bang_Sync
0CA8: 68 20     CMP A,#20
0CAA: F0 60     BEQ MML_Nop
0CAC: 68 2A     CMP A,#2A
0CAE: F0 5C     BEQ MML_Nop
0CB0: 68 25     CMP A,#25
0CB2: D0 03     BNE $0CB7
0CB4: 5F 01 0E  JMP !MML_Percent_Comment
0CB7: C4 B2     MOV $B2,A
0CB9: 28 3E     AND A,#3E
0CBB: FD        MOV Y,A
0CBC: F6 C6 0C  MOV A,!$0CC6+Y
0CBF: 2D        PUSH A
0CC0: F6 C5 0C  MOV A,!MMLDispatchTable+Y
0CC3: 2D        PUSH A
0CC4: 6F        RET

MMLDispatchTable:
0CC5:  dw $0E0C   ; chars '@' 'A' -> MML_At_or_A
0CC7:  dw $0FE9   ; chars 'B' 'C' -> MML_Note
0CC9:  dw $0FE9   ; chars 'D' 'E' -> MML_Note
0CCB:  dw $0FE9   ; chars 'F' 'G' -> MML_Note
0CCD:  dw $0D0D   ; chars 'H' 'I' -> MML_H_I_Echo
0CCF:  dw $0D53   ; chars 'J' 'K' -> MML_J_K
0CD1:  dw $0D77   ; chars 'L' 'M' -> MML_L_M
0CD3:  dw $0E2E   ; chars 'N' 'O' -> MML_N_O
0CD5:  dw $0E6E   ; chars 'P' 'Q' -> MML_P_Q
0CD7:  dw $0EA1   ; chars 'R' 'S' -> MML_R_Rest
0CD9:  dw $0EAA   ; chars 'T' 'U' -> MML_T_Tempo
0CDB:  dw $0EB4   ; chars 'V' 'W' -> MML_V_Volume
0CDD:  dw $0D0C   ; chars 'X' 'Y' -> MML_Nop
0CDF:  dw $0EE2   ; chars 'Z' '[' -> MML_LBracket_Legato
0CE1:  dw $0EE9   ; chars '\' ']' -> MML_RBracket_EndLegato
0CE3:  dw $0EBA   ; chars '^' '_' -> MML_Caret_VolStep
0CE5:  dw $0D0C   ; chars '`' 'a' -> MML_Nop
0CE7:  dw $0ED0   ; chars 'b' 'c' -> MML_Sharp
0CE9:  dw $0DB1   ; chars 'd' 'e' -> MML_Dollar_FIR
0CEB:  dw $0EDB   ; chars 'f' 'g' -> MML_Amp_Tie
0CED:  dw $0EF2   ; chars 'h' 'i' -> MML_Paren_Detune
0CEF:  dw $0EFB   ; chars 'j' 'k' -> MML_Plus_OctUp
0CF1:  dw $0F01   ; chars 'l' 'm' -> MML_Minus_OctDown
0CF3:  dw $0D0C   ; chars 'n' 'o' -> MML_Nop
0CF5:  dw $0F0B   ; chars 'p' 'q' -> MML_Pan
0CF7:  dw $0F0B   ; chars 'r' 's' -> MML_Pan
0CF9:  dw $0F0B   ; chars 't' 'u' -> MML_Pan
0CFB:  dw $0F0B   ; chars 'v' 'w' -> MML_Pan
0CFD:  dw $0F0B   ; chars 'x' 'y' -> MML_Pan
0CFF:  dw $0F0B   ; chars 'z' '{' -> MML_Pan
0D01:  dw $0F0B   ; chars '|' '}' -> MML_Pan
0D03:  dw $0F0B   ; chars '~' -> MML_Pan

MML_Bang_Sync:
0D05: E5 76 04  MOV A,!$0476
0D08: BC        INC A
0D09: C5 76 04  MOV !$0476,A

MML_Nop:
0D0C: 6F        RET

MML_H_I_Echo:
0D0D: 3F AC 13  CALL !ReadNumber
0D10: 78 49 B2  CMP $B2,#49
0D13: F0 31     BEQ MML_I_EchoFeedback
0D15: E4 B4     MOV A,$B4
0D17: F0 1C     BEQ $0D35
0D19: EB B4     MOV Y,$B4
0D1B: F6 04 15  MOV A,!VolumeTable+Y
0D1E: 03 24 07  BBS $24.0,$0D28
0D21: C4 D7     MOV $D7,A
0D23: 09 1E D0  OR $D0,$1E
0D26: 2F 18     BRA $0D40
0D28: C4 DA     MOV $DA,A
0D2A: 09 1E D1  OR $D1,$1E
0D2D: 2F 11     BRA $0D40
0D2F: 24 D1     AND A,$D1
0D31: C4 D1     MOV $D1,A
0D33: 2F 0B     BRA $0D40
0D35: E4 1E     MOV A,$1E
0D37: 48 FF     EOR A,#FF
0D39: 03 24 F3  BBS $24.0,$0D2F
0D3C: 24 D0     AND A,$D0
0D3E: C4 D0     MOV $D0,A
0D40: E3 CE 02  BBS $CE.7,$0D45
0D43: 8B CE     DEC $CE
0D45: 6F        RET

MML_I_EchoFeedback:
0D46: 03 24 05  BBS $24.0,$0D4E
0D49: FA B4 D9  MOV $D9,$B4
0D4C: 2F F2     BRA $0D40
0D4E: FA B4 DC  MOV $DC,$B4
0D51: 2F ED     BRA $0D40

MML_J_K:
0D53: 3F AC 13  CALL !ReadNumber
0D56: 78 4B B2  CMP $B2,#4B
0D59: F0 09     BEQ $0D64
0D5B: 03 24 05  BBS $24.0,$0D63             ; J ignored in SFX
0D5E: E4 B4     MOV A,$B4
0D60: 5F 26 08  JMP !SetEchoDelay
0D63: 6F        RET
0D64: 03 24 08  BBS $24.0,$0D6F
0D67: FA B4 D8  MOV $D8,$B4
0D6A: 38 7F D8  AND $D8,#7F
0D6D: 2F D1     BRA $0D40
0D6F: FA B4 DB  MOV $DB,$B4
0D72: 38 7F DB  AND $DB,#7F
0D75: 2F C9     BRA $0D40

MML_L_M:
0D77: 3F AC 13  CALL !ReadNumber
0D7A: 78 4C B2  CMP $B2,#4C
0D7D: F0 20     BEQ MML_L_AutoPan
0D7F: E4 B4     MOV A,$B4
0D81: F0 0B     BEQ $0D8E
0D83: 03 24 04  BBS $24.0,$0D8A
0D86: 09 1E D2  OR $D2,$1E
0D89: 6F        RET
0D8A: 09 1E D3  OR $D3,$1E
0D8D: 6F        RET
0D8E: E4 1E     MOV A,$1E
0D90: 48 FF     EOR A,#FF
0D92: 03 24 05  BBS $24.0,$0D9A
0D95: 24 D2     AND A,$D2
0D97: C4 D2     MOV $D2,A
0D99: 6F        RET
0D9A: 24 D3     AND A,$D3
0D9C: C4 D3     MOV $D3,A
0D9E: 6F        RET

MML_L_AutoPan:
0D9F: F5 70 02  MOV A,!$0270+X
0DA2: 68 40     CMP A,#40
0DA4: 90 05     BCC $0DAB
0DA6: 58 FF B4  EOR $B4,#FF
0DA9: AB B4     INC $B4
0DAB: E4 B4     MOV A,$B4
0DAD: D5 40 04  MOV !$0440+X,A
0DB0: 6F        RET

MML_Dollar_FIR:
0DB1: 3F AC 13  CALL !ReadNumber
0DB4: 8D 00     MOV Y,#00
0DB6: F7 14     MOV A,[$14]+Y
0DB8: 68 2C     CMP A,#2C
0DBA: F0 28     BEQ MML_Dollar_UserFIR
0DBC: 0B B4     ASL $B4
0DBE: 0B B4     ASL $B4
0DC0: 0B B4     ASL $B4
0DC2: E8 B0     MOV A,#B0
0DC4: 60        CLRC
0DC5: 84 B4     ADC A,$B4
0DC7: C4 B4     MOV $B4,A
0DC9: E8 15     MOV A,#15
0DCB: 88 00     ADC A,#00
0DCD: C4 B5     MOV $B5,A
0DCF: 8D 00     MOV Y,#00
0DD1: E8 0F     MOV A,#0F
0DD3: 2D        PUSH A
0DD4: C4 F2     MOV $F2,A
0DD6: F7 B4     MOV A,[$B4]+Y
0DD8: FC        INC Y
0DD9: C4 F3     MOV $F3,A
0DDB: AE        POP A
0DDC: 60        CLRC
0DDD: 88 10     ADC A,#10
0DDF: 68 80     CMP A,#80
0DE1: 90 F0     BCC $0DD3
0DE3: 6F        RET

MML_Dollar_UserFIR:
0DE4: 3A 14     INCW $14
0DE6: E4 B4     MOV A,$B4
0DE8: 28 07     AND A,#07                   ; $r,v: r&7 -> UserFIR[r]; written to DSP when r=7
0DEA: 2D        PUSH A
0DEB: 3F AC 13  CALL !ReadNumber
0DEE: EE        POP Y
0DEF: E4 B4     MOV A,$B4
0DF1: D6 D0 15  MOV !UserFIR+Y,A
0DF4: AD 07     CMP Y,#07
0DF6: F0 01     BEQ $0DF9
0DF8: 6F        RET
0DF9: 8F D0 B4  MOV $B4,#D0
0DFC: 8F 15 B5  MOV $B5,#15
0DFF: 2F CE     BRA $0DCF

MML_Percent_Comment:
0E01: 8D 00     MOV Y,#00
0E03: F7 14     MOV A,[$14]+Y
0E05: 3A 14     INCW $14
0E07: 68 25     CMP A,#25
0E09: D0 F8     BNE $0E03
0E0B: 6F        RET

MML_At_or_A:
0E0C: 78 40 B2  CMP $B2,#40
0E0F: F0 03     BEQ $0E14
0E11: 5F E9 0F  JMP !MML_Note
0E14: 3F AC 13  CALL !ReadNumber
0E17: E4 B4     MOV A,$B4
0E19: 75 50 02  CMP A,!$0250+X
0E1C: F0 0C     BEQ $0E2A
0E1E: D5 50 02  MOV !$0250+X,A
0E21: 03 24 07  BBS $24.0,$0E2B
0E24: E4 2F     MOV A,$2F
0E26: 24 1E     AND A,$1E
0E28: F0 01     BEQ $0E2B
0E2A: 6F        RET
0E2B: 5F BC 11  JMP !SetInstrument

MML_N_O:
0E2E: 78 4F B2  CMP $B2,#4F
0E31: D0 09     BNE $0E3C
0E33: 3F AC 13  CALL !ReadNumber
0E36: E4 B4     MOV A,$B4
0E38: D5 40 02  MOV !$0240+X,A
0E3B: 6F        RET
0E3C: 8F FF B4  MOV $B4,#FF
0E3F: 3F AF 13  CALL !ReadNumberDefault
0E42: 78 FF B4  CMP $B4,#FF
0E45: F0 16     BEQ $0E5D
0E47: E4 B4     MOV A,$B4
0E49: 28 1F     AND A,#1F
0E4B: 38 E0 CF  AND $CF,#E0
0E4E: 04 CF     OR A,$CF
0E50: C4 CF     MOV $CF,A
0E52: 03 24 04  BBS $24.0,$0E59
0E55: 09 1E D4  OR $D4,$1E
0E58: 6F        RET
0E59: 09 1E D5  OR $D5,$1E
0E5C: 6F        RET
0E5D: E4 1E     MOV A,$1E
0E5F: 48 FF     EOR A,#FF
0E61: 03 24 05  BBS $24.0,$0E69
0E64: 24 D4     AND A,$D4
0E66: C4 D4     MOV $D4,A
0E68: 6F        RET
0E69: 24 D5     AND A,$D5
0E6B: C4 D5     MOV $D5,A
0E6D: 6F        RET

MML_P_Q:
0E6E: 3F AC 13  CALL !ReadNumber
0E71: 78 51 B2  CMP $B2,#51
0E74: D0 08     BNE $0E7E
0E76: E4 B4     MOV A,$B4
0E78: 28 0F     AND A,#0F
0E7A: D5 00 04  MOV !$0400+X,A
0E7D: 6F        RET
0E7E: F5 F0 03  MOV A,!$03F0+X
0E81: C4 B2     MOV $B2,A
0E83: E4 B4     MOV A,$B4
0E85: D5 F0 03  MOV !$03F0+X,A
0E88: E4 B2     MOV A,$B2
0E8A: D0 14     BNE $0EA0
0E8C: F5 E0 03  MOV A,!$03E0+X
0E8F: D5 C0 03  MOV !$03C0+X,A
0E92: F5 D0 03  MOV A,!$03D0+X
0E95: D5 B0 03  MOV !$03B0+X,A
0E98: F5 20 02  MOV A,!$0220+X
0E9B: 08 04     OR A,#04
0E9D: D5 20 02  MOV !$0220+X,A
0EA0: 6F        RET

MML_R_Rest:
0EA1: 8F 00 B2  MOV $B2,#00
0EA4: 8F 00 B3  MOV $B3,#00
0EA7: 5F 2E 10  JMP !Note_Common

MML_T_Tempo:
0EAA: 3F AC 13  CALL !ReadNumber
0EAD: 03 24 03  BBS $24.0,$0EB3
0EB0: FA B4 25  MOV $25,$B4
0EB3: 6F        RET

MML_V_Volume:
0EB4: 3F AC 13  CALL !ReadNumber
0EB7: 5F B6 11  JMP !SetVolume

MML_Caret_VolStep:
0EBA: F5 30 02  MOV A,!$0230+X
0EBD: 13 B2 06  BBC $B2.0,$0EC6
0EC0: 28 0F     AND A,#0F
0EC2: 9C        DEC A
0EC3: 10 06     BPL $0ECB
0EC5: 6F        RET
0EC6: BC        INC A
0EC7: 28 0F     AND A,#0F
0EC9: F0 FA     BEQ $0EC5                   ; ^ no longer wraps 15 -> 0
0ECB: C4 B4     MOV $B4,A
0ECD: 5F B6 11  JMP !SetVolume

MML_Sharp:
0ED0: 3F E2 13  CALL !ReadChar
0ED3: 60        CLRC
0ED4: 88 07     ADC A,#07
0ED6: C4 B2     MOV $B2,A
0ED8: 5F E9 0F  JMP !MML_Note

MML_Amp_Tie:
0EDB: F5 20 02  MOV A,!$0220+X
0EDE: 08 01     OR A,#01
0EE0: 2F 0C     BRA $0EEE

MML_LBracket_Legato:
0EE2: F5 20 02  MOV A,!$0220+X
0EE5: 08 06     OR A,#06
0EE7: 2F 05     BRA $0EEE

MML_RBracket_EndLegato:
0EE9: F5 20 02  MOV A,!$0220+X
0EEC: 28 FD     AND A,#FD
0EEE: D5 20 02  MOV !$0220+X,A
0EF1: 6F        RET

MML_Paren_Detune:
0EF2: 3F AC 13  CALL !ReadNumber
0EF5: E4 B4     MOV A,$B4
0EF7: D5 10 02  MOV !$0210+X,A
0EFA: 6F        RET

MML_Plus_OctUp:
0EFB: F5 40 02  MOV A,!$0240+X
0EFE: BC        INC A
0EFF: 2F 04     BRA $0F05

MML_Minus_OctDown:
0F01: F5 40 02  MOV A,!$0240+X
0F04: 9C        DEC A
0F05: 28 07     AND A,#07
0F07: D5 40 02  MOV !$0240+X,A
0F0A: 6F        RET

MML_Pan:
0F0B: E4 B2     MOV A,$B2
0F0D: 48 03     EOR A,#03
0F0F: BC        INC A
0F10: 28 03     AND A,#03
0F12: D0 01     BNE $0F15
0F14: BC        INC A
0F15: 68 03     CMP A,#03
0F17: F0 0C     BEQ $0F25
0F19: 68 01     CMP A,#01
0F1B: D0 04     BNE $0F21
0F1D: E8 7F     MOV A,#7F
0F1F: 2F 0C     BRA $0F2D
0F21: E8 00     MOV A,#00
0F23: 2F 08     BRA $0F2D
0F25: 8F 40 B4  MOV $B4,#40
0F28: 3F AF 13  CALL !ReadNumberDefault
0F2B: E4 B4     MOV A,$B4
0F2D: D5 70 02  MOV !$0270+X,A
0F30: 80        SETC
0F31: A8 40     SBC A,#40
0F33: 10 03     BPL $0F38
0F35: 48 FF     EOR A,#FF
0F37: BC        INC A
0F38: D5 30 04  MOV !$0430+X,A
0F3B: E8 00     MOV A,#00
0F3D: D5 40 04  MOV !$0440+X,A
0F40: D5 20 04  MOV !$0420+X,A
0F43: 6F        RET

MML_EndOfPhrase:
0F44: 13 24 21  BBC $24.0,Seq_PhraseRepeat
0F47: AE        POP A
0F48: AE        POP A

Sfx_Stop:
0F49: E4 1E     MOV A,$1E
0F4B: 48 FF     EOR A,#FF
0F4D: C4 B4     MOV $B4,A
0F4F: 29 B4 2F  AND $2F,$B4
0F52: 29 B4 D5  AND $D5,$B4
0F55: 29 B4 D3  AND $D3,$B4
0F58: 29 B4 D1  AND $D1,$B4
0F5B: E8 00     MOV A,#00
0F5D: D4 80     MOV $80+X,A                 ; SFX end: hand voice back to music ($80/$90 of channel n)
0F5F: D4 78     MOV $78+X,A
0F61: E8 01     MOV A,#01
0F63: D4 88     MOV $88+X,A
0F65: 5F A1 13  JMP !KeyOffCurrent

Seq_PhraseRepeat:
0F68: F5 60 02  MOV A,!$0260+X
0F6B: 9C        DEC A
0F6C: D5 60 02  MOV !$0260+X,A
0F6F: F0 0E     BEQ Seq_NextOrderEntry
0F71: F5 60 04  MOV A,!$0460+X
0F74: FD        MOV Y,A
0F75: F5 50 04  MOV A,!$0450+X
0F78: D4 40     MOV $40+X,A
0F7A: DB 50     MOV $50+X,Y
0F7C: DA 14     MOVW $14,YA
0F7E: 6F        RET

Seq_NextOrderEntry:
0F7F: F4 60     MOV A,$60+X
0F81: FB 70     MOV Y,$70+X
0F83: DA B0     MOVW $B0,YA
0F85: 8D 00     MOV Y,#00
0F87: F7 B0     MOV A,[$B0]+Y
0F89: 3A B0     INCW $B0
0F8B: C4 B4     MOV $B4,A
0F8D: F7 B0     MOV A,[$B0]+Y
0F8F: 3A B0     INCW $B0
0F91: C4 B2     MOV $B2,A
0F93: F7 B0     MOV A,[$B0]+Y
0F95: 3A B0     INCW $B0
0F97: C4 B3     MOV $B3,A
0F99: 04 B2     OR A,$B2
0F9B: F0 EA     BEQ $0F87
0F9D: E4 B4     MOV A,$B4
0F9F: D0 05     BNE $0FA6
0FA1: AE        POP A
0FA2: AE        POP A
0FA3: 5F A3 12  JMP !StopAll
0FA6: BC        INC A
0FA7: D0 18     BNE $0FC1
0FA9: AE        POP A
0FAA: AE        POP A
0FAB: E4 1E     MOV A,$1E
0FAD: 48 FF     EOR A,#FF
0FAF: 24 2E     AND A,$2E
0FB1: C4 2E     MOV $2E,A
0FB3: E4 1E     MOV A,$1E
0FB5: 24 2F     AND A,$2F
0FB7: D0 07     BNE $0FC0
0FB9: E8 00     MOV A,#00
0FBB: D4 80     MOV $80+X,A
0FBD: 5F A1 13  JMP !KeyOffCurrent
0FC0: 6F        RET
0FC1: BC        INC A
0FC2: D0 0A     BNE $0FCE
0FC4: BA 12     MOVW YA,$12
0FC6: 7A B2     ADDW YA,$B2
0FC8: 8F 01 22  MOV $22,#01
0FCB: 5F 83 0F  JMP !$0F83
0FCE: E4 B4     MOV A,$B4
0FD0: D5 60 02  MOV !$0260+X,A
0FD3: BA B0     MOVW YA,$B0
0FD5: D4 60     MOV $60+X,A
0FD7: DB 70     MOV $70+X,Y
0FD9: BA B2     MOVW YA,$B2
0FDB: 7A 12     ADDW YA,$12
0FDD: D5 50 04  MOV !$0450+X,A
0FE0: 2D        PUSH A
0FE1: DD        MOV A,Y
0FE2: D5 60 04  MOV !$0460+X,A
0FE5: AE        POP A
0FE6: 5F 78 0F  JMP !$0F78

MML_Note:
0FE9: 80        SETC
0FEA: B8 41 B2  SBC $B2,#41
0FED: 0B B2     ASL $B2
0FEF: EB B2     MOV Y,$B2
0FF1: F6 14 15  MOV A,!NotePitchTable+Y
0FF4: C4 B2     MOV $B2,A
0FF6: F6 15 15  MOV A,!$1515+Y
0FF9: C4 B3     MOV $B3,A
0FFB: E8 06     MOV A,#06
0FFD: 80        SETC
0FFE: B5 40 02  SBC A,!$0240+X
1001: 30 09     BMI $100C
1003: F0 07     BEQ $100C
1005: FD        MOV Y,A
1006: 4B B3     LSR $B3
1008: 6B B2     ROR $B2
100A: FE FA     DBNZ Y,$1006
100C: BA B2     MOVW YA,$B2
100E: AD 40     CMP Y,#40
1010: 90 06     BCC $1018
1012: E8 FF     MOV A,#FF
1014: 8D 3F     MOV Y,#3F
1016: DA B2     MOVW $B2,YA
1018: D5 E0 03  MOV !$03E0+X,A
101B: DD        MOV A,Y
101C: D5 D0 03  MOV !$03D0+X,A
101F: F5 F0 03  MOV A,!$03F0+X
1022: D0 0A     BNE Note_Common
1024: F5 E0 03  MOV A,!$03E0+X
1027: D5 C0 03  MOV !$03C0+X,A
102A: DD        MOV A,Y
102B: D5 B0 03  MOV !$03B0+X,A

Note_Common:
102E: AE        POP A
102F: AE        POP A
1030: E8 00     MOV A,#00                   ; clear key-on pending
1032: D4 80     MOV $80+X,A
1034: 3F 44 11  CALL !ReadLength
1037: F5 20 02  MOV A,!$0220+X
103A: C4 27     MOV $27,A
103C: 28 EA     AND A,#EA
103E: D5 20 02  MOV !$0220+X,A
1041: 03 27 08  BBS $27.0,$104C
1044: F5 F0 03  MOV A,!$03F0+X
1047: D0 03     BNE $104C
1049: 3F F8 10  CALL !Note_ResetLFOPhase
104C: E4 B2     MOV A,$B2
104E: 04 B3     OR A,$B3
1050: D0 15     BNE $1067
1052: F5 20 02  MOV A,!$0220+X
1055: 08 14     OR A,#14
1057: D5 20 02  MOV !$0220+X,A
105A: 03 24 06  BBS $24.0,$1063
105D: E4 1E     MOV A,$1E
105F: 24 2F     AND A,$2F
1061: D0 03     BNE $1066
1063: 5F A1 13  JMP !KeyOffCurrent
1066: 6F        RET
1067: 03 24 06  BBS $24.0,$1070
106A: E4 1E     MOV A,$1E
106C: 24 2F     AND A,$2F
106E: D0 F6     BNE $1066
1070: F5 C0 03  MOV A,!$03C0+X
1073: C4 B2     MOV $B2,A
1075: F5 B0 03  MOV A,!$03B0+X
1078: C4 B3     MOV $B3,A
107A: 43 27 08  BBS $27.2,$1085
107D: E4 27     MOV A,$27
107F: 28 03     AND A,#03
1081: 68 03     CMP A,#03
1083: F0 1B     BEQ $10A0
1085: F5 80 02  MOV A,!$0280+X
1088: D4 A0     MOV $A0+X,A
108A: 43 27 08  BBS $27.2,Note_ScheduleKeyOn
108D: 03 27 10  BBS $27.0,$10A0
1090: F5 F0 03  MOV A,!$03F0+X
1093: D0 0B     BNE $10A0

Note_ScheduleKeyOn:
1095: E8 01     MOV A,#01                   ; key-on deferred 3 fast ticks (~8-12 ms) after KOF
1097: D4 80     MOV $80+X,A
1099: 3F A1 13  CALL !KeyOffCurrent
109C: E8 03     MOV A,#03
109E: D4 90     MOV $90+X,A
10A0: 3F 2F 0B  CALL !FX_ApplyPitch
10A3: F4 90     MOV A,$90+X
10A5: D0 BF     BNE $1066

Note_SetVoiceRegs:
10A7: 3F 43 12  CALL !WriteVoiceVolume
10AA: E4 2F     MOV A,$2F
10AC: 48 FF     EOR A,#FF
10AE: C4 B4     MOV $B4,A
10B0: 24 D2     AND A,$D2
10B2: C4 B5     MOV $B5,A
10B4: E4 D3     MOV A,$D3
10B6: 24 2F     AND A,$2F
10B8: 04 B5     OR A,$B5
10BA: 8F 2D F2  MOV $F2,#2D
10BD: C4 F3     MOV $F3,A
10BF: E4 B4     MOV A,$B4
10C1: 24 D4     AND A,$D4
10C3: C4 B5     MOV $B5,A
10C5: E4 D5     MOV A,$D5
10C7: 24 2F     AND A,$2F
10C9: 04 B5     OR A,$B5
10CB: 8F 3D F2  MOV $F2,#3D
10CE: C4 F3     MOV $F3,A
10D0: 7D        MOV A,X
10D1: 28 07     AND A,#07
10D3: 9F        XCN A
10D4: 08 04     OR A,#04
10D6: C4 B8     MOV $B8,A
10D8: 8D 00     MOV Y,#00
10DA: F7 B6     MOV A,[$B6]+Y
10DC: FC        INC Y
10DD: 3F F0 10  CALL !WriteDSP_Inc
10E0: F7 B6     MOV A,[$B6]+Y
10E2: FC        INC Y
10E3: 08 80     OR A,#80
10E5: 3F F0 10  CALL !WriteDSP_Inc
10E8: F7 B6     MOV A,[$B6]+Y
10EA: FC        INC Y
10EB: 3F F0 10  CALL !WriteDSP_Inc
10EE: E8 00     MOV A,#00

WriteDSP_Inc:
10F0: FA B8 F2  MOV $F2,$B8
10F3: C4 F3     MOV $F3,A
10F5: AB B8     INC $B8
10F7: 6F        RET

Note_ResetLFOPhase:
10F8: 8D 00     MOV Y,#00
10FA: F5 90 02  MOV A,!$0290+X
10FD: 28 80     AND A,#80
10FF: F0 0F     BEQ $1110
1101: F5 90 02  MOV A,!$0290+X
1104: 28 03     AND A,#03
1106: 68 02     CMP A,#02
1108: B0 01     BCS $110B
110A: FC        INC Y
110B: 68 03     CMP A,#03
110D: F0 01     BEQ $1110
110F: FC        INC Y
1110: DD        MOV A,Y
1111: F0 0A     BEQ $111D
1113: F5 A0 02  MOV A,!$02A0+X
1116: DC        DEC Y
1117: F0 04     BEQ $111D
1119: 48 FF     EOR A,#FF
111B: BC        INC A
111C: FC        INC Y
111D: D5 E0 02  MOV !$02E0+X,A
1120: DD        MOV A,Y
1121: F0 09     BEQ $112C
1123: F5 20 03  MOV A,!$0320+X
1126: DC        DEC Y
1127: F0 03     BEQ $112C
1129: 48 FF     EOR A,#FF
112B: BC        INC A
112C: D5 60 03  MOV !$0360+X,A
112F: E8 00     MOV A,#00
1131: D5 F0 02  MOV !$02F0+X,A
1134: D5 70 03  MOV !$0370+X,A
1137: F5 00 03  MOV A,!$0300+X
113A: D5 D0 02  MOV !$02D0+X,A
113D: F5 80 03  MOV A,!$0380+X
1140: D5 50 03  MOV !$0350+X,A
1143: 6F        RET

ReadLength:
1144: F5 00 02  MOV A,!$0200+X
1147: C4 B4     MOV $B4,A
1149: 3F AF 13  CALL !ReadNumberDefault
114C: E4 14     MOV A,$14
114E: D4 40     MOV $40+X,A
1150: E4 15     MOV A,$15
1152: D4 50     MOV $50+X,A
1154: E4 B4     MOV A,$B4
1156: D5 00 02  MOV !$0200+X,A
1159: D0 01     BNE $115C
115B: BC        INC A
115C: D4 30     MOV $30+X,A
115E: FD        MOV Y,A
115F: F5 00 04  MOV A,!$0400+X
1162: F0 18     BEQ $117C
1164: CF        MUL YA
1165: DA B6     MOVW $B6,YA
1167: 4B B7     LSR $B7
1169: 6B B6     ROR $B6
116B: 4B B7     LSR $B7
116D: 6B B6     ROR $B6
116F: 4B B7     LSR $B7
1171: 6B B6     ROR $B6
1173: 4B B7     LSR $B7
1175: 6B B6     ROR $B6
1177: E4 B6     MOV A,$B6
1179: D0 01     BNE $117C
117B: BC        INC A
117C: D5 10 04  MOV !$0410+X,A
117F: 6F        RET

GetInstrumentPtr:
1180: 13 24 1B  BBC $24.0,$119E
1183: F5 20 02  MOV A,!$0220+X
1186: 28 60     AND A,#60                   ; SFX flags bit5/bit6 select SFX instrument bank 1/2
1188: F0 14     BEQ $119E
118A: 28 20     AND A,#20
118C: F0 08     BEQ $1196
118E: 8F 7D B6  MOV $B6,#7D
1191: 8F 04 B7  MOV $B7,#04
1194: 2F 13     BRA $11A9
1196: 8F 01 B6  MOV $B6,#01
1199: 8F 05 B7  MOV $B7,#05
119C: 2F 0B     BRA $11A9
119E: 8D 00     MOV Y,#00
11A0: F7 12     MOV A,[$12]+Y
11A2: C4 B6     MOV $B6,A
11A4: FC        INC Y
11A5: F7 12     MOV A,[$12]+Y
11A7: C4 B7     MOV $B7,A
11A9: 8D 0B     MOV Y,#0B
11AB: F5 50 02  MOV A,!$0250+X
11AE: CF        MUL YA
11AF: 7A B6     ADDW YA,$B6
11B1: 7A 12     ADDW YA,$12
11B3: DA B6     MOVW $B6,YA
11B5: 6F        RET

SetVolume:
11B6: E4 B4     MOV A,$B4
11B8: D5 30 02  MOV !$0230+X,A
11BB: 6F        RET

SetInstrument:
11BC: 3F 80 11  CALL !GetInstrumentPtr
11BF: E8 00     MOV A,#00
11C1: D5 10 03  MOV !$0310+X,A
11C4: D5 F0 02  MOV !$02F0+X,A
11C7: D5 E0 02  MOV !$02E0+X,A
11CA: D5 C0 02  MOV !$02C0+X,A
11CD: D5 90 03  MOV !$0390+X,A
11D0: D5 70 03  MOV !$0370+X,A
11D3: D5 60 03  MOV !$0360+X,A
11D6: D5 40 03  MOV !$0340+X,A
11D9: 8D 03     MOV Y,#03
11DB: F7 B6     MOV A,[$B6]+Y
11DD: FC        INC Y
11DE: D5 A0 02  MOV !$02A0+X,A
11E1: C4 B9     MOV $B9,A
11E3: F7 B6     MOV A,[$B6]+Y
11E5: 1C        ASL A                       ; tremolo period *4 (runs at fast-tick rate)
11E6: D5 D0 02  MOV !$02D0+X,A
11E9: D5 00 03  MOV !$0300+X,A
11EC: 1C        ASL A
11ED: D5 B0 02  MOV !$02B0+X,A
11F0: C4 BA     MOV $BA,A
11F2: F0 12     BEQ $1206
11F4: E4 B9     MOV A,$B9
11F6: F0 0E     BEQ $1206
11F8: 4D        PUSH X
11F9: 8D 00     MOV Y,#00
11FB: F8 BA     MOV X,$BA
11FD: 9E        DIV YA,X
11FE: CE        POP X
11FF: D5 10 03  MOV !$0310+X,A
1202: DD        MOV A,Y
1203: D5 C0 02  MOV !$02C0+X,A
1206: 8D 05     MOV Y,#05
1208: F7 B6     MOV A,[$B6]+Y
120A: FC        INC Y
120B: 5C        LSR A                       ; vibrato depth halved vs PoP
120C: D5 20 03  MOV !$0320+X,A
120F: C4 B9     MOV $B9,A
1211: F7 B6     MOV A,[$B6]+Y
1213: D5 30 03  MOV !$0330+X,A
1216: C4 BA     MOV $BA,A
1218: 5C        LSR A
1219: D5 50 03  MOV !$0350+X,A
121C: D5 80 03  MOV !$0380+X,A
121F: E4 BA     MOV A,$BA
1221: F0 12     BEQ $1235
1223: E4 B9     MOV A,$B9
1225: F0 0E     BEQ $1235
1227: 4D        PUSH X
1228: 8D 00     MOV Y,#00
122A: F8 BA     MOV X,$BA
122C: 9E        DIV YA,X
122D: CE        POP X
122E: D5 90 03  MOV !$0390+X,A
1231: DD        MOV A,Y
1232: D5 40 03  MOV !$0340+X,A
1235: 8D 07     MOV Y,#07
1237: F7 B6     MOV A,[$B6]+Y
1239: D5 90 02  MOV !$0290+X,A
123C: FC        INC Y
123D: F7 B6     MOV A,[$B6]+Y
123F: D5 80 02  MOV !$0280+X,A
1242: 6F        RET

WriteVoiceVolume:
1243: 7D        MOV A,X
1244: 28 07     AND A,#07
1246: 9F        XCN A
1247: C4 B8     MOV $B8,A
1249: F5 30 02  MOV A,!$0230+X
124C: FD        MOV Y,A
124D: F6 04 15  MOV A,!VolumeTable+Y
1250: C4 B9     MOV $B9,A
1252: F5 E0 02  MOV A,!$02E0+X
1255: 10 03     BPL $125A
1257: 48 FF     EOR A,#FF
1259: BC        INC A
125A: 60        CLRC
125B: 84 B9     ADC A,$B9
125D: 90 02     BCC $1261
125F: E8 FF     MOV A,#FF
1261: C4 B9     MOV $B9,A
1263: F5 70 02  MOV A,!$0270+X
1266: 78 00 C3  CMP $C3,#00
1269: F0 02     BEQ $126D
126B: E8 40     MOV A,#40
126D: FD        MOV Y,A
126E: F6 30 15  MOV A,!PanSineTable+Y
1271: EB B9     MOV Y,$B9
1273: CF        MUL YA
1274: DD        MOV A,Y
1275: 68 7F     CMP A,#7F                   ; clamp each side to $7F (PoP could overflow)
1277: 90 02     BCC $127B
1279: E8 7F     MOV A,#7F
127B: 3F F0 10  CALL !WriteDSP_Inc
127E: E8 7F     MOV A,#7F
1280: 80        SETC
1281: B5 70 02  SBC A,!$0270+X
1284: 78 00 C3  CMP $C3,#00
1287: F0 02     BEQ $128B
1289: E8 40     MOV A,#40
128B: FD        MOV Y,A
128C: F6 30 15  MOV A,!PanSineTable+Y
128F: EB B9     MOV Y,$B9
1291: CF        MUL YA
1292: DD        MOV A,Y
1293: 68 7F     CMP A,#7F
1295: 90 02     BCC $1299
1297: E8 7F     MOV A,#7F
1299: 5F F0 10  JMP !WriteDSP_Inc

StopMusic:
129C: CD 00     MOV X,#00
129E: 8D 08     MOV Y,#08
12A0: 5F B8 12  JMP !ResetChannels

StopAll:
12A3: E8 00     MOV A,#00
12A5: C4 DA     MOV $DA,A
12A7: C4 DC     MOV $DC,A
12A9: C4 2F     MOV $2F,A
12AB: C4 D1     MOV $D1,A
12AD: C4 D5     MOV $D5,A
12AF: C4 D3     MOV $D3,A
12B1: 8F 40 DB  MOV $DB,#40
12B4: CD 00     MOV X,#00
12B6: 8D 10     MOV Y,#10

ResetChannels:
12B8: E8 01     MOV A,#01
12BA: D4 30     MOV $30+X,A
12BC: 9C        DEC A
12BD: D4 40     MOV $40+X,A
12BF: D4 50     MOV $50+X,A
12C1: D4 60     MOV $60+X,A
12C3: D4 70     MOV $70+X,A
12C5: D4 A0     MOV $A0+X,A
12C7: D4 80     MOV $80+X,A
12C9: D4 90     MOV $90+X,A
12CB: D5 40 04  MOV !$0440+X,A
12CE: D5 30 04  MOV !$0430+X,A
12D1: D5 20 04  MOV !$0420+X,A
12D4: D5 50 04  MOV !$0450+X,A
12D7: D5 60 04  MOV !$0460+X,A
12DA: D5 10 02  MOV !$0210+X,A
12DD: D5 20 02  MOV !$0220+X,A
12E0: D5 60 02  MOV !$0260+X,A
12E3: D5 80 02  MOV !$0280+X,A
12E6: D5 10 04  MOV !$0410+X,A
12E9: D5 00 04  MOV !$0400+X,A
12EC: D5 E0 03  MOV !$03E0+X,A
12EF: D5 D0 03  MOV !$03D0+X,A
12F2: D5 C0 03  MOV !$03C0+X,A
12F5: D5 B0 03  MOV !$03B0+X,A
12F8: D5 F0 03  MOV !$03F0+X,A
12FB: D5 A0 03  MOV !$03A0+X,A
12FE: D5 90 02  MOV !$0290+X,A
1301: D5 A0 02  MOV !$02A0+X,A
1304: D5 B0 02  MOV !$02B0+X,A
1307: D5 C0 02  MOV !$02C0+X,A
130A: D5 D0 02  MOV !$02D0+X,A
130D: D5 E0 02  MOV !$02E0+X,A
1310: D5 F0 02  MOV !$02F0+X,A
1313: D5 00 03  MOV !$0300+X,A
1316: D5 10 03  MOV !$0310+X,A
1319: D5 20 03  MOV !$0320+X,A
131C: D5 30 03  MOV !$0330+X,A
131F: D5 40 03  MOV !$0340+X,A
1322: D5 50 03  MOV !$0350+X,A
1325: D5 60 03  MOV !$0360+X,A
1328: D5 70 03  MOV !$0370+X,A
132B: D5 80 03  MOV !$0380+X,A
132E: D5 90 03  MOV !$0390+X,A
1331: E8 10     MOV A,#10
1333: D5 00 02  MOV !$0200+X,A
1336: E8 40     MOV A,#40
1338: D5 70 02  MOV !$0270+X,A
133B: E8 0D     MOV A,#0D
133D: D5 30 02  MOV !$0230+X,A
1340: E8 04     MOV A,#04
1342: D5 40 02  MOV !$0240+X,A
1345: E8 80     MOV A,#80
1347: D5 50 02  MOV !$0250+X,A
134A: 3D        INC X
134B: DC        DEC Y
134C: F0 03     BEQ $1351
134E: 5F B8 12  JMP !ResetChannels
1351: 8F 40 D8  MOV $D8,#40
1354: E3 CE 02  BBS $CE.7,$1359
1357: 8B CE     DEC $CE
1359: E8 00     MOV A,#00
135B: C4 28     MOV $28,A
135D: C4 D7     MOV $D7,A
135F: C4 D9     MOV $D9,A
1361: C4 17     MOV $17,A
1363: C4 2E     MOV $2E,A
1365: C4 D0     MOV $D0,A
1367: C4 D4     MOV $D4,A
1369: C4 D2     MOV $D2,A
136B: C4 1A     MOV $1A,A
136D: C4 1B     MOV $1B,A
136F: C4 1C     MOV $1C,A
1371: C4 C0     MOV $C0,A
1373: C5 76 04  MOV !$0476,A
1376: E4 2F     MOV A,$2F
1378: 48 FF     EOR A,#FF
137A: 8D 5C     MOV Y,#5C
137C: 3F 3E 0A  CALL !WriteDSP
137F: E8 08     MOV A,#08
1381: 8D 00     MOV Y,#00
1383: 8F 01 1E  MOV $1E,#01
1386: 2D        PUSH A
1387: E4 2F     MOV A,$2F
1389: 24 1E     AND A,$1E
138B: D0 08     BNE $1395
138D: 3F 3E 0A  CALL !WriteDSP
1390: FC        INC Y
1391: 3F 3E 0A  CALL !WriteDSP
1394: DC        DEC Y
1395: DD        MOV A,Y
1396: 60        CLRC
1397: 88 10     ADC A,#10
1399: FD        MOV Y,A
139A: 0B 1E     ASL $1E
139C: AE        POP A
139D: 9C        DEC A
139E: D0 E6     BNE $1386
13A0: 6F        RET

KeyOffCurrent:
13A1: 8F 5C F2  MOV $F2,#5C
13A4: FA 1E F3  MOV $F3,$1E
13A7: E8 00     MOV A,#00
13A9: D4 90     MOV $90+X,A
13AB: 6F        RET

ReadNumber:
13AC: 8F 00 B4  MOV $B4,#00

ReadNumberDefault:
13AF: 8D 00     MOV Y,#00
13B1: F7 14     MOV A,[$14]+Y
13B3: 68 30     CMP A,#30
13B5: 90 2A     BCC $13E1
13B7: 68 3A     CMP A,#3A
13B9: B0 26     BCS $13E1
13BB: CB B4     MOV $B4,Y
13BD: 2F 0C     BRA $13CB
13BF: 8D 00     MOV Y,#00
13C1: F7 14     MOV A,[$14]+Y
13C3: 68 30     CMP A,#30
13C5: 90 1A     BCC $13E1
13C7: 68 3A     CMP A,#3A
13C9: B0 16     BCS $13E1
13CB: 3A 14     INCW $14
13CD: 80        SETC
13CE: A8 30     SBC A,#30
13D0: 2D        PUSH A
13D1: E4 B4     MOV A,$B4
13D3: 1C        ASL A
13D4: 1C        ASL A
13D5: 84 B4     ADC A,$B4
13D7: 1C        ASL A
13D8: C4 B4     MOV $B4,A
13DA: AE        POP A
13DB: 84 B4     ADC A,$B4
13DD: C4 B4     MOV $B4,A
13DF: 2F DE     BRA $13BF
13E1: 6F        RET

ReadChar:
13E2: 8D 00     MOV Y,#00
13E4: F7 14     MOV A,[$14]+Y
13E6: 3A 14     INCW $14
13E8: 6F        RET

StartFade:
13E9: E4 1A     MOV A,$1A
13EB: D0 09     BNE $13F6
13ED: 8F 00 1B  MOV $1B,#00
13F0: 8F 00 1C  MOV $1C,#00
13F3: 8F FF 1A  MOV $1A,#FF
13F6: 6F        RET

StartSong:
13F7: E8 00     MOV A,#00
13F9: C4 28     MOV $28,A
13FB: FA 08 B0  MOV $B0,$08
13FE: FA 09 B1  MOV $B1,$09
1401: FA B0 12  MOV $12,$B0
1404: FA B1 13  MOV $13,$B1
1407: E8 02     MOV A,#02
1409: 8D 00     MOV Y,#00
140B: 7A B0     ADDW YA,$B0
140D: DA B2     MOVW $B2,YA
140F: 8D 00     MOV Y,#00
1411: F7 B2     MOV A,[$B2]+Y
1413: 3A B2     INCW $B2
1415: C4 2E     MOV $2E,A
1417: 8F 01 1E  MOV $1E,#01
141A: CD 00     MOV X,#00
141C: 8F 08 BB  MOV $BB,#08
141F: 3F 35 14  CALL !StartSong_Channel
1422: 0B 1E     ASL $1E
1424: 3D        INC X
1425: 6E BB F7  DBNZ $BB,$141F
1428: E8 7F     MOV A,#7F
142A: 8D 0C     MOV Y,#0C
142C: 3F 3E 0A  CALL !WriteDSP
142F: 8D 1C     MOV Y,#1C
1431: 3F 3E 0A  CALL !WriteDSP
1434: 6F        RET

StartSong_Channel:
1435: E4 1E     MOV A,$1E
1437: 24 2E     AND A,$2E
1439: F0 4D     BEQ $1488
143B: 8D 00     MOV Y,#00
143D: F7 B2     MOV A,[$B2]+Y
143F: C4 B4     MOV $B4,A
1441: FC        INC Y
1442: F7 B2     MOV A,[$B2]+Y
1444: C4 B5     MOV $B5,A
1446: BA B0     MOVW YA,$B0
1448: 7A B4     ADDW YA,$B4
144A: DA B4     MOVW $B4,YA
144C: 8D 00     MOV Y,#00
144E: F7 B4     MOV A,[$B4]+Y
1450: F0 2E     BEQ $1480
1452: BC        INC A
1453: F0 2B     BEQ $1480
1455: 9C        DEC A
1456: D5 60 02  MOV !$0260+X,A
1459: 3A B4     INCW $B4
145B: F7 B4     MOV A,[$B4]+Y
145D: C4 B6     MOV $B6,A
145F: 3A B4     INCW $B4
1461: F7 B4     MOV A,[$B4]+Y
1463: C4 B7     MOV $B7,A
1465: 3A B4     INCW $B4
1467: E4 B4     MOV A,$B4
1469: D4 60     MOV $60+X,A
146B: E4 B5     MOV A,$B5
146D: D4 70     MOV $70+X,A
146F: BA B6     MOVW YA,$B6
1471: 7A B0     ADDW YA,$B0
1473: D5 50 04  MOV !$0450+X,A
1476: D4 40     MOV $40+X,A
1478: DD        MOV A,Y
1479: D5 60 04  MOV !$0460+X,A
147C: D4 50     MOV $50+X,A
147E: 2F 08     BRA $1488
1480: E4 1E     MOV A,$1E
1482: 48 FF     EOR A,#FF
1484: 24 2E     AND A,$2E
1486: C4 2E     MOV $2E,A
1488: 3A B2     INCW $B2
148A: 3A B2     INCW $B2
148C: 6F        RET

BitTable:
148D:  db $01,$02,$04,$08,$10,$20,$40,$80

Sfx_Start:
1495: FD        MOV Y,A
1496: 60        CLRC
1497: 88 08     ADC A,#08
1499: 5D        MOV X,A
149A: F6 8D 14  MOV A,!BitTable+Y
149D: C4 1E     MOV $1E,A
149F: 09 1E 2F  OR $2F,$1E
14A2: E5 74 04  MOV A,!$0474
14A5: D4 40     MOV $40+X,A
14A7: E5 75 04  MOV A,!$0475
14AA: D4 50     MOV $50+X,A
14AC: E8 01     MOV A,#01
14AE: D4 30     MOV $30+X,A
14B0: E8 20     MOV A,#20
14B2: D5 00 02  MOV !$0200+X,A
14B5: E8 0D     MOV A,#0D
14B7: D5 30 02  MOV !$0230+X,A
14BA: E8 04     MOV A,#04
14BC: D5 40 02  MOV !$0240+X,A
14BF: E8 40     MOV A,#40
14C1: D5 70 02  MOV !$0270+X,A
14C4: E5 77 04  MOV A,!$0477
14C7: D5 20 02  MOV !$0220+X,A
14CA: E8 00     MOV A,#00
14CC: D5 10 02  MOV !$0210+X,A
14CF: D4 A0     MOV $A0+X,A
14D1: D4 90     MOV $90+X,A
14D3: BC        INC A
14D4: D4 80     MOV $80+X,A
14D6: E8 80     MOV A,#80
14D8: D5 50 02  MOV !$0250+X,A
14DB: D8 B0     MOV $B0,X
14DD: 8F 00 B1  MOV $B1,#00
14E0: 60        CLRC
14E1: 98 90 B0  ADC $B0,#90
14E4: 98 02 B1  ADC $B1,#02
14E7: E8 1C     MOV A,#1C
14E9: 8D 00     MOV Y,#00
14EB: 2D        PUSH A
14EC: E8 00     MOV A,#00
14EE: D7 B0     MOV [$B0]+Y,A
14F0: 60        CLRC
14F1: 98 10 B0  ADC $B0,#10
14F4: 98 00 B1  ADC $B1,#00
14F7: AE        POP A
14F8: 9C        DEC A
14F9: D0 F0     BNE $14EB
14FB: 5F A1 13  JMP !KeyOffCurrent

IncPort0:
14FE: E4 F4     MOV A,$F4
1500: BC        INC A
1501: C4 F4     MOV $F4,A
1503: 6F        RET

VolumeTable:
1504:  db $00,$03,$07,$0B,$0F,$13,$18,$1E,$24,$2B,$34,$3E,$4C,$60,$78,$7F

NotePitchTable:
1514:  dw $4000   ;
1516:  dw $47D0   ;
1518:  dw $2600   ;
151A:  dw $2AB0   ;
151C:  dw $2FF0   ;
151E:  dw $32C0   ;
1520:  dw $3900   ;
1522:  dw $43D0   ;
1524:  dw $47D0   ;
1526:  dw $2850   ;
1528:  dw $2D40   ;
152A:  dw $32C0   ;
152C:  dw $35C8   ;
152E:  dw $3C60   ;

PanSineTable:
1530:  db $00,$03,$06,$09,$0C,$0F,$12,$15,$19,$1C,$1F,$22,$25,$28,$2B,$2E
1540:  db $31,$35,$38,$3B,$3E,$41,$44,$47,$4A,$4D,$50,$53,$56,$59,$5C,$5F
1550:  db $61,$64,$67,$6A,$6D,$70,$73,$75,$78,$7B,$7E,$80,$83,$86,$88,$8B
1560:  db $8E,$90,$93,$95,$98,$9B,$9D,$9F,$A2,$A4,$A7,$A9,$AB,$AE,$B0,$B2
1570:  db $B5,$B7,$B9,$BB,$BD,$BF,$C1,$C3,$C5,$C7,$C9,$CB,$CD,$CF,$D1,$D3
1580:  db $D4,$D6,$D8,$D9,$DB,$DD,$DE,$E0,$E1,$E3,$E4,$E6,$E7,$E8,$EA,$EB
1590:  db $EC,$ED,$EE,$EF,$F1,$F2,$F3,$F4,$F4,$F5,$F6,$F7,$F8,$F9,$F9,$FA
15A0:  db $FB,$FB,$FC,$FC,$FD,$FD,$FE,$FE,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF

FIRPresets:
15B0:  db $7F,$00,$00,$00,$00,$00,$00,$00
15B8:  db $58,$BF,$DB,$F0,$FE,$07,$0C,$0C
15C0:  db $0C,$21,$2B,$2B,$13,$FE,$F3,$F9
15C8:  db $34,$33,$00,$D9,$E5,$01,$FC,$EB
15D0:  db $00,$00,$00,$00,$00,$00,$00,$00

EchoClearRegs:
15D8:  db $2C,$3C,$0D,$4D,$6C,$4C,$5C,$3D,$2D,$5C
