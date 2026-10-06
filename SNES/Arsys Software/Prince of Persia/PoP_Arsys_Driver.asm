; Prince of Persia (SFC/SNES) - Arsys Software sound driver
; Annotated SPC700 disassembly of $0460-$150D, generated from "04 - Stage 1.spc"
; Syntax: SPCdas-style (dp = $xx, abs = !$xxxx). See PoP_Arsys_Driver.md for the format docs.


Reset:
0460: 20        CLRP
0461: CD CF     MOV X,#CF
0463: BD        MOV SP,X
0464: E8 00     MOV A,#00
0466: 5D        MOV X,A

Reset_ClearZP:
0467: AF        MOV (X)+,A
0468: C8 E0     CMP X,#E0
046A: D0 FB     BNE Reset_ClearZP
046C: 3F 08 15  CALL !IncPort0
046F: 8F 01 CD  MOV $CD,#01
0472: E8 04     MOV A,#04
0474: 3F 02 08  CALL !SetEchoDelay
0477: A2 CF     SET1 $CF.5
0479: 8F F0 F1  MOV $F1,#F0                 ; timer0 off (and clear ports)
047C: 8F 1A FA  MOV $FA,#1A                 ; T0 target = 26 -> 3.25 ms per timer tick
047F: 8F 01 F1  MOV $F1,#01                 ; start timer0
0482: 8F FF C2  MOV $C2,#FF
0485: 8F 05 1F  MOV $1F,#05
0488: 8F 00 C3  MOV $C3,#00
048B: EB 5D     MOV Y,$5D                   ; DIR = $3D (sample directory @ $3D00)
048D: E8 3D     MOV A,#3D
048F: 3F B1 09  CALL !WriteDSP
0492: 3F 9D 12  CALL !StopAll
0495: 8F 60 14  MOV $14,#60                 ; SFX bank header @ $1560
0498: 8F 15 15  MOV $15,#15
049B: 8D 00     MOV Y,#00
049D: E8 12     MOV A,#12
049F: D7 14     MOV [$14]+Y,A
04A1: FC        INC Y
04A2: E8 03     MOV A,#03
04A4: D7 14     MOV [$14]+Y,A
04A6: FC        INC Y
04A7: 8F 12 C6  MOV $C6,#12
04AA: 8F 00 C7  MOV $C7,#00
04AD: E8 08     MOV A,#08

Reset_SfxSlotPtrs:
04AF: 2D        PUSH A
04B0: E4 C6     MOV A,$C6
04B2: D7 14     MOV [$14]+Y,A
04B4: FC        INC Y
04B5: E4 C7     MOV A,$C7
04B7: D7 14     MOV [$14]+Y,A
04B9: FC        INC Y
04BA: 60        CLRC
04BB: 98 60 C6  ADC $C6,#60
04BE: 98 00 C7  ADC $C7,#00
04C1: AE        POP A
04C2: 9C        DEC A
04C3: D0 EA     BNE Reset_SfxSlotPtrs

MainLoop:
04C5: E4 2E     MOV A,$2E                   ; publish music/SFX active masks on ports 3/2
04C7: C4 F7     MOV $F7,A
04C9: E4 2F     MOV A,$2F
04CB: C4 F6     MOV $F6,A
04CD: 3F 68 08  CALL !TimerService          ; run timer-driven work
04D0: 8F 00 F5  MOV $F5,#00                 ; port1 out = 0 (idle)
04D3: 78 01 F5  CMP $F5,#01                 ; wait CPU: port1 == 1 (command ready)
04D6: D0 ED     BNE MainLoop
04D8: E4 F4     MOV A,$F4                   ; A = command (port0)
04DA: 8F 02 F5  MOV $F5,#02                 ; ack: port1 out = 2
04DD: 78 00 F5  CMP $F5,#00                 ; wait CPU to release port1
04E0: D0 FB     BNE $04DD

MainLoop_Dispatch:
04E2: 28 1F     AND A,#1F                   ; 32-entry table, push/RET dispatch
04E4: 1C        ASL A
04E5: FD        MOV Y,A
04E6: F6 F0 04  MOV A,!$04F0+Y
04E9: 2D        PUSH A
04EA: F6 EF 04  MOV A,!CmdTable+Y
04ED: 2D        PUSH A
04EE: 6F        RET

CmdTable:
04EF:  dw $061D   ; cmd $00 -> Cmd00_StopAll
04F1:  dw $0623   ; cmd $01 -> Cmd01_PlaySong
04F3:  dw $0644   ; cmd $02 -> Cmd02_LoadSamples
04F5:  dw $067F   ; cmd $03 -> Cmd03_LoadSong
04F7:  dw $0743   ; cmd $04 -> Cmd04_FadeOut
04F9:  dw $0000   ; cmd $05 (null - jumps to $0000)
04FB:  dw $074E   ; cmd $06 -> Cmd06_LoadSfxBank
04FD:  dw $0762   ; cmd $07 -> Cmd07_Nop
04FF:  dw $0765   ; cmd $08 -> Cmd08_09_Nop
0501:  dw $0765   ; cmd $09 -> Cmd08_09_Nop
0503:  dw $05F3   ; cmd $0A -> Cmd0A_ReadRAM
0505:  dw $060F   ; cmd $0B -> Cmd0B_WriteDSP
0507:  dw $06A9   ; cmd $0C -> Cmd0C_LoadSfxInstruments
0509:  dw $0708   ; cmd $0D -> Cmd0D_LoadAndPlaySfx
050B:  dw $0730   ; cmd $0E -> Cmd0E_StopSfx
050D:  dw $05BC   ; cmd $0F -> Cmd0F_UploadAndJump
050F:  dw $0553   ; cmd $10 -> Cmd10_PauseMusic
0511:  dw $0594   ; cmd $11 -> Cmd11_ResumeMusic
0513:  dw $0547   ; cmd $12 -> Cmd12_ReportStatus
0515:  dw $0536   ; cmd $13 -> Cmd13_ReadSyncCounter
0517:  dw $052F   ; cmd $14 -> Cmd14_SetMono
0519:  dw $0000   ; cmd $15 (null - jumps to $0000)
051B:  dw $074E   ; cmd $16 -> Cmd06_LoadSfxBank
051D:  dw $0762   ; cmd $17 -> Cmd07_Nop
051F:  dw $0765   ; cmd $18 -> Cmd08_09_Nop
0521:  dw $0765   ; cmd $19 -> Cmd08_09_Nop
0523:  dw $05F3   ; cmd $1A -> Cmd0A_ReadRAM
0525:  dw $060F   ; cmd $1B -> Cmd0B_WriteDSP
0527:  dw $06A9   ; cmd $1C -> Cmd0C_LoadSfxInstruments
0529:  dw $0708   ; cmd $1D -> Cmd0D_LoadAndPlaySfx
052B:  dw $0730   ; cmd $1E -> Cmd0E_StopSfx
052D:  dw $05BC   ; cmd $1F -> Cmd0F_UploadAndJump

Cmd14_SetMono:
052F: 3F DC 07  CALL !IO_RecvByte
0532: C4 C3     MOV $C3,A
0534: 2F 1A     BRA Cmd_Return

Cmd13_ReadSyncCounter:
0536: E5 56 04  MOV A,!$0456
0539: 3F EF 07  CALL !IO_SendByte
053C: E5 56 04  MOV A,!$0456
053F: F0 0F     BEQ Cmd_Return
0541: 9C        DEC A
0542: C5 56 04  MOV !$0456,A
0545: 2F 09     BRA Cmd_Return

Cmd12_ReportStatus:
0547: FA 2E F7  MOV $F7,$2E
054A: FA 2F F6  MOV $F6,$2F
054D: 3F DC 07  CALL !IO_RecvByte

Cmd_Return:
0550: 5F C5 04  JMP !MainLoop

Cmd10_PauseMusic:
0553: E4 2E     MOV A,$2E
0555: F0 3A     BEQ $0591
0557: E4 28     MOV A,$28
0559: D0 36     BNE $0591
055B: 8F 01 28  MOV $28,#01
055E: 8F 01 1E  MOV $1E,#01
0561: 8D 00     MOV Y,#00
0563: E4 1E     MOV A,$1E
0565: 24 2F     AND A,$2F
0567: D0 13     BNE $057C
0569: E8 00     MOV A,#00
056B: 3F B1 09  CALL !WriteDSP
056E: FC        INC Y
056F: 3F B1 09  CALL !WriteDSP
0572: DC        DEC Y
0573: 6D        PUSH Y
0574: E4 1E     MOV A,$1E
0576: 8D 5C     MOV Y,#5C
0578: 3F B1 09  CALL !WriteDSP
057B: EE        POP Y
057C: DD        MOV A,Y
057D: 60        CLRC
057E: 88 10     ADC A,#10
0580: FD        MOV Y,A
0581: 0B 1E     ASL $1E
0583: 90 DE     BCC $0563
0585: E8 00     MOV A,#00
0587: 8D 2C     MOV Y,#2C
0589: 3F B1 09  CALL !WriteDSP
058C: 8D 3C     MOV Y,#3C
058E: 3F B1 09  CALL !WriteDSP
0591: 5F C5 04  JMP !MainLoop

Cmd11_ResumeMusic:
0594: E4 28     MOV A,$28
0596: F0 F9     BEQ $0591
0598: CD 00     MOV X,#00
059A: 8F 00 28  MOV $28,#00
059D: 8F 01 1E  MOV $1E,#01
05A0: E4 1E     MOV A,$1E
05A2: 24 2E     AND A,$2E
05A4: F0 09     BEQ $05AF
05A6: E4 1E     MOV A,$1E
05A8: 24 2F     AND A,$2F
05AA: D0 03     BNE $05AF
05AC: 3F 7B 14  CALL !ResumeChannel
05AF: 3D        INC X
05B0: 0B 1E     ASL $1E
05B2: 90 EC     BCC $05A0
05B4: E3 CE 02  BBS $CE.7,$05B9
05B7: 8B CE     DEC $CE
05B9: 5F C5 04  JMP !MainLoop

Cmd0F_UploadAndJump:
05BC: 8F AA F4  MOV $F4,#AA
05BF: 8F BB F5  MOV $F5,#BB
05C2: 64 F4     CMP A,$F4
05C4: 68 CC     CMP A,#CC
05C6: D0 FA     BNE $05C2
05C8: FA F6 14  MOV $14,$F6
05CB: FA F7 15  MOV $15,$F7
05CE: 8D 00     MOV Y,#00
05D0: C4 F4     MOV $F4,A
05D2: 2D        PUSH A
05D3: E4 F5     MOV A,$F5
05D5: D7 14     MOV [$14]+Y,A
05D7: 3A 14     INCW $14
05D9: AE        POP A
05DA: 64 F4     CMP A,$F4
05DC: F0 FC     BEQ $05DA
05DE: BC        INC A
05DF: 64 F4     CMP A,$F4
05E1: F0 ED     BEQ $05D0
05E3: 78 00 F5  CMP $F5,#00
05E6: D0 DA     BNE $05C2
05E8: FA F6 14  MOV $14,$F6
05EB: FA F7 15  MOV $15,$F7
05EE: CD 00     MOV X,#00
05F0: 1F 14 00  JMP [!$0014+X]              ; jump to address supplied by CPU

Cmd0A_ReadRAM:
05F3: 3F 6B 07  CALL !IO_RecvWord
05F6: FA C4 B0  MOV $B0,$C4
05F9: FA C5 B1  MOV $B1,$C5
05FC: 3F 6B 07  CALL !IO_RecvWord
05FF: 8D 00     MOV Y,#00
0601: F7 B0     MOV A,[$B0]+Y
0603: 3F EF 07  CALL !IO_SendByte
0606: 3A B0     INCW $B0
0608: 1A C4     DECW $C4
060A: D0 F5     BNE $0601
060C: 5F C5 04  JMP !MainLoop

Cmd0B_WriteDSP:
060F: 3F DC 07  CALL !IO_RecvByte
0612: 2D        PUSH A
0613: 3F DC 07  CALL !IO_RecvByte
0616: EE        POP Y
0617: 3F B1 09  CALL !WriteDSP
061A: 5F C5 04  JMP !MainLoop

Cmd00_StopAll:
061D: 3F 9D 12  CALL !StopAll
0620: 5F C5 04  JMP !MainLoop

