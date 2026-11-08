# I Spy Challenger (U) — MusyX GBA project data dump

Project base 0x086AC6FC. All offsets below are relative to the project base unless written as full 0x08xxxxxx addresses.

## Header
```
+0x00  0x00020  objects (macros/keymaps)
+0x04  0x01254  ADSR tables
+0x08  0x01254  (unused, = ADSR off)
+0x0C  0x01254  FX table
+0x10  0x00000  (unused)
+0x14  0x00000  (unused)
+0x18  0x013B0  songs
+0x1C  0x1D31C  samples
```

Counts: 83 objects, 43 FX, 28 songs, 43 samples.

## FX table
```
 fx  object prio  b3  chan  vol  pan  key
  0     29    10  255   any  127   64   60
  1     28    10  255   any  127   64   60
  2     49    10  255   any  127   64   60
  3     59    10  255   any  127   64   60
  4     62    10  255   any  127   64   60
  5     57    10  255   any  127   64   60
  6     52    10  255   any  127   64   60
  7     47    10  255   any  127   64   60
  8     34    10  255   any  127   64   60
  9     39    10  255   any  127   64   60
 10     27    10  255   any  127   64   60
 11     50    10  255   any  127   64   60
 12     38    10  255   any  127   64   60
 13     40    10  255   any  127   64   60
 14     35    10  255   any  127   64   60
 15     48    10  255   any  127   64   60
 16     37    10  255   any  127   64   60
 17     36    10  255   any  127   64   60
 18     58    10  255   any  127   64   60
 19     61    10  255   any  127   64   60
 20     32    10  255   any  127   64   60
 21     56    10  255   any  127   64   60
 22     44    10  255   any  127   64   60
 23     45    10  255   any  127   64   60
 24     46    10  255   any  127   64   60
 25     26    10  255   any  127   64   60
 26     25    10  255   any  127   64   60
 27     55    10  255   any  127   64   60
 28     51    10  255   any  127   64   60
 29     30    10  255   any  127   64   60
 30     31    10  255   any  127   64   60
 31     54    10  255   any  127   64   60
 32     53    10  255   any  127   64   60
 33     24    10  255   any  127   64   60
 34     19    10  255   any  127   64   60
 35     17    10  255   any  127   64   60
 36     16    10  255   any  127   64   60
 37     15    10  255   any  127   64   60
 38     23    10  255   any  127   64   60
 39     22    10  255   any  127   64   60
 40     21    10  255   any  127   64   60
 41     20    10  255   any  127   64   60
 42     18    10  255   any  127   64   60
```

## Samples
```
  #   offset    length  loopStart  rate(Hz) root type
  0  0x01D3C8     1125          -     11397   60  0
  1  0x01D840     2912          -     11397   60  0
  2  0x01E3B0     2748       2614     11025   76  0
  3  0x01EE7C    23829          -     11025   48  0
  4  0x024BA4     2352       2286     11397   72  0
  5  0x0254E4     6603          -     11397   60  0
  6  0x026EC0     7278          -     11397   60  0
  7  0x028B40     8873          -     11397   60  0
  8  0x02ADFC     6153          -     11397   60  0
  9  0x02C618     4438          -     11397   60  0
 10  0x02D780     6305          -     11397   60  0
 11  0x02F034     8717          -     11397   60  0
 12  0x031254     7038          -     11397   60  0
 13  0x032DE4     3507          -     11397   60  0
 14  0x033BA8     8729          -     11397   60  0
 15  0x035DD4     2713          -     11397   60  0
 16  0x036880     2639          -     11397   60  0
 17  0x0372E0     1927          -     11397   60  0
 18  0x037A78     3110          -     11397   60  0
 19  0x0386B0     7633          -     11397   60  0
 20  0x03A494     7305       2084     12000   65  0
 21  0x03C130     5250       5082     11025   60  0
 22  0x03D5C4     2445          -     11397   60  0
 23  0x03DF64     2352          -     11397   60  0
 24  0x03E8A4     2057          -     11397   60  0
 25  0x03F0C0     2745          -     11397   60  0
 26  0x03FB8C     2445          -     11397   60  0
 27  0x04052C     2445          -     11397   72  0
 28  0x040ECC     5302          -     11397   60  0
 29  0x042394     6815          -     11397   60  0
 30  0x043E44     5690          -     11397   60  0
 31  0x045490     5955          -     11397   60  0
 32  0x046BE4     6153          -     11397   60  0
 33  0x048400     2849          -     11397   60  0
 34  0x048F34     2356          -     11397   60  0
 35  0x049878    10495          -     11397   60  0
 36  0x04C188     6155          -     11397   60  0
 37  0x04D9A4     3462          -     11397   60  0
 38  0x04E73C    19915          -     11397   60  0
 39  0x053518     5349          -     11397   60  0
 40  0x054A10        0          -     11397   60  0
 41  0x054A20        0          -     11397   60  0
 42  0x054A30    13748      13704     11397   60  0
```

