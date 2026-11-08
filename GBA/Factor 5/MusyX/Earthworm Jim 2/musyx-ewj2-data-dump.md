# Earthworm Jim 2 (E) — MusyX GBA project data dump

Project base 0x0872AB74. All offsets below are relative to the project base unless written as full 0x08xxxxxx addresses.

## Header
```
+0x00  0x00020  objects (macros/keymaps)
+0x04  0x00D28  ADSR tables
+0x08  0x00D28  (unused, = ADSR off)
+0x0C  0x00D28  FX table
+0x10  0x00000  (unused)
+0x14  0x00000  (unused)
+0x18  0x00F64  songs
+0x1C  0x1AD18  samples
```

Counts: 126 objects, 71 FX, 11 songs, 125 samples.

## FX table
```
 fx  object prio  b3  chan  vol  pan  key
  0     70    10  255   any  127   64   60
  1     69    10  255   any  127   64   60
  2     68    10  255   any  127   64   60
  3     67    10  255   any  127   64   60
  4     66    10  255   any  127   64   60
  5     65    10  255   any  127   64   60
  6     64    10  255   any  127   64   60
  7     63    10  255   any  127   64   60
  8     62    10  255   any  127   64   60
  9     61    10  255   any  127   64   60
 10     60    10  255   any  127   64   60
 11     59    10  255   any  127   64   60
 12     58    10  255   any  127   64   60
 13     57    10  255   any  127   64   60
 14     56    10  255   any  127   64   60
 15      7    10  255   any  127   64   60
 16     55    10  255   any  127   64   60
 17     54    10  255   any  127   64   60
 18     53    10  255   any  127   64   60
 19     52    10  255   any  127   64   60
 20     51    10  255   any  127   64   60
 21     50    10  255   any  127   64   60
 22     49    10  255   any  127   64   60
 23     48    10  255   any  127   64   60
 24     47    10  255   any  127   64   60
 25     46    10  255   any  127   64   60
 26     45    10  255   any  127   64   60
 27     44    10  255   any  127   64   60
 28     43    10  255   any  127   64   60
 29     42    10  255   any  127   64   60
 30     41    10  255   any  127   64   60
 31     40    10  255   any  127   64   60
 32     39    10  255   any  127   64   60
 33     38    10  255   any  127   64   60
 34     37    10  255   any  127   64   60
 35     36    10  255   any  127   64   60
 36     35    10  255   any  127   64   60
 37     34    10  255   any  127   64   60
 38     33    10  255   any  127   64   60
 39     32    10  255   any  127   64   60
 40     31    10  255   any  127   64   60
 41     30    10  255   any  127   64   60
 42     29    10  255   any  127   64   60
 43     28    10  255   any  127   64   60
 44     27    10  255   any  127   64   60
 45     26    10  255   any  127   64   60
 46     25    10  255   any  127   64   60
 47     24    10  255   any  127   64   60
 48     23    10  255   any  127   64   60
 49     22    10  255   any  127   64   60
 50     21    10  255   any  127   64   60
 51     20    10  255   any  127   64   60
 52     19    10  255   any  127   64   60
 53     18    10  255   any  127   64   60
 54     17    10  255   any  127   64   60
 55     16    10  255   any  127   64   60
 56     15    10  255   any  127   64   60
 57     14    10  255   any  127   64   60
 58     13    10  255   any  127   64   60
 59     12    10  255   any  127   64   60
 60     11    10  255   any  127   64   60
 61     10    10  255   any  127   64   60
 62      9    10  255   any  127   64   60
 63      8    10  255   any  127   64   60
 64      6    10  255   any  127   64   60
 65      5    10  255   any  127   64   60
 66      4    10  255   any  127   64   60
 67      3    10  255   any  127   64   60
 68      2    10  255   any  127   64   60
 69      1    10  255   any  127   64   60
 70      0    10  255   any  127   64   60
```