Cmd01_PlaySong:
0623: 8F FF F7  MOV $F7,#FF
0626: 3F DC 07  CALL !IO_RecvByte
0629: 68 00     CMP A,#00
062B: F0 08     BEQ $0635
062D: 8F 80 08  MOV $08,#80                 ; A!=0 -> song buffer B @ $3680
0630: 8F 36 09  MOV $09,#36
0633: 2F 06     BRA $063B
0635: 8F 80 08  MOV $08,#80                 ; A==0 -> song buffer A @ $1A80
0638: 8F 1A 09  MOV $09,#1A
063B: 3F 96 12  CALL !StopMusic
063E: 3F E7 13  CALL !StartSong
0641: 5F C5 04  JMP !MainLoop

Cmd02_LoadSamples:
0644: 8F 00 C9  MOV $C9,#00
0647: 8F 3E CA  MOV $CA,#3E                 ; SFX-sample directory entries go to $3E00 (SRCN $40+)
064A: 3F 9D 12  CALL !StopAll
064D: 3F 6B 07  CALL !IO_RecvWord
0650: E4 C4     MOV A,$C4
0652: 04 C5     OR A,$C5
0654: F0 20     BEQ $0676
0656: BA C4     MOVW YA,$C4
0658: 8F 00 C6  MOV $C6,#00
065B: 8F 3D C7  MOV $C7,#3D                 ; receive directory @ $3D00
065E: 3F 82 07  CALL !IO_RecvBlock
0661: 3F 6B 07  CALL !IO_RecvWord
0664: 8F 00 C6  MOV $C6,#00
0667: 8F 3F C7  MOV $C7,#3F                 ; receive BRR @ $3F00
066A: BA C4     MOVW YA,$C4
066C: 7A C6     ADDW YA,$C6
066E: DA CB     MOVW $CB,YA                 ; $CB = next free sample address
0670: 3F 82 07  CALL !IO_RecvBlock
0673: 5F C5 04  JMP !MainLoop
0676: 8F 00 CB  MOV $CB,#00
0679: 8F 3F CC  MOV $CC,#3F
067C: 5F C5 04  JMP !MainLoop

Cmd03_LoadSong:
067F: 3F DC 07  CALL !IO_RecvByte
0682: 68 00     CMP A,#00
0684: F0 08     BEQ $068E
0686: 8F 80 C6  MOV $C6,#80
0689: 8F 36 C7  MOV $C7,#36
068C: 2F 06     BRA $0694
068E: 8F 80 C6  MOV $C6,#80
0691: 8F 1A C7  MOV $C7,#1A
0694: E4 2E     MOV A,$2E
0696: F0 08     BEQ $06A0
0698: 69 09 C7  CMP $C7,$09
069B: D0 03     BNE $06A0
069D: 3F 96 12  CALL !StopMusic
06A0: 3F 6B 07  CALL !IO_RecvWord
06A3: 3F 82 07  CALL !IO_RecvBlock
06A6: 5F C5 04  JMP !MainLoop

Cmd0C_LoadSfxInstruments:
06A9: 8F 72 C6  MOV $C6,#72                 ; SFX instrument table @ $1872 (11 bytes each)
06AC: 8F 18 C7  MOV $C7,#18
06AF: 3F DC 07  CALL !IO_RecvByte
06B2: 5D        MOV X,A
06B3: E8 0B     MOV A,#0B
06B5: 2D        PUSH A
06B6: 3F DC 07  CALL !IO_RecvByte
06B9: 8D 00     MOV Y,#00
06BB: D7 C6     MOV [$C6]+Y,A
06BD: 3A C6     INCW $C6
06BF: AE        POP A
06C0: 9C        DEC A
06C1: D0 F2     BNE $06B5
06C3: 1D        DEC X
06C4: D0 ED     BNE $06B3
06C6: 3F 6B 07  CALL !IO_RecvWord
06C9: BA C4     MOVW YA,$C4
06CB: 2D        PUSH A
06CC: 6D        PUSH Y
06CD: FA C9 C6  MOV $C6,$C9
06D0: FA CA C7  MOV $C7,$CA
06D3: 3F 82 07  CALL !IO_RecvBlock
06D6: EE        POP Y
06D7: AE        POP A
06D8: DA C4     MOVW $C4,YA
06DA: FA C9 C6  MOV $C6,$C9
06DD: FA CA C7  MOV $C7,$CA
06E0: 8D 00     MOV Y,#00                   ; relocate received dir entries by free-sample pointer
06E2: F7 C6     MOV A,[$C6]+Y
06E4: 60        CLRC
06E5: 84 CB     ADC A,$CB
06E7: D7 C6     MOV [$C6]+Y,A
06E9: 3A C6     INCW $C6
06EB: F7 C6     MOV A,[$C6]+Y
06ED: 84 CC     ADC A,$CC
06EF: D7 C6     MOV [$C6]+Y,A
06F1: 3A C6     INCW $C6
06F3: 1A C4     DECW $C4
06F5: 1A C4     DECW $C4
06F7: D0 E7     BNE $06E0
06F9: 3F 6B 07  CALL !IO_RecvWord
06FC: FA CB C6  MOV $C6,$CB
06FF: FA CC C7  MOV $C7,$CC
0702: 3F 82 07  CALL !IO_RecvBlock
0705: 5F C5 04  JMP !MainLoop

Cmd0D_LoadAndPlaySfx:
0708: 3F DC 07  CALL !IO_RecvByte
070B: C5 52 04  MOV !$0452,A
070E: 8D 60     MOV Y,#60                   ; slot address = $1572 + n*$60
0710: CF        MUL YA
0711: 60        CLRC
0712: 88 72     ADC A,#72
0714: C4 C6     MOV $C6,A
0716: C5 54 04  MOV !$0454,A
0719: DD        MOV A,Y
071A: 88 15     ADC A,#15
071C: C4 C7     MOV $C7,A
071E: C5 55 04  MOV !$0455,A
0721: 3F 6B 07  CALL !IO_RecvWord
0724: 3F 82 07  CALL !IO_RecvBlock
0727: E5 52 04  MOV A,!$0452
072A: 3F A5 14  CALL !Sfx_Start
072D: 5F C5 04  JMP !MainLoop

Cmd0E_StopSfx:
0730: 3F DC 07  CALL !IO_RecvByte
0733: FD        MOV Y,A
0734: 60        CLRC
0735: 88 08     ADC A,#08
0737: 5D        MOV X,A
0738: F6 9D 14  MOV A,!BitTable+Y
073B: C4 1E     MOV $1E,A
073D: 3F 72 0F  CALL !Sfx_Stop
0740: 5F C5 04  JMP !MainLoop

Cmd04_FadeOut:
0743: 3F DC 07  CALL !IO_RecvByte
0746: C4 1F     MOV $1F,A
0748: 3F D9 13  CALL !StartFade
074B: 5F C5 04  JMP !MainLoop

Cmd06_LoadSfxBank:
074E: 3F 6B 07  CALL !IO_RecvWord
0751: 8F 60 C6  MOV $C6,#60
0754: 8F 15 C7  MOV $C7,#15
0757: 3F 82 07  CALL !IO_RecvBlock
075A: E8 00     MOV A,#00
075C: 3F A5 14  CALL !Sfx_Start
075F: 5F C5 04  JMP !MainLoop

Cmd07_Nop:
0762: 5F C5 04  JMP !MainLoop

Cmd08_09_Nop:
0765: 5F C5 04  JMP !MainLoop
0768: 5F C5 04  JMP !MainLoop

IO_RecvWord:
076B: 8F 03 F5  MOV $F5,#03
076E: 78 01 F5  CMP $F5,#01
0771: D0 FB     BNE $076E
0773: FA F6 C4  MOV $C4,$F6
0776: FA F7 C5  MOV $C5,$F7
0779: 8F 02 F5  MOV $F5,#02
077C: 78 00 F5  CMP $F5,#00
077F: D0 FB     BNE $077C
0781: 6F        RET

IO_RecvBlock:
0782: 8F 00 C8  MOV $C8,#00
0785: 8F 00 F5  MOV $F5,#00
0788: E4 C8     MOV A,$C8
078A: 28 0F     AND A,#0F
078C: D0 03     BNE $0791
078E: 3F 68 08  CALL !TimerService
0791: 8D 40     MOV Y,#40
0793: E4 C8     MOV A,$C8
0795: 2E F5 04  CBNE $F5,$079C
0798: FE FB     DBNZ Y,$0795
079A: 2F F2     BRA $078E
079C: 8D 00     MOV Y,#00
079E: E4 F4     MOV A,$F4
07A0: D7 C6     MOV [$C6]+Y,A
07A2: FC        INC Y
07A3: E4 F6     MOV A,$F6
07A5: D7 C6     MOV [$C6]+Y,A
07A7: FC        INC Y
07A8: E4 F7     MOV A,$F7
07AA: D7 C6     MOV [$C6]+Y,A
07AC: 60        CLRC
07AD: 98 03 C6  ADC $C6,#03
07B0: 98 00 C7  ADC $C7,#00
07B3: FA F5 C8  MOV $C8,$F5
07B6: FA C8 F5  MOV $F5,$C8
07B9: 80        SETC
07BA: B8 03 C4  SBC $C4,#03
07BD: B8 00 C5  SBC $C5,#00
07C0: 90 06     BCC $07C8
07C2: E4 C4     MOV A,$C4
07C4: 04 C5     OR A,$C5
07C6: D0 C0     BNE $0788
07C8: BA C6     MOVW YA,$C6
07CA: 7A C4     ADDW YA,$C4
07CC: DA C6     MOVW $C6,YA
07CE: 78 01 F5  CMP $F5,#01
07D1: D0 F5     BNE $07C8
07D3: 8F 02 F5  MOV $F5,#02
07D6: 78 00 F5  CMP $F5,#00
07D9: D0 FB     BNE $07D6
07DB: 6F        RET

IO_RecvByte:
07DC: 8F 01 F5  MOV $F5,#01
07DF: 78 01 F5  CMP $F5,#01
07E2: D0 FB     BNE $07DF
07E4: E4 F4     MOV A,$F4
07E6: 8F 02 F5  MOV $F5,#02
07E9: 78 00 F5  CMP $F5,#00
07EC: D0 FB     BNE $07E9
07EE: 6F        RET

IO_SendByte:
07EF: C4 F4     MOV $F4,A
07F1: 8F 01 F5  MOV $F5,#01
07F4: 78 01 F5  CMP $F5,#01
07F7: D0 FB     BNE $07F4
07F9: 8F 02 F5  MOV $F5,#02
07FC: 78 00 F5  CMP $F5,#00
07FF: D0 FB     BNE $07FC
0801: 6F        RET

SetEchoDelay:
0802: 64 CD     CMP A,$CD
0804: D0 01     BNE $0807
0806: 6F        RET
0807: C4 CD     MOV $CD,A
0809: 28 0F     AND A,#0F
080B: BC        INC A
080C: 48 FF     EOR A,#FF
080E: F3 CE 03  BBC $CE.7,$0814
0811: 60        CLRC
0812: 84 CE     ADC A,$CE
0814: C4 CE     MOV $CE,A
0816: 8D 04     MOV Y,#04                   ; zero EON/EFB/EVOL while EDL changes
0818: F6 5D 08  MOV A,!$085D+Y
081B: C4 F2     MOV $F2,A
081D: E8 00     MOV A,#00
081F: C4 F3     MOV $F3,A
0821: FE F5     DBNZ Y,$0818
0823: E4 CF     MOV A,$CF
0825: 08 20     OR A,#20
0827: 8D 6C     MOV Y,#6C
0829: 3F B1 09  CALL !WriteDSP
082C: E4 CD     MOV A,$CD
082E: 8D 7D     MOV Y,#7D
0830: 3F B1 09  CALL !WriteDSP
0833: 1C        ASL A                       ; ESA = -(EDL*8): echo buffer at top of RAM
0834: 1C        ASL A
0835: 1C        ASL A
0836: 48 FF     EOR A,#FF
0838: BC        INC A
0839: 8D 6D     MOV Y,#6D
083B: 5F B1 09  JMP !WriteDSP

FIRPresets:
083E:  db $7F,$00,$00,$00,$00,$00,$00,$00
0846:  db $58,$BF,$DB,$F0,$FE,$07,$0C,$0C
084E:  db $0C,$21,$2B,$2B,$13,$FE,$F3,$F9
0856:  db $34,$33,$00,$D9,$E5,$01,$FC,$EB

EchoClearRegs:
085E:  db $2C,$3C,$0D,$4D,$6C,$4C,$5C,$3D,$2D,$5C