## Songs
### Song 0  (offset 0x01424)
```
initial BPM 166, 2 patterns
program map  : p0->obj9(pri 0), p1->obj14(pri 0), p2->obj6(pri 0), p3->obj8(pri 0), p4->obj11(pri 0), p5->obj2(pri 0), p6->obj5(pri 0), p7->obj3(pri 0), p8->obj4(pri 0), p9->obj12(pri 0), p10->obj10(pri 0), p11->obj13(pri 0), p12->obj1(pri 0), p13->obj7(pri 0), p14->obj0(pri 0)
track  8: +0 pat0  +0 END
track 16 (tempo): +0 pat1  +0 END
notes 30, length 228 ticks (0.9 s at initial tempo), loop none
```
### Song 1  (offset 0x0197C)
```
initial BPM 166, 2 patterns
program map  : p0->obj9(pri 0), p1->obj14(pri 0), p2->obj6(pri 0), p3->obj8(pri 0), p4->obj11(pri 0), p5->obj2(pri 0), p6->obj5(pri 0), p7->obj3(pri 0), p8->obj4(pri 0), p9->obj12(pri 0), p10->obj10(pri 0), p11->obj13(pri 0), p12->obj1(pri 0), p13->obj7(pri 0), p14->obj0(pri 0)
track  0 (PSG): +0 pat0  +0 END
track 16 (tempo): +0 pat1  +0 END
notes 15, length 236 ticks (0.9 s at initial tempo), loop none
```
### Song 2  (offset 0x01E7C)
```
initial BPM 200, 2 patterns
program map  : p0->obj9(pri 0), p1->obj14(pri 0), p2->obj6(pri 0), p3->obj8(pri 0), p4->obj11(pri 0), p5->obj2(pri 0), p6->obj5(pri 0), p7->obj3(pri 0), p8->obj4(pri 0), p9->obj12(pri 0), p10->obj10(pri 0), p11->obj13(pri 0), p12->obj1(pri 0), p13->obj7(pri 0), p14->obj0(pri 0)
track  1 (PSG): +0 pat0  +0 END
track 16 (tempo): +0 pat1  +0 END
notes 22, length 597 ticks (1.9 s at initial tempo), loop none
```
### Song 3  (offset 0x023A4)
```
initial BPM 120, 2 patterns
program map  : p0->obj9(pri 0), p1->obj14(pri 0), p2->obj6(pri 0), p3->obj8(pri 0), p4->obj11(pri 0), p5->obj2(pri 0), p6->obj5(pri 0), p7->obj3(pri 0), p8->obj4(pri 0), p9->obj12(pri 0), p10->obj10(pri 0), p11->obj13(pri 0), p12->obj1(pri 0), p13->obj7(pri 0), p14->obj0(pri 0)
track  4: +0 pat0  +0 END
track 16 (tempo): +0 pat1  +0 END
notes 20, length 181 ticks (0.9 s at initial tempo), loop none
```
### Song 4  (offset 0x028B4)
```
initial BPM 160, 2 patterns
program map  : p0->obj13(pri 0), p1->obj76(pri 0), p2->obj12(pri 0), p3->obj81(pri 0), p4->obj0(pri 0), p5->obj75(pri 0), p6->obj72(pri 0), p7->obj77(pri 0), p8->obj74(pri 0), p9->obj73(pri 0), p10->obj71(pri 0), p11->obj70(pri 0), p12->obj69(pri 0), p13->obj68(pri 0), p14->obj79(pri 0), p15->obj78(pri 0), p16->obj67(pri 0), p17->obj65(pri 0), p18->obj64(pri 0)
drum map(ch9): p0->obj82(pri 0)
track  4: +0 pat0  +0 END
track 16 (tempo): +0 pat1  +0 END
notes 8, length 95 ticks (0.4 s at initial tempo), loop none
```
### Song 5  (offset 0x02D8C)
```
initial BPM 94, 2 patterns
program map  : p0->obj13(pri 0), p1->obj76(pri 0), p2->obj12(pri 0), p3->obj81(pri 0), p4->obj0(pri 0), p5->obj75(pri 0), p6->obj72(pri 0), p7->obj77(pri 0), p8->obj74(pri 0), p9->obj73(pri 0), p10->obj71(pri 0), p11->obj70(pri 0), p12->obj69(pri 0), p13->obj68(pri 0), p14->obj79(pri 0), p15->obj78(pri 0), p16->obj67(pri 0), p17->obj65(pri 0), p18->obj64(pri 0)
drum map(ch9): p0->obj82(pri 0)
track  4: +0 pat0  +0 END
track 16 (tempo): +0 pat1  +0 END
notes 8, length 43 ticks (0.3 s at initial tempo), loop none
```
### Song 6  (offset 0x03248)
```
initial BPM 122, 5 patterns
program map  : p0->obj13(pri 0), p1->obj76(pri 0), p2->obj12(pri 0), p3->obj81(pri 0), p4->obj0(pri 0), p5->obj75(pri 0), p6->obj72(pri 0), p7->obj77(pri 0), p8->obj74(pri 0), p9->obj73(pri 0), p10->obj71(pri 0), p11->obj70(pri 0), p12->obj69(pri 0), p13->obj68(pri 0), p14->obj79(pri 0), p15->obj78(pri 0), p16->obj67(pri 0), p17->obj65(pri 0), p18->obj64(pri 0)
drum map(ch9): p0->obj82(pri 0)
track  0 (PSG): +0 pat0  +8447 LOOP->entry0 (+0)
track  1 (PSG): +0 pat1  +8447 LOOP->entry0 (+0)
track  4: +0 pat2  +8447 LOOP->entry0 (+0)
track  9: +0 pat3  +8447 LOOP->entry0 (+0)
track 16 (tempo): +0 pat4  +8447 LOOP->entry0 (+0)
notes 970, length 8447 ticks (43.3 s at initial tempo), loop 0-8447
```
### Song 7  (offset 0x04DF8)
```
initial BPM 180, 3 patterns
program map  : p0->obj13(pri 0), p1->obj76(pri 0), p2->obj12(pri 0), p3->obj81(pri 0), p4->obj0(pri 0), p5->obj75(pri 0), p6->obj72(pri 0), p7->obj77(pri 0), p8->obj74(pri 0), p9->obj73(pri 0), p10->obj71(pri 0), p11->obj70(pri 0), p12->obj69(pri 0), p13->obj68(pri 0), p14->obj79(pri 0), p15->obj78(pri 0), p16->obj67(pri 0), p17->obj65(pri 0), p18->obj64(pri 0)
drum map(ch9): p0->obj82(pri 0)
track  4: +0 pat0  +8447 LOOP->entry0 (+0)
track  9: +0 pat1  +8447 LOOP->entry0 (+0)
track 16 (tempo): +0 pat2  +8447 LOOP->entry0 (+0)
notes 623, length 8447 ticks (29.3 s at initial tempo), loop 0-8447
```
### Song 8  (offset 0x06158)
```
initial BPM 147, 5 patterns
program map  : p0->obj13(pri 0), p1->obj76(pri 0), p2->obj12(pri 0), p3->obj81(pri 0), p4->obj0(pri 0), p5->obj75(pri 0), p6->obj72(pri 0), p7->obj77(pri 0), p8->obj74(pri 0), p9->obj73(pri 0), p10->obj71(pri 0), p11->obj70(pri 0), p12->obj69(pri 0), p13->obj68(pri 0), p14->obj79(pri 0), p15->obj78(pri 0), p16->obj67(pri 0), p17->obj65(pri 0), p18->obj64(pri 0)
drum map(ch9): p0->obj82(pri 0)
track  4: +0 pat0  +9215 LOOP->entry0 (+0)
track  9: +0 pat1  +9215 LOOP->entry0 (+0)
track 13: +0 pat2  +9215 LOOP->entry0 (+0)
track 15: +5760 pat3  +3455 LOOP->entry0 (+5760)
track 16 (tempo): +0 pat4  +9215 LOOP->entry0 (+0)
notes 637, length 9215 ticks (39.2 s at initial tempo), loop 0-9215
```
### Song 9  (offset 0x0754C)
```
initial BPM 170, 6 patterns
program map  : p0->obj13(pri 0), p1->obj76(pri 0), p2->obj12(pri 0), p3->obj81(pri 0), p4->obj0(pri 0), p5->obj75(pri 0), p6->obj72(pri 0), p7->obj77(pri 0), p8->obj74(pri 0), p9->obj73(pri 0), p10->obj71(pri 0), p11->obj70(pri 0), p12->obj69(pri 0), p13->obj68(pri 0), p14->obj79(pri 0), p15->obj78(pri 0), p16->obj67(pri 0), p17->obj65(pri 0), p18->obj64(pri 0)
drum map(ch9): p0->obj82(pri 0)
track  0 (PSG): +0 pat0  +8447 LOOP->entry0 (+0)
track  1 (PSG): +96 pat1  +8351 LOOP->entry0 (+96)
track  4: +0 pat2  +8447 LOOP->entry0 (+0)
track  9: +0 pat3  +8447 LOOP->entry0 (+0)
track 13: +0 pat4  +8447 LOOP->entry0 (+0)
track 16 (tempo): +0 pat5  +8447 LOOP->entry0 (+0)
notes 557, length 8447 ticks (31.1 s at initial tempo), loop 0-8447
```
### Song 10  (offset 0x08780)
```
initial BPM 130, 5 patterns
program map  : p0->obj13(pri 0), p1->obj76(pri 0), p2->obj12(pri 0), p3->obj81(pri 0), p4->obj0(pri 0), p5->obj75(pri 0), p6->obj72(pri 0), p7->obj77(pri 0), p8->obj74(pri 0), p9->obj73(pri 0), p10->obj71(pri 0), p11->obj70(pri 0), p12->obj69(pri 0), p13->obj68(pri 0), p14->obj79(pri 0), p15->obj78(pri 0), p16->obj67(pri 0), p17->obj65(pri 0), p18->obj64(pri 0)
drum map(ch9): p0->obj82(pri 0)
track  0 (PSG): +7296 pat0  +8447 LOOP->entry0 (+7296)
track  1 (PSG): +0 pat1  +15743 LOOP->entry0 (+0)
track  4: +0 pat2  +15743 LOOP->entry0 (+0)
track  9: +0 pat3  +15743 LOOP->entry0 (+0)
track 16 (tempo): +0 pat4  +15743 LOOP->entry0 (+0)
notes 1679, length 15743 ticks (75.7 s at initial tempo), loop 0-15743
```
### Song 11  (offset 0x0B3E0)
```
initial BPM 186, 7 patterns
program map  : p0->obj13(pri 0), p1->obj76(pri 0), p2->obj12(pri 0), p3->obj81(pri 0), p4->obj0(pri 0), p5->obj75(pri 0), p6->obj72(pri 0), p7->obj77(pri 0), p8->obj74(pri 0), p9->obj73(pri 0), p10->obj71(pri 0), p11->obj70(pri 0), p12->obj69(pri 0), p13->obj68(pri 0), p14->obj79(pri 0), p15->obj78(pri 0), p16->obj67(pri 0), p17->obj65(pri 0), p18->obj64(pri 0)
drum map(ch9): p0->obj82(pri 0)
track  0 (PSG): +64 pat0  +18367 LOOP->entry0 (+64)
track  1 (PSG): +0 pat1  +18431 LOOP->entry0 (+0)
track  4: +64 pat2  +18367 LOOP->entry0 (+64)
track  6: +4669 pat3  +13762 LOOP->entry0 (+4669)
track  8: +9308 pat4  +9123 LOOP->entry0 (+9308)
track  9: +0 pat5  +18431 LOOP->entry0 (+0)
track 16 (tempo): +0 pat6  +18431 LOOP->entry0 (+0)
notes 1283, length 18431 ticks (61.9 s at initial tempo), loop 0-18431
```
### Song 12  (offset 0x0D738)
```
initial BPM 199, 3 patterns
program map  : p0->obj13(pri 0), p1->obj76(pri 0), p2->obj12(pri 0), p3->obj81(pri 0), p4->obj0(pri 0), p5->obj75(pri 0), p6->obj72(pri 0), p7->obj77(pri 0), p8->obj74(pri 0), p9->obj73(pri 0), p10->obj71(pri 0), p11->obj70(pri 0), p12->obj69(pri 0), p13->obj68(pri 0), p14->obj79(pri 0), p15->obj78(pri 0), p16->obj67(pri 0), p17->obj65(pri 0), p18->obj64(pri 0)
drum map(ch9): p0->obj82(pri 0)
track  4: +98 pat0  +0 END
track  9: +71 pat1  +0 END
track 16 (tempo): +0 pat2  +0 END
notes 41, length 1162 ticks (3.6 s at initial tempo), loop none
```
### Song 13  (offset 0x0DCF4)
```
initial BPM 199, 3 patterns
program map  : p0->obj13(pri 0), p1->obj76(pri 0), p2->obj12(pri 0), p3->obj81(pri 0), p4->obj0(pri 0), p5->obj75(pri 0), p6->obj72(pri 0), p7->obj77(pri 0), p8->obj74(pri 0), p9->obj73(pri 0), p10->obj71(pri 0), p11->obj70(pri 0), p12->obj69(pri 0), p13->obj68(pri 0), p14->obj79(pri 0), p15->obj78(pri 0), p16->obj67(pri 0), p17->obj65(pri 0), p18->obj64(pri 0)
drum map(ch9): p0->obj82(pri 0)
track  4: +98 pat0  +0 END
track  9: +71 pat1  +0 END
track 16 (tempo): +0 pat2  +0 END
notes 38, length 1147 ticks (3.6 s at initial tempo), loop none
```
### Song 14  (offset 0x0E29C)
```
initial BPM 200, 5 patterns
program map  : p0->obj13(pri 0), p1->obj76(pri 0), p2->obj12(pri 0), p3->obj81(pri 0), p4->obj0(pri 0), p5->obj75(pri 0), p6->obj72(pri 0), p7->obj77(pri 0), p8->obj74(pri 0), p9->obj73(pri 0), p10->obj71(pri 0), p11->obj70(pri 0), p12->obj69(pri 0), p13->obj68(pri 0), p14->obj79(pri 0), p15->obj78(pri 0), p16->obj67(pri 0), p17->obj65(pri 0), p18->obj64(pri 0)
drum map(ch9): p0->obj82(pri 0)
track  0 (PSG): +128 pat0  +0 END
track  8: +128 pat1  +0 END
track  9: +224 pat2  +0 END
track 15: +128 pat3  +0 END
track 16 (tempo): +0 pat4  +0 END
notes 38, length 888 ticks (2.8 s at initial tempo), loop none
```
### Song 15  (offset 0x0E884)
```
initial BPM 186, 5 patterns
program map  : p0->obj13(pri 0), p1->obj76(pri 0), p2->obj12(pri 0), p3->obj81(pri 0), p4->obj0(pri 0), p5->obj75(pri 0), p6->obj72(pri 0), p7->obj77(pri 0), p8->obj74(pri 0), p9->obj73(pri 0), p10->obj71(pri 0), p11->obj70(pri 0), p12->obj69(pri 0), p13->obj68(pri 0), p14->obj79(pri 0), p15->obj78(pri 0), p16->obj67(pri 0), p17->obj65(pri 0), p18->obj64(pri 0)
drum map(ch9): p0->obj82(pri 0)
track  0 (PSG): +0 pat0  +9215 LOOP->entry0 (+0)
track  4: +96 pat1  +9119 LOOP->entry0 (+96)
track  9: +0 pat2  +9215 LOOP->entry0 (+0)
track 13: +0 pat3  +9215 LOOP->entry0 (+0)
track 16 (tempo): +0 pat4  +9215 LOOP->entry0 (+0)
notes 560, length 9215 ticks (31.0 s at initial tempo), loop 0-9215
```
### Song 16  (offset 0x0FAA8)
```
initial BPM 154, 6 patterns
program map  : p0->obj13(pri 0), p1->obj76(pri 0), p2->obj12(pri 0), p3->obj81(pri 0), p4->obj0(pri 0), p5->obj75(pri 0), p6->obj72(pri 0), p7->obj77(pri 0), p8->obj74(pri 0), p9->obj73(pri 0), p10->obj71(pri 0), p11->obj70(pri 0), p12->obj69(pri 0), p13->obj68(pri 0), p14->obj79(pri 0), p15->obj78(pri 0), p16->obj67(pri 0), p17->obj65(pri 0), p18->obj64(pri 0)
drum map(ch9): p0->obj82(pri 0)
track  0 (PSG): +96 pat0  +6047 LOOP->entry0 (+96)
track  4: +0 pat1  +6143 LOOP->entry0 (+0)
track  9: +0 pat2  +6143 LOOP->entry0 (+0)
track 13: +0 pat3  +6143 LOOP->entry0 (+0)
track 14: +95 pat4  +6048 LOOP->entry0 (+95)
track 16 (tempo): +0 pat5  +6143 LOOP->entry0 (+0)
notes 232, length 6143 ticks (24.9 s at initial tempo), loop 0-6143
```
### Song 17  (offset 0x1053C)
```
initial BPM 101, 4 patterns
program map  : p0->obj13(pri 0), p1->obj76(pri 0), p2->obj12(pri 0), p3->obj81(pri 0), p4->obj0(pri 0), p5->obj75(pri 0), p6->obj72(pri 0), p7->obj77(pri 0), p8->obj74(pri 0), p9->obj73(pri 0), p10->obj71(pri 0), p11->obj70(pri 0), p12->obj69(pri 0), p13->obj68(pri 0), p14->obj79(pri 0), p15->obj78(pri 0), p16->obj67(pri 0), p17->obj65(pri 0), p18->obj64(pri 0)
drum map(ch9): p0->obj82(pri 0)
track  0 (PSG): +0 pat0  +13439 LOOP->entry0 (+0)
track  4: +0 pat1  +13439 LOOP->entry0 (+0)
track  9: +0 pat2  +13439 LOOP->entry0 (+0)
track 16 (tempo): +0 pat3  +13439 LOOP->entry0 (+0)
notes 2718, length 13439 ticks (83.2 s at initial tempo), loop 0-13439
```
### Song 18  (offset 0x149BC)
```
initial BPM 130, 5 patterns
program map  : p0->obj13(pri 0), p1->obj76(pri 0), p2->obj12(pri 0), p3->obj81(pri 0), p4->obj0(pri 0), p5->obj75(pri 0), p6->obj72(pri 0), p7->obj77(pri 0), p8->obj74(pri 0), p9->obj73(pri 0), p10->obj71(pri 0), p11->obj70(pri 0), p12->obj69(pri 0), p13->obj68(pri 0), p14->obj79(pri 0), p15->obj78(pri 0), p16->obj67(pri 0), p17->obj65(pri 0), p18->obj64(pri 0)
drum map(ch9): p0->obj82(pri 0)
track  0 (PSG): +0 pat0  +9215 LOOP->entry0 (+0)
track  4: +0 pat1  +9215 LOOP->entry0 (+0)
track  9: +0 pat2  +9215 LOOP->entry0 (+0)
track 15: +0 pat3  +9215 LOOP->entry0 (+0)
track 16 (tempo): +0 pat4  +9215 LOOP->entry0 (+0)
notes 1003, length 9215 ticks (44.3 s at initial tempo), loop 0-9215
```
### Song 19  (offset 0x16644)
```
initial BPM 220, 3 patterns
program map  : p0->obj13(pri 0), p1->obj76(pri 0), p2->obj12(pri 0), p3->obj81(pri 0), p4->obj0(pri 0), p5->obj75(pri 0), p6->obj72(pri 0), p7->obj77(pri 0), p8->obj74(pri 0), p9->obj73(pri 0), p10->obj71(pri 0), p11->obj70(pri 0), p12->obj69(pri 0), p13->obj68(pri 0), p14->obj79(pri 0), p15->obj78(pri 0), p16->obj67(pri 0), p17->obj65(pri 0), p18->obj64(pri 0)
drum map(ch9): p0->obj82(pri 0)
track  9: +0 pat0  +0 END
track 13: +0 pat1  +0 END
track 16 (tempo): +0 pat2  +0 END
notes 34, length 412 ticks (1.2 s at initial tempo), loop none
```
### Song 20  (offset 0x16BD4)
```
initial BPM 165, 2 patterns
program map  : p0->obj13(pri 0), p1->obj76(pri 0), p2->obj12(pri 0), p3->obj81(pri 0), p4->obj0(pri 0), p5->obj75(pri 0), p6->obj72(pri 0), p7->obj77(pri 0), p8->obj74(pri 0), p9->obj73(pri 0), p10->obj71(pri 0), p11->obj70(pri 0), p12->obj69(pri 0), p13->obj68(pri 0), p14->obj79(pri 0), p15->obj78(pri 0), p16->obj67(pri 0), p17->obj65(pri 0), p18->obj64(pri 0)
drum map(ch9): p0->obj82(pri 0)
track  4: +0 pat0  +0 END
track 16 (tempo): +0 pat1  +0 END
notes 9, length 189 ticks (0.7 s at initial tempo), loop none
```
### Song 21  (offset 0x170B0)
```
initial BPM 150, 3 patterns
program map  : p0->obj13(pri 0), p1->obj76(pri 0), p2->obj12(pri 0), p3->obj81(pri 0), p4->obj0(pri 0), p5->obj75(pri 0), p6->obj72(pri 0), p7->obj77(pri 0), p8->obj74(pri 0), p9->obj73(pri 0), p10->obj71(pri 0), p11->obj70(pri 0), p12->obj69(pri 0), p13->obj68(pri 0), p14->obj79(pri 0), p15->obj78(pri 0), p16->obj67(pri 0), p17->obj65(pri 0), p18->obj64(pri 0)
drum map(ch9): p0->obj82(pri 0)
track  0 (PSG): +0 pat0  +0 END
track  4: +2 pat1  +0 END
track 16 (tempo): +0 pat2  +0 END
notes 14, length 413 ticks (1.7 s at initial tempo), loop none
```
### Song 22  (offset 0x175CC)
```
initial BPM 145, 2 patterns
program map  : p0->obj13(pri 0), p1->obj76(pri 0), p2->obj12(pri 0), p3->obj81(pri 0), p4->obj0(pri 0), p5->obj75(pri 0), p6->obj72(pri 0), p7->obj77(pri 0), p8->obj74(pri 0), p9->obj73(pri 0), p10->obj71(pri 0), p11->obj70(pri 0), p12->obj69(pri 0), p13->obj68(pri 0), p14->obj79(pri 0), p15->obj78(pri 0), p16->obj67(pri 0), p17->obj65(pri 0), p18->obj64(pri 0)
drum map(ch9): p0->obj82(pri 0)
track  5: +0 pat0  +0 END
track 16 (tempo): +0 pat1  +0 END
notes 16, length 183 ticks (0.8 s at initial tempo), loop none
```
### Song 23  (offset 0x17AD4)
```
initial BPM 145, 3 patterns
program map  : p0->obj13(pri 0), p1->obj76(pri 0), p2->obj12(pri 0), p3->obj81(pri 0), p4->obj0(pri 0), p5->obj75(pri 0), p6->obj72(pri 0), p7->obj77(pri 0), p8->obj74(pri 0), p9->obj73(pri 0), p10->obj71(pri 0), p11->obj70(pri 0), p12->obj69(pri 0), p13->obj68(pri 0), p14->obj79(pri 0), p15->obj78(pri 0), p16->obj67(pri 0), p17->obj65(pri 0), p18->obj64(pri 0)
drum map(ch9): p0->obj82(pri 0)
track  4: +0 pat0  +0 END
track  5: +52 pat1  +0 END
track 16 (tempo): +0 pat2  +0 END
notes 9, length 257 ticks (1.1 s at initial tempo), loop none
```
### Song 24  (offset 0x17FD0)
```
initial BPM 145, 2 patterns
program map  : p0->obj13(pri 0), p1->obj76(pri 0), p2->obj12(pri 0), p3->obj81(pri 0), p4->obj0(pri 0), p5->obj75(pri 0), p6->obj72(pri 0), p7->obj77(pri 0), p8->obj74(pri 0), p9->obj73(pri 0), p10->obj71(pri 0), p11->obj70(pri 0), p12->obj69(pri 0), p13->obj68(pri 0), p14->obj79(pri 0), p15->obj78(pri 0), p16->obj67(pri 0), p17->obj65(pri 0), p18->obj64(pri 0)
drum map(ch9): p0->obj82(pri 0)
track  4: +0 pat0  +0 END
track 16 (tempo): +0 pat1  +0 END
notes 10, length 257 ticks (1.1 s at initial tempo), loop none
```
### Song 25  (offset 0x184B4)
```
initial BPM 176, 2 patterns
program map  : p0->obj13(pri 0), p1->obj76(pri 0), p2->obj12(pri 0), p3->obj81(pri 0), p4->obj0(pri 0), p5->obj75(pri 0), p6->obj72(pri 0), p7->obj77(pri 0), p8->obj74(pri 0), p9->obj73(pri 0), p10->obj71(pri 0), p11->obj70(pri 0), p12->obj69(pri 0), p13->obj68(pri 0), p14->obj79(pri 0), p15->obj78(pri 0), p16->obj67(pri 0), p17->obj65(pri 0), p18->obj64(pri 0)
drum map(ch9): p0->obj82(pri 0)
track  4: +0 pat0  +0 END
track 16 (tempo): +0 pat1  +0 END
notes 14, length 189 ticks (0.7 s at initial tempo), loop none
```
### Song 26  (offset 0x189B0)
```
initial BPM 182, 6 patterns
program map  : p0->obj13(pri 0), p1->obj76(pri 0), p2->obj12(pri 0), p3->obj81(pri 0), p4->obj0(pri 0), p5->obj75(pri 0), p6->obj72(pri 0), p7->obj77(pri 0), p8->obj74(pri 0), p9->obj73(pri 0), p10->obj71(pri 0), p11->obj70(pri 0), p12->obj69(pri 0), p13->obj68(pri 0), p14->obj79(pri 0), p15->obj78(pri 0), p16->obj67(pri 0), p17->obj65(pri 0), p18->obj64(pri 0)
drum map(ch9): p0->obj82(pri 0)
track  0 (PSG): +0 pat0  +24575 LOOP->entry0 (+0)
track  4: +0 pat1  +24575 LOOP->entry0 (+0)
track  9: +0 pat2  +24575 LOOP->entry0 (+0)
track 12: +0 pat3  +24575 LOOP->entry0 (+0)
track 13: +0 pat4  +24575 LOOP->entry0 (+0)
track 16 (tempo): +0 pat5  +24575 LOOP->entry0 (+0)
notes 2694, length 24575 ticks (84.4 s at initial tempo), loop 0-24575
```
### Song 27  (offset 0x1CDF8)
```
initial BPM 176, 2 patterns
program map  : p0->obj13(pri 0), p1->obj76(pri 0), p2->obj12(pri 0), p3->obj81(pri 0), p4->obj0(pri 0), p5->obj75(pri 0), p6->obj72(pri 0), p7->obj77(pri 0), p8->obj74(pri 0), p9->obj73(pri 0), p10->obj71(pri 0), p11->obj70(pri 0), p12->obj69(pri 0), p13->obj68(pri 0), p14->obj79(pri 0), p15->obj78(pri 0), p16->obj67(pri 0), p17->obj65(pri 0), p18->obj64(pri 0)
drum map(ch9): p0->obj82(pri 0)
track  0 (PSG): +0 pat0  +0 END
track 16 (tempo): +0 pat1  +0 END
notes 21, length 393 ticks (1.4 s at initial tempo), loop none
```