## Samples
```
  #   offset    length  loopStart  rate(Hz) root type
  0  0x01AF0C    14304          -     11025   60  0
  1  0x01E6FC     9184          -     11025   60  0
  2  0x020AEC    15001          -      8000   60  0
  3  0x024598    14720          -      8000   60  0
  4  0x027F28     1417          -      8000   60  0
  5  0x0284C4     5144          -      8000   60  0
  6  0x0298EC    10320          -     22050   60  0
  7  0x02C14C      864          0     11025   60  0
  8  0x02C4BC     1952          -      8000   60  0
  9  0x02CC6C     5040          -      8000   60  0
 10  0x02E02C     3072          -      8000   60  0
 11  0x02EC3C     4768          -      8000   60  0
 12  0x02FEEC     1136          -      8000   60  0
 13  0x03036C     4000          -      8000   60  0
 14  0x03131C     8352          -      8000   60  0
 15  0x0333CC     4432          -      8000   60  0
 16  0x03452C     1328          -      8000   60  0
 17  0x034A6C     4944          -      8000   60  0
 18  0x035DCC     1696          -      8000   60  0
 19  0x03647C     3424          -      8000   60  0
 20  0x0371EC     1632          -      8000   60  0
 21  0x03785C     2144          -      8000   60  0
 22  0x0380CC     4176          -      8000   60  0
 23  0x03912C     3792          -      8000   60  0
 24  0x03A00C     8256          -      8000   60  0
 25  0x03C05C     1888          -      8000   60  0
 26  0x03C7CC     6592          -      8000   60  0
 27  0x03E19C     5824          -      8000   60  0
 28  0x03F86C     2880          -      8000   60  0
 29  0x0403BC     1904          -      8000   60  0
 30  0x040B3C     3760          -      8000   60  0
 31  0x0419FC     2176          -      8000   60  0
 32  0x04228C     3088          -      8000   60  0
 33  0x042EAC     1360          -      8000   60  0
 34  0x04340C     5506          -      8000   60  0
 35  0x0449A0     8256          -      8000   60  0
 36  0x0469F0     5520          -      8000   60  0
 37  0x047F90     9616          -      8000   60  0
 38  0x04A530     3840          -      8000   60  0
 39  0x04B440     4752          -      8000   60  0
 40  0x04C6E0     3920          -      8000   60  0
 41  0x04D640     4592          -      8000   60  0
 42  0x04E840     5760          -      8000   60  0
 43  0x04FED0     5904          -      8000   60  0
 44  0x0515F0     7536          -      8000   60  0
 45  0x053370     7360          -      8000   60  0
 46  0x055040    11264          -      8000   60  0
 47  0x057C50     3200          -      8000   60  0
 48  0x0588E0     4432          -      8000   60  0
 49  0x059A40     7968          -      8000   60  0
 50  0x05B970     5488          -      8000   60  0
 51  0x05CEF0    10688          -      8000   60  0
 52  0x05F8C0     4560          -      8000   60  0
 53  0x060AA0     9776          -      8000   60  0
 54  0x0630E0     1888          -      8000   60  0
 55  0x063850     4144          -      8000   60  0
 56  0x064890     4976          -      8000   60  0
 57  0x065C10     4208          -      8000   60  0
 58  0x066C90     1376          -      8000   60  0
 59  0x067200     2560          -      8000   60  0
 60  0x067C10     4944          -      8000   60  0
 61  0x068F70      976          -      8000   60  0
 62  0x069350     3728          -      8000   60  0
 63  0x06A1F0    15408          -      8000   60  0
 64  0x06DE30     3104          -      8000   60  0
 65  0x06EA60     8672          -      8000   60  0
 66  0x070C50     5760          -      8000   60  0
 67  0x0722E0     3040          -      8000   60  0
 68  0x072ED0     4656          -      8000   60  0
 69  0x074110     4192          -      8000   60  0
 70  0x075180     6432          -      8000   60  0
 71  0x076AB0     3600          -     12032   60  0
 72  0x0778D0     3520          -     12032   60  0
 73  0x0786A0     3408          -     10368   60  0
 74  0x079400     3104          -     10112   60  0
 75  0x07A030     5664       3328      8288   60  0
 76  0x07B660     1136       1088     12544   60  0
 77  0x07BAE0     8896        544     11760   60  0
 78  0x07DDB0     2448          -     12032   60  0
 79  0x07E750       48         16     16144   60  0
 80  0x07E790     1296       1200      9616   60  0
 81  0x07ECB0     1744       1696     38360   60  0
 82  0x07F390     4448       3984     36816   60  0
 83  0x080500      112         64     24232   60  0
 84  0x080580     5856          -     10248   60  0
 85  0x081C70     2176       1648      3328   60  0
 86  0x082500    11568          -     13608   60  0
 87  0x085240     3520          -     12288   60  0
 88  0x086010     3600          -     12248   60  0
 89  0x086E30     3408          -      8496   60  0
 90  0x087B90     3104          -     10104   60  0
 91  0x0887C0     2721          -     20736   60  0
 92  0x089274     8896        544     26208   60  0
 93  0x08B544     2560       2512     47952   60  0
 94  0x08BF54     1280       1232     49280   60  0
 95  0x08C464     1968       1584     16080   60  0
 96  0x08CC24    67968          -     22050   60  0
 97  0x09D5B4    38976          -     22050   60  0
 98  0x0A6E04    14402          -     44100   60  0
 99  0x0AA658    65980          -     44100   60  0
100  0x0BA824     4000          -     14304   60  0
101  0x0BB7D4     1760          -     12696   60  0
102  0x0BBEC4     3504          -     49920   60  0
103  0x0BCC84     1792          -     32680   60  0
104  0x0BD394     2128          -      9048   60  0
105  0x0BDBF4     2400       2288     37312   60  0
106  0x0BE564      496        240     16952   60  0
107  0x0BE764     2400       2352     22872   60  0
108  0x0BF0D4     2176       1648     21888   60  0
109  0x0BF964     4192          -     16640   60  0
110  0x0C09D4     4160          -     23712   60  0
111  0x0C1A24     1056        832      2368   60  0
112  0x0C1E54     2320          -     10112   60  0
113  0x0C2774     4272       3440     28072   60  0
114  0x0C3834     6400       4048     11192   60  0
115  0x0C5144    11168          -     18176   60  0
116  0x0C7CF4    12800          -     12544   60  0
117  0x0CAF04     7040          -     22272   60  0
118  0x0CCA94     6416          -     13568   60  0
119  0x0CE3B4     2256          -     12544   60  0
120  0x0CEC94     2416          -     12032   60  0
121  0x0CF614     2704          -     12248   60  0
122  0x0D00B4     2480          -     12192   60  0
123  0x0D0A74     7376          -     15240   60  0
124  0x0D2754    10640          -     12288   60  0
```