TimerService:
0868: E4 FD     MOV A,$FD                   ; $FD = timer0 ticks elapsed
086A: 2D        PUSH A
086B: 60        CLRC
086C: 84 BF     ADC A,$BF
086E: C4 BF     MOV $BF,A
0870: 68 05     CMP A,#05                   ; every 5 timer ticks (16.25 ms) -> FrameUpdate
0872: 90 07     BCC $087B
0874: A8 05     SBC A,#05
0876: C4 BF     MOV $BF,A
0878: 3F 93 08  CALL !FrameUpdate
087B: AE        POP A
087C: 1C        ASL A                       ; tempo accumulator += ticks*16
087D: 1C        ASL A
087E: 1C        ASL A
087F: 1C        ASL A
0880: 60        CLRC
0881: 84 C1     ADC A,$C1
0883: B0 06     BCS $088B
0885: C4 C1     MOV $C1,A
0887: 64 25     CMP A,$25                   ; >= T ($25) -> one sequencer tick
0889: 90 07     BCC $0892
088B: A4 25     SBC A,$25
088D: C4 C1     MOV $C1,A
088F: 3F 89 09  CALL !MusicTick
0892: 6F        RET

FrameUpdate:
0893: F3 CE 6D  BBC $CE.7,Frame_Fade        ; echo "dirty" countdown; apply when it reaches 0
0896: AB CE     INC $CE
0898: D0 69     BNE Frame_Fade
089A: E4 2F     MOV A,$2F
089C: 48 FF     EOR A,#FF
089E: 24 D0     AND A,$D0
08A0: C4 B2     MOV $B2,A
08A2: E4 2F     MOV A,$2F
08A4: 24 D1     AND A,$D1
08A6: 04 B2     OR A,$B2
08A8: F0 04     BEQ $08AE
08AA: B2 CF     CLR1 $CF.5
08AC: 2F 17     BRA Frame_EchoOn
08AE: A2 CF     SET1 $CF.5
08B0: E4 CF     MOV A,$CF
08B2: 8D 6C     MOV Y,#6C
08B4: 3F B1 09  CALL !WriteDSP
08B7: E8 00     MOV A,#00
08B9: 8D 2C     MOV Y,#2C
08BB: 3F B1 09  CALL !WriteDSP
08BE: 8D 3C     MOV Y,#3C
08C0: 3F B1 09  CALL !WriteDSP
08C3: 2F 3E     BRA Frame_Fade

Frame_EchoOn:
08C5: E4 CF     MOV A,$CF
08C7: 8D 6C     MOV Y,#6C
08C9: 3F B1 09  CALL !WriteDSP
08CC: 8D 4D     MOV Y,#4D
08CE: 3F B1 09  CALL !WriteDSP
08D1: E4 D9     MOV A,$D9
08D3: 8D 0D     MOV Y,#0D
08D5: 3F B1 09  CALL !WriteDSP
08D8: E4 2F     MOV A,$2F
08DA: D0 06     BNE $08E2
08DC: EB D7     MOV Y,$D7
08DE: E4 D8     MOV A,$D8
08E0: 2F 04     BRA $08E6
08E2: EB DA     MOV Y,$DA
08E4: E4 DB     MOV A,$DB
08E6: 78 00 C3  CMP $C3,#00
08E9: F0 02     BEQ $08ED
08EB: E8 40     MOV A,#40
08ED: 1C        ASL A
08EE: 2D        PUSH A
08EF: 6D        PUSH Y
08F0: CF        MUL YA
08F1: DD        MOV A,Y
08F2: 8D 2C     MOV Y,#2C
08F4: 3F B1 09  CALL !WriteDSP
08F7: EE        POP Y
08F8: AE        POP A
08F9: BC        INC A
08FA: 48 FF     EOR A,#FF
08FC: CF        MUL YA
08FD: DD        MOV A,Y
08FE: 8D 3C     MOV Y,#3C
0900: 3F B1 09  CALL !WriteDSP

Frame_Fade:
0903: 8F 00 1D  MOV $1D,#00
0906: FA 08 12  MOV $12,$08
0909: FA 09 13  MOV $13,$09
090C: E4 1A     MOV A,$1A                   ; fade active?
090E: F0 16     BEQ Frame_MasterVol
0910: AB 1B     INC $1B
0912: 69 1B 1F  CMP $1F,$1B
0915: D0 0F     BNE Frame_MasterVol
0917: 8F 00 1B  MOV $1B,#00
091A: AB 1C     INC $1C
091C: AB 1D     INC $1D
091E: 78 0F 1C  CMP $1C,#0F
0921: D0 03     BNE Frame_MasterVol
0923: 3F 9D 12  CALL !StopAll

Frame_MasterVol:
0926: E8 0F     MOV A,#0F
0928: 80        SETC
0929: A4 1C     SBC A,$1C
092B: FD        MOV Y,A
092C: F6 58 0B  MOV A,!VolumeTable+Y        ; MVOL = VolumeTable[15-fadeLevel]
092F: 8D 0C     MOV Y,#0C
0931: 3F B1 09  CALL !WriteDSP
0934: 8D 1C     MOV Y,#1C
0936: 3F B1 09  CALL !WriteDSP

Frame_MusicFX:
0939: E4 28     MOV A,$28
093B: D0 1F     BNE Frame_SfxTracks
093D: E4 2E     MOV A,$2E
093F: 48 FF     EOR A,#FF
0941: 04 2F     OR A,$2F
0943: C4 D6     MOV $D6,A
0945: CD 00     MOV X,#00
0947: 8F 01 1E  MOV $1E,#01
094A: 8D 08     MOV Y,#08
094C: 6D        PUSH Y
094D: E4 1E     MOV A,$1E
094F: 24 D6     AND A,$D6
0951: D0 03     BNE $0956
0953: 3F B6 09  CALL !ChannelFrameFX
0956: 3D        INC X
0957: 0B 1E     ASL $1E
0959: EE        POP Y
095A: FE F0     DBNZ Y,$094C

Frame_SfxTracks:
095C: CD 08     MOV X,#08                   ; SFX channels 8-15 run at frame rate (not tempo)
095E: 8F 01 1E  MOV $1E,#01
0961: 8F 01 24  MOV $24,#01
0964: 8F 60 12  MOV $12,#60
0967: 8F 15 13  MOV $13,#15
096A: 8D 08     MOV Y,#08
096C: 6D        PUSH Y
096D: E4 1E     MOV A,$1E
096F: 24 2F     AND A,$2F
0971: F0 06     BEQ $0979
0973: 3F B6 09  CALL !ChannelFrameFX
0976: 3F 9D 0C  CALL !ChannelTick
0979: 3D        INC X
097A: 0B 1E     ASL $1E
097C: EE        POP Y
097D: FE ED     DBNZ Y,$096C
097F: 8F 00 24  MOV $24,#00
0982: FA 08 12  MOV $12,$08
0985: FA 09 13  MOV $13,$09
0988: 6F        RET

MusicTick:
0989: E4 28     MOV A,$28
098B: D0 FB     BNE $0988
098D: FA 08 12  MOV $12,$08
0990: FA 09 13  MOV $13,$09
0993: 8F 01 1E  MOV $1E,#01
0996: 8F 00 11  MOV $11,#00
0999: CD 00     MOV X,#00
099B: 8D 08     MOV Y,#08
099D: 6D        PUSH Y
099E: E4 1E     MOV A,$1E
09A0: 24 2E     AND A,$2E
09A2: F0 03     BEQ $09A7
09A4: 3F 9D 0C  CALL !ChannelTick
09A7: 3D        INC X
09A8: 0B 1E     ASL $1E
09AA: 98 10 11  ADC $11,#10
09AD: EE        POP Y
09AE: FE ED     DBNZ Y,$099D
09B0: 6F        RET

WriteDSP:
09B1: CB F2     MOV $F2,Y
09B3: C4 F3     MOV $F3,A
09B5: 6F        RET

ChannelFrameFX:
09B6: F5 40 04  MOV A,!$0440+X
09B9: F0 51     BEQ $0A0C
09BB: C4 B5     MOV $B5,A
09BD: 8F 00 B4  MOV $B4,#00
09C0: 28 80     AND A,#80
09C2: 4B B5     LSR $B5
09C4: 6B B4     ROR $B4
09C6: 04 B5     OR A,$B5
09C8: C4 B5     MOV $B5,A
09CA: 28 80     AND A,#80
09CC: 4B B5     LSR $B5
09CE: 6B B4     ROR $B4
09D0: 04 B5     OR A,$B5
09D2: C4 B5     MOV $B5,A
09D4: F5 70 02  MOV A,!$0270+X
09D7: FD        MOV Y,A
09D8: F5 20 04  MOV A,!$0420+X
09DB: 7A B4     ADDW YA,$B4
09DD: 6D        PUSH Y
09DE: 2D        PUSH A
09DF: DD        MOV A,Y
09E0: 80        SETC
09E1: A8 40     SBC A,#40
09E3: 10 03     BPL $09E8
09E5: 48 FF     EOR A,#FF
09E7: BC        INC A
09E8: 75 30 04  CMP A,!$0430+X
09EB: 90 0D     BCC $09FA
09ED: F5 40 04  MOV A,!$0440+X
09F0: 48 FF     EOR A,#FF
09F2: BC        INC A
09F3: D5 40 04  MOV !$0440+X,A
09F6: AE        POP A
09F7: AE        POP A
09F8: 2F 08     BRA FX_Tremolo
09FA: AE        POP A
09FB: D5 20 04  MOV !$0420+X,A
09FE: AE        POP A
09FF: D5 70 02  MOV !$0270+X,A

FX_Tremolo:
0A02: F5 A0 02  MOV A,!$02A0+X
0A05: F0 17     BEQ $0A1E
0A07: F5 B0 02  MOV A,!$02B0+X
0A0A: F0 12     BEQ $0A1E
0A0C: F5 90 02  MOV A,!$0290+X
0A0F: C4 27     MOV $27,A
0A11: F5 A0 02  MOV A,!$02A0+X
0A14: F0 0B     BEQ FX_Portamento
0A16: F5 B0 02  MOV A,!$02B0+X
0A19: F0 06     BEQ FX_Portamento
0A1B: 3F 04 0C  CALL !LFO_Step
0A1E: 3F FC 11  CALL !WriteVoiceVolume

FX_Portamento:
0A21: F5 C0 03  MOV A,!$03C0+X
0A24: C4 B2     MOV $B2,A
0A26: F5 B0 03  MOV A,!$03B0+X
0A29: C4 B3     MOV $B3,A
0A2B: F5 F0 03  MOV A,!$03F0+X
0A2E: F0 4C     BEQ FX_Vibrato
0A30: 8D 03     MOV Y,#03
0A32: F5 40 02  MOV A,!$0240+X
0A35: F0 0D     BEQ $0A44
0A37: 68 06     CMP A,#06
0A39: 90 02     BCC $0A3D
0A3B: E8 06     MOV A,#06
0A3D: FD        MOV Y,A
0A3E: E8 03     MOV A,#03
0A40: 1C        ASL A
0A41: FE FD     DBNZ Y,$0A40
0A43: FD        MOV Y,A
0A44: F5 F0 03  MOV A,!$03F0+X
0A47: CF        MUL YA
0A48: DA B0     MOVW $B0,YA
0A4A: F5 E0 03  MOV A,!$03E0+X
0A4D: C4 B4     MOV $B4,A
0A4F: F5 D0 03  MOV A,!$03D0+X
0A52: C4 B5     MOV $B5,A
0A54: BA B2     MOVW YA,$B2
0A56: 5A B4     CMPW YA,$B4
0A58: F0 22     BEQ FX_Vibrato
0A5A: B0 08     BCS $0A64
0A5C: 7A B0     ADDW YA,$B0
0A5E: 5A B4     CMPW YA,$B4
0A60: 90 0A     BCC $0A6C
0A62: 2F 06     BRA $0A6A
0A64: 9A B0     SUBW YA,$B0
0A66: 5A B4     CMPW YA,$B4
0A68: B0 02     BCS $0A6C
0A6A: BA B4     MOVW YA,$B4
0A6C: DA B2     MOVW $B2,YA
0A6E: D5 C0 03  MOV !$03C0+X,A
0A71: DD        MOV A,Y
0A72: D5 B0 03  MOV !$03B0+X,A
0A75: 8D 5C     MOV Y,#5C
0A77: E8 00     MOV A,#00
0A79: 3F B1 09  CALL !WriteDSP