## Objects (macros and keymaps)
```
OBJ   0 @0016C MACRO chan=0 flags=01
   00170  NOP                                    
   00172  VOLUME         127                     
   00174  PSGDUTY        2                       
   00176  PSGENV         2                       
   00178  KEYON          0                       
   0017A  WAIT           0,10                    
   0017E  VIBRATO        5,7                     
   00182  WAIT           0,31                    
   00186  SILENCE        0                       
   00188  END                                    
OBJ   1 @0018C MACRO chan=any flags=00
   00190  NOISEPARAM     51                      
   00192  FADE           1,1332                  
   00196  KEYON          0                       
   00198  WAIT           1,25                    
   0019C  SILENCE        0                       
   0019E  END                                    
OBJ   2 @001A0 MACRO chan=any flags=00
   001A4  NOISEPARAM     32                      
   001A6  PSGENV         2                       
   001A8  KEYON          0                       
   001AA  WAIT           0,10                    
   001AE  NOISEPARAM     59                      
   001B0  WAIT           1,5                     
   001B4  NOISEPARAM     23                      
   001B6  WAIT           1,7                     
   001BA  SILENCE        0                       
   001BC  END                                    
OBJ   3 @001C0 MACRO chan=any flags=00
   001C4  NOISEPARAM     64                      
   001C6  KEYON          0                       
   001C8  WAIT           0,1                     
   001CC  NOISEPARAM     8                       
   001CE  WAIT           0,2                     
   001D2  NOISEPARAM     24                      
   001D4  WAIT           0,1                     
   001D8  NOISEPARAM     44                      
   001DA  WAIT           0,2                     
   001DE  NOISEPARAM     56                      
   001E0  WAIT           0,1                     
   001E4  NOISEPARAM     72                      
   001E6  WAIT           0,1                     
   001EA  NOISEPARAM     88                      
   001EC  WAIT           0,1                     
   001F0  NOISEPARAM     104                     
   001F2  WAIT           0,1                     
   001F6  NOISEPARAM     120                     
   001F8  WAIT           0,1                     
   001FC  NOISEPARAM     136                     
   001FE  WAIT           0,2                     
   00202  NOISEPARAM     24                      
   00204  WAIT           0,2                     
   00208  SILENCE        0                       
   0020A  END                                    
OBJ   4 @0020C MACRO chan=any flags=00
   00210  NOISEPARAM     120                     
   00212  PSGENV         3                       
   00214  KEYON          0                       
   00216  WAIT           0,7                     
   0021A  NOISEPARAM     80                      
   0021C  WAIT           1,31                    
   00220  SILENCE        0                       
   00222  END                                    
OBJ   5 @00224 MACRO chan=any flags=00
   00228  NOISEPARAM     136                     
   0022A  PSGENV         4                       
   0022C  KEYON          0                       
   0022E  WAIT           0,61                    
   00232  SILENCE        0                       
   00234  END                                    
OBJ   6 @00238 MACRO chan=any flags=00
   0023C  PSGDUTY        1                       
   0023E  PSGENV         3                       
   00240  KEYON          0                       
   00242  VIBRATO        4,1536                  
   00246  WAIT           0,61                    
   0024A  SILENCE        0                       
   0024C  END                                    
OBJ   7 @00250 MACRO chan=any flags=00
   00254  AGESPEED       255                     
   00256  STARTSAMPLE    0,4,0                   
   0025E  KEYON          0                       
   00260  SETPITCH       16665                   
   00264  PITCHSWEEP     0,512,20480             
   0026A  WAIT           5,13                    
   0026E  FADE           0,2105                  
   00272  WAIT           4,16                    
   00276  SILENCE        0                       
   00278  END                                    
OBJ   8 @0027C MACRO chan=any flags=00
   00280  STARTSAMPLE    0,0,0                   
   00288  KEYON          0                       
   0028A  WAIT           4,-1                    
   0028E  END                                    
OBJ   9 @00290 MACRO chan=any flags=00
   00294  STARTSAMPLE    0,1,0                   
   0029C  KEYON          0                       
   0029E  WAIT           4,-1                    
   002A2  END                                    
OBJ  10 @002A4 MACRO chan=0 flags=01
   002A8  NOP                                    
   002AA  VOLUME         80                      
   002AC  PSGDUTY        2                       
   002AE  PSGENV         1                       
   002B0  KEYON          0                       
   002B2  WAIT           0,10                    
   002B6  VOLUME         30                      
   002B8  WAIT           0,1                     
   002BC  PSGENV         3                       
   002BE  WAIT           0,13                    
   002C2  WAIT           0,13                    
   002C6  SILENCE        0                       
   002C8  END                                    
OBJ  11 @002CC MACRO chan=any flags=00
   002D0  AGESPEED       255                     
   002D2  STARTSAMPLE    0,3,0                   
   002DA  KEYON          1                       
   002DC  WAIT           4,-1                    
   002E0  END                                    
OBJ  12 @002E4 MACRO chan=any flags=00
   002E8  STARTSAMPLE    0,2,0                   
   002F0  KEYON          0                       
   002F2  WAIT           5,13                    
   002F6  VIBRATO        6,12                    
   002FA  WAIT           5,31                    
   002FE  ADDAGE         -32768                  
   00302  FADE           0,9325                  
   00306  WAIT           4,7                     
   0030A  SILENCE        0                       
   0030C  END                                    
OBJ  13 @00310 MACRO chan=any flags=00
   00314  AGESPEED       255                     
   00316  STARTSAMPLE    0,4,0                   
   0031E  KEYON          0                       
   00320  WAIT           5,13                    
   00324  FADE           0,9325                  
   00328  WAIT           4,7                     
   0032C  SILENCE        0                       
   0032E  END                                    
OBJ  14 @00330 MACRO chan=any flags=00
   00334  VOLUME         127                     
   00336  PSGDUTY        2                       
   00338  KEYON          1                       
   0033A  VIBRATO        5,18                    
   0033E  WAIT           0,1                     
   00342  ADDPITCH       1,768                   
   00346  WAIT           0,1                     
   0034A  ADDPITCH       1,2048                  
   0034E  WAIT           0,1                     
   00352  VOLUME         50                      
   00354  ADDPITCH       1,0                     
   00358  WAIT           0,1                     
   0035C  ADDPITCH       1,768                   
   00360  WAIT           0,1                     
   00364  ADDPITCH       1,2048                  
   00368  PSGENV         1                       
   0036A  END                                    
OBJ  15 @0036C MACRO chan=any flags=00
   00370  STARTSAMPLE    0,6,0                   
   00378  KEYON          0                       
   0037A  WAIT           5,8                     
   0037E  SILENCE        0                       
   00380  STARTSAMPLE    0,6,0                   
   00388  KEYON          0                       
   0038A  WAIT           1,37                    
   0038E  SILENCE        0                       
   00390  STARTSAMPLE    0,6,0                   
   00398  KEYON          0                       
   0039A  WAIT           1,31                    
   0039E  SILENCE        0                       
   003A0  STARTSAMPLE    0,6,0                   
   003A8  KEYON          0                       
   003AA  WAIT           1,8                     
   003AE  SILENCE        0                       
   003B0  STARTSAMPLE    0,6,0                   
   003B8  KEYON          0                       
   003BA  WAIT           1,16                    
   003BE  SILENCE        0                       
   003C0  STARTSAMPLE    0,6,0                   
   003C8  KEYON          0                       
   003CA  WAIT           1,43                    
   003CE  SILENCE        0                       
   003D0  END                                    
OBJ  16 @003D4 MACRO chan=any flags=00
   003D8  STARTSAMPLE    0,7,0                   
   003E0  KEYON          0                       
   003E2  WAIT           5,16                    
   003E6  SILENCE        0                       
   003E8  STARTSAMPLE    0,7,0                   
   003F0  KEYON          0                       
   003F2  WAIT           1,31                    
   003F6  SILENCE        0                       
   003F8  STARTSAMPLE    0,7,0                   
   00400  KEYON          0                       
   00402  WAIT           1,8                     
   00406  SILENCE        0                       
   00408  STARTSAMPLE    0,7,0                   
   00410  KEYON          0                       
   00412  WAIT           1,8                     
   00416  SILENCE        0                       
   00418  STARTSAMPLE    0,7,0                   
   00420  KEYON          0                       
   00422  WAIT           1,31                    
   00426  SILENCE        0                       
   00428  STARTSAMPLE    0,7,0                   
   00430  KEYON          0                       
   00432  WAIT           1,8                     
   00436  SILENCE        0                       
   00438  STARTSAMPLE    0,7,0                   
   00440  KEYON          0                       
   00442  WAIT           1,16                    
   00446  SILENCE        0                       
   00448  STARTSAMPLE    0,7,0                   
   00450  KEYON          0                       
   00452  WAIT           1,43                    
   00456  SILENCE        0                       
   00458  END                                    
OBJ  17 @0045C MACRO chan=any flags=00
   00460  STARTSAMPLE    0,8,0                   
   00468  KEYON          0                       
   0046A  WAIT           5,31                    
   0046E  SILENCE        0                       
   00470  STARTSAMPLE    0,8,0                   
   00478  KEYON          0                       
   0047A  WAIT           1,8                     
   0047E  SILENCE        0                       
   00480  STARTSAMPLE    0,8,0                   
   00488  KEYON          0                       
   0048A  WAIT           1,16                    
   0048E  SILENCE        0                       
   00490  STARTSAMPLE    0,8,0                   
   00498  KEYON          0                       
   0049A  WAIT           1,31                    
   0049E  SILENCE        0                       
   004A0  STARTSAMPLE    0,8,0                   
   004A8  KEYON          0                       
   004AA  WAIT           1,16                    
   004AE  SILENCE        0                       
   004B0  STARTSAMPLE    0,8,0                   
   004B8  KEYON          0                       
   004BA  WAIT           1,16                    
   004BE  SILENCE        0                       
   004C0  STARTSAMPLE    0,8,0                   
   004C8  KEYON          0                       
   004CA  WAIT           1,8                     
   004CE  SILENCE        0                       
   004D0  STARTSAMPLE    0,8,0                   
   004D8  KEYON          0                       
   004DA  WAIT           1,43                    
   004DE  SILENCE        0                       
   004E0  END                                    
OBJ  18 @004E4 MACRO chan=any flags=00
   004E8  STARTSAMPLE    0,5,0                   
   004F0  KEYON          0                       
   004F2  WAIT           5,46                    
   004F6  SILENCE        0                       
   004F8  STARTSAMPLE    0,5,0                   
   00500  KEYON          0                       
   00502  WAIT           1,8                     
   00506  SILENCE        0                       
   00508  STARTSAMPLE    0,5,0                   
   00510  KEYON          0                       
   00512  WAIT           1,8                     
   00516  SILENCE        0                       
   00518  STARTSAMPLE    0,5,0                   
   00520  KEYON          0                       
   00522  WAIT           1,16                    
   00526  SILENCE        0                       
   00528  STARTSAMPLE    0,5,0                   
   00530  KEYON          0                       
   00532  WAIT           1,31                    
   00536  SILENCE        0                       
   00538  STARTSAMPLE    0,5,0                   
   00540  KEYON          0                       
   00542  WAIT           1,8                     
   00546  SILENCE        0                       
   00548  STARTSAMPLE    0,5,0                   
   00550  KEYON          0                       
   00552  WAIT           1,16                    
   00556  SILENCE        0                       
   00558  STARTSAMPLE    0,5,0                   
   00560  KEYON          0                       
   00562  WAIT           1,43                    
   00566  SILENCE        0                       
   00568  END                                    
OBJ  19 @0056C MACRO chan=any flags=00
   00570  STARTSAMPLE    0,9,0                   
   00578  KEYON          0                       
   0057A  WAIT           5,46                    
   0057E  SILENCE        0                       
   00580  STARTSAMPLE    0,9,0                   
   00588  KEYON          0                       
   0058A  WAIT           1,8                     
   0058E  SILENCE        0                       
   00590  STARTSAMPLE    0,9,0                   
   00598  KEYON          0                       
   0059A  WAIT           1,8                     
   0059E  SILENCE        0                       
   005A0  STARTSAMPLE    0,9,0                   
   005A8  KEYON          0                       
   005AA  WAIT           1,16                    
   005AE  SILENCE        0                       
   005B0  STARTSAMPLE    0,9,0                   
   005B8  KEYON          0                       
   005BA  WAIT           1,31                    
   005BE  SILENCE        0                       
   005C0  STARTSAMPLE    0,9,0                   
   005C8  KEYON          0                       
   005CA  WAIT           1,8                     
   005CE  SILENCE        0                       
   005D0  STARTSAMPLE    0,9,0                   
   005D8  KEYON          0                       
   005DA  WAIT           1,16                    
   005DE  SILENCE        0                       
   005E0  STARTSAMPLE    0,9,0                   
   005E8  KEYON          0                       
   005EA  WAIT           1,43                    
   005EE  SILENCE        0                       
   005F0  END                                    
OBJ  20 @005F4 MACRO chan=any flags=00
   005F8  STARTSAMPLE    0,10,0                  
   00600  KEYON          0                       
   00602  WAIT           5,31                    
   00606  SILENCE        0                       
   00608  STARTSAMPLE    0,10,0                  
   00610  KEYON          0                       
   00612  WAIT           1,31                    
   00616  SILENCE        0                       
   00618  STARTSAMPLE    0,10,0                  
   00620  KEYON          0                       
   00622  WAIT           1,31                    
   00626  SILENCE        0                       
   00628  STARTSAMPLE    0,10,0                  
   00630  KEYON          0                       
   00632  WAIT           1,16                    
   00636  SILENCE        0                       
   00638  STARTSAMPLE    0,10,0                  
   00640  KEYON          0                       
   00642  WAIT           1,8                     
   00646  SILENCE        0                       
   00648  STARTSAMPLE    0,10,0                  
   00650  KEYON          0                       
   00652  WAIT           1,43                    
   00656  SILENCE        0                       
   00658  END                                    
OBJ  21 @0065C MACRO chan=any flags=00
   00660  STARTSAMPLE    0,11,0                  
   00668  KEYON          0                       
   0066A  WAIT           5,8                     
   0066E  SILENCE        0                       
   00670  STARTSAMPLE    0,11,0                  
   00678  KEYON          0                       
   0067A  WAIT           1,16                    
   0067E  SILENCE        0                       
   00680  STARTSAMPLE    0,11,0                  
   00688  KEYON          0                       
   0068A  WAIT           1,46                    
   0068E  SILENCE        0                       
   00690  STARTSAMPLE    0,11,0                  
   00698  KEYON          0                       
   0069A  WAIT           1,8                     
   0069E  SILENCE        0                       
   006A0  STARTSAMPLE    0,11,0                  
   006A8  KEYON          0                       
   006AA  WAIT           1,16                    
   006AE  SILENCE        0                       
   006B0  STARTSAMPLE    0,11,0                  
   006B8  KEYON          0                       
   006BA  WAIT           1,55                    
   006BE  SILENCE        0                       
   006C0  END                                    
OBJ  22 @006C4 MACRO chan=any flags=00
   006C8  STARTSAMPLE    0,12,0                  
   006D0  KEYON          0                       
   006D2  WAIT           5,46                    
   006D6  SILENCE        0                       
   006D8  STARTSAMPLE    0,12,0                  
   006E0  KEYON          0                       
   006E2  WAIT           1,16                    
   006E6  SILENCE        0                       
   006E8  STARTSAMPLE    0,12,0                  
   006F0  KEYON          0                       
   006F2  WAIT           1,31                    
   006F6  SILENCE        0                       
   006F8  STARTSAMPLE    0,12,0                  
   00700  KEYON          0                       
   00702  WAIT           1,8                     
   00706  SILENCE        0                       
   00708  STARTSAMPLE    0,12,0                  
   00710  KEYON          0                       
   00712  WAIT           1,8                     
   00716  SILENCE        0                       
   00718  STARTSAMPLE    0,12,0                  
   00720  KEYON          0                       
   00722  WAIT           1,31                    
   00726  SILENCE        0                       
   00728  END                                    
OBJ  23 @0072C MACRO chan=any flags=00
   00730  STARTSAMPLE    0,13,0                  
   00738  KEYON          0                       
   0073A  WAIT           5,31                    
   0073E  SILENCE        0                       
   00740  STARTSAMPLE    0,13,0                  
   00748  KEYON          0                       
   0074A  WAIT           1,16                    
   0074E  SILENCE        0                       
   00750  STARTSAMPLE    0,13,0                  
   00758  KEYON          0                       
   0075A  WAIT           1,31                    
   0075E  SILENCE        0                       
   00760  STARTSAMPLE    0,13,0                  
   00768  KEYON          0                       
   0076A  WAIT           1,31                    
   0076E  SILENCE        0                       
   00770  STARTSAMPLE    0,13,0                  
   00778  KEYON          0                       
   0077A  WAIT           1,16                    
   0077E  SILENCE        0                       
   00780  STARTSAMPLE    0,13,0                  
   00788  KEYON          0                       
   0078A  WAIT           1,31                    
   0078E  SILENCE        0                       
   00790  END                                    
OBJ  24 @00794 MACRO chan=any flags=00
   00798  STARTSAMPLE    0,14,0                  
   007A0  KEYON          0                       
   007A2  WAIT           5,16                    
   007A6  SILENCE        0                       
   007A8  STARTSAMPLE    0,14,0                  
   007B0  KEYON          0                       
   007B2  WAIT           1,31                    
   007B6  SILENCE        0                       
   007B8  STARTSAMPLE    0,14,0                  
   007C0  KEYON          0                       
   007C2  WAIT           1,8                     
   007C6  SILENCE        0                       
   007C8  STARTSAMPLE    0,14,0                  
   007D0  KEYON          0                       
   007D2  WAIT           1,16                    
   007D6  SILENCE        0                       
   007D8  STARTSAMPLE    0,14,0                  
   007E0  KEYON          0                       
   007E2  WAIT           1,46                    
   007E6  SILENCE        0                       
   007E8  STARTSAMPLE    0,14,0                  
   007F0  KEYON          0                       
   007F2  WAIT           1,31                    
   007F6  SILENCE        0                       
   007F8  STARTSAMPLE    0,14,0                  
   00800  KEYON          0                       
   00802  WAIT           1,31                    
   00806  SILENCE        0                       
   00808  END                                    
OBJ  25 @0080C MACRO chan=any flags=00
   00810  STARTSAMPLE    0,4,0                   
   00818  SETPITCH       19200                   
   0081C  KEYON          0                       
   0081E  WAIT           5,7                     
   00822  SILENCE        0                       
   00824  STARTSAMPLE    0,4,0                   
   0082C  SETPITCH       17920                   
   00830  KEYON          0                       
   00832  VIBRATO        4,73                    
   00836  WAIT           5,7                     
   0083A  FADE           0,9325                  
   0083E  SILENCE        0                       
   00840  STARTSAMPLE    0,4,0                   
   00848  SETPITCH       17408                   
   0084C  KEYON          0                       
   0084E  WAIT           5,7                     
   00852  FADE           0,9325                  
   00856  SILENCE        0                       
   00858  STARTSAMPLE    0,4,0                   
   00860  SETPITCH       18944                   
   00864  KEYON          0                       
   00866  WAIT           1,7                     
   0086A  FADE           0,9325                  
   0086E  SILENCE        0                       
   00870  WAIT           1,5                     
   00874  STARTSAMPLE    0,4,0                   
   0087C  SETPITCH       17920                   
   00880  KEYON          0                       
   00882  WAIT           1,10                    
   00886  FADE           0,2105                  
   0088A  SILENCE        0                       
   0088C  END                                    
OBJ  26 @00890 MACRO chan=any flags=00
   00894  PLAYMACRO      0,4,0,255,60            
   0089C  KEYON          0                       
   0089E  WAIT           1,7                     
   008A2  SILENCE        0                       
   008A4  PLAYMACRO      0,-5,0,255,60           
   008AC  KEYON          0                       
   008AE  WAIT           1,2                     
   008B2  SILENCE        0                       
   008B4  END                                    
OBJ  27 @008B8 MACRO chan=0 flags=01
   008BC  VOLUME         127                     
   008BE  PLAYMACRO      0,2,0,255,33            
   008C6  WAIT           1,1                     
   008CA  NOP                                    
   008CC  PSGDUTY        2                       
   008CE  KEYON          1                       
   008D0  PSGENV         10                      
   008D2  PITCHSWEEP     0,808,15360             
   008D8  VIBRATO        4,64                    
   008DC  WAIT           0,13                    
   008E0  VOLUME         127                     
   008E2  PSGENV         10                      
   008E4  PITCHSWEEP     0,808,15360             
   008EA  WAIT           0,7                     
   008EE  SILENCE        0                       
   008F0  PLAYMACRO      0,10,0,255,60           
   008F8  KEYON          0                       
   008FA  WAIT           1,2                     
   008FE  SILENCE        0                       
   00900  END                                    
OBJ  28 @00904 MACRO chan=any flags=00
   00908  STARTSAMPLE    0,4,0                   
   00910  KEYON          0                       
   00912  SETPITCH       16665                   
   00916  PITCHSWEEP     0,512,20480             
   0091C  WAIT           5,13                    
   00920  STARTSAMPLE    0,4,0                   
   00928  KEYON          0                       
   0092A  SETPITCH       16640                   
   0092E  PITCHSWEEP     1,209,12800             
   00934  WAIT           1,7                     
   00938  SILENCE        0                       
   0093A  END                                    
OBJ  29 @0093C MACRO chan=0 flags=01
   00940  NOP                                    
   00942  SETPITCH       22528                   
   00946  IFFLAG         0,1572                  -> 00F6A
   0094C  PANNING        0,0                     
   00950  SETFLAG        1,0                     
   00954  GOTO           1566                    -> 00F72
OBJ  30 @0097C MACRO chan=0 flags=01
   00980  NOP                                    
   00982  PSGDUTY        1                       
   00984  KEYON          0                       
   00986  PSGENV         9                       
   00988  VIBRATO        2,12864                 
   0098C  VOLUME         127                     
   0098E  WAIT           1,5                     
   00992  PSGENV         1                       
   00994  SILENCE        0                       
   00996  END                                    
OBJ  31 @00998 MACRO chan=any flags=00
   0099C  VOLUME         127                     
   0099E  STARTSAMPLE    0,17,0                  
   009A6  SETPITCH       14080                   
   009AA  KEYON          0                       
   009AC  PITCHSWEEP     1,-281,-25600           
   009B2  FADE           0,360                   
   009B6  WAIT           4,7                     
   009BA  FADE           0,2105                  
   009BE  WAIT           1,121                   
   009C2  FADE           0,1070                  
   009C6  SILENCE        0                       
   009C8  END                                    
OBJ  32 @009CC MACRO chan=any flags=00
   009D0  STARTSAMPLE    0,19,0                  
   009D8  KEYON          1                       
   009DA  SETPITCH       19200                   
   009DE  WAIT           4,-1                    
   009E2  END                                    
OBJ  33 @009E4 MACRO chan=any flags=00
   009E8  STARTSAMPLE    0,15,0                  
   009F0  KEYON          0                       
   009F2  WAIT           5,-1                    
   009F6  FADE           0,2105                  
   009FA  WAIT           4,31                    
   009FE  SILENCE        0                       
   00A00  END                                    
OBJ  34 @00A04 MACRO chan=0 flags=01
   00A08  VOLUME         127                     
   00A0A  PLAYMACRO      0,0,0,255,33            
   00A12  WAIT           1,1                     
   00A16  NOP                                    
   00A18  PSGDUTY        2                       
   00A1A  KEYON          1                       
   00A1C  PSGENV         10                      
   00A1E  PITCHSWEEP     0,808,15360             
   00A24  VIBRATO        4,64                    
   00A28  WAIT           0,19                    
   00A2C  VOLUME         127                     
   00A2E  PSGENV         10                      
   00A30  PITCHSWEEP     0,808,15360             
   00A36  WAIT           0,13                    
   00A3A  SILENCE        0                       
   00A3C  END                                    
OBJ  35 @00A40 MACRO chan=any flags=00
   00A44  STARTSAMPLE    0,21,0                  
   00A4C  SETPITCH       15360                   
   00A50  KEYON          0                       
   00A52  WAIT           5,7                     
   00A56  FADE           0,9325                  
   00A5A  ADDPITCH       1,6149                  
   00A5E  WAIT           5,7                     
   00A62  FADE           0,9325                  
   00A66  ADDPITCH       1,7173                  
   00A6A  WAIT           5,7                     
   00A6E  FADE           0,2611                  
   00A72  ADDPITCH       1,6144                  
   00A76  WAIT           1,7                     
   00A7A  FADE           0,1764                  
   00A7E  SILENCE        0                       
   00A80  END                                    
OBJ  36 @00A84 MACRO chan=1 flags=01
   00A88  NOP                                    
   00A8A  PSGDUTY        3                       
   00A8C  KEYON          0                       
   00A8E  PSGENV         9                       
   00A90  VIBRATO        2,12864                 
   00A94  WAIT           0,4                     
   00A98  WAIT           1,4                     
   00A9C  PSGENV         1                       
   00A9E  WAIT           0,4                     
   00AA2  SILENCE        0                       
   00AA4  PLAYMACRO      0,0,0,255,61            
   00AAC  END                                    
OBJ  37 @00AB0 MACRO chan=1 flags=01
   00AB4  NOP                                    
   00AB6  PSGDUTY        3                       
   00AB8  KEYON          0                       
   00ABA  PSGENV         9                       
   00ABC  VIBRATO        2,12864                 
   00AC0  WAIT           0,4                     
   00AC4  WAIT           1,4                     
   00AC8  PSGENV         1                       
   00ACA  VOLUME         127                     
   00ACC  WAIT           0,4                     
   00AD0  SILENCE        0                       
   00AD2  PLAYMACRO      0,0,0,255,41            
   00ADA  END                                    
OBJ  38 @00ADC MACRO chan=1 flags=01
   00AE0  NOP                                    
   00AE2  KEYON          0                       
   00AE4  PSGENV         10                      
   00AE6  PITCHSWEEP     1,2363,30720            
   00AEC  VIBRATO        4,64                    
   00AF0  WAIT           0,16                    
   00AF4  PLAYMACRO      0,0,0,255,48            
   00AFC  SILENCE        0                       
   00AFE  END                                    
OBJ  39 @00B00 MACRO chan=3 flags=00
   00B04  NOP                                    
   00B06  KEYON          0                       
   00B08  PSGENV         10                      
   00B0A  PITCHSWEEP     1,2363,30720            
   00B10  VIBRATO        4,64                    
   00B14  WAIT           0,16                    
   00B18  PLAYMACRO      0,0,0,255,42            
   00B20  SILENCE        0                       
   00B22  END                                    
OBJ  40 @00B24 MACRO chan=3 flags=00
   00B28  NOP                                    
   00B2A  KEYON          0                       
   00B2C  PSGENV         9                       
   00B2E  PITCHSWEEP     1,2363,30720            
   00B34  VIBRATO        4,64                    
   00B38  WAIT           0,11                    
   00B3C  PSGENV         2                       
   00B3E  VOLUME         127                     
   00B40  FADE           0,5021                  
   00B44  WAIT           0,19                    
   00B48  SILENCE        0                       
   00B4A  END                                    
OBJ  41 @00B4C MACRO chan=any flags=00
   00B50  PLAYMACRO      0,0,0,255,42            
   00B58  PLAYMACRO      0,0,0,255,43            
   00B60  END                                    
OBJ  42 @00B64 MACRO chan=any flags=00
   00B68  STARTSAMPLE    0,4,0                   
   00B70  SETPITCH       16384                   
   00B74  KEYON          0                       
   00B76  WAIT           5,5                     
   00B7A  FADE           0,5021                  
   00B7E  ADDPITCH       1,1792                  
   00B82  FADE           0,3435                  
   00B86  VIBRATO        31,9                    
   00B8A  WAIT           4,5                     
   00B8E  ADDPITCH       1,3072                  
   00B92  FADE           0,2611                  
   00B96  WAIT           5,5                     
   00B9A  SILENCE        0                       
   00B9C  END                                    
OBJ  43 @00BA0 MACRO chan=any flags=00
   00BA4  STARTSAMPLE    0,4,0                   
   00BAC  KEYON          0                       
   00BAE  SETPITCH       15360                   
   00BB2  WAIT           5,5                     
   00BB6  FADE           0,5021                  
   00BBA  ADDPITCH       1,1024                  
   00BBE  FADE           0,3435                  
   00BC2  VIBRATO        31,9                    
   00BC6  WAIT           4,5                     
   00BCA  ADDPITCH       1,1792                  
   00BCE  FADE           0,2611                  
   00BD2  WAIT           5,5                     
   00BD6  SILENCE        0                       
   00BD8  END                                    
OBJ  44 @00BDC MACRO chan=any flags=00
   00BE0  VOLUME         43                      
   00BE2  STARTSAMPLE    0,4,0                   
   00BEA  KEYON          0                       
   00BEC  SETPITCH       15360                   
   00BF0  WAIT           5,4                     
   00BF4  FADE           0,5021                  
   00BF8  ADDPITCH       1,1280                  
   00BFC  FADE           0,3435                  
   00C00  VIBRATO        31,9                    
   00C04  WAIT           4,4                     
   00C08  ADDPITCH       1,3072                  
   00C0C  FADE           0,2611                  
   00C10  WAIT           5,4                     
   00C14  SILENCE        0                       
   00C16  END                                    
OBJ  45 @00C18 MACRO chan=any flags=00
   00C1C  VOLUME         101                     
   00C1E  PLAYMACRO      0,0,0,255,9             
   00C26  VOLUME         127                     
   00C28  STARTSAMPLE    0,17,0                  
   00C30  KEYON          0                       
   00C32  WAIT           4,-1                    
   00C36  END                                    
OBJ  46 @00C38 MACRO chan=0 flags=01
   00C3C  NOP                                    
   00C3E  IFFLAG         0,812                   -> 00F6A
   00C44  VOLUME         127                     
   00C46  PSGDUTY        1                       
   00C48  PSGENV         2                       
   00C4A  SETPITCH       18432                   
   00C4E  KEYON          0                       
   00C50  WAIT           0,10                    
   00C54  VIBRATO        5,7                     
   00C58  WAIT           0,31                    
   00C5C  SILENCE        0                       
   00C5E  END                                    
OBJ  47 @00C60 MACRO chan=any flags=00
   00C64  STARTSAMPLE    0,20,0                  
   00C6C  SETPITCH       16640                   
   00C70  KEYON          0                       
   00C72  WAIT           5,3                     
   00C76  FADE           0,539                   
   00C7A  ADDPITCH       1,2309                  
   00C7E  VIBRATO        4,-54                   
   00C82  WAIT           5,7                     
   00C86  FADE           0,9325                  
   00C8A  ADDPITCH       1,1280                  
   00C8E  WAIT           5,7                     
   00C92  FADE           0,9325                  
   00C96  ADDPITCH       1,2176                  
   00C9A  VOLUME         127                     
   00C9C  WAIT           1,7                     
   00CA0  FADE           0,4080                  
   00CA4  SILENCE        0                       
   00CA6  END                                    
OBJ  48 @00CA8 MACRO chan=any flags=00
   00CAC  AGESPEED       255                     
   00CAE  STARTSAMPLE    0,4,0                   
   00CB6  KEYON          0                       
   00CB8  SETPITCH       30874                   
   00CBC  PITCHSWEEP     1,-660,-20480           
   00CC2  WAIT           5,13                    
   00CC6  FADE           0,3435                  
   00CCA  WAIT           4,16                    
   00CCE  SILENCE        0                       
   00CD0  END                                    
OBJ  49 @00CD4 MACRO chan=any flags=00
   00CD8  AGESPEED       255                     
   00CDA  STARTSAMPLE    0,4,0                   
   00CE2  KEYON          0                       
   00CE4  SETPITCH       20634                   
   00CE8  PITCHSWEEP     1,-372,-20480           
   00CEE  WAIT           5,13                    
   00CF2  FADE           0,2105                  
   00CF6  ADDPITCH       1,7680                  
   00CFA  PITCHSWEEP     1,335,20480             
   00D00  WAIT           4,31                    
   00D04  FADE           0,9325                  
   00D08  SILENCE        0                       
   00D0A  END                                    
OBJ  50 @00D0C MACRO chan=any flags=00
   00D10  STARTSAMPLE    0,4,0                   
   00D18  SETPITCH       19456                   
   00D1C  KEYON          0                       
   00D1E  WAIT           5,4                     
   00D22  FADE           0,309                   
   00D26  ADDPITCH       1,4869                  
   00D2A  VIBRATO        4,-54                   
   00D2E  WAIT           5,5                     
   00D32  FADE           0,9325                  
   00D36  ADDPITCH       1,4357                  
   00D3A  WAIT           5,7                     
   00D3E  FADE           0,9325                  
   00D42  ADDPITCH       1,3840                  
   00D46  WAIT           1,6                     
   00D4A  FADE           0,9325                  
   00D4E  ADDPITCH       1,4608                  
   00D52  WAIT           1,7                     
   00D56  FADE           0,6528                  
   00D5A  ADDPITCH       1,3328                  
   00D5E  WAIT           1,7                     
   00D62  FADE           0,2105                  
   00D66  ADDPITCH       1,3072                  
   00D6A  VOLUME         127                     
   00D6C  WAIT           1,7                     
   00D70  FADE           0,9325                  
   00D74  VOLUME         127                     
   00D76  ADDPITCH       1,20480                 
   00D7A  WAIT           1,4                     
   00D7E  FADE           0,165                   
   00D82  SILENCE        0                       
   00D84  END                                    
OBJ  51 @00D88 MACRO chan=any flags=00
   00D8C  STARTSAMPLE    0,3,0                   
   00D94  KEYON          0                       
   00D96  SETPITCH       22528                   
   00D9A  WAIT           5,19                    
   00D9E  FADE           0,2331                  
   00DA2  SILENCE        0                       
   00DA4  END                                    
OBJ  52 @00DA8 MACRO chan=any flags=00
   00DAC  STARTSAMPLE    0,1,0                   
   00DB4  SETPITCH       17920                   
   00DB8  KEYON          0                       
   00DBA  FADE           0,9325                  
   00DBE  WAIT           4,1                     
   00DC2  END                                    
OBJ  53 @00DC4 MACRO chan=any flags=00
   00DC8  STARTSAMPLE    0,17,0                  
   00DD0  SETPITCH       15360                   
   00DD4  KEYON          0                       
   00DD6  PITCHSWEEP     0,-335,-20480           
   00DDC  WAIT           4,-1                    
   00DE0  END                                    
OBJ  54 @00DE4 MACRO chan=any flags=00
   00DE8  STARTSAMPLE    0,17,0                  
   00DF0  SETPITCH       10240                   
   00DF4  KEYON          0                       
   00DF6  PITCHSWEEP     0,251,15360             
   00DFC  WAIT           4,-1                    
   00E00  END                                    
OBJ  55 @00E04 MACRO chan=any flags=00
   00E08  STARTSAMPLE    0,1,0                   
   00E10  SETPITCH       12800                   
   00E14  KEYON          0                       
   00E16  WAIT           4,1                     
   00E1A  END                                    
OBJ  56 @00E1C MACRO chan=any flags=00
   00E20  VOLUME         100                     
   00E22  STARTSAMPLE    128,4,0                 
   00E2A  KEYON          0                       
   00E2C  SETPITCH       21504                   
   00E30  WAIT           5,7                     
   00E34  FADE           0,5021                  
   00E38  ADDPITCH       1,1280                  
   00E3C  FADE           0,3435                  
   00E40  VIBRATO        13,22                   
   00E44  WAIT           4,5                     
   00E48  ADDPITCH       1,0                     
   00E4C  FADE           0,9325                  
   00E50  WAIT           5,7                     
   00E54  SILENCE        0                       
   00E56  END                                    
OBJ  57 @00E58 MACRO chan=any flags=00
   00E5C  STARTSAMPLE    0,4,0                   
   00E64  KEYON          0                       
   00E66  SETPITCH       14080                   
   00E6A  WAIT           5,7                     
   00E6E  FADE           0,5021                  
   00E72  ADDPITCH       1,1280                  
   00E76  FADE           0,3435                  
   00E7A  VIBRATO        31,9                    
   00E7E  WAIT           4,5                     
   00E82  ADDPITCH       1,2304                  
   00E86  FADE           0,2611                  
   00E8A  WAIT           5,7                     
   00E8E  SILENCE        0                       
   00E90  END                                    
OBJ  58 @00E94 MACRO chan=any flags=00
   00E98  STARTSAMPLE    0,4,0                   
   00EA0  KEYON          0                       
   00EA2  SETPITCH       12800                   
   00EA6  WAIT           5,7                     
   00EAA  FADE           0,5021                  
   00EAE  ADDPITCH       1,2816                  
   00EB2  FADE           0,3435                  
   00EB6  VIBRATO        31,9                    
   00EBA  WAIT           4,7                     
   00EBE  ADDPITCH       1,1792                  
   00EC2  FADE           0,2611                  
   00EC6  WAIT           5,7                     
   00ECA  SILENCE        0                       
   00ECC  END                                    
OBJ  59 @00ED0 MACRO chan=any flags=00
   00ED4  AGESPEED       255                     
   00ED6  STARTSAMPLE    0,4,0                   
   00EDE  KEYON          0                       
   00EE0  SETPITCH       20634                   
   00EE4  PITCHSWEEP     1,-372,-20480           
   00EEA  WAIT           5,13                    
   00EEE  FADE           0,2105                  
   00EF2  WAIT           4,16                    
   00EF6  SILENCE        0                       
   00EF8  END                                    
OBJ  60 @00EFC MACRO chan=any flags=00
   00F00  STARTSAMPLE    0,16,0                  
   00F08  KEYON          0                       
   00F0A  WAIT           4,-1                    
   00F0E  END                                    
OBJ  61 @00F10 MACRO chan=any flags=00
   00F14  STARTSAMPLE    0,18,0                  
   00F1C  KEYON          0                       
   00F1E  WAIT           4,-1                    
   00F22  END                                    
OBJ  62 @00F24 MACRO chan=any flags=00
   00F28  SCALEVOL       0,0,100                 
   00F2E  PULSESWEEP     1,1,63,634              
   00F34  KEYON          0                       
   00F36  SETPITCH       19303                   
   00F3A  PITCHSWEEP     1,677,12877             
   00F40  WAIT           1,5                     
   00F44  SILENCE        0                       
   00F46  WAIT           0,1                     
   00F4A  KEYON          0                       
   00F4C  SILENCE        1                       
   00F4E  END                                    
OBJ  63 @00F50 MACRO chan=0 flags=01
   00F54  NOP                                    
   00F56  IFFLAG         0,20                    -> 00F6A
   00F5C  PANNING        0,0                     
   00F60  SETFLAG        1,0                     
   00F64  GOTO           14                      -> 00F72
   00F6A  PANNING        127,0                   
   00F6E  SETFLAG        0,0                     
   00F72  VOLUME         127                     
   00F74  PSGDUTY        2                       
   00F76  PSGENV         2                       
   00F78  KEYON          0                       
   00F7A  WAIT           0,10                    
   00F7E  VIBRATO        5,7                     
   00F82  WAIT           0,31                    
   00F86  SILENCE        0                       
   00F88  END                                    
OBJ  64 @00F8C MACRO chan=0 flags=01
   00F90  NOP                                    
   00F92  VOLUME         127                     
   00F94  PSGDUTY        2                       
   00F96  PSGENV         2                       
   00F98  KEYON          0                       
   00F9A  WAIT           0,10                    
   00F9E  VIBRATO        5,7                     
   00FA2  WAIT           1,13                    
   00FA6  SILENCE        0                       
   00FA8  END                                    
OBJ  65 @00FAC MACRO chan=any flags=00
   00FB0  AGESPEED       128                     
   00FB2  KEYMAP         66,-36                  
   00FB8  KEYON          0                       
   00FBA  REVERB         1                       
   00FBC  WAIT           1,-1                    
   00FC0  SILENCE        0                       
   00FC2  END                                    
OBJ  66 @00FC4 KEYMAP (7 keys)
   key   0: sample  27  pitch  +9216  pan   +0  b5 0  fixedPitch 0  b7 0
   key   1: sample  26  pitch  +5888  pan   +0  b5 0  fixedPitch 0  b7 0
   key   2: sample  25  pitch  +5632  pan   +0  b5 0  fixedPitch 0  b7 0
   key   3: sample  24  pitch  +5376  pan   +0  b5 0  fixedPitch 0  b7 0
   key   4: sample  24  pitch  +5120  pan   +0  b5 0  fixedPitch 0  b7 0
   key   5: sample  23  pitch  +4864  pan   +0  b5 0  fixedPitch 0  b7 0
   key   6: sample  22  pitch  +4608  pan   +0  b5 0  fixedPitch 0  b7 0
OBJ  67 @01004 MACRO chan=0 flags=01
   01008  NOP                                    
   0100A  VOLUME         37                      
   0100C  PSGDUTY        2                       
   0100E  PSGENV         1                       
   01010  KEYON          0                       
   01012  WAIT           0,10                    
   01016  VOLUME         30                      
   01018  WAIT           0,1                     
   0101C  PSGENV         3                       
   0101E  WAIT           0,13                    
   01022  WAIT           0,13                    
   01026  SILENCE        0                       
   01028  END                                    
OBJ  68 @0102C MACRO chan=any flags=00
   01030  STARTSAMPLE    0,28,0                  
   01038  VOLUME         127                     
   0103A  KEYON          0                       
   0103C  WAIT           1,-1                    
   01040  FADE           0,3435                  
   01044  SILENCE        0                       
   01046  END                                    
OBJ  69 @01048 MACRO chan=any flags=00
   0104C  STARTSAMPLE    0,29,0                  
   01054  VOLUME         127                     
   01056  PANNING        27,0                    
   0105A  KEYON          0                       
   0105C  WAIT           1,31                    
   01060  FADE           0,2105                  
   01064  SILENCE        0                       
   01066  END                                    
OBJ  70 @01068 MACRO chan=any flags=00
   0106C  STARTSAMPLE    0,30,0                  
   01074  KEYON          0                       
   01076  WAIT           1,31                    
   0107A  FADE           0,2105                  
   0107E  SILENCE        0                       
   01080  END                                    
OBJ  71 @01084 MACRO chan=any flags=00
   01088  STARTSAMPLE    0,31,0                  
   01090  KEYON          0                       
   01092  WAIT           1,31                    
   01096  FADE           0,2105                  
   0109A  SILENCE        0                       
   0109C  END                                    
OBJ  72 @010A0 MACRO chan=any flags=00
   010A4  STARTSAMPLE    0,32,0                  
   010AC  KEYON          0                       
   010AE  WAIT           5,31                    
   010B2  FADE           0,2105                  
   010B6  WAIT           4,31                    
   010BA  SILENCE        0                       
   010BC  END                                    
OBJ  73 @010C0 MACRO chan=any flags=00
   010C4  STARTSAMPLE    0,33,0                  
   010CC  KEYON          0                       
   010CE  WAIT           5,31                    
   010D2  FADE           0,2105                  
   010D6  WAIT           4,31                    
   010DA  SILENCE        0                       
   010DC  END                                    
OBJ  74 @010E0 MACRO chan=any flags=00
   010E4  STARTSAMPLE    0,40,0                  
   010EC  KEYON          0                       
   010EE  WAIT           5,31                    
   010F2  FADE           0,2105                  
   010F6  WAIT           4,31                    
   010FA  SILENCE        0                       
   010FC  END                                    
OBJ  75 @01100 MACRO chan=any flags=00
   01104  STARTSAMPLE    0,41,0                  
   0110C  KEYON          0                       
   0110E  WAIT           5,31                    
   01112  FADE           0,2105                  
   01116  WAIT           4,31                    
   0111A  SILENCE        0                       
   0111C  END                                    
OBJ  76 @01120 MACRO chan=0 flags=01
   01124  NOP                                    
   01126  VOLUME         127                     
   01128  PSGDUTY        1                       
   0112A  KEYON          1                       
   0112C  WAIT           0,1                     
   01130  PSGDUTY        2                       
   01132  KEYON          1                       
   01134  ADDPITCH       1,3072                  
   01138  PSGENV         2                       
   0113A  END                                    
OBJ  77 @0113C MACRO chan=any flags=00
   01140  AGESPEED       150                     
   01142  STARTSAMPLE    0,42,0                  
   0114A  KEYON          0                       
   0114C  WAIT           5,31                    
   01150  FADE           0,2105                  
   01154  WAIT           4,31                    
   01158  SILENCE        0                       
   0115A  END                                    
OBJ  78 @0115C MACRO chan=any flags=00
   01160  PSGDUTY        2                       
   01162  KEYON          0                       
   01164  WAIT           1,31                    
   01168  SILENCE        0                       
   0116A  END                                    
OBJ  79 @0116C MACRO chan=any flags=00
   01170  PSGDUTY        2                       
   01172  KEYON          0                       
   01174  VOLUME         70                      
   01176  WAIT           0,1                     
   0117A  PSGENV         1                       
   0117C  WAIT           0,13                    
   01180  SILENCE        0                       
   01182  END                                    
OBJ  80 @01184 KEYMAP (12 keys)
   key   0: sample  37  pitch  +6144  pan   +0  b5 0  fixedPitch 0  b7 0
   key   1: sample  19  pitch  +5888  pan   +0  b5 0  fixedPitch 0  b7 0
   key   2: sample  35  pitch  +5632  pan  +20  b5 0  fixedPitch 0  b7 0
   key   3: sample  36  pitch  +5376  pan   +0  b5 0  fixedPitch 0  b7 0
   key   4: sample  35  pitch  +5120  pan  +30  b5 0  fixedPitch 0  b7 0
   key   5: sample  39  pitch  +3584  pan  -64  b5 0  fixedPitch 0  b7 0
   key   6: sample  34  pitch  +4608  pan  -32  b5 0  fixedPitch 0  b7 0
   key   7: sample  39  pitch  +3840  pan  -16  b5 0  fixedPitch 0  b7 0
   key   8: sample  34  pitch  +4096  pan  -35  b5 0  fixedPitch 0  b7 0
   key   9: sample  39  pitch  +3840  pan   +0  b5 0  fixedPitch 0  b7 0
   key  10: sample  38  pitch  +3584  pan  -38  b5 0  fixedPitch 0  b7 0
   key  11: sample  39  pitch  +4096  pan  +32  b5 0  fixedPitch 0  b7 0
OBJ  81 @011EC MACRO chan=any flags=00
   011F0  PANNING        10,0                    
   011F4  PULSESWEEP     5,5,63,24               
   011FA  KEYON          1                       
   011FC  FADE           0,5021                  
   01200  WAIT           0,3                     
   01204  PULSESWEEP     10,10,32,181            
   0120A  WAIT           0,5                     
   0120E  FADE           0,2105                  
   01212  WAIT           1,25                    
   01216  VIBRATO        8,16                    
   0121A  WAIT           1,31                    
   0121E  FADE           0,9325                  
   01222  SILENCE        1                       
   01224  END                                    
OBJ  82 @01228 MACRO chan=any flags=00
   0122C  AGESPEED       128                     
   0122E  KEYMAP         80,-36                  
   01234  KEYON          0                       
   01236  REVERB         1                       
   01238  SPLITKEY       47,12                   -> 01244
   0123E  SPLITKEY       46,14                   -> 0124C
   01244  WAIT           1,-1                    
   01248  SILENCE        0                       
   0124A  STOP                                   
   0124C  WAIT           1,-1                    
   01250  SILENCE        0                       
   01252  END                                    
```