## Songs
### Song 0  (offset 0x00F94)
```
initial BPM 107, 7 patterns
program map  : p0->obj74(pri 0), p1->obj73(pri 0), p2->obj72(pri 0), p3->obj71(pri 0), p4->obj77(pri 0), p5->obj76(pri 0), p6->obj75(pri 0)
track  4: +0 pat0  +25343 LOOP->entry0 (+0)
track  6: +0 pat1  +25343 LOOP->entry0 (+0)
track  7: +0 pat2  +25343 LOOP->entry0 (+0)
track  8: +0 pat3  +25343 LOOP->entry0 (+0)
track 10: +0 pat4  +25343 LOOP->entry0 (+0)
track 12: +0 pat5  +25343 LOOP->entry0 (+0)
track 16 (tempo): +0 pat6  +25343 LOOP->entry0 (+0)
notes 838, length 25343 ticks (148.0 s at initial tempo), loop 0-25343
```
### Song 1  (offset 0x02888)
```
initial BPM 200, 9 patterns
program map  : p0->obj83(pri 0), p1->obj82(pri 0), p2->obj81(pri 0), p3->obj80(pri 0), p4->obj79(pri 0), p5->obj78(pri 0)
track  6: +0 pat0  +1695 pat1  +28376 LOOP->entry1 (+15)
track  7: +0 pat2  +1692 pat3  +28379 LOOP->entry1 (+12)
track  8: +0 pat4  +1695 pat5  +28376 LOOP->entry1 (+15)
track 10: +0 pat6  +1764 pat7  +28307 LOOP->entry1 (+84)
track 16 (tempo): +0 pat8  +30071 END
notes 2178, length 67191 ticks (210.0 s at initial tempo), loop 1680-30071
```
### Song 2  (offset 0x060E4)
```
initial BPM 130, 3 patterns
program map  : p0->obj84(pri 0), p1->obj85(pri 0)
track  4: +0 pat0  +7556 LOOP->entry0 (+0)
track  5: +0 pat1  +7556 LOOP->entry0 (+0)
track 16 (tempo): +0 pat2  +7556 LOOP->entry0 (+0)
notes 365, length 7805 ticks (37.5 s at initial tempo), loop 0-7556
```
### Song 3  (offset 0x06E3C)
```
initial BPM 250, 11 patterns
program map  : p0->obj90(pri 0), p1->obj89(pri 0), p2->obj88(pri 0), p3->obj87(pri 0), p4->obj86(pri 0), p6->obj91(pri 0), p7->obj95(pri 0), p8->obj94(pri 0), p9->obj93(pri 0), p10->obj92(pri 0)
track  4: +0 pat0  +42841 LOOP->entry0 (+0)
track  5: +0 pat1  +42841 LOOP->entry0 (+0)
track  6: +0 pat2  +42841 LOOP->entry0 (+0)
track  7: +0 pat3  +42841 LOOP->entry0 (+0)
track  8: +0 pat4  +42841 LOOP->entry0 (+0)
track 11: +0 pat5  +42841 LOOP->entry0 (+0)
track 12: +0 pat6  +42841 LOOP->entry0 (+0)
track 13: +0 pat7  +42841 LOOP->entry0 (+0)
track 14: +0 pat8  +42841 LOOP->entry0 (+0)
track 15: +0 pat9  +42841 LOOP->entry0 (+0)
track 16 (tempo): +0 pat10  +42841 LOOP->entry0 (+0)
notes 1467, length 43108 ticks (107.8 s at initial tempo), loop 0-42841
```
### Song 4  (offset 0x09678)
```
initial BPM 120, 3 patterns
program map  : p0->obj96(pri 0)
track  4: +0 pat0  +12 pat1  +50379 LOOP->entry1 (+1)
track 16 (tempo): +0 pat2  +50391 END
notes 1146, length 50391 ticks (262.5 s at initial tempo), loop 11-50391
```
### Song 5  (offset 0x0B600)
```
initial BPM 120, 9 patterns
program map  : p0->obj96(pri 0), p1->obj98(pri 0), p2->obj99(pri 0), p3->obj97(pri 0), p32->obj97(pri 0)
track  4: +0 pat0  +9 pat1  +20726 LOOP->entry1 (+0)
track  5: +0 pat2  +9 pat3  +20726 LOOP->entry1 (+0)
track  6: +0 pat4  +57 pat5  +20678 LOOP->entry1 (+48)
track  7: +0 pat6  +291 pat7  +20444 LOOP->entry1 (+282)
track 16 (tempo): +0 pat8  +20735 END
notes 1598, length 20735 ticks (108.0 s at initial tempo), loop 9-20735
```
### Song 6  (offset 0x0E0BC)
```
initial BPM 120, 20 patterns
program map  : p0->obj106(pri 0), p1->obj105(pri 0), p2->obj104(pri 0), p3->obj100(pri 0), p4->obj103(pri 0), p5->obj102(pri 0), p6->obj101(pri 0), p7->obj108(pri 0), p8->obj107(pri 0)
track  0 (PSG): +0 pat0  +28363 END
track  4: +0 pat1  +1022 pat2  +27341 LOOP->entry1 (+48)
track  5: +0 pat3  +26982 pat4  +1381 LOOP->entry1 (+26008)
track  6: +0 pat5  +1022 pat6  +27341 LOOP->entry1 (+48)
track  7: +0 pat7  +7498 pat8  +20865 LOOP->entry1 (+6524)
track  8: +0 pat9  +1022 pat10  +27341 LOOP->entry1 (+48)
track 10: +0 pat11  +14348 pat12  +14015 LOOP->entry1 (+13374)
track 11: +0 pat13  +26808 pat14  +1555 LOOP->entry1 (+25834)
track 12: +0 pat15  +1022 pat16  +27341 LOOP->entry1 (+48)
track 13: +0 pat17  +994 pat18  +27369 LOOP->entry1 (+20)
track 16 (tempo): +0 pat19  +28363 END
notes 3305, length 66503 ticks (346.4 s at initial tempo), loop 974-28363
```
### Song 7  (offset 0x13498)
```
initial BPM 135, 7 patterns
program map  : p0->obj111(pri 0), p1->obj109(pri 0), p3->obj110(pri 0)
track  4: +0 pat0  +372 pat1  +7856 LOOP->entry1 (+16)
track  5: +0 pat2  +398 pat3  +7830 LOOP->entry1 (+42)
track  7: +0 pat4  +358 pat5  +7870 LOOP->entry1 (+2)
track 16 (tempo): +0 pat6  +8228 END
notes 506, length 65853 ticks (304.9 s at initial tempo), loop 356-8228
```
### Song 8  (offset 0x14590)
```
initial BPM 200, 7 patterns
program map  : p0->obj114(pri 0), p1->obj113(pri 0), p2->obj112(pri 0)
track  4: +0 pat0  +1599 pat1  +35327 LOOP->entry1 (+0)
track  5: +0 pat2  +1602 pat3  +35324 LOOP->entry1 (+3)
track  6: +0 pat4  +1599 pat5  +35327 LOOP->entry1 (+0)
track 16 (tempo): +0 pat6  +36926 END
notes 942, length 66138 ticks (206.7 s at initial tempo), loop 1599-36926
```
### Song 9  (offset 0x160C0)
```
initial BPM 165, 4 patterns
program map  : p0->obj115(pri 0), p1->obj96(pri 0)
track  4: +0 pat0  +5 pat1  +24186 LOOP->entry1 (+0)
track 16 (tempo): +0 pat2  +768 pat3  +23423 LOOP->entry1 (+763)
notes 1604, length 24196 ticks (91.7 s at initial tempo), loop 5-24191
```
### Song 10  (offset 0x18B24)
```
initial BPM 120, 21 patterns
program map  : p0->obj122(pri 0), p1->obj121(pri 0), p2->obj120(pri 0), p3->obj119(pri 0), p4->obj118(pri 0), p5->obj117(pri 0), p6->obj116(pri 0), p7->obj124(pri 0), p8->obj123(pri 0), p9->obj125(pri 0)
track  4: +0 pat0  +64 pat1  +16952 LOOP->entry1 (+0)
track  5: +0 pat2  +64 pat3  +16952 LOOP->entry1 (+0)
track  6: +0 pat4  +64 pat5  +16952 LOOP->entry1 (+0)
track  7: +0 pat6  +64 pat7  +16952 LOOP->entry1 (+0)
track  8: +0 pat8  +2326 pat9  +14690 LOOP->entry1 (+2262)
track 10: +0 pat10  +276 pat11  +16740 LOOP->entry1 (+212)
track 11: +0 pat12  +842 pat13  +16174 LOOP->entry1 (+778)
track 12: +0 pat14  +560 pat15  +16456 LOOP->entry1 (+496)
track 13: +0 pat16  +64 pat17  +16952 LOOP->entry1 (+0)
track 14: +0 pat18  +630 pat19  +16386 LOOP->entry1 (+566)
track 16 (tempo): +0 pat20  +17016 END
notes 1172, length 17091 ticks (89.0 s at initial tempo), loop 64-17016
```