FX_Vibrato:
0A7C: F4 A0     MOV A,$A0+X
0A7E: F0 0D     BEQ $0A8D
0A80: 9B A0     DEC $A0+X
0A82: 2F 05     BRA $0A89
0A84: F5 F0 03  MOV A,!$03F0+X
0A87: F0 04     BEQ $0A8D
0A89: E8 00     MOV A,#00
0A8B: 2F 2E     BRA FX_ApplyPitch
0A8D: F5 20 03  MOV A,!$0320+X
0A90: F0 F7     BEQ $0A89
0A92: F5 30 03  MOV A,!$0330+X
0A95: F0 F2     BEQ $0A89
0A97: 4D        PUSH X
0A98: 7D        MOV A,X
0A99: 60        CLRC
0A9A: 88 80     ADC A,#80
0A9C: 5D        MOV X,A
0A9D: 3F 04 0C  CALL !LFO_Step
0AA0: CE        POP X
0AA1: F5 20 03  MOV A,!$0320+X
0AA4: 5C        LSR A
0AA5: C4 B0     MOV $B0,A
0AA7: F5 60 03  MOV A,!$0360+X
0AAA: 10 03     BPL $0AAF
0AAC: 48 FF     EOR A,#FF
0AAE: BC        INC A
0AAF: 80        SETC
0AB0: A4 B0     SBC A,$B0
0AB2: 2D        PUSH A
0AB3: E8 00     MOV A,#00
0AB5: 8D 5C     MOV Y,#5C
0AB7: 3F B1 09  CALL !WriteDSP
0ABA: AE        POP A

FX_ApplyPitch:
0ABB: 8F 00 B5  MOV $B5,#00
0ABE: 60        CLRC
0ABF: 95 10 02  ADC A,!$0210+X
0AC2: C4 B4     MOV $B4,A
0AC4: 1C        ASL A
0AC5: 90 02     BCC $0AC9
0AC7: 8B B5     DEC $B5
0AC9: E8 00     MOV A,#00
0ACB: C4 0E     MOV $0E,A
0ACD: C4 0F     MOV $0F,A
0ACF: 3F A8 11  CALL !GetInstrumentPtr
0AD2: 8D 09     MOV Y,#09                   ; inst[9..10] = signed fine tune, pitch *= 1 + t/256
0AD4: F7 B6     MOV A,[$B6]+Y
0AD6: 60        CLRC
0AD7: 84 B4     ADC A,$B4
0AD9: C4 B4     MOV $B4,A
0ADB: FC        INC Y
0ADC: F7 B6     MOV A,[$B6]+Y
0ADE: 84 B5     ADC A,$B5
0AE0: C4 B5     MOV $B5,A
0AE2: C4 B9     MOV $B9,A
0AE4: FA B4 B8  MOV $B8,$B4
0AE7: F3 B5 08  BBC $B5.7,$0AF2
0AEA: 58 FF B8  EOR $B8,#FF
0AED: 58 FF B9  EOR $B9,#FF
0AF0: 3A B8     INCW $B8
0AF2: E4 B8     MOV A,$B8
0AF4: EB B2     MOV Y,$B2
0AF6: CF        MUL YA
0AF7: DA 0C     MOVW $0C,YA
0AF9: E4 B8     MOV A,$B8
0AFB: EB B3     MOV Y,$B3
0AFD: CF        MUL YA
0AFE: 7A 0D     ADDW YA,$0D
0B00: DA 0D     MOVW $0D,YA
0B02: 90 02     BCC $0B06
0B04: AB 0F     INC $0F
0B06: E4 B9     MOV A,$B9
0B08: EB B2     MOV Y,$B2
0B0A: CF        MUL YA
0B0B: 7A 0D     ADDW YA,$0D
0B0D: DA 0D     MOVW $0D,YA
0B0F: 90 02     BCC $0B13
0B11: AB 0F     INC $0F
0B13: E4 B9     MOV A,$B9
0B15: EB B3     MOV Y,$B3
0B17: CF        MUL YA
0B18: 7A 0E     ADDW YA,$0E
0B1A: DA 0E     MOVW $0E,YA
0B1C: E4 0F     MOV A,$0F
0B1E: D0 06     BNE $0B26
0B20: BA 0D     MOVW YA,$0D
0B22: AD 40     CMP Y,#40
0B24: 90 02     BCC $0B28
0B26: 8D 40     MOV Y,#40
0B28: F3 B4 0D  BBC $B4.7,$0B38
0B2B: DA 0C     MOVW $0C,YA
0B2D: BA B2     MOVW YA,$B2
0B2F: 9A 0C     SUBW YA,$0C
0B31: B0 11     BCS $0B44
0B33: E8 00     MOV A,#00
0B35: FD        MOV Y,A
0B36: 2F 0C     BRA $0B44
0B38: 7A B2     ADDW YA,$B2
0B3A: B0 04     BCS $0B40
0B3C: AD 40     CMP Y,#40
0B3E: 90 04     BCC $0B44
0B40: E8 FF     MOV A,#FF
0B42: 8D 3F     MOV Y,#3F
0B44: DA B2     MOVW $B2,YA
0B46: 7D        MOV A,X
0B47: 28 07     AND A,#07
0B49: 9F        XCN A
0B4A: 08 02     OR A,#02
0B4C: FD        MOV Y,A
0B4D: E4 B2     MOV A,$B2
0B4F: 3F B1 09  CALL !WriteDSP
0B52: FC        INC Y
0B53: E4 B3     MOV A,$B3
0B55: 5F B1 09  JMP !WriteDSP

VolumeTable:
0B58:  db $00,$03,$07,$0B,$0F,$13,$18,$1E,$24,$2B,$34,$3E,$4C,$60,$78,$7F

NotePitchTable:
0B68:  dw $4000   ;
0B6A:  dw $47D0   ;
0B6C:  dw $2600   ;
0B6E:  dw $2AB0   ;
0B70:  dw $2FF0   ;
0B72:  dw $32C0   ;
0B74:  dw $3900   ;
0B76:  dw $43D0   ;
0B78:  dw $47D0   ;
0B7A:  dw $2850   ;
0B7C:  dw $2D40   ;
0B7E:  dw $32C0   ;
0B80:  dw $35C8   ;
0B82:  dw $3C60   ;

PanSineTable:
0B84:  db $00,$03,$06,$09,$0C,$0F,$12,$15,$19,$1C,$1F,$22,$25,$28,$2B,$2E
0B94:  db $31,$35,$38,$3B,$3E,$41,$44,$47,$4A,$4D,$50,$53,$56,$59,$5C,$5F
0BA4:  db $61,$64,$67,$6A,$6D,$70,$73,$75,$78,$7B,$7E,$80,$83,$86,$88,$8B
0BB4:  db $8E,$90,$93,$95,$98,$9B,$9D,$9F,$A2,$A4,$A7,$A9,$AB,$AE,$B0,$B2
0BC4:  db $B5,$B7,$B9,$BB,$BD,$BF,$C1,$C3,$C5,$C7,$C9,$CB,$CD,$CF,$D1,$D3
0BD4:  db $D4,$D6,$D8,$D9,$DB,$DD,$DE,$E0,$E1,$E3,$E4,$E6,$E7,$E8,$EA,$EB
0BE4:  db $EC,$ED,$EE,$EF,$F1,$F2,$F3,$F4,$F4,$F5,$F6,$F7,$F8,$F9,$F9,$FA
0BF4:  db $FB,$FB,$FC,$FC,$FD,$FD,$FE,$FE,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF

LFO_Step:
0C04: 23 27 58  BBS $27.1,LFO_StepSquare
0C07: F5 10 03  MOV A,!$0310+X
0C0A: 60        CLRC
0C0B: 95 E0 02  ADC A,!$02E0+X
0C0E: D5 E0 02  MOV !$02E0+X,A
0C11: F5 C0 02  MOV A,!$02C0+X
0C14: 60        CLRC
0C15: 95 D0 02  ADC A,!$02D0+X
0C18: D5 D0 02  MOV !$02D0+X,A
0C1B: 90 11     BCC $0C2E
0C1D: F5 E0 02  MOV A,!$02E0+X
0C20: BC        INC A
0C21: D5 E0 02  MOV !$02E0+X,A
0C24: F5 B0 02  MOV A,!$02B0+X
0C27: 60        CLRC
0C28: 95 D0 02  ADC A,!$02D0+X
0C2B: D5 D0 02  MOV !$02D0+X,A
0C2E: F5 F0 02  MOV A,!$02F0+X
0C31: BC        INC A
0C32: D5 F0 02  MOV !$02F0+X,A
0C35: 75 B0 02  CMP A,!$02B0+X
0C38: D0 24     BNE $0C5E
0C3A: 13 27 0D  BBC $27.0,$0C4A
0C3D: F3 27 05  BBC $27.7,$0C45
0C40: F5 A0 02  MOV A,!$02A0+X
0C43: 2F 02     BRA $0C47
0C45: E8 00     MOV A,#00
0C47: D5 E0 02  MOV !$02E0+X,A
0C4A: F5 E0 02  MOV A,!$02E0+X
0C4D: 48 FF     EOR A,#FF
0C4F: BC        INC A
0C50: D5 E0 02  MOV !$02E0+X,A
0C53: F5 00 03  MOV A,!$0300+X
0C56: D5 D0 02  MOV !$02D0+X,A
0C59: E8 00     MOV A,#00
0C5B: D5 F0 02  MOV !$02F0+X,A
0C5E: 6F        RET

LFO_StepSquare:
0C5F: F5 F0 02  MOV A,!$02F0+X
0C62: BC        INC A
0C63: D5 F0 02  MOV !$02F0+X,A
0C66: 75 B0 02  CMP A,!$02B0+X
0C69: D0 F3     BNE $0C5E
0C6B: E8 00     MOV A,#00
0C6D: D5 F0 02  MOV !$02F0+X,A
0C70: 03 27 10  BBS $27.0,LFO_Random
0C73: F5 E0 02  MOV A,!$02E0+X
0C76: D0 05     BNE $0C7D
0C78: F5 A0 02  MOV A,!$02A0+X
0C7B: 2F 02     BRA $0C7F
0C7D: E8 00     MOV A,#00
0C7F: D5 E0 02  MOV !$02E0+X,A
0C82: 6F        RET

LFO_Random:
0C83: F5 A0 02  MOV A,!$02A0+X
0C86: FD        MOV Y,A
0C87: E4 2C     MOV A,$2C
0C89: 7C        ROR A
0C8A: 7C        ROR A
0C8B: BC        INC A
0C8C: 44 2C     EOR A,$2C
0C8E: C4 2C     MOV $2C,A
0C90: 60        CLRC
0C91: 84 2D     ADC A,$2D
0C93: C4 2D     MOV $2D,A
0C95: AB 2D     INC $2D
0C97: CF        MUL YA
0C98: DD        MOV A,Y
0C99: D5 E0 02  MOV !$02E0+X,A
0C9C: 6F        RET

ChannelTick:
0C9D: 9B 30     DEC $30+X
0C9F: F0 20     BEQ MML_ReadNext
0CA1: F5 10 04  MOV A,!$0410+X
0CA4: F0 1A     BEQ $0CC0
0CA6: 9C        DEC A
0CA7: D5 10 04  MOV !$0410+X,A
0CAA: D0 14     BNE $0CC0
0CAC: 03 24 06  BBS $24.0,$0CB5
0CAF: E4 1E     MOV A,$1E
0CB1: 24 2F     AND A,$2F
0CB3: D0 0B     BNE $0CC0
0CB5: F5 20 02  MOV A,!$0220+X
0CB8: 08 04     OR A,#04
0CBA: D5 20 02  MOV !$0220+X,A
0CBD: 5F 95 13  JMP !KeyOffCurrent
0CC0: 6F        RET

MML_ReadNext:
0CC1: F4 40     MOV A,$40+X
0CC3: C4 14     MOV $14,A
0CC5: F4 50     MOV A,$50+X
0CC7: C4 15     MOV $15,A

MML_Loop:
0CC9: E8 0C     MOV A,#0C                   ; push return = MML_Loop so non-timed commands RET into the parser
0CCB: 2D        PUSH A
0CCC: E8 C9     MOV A,#C9
0CCE: 2D        PUSH A
0CCF: 8D 00     MOV Y,#00
0CD1: F7 14     MOV A,[$14]+Y
0CD3: 3A 14     INCW $14
0CD5: 28 7F     AND A,#7F                   ; bit 7 of every MML byte is ignored
0CD7: D0 03     BNE $0CDC
0CD9: 5F 6D 0F  JMP !MML_EndOfPhrase
0CDC: 68 21     CMP A,#21
0CDE: F0 5D     BEQ MML_Bang_Sync
0CE0: 68 20     CMP A,#20
0CE2: F0 60     BEQ MML_Nop
0CE4: 68 2A     CMP A,#2A
0CE6: F0 5C     BEQ MML_Nop
0CE8: 68 25     CMP A,#25
0CEA: D0 03     BNE $0CEF
0CEC: 5F 2A 0E  JMP !MML_Percent_Comment
0CEF: C4 B2     MOV $B2,A                   ; index = (c & $3E): two characters per entry
0CF1: 28 3E     AND A,#3E
0CF3: FD        MOV Y,A
0CF4: F6 FE 0C  MOV A,!$0CFE+Y
0CF7: 2D        PUSH A
0CF8: F6 FD 0C  MOV A,!MMLDispatchTable+Y
0CFB: 2D        PUSH A
0CFC: 6F        RET

MMLDispatchTable:
0CFD:  dw $0E35   ; chars '@' 'A' -> MML_At_or_A
0CFF:  dw $0FFC   ; chars 'B' 'C' -> MML_Note
0D01:  dw $0FFC   ; chars 'D' 'E' -> MML_Note
0D03:  dw $0FFC   ; chars 'F' 'G' -> MML_Note
0D05:  dw $0D45   ; chars 'H' 'I' -> MML_H_I_Echo
0D07:  dw $0D8B   ; chars 'J' 'K' -> MML_J_K
0D09:  dw $0DAB   ; chars 'L' 'M' -> MML_L_M
0D0B:  dw $0E58   ; chars 'N' 'O' -> MML_N_O
0D0D:  dw $0E98   ; chars 'P' 'Q' -> MML_P_Q
0D0F:  dw $0ECB   ; chars 'R' 'S' -> MML_R_Rest
0D11:  dw $0ED4   ; chars 'T' 'U' -> MML_T_Tempo
0D13:  dw $0EDF   ; chars 'V' 'W' -> MML_V_Volume
0D15:  dw $0D44   ; chars 'X' 'Y' -> MML_Nop
0D17:  dw $0F0B   ; chars 'Z' '[' -> MML_LBracket_Legato
0D19:  dw $0F12   ; chars '\' ']' -> MML_RBracket_EndLegato
0D1B:  dw $0EE5   ; chars '^' '_' -> MML_Caret_VolStep
0D1D:  dw $0D44   ; chars '`' 'a' -> MML_Nop
0D1F:  dw $0EF9   ; chars 'b' 'c' -> MML_Sharp
0D21:  dw $0DE5   ; chars 'd' 'e' -> MML_Dollar_FIR
0D23:  dw $0F04   ; chars 'f' 'g' -> MML_Amp_Tie
0D25:  dw $0F1B   ; chars 'h' 'i' -> MML_Paren_Detune
0D27:  dw $0F24   ; chars 'j' 'k' -> MML_Plus_OctUp
0D29:  dw $0F2A   ; chars 'l' 'm' -> MML_Minus_OctDown
0D2B:  dw $0D44   ; chars 'n' 'o' -> MML_Nop
0D2D:  dw $0F34   ; chars 'p' 'q' -> MML_Pan
0D2F:  dw $0F34   ; chars 'r' 's' -> MML_Pan
0D31:  dw $0F34   ; chars 't' 'u' -> MML_Pan
0D33:  dw $0F34   ; chars 'v' 'w' -> MML_Pan
0D35:  dw $0F34   ; chars 'x' 'y' -> MML_Pan
0D37:  dw $0F34   ; chars 'z' '{' -> MML_Pan
0D39:  dw $0F34   ; chars '|' '}' -> MML_Pan
0D3B:  dw $0F34   ; chars '~' -> MML_Pan

MML_Bang_Sync:
0D3D: E5 56 04  MOV A,!$0456
0D40: BC        INC A
0D41: C5 56 04  MOV !$0456,A

MML_Nop:
0D44: 6F        RET

MML_H_I_Echo:
0D45: 3F 9C 13  CALL !ReadNumber
0D48: 78 49 B2  CMP $B2,#49
0D4B: F0 31     BEQ MML_I_EchoFeedback
0D4D: E4 B4     MOV A,$B4
0D4F: F0 1C     BEQ $0D6D
0D51: EB B4     MOV Y,$B4
0D53: F6 58 0B  MOV A,!VolumeTable+Y        ; H n: echo volume = VolumeTable[n]
0D56: 03 24 07  BBS $24.0,$0D60
0D59: C4 D7     MOV $D7,A
0D5B: 09 1E D0  OR $D0,$1E
0D5E: 2F 18     BRA $0D78
0D60: C4 DA     MOV $DA,A
0D62: 09 1E D1  OR $D1,$1E
0D65: 2F 11     BRA $0D78
0D67: 24 D1     AND A,$D1
0D69: C4 D1     MOV $D1,A
0D6B: 2F 0B     BRA $0D78
0D6D: E4 1E     MOV A,$1E
0D6F: 48 FF     EOR A,#FF
0D71: 03 24 F3  BBS $24.0,$0D67
0D74: 24 D0     AND A,$D0
0D76: C4 D0     MOV $D0,A
0D78: E3 CE 02  BBS $CE.7,$0D7D
0D7B: 8B CE     DEC $CE
0D7D: 6F        RET

MML_I_EchoFeedback:
0D7E: 03 24 05  BBS $24.0,$0D86
0D81: FA B4 D9  MOV $D9,$B4
0D84: 2F F2     BRA $0D78
0D86: FA B4 DC  MOV $DC,$B4
0D89: 2F ED     BRA $0D78

MML_J_K:
0D8B: 3F 9C 13  CALL !ReadNumber
0D8E: 78 4B B2  CMP $B2,#4B
0D91: F0 05     BEQ $0D98
0D93: E4 B4     MOV A,$B4
0D95: 5F 02 08  JMP !SetEchoDelay           ; J n: echo delay
0D98: 03 24 08  BBS $24.0,$0DA3
0D9B: FA B4 D8  MOV $D8,$B4                 ; K n: echo balance (64 = centre)
0D9E: 38 7F D8  AND $D8,#7F
0DA1: 2F D5     BRA $0D78
0DA3: FA B4 DB  MOV $DB,$B4
0DA6: 38 7F DB  AND $DB,#7F
0DA9: 2F CD     BRA $0D78

MML_L_M:
0DAB: 3F 9C 13  CALL !ReadNumber
0DAE: 78 4C B2  CMP $B2,#4C
0DB1: F0 20     BEQ MML_L_AutoPan
0DB3: E4 B4     MOV A,$B4
0DB5: F0 0B     BEQ $0DC2
0DB7: 03 24 04  BBS $24.0,$0DBE
0DBA: 09 1E D2  OR $D2,$1E
0DBD: 6F        RET
0DBE: 09 1E D3  OR $D3,$1E
0DC1: 6F        RET
0DC2: E4 1E     MOV A,$1E
0DC4: 48 FF     EOR A,#FF
0DC6: 03 24 05  BBS $24.0,$0DCE
0DC9: 24 D2     AND A,$D2
0DCB: C4 D2     MOV $D2,A
0DCD: 6F        RET
0DCE: 24 D3     AND A,$D3
0DD0: C4 D3     MOV $D3,A
0DD2: 6F        RET

MML_L_AutoPan:
0DD3: F5 70 02  MOV A,!$0270+X
0DD6: 68 40     CMP A,#40
0DD8: 90 05     BCC $0DDF
0DDA: 58 FF B4  EOR $B4,#FF
0DDD: AB B4     INC $B4
0DDF: E4 B4     MOV A,$B4
0DE1: D5 40 04  MOV !$0440+X,A
0DE4: 6F        RET

MML_Dollar_FIR:
0DE5: 3F 9C 13  CALL !ReadNumber
0DE8: 8D 00     MOV Y,#00
0DEA: F7 14     MOV A,[$14]+Y
0DEC: 68 2C     CMP A,#2C
0DEE: F0 28     BEQ $0E18
0DF0: 0B B4     ASL $B4                     ; $n: FIR preset n
0DF2: 0B B4     ASL $B4
0DF4: 0B B4     ASL $B4
0DF6: E8 3E     MOV A,#3E
0DF8: 60        CLRC
0DF9: 84 B4     ADC A,$B4
0DFB: C4 B4     MOV $B4,A
0DFD: E8 08     MOV A,#08
0DFF: 88 00     ADC A,#00
0E01: C4 B5     MOV $B5,A
0E03: 8D 00     MOV Y,#00
0E05: E8 0F     MOV A,#0F
0E07: 2D        PUSH A
0E08: C4 F2     MOV $F2,A
0E0A: F7 B4     MOV A,[$B4]+Y
0E0C: FC        INC Y
0E0D: C4 F3     MOV $F3,A
0E0F: AE        POP A
0E10: 60        CLRC
0E11: 88 10     ADC A,#10
0E13: 68 80     CMP A,#80
0E15: 90 F0     BCC $0E07
0E17: 6F        RET
0E18: 3A 14     INCW $14                    ; $r,v: write FIR coefficient r
0E1A: E4 B4     MOV A,$B4
0E1C: 2D        PUSH A
0E1D: 3F 9C 13  CALL !ReadNumber
0E20: AE        POP A
0E21: 9F        XCN A
0E22: 08 0F     OR A,#0F
0E24: FD        MOV Y,A
0E25: E4 B4     MOV A,$B4
0E27: 5F B1 09  JMP !WriteDSP

MML_Percent_Comment:
0E2A: 8D 00     MOV Y,#00
0E2C: F7 14     MOV A,[$14]+Y
0E2E: 3A 14     INCW $14
0E30: 68 25     CMP A,#25
0E32: D0 F8     BNE $0E2C
0E34: 6F        RET

MML_At_or_A:
0E35: 78 40 B2  CMP $B2,#40
0E38: F0 03     BEQ $0E3D
0E3A: 5F FC 0F  JMP !MML_Note
0E3D: 3F 9C 13  CALL !ReadNumber
0E40: E4 B4     MOV A,$B4
0E42: 75 50 02  CMP A,!$0250+X
0E45: D0 01     BNE $0E48
0E47: 6F        RET
0E48: D5 50 02  MOV !$0250+X,A
0E4B: 03 24 07  BBS $24.0,$0E55
0E4E: E4 2F     MOV A,$2F
0E50: 24 1E     AND A,$1E
0E52: F0 01     BEQ $0E55
0E54: 6F        RET
0E55: 5F D8 11  JMP !SetInstrument

MML_N_O:
0E58: 78 4F B2  CMP $B2,#4F
0E5B: D0 09     BNE $0E66
0E5D: 3F 9C 13  CALL !ReadNumber
0E60: E4 B4     MOV A,$B4
0E62: D5 40 02  MOV !$0240+X,A              ; O n
0E65: 6F        RET
0E66: 8F FF B4  MOV $B4,#FF                 ; N n: noise (no arg / 255 = off)
0E69: 3F 9F 13  CALL !ReadNumberDefault
0E6C: 78 FF B4  CMP $B4,#FF
0E6F: F0 16     BEQ $0E87
0E71: E4 B4     MOV A,$B4
0E73: 28 1F     AND A,#1F
0E75: 38 E0 CF  AND $CF,#E0
0E78: 04 CF     OR A,$CF
0E7A: C4 CF     MOV $CF,A
0E7C: 03 24 04  BBS $24.0,$0E83
0E7F: 09 1E D4  OR $D4,$1E
0E82: 6F        RET
0E83: 09 1E D5  OR $D5,$1E
0E86: 6F        RET
0E87: E4 1E     MOV A,$1E
0E89: 48 FF     EOR A,#FF
0E8B: 03 24 05  BBS $24.0,$0E93
0E8E: 24 D4     AND A,$D4
0E90: C4 D4     MOV $D4,A
0E92: 6F        RET
0E93: 24 D5     AND A,$D5
0E95: C4 D5     MOV $D5,A
0E97: 6F        RET

MML_P_Q:
0E98: 3F 9C 13  CALL !ReadNumber
0E9B: 78 51 B2  CMP $B2,#51
0E9E: D0 08     BNE $0EA8
0EA0: E4 B4     MOV A,$B4                   ; Q n: gate (n/16 of length, 0 = full)
0EA2: 28 0F     AND A,#0F
0EA4: D5 00 04  MOV !$0400+X,A
0EA7: 6F        RET
0EA8: F5 F0 03  MOV A,!$03F0+X
0EAB: C4 B2     MOV $B2,A
0EAD: E4 B4     MOV A,$B4
0EAF: D5 F0 03  MOV !$03F0+X,A              ; P n: portamento speed
0EB2: E4 B2     MOV A,$B2
0EB4: D0 14     BNE $0ECA
0EB6: F5 E0 03  MOV A,!$03E0+X
0EB9: D5 C0 03  MOV !$03C0+X,A
0EBC: F5 D0 03  MOV A,!$03D0+X
0EBF: D5 B0 03  MOV !$03B0+X,A
0EC2: F5 20 02  MOV A,!$0220+X
0EC5: 08 04     OR A,#04
0EC7: D5 20 02  MOV !$0220+X,A
0ECA: 6F        RET