## Objects (macros and keymaps)
```
OBJ   0 @00218 MACRO chan=any flags=00
   0021C  STARTSAMPLE    0,0,0                   
   00224  KEYON          0                       
   00226  WAIT           4,-1                    
   0022A  END                                    
OBJ   1 @0022C MACRO chan=any flags=00
   00230  STARTSAMPLE    0,1,0                   
   00238  KEYON          0                       
   0023A  WAIT           4,-1                    
   0023E  END                                    
OBJ   2 @00240 MACRO chan=any flags=00
   00244  STARTSAMPLE    0,2,0                   
   0024C  KEYON          0                       
   0024E  WAIT           4,-1                    
   00252  END                                    
OBJ   3 @00254 MACRO chan=any flags=00
   00258  STARTSAMPLE    0,3,0                   
   00260  KEYON          0                       
   00262  WAIT           4,-1                    
   00266  END                                    
OBJ   4 @00268 MACRO chan=any flags=00
   0026C  STARTSAMPLE    0,4,0                   
   00274  KEYON          0                       
   00276  WAIT           4,-1                    
   0027A  END                                    
OBJ   5 @0027C MACRO chan=any flags=00
   00280  STARTSAMPLE    0,5,0                   
   00288  KEYON          0                       
   0028A  WAIT           4,-1                    
   0028E  END                                    
OBJ   6 @00290 MACRO chan=any flags=00
   00294  STARTSAMPLE    0,6,0                   
   0029C  KEYON          0                       
   0029E  WAIT           4,-1                    
   002A2  END                                    
OBJ   7 @002A4 MACRO chan=any flags=00
   002A8  STARTSAMPLE    0,7,0                   
   002B0  KEYON          0                       
   002B2  WAIT           1,-1                    
   002B6  SILENCE        0                       
   002B8  END                                    
OBJ   8 @002BC MACRO chan=any flags=00
   002C0  STARTSAMPLE    0,8,0                   
   002C8  KEYON          0                       
   002CA  WAIT           4,-1                    
   002CE  END                                    
OBJ   9 @002D0 MACRO chan=any flags=00
   002D4  STARTSAMPLE    0,9,0                   
   002DC  KEYON          0                       
   002DE  WAIT           4,-1                    
   002E2  END                                    
OBJ  10 @002E4 MACRO chan=any flags=00
   002E8  STARTSAMPLE    0,10,0                  
   002F0  KEYON          0                       
   002F2  WAIT           4,-1                    
   002F6  END                                    
OBJ  11 @002F8 MACRO chan=any flags=00
   002FC  STARTSAMPLE    0,11,0                  
   00304  KEYON          0                       
   00306  WAIT           4,-1                    
   0030A  END                                    
OBJ  12 @0030C MACRO chan=any flags=00
   00310  STARTSAMPLE    0,12,0                  
   00318  KEYON          0                       
   0031A  WAIT           4,-1                    
   0031E  END                                    
OBJ  13 @00320 MACRO chan=any flags=00
   00324  STARTSAMPLE    0,13,0                  
   0032C  KEYON          0                       
   0032E  WAIT           4,-1                    
   00332  END                                    
OBJ  14 @00334 MACRO chan=any flags=00
   00338  STARTSAMPLE    0,14,0                  
   00340  KEYON          0                       
   00342  WAIT           4,-1                    
   00346  END                                    
OBJ  15 @00348 MACRO chan=any flags=00
   0034C  STARTSAMPLE    0,15,0                  
   00354  KEYON          0                       
   00356  WAIT           4,-1                    
   0035A  END                                    
OBJ  16 @0035C MACRO chan=any flags=00
   00360  STARTSAMPLE    0,16,0                  
   00368  KEYON          0                       
   0036A  WAIT           4,-1                    
   0036E  END                                    
OBJ  17 @00370 MACRO chan=any flags=00
   00374  STARTSAMPLE    0,17,0                  
   0037C  KEYON          0                       
   0037E  WAIT           4,-1                    
   00382  END                                    
OBJ  18 @00384 MACRO chan=any flags=00
   00388  STARTSAMPLE    0,18,0                  
   00390  KEYON          0                       
   00392  WAIT           4,-1                    
   00396  END                                    
OBJ  19 @00398 MACRO chan=any flags=00
   0039C  STARTSAMPLE    0,19,0                  
   003A4  KEYON          0                       
   003A6  WAIT           4,-1                    
   003AA  END                                    
OBJ  20 @003AC MACRO chan=any flags=00
   003B0  STARTSAMPLE    0,20,0                  
   003B8  KEYON          0                       
   003BA  WAIT           4,-1                    
   003BE  END                                    
OBJ  21 @003C0 MACRO chan=any flags=00
   003C4  STARTSAMPLE    0,21,0                  
   003CC  KEYON          0                       
   003CE  WAIT           4,-1                    
   003D2  END                                    
OBJ  22 @003D4 MACRO chan=any flags=00
   003D8  STARTSAMPLE    0,22,0                  
   003E0  KEYON          0                       
   003E2  WAIT           4,-1                    
   003E6  END                                    
OBJ  23 @003E8 MACRO chan=any flags=00
   003EC  STARTSAMPLE    0,23,0                  
   003F4  KEYON          0                       
   003F6  WAIT           4,-1                    
   003FA  END                                    
OBJ  24 @003FC MACRO chan=any flags=00
   00400  STARTSAMPLE    0,24,0                  
   00408  KEYON          0                       
   0040A  WAIT           4,-1                    
   0040E  END                                    
OBJ  25 @00410 MACRO chan=any flags=00
   00414  STARTSAMPLE    0,25,0                  
   0041C  KEYON          0                       
   0041E  WAIT           4,-1                    
   00422  END                                    
OBJ  26 @00424 MACRO chan=any flags=00
   00428  STARTSAMPLE    0,26,0                  
   00430  KEYON          0                       
   00432  WAIT           4,-1                    
   00436  END                                    
OBJ  27 @00438 MACRO chan=any flags=00
   0043C  STARTSAMPLE    0,27,0                  
   00444  KEYON          0                       
   00446  WAIT           4,-1                    
   0044A  END                                    
OBJ  28 @0044C MACRO chan=any flags=00
   00450  STARTSAMPLE    0,28,0                  
   00458  KEYON          0                       
   0045A  WAIT           4,-1                    
   0045E  END                                    
OBJ  29 @00460 MACRO chan=any flags=00
   00464  STARTSAMPLE    0,29,0                  
   0046C  KEYON          0                       
   0046E  WAIT           4,-1                    
   00472  END                                    
OBJ  30 @00474 MACRO chan=any flags=00
   00478  STARTSAMPLE    0,30,0                  
   00480  KEYON          0                       
   00482  WAIT           4,-1                    
   00486  END                                    
OBJ  31 @00488 MACRO chan=any flags=00
   0048C  STARTSAMPLE    0,31,0                  
   00494  KEYON          0                       
   00496  WAIT           4,-1                    
   0049A  END                                    
OBJ  32 @0049C MACRO chan=any flags=00
   004A0  STARTSAMPLE    0,32,0                  
   004A8  KEYON          0                       
   004AA  WAIT           4,-1                    
   004AE  END                                    
OBJ  33 @004B0 MACRO chan=any flags=00
   004B4  STARTSAMPLE    0,33,0                  
   004BC  KEYON          0                       
   004BE  WAIT           4,-1                    
   004C2  END                                    
OBJ  34 @004C4 MACRO chan=any flags=00
   004C8  STARTSAMPLE    0,34,0                  
   004D0  KEYON          0                       
   004D2  WAIT           4,-1                    
   004D6  END                                    
OBJ  35 @004D8 MACRO chan=any flags=00
   004DC  STARTSAMPLE    0,35,0                  
   004E4  KEYON          0                       
   004E6  WAIT           4,-1                    
   004EA  END                                    
OBJ  36 @004EC MACRO chan=any flags=00
   004F0  STARTSAMPLE    0,36,0                  
   004F8  KEYON          0                       
   004FA  WAIT           4,-1                    
   004FE  END                                    
OBJ  37 @00500 MACRO chan=any flags=00
   00504  STARTSAMPLE    0,37,0                  
   0050C  KEYON          0                       
   0050E  WAIT           4,-1                    
   00512  END                                    
OBJ  38 @00514 MACRO chan=any flags=00
   00518  STARTSAMPLE    0,38,0                  
   00520  KEYON          0                       
   00522  WAIT           4,-1                    
   00526  END                                    
OBJ  39 @00528 MACRO chan=any flags=00
   0052C  STARTSAMPLE    0,39,0                  
   00534  KEYON          0                       
   00536  WAIT           4,-1                    
   0053A  END                                    
OBJ  40 @0053C MACRO chan=any flags=00
   00540  STARTSAMPLE    0,40,0                  
   00548  KEYON          0                       
   0054A  WAIT           4,-1                    
   0054E  END                                    
OBJ  41 @00550 MACRO chan=any flags=00
   00554  STARTSAMPLE    0,41,0                  
   0055C  KEYON          0                       
   0055E  WAIT           4,-1                    
   00562  END                                    
OBJ  42 @00564 MACRO chan=any flags=00
   00568  STARTSAMPLE    0,42,0                  
   00570  KEYON          0                       
   00572  WAIT           4,-1                    
   00576  END                                    
OBJ  43 @00578 MACRO chan=any flags=00
   0057C  STARTSAMPLE    0,43,0                  
   00584  KEYON          0                       
   00586  WAIT           4,-1                    
   0058A  END                                    
OBJ  44 @0058C MACRO chan=any flags=00
   00590  STARTSAMPLE    0,44,0                  
   00598  KEYON          0                       
   0059A  WAIT           4,-1                    
   0059E  END                                    
OBJ  45 @005A0 MACRO chan=any flags=00
   005A4  STARTSAMPLE    0,45,0                  
   005AC  KEYON          0                       
   005AE  WAIT           4,-1                    
   005B2  END                                    
OBJ  46 @005B4 MACRO chan=any flags=00
   005B8  STARTSAMPLE    0,46,0                  
   005C0  KEYON          0                       
   005C2  WAIT           4,-1                    
   005C6  END                                    
OBJ  47 @005C8 MACRO chan=any flags=00
   005CC  STARTSAMPLE    0,47,0                  
   005D4  KEYON          0                       
   005D6  WAIT           4,-1                    
   005DA  END                                    
OBJ  48 @005DC MACRO chan=any flags=00
   005E0  STARTSAMPLE    0,48,0                  
   005E8  KEYON          0                       
   005EA  WAIT           4,-1                    
   005EE  END                                    
OBJ  49 @005F0 MACRO chan=any flags=00
   005F4  STARTSAMPLE    0,49,0                  
   005FC  KEYON          0                       
   005FE  WAIT           4,-1                    
   00602  END                                    
OBJ  50 @00604 MACRO chan=any flags=00
   00608  STARTSAMPLE    0,50,0                  
   00610  KEYON          0                       
   00612  WAIT           4,-1                    
   00616  END                                    
OBJ  51 @00618 MACRO chan=any flags=00
   0061C  STARTSAMPLE    0,51,0                  
   00624  KEYON          0                       
   00626  WAIT           4,-1                    
   0062A  END                                    
OBJ  52 @0062C MACRO chan=any flags=00
   00630  STARTSAMPLE    0,52,0                  
   00638  KEYON          0                       
   0063A  WAIT           4,-1                    
   0063E  END                                    
OBJ  53 @00640 MACRO chan=any flags=00
   00644  STARTSAMPLE    0,53,0                  
   0064C  KEYON          0                       
   0064E  WAIT           4,-1                    
   00652  END                                    
OBJ  54 @00654 MACRO chan=any flags=00
   00658  STARTSAMPLE    0,54,0                  
   00660  KEYON          0                       
   00662  WAIT           4,-1                    
   00666  END                                    
OBJ  55 @00668 MACRO chan=any flags=00
   0066C  STARTSAMPLE    0,55,0                  
   00674  KEYON          0                       
   00676  WAIT           4,-1                    
   0067A  END                                    
OBJ  56 @0067C MACRO chan=any flags=00
   00680  STARTSAMPLE    0,56,0                  
   00688  KEYON          0                       
   0068A  WAIT           4,-1                    
   0068E  END                                    
OBJ  57 @00690 MACRO chan=any flags=00
   00694  STARTSAMPLE    0,57,0                  
   0069C  KEYON          0                       
   0069E  WAIT           4,-1                    
   006A2  END                                    
OBJ  58 @006A4 MACRO chan=any flags=00
   006A8  STARTSAMPLE    0,58,0                  
   006B0  KEYON          0                       
   006B2  WAIT           4,-1                    
   006B6  END                                    
OBJ  59 @006B8 MACRO chan=any flags=00
   006BC  STARTSAMPLE    0,59,0                  
   006C4  KEYON          0                       
   006C6  WAIT           4,-1                    
   006CA  END                                    
OBJ  60 @006CC MACRO chan=any flags=00
   006D0  STARTSAMPLE    0,60,0                  
   006D8  KEYON          0                       
   006DA  WAIT           4,-1                    
   006DE  END                                    
OBJ  61 @006E0 MACRO chan=any flags=00
   006E4  STARTSAMPLE    0,61,0                  
   006EC  KEYON          0                       
   006EE  WAIT           4,-1                    
   006F2  END                                    
OBJ  62 @006F4 MACRO chan=any flags=00
   006F8  STARTSAMPLE    0,62,0                  
   00700  KEYON          0                       
   00702  WAIT           4,-1                    
   00706  END                                    
OBJ  63 @00708 MACRO chan=any flags=00
   0070C  STARTSAMPLE    0,63,0                  
   00714  KEYON          0                       
   00716  WAIT           4,-1                    
   0071A  END                                    
OBJ  64 @0071C MACRO chan=any flags=00
   00720  STARTSAMPLE    0,64,0                  
   00728  KEYON          0                       
   0072A  WAIT           4,-1                    
   0072E  END                                    
OBJ  65 @00730 MACRO chan=any flags=00
   00734  STARTSAMPLE    0,65,0                  
   0073C  KEYON          0                       
   0073E  WAIT           4,-1                    
   00742  END                                    
OBJ  66 @00744 MACRO chan=any flags=00
   00748  STARTSAMPLE    0,66,0                  
   00750  KEYON          0                       
   00752  WAIT           4,-1                    
   00756  END                                    
OBJ  67 @00758 MACRO chan=any flags=00
   0075C  STARTSAMPLE    0,67,0                  
   00764  KEYON          0                       
   00766  WAIT           4,-1                    
   0076A  END                                    
OBJ  68 @0076C MACRO chan=any flags=00
   00770  STARTSAMPLE    0,68,0                  
   00778  KEYON          0                       
   0077A  WAIT           4,-1                    
   0077E  END                                    
OBJ  69 @00780 MACRO chan=any flags=00
   00784  STARTSAMPLE    0,69,0                  
   0078C  KEYON          0                       
   0078E  WAIT           4,-1                    
   00792  END                                    
OBJ  70 @00794 MACRO chan=any flags=00
   00798  STARTSAMPLE    0,70,0                  
   007A0  KEYON          0                       
   007A2  WAIT           4,-1                    
   007A6  END                                    
OBJ  71 @007A8 MACRO chan=any flags=00
   007AC  STARTSAMPLE    0,71,0                  
   007B4  KEYON          1                       
   007B6  WAIT           4,-1                    
   007BA  END                                    
OBJ  72 @007BC MACRO chan=any flags=00
   007C0  STARTSAMPLE    0,72,0                  
   007C8  KEYON          1                       
   007CA  WAIT           4,-1                    
   007CE  END                                    
OBJ  73 @007D0 MACRO chan=any flags=00
   007D4  STARTSAMPLE    0,73,0                  
   007DC  KEYON          1                       
   007DE  WAIT           4,-1                    
   007E2  END                                    
OBJ  74 @007E4 MACRO chan=any flags=00
   007E8  STARTSAMPLE    0,74,0                  
   007F0  KEYON          1                       
   007F2  WAIT           4,-1                    
   007F6  END                                    
OBJ  75 @007F8 MACRO chan=any flags=00
   007FC  STARTSAMPLE    0,75,0                  
   00804  KEYON          1                       
   00806  WAIT           5,-1                    
   0080A  FADE           0,2105                  
   0080E  WAIT           4,31                    
   00812  SILENCE        0                       
   00814  END                                    
OBJ  76 @00818 MACRO chan=any flags=00
   0081C  STARTSAMPLE    0,76,0                  
   00824  KEYON          1                       
   00826  WAIT           5,-1                    
   0082A  FADE           0,2105                  
   0082E  WAIT           4,31                    
   00832  SILENCE        0                       
   00834  END                                    
OBJ  77 @00838 MACRO chan=any flags=00
   0083C  SETPRIO        255                     
   0083E  STARTSAMPLE    0,77,0                  
   00846  KEYON          1                       
   00848  WAIT           5,-1                    
   0084C  FADE           0,2105                  
   00850  WAIT           4,31                    
   00854  SILENCE        0                       
   00856  END                                    
OBJ  78 @00858 MACRO chan=any flags=00
   0085C  SETPRIO        255                     
   0085E  STARTSAMPLE    0,78,0                  
   00866  KEYON          1                       
   00868  WAIT           4,-1                    
   0086C  END                                    
OBJ  79 @00870 MACRO chan=any flags=00
   00874  AGESPEED       1                       
   00876  SETAGE         200                     
   0087A  STARTSAMPLE    0,79,0                  
   00882  KEYON          1                       
   00884  WAIT           5,-1                    
   00888  FADE           0,2105                  
   0088C  WAIT           4,31                    
   00890  SILENCE        0                       
   00892  END                                    
OBJ  80 @00894 MACRO chan=8 flags=00
   00898  NOP                                    
   0089A  STARTSAMPLE    0,80,0                  
   008A2  KEYON          1                       
   008A4  WAIT           5,-1                    
   008A8  FADE           0,2105                  
   008AC  WAIT           4,31                    
   008B0  SILENCE        0                       
   008B2  END                                    
OBJ  81 @008B4 MACRO chan=any flags=00
   008B8  SETAGE         200                     
   008BC  AGESPEED       5                       
   008BE  STARTSAMPLE    0,81,0                  
   008C6  KEYON          1                       
   008C8  WAIT           5,-1                    
   008CC  FADE           0,2105                  
   008D0  WAIT           4,31                    
   008D4  SILENCE        0                       
   008D6  END                                    
OBJ  82 @008D8 MACRO chan=any flags=00
   008DC  STARTSAMPLE    0,82,0                  
   008E4  KEYON          1                       
   008E6  WAIT           5,-1                    
   008EA  FADE           0,2105                  
   008EE  WAIT           4,31                    
   008F2  SILENCE        0                       
   008F4  END                                    
OBJ  83 @008F8 MACRO chan=any flags=00
   008FC  SETAGE         1                       
   00900  AGESPEED       200                     
   00902  STARTSAMPLE    0,83,0                  
   0090A  KEYON          1                       
   0090C  WAIT           5,-1                    
   00910  FADE           0,2105                  
   00914  WAIT           4,31                    
   00918  SILENCE        0                       
   0091A  END                                    
OBJ  84 @0091C MACRO chan=any flags=00
   00920  STARTSAMPLE    0,84,0                  
   00928  KEYON          1                       
   0092A  WAIT           4,-1                    
   0092E  END                                    
OBJ  85 @00930 MACRO chan=any flags=00
   00934  STARTSAMPLE    0,85,0                  
   0093C  KEYON          1                       
   0093E  WAIT           5,-1                    
   00942  FADE           0,2105                  
   00946  WAIT           4,31                    
   0094A  SILENCE        0                       
   0094C  END                                    
OBJ  86 @00950 MACRO chan=any flags=00
   00954  STARTSAMPLE    0,86,0                  
   0095C  KEYON          0                       
   0095E  WAIT           4,-1                    
   00962  END                                    
OBJ  87 @00964 MACRO chan=any flags=00
   00968  STARTSAMPLE    0,87,0                  
   00970  KEYON          0                       
   00972  WAIT           4,-1                    
   00976  END                                    
OBJ  88 @00978 MACRO chan=any flags=00
   0097C  STARTSAMPLE    0,88,0                  
   00984  KEYON          0                       
   00986  WAIT           4,-1                    
   0098A  END                                    
OBJ  89 @0098C MACRO chan=any flags=00
   00990  STARTSAMPLE    0,89,0                  
   00998  KEYON          0                       
   0099A  WAIT           4,-1                    
   0099E  END                                    
OBJ  90 @009A0 MACRO chan=any flags=00
   009A4  STARTSAMPLE    0,90,0                  
   009AC  KEYON          0                       
   009AE  WAIT           4,-1                    
   009B2  END                                    
OBJ  91 @009B4 MACRO chan=any flags=00
   009B8  STARTSAMPLE    0,91,0                  
   009C0  KEYON          0                       
   009C2  WAIT           5,-1                    
   009C6  FADE           0,2105                  
   009CA  WAIT           4,31                    
   009CE  SILENCE        0                       
   009D0  END                                    
OBJ  92 @009D4 MACRO chan=any flags=00
   009D8  STARTSAMPLE    0,92,0                  
   009E0  KEYON          1                       
   009E2  WAIT           5,-1                    
   009E6  FADE           0,2105                  
   009EA  WAIT           4,31                    
   009EE  SILENCE        0                       
   009F0  END                                    
OBJ  93 @009F4 MACRO chan=any flags=00
   009F8  STARTSAMPLE    0,93,0                  
   00A00  KEYON          1                       
   00A02  WAIT           5,-1                    
   00A06  FADE           0,2105                  
   00A0A  WAIT           4,31                    
   00A0E  SILENCE        0                       
   00A10  END                                    
OBJ  94 @00A14 MACRO chan=any flags=00
   00A18  STARTSAMPLE    0,94,0                  
   00A20  KEYON          1                       
   00A22  WAIT           5,-1                    
   00A26  FADE           0,2105                  
   00A2A  WAIT           4,31                    
   00A2E  SILENCE        0                       
   00A30  END                                    
OBJ  95 @00A34 MACRO chan=any flags=00
   00A38  STARTSAMPLE    0,95,0                  
   00A40  KEYON          1                       
   00A42  WAIT           5,-1                    
   00A46  SILENCE        0                       
   00A48  END                                    
OBJ  96 @00A4C MACRO chan=any flags=00
   00A50  STARTSAMPLE    0,96,0                  
   00A58  KEYON          1                       
   00A5A  WAIT           4,-1                    
   00A5E  END                                    
OBJ  97 @00A60 MACRO chan=any flags=00
   00A64  STARTSAMPLE    0,97,0                  
   00A6C  KEYON          1                       
   00A6E  WAIT           4,-1                    
   00A72  END                                    
OBJ  98 @00A74 MACRO chan=any flags=00
   00A78  STARTSAMPLE    0,98,0                  
   00A80  KEYON          1                       
   00A82  WAIT           4,-1                    
   00A86  END                                    
OBJ  99 @00A88 MACRO chan=any flags=00
   00A8C  STARTSAMPLE    0,99,0                  
   00A94  KEYON          1                       
   00A96  WAIT           4,-1                    
   00A9A  END                                    
OBJ 100 @00A9C MACRO chan=any flags=00
   00AA0  STARTSAMPLE    0,105,0                 
   00AA8  KEYON          1                       
   00AAA  WAIT           5,-1                    
   00AAE  FADE           0,2105                  
   00AB2  WAIT           4,31                    
   00AB6  SILENCE        0                       
   00AB8  END                                    
OBJ 101 @00ABC MACRO chan=any flags=00
   00AC0  STARTSAMPLE    0,100,0                 
   00AC8  KEYON          1                       
   00ACA  WAIT           4,-1                    
   00ACE  END                                    
OBJ 102 @00AD0 MACRO chan=any flags=00
   00AD4  STARTSAMPLE    0,101,0                 
   00ADC  KEYON          1                       
   00ADE  WAIT           4,-1                    
   00AE2  END                                    
OBJ 103 @00AE4 MACRO chan=any flags=00
   00AE8  STARTSAMPLE    0,102,0                 
   00AF0  KEYON          1                       
   00AF2  WAIT           4,-1                    
   00AF6  END                                    
OBJ 104 @00AF8 MACRO chan=any flags=00
   00AFC  STARTSAMPLE    0,103,0                 
   00B04  KEYON          1                       
   00B06  WAIT           4,-1                    
   00B0A  END                                    
OBJ 105 @00B0C MACRO chan=any flags=00
   00B10  STARTSAMPLE    0,104,0                 
   00B18  KEYON          1                       
   00B1A  WAIT           4,-1                    
   00B1E  END                                    
OBJ 106 @00B20 MACRO chan=any flags=00
   00B24  STARTSAMPLE    0,106,0                 
   00B2C  KEYON          1                       
   00B2E  WAIT           5,-1                    
   00B32  FADE           0,2105                  
   00B36  WAIT           4,31                    
   00B3A  SILENCE        0                       
   00B3C  END                                    
OBJ 107 @00B40 MACRO chan=any flags=00
   00B44  STARTSAMPLE    0,107,0                 
   00B4C  KEYON          1                       
   00B4E  WAIT           5,-1                    
   00B52  FADE           0,2105                  
   00B56  WAIT           4,31                    
   00B5A  SILENCE        0                       
   00B5C  END                                    
OBJ 108 @00B60 MACRO chan=any flags=00
   00B64  STARTSAMPLE    0,108,0                 
   00B6C  KEYON          1                       
   00B6E  WAIT           5,-1                    
   00B72  FADE           0,2105                  
   00B76  WAIT           4,31                    
   00B7A  SILENCE        0                       
   00B7C  END                                    
OBJ 109 @00B80 MACRO chan=any flags=00
   00B84  STARTSAMPLE    0,111,0                 
   00B8C  KEYON          1                       
   00B8E  WAIT           5,-1                    
   00B92  FADE           0,2105                  
   00B96  WAIT           4,31                    
   00B9A  SILENCE        0                       
   00B9C  END                                    
OBJ 110 @00BA0 MACRO chan=any flags=00
   00BA4  STARTSAMPLE    0,109,0                 
   00BAC  KEYON          1                       
   00BAE  WAIT           4,-1                    
   00BB2  END                                    
OBJ 111 @00BB4 MACRO chan=any flags=00
   00BB8  STARTSAMPLE    0,110,0                 
   00BC0  KEYON          1                       
   00BC2  WAIT           4,-1                    
   00BC6  END                                    
OBJ 112 @00BC8 MACRO chan=any flags=00
   00BCC  STARTSAMPLE    0,112,0                 
   00BD4  KEYON          1                       
   00BD6  WAIT           4,-1                    
   00BDA  END                                    
OBJ 113 @00BDC MACRO chan=any flags=00
   00BE0  STARTSAMPLE    0,113,0                 
   00BE8  KEYON          1                       
   00BEA  WAIT           5,-1                    
   00BEE  FADE           0,2105                  
   00BF2  WAIT           4,31                    
   00BF6  SILENCE        0                       
   00BF8  END                                    
OBJ 114 @00BFC MACRO chan=any flags=00
   00C00  SETPRIO        255                     
   00C02  STARTSAMPLE    0,114,0                 
   00C0A  KEYON          1                       
   00C0C  WAIT           5,-1                    
   00C10  FADE           0,2105                  
   00C14  WAIT           4,31                    
   00C18  SILENCE        0                       
   00C1A  END                                    
OBJ 115 @00C1C MACRO chan=0 flags=01
   00C20  NOP                                    
   00C22  IFFLAG         0,20                    -> 00C36
   00C28  PANNING        0,0                     
   00C2C  SETFLAG        1,0                     
   00C30  GOTO           14                      -> 00C3E
   00C36  PANNING        127,0                   
   00C3A  SETFLAG        0,0                     
   00C3E  VOLUME         127                     
   00C40  PSGDUTY        2                       
   00C42  PSGENV         2                       
   00C44  KEYON          0                       
   00C46  WAIT           0,10                    
   00C4A  VIBRATO        5,7                     
   00C4E  WAIT           0,31                    
   00C52  SILENCE        0                       
   00C54  END                                    
OBJ 116 @00C58 MACRO chan=any flags=00
   00C5C  STARTSAMPLE    0,115,0                 
   00C64  KEYON          1                       
   00C66  WAIT           4,-1                    
   00C6A  END                                    
OBJ 117 @00C6C MACRO chan=any flags=00
   00C70  SETAGE         65535                   
   00C74  STARTSAMPLE    0,116,0                 
   00C7C  KEYON          1                       
   00C7E  WAIT           4,-1                    
   00C82  END                                    
OBJ 118 @00C84 MACRO chan=any flags=00
   00C88  STARTSAMPLE    0,117,0                 
   00C90  KEYON          1                       
   00C92  WAIT           4,-1                    
   00C96  END                                    
OBJ 119 @00C98 MACRO chan=5 flags=00
   00C9C  NOP                                    
   00C9E  STARTSAMPLE    0,118,0                 
   00CA6  KEYON          1                       
   00CA8  WAIT           4,-1                    
   00CAC  END                                    
OBJ 120 @00CB0 MACRO chan=any flags=00
   00CB4  STARTSAMPLE    0,119,0                 
   00CBC  KEYON          1                       
   00CBE  WAIT           4,-1                    
   00CC2  END                                    
OBJ 121 @00CC4 MACRO chan=any flags=00
   00CC8  STARTSAMPLE    0,120,0                 
   00CD0  KEYON          1                       
   00CD2  WAIT           4,-1                    
   00CD6  END                                    
OBJ 122 @00CD8 MACRO chan=any flags=00
   00CDC  STARTSAMPLE    0,121,0                 
   00CE4  KEYON          1                       
   00CE6  WAIT           4,-1                    
   00CEA  END                                    
OBJ 123 @00CEC MACRO chan=any flags=00
   00CF0  STARTSAMPLE    0,122,0                 
   00CF8  KEYON          1                       
   00CFA  WAIT           4,-1                    
   00CFE  END                                    
OBJ 124 @00D00 MACRO chan=any flags=00
   00D04  STARTSAMPLE    0,123,0                 
   00D0C  KEYON          1                       
   00D0E  WAIT           4,-1                    
   00D12  END                                    
OBJ 125 @00D14 MACRO chan=any flags=00
   00D18  STARTSAMPLE    0,124,0                 
   00D20  KEYON          1                       
   00D22  WAIT           4,-1                    
   00D26  END                                    
```