MML_R_Rest:
0ECB: 8F 00 B2  MOV $B2,#00
0ECE: 8F 00 B3  MOV $B3,#00
0ED1: 5F 41 10  JMP !Note_Common

MML_T_Tempo:
0ED4: 3F 9C 13  CALL !ReadNumber
0ED7: 03 24 04  BBS $24.0,$0EDE
0EDA: E4 B4     MOV A,$B4
0EDC: C4 25     MOV $25,A
0EDE: 6F        RET

MML_V_Volume:
0EDF: 3F 9C 13  CALL !ReadNumber
0EE2: 5F C0 11  JMP !SetVolume

MML_Caret_VolStep:
0EE5: F5 30 02  MOV A,!$0230+X
0EE8: 13 B2 06  BBC $B2.0,$0EF1
0EEB: 28 0F     AND A,#0F
0EED: 9C        DEC A
0EEE: 10 04     BPL $0EF4
0EF0: 6F        RET
0EF1: BC        INC A
0EF2: 28 0F     AND A,#0F
0EF4: C4 B4     MOV $B4,A
0EF6: 5F C0 11  JMP !SetVolume

MML_Sharp:
0EF9: 3F D2 13  CALL !ReadChar
0EFC: 60        CLRC                        ; #X = table entry X+7
0EFD: 88 07     ADC A,#07
0EFF: C4 B2     MOV $B2,A
0F01: 5F FC 0F  JMP !MML_Note

MML_Amp_Tie:
0F04: F5 20 02  MOV A,!$0220+X
0F07: 08 01     OR A,#01                    ; flag bit0 = tie/slur next note
0F09: 2F 0C     BRA $0F17

MML_LBracket_Legato:
0F0B: F5 20 02  MOV A,!$0220+X
0F0E: 08 06     OR A,#06                    ; flag bits1,2 = legato block, retrigger first
0F10: 2F 05     BRA $0F17

MML_RBracket_EndLegato:
0F12: F5 20 02  MOV A,!$0220+X
0F15: 28 FD     AND A,#FD
0F17: D5 20 02  MOV !$0220+X,A
0F1A: 6F        RET

MML_Paren_Detune:
0F1B: 3F 9C 13  CALL !ReadNumber
0F1E: E4 B4     MOV A,$B4
0F20: D5 10 02  MOV !$0210+X,A
0F23: 6F        RET

MML_Plus_OctUp:
0F24: F5 40 02  MOV A,!$0240+X
0F27: BC        INC A
0F28: 2F 04     BRA $0F2E

MML_Minus_OctDown:
0F2A: F5 40 02  MOV A,!$0240+X
0F2D: 9C        DEC A
0F2E: 28 07     AND A,#07
0F30: D5 40 02  MOV !$0240+X,A
0F33: 6F        RET

MML_Pan:
0F34: E4 B2     MOV A,$B2
0F36: 48 03     EOR A,#03
0F38: BC        INC A
0F39: 28 03     AND A,#03
0F3B: D0 01     BNE $0F3E
0F3D: BC        INC A
0F3E: 68 03     CMP A,#03
0F40: F0 0C     BEQ $0F4E
0F42: 68 01     CMP A,#01
0F44: D0 04     BNE $0F4A
0F46: E8 7F     MOV A,#7F
0F48: 2F 0C     BRA $0F56
0F4A: E8 00     MOV A,#00
0F4C: 2F 08     BRA $0F56
0F4E: 8F 40 B4  MOV $B4,#40
0F51: 3F 9F 13  CALL !ReadNumberDefault
0F54: E4 B4     MOV A,$B4
0F56: D5 70 02  MOV !$0270+X,A
0F59: 80        SETC
0F5A: A8 40     SBC A,#40
0F5C: 10 03     BPL $0F61
0F5E: 48 FF     EOR A,#FF
0F60: BC        INC A
0F61: D5 30 04  MOV !$0430+X,A
0F64: E8 00     MOV A,#00
0F66: D5 40 04  MOV !$0440+X,A
0F69: D5 20 04  MOV !$0420+X,A
0F6C: 6F        RET

MML_EndOfPhrase:
0F6D: 13 24 17  BBC $24.0,Seq_PhraseRepeat
0F70: AE        POP A
0F71: AE        POP A

Sfx_Stop:
0F72: E4 1E     MOV A,$1E
0F74: 48 FF     EOR A,#FF
0F76: C4 B4     MOV $B4,A
0F78: 29 B4 2F  AND $2F,$B4
0F7B: 29 B4 D5  AND $D5,$B4
0F7E: 29 B4 D3  AND $D3,$B4
0F81: 29 B4 D1  AND $D1,$B4
0F84: 5F 95 13  JMP !KeyOffCurrent

Seq_PhraseRepeat:
0F87: F5 60 02  MOV A,!$0260+X
0F8A: 9C        DEC A
0F8B: D5 60 02  MOV !$0260+X,A
0F8E: F0 0B     BEQ Seq_NextOrderEntry
0F90: F4 80     MOV A,$80+X
0F92: FB 90     MOV Y,$90+X
0F94: D4 40     MOV $40+X,A
0F96: DB 50     MOV $50+X,Y
0F98: DA 14     MOVW $14,YA
0F9A: 6F        RET

Seq_NextOrderEntry:
0F9B: F4 60     MOV A,$60+X
0F9D: FB 70     MOV Y,$70+X
0F9F: DA B0     MOVW $B0,YA
0FA1: 8D 00     MOV Y,#00
0FA3: F7 B0     MOV A,[$B0]+Y
0FA5: 3A B0     INCW $B0
0FA7: C4 B4     MOV $B4,A
0FA9: F7 B0     MOV A,[$B0]+Y
0FAB: 3A B0     INCW $B0
0FAD: C4 B2     MOV $B2,A
0FAF: F7 B0     MOV A,[$B0]+Y
0FB1: 3A B0     INCW $B0
0FB3: C4 B3     MOV $B3,A
0FB5: 04 B2     OR A,$B2
0FB7: F0 EA     BEQ $0FA3
0FB9: E4 B4     MOV A,$B4
0FBB: D0 05     BNE $0FC2
0FBD: AE        POP A                       ; count 00: stop everything
0FBE: AE        POP A
0FBF: 5F 9D 12  JMP !StopAll
0FC2: BC        INC A
0FC3: D0 14     BNE $0FD9
0FC5: AE        POP A
0FC6: AE        POP A
0FC7: E4 1E     MOV A,$1E                   ; count FF: channel ends
0FC9: 48 FF     EOR A,#FF
0FCB: 24 2E     AND A,$2E
0FCD: C4 2E     MOV $2E,A
0FCF: E4 1E     MOV A,$1E
0FD1: 24 2F     AND A,$2F
0FD3: D0 03     BNE $0FD8
0FD5: 5F 95 13  JMP !KeyOffCurrent
0FD8: 6F        RET
0FD9: BC        INC A
0FDA: D0 0A     BNE $0FE6
0FDC: BA 12     MOVW YA,$12                 ; count FE: jump within order list
0FDE: 7A B2     ADDW YA,$B2
0FE0: 8F 01 22  MOV $22,#01
0FE3: 5F 9F 0F  JMP !$0F9F
0FE6: E4 B4     MOV A,$B4
0FE8: D5 60 02  MOV !$0260+X,A
0FEB: BA B0     MOVW YA,$B0
0FED: D4 60     MOV $60+X,A
0FEF: DB 70     MOV $70+X,Y
0FF1: BA B2     MOVW YA,$B2
0FF3: 7A 12     ADDW YA,$12
0FF5: D4 80     MOV $80+X,A
0FF7: DB 90     MOV $90+X,Y
0FF9: 5F 94 0F  JMP !$0F94

MML_Note:
0FFC: 80        SETC
0FFD: B8 41 B2  SBC $B2,#41                 ; index = (letter - A)
1000: 0B B2     ASL $B2
1002: EB B2     MOV Y,$B2
1004: F6 68 0B  MOV A,!NotePitchTable+Y
1007: C4 B2     MOV $B2,A
1009: F6 69 0B  MOV A,!$0B69+Y
100C: C4 B3     MOV $B3,A
100E: E8 06     MOV A,#06                   ; shift right by (6 - octave); O6 == O7
1010: 80        SETC
1011: B5 40 02  SBC A,!$0240+X
1014: 30 09     BMI $101F
1016: F0 07     BEQ $101F
1018: FD        MOV Y,A
1019: 4B B3     LSR $B3
101B: 6B B2     ROR $B2
101D: FE FA     DBNZ Y,$1019
101F: BA B2     MOVW YA,$B2
1021: AD 40     CMP Y,#40                   ; clamp to $3FFF
1023: 90 06     BCC $102B
1025: E8 FF     MOV A,#FF
1027: 8D 3F     MOV Y,#3F
1029: DA B2     MOVW $B2,YA
102B: D5 E0 03  MOV !$03E0+X,A
102E: DD        MOV A,Y
102F: D5 D0 03  MOV !$03D0+X,A
1032: F5 F0 03  MOV A,!$03F0+X
1035: D0 0A     BNE Note_Common
1037: F5 E0 03  MOV A,!$03E0+X
103A: D5 C0 03  MOV !$03C0+X,A
103D: DD        MOV A,Y
103E: D5 B0 03  MOV !$03B0+X,A

Note_Common:
1041: AE        POP A
1042: AE        POP A
1043: 3F 6C 11  CALL !ReadLength
1046: F5 20 02  MOV A,!$0220+X
1049: C4 27     MOV $27,A
104B: 28 EA     AND A,#EA
104D: D5 20 02  MOV !$0220+X,A
1050: 03 27 68  BBS $27.0,$10BB             ; tie: keep LFO phase
1053: F5 F0 03  MOV A,!$03F0+X
1056: D0 63     BNE $10BB
1058: 03 24 06  BBS $24.0,$1061
105B: E4 1E     MOV A,$1E
105D: 24 2F     AND A,$2F
105F: D0 07     BNE $1068
1061: E4 1E     MOV A,$1E
1063: 8D 5C     MOV Y,#5C
1065: 3F B1 09  CALL !WriteDSP
1068: 8D 00     MOV Y,#00
106A: F5 90 02  MOV A,!$0290+X
106D: 28 80     AND A,#80
106F: F0 0F     BEQ $1080
1071: F5 90 02  MOV A,!$0290+X
1074: 28 03     AND A,#03
1076: 68 02     CMP A,#02
1078: B0 01     BCS $107B
107A: FC        INC Y
107B: 68 03     CMP A,#03
107D: F0 01     BEQ $1080
107F: FC        INC Y
1080: E8 00     MOV A,#00
1082: FC        INC Y
1083: DC        DEC Y
1084: F0 0A     BEQ $1090
1086: F5 A0 02  MOV A,!$02A0+X
1089: DC        DEC Y
108A: F0 04     BEQ $1090
108C: 48 FF     EOR A,#FF
108E: BC        INC A
108F: FC        INC Y
1090: D5 E0 02  MOV !$02E0+X,A
1093: E8 00     MOV A,#00
1095: D5 F0 02  MOV !$02F0+X,A
1098: F5 00 03  MOV A,!$0300+X
109B: D5 D0 02  MOV !$02D0+X,A
109E: E8 00     MOV A,#00
10A0: FC        INC Y
10A1: DC        DEC Y
10A2: F0 09     BEQ $10AD
10A4: F5 20 03  MOV A,!$0320+X
10A7: DC        DEC Y
10A8: F0 03     BEQ $10AD
10AA: 48 FF     EOR A,#FF
10AC: BC        INC A
10AD: D5 60 03  MOV !$0360+X,A
10B0: E8 00     MOV A,#00
10B2: D5 70 03  MOV !$0370+X,A
10B5: F5 80 03  MOV A,!$0380+X
10B8: D5 50 03  MOV !$0350+X,A
10BB: E4 B2     MOV A,$B2
10BD: 04 B3     OR A,$B3
10BF: D0 09     BNE $10CA
10C1: E8 14     MOV A,#14                   ; rest: mark voice keyed-off
10C3: 15 20 02  OR A,!$0220+X
10C6: D5 20 02  MOV !$0220+X,A
10C9: 6F        RET
10CA: 03 24 07  BBS $24.0,$10D4
10CD: E4 1E     MOV A,$1E
10CF: 24 2F     AND A,$2F
10D1: F0 01     BEQ $10D4
10D3: 6F        RET
10D4: F5 C0 03  MOV A,!$03C0+X
10D7: C4 B2     MOV $B2,A
10D9: F5 B0 03  MOV A,!$03B0+X
10DC: C4 B3     MOV $B3,A
10DE: 43 27 08  BBS $27.2,$10E9
10E1: E4 27     MOV A,$27
10E3: 28 03     AND A,#03
10E5: 68 03     CMP A,#03
10E7: F0 1A     BEQ Note_SetVoiceRegs
10E9: F5 80 02  MOV A,!$0280+X
10EC: D4 A0     MOV $A0+X,A
10EE: 43 27 08  BBS $27.2,Note_KeyOn
10F1: 03 27 0F  BBS $27.0,Note_SetVoiceRegs
10F4: F5 F0 03  MOV A,!$03F0+X
10F7: D0 0A     BNE Note_SetVoiceRegs

Note_KeyOn:
10F9: 3F 03 11  CALL !Note_SetVoiceRegs
10FC: E4 1E     MOV A,$1E
10FE: 8D 4C     MOV Y,#4C                   ; KON
1100: 5F B1 09  JMP !WriteDSP

Note_SetVoiceRegs:
1103: E8 3D     MOV A,#3D
1105: 8D 5D     MOV Y,#5D
1107: 3F B1 09  CALL !WriteDSP
110A: 3F FC 11  CALL !WriteVoiceVolume
110D: E8 00     MOV A,#00
110F: 8D 5C     MOV Y,#5C
1111: 3F B1 09  CALL !WriteDSP
1114: 3F BB 0A  CALL !FX_ApplyPitch
1117: 7D        MOV A,X
1118: 28 07     AND A,#07
111A: 9F        XCN A
111B: 08 04     OR A,#04
111D: C4 B8     MOV $B8,A
111F: 8D 00     MOV Y,#00
1121: F7 B6     MOV A,[$B6]+Y               ; inst[0] -> SRCN
1123: FC        INC Y
1124: 3F 60 11  CALL !WriteDSP_Inc
1127: F7 B6     MOV A,[$B6]+Y               ; inst[1] -> ADSR1 (bit7 forced on)
1129: FC        INC Y
112A: 08 80     OR A,#80
112C: 3F 60 11  CALL !WriteDSP_Inc
112F: F7 B6     MOV A,[$B6]+Y               ; inst[2] -> ADSR2
1131: FC        INC Y
1132: 3F 60 11  CALL !WriteDSP_Inc
1135: E8 00     MOV A,#00                   ; GAIN = 0
1137: 3F 60 11  CALL !WriteDSP_Inc
113A: E4 2F     MOV A,$2F
113C: 48 FF     EOR A,#FF
113E: C4 B4     MOV $B4,A
1140: 24 D2     AND A,$D2
1142: C4 B5     MOV $B5,A
1144: E4 D3     MOV A,$D3
1146: 24 2F     AND A,$2F
1148: 04 B5     OR A,$B5
114A: 8D 2D     MOV Y,#2D                   ; PMON
114C: 3F B1 09  CALL !WriteDSP
114F: E4 B4     MOV A,$B4
1151: 24 D4     AND A,$D4
1153: C4 B5     MOV $B5,A
1155: E4 D5     MOV A,$D5
1157: 24 2F     AND A,$2F
1159: 04 B5     OR A,$B5
115B: 8D 3D     MOV Y,#3D                   ; NON
115D: 5F B1 09  JMP !WriteDSP

WriteDSP_Inc:
1160: 2D        PUSH A
1161: E4 B8     MOV A,$B8
1163: C4 F2     MOV $F2,A
1165: BC        INC A
1166: C4 B8     MOV $B8,A
1168: AE        POP A
1169: C4 F3     MOV $F3,A
116B: 6F        RET

ReadLength:
116C: F5 00 02  MOV A,!$0200+X
116F: C4 B4     MOV $B4,A
1171: 3F 9F 13  CALL !ReadNumberDefault
1174: E4 14     MOV A,$14
1176: D4 40     MOV $40+X,A
1178: E4 15     MOV A,$15
117A: D4 50     MOV $50+X,A
117C: E4 B4     MOV A,$B4
117E: D5 00 02  MOV !$0200+X,A              ; length becomes the new default (sticky)
1181: D0 01     BNE $1184
1183: BC        INC A
1184: D4 30     MOV $30+X,A
1186: FD        MOV Y,A
1187: F5 00 04  MOV A,!$0400+X
118A: F0 18     BEQ $11A4
118C: CF        MUL YA
118D: DA B6     MOVW $B6,YA
118F: 4B B7     LSR $B7
1191: 6B B6     ROR $B6
1193: 4B B7     LSR $B7
1195: 6B B6     ROR $B6
1197: 4B B7     LSR $B7
1199: 6B B6     ROR $B6
119B: 4B B7     LSR $B7
119D: 6B B6     ROR $B6
119F: E4 B6     MOV A,$B6
11A1: D0 01     BNE $11A4
11A3: BC        INC A
11A4: D5 10 04  MOV !$0410+X,A
11A7: 6F        RET

GetInstrumentPtr:
11A8: 8D 00     MOV Y,#00
11AA: F7 12     MOV A,[$12]+Y
11AC: C4 B6     MOV $B6,A
11AE: FC        INC Y
11AF: F7 12     MOV A,[$12]+Y
11B1: C4 B7     MOV $B7,A
11B3: 8D 0B     MOV Y,#0B                   ; entry = base + [base] + n*11
11B5: F5 50 02  MOV A,!$0250+X
11B8: CF        MUL YA
11B9: 7A B6     ADDW YA,$B6
11BB: 7A 12     ADDW YA,$12
11BD: DA B6     MOVW $B6,YA
11BF: 6F        RET

SetVolume:
11C0: E4 B4     MOV A,$B4
11C2: D5 30 02  MOV !$0230+X,A
11C5: 03 24 07  BBS $24.0,$11CF
11C8: E4 1E     MOV A,$1E
11CA: 24 2F     AND A,$2F
11CC: F0 01     BEQ $11CF
11CE: 6F        RET
11CF: 3F A8 11  CALL !GetInstrumentPtr
11D2: FA B4 B2  MOV $B2,$B4
11D5: 5F FC 11  JMP !WriteVoiceVolume

SetInstrument:
11D8: E4 1E     MOV A,$1E
11DA: 8D 5C     MOV Y,#5C
11DC: 3F B1 09  CALL !WriteDSP
11DF: 3F A8 11  CALL !GetInstrumentPtr
11E2: 8D 03     MOV Y,#03                   ; inst[3],[4] -> tremolo depth/period
11E4: 3F 4D 12  CALL !LFO_Setup
11E7: 7D        MOV A,X
11E8: 60        CLRC
11E9: 88 80     ADC A,#80
11EB: 4D        PUSH X
11EC: 5D        MOV X,A
11ED: 3F 4D 12  CALL !LFO_Setup             ; inst[5],[6] -> vibrato depth/period
11F0: CE        POP X
11F1: F7 B6     MOV A,[$B6]+Y               ; inst[7] -> LFO mode
11F3: D5 90 02  MOV !$0290+X,A
11F6: FC        INC Y
11F7: F7 B6     MOV A,[$B6]+Y               ; inst[8] -> vibrato delay
11F9: D5 80 02  MOV !$0280+X,A

WriteVoiceVolume:
11FC: F5 E0 02  MOV A,!$02E0+X
11FF: 10 03     BPL $1204
1201: 48 FF     EOR A,#FF
1203: BC        INC A
1204: C4 B8     MOV $B8,A
1206: F5 30 02  MOV A,!$0230+X
1209: FD        MOV Y,A
120A: F6 58 0B  MOV A,!VolumeTable+Y        ; base volume from VolumeTable[V]
120D: 60        CLRC
120E: 84 B8     ADC A,$B8
1210: 90 02     BCC $1214
1212: E8 FF     MOV A,#FF
1214: 2D        PUSH A
1215: FD        MOV Y,A
1216: F5 70 02  MOV A,!$0270+X
1219: 78 00 C3  CMP $C3,#00
121C: F0 02     BEQ $1220
121E: E8 40     MOV A,#40
1220: FD        MOV Y,A
1221: F6 84 0B  MOV A,!PanSineTable+Y       ; equal-power pan: L = vol*sin[pan]
1224: EE        POP Y
1225: 6D        PUSH Y
1226: CF        MUL YA
1227: 6D        PUSH Y
1228: 7D        MOV A,X
1229: 28 07     AND A,#07
122B: 9F        XCN A
122C: FD        MOV Y,A
122D: AE        POP A
122E: 3F B1 09  CALL !WriteDSP
1231: AE        POP A
1232: 6D        PUSH Y
1233: 2D        PUSH A
1234: E8 7F     MOV A,#7F
1236: 80        SETC
1237: B5 70 02  SBC A,!$0270+X
123A: 78 00 C3  CMP $C3,#00
123D: F0 02     BEQ $1241
123F: E8 40     MOV A,#40
1241: FD        MOV Y,A
1242: F6 84 0B  MOV A,!PanSineTable+Y       ; R = vol*sin[127-pan]
1245: EE        POP Y
1246: CF        MUL YA
1247: DD        MOV A,Y
1248: EE        POP Y
1249: FC        INC Y
124A: 5F B1 09  JMP !WriteDSP

LFO_Setup:
124D: 8F 00 BB  MOV $BB,#00
1250: 8F 00 BC  MOV $BC,#00
1253: F7 B6     MOV A,[$B6]+Y
1255: FC        INC Y
1256: C4 B9     MOV $B9,A
1258: F7 B6     MOV A,[$B6]+Y
125A: FC        INC Y
125B: C4 BA     MOV $BA,A
125D: E4 BA     MOV A,$BA
125F: F0 11     BEQ $1272
1261: E4 B9     MOV A,$B9
1263: F0 0D     BEQ $1272
1265: 6D        PUSH Y
1266: 4D        PUSH X
1267: 8D 00     MOV Y,#00
1269: F8 BA     MOV X,$BA
126B: 9E        DIV YA,X
126C: C4 BB     MOV $BB,A
126E: CB BC     MOV $BC,Y
1270: CE        POP X
1271: EE        POP Y
1272: E4 B9     MOV A,$B9
1274: D5 A0 02  MOV !$02A0+X,A
1277: E4 BA     MOV A,$BA
1279: D5 B0 02  MOV !$02B0+X,A
127C: 5C        LSR A
127D: D5 D0 02  MOV !$02D0+X,A
1280: D5 00 03  MOV !$0300+X,A
1283: E4 BC     MOV A,$BC
1285: D5 C0 02  MOV !$02C0+X,A
1288: E4 BB     MOV A,$BB
128A: D5 10 03  MOV !$0310+X,A
128D: E8 00     MOV A,#00
128F: D5 F0 02  MOV !$02F0+X,A
1292: D5 E0 02  MOV !$02E0+X,A
1295: 6F        RET

StopMusic:
1296: CD 00     MOV X,#00
1298: 8D 08     MOV Y,#08
129A: 5F AF 12  JMP !ResetChannels

StopAll:
129D: E8 00     MOV A,#00
129F: C4 DA     MOV $DA,A
12A1: C4 DC     MOV $DC,A
12A3: C4 2F     MOV $2F,A
12A5: C4 D1     MOV $D1,A
12A7: C4 D5     MOV $D5,A
12A9: C4 D3     MOV $D3,A
12AB: CD 00     MOV X,#00
12AD: 8D 10     MOV Y,#10

ResetChannels:
12AF: E8 01     MOV A,#01
12B1: D4 30     MOV $30+X,A
12B3: 9C        DEC A
12B4: D5 40 04  MOV !$0440+X,A
12B7: D5 30 04  MOV !$0430+X,A
12BA: D5 20 04  MOV !$0420+X,A
12BD: D4 40     MOV $40+X,A
12BF: D4 50     MOV $50+X,A
12C1: D4 60     MOV $60+X,A
12C3: D4 70     MOV $70+X,A
12C5: D4 80     MOV $80+X,A
12C7: D4 90     MOV $90+X,A
12C9: D4 A0     MOV $A0+X,A
12CB: D5 10 02  MOV !$0210+X,A
12CE: D5 20 02  MOV !$0220+X,A
12D1: D5 60 02  MOV !$0260+X,A
12D4: D5 80 02  MOV !$0280+X,A
12D7: D5 10 04  MOV !$0410+X,A
12DA: D5 00 04  MOV !$0400+X,A
12DD: D5 E0 03  MOV !$03E0+X,A
12E0: D5 D0 03  MOV !$03D0+X,A
12E3: D5 C0 03  MOV !$03C0+X,A
12E6: D5 B0 03  MOV !$03B0+X,A
12E9: D5 F0 03  MOV !$03F0+X,A
12EC: D5 A0 03  MOV !$03A0+X,A
12EF: D5 90 02  MOV !$0290+X,A
12F2: D5 A0 02  MOV !$02A0+X,A
12F5: D5 B0 02  MOV !$02B0+X,A
12F8: D5 C0 02  MOV !$02C0+X,A
12FB: D5 D0 02  MOV !$02D0+X,A
12FE: D5 E0 02  MOV !$02E0+X,A
1301: D5 F0 02  MOV !$02F0+X,A
1304: D5 00 03  MOV !$0300+X,A
1307: D5 10 03  MOV !$0310+X,A
130A: D5 20 03  MOV !$0320+X,A
130D: D5 30 03  MOV !$0330+X,A
1310: D5 40 03  MOV !$0340+X,A
1313: D5 50 03  MOV !$0350+X,A
1316: D5 60 03  MOV !$0360+X,A
1319: D5 70 03  MOV !$0370+X,A
131C: D5 80 03  MOV !$0380+X,A
131F: D5 90 03  MOV !$0390+X,A
1322: E8 10     MOV A,#10
1324: D5 00 02  MOV !$0200+X,A
1327: E8 40     MOV A,#40
1329: D5 70 02  MOV !$0270+X,A
132C: E8 0D     MOV A,#0D
132E: D5 30 02  MOV !$0230+X,A
1331: E8 04     MOV A,#04
1333: D5 40 02  MOV !$0240+X,A
1336: E8 80     MOV A,#80
1338: D5 50 02  MOV !$0250+X,A
133B: 3D        INC X
133C: DC        DEC Y
133D: F0 03     BEQ $1342
133F: 5F AF 12  JMP !ResetChannels
1342: 8F 40 D8  MOV $D8,#40
1345: 8F 40 DB  MOV $DB,#40
1348: E3 CE 02  BBS $CE.7,$134D
134B: 8B CE     DEC $CE
134D: E8 00     MOV A,#00
134F: C4 28     MOV $28,A
1351: C4 D7     MOV $D7,A
1353: C4 D9     MOV $D9,A
1355: C4 17     MOV $17,A
1357: C4 2E     MOV $2E,A
1359: C4 D0     MOV $D0,A
135B: C4 D4     MOV $D4,A
135D: C4 D2     MOV $D2,A
135F: C4 1A     MOV $1A,A
1361: C4 1B     MOV $1B,A
1363: C4 1C     MOV $1C,A
1365: C4 C0     MOV $C0,A
1367: C5 56 04  MOV !$0456,A
136A: E4 2F     MOV A,$2F
136C: 48 FF     EOR A,#FF
136E: 8D 5C     MOV Y,#5C
1370: 3F B1 09  CALL !WriteDSP
1373: E8 08     MOV A,#08
1375: 8D 00     MOV Y,#00
1377: 8F 01 1E  MOV $1E,#01
137A: 2D        PUSH A
137B: E4 2F     MOV A,$2F
137D: 24 1E     AND A,$1E
137F: D0 08     BNE $1389
1381: 3F B1 09  CALL !WriteDSP
1384: FC        INC Y
1385: 3F B1 09  CALL !WriteDSP
1388: DC        DEC Y
1389: DD        MOV A,Y
138A: 60        CLRC
138B: 88 10     ADC A,#10
138D: FD        MOV Y,A
138E: 0B 1E     ASL $1E
1390: AE        POP A
1391: 9C        DEC A
1392: D0 E6     BNE $137A
1394: 6F        RET

KeyOffCurrent:
1395: E4 1E     MOV A,$1E
1397: 8D 5C     MOV Y,#5C
1399: 5F B1 09  JMP !WriteDSP

ReadNumber:
139C: 8F 00 B4  MOV $B4,#00

ReadNumberDefault:
139F: 8D 00     MOV Y,#00
13A1: F7 14     MOV A,[$14]+Y
13A3: 68 30     CMP A,#30
13A5: 90 2A     BCC $13D1
13A7: 68 3A     CMP A,#3A
13A9: B0 26     BCS $13D1
13AB: CB B4     MOV $B4,Y
13AD: 2F 0C     BRA $13BB
13AF: 8D 00     MOV Y,#00
13B1: F7 14     MOV A,[$14]+Y
13B3: 68 30     CMP A,#30
13B5: 90 1A     BCC $13D1
13B7: 68 3A     CMP A,#3A
13B9: B0 16     BCS $13D1
13BB: 3A 14     INCW $14
13BD: 80        SETC                        ; decimal number parser
13BE: A8 30     SBC A,#30
13C0: 2D        PUSH A
13C1: E4 B4     MOV A,$B4
13C3: 1C        ASL A
13C4: 1C        ASL A
13C5: 84 B4     ADC A,$B4
13C7: 1C        ASL A
13C8: C4 B4     MOV $B4,A
13CA: AE        POP A
13CB: 84 B4     ADC A,$B4
13CD: C4 B4     MOV $B4,A
13CF: 2F DE     BRA $13AF
13D1: 6F        RET

ReadChar:
13D2: 8D 00     MOV Y,#00
13D4: F7 14     MOV A,[$14]+Y
13D6: 3A 14     INCW $14
13D8: 6F        RET

StartFade:
13D9: E4 1A     MOV A,$1A
13DB: D0 09     BNE $13E6
13DD: 8F 00 1B  MOV $1B,#00
13E0: 8F 00 1C  MOV $1C,#00
13E3: 8F FF 1A  MOV $1A,#FF
13E6: 6F        RET

StartSong:
13E7: E8 00     MOV A,#00
13E9: C4 28     MOV $28,A
13EB: FA 08 B0  MOV $B0,$08
13EE: FA 09 B1  MOV $B1,$09
13F1: FA B0 12  MOV $12,$B0
13F4: FA B1 13  MOV $13,$B1
13F7: E8 02     MOV A,#02
13F9: 8D 00     MOV Y,#00
13FB: 7A B0     ADDW YA,$B0
13FD: DA B2     MOVW $B2,YA
13FF: 8D 00     MOV Y,#00
1401: F7 B2     MOV A,[$B2]+Y               ; header byte 2 = channel enable mask
1403: 3A B2     INCW $B2
1405: C4 2E     MOV $2E,A
1407: 8F 01 1E  MOV $1E,#01
140A: CD 00     MOV X,#00
140C: 8D 08     MOV Y,#08
140E: 6D        PUSH Y
140F: 3F 25 14  CALL !StartSong_Channel
1412: 0B 1E     ASL $1E
1414: 3D        INC X
1415: EE        POP Y
1416: FE F6     DBNZ Y,$140E
1418: E8 7F     MOV A,#7F
141A: 8D 0C     MOV Y,#0C
141C: 3F B1 09  CALL !WriteDSP
141F: E8 1C     MOV A,#1C
1421: 3F B1 09  CALL !WriteDSP
1424: 6F        RET

StartSong_Channel:
1425: E4 1E     MOV A,$1E
1427: 24 2E     AND A,$2E
1429: F0 4B     BEQ $1476
142B: 8D 00     MOV Y,#00
142D: F7 B2     MOV A,[$B2]+Y
142F: C4 B4     MOV $B4,A
1431: FC        INC Y
1432: F7 B2     MOV A,[$B2]+Y
1434: C4 B5     MOV $B5,A
1436: BA B0     MOVW YA,$B0
1438: 7A B4     ADDW YA,$B4
143A: DA B4     MOVW $B4,YA
143C: 8D 00     MOV Y,#00
143E: F7 B4     MOV A,[$B4]+Y
1440: F0 2C     BEQ $146E
1442: BC        INC A
1443: F0 29     BEQ $146E
1445: 9C        DEC A
1446: D5 60 02  MOV !$0260+X,A
1449: 3A B4     INCW $B4
144B: F7 B4     MOV A,[$B4]+Y
144D: C4 B6     MOV $B6,A
144F: 3A B4     INCW $B4
1451: F7 B4     MOV A,[$B4]+Y
1453: C4 B7     MOV $B7,A
1455: 3A B4     INCW $B4
1457: E4 B4     MOV A,$B4
1459: D4 60     MOV $60+X,A
145B: E4 B5     MOV A,$B5
145D: D4 70     MOV $70+X,A
145F: BA B6     MOVW YA,$B6
1461: 7A B0     ADDW YA,$B0
1463: D4 80     MOV $80+X,A
1465: D4 40     MOV $40+X,A
1467: DD        MOV A,Y
1468: D4 90     MOV $90+X,A
146A: D4 50     MOV $50+X,A
146C: 2F 08     BRA $1476
146E: E4 1E     MOV A,$1E
1470: 48 FF     EOR A,#FF
1472: 24 2E     AND A,$2E
1474: C4 2E     MOV $2E,A
1476: 3A B2     INCW $B2
1478: 3A B2     INCW $B2
147A: 6F        RET

ResumeChannel:
147B: E4 1E     MOV A,$1E
147D: 8D 5C     MOV Y,#5C
147F: 3F B1 09  CALL !WriteDSP
1482: F5 50 02  MOV A,!$0250+X
1485: 1C        ASL A
1486: 90 01     BCC $1489
1488: 6F        RET
1489: F5 20 02  MOV A,!$0220+X
148C: 28 10     AND A,#10
148E: D0 F8     BNE $1488
1490: F5 C0 03  MOV A,!$03C0+X
1493: C4 B2     MOV $B2,A
1495: F5 B0 03  MOV A,!$03B0+X
1498: C4 B3     MOV $B3,A
149A: 5F F9 10  JMP !Note_KeyOn

BitTable:
149D:  db $01,$02,$04,$08,$10,$20,$40,$80

Sfx_Start:
14A5: FD        MOV Y,A
14A6: 60        CLRC
14A7: 88 08     ADC A,#08
14A9: 5D        MOV X,A
14AA: F6 9D 14  MOV A,!BitTable+Y
14AD: C4 1E     MOV $1E,A
14AF: 04 2F     OR A,$2F
14B1: C4 2F     MOV $2F,A
14B3: E5 54 04  MOV A,!$0454
14B6: D4 40     MOV $40+X,A
14B8: E5 55 04  MOV A,!$0455
14BB: D4 50     MOV $50+X,A
14BD: E8 01     MOV A,#01
14BF: D4 30     MOV $30+X,A
14C1: E8 20     MOV A,#20
14C3: D5 00 02  MOV !$0200+X,A
14C6: E8 0D     MOV A,#0D
14C8: D5 30 02  MOV !$0230+X,A
14CB: E8 04     MOV A,#04
14CD: D5 40 02  MOV !$0240+X,A
14D0: E8 40     MOV A,#40
14D2: D5 70 02  MOV !$0270+X,A
14D5: E8 00     MOV A,#00
14D7: D5 20 02  MOV !$0220+X,A
14DA: D5 10 02  MOV !$0210+X,A
14DD: D4 A0     MOV $A0+X,A
14DF: E8 80     MOV A,#80
14E1: D5 50 02  MOV !$0250+X,A
14E4: D8 B0     MOV $B0,X
14E6: 8F 00 B1  MOV $B1,#00
14E9: 60        CLRC
14EA: 98 90 B0  ADC $B0,#90
14ED: 98 02 B1  ADC $B1,#02
14F0: E8 1C     MOV A,#1C
14F2: 8D 00     MOV Y,#00
14F4: 2D        PUSH A
14F5: E8 00     MOV A,#00
14F7: D7 B0     MOV [$B0]+Y,A
14F9: 60        CLRC
14FA: 98 10 B0  ADC $B0,#10
14FD: 98 00 B1  ADC $B1,#00
1500: AE        POP A
1501: 9C        DEC A
1502: D0 F0     BNE $14F4
1504: 3F 95 13  CALL !KeyOffCurrent
1507: 6F        RET

IncPort0:
1508: E4 F4     MOV A,$F4
150A: BC        INC A
150B: C4 F4     MOV $F4,A
150D: 6F        RET
