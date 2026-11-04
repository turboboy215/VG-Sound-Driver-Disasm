# RADriver — data dump (PK, AI, MO, PM, NFSU)

Decoded sound banks, sample headers, sequenced-song summaries and streamed-music tables. Companion to `radriver-technical-reference.md`.

```
==============================================================================
Punch King: Arcade Boxing (E)  [PK]
==============================================================================
mix rate 22050 Hz, 12 voices (arguments passed to snd_init by the game)

Sound bank @ 0x812b588: songCount=17 sampleCount=100 songTable=0x812b598 sampleTable=0x812b620

  #   address    type    length  loopStart  seconds@11025
    0 0x801fcd8  PCM8      9310          0    0.84
    1 0x8022448  PCM8      2434          0    0.22
    2 0x80230dc  PCM8      4445          0    0.40
    3 0x802454c  PCM8      4128          0    0.37
    4 0x802587c  PCM8     21857          0    1.98
    5 0x802b0f0  PCM8      8313          0    0.75
    6 0x802d47c  PCM8     19042          0    1.73
    7 0x80321f0  PCM8     19555          0    1.77
    8 0x8037164  PCM8     12287          0    1.11
    9 0x803a474  PCM8     15682          0    1.42
   10 0x803e4c8  PCM8     13140          0    1.19
   11 0x8041b2c  PCM8     24258          0    2.20
   12 0x8047d00  PCM8     13121          0    1.19
   13 0x804b354  PCM8     16384          0    1.49
   14 0x804f664  PCM8     22768          0    2.07
   15 0x8055264  PCM8     10154          0    0.92
   16 0x8057d20  PCM8     18849          0    1.71
   17 0x805c9d4  PCM8     21841          0    1.98
   18 0x8062238  PCM8     15499          0    1.41
   19 0x80661d4  PCM8      7811          0    0.71
   20 0x8068368  PCM8      8440          0    0.77
   21 0x806a770  PCM8      8641          0    0.78
   22 0x806cc44  PCM8     10467          0    0.95
   23 0x806f838  PCM8      8820          0    0.80
   24 0x8071dbc  PCM8      7185          0    0.65
   25 0x8073ce0  PCM8      9377          0    0.85
   26 0x8076494  PCM8      9282          0    0.84
   27 0x8078be8  PCM8     10689          0    0.97
   28 0x807b8bc  PCM8      8291          0    0.75
   29 0x807dc30  PCM8      5410          0    0.49
   30 0x807f464  PCM8      9325          0    0.85
   31 0x8081be4  PCM8     13474          0    1.22
   32 0x8085398  PCM8     10392          0    0.94
   33 0x8087f40  PCM8      5169          0    0.47
   34 0x8089684  PCM8      7497          0    0.68
   35 0x808b6e0  PCM8      5405          0    0.49
   36 0x808cf10  PCM8     10284          0    0.93
   37 0x808fa4c  PCM8      4869          0    0.44
   38 0x8091064  PCM8      8619          0    0.78
   39 0x8093520  PCM8      6178          0    0.56
   40 0x8095054  PCM8      9825          0    0.89
   41 0x80979c8  PCM8      9462          0    0.86
   42 0x809a1d0  PCM8     11103          0    1.01
   43 0x809d040  PCM8      5860          0    0.53
   44 0x809ea34  PCM8      7863          0    0.71
   45 0x80a0bfc  PCM8     11466          0    1.04
   46 0x80a3bd8  PCM8      3525          0    0.32
   47 0x80a4cb0  PCM8     12087          0    1.10
   48 0x80a7ef8  PCM8      6444          0    0.58
   49 0x80a9b34  PCM8      8799          0    0.80
   50 0x80ac0a4  PCM8      6601          0    0.60
   51 0x80add80  PCM8      6510          0    0.59
   52 0x80afa00  PCM8      5843          0    0.53
   53 0x80b13e4  PCM8      6520          0    0.59
   54 0x80b306c  PCM8     11294          0    1.02
   55 0x80b5f9c  PCM8     16382          0    1.49
   56 0x80ba2ac  PCM8      6291          0    0.57
   57 0x80bbe50  PCM8      4627          0    0.42
   58 0x80bd374  PCM8      3304          0    0.30
   59 0x80be36c  PCM8     26487          0    2.40
   60 0x80c4df4  PCM8     21760          0    1.97
   61 0x80ca604  PCM8     12368          0    1.12
   62 0x80cd964  PCM8     15842          0    1.44
   63 0x80d1a58  PCM8     27359          0    2.48
   64 0x80d8848  PCM8      1334          0    0.12
   65 0x80d9090  PCM8      8177          0    0.74
   66 0x80db394  PCM8     34661          0    3.14
   67 0x80e3e0c  PCM8      1763          0    0.16
   68 0x80e4800  PCM8      1690          0    0.15
   69 0x80e51ac  PCM8      3595          0    0.33
   70 0x80e62c8  PCM8     18047          0    1.64
   71 0x80eac58  PCM8      7764          0    0.70
   72 0x80ecdbc  PCM8      5121          0    0.46
   73 0x80ee4d0  PCM8      1341          0    0.12
   74 0x80eed20  PCM8      2461          0    0.22
   75 0x80ef9d0  PCM8      4107          0    0.37
   76 0x80f0cec  PCM8     12271          0    1.11
   77 0x80f3fec  PCM8      8630          0    0.78
   78 0x80f64b4  PCM8      8749          0    0.79
   79 0x80f89f4  PCM8     11995          0    1.09
   80 0x80fbbe0  PCM8      8507          0    0.77
   81 0x80fe02c  PCM8      9292          0    0.84
   82 0x8100788  PCM8     16133       7275    1.46   (looped)
   83 0x81049a0  PCM8     12079          0    1.10
   84 0x8107be0  PCM8      1710          0    0.16
   85 0x81085a0  PCM8      1710          0    0.16
   86 0x8108f60  PCM8      4708          0    0.43
   87 0x810a4d4  PCM8      3883          0    0.35
   88 0x810b710  PCM8     14638       5062    1.33   (looped)
   89 0x810f350  PCM8      3032          0    0.28
   90 0x8110238  PCM8      4329       1990    0.39   (looped)
   91 0x8111634  PCM8     22035      10335    2.00   (looped)
   92 0x8116f58  PCM8     18609       4994    1.69   (looped)
   93 0x811bb1c  PCM8     12318          0    1.12
   94 0x811ee4c  PCM8      2246          0    0.20
   95 0x811fa24  PCM8      6085          0    0.55
   96 0x81214fc  PCM8       961          0    0.09
   97 0x8121bd0  PCM8      7423       3342    0.67   (looped)
   98 0x8123be0  PCM8     17605       7165    1.60   (looped)
   99 0x81283b8  PCM8     11967          0    1.09

  Sequenced songs (event-stream format, see technical reference section 7)
  #   start      loop       bytes  MIDI ch used                 progs  keys    ticks   tempo(t/frame) ~len   terminator
   0  0x8000404 0x8000404   7773  4,5,6,7,8,10,11,12,13,14,15   11    57-79   19206    4.000       80.4s  B0 B3 (loop)
   1  0x8002264 0x8002264   3019  4,5,6,7,8,10,11,12             8    56-64   23040    4.667       82.7s  B0 B3 (loop)
   2  0x8002e30 0x8002e30   8171  4,6,12,13,14,15                6    47-71   21600    4.000       90.4s  B0 B3 (loop)
   3  0x8004e1c 0x8004e1c   8779  4,5,11,12,13,14,15             7    61-80   23040    4.667       82.7s  B0 B3 (loop)
   4  0x8007068 0x8007068  10123  4,5,6,12,13,14,15              7    58-79   19200    3.667       87.7s  B0 B3 (loop)
   5  0x80097f4 0x80097f4  10071  8,10,12,13,14                  5    45-76   23040    4.000       96.4s  B0 B3 (loop)
   6  0x800bf4c 0x800bf4c    201  4                              1    52-73   24960    4.000      104.5s  B0 B3 (loop)
   7  0x800c018 0x800c018   2429  4,5,6,7,8,12                   6    45-63    7680    4.067       31.6s  B0 B3 (loop)
   8  0x800c998 0x800c998   9053  4,5,6,10,11,12                 6    59-77   24000    4.333       92.7s  B0 B3 (loop)
   9  0x800ecf8 0x800ecf8  10523  4,5,6,12,13,14,15              7    48-80   25440    4.667       91.3s  B0 B3 (loop)
  10  0x8011614 0x8011614  10767  4,5,6,7,8,12,13,14,15          9    48-74   24960    4.667       89.5s  B0 B3 (loop)
  11  0x8014024 0x8014024  11045  4,5,10,12,13,14,15             6    41-75   24960    4.667       89.5s  B0 B3 (loop)
  12  0x8016b4c 0x8016b4c   7949  4,5,7,12,13                    5    54-77   23040    4.000       96.4s  B0 B3 (loop)
  13  0x8018a5c 0x8018a5c   3771  4,6,12,13,14,15                6    48-67    9600    4.667       34.4s  B0 B3 (loop)
  14  0x8019918 0x8019918  12495  4,5,6,12,13,14,15              7    46-87   24960    4.333       96.4s  B0 B3 (loop)
  15  0x801c9e8 0x801c9e8  11193  4,5,6,7,8,10,11,12,13,14,15   11    38-79   23044    4.333       89.0s  B0 B3 (loop)
  16  0x801f5a4 0x801f5a4   1843  4,6,7,8,10,11                  6    40-69    3840    4.000       16.1s  B0 B3 (loop)

==============================================================================
Aggressive Inline (E)  [AI]
==============================================================================
mix rate 11025 Hz, 2 voices (arguments passed to snd_init by the game)

Sound bank @ 0x8031608: songCount=0 sampleCount=30 songTable=0x8031618 sampleTable=0x8031618

  #   address    type    length  loopStart  seconds@11025
    0 0x8000284  PCM8     17839       4543    1.62   (looped)
    1 0x8004b44  PCM8      4502          0    0.41
    2 0x8005fec  PCM8      1578          0    0.14
    3 0x8006928  PCM8      4272          0    0.39
    4 0x8007ce8  PCM8      4927          0    0.45
    5 0x8009338  PCM8      8225          0    0.75
    6 0x800b66c  PCM8      7392          0    0.67
    7 0x800d65c  PCM8      8782          0    0.80
    8 0x800fbbc  PCM8      2848          0    0.26
    9 0x80109ec  PCM8      8445          0    0.77
   10 0x8012dfc  PCM8      7545          0    0.68
   11 0x8014e88  PCM8     13927          0    1.26
   12 0x8018800  PCM8      3107          0    0.28
   13 0x8019734  PCM8      3456          0    0.31
   14 0x801a7c4  PCM8     11262          0    1.02
   15 0x801d6d4  PCM8      4410          0    0.40
   16 0x801eb20  PCM8      4167          0    0.38
   17 0x801fe78  PCM8      3384          0    0.31
   18 0x8020ec0  PCM8      3424          0    0.31
   19 0x8021f30  PCM8      3808          0    0.35
   20 0x8023120  PCM8      2168          0    0.20
   21 0x8023ca8  PCM8      4934          0    0.45
   22 0x8025300  PCM8     10992          0    1.00
   23 0x8028100  PCM8      3646          0    0.33
   24 0x8029250  PCM8      6596          0    0.60
   25 0x802af24  PCM8      6906          0    0.63
   26 0x802cd30  PCM8      3811          0    0.35
   27 0x802df24  PCM8      6297          0    0.57
   28 0x802fad0  PCM8      2896          0    0.26
   29 0x8030930  PCM8      2503          0    0.23

  Streamed (block + order-list) music table @ 0x806aedc

  stream 0: block table 0x806ac58 (5 blocks), order list 0x806ac6c
     block  0 0x8262fb0 type ADPCM   12438 B =   24876 samples =   2.26s
     block  1 0x8266058 type ADPCM    3275 B =    6550 samples =   0.59s
     block  2 0x8266d34 type ADPCM    9234 B =   18468 samples =   1.68s
     block  3 0x8269158 type ADPCM    9189 B =   18378 samples =   1.67s
     block  4 0x826b550 type ADPCM   99827 B =  199654 samples =  18.11s
     block data 133963 B; order list 174 entries + -1 terminator:
       0 0 0 0 1 2 1 2 1 2 1 3 1 2 1 2 1 2 1 3 4 1 2 1 2 1 2 1 3 1 2 1 2 1 2 1 3 4 1 2 1 2 1 2 1 3 1 2 1 2
       1 2 1 3 4 1 2 1 2 1 2 1 3 1 2 1 2 1 2 1 3 4 1 2 1 2 1 2 1 3 1 2 1 2 1 2 1 3 4 1 2 1 2 1 2 1 3 1 2 1
       2 1 2 1 3 4 1 2 1 2 1 2 1 3 1 2 1 2 1 2 1 3 4 1 2 1 2 1 2 1 3 1 2 1 2 1 2 1 3 4 1 2 1 2 1 2 1 3 1 2
       1 2 1 2 1 3 4 1 2 1 2 1 2 1 3 1 2 1 2 1 2 1 3 4 -1

  stream 1: block table 0x80692e0 (17 blocks), order list 0x8069324
     block  0 0x817f1a0 type ADPCM   14111 B =   28222 samples =   2.56s
     block  1 0x81828d0 type ADPCM   14267 B =   28534 samples =   2.59s
     block  2 0x818609c type ADPCM   10718 B =   21436 samples =   1.94s
     block  3 0x8188a8c type ADPCM    3597 B =    7194 samples =   0.65s
     block  4 0x81898ac type ADPCM   17488 B =   34976 samples =   3.17s
     block  5 0x818dd0c type ADPCM  113256 B =  226512 samples =  20.55s
     block  6 0x81a9784 type ADPCM  100737 B =  201474 samples =  18.27s
     block  7 0x81c2118 type ADPCM   12127 B =   24254 samples =   2.20s
     block  8 0x81c5088 type ADPCM   20998 B =   41996 samples =   3.81s
     block  9 0x81ca2a0 type ADPCM    1664 B =    3328 samples =   0.30s
     block 10 0x81ca930 type ADPCM    3639 B =    7278 samples =   0.66s
     block 11 0x81cb778 type ADPCM    1793 B =    3586 samples =   0.33s
     block 12 0x81cbe8c type ADPCM    3491 B =    6982 samples =   0.63s
     block 13 0x81ccc40 type ADPCM    5411 B =   10822 samples =   0.98s
     block 14 0x81ce174 type ADPCM    8831 B =   17662 samples =   1.60s
     block 15 0x81d0404 type ADPCM    5276 B =   10552 samples =   0.96s
     block 16 0x81d18b0 type ADPCM    5404 B =   10808 samples =   0.98s
     block data 342808 B; order list 1000 entries + -1 terminator:
       0 0 0 1 2 3 2 3 2 4 5 6 8 9 10 10 11 12 13 10 11 12 9 10 10 11 12 13 14 15 14 16 14 15 14 16 6 7 5 6
       8 9 10 11 12 9 10 10 11 12 13 14 15 14 16 14 15 14 16 6 7 2 3 2 4 5 6 8 9 10 10 11 12 13 10 11 12 9
       10 10 11 12 13 14 15 14 16 14 15 14 16 6 7 5 6 8 9 10 11 12 9 10 10 11 12 13 14 15 14 16 14 15 14 16
       6 7 2 3 2 4 5 6 8 9 10 10 11 12 13 10 11 12 9 10 10 11 12 13 14 15 14 16 14 15 14 16 6 7 5 6 8 9 10
       11 12 9 10 10 11 12 13 14 15 14 16 14 15 14 16 6 7 2 3 2 4 5 6 8 9 10 10 11 12 13 10 11 12 9 10 10
       11 12 13 14 15 14 16 14 15 14 16 6 7 5 6 8 9 10 11 12 9 10 10 11 12 13 14 15 14 16 14 15 14 16 6 7 2
       3 2 4 5 6 8 9 10 10 11 12 13 10 11 12 9 10 10 11 12 13 14 15 14 16 14 15 14 16 6 7 5 6 8 9 10 11 12
       9 10 10 11 12 13 14 15 14 16 14 15 14 16 6 7 2 3 2 4 5 6 8 9 10 10 11 12 13 10 11 12 9 10 10 11 12
       13 14 15 14 16 14 15 14 16 6 7 5 6 8 9 10 11 12 9 10 10 11 12 13 14 15 14 16 14 15 14 16 6 7 2 3 2 4
       5 6 8 9 10 10 11 12 13 10 11 12 9 10 10 11 12 13 14 15 14 16 14 15 14 16 6 7 5 6 8 9 10 11 12 9 10
       10 11 12 13 14 15 14 16 14 15 14 16 6 7 2 3 2 4 5 6 8 9 10 10 11 12 13 10 11 12 9 10 10 11 12 13 14
       15 14 16 14 15 14 16 6 7 5 6 8 9 10 11 12 9 10 10 11 12 13 14 15 14 16 14 15 14 16 6 7 2 3 2 4 5 6 8
       9 10 10 11 12 13 10 11 12 9 10 10 11 12 13 14 15 14 16 14 15 14 16 6 7 5 6 8 9 10 11 12 9 10 10 11
       12 13 14 15 14 16 14 15 14 16 6 7 2 3 2 4 5 6 8 9 10 10 11 12 13 10 11 12 9 10 10 11 12 13 14 15 14
       16 14 15 14 16 6 7 5 6 8 9 10 11 12 9 10 10 11 12 13 14 15 14 16 14 15 14 16 6 7 2 3 2 4 5 6 8 9 10
       10 11 12 13 10 11 12 9 10 10 11 12 13 14 15 14 16 14 15 14 16 6 7 5 6 8 9 10 11 12 9 10 10 11 12 13
       14 15 14 16 14 15 14 16 6 7 2 3 2 4 5 6 8 9 10 10 11 12 13 10 11 12 9 10 10 11 12 13 14 15 14 16 14
       15 14 16 6 7 5 6 8 9 10 11 12 9 10 10 11 12 13 14 15 14 16 14 15 14 16 6 7 2 3 2 4 5 6 8 9 10 10 11
       12 13 10 11 12 9 10 10 11 12 13 14 15 14 16 14 15 14 16 6 7 5 6 8 9 10 11 12 9 10 10 11 12 13 14 15
       14 16 14 15 14 16 6 7 2 3 2 4 5 6 8 9 10 10 11 12 13 10 11 12 9 10 10 11 12 13 14 15 14 16 14 15 14
       16 6 7 5 6 8 9 10 11 12 9 10 10 11 12 13 14 15 14 16 14 15 14 16 6 7 2 3 2 4 5 6 8 9 10 10 11 12 13
       10 11 12 9 10 10 11 12 13 14 15 14 16 14 15 14 16 6 7 5 6 8 9 10 11 12 9 10 10 11 12 13 14 15 14 16
       14 15 14 16 6 7 2 3 2 4 5 6 8 9 10 10 11 12 13 10 11 12 9 10 10 11 12 13 14 15 14 16 14 15 14 16 6 7
       5 6 8 9 10 11 12 9 10 10 11 12 13 14 15 14 16 14 15 14 16 6 7 2 3 2 4 5 6 8 9 10 10 11 12 13 10 11
       12 9 10 10 11 12 13 14 15 14 16 14 15 14 16 6 7 5 6 8 9 10 11 12 9 10 10 11 12 13 14 15 14 16 14 15
       14 16 6 7 2 3 2 4 5 6 8 9 10 10 11 12 13 10 11 12 9 10 10 11 12 13 14 15 14 16 14 15 14 16 6 7 5 6 8
       9 10 11 12 9 10 10 11 12 13 14 15 14 16 14 15 14 16 6 7 2 3 2 4 -1

  stream 2: block table 0x80690a4 (5 blocks), order list 0x80690b8
     block  0 0x806ddc0 type ADPCM  297720 B =  595440 samples =  54.01s
     block  1 0x80b68c8 type ADPCM   33121 B =   66242 samples =   6.01s
     block  2 0x80bea3c type ADPCM   12384 B =   24768 samples =   2.25s
     block  3 0x80c1aac type ADPCM    4096 B =    8192 samples =   0.74s
     block  4 0x80c2abc type ADPCM    3968 B =    7936 samples =   0.72s
     block data 351289 B; order list 89 entries + -1 terminator:
       1 2 3 2 3 2 3 2 4 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
       0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -1

  stream 3: block table 0x80691a8 (12 blocks), order list 0x80691d8
     block  0 0x80f8b74 type ADPCM   26085 B =   52170 samples =   4.73s
     block  1 0x80ff16c type ADPCM   13048 B =   26096 samples =   2.37s
     block  2 0x8102474 type ADPCM    9864 B =   19728 samples =   1.79s
     block  3 0x8104b0c type ADPCM    3199 B =    6398 samples =   0.58s
     block  4 0x810579c type ADPCM    3366 B =    6732 samples =   0.61s
     block  5 0x81064d4 type ADPCM   78305 B =  156610 samples =  14.20s
     block  6 0x81196c8 type ADPCM   42560 B =   85120 samples =   7.72s
     block  7 0x8123d18 type ADPCM    9656 B =   19312 samples =   1.75s
     block  8 0x81262e0 type ADPCM    9462 B =   18924 samples =   1.72s
     block  9 0x81287e8 type ADPCM  104831 B =  209662 samples =  19.02s
     block 10 0x8142178 type ADPCM   26174 B =   52348 samples =   4.75s
     block 11 0x81487c8 type ADPCM  130568 B =  261136 samples =  23.69s
     block data 457118 B; order list 31 entries + -1 terminator:
       1 1 1 1 2 3 2 3 2 3 2 4 5 11 0 6 7 6 8 5 0 6 7 6 8 9 10 6 7 6 8 -1

  stream 4: block table 0x806a370 (17 blocks), order list 0x806a3b4
     block  0 0x81fd52c type ADPCM    5712 B =   11424 samples =   1.04s
     block  1 0x81feb8c type ADPCM    2128 B =    4256 samples =   0.39s
     block  2 0x81ff3ec type ADPCM    7520 B =   15040 samples =   1.36s
     block  3 0x820115c type ADPCM    7537 B =   15074 samples =   1.37s
     block  4 0x8202ee0 type ADPCM   24096 B =   48192 samples =   4.37s
     block  5 0x8208d10 type ADPCM    3456 B =    6912 samples =   0.63s
     block  6 0x8209aa0 type ADPCM   20704 B =   41408 samples =   3.76s
     block  7 0x820eb90 type ADPCM    4361 B =    8722 samples =   0.79s
     block  8 0x820fcac type ADPCM   20480 B =   40960 samples =   3.72s
     block  9 0x8214cbc type ADPCM   20832 B =   41664 samples =   3.78s
     block 10 0x8219e2c type ADPCM   20798 B =   41596 samples =   3.77s
     block 11 0x821ef7c type ADPCM    4487 B =    8974 samples =   0.81s
     block 12 0x8220114 type ADPCM   10240 B =   20480 samples =   1.86s
     block 13 0x8222924 type ADPCM    7438 B =   14876 samples =   1.35s
     block 14 0x8224644 type ADPCM   22672 B =   45344 samples =   4.11s
     block 15 0x8229ee4 type ADPCM   22208 B =   44416 samples =   4.03s
     block 16 0x822f5b4 type ADPCM    2079 B =    4158 samples =   0.38s
     block data 206748 B; order list 953 entries + -1 terminator:
       1 0 2 1 0 2 1 0 2 1 0 3 16 4 5 16 4 6 7 11 8 7 11 9 7 11 10 7 12 13 14 13 14 13 15 4 5 16 4 6 7 11 8
       7 11 9 7 11 10 7 12 13 14 13 14 13 15 0 2 1 0 2 1 0 2 1 0 3 16 4 5 16 4 6 7 11 8 7 11 9 7 11 10 7 12
       13 14 13 14 13 15 4 5 16 4 6 7 11 8 7 11 9 7 11 10 7 12 13 14 13 14 13 15 0 2 1 0 2 1 0 2 1 0 3 16 4
       5 16 4 6 7 11 8 7 11 9 7 11 10 7 12 13 14 13 14 13 15 4 5 16 4 6 7 11 8 7 11 9 7 11 10 7 12 13 14 13
       14 13 15 0 2 1 0 2 1 0 2 1 0 3 16 4 5 16 4 6 7 11 8 7 11 9 7 11 10 7 12 13 14 13 14 13 15 4 5 16 4 6
       7 11 8 7 11 9 7 11 10 7 12 13 14 13 14 13 15 0 2 1 0 2 1 0 2 1 0 3 16 4 5 16 4 6 7 11 8 7 11 9 7 11
       10 7 12 13 14 13 14 13 15 4 5 16 4 6 7 11 8 7 11 9 7 11 10 7 12 13 14 13 14 13 15 0 2 1 0 2 1 0 2 1
       0 3 16 4 5 16 4 6 7 11 8 7 11 9 7 11 10 7 12 13 14 13 14 13 15 4 5 16 4 6 7 11 8 7 11 9 7 11 10 7 12
       13 14 13 14 13 15 0 2 1 0 2 1 0 2 1 0 3 16 4 5 16 4 6 7 11 8 7 11 9 7 11 10 7 12 13 14 13 14 13 15 4
       5 16 4 6 7 11 8 7 11 9 7 11 10 7 12 13 14 13 14 13 15 0 2 1 0 2 1 0 2 1 0 3 16 4 5 16 4 6 7 11 8 7
       11 9 7 11 10 7 12 13 14 13 14 13 15 4 5 16 4 6 7 11 8 7 11 9 7 11 10 7 12 13 14 13 14 13 15 0 2 1 0
       2 1 0 2 1 0 3 16 4 5 16 4 6 7 11 8 7 11 9 7 11 10 7 12 13 14 13 14 13 15 4 5 16 4 6 7 11 8 7 11 9 7
       11 10 7 12 13 14 13 14 13 15 0 2 1 0 2 1 0 2 1 0 3 16 4 5 16 4 6 7 11 8 7 11 9 7 11 10 7 12 13 14 13
       14 13 15 4 5 16 4 6 7 11 8 7 11 9 7 11 10 7 12 13 14 13 14 13 15 0 2 1 0 2 1 0 2 1 0 3 16 4 5 16 4 6
       7 11 8 7 11 9 7 11 10 7 12 13 14 13 14 13 15 4 5 16 4 6 7 11 8 7 11 9 7 11 10 7 12 13 14 13 14 13 15
       0 2 1 0 2 1 0 2 1 0 3 16 4 5 16 4 6 7 11 8 7 11 9 7 11 10 7 12 13 14 13 14 13 15 4 5 16 4 6 7 11 8 7
       11 9 7 11 10 7 12 13 14 13 14 13 15 0 2 1 0 2 1 0 2 1 0 3 16 4 5 16 4 6 7 11 8 7 11 9 7 11 10 7 12
       13 14 13 14 13 15 4 5 16 4 6 7 11 8 7 11 9 7 11 10 7 12 13 14 13 14 13 15 0 2 1 0 2 1 0 2 1 0 3 16 4
       5 16 4 6 7 11 8 7 11 9 7 11 10 7 12 13 14 13 14 13 15 4 5 16 4 6 7 11 8 7 11 9 7 11 10 7 12 13 14 13
       14 13 15 0 2 1 0 2 1 0 2 1 0 3 16 4 5 16 4 6 7 11 8 7 11 9 7 11 10 7 12 13 14 13 14 13 15 4 5 16 4 6
       7 11 8 7 11 9 7 11 10 7 12 13 14 13 14 13 15 0 2 1 0 2 1 0 2 1 0 3 16 4 5 16 4 6 7 11 8 7 11 9 7 11
       10 7 12 13 14 13 14 13 15 4 5 16 4 6 7 11 8 7 11 9 7 11 10 7 12 13 14 13 14 13 15 0 2 1 0 2 1 0 2 1
       0 3 16 4 5 16 4 6 7 11 8 7 11 9 7 11 10 7 12 13 14 13 14 13 15 4 5 16 4 6 7 11 8 7 11 9 7 11 10 7 12
       13 14 13 14 13 15 -1

  stream 5: block table 0x806ab28 (11 blocks), order list 0x806ab54
     block  0 0x822fde4 type ADPCM    6936 B =   13872 samples =   1.26s
     block  1 0x823190c type ADPCM   18911 B =   37822 samples =   3.43s
     block  2 0x82362fc type ADPCM   10519 B =   21038 samples =   1.91s
     block  3 0x8238c24 type ADPCM    8329 B =   16658 samples =   1.51s
     block  4 0x823acc0 type ADPCM    8265 B =   16530 samples =   1.50s
     block  5 0x823cd1c type ADPCM    9600 B =   19200 samples =   1.74s
     block  6 0x823f2ac type ADPCM   14081 B =   28162 samples =   2.55s
     block  7 0x82429c0 type ADPCM    4672 B =    9344 samples =   0.85s
     block  8 0x8243c10 type ADPCM    4717 B =    9434 samples =   0.86s
     block  9 0x8244e90 type ADPCM   11936 B =   23872 samples =   2.17s
     block 10 0x8247d40 type ADPCM    7072 B =   14144 samples =   1.28s
     block data 105038 B; order list 44 entries + -1 terminator:
       1 1 1 1 2 3 2 4 2 3 2 4 5 5 1 1 1 1 2 3 2 4 2 3 2 4 5 5 6 7 6 8 6 7 6 8 9 10 9 0 9 10 9 0 -1

  stream 6: block table 0x8069218 (12 blocks), order list 0x8069248
     block  0 0x81685e0 type ADPCM    1544 B =    3088 samples =   0.28s
     block  1 0x8168bf8 type ADPCM    6658 B =   13316 samples =   1.21s
     block  2 0x816a60c type ADPCM    6593 B =   13186 samples =   1.20s
     block  3 0x816bfe0 type ADPCM   13218 B =   26436 samples =   2.40s
     block  4 0x816f394 type ADPCM    3286 B =    6572 samples =   0.60s
     block  5 0x817007c type ADPCM    3433 B =    6866 samples =   0.62s
     block  6 0x8170df8 type ADPCM   18400 B =   36800 samples =   3.34s
     block  7 0x81755e8 type ADPCM    8244 B =   16488 samples =   1.50s
     block  8 0x817762c type ADPCM    8236 B =   16472 samples =   1.49s
     block  9 0x8179668 type ADPCM    9967 B =   19934 samples =   1.81s
     block 10 0x817bd68 type ADPCM    9984 B =   19968 samples =   1.81s
     block 11 0x817e478 type ADPCM    3349 B =    6698 samples =   0.61s
     block data 92912 B; order list 74 entries + -1 terminator:
       1 1 1 2 10 3 5 10 3 4 10 3 5 10 3 4 6 7 6 8 6 7 6 8 9 3 5 9 3 4 9 3 5 9 3 4 6 7 6 8 6 7 6 8 11 0 11
       0 11 11 0 11 0 11 11 0 11 0 11 11 0 11 0 11 10 3 5 10 3 4 10 10 10 10 -1

  stream 7: block table 0x806a1b0 (9 blocks), order list 0x806a1d4
     block  0 0x81ea19c type ADPCM   12654 B =   25308 samples =   2.30s
     block  1 0x81ed31c type ADPCM    2886 B =    5772 samples =   0.52s
     block  2 0x81ede74 type ADPCM    2855 B =    5710 samples =   0.52s
     block  3 0x81ee9ac type ADPCM   12605 B =   25210 samples =   2.29s
     block  4 0x81f1afc type ADPCM    7835 B =   15670 samples =   1.42s
     block  5 0x81f39a8 type ADPCM    7851 B =   15702 samples =   1.42s
     block  6 0x81f5864 type ADPCM    2896 B =    5792 samples =   0.53s
     block  7 0x81f63c4 type ADPCM    4744 B =    9488 samples =   0.86s
     block  8 0x81f765c type ADPCM    4722 B =    9444 samples =   0.86s
     block data 59048 B; order list 52 entries + -1 terminator:
       0 1 0 2 6 3 6 3 6 3 6 3 4 4 4 5 4 4 4 5 6 3 6 3 6 3 6 3 4 4 4 5 4 4 4 5 6 7 6 7 6 7 6 7 6 8 6 8 6 8
       6 8 -1

  stream 8: block table 0x8069af8 (11 blocks), order list 0x8069b24
     block  0 0x81d2ddc type ADPCM   17966 B =   35932 samples =   3.26s
     block  1 0x81d741c type ADPCM   17958 B =   35916 samples =   3.26s
     block  2 0x81dba54 type ADPCM    4637 B =    9274 samples =   0.84s
     block  3 0x81dcc84 type ADPCM    2979 B =    5958 samples =   0.54s
     block  4 0x81dd838 type ADPCM    4416 B =    8832 samples =   0.80s
     block  5 0x81de988 type ADPCM    3168 B =    6336 samples =   0.57s
     block  6 0x81df5f8 type ADPCM   12064 B =   24128 samples =   2.19s
     block  7 0x81e2528 type ADPCM   12255 B =   24510 samples =   2.22s
     block  8 0x81e5518 type ADPCM    4365 B =    8730 samples =   0.79s
     block  9 0x81e6638 type ADPCM    7745 B =   15490 samples =   1.40s
     block 10 0x81e848c type ADPCM    7423 B =   14846 samples =   1.35s
     block data 94976 B; order list 836 entries + -1 terminator:
       0 0 0 0 1 1 1 1 2 2 3 2 2 3 2 2 3 2 2 3 4 4 5 4 4 5 2 2 3 2 2 3 6 6 6 6 7 7 6 6 8 9 8 10 8 9 8 10 6
       6 6 6 7 7 6 6 1 1 1 1 2 2 3 2 2 3 2 2 3 2 2 3 4 4 5 4 4 5 2 2 3 2 2 3 6 6 6 6 7 7 6 6 8 9 8 10 8 9 8
       10 6 6 6 6 7 7 6 6 1 1 1 1 2 2 3 2 2 3 2 2 3 2 2 3 4 4 5 4 4 5 2 2 3 2 2 3 6 6 6 6 7 7 6 6 8 9 8 10
       8 9 8 10 6 6 6 6 7 7 6 6 1 1 1 1 2 2 3 2 2 3 2 2 3 2 2 3 4 4 5 4 4 5 2 2 3 2 2 3 6 6 6 6 7 7 6 6 8 9
       8 10 8 9 8 10 6 6 6 6 7 7 6 6 1 1 1 1 2 2 3 2 2 3 2 2 3 2 2 3 4 4 5 4 4 5 2 2 3 2 2 3 6 6 6 6 7 7 6
       6 8 9 8 10 8 9 8 10 6 6 6 6 7 7 6 6 1 1 1 1 2 2 3 2 2 3 2 2 3 2 2 3 4 4 5 4 4 5 2 2 3 2 2 3 6 6 6 6
       7 7 6 6 8 9 8 10 8 9 8 10 6 6 6 6 7 7 6 6 1 1 1 1 2 2 3 2 2 3 2 2 3 2 2 3 4 4 5 4 4 5 2 2 3 2 2 3 6
       6 6 6 7 7 6 6 8 9 8 10 8 9 8 10 6 6 6 6 7 7 6 6 1 1 1 1 2 2 3 2 2 3 2 2 3 2 2 3 4 4 5 4 4 5 2 2 3 2
       2 3 6 6 6 6 7 7 6 6 8 9 8 10 8 9 8 10 6 6 6 6 7 7 6 6 1 1 1 1 2 2 3 2 2 3 2 2 3 2 2 3 4 4 5 4 4 5 2
       2 3 2 2 3 6 6 6 6 7 7 6 6 8 9 8 10 8 9 8 10 6 6 6 6 7 7 6 6 1 1 1 1 2 2 3 2 2 3 2 2 3 2 2 3 4 4 5 4
       4 5 2 2 3 2 2 3 6 6 6 6 7 7 6 6 8 9 8 10 8 9 8 10 6 6 6 6 7 7 6 6 1 1 1 1 2 2 3 2 2 3 2 2 3 2 2 3 4
       4 5 4 4 5 2 2 3 2 2 3 6 6 6 6 7 7 6 6 8 9 8 10 8 9 8 10 6 6 6 6 7 7 6 6 1 1 1 1 2 2 3 2 2 3 2 2 3 2
       2 3 4 4 5 4 4 5 2 2 3 2 2 3 6 6 6 6 7 7 6 6 8 9 8 10 8 9 8 10 6 6 6 6 7 7 6 6 1 1 1 1 2 2 3 2 2 3 2
       2 3 2 2 3 4 4 5 4 4 5 2 2 3 2 2 3 6 6 6 6 7 7 6 6 8 9 8 10 8 9 8 10 6 6 6 6 7 7 6 6 1 1 1 1 2 2 3 2
       2 3 2 2 3 2 2 3 4 4 5 4 4 5 2 2 3 2 2 3 6 6 6 6 7 7 6 6 8 9 8 10 8 9 8 10 6 6 6 6 7 7 6 6 1 1 1 1 2
       2 3 2 2 3 2 2 3 2 2 3 4 4 5 4 4 5 2 2 3 2 2 3 6 6 6 6 7 7 6 6 8 9 8 10 8 9 8 10 6 6 6 6 7 7 6 6 1 1
       1 1 2 2 3 2 2 3 2 2 3 2 2 3 4 4 5 4 4 5 2 2 3 2 2 3 6 6 6 6 7 7 6 6 8 9 8 10 8 9 8 10 6 6 6 6 7 7 6
       6 -1

  stream 9: block table 0x806abb0 (14 blocks), order list 0x806abe8
     block  0 0x82498f0 type ADPCM     280 B =     560 samples =   0.05s
     block  1 0x8249a18 type ADPCM   22723 B =   45446 samples =   4.12s
     block  2 0x824f2ec type ADPCM    2460 B =    4920 samples =   0.45s
     block  3 0x824fc98 type ADPCM    2144 B =    4288 samples =   0.39s
     block  4 0x8250508 type ADPCM   20511 B =   41022 samples =   3.72s
     block  5 0x8255538 type ADPCM    4736 B =    9472 samples =   0.86s
     block  6 0x82567c8 type ADPCM    4741 B =    9482 samples =   0.86s
     block  7 0x8257a60 type ADPCM   12480 B =   24960 samples =   2.26s
     block  8 0x825ab30 type ADPCM   12798 B =   25596 samples =   2.32s
     block  9 0x825dd40 type ADPCM    4753 B =    9506 samples =   0.86s
     block 10 0x825efe4 type ADPCM    4718 B =    9436 samples =   0.86s
     block 11 0x8260264 type ADPCM    4736 B =    9472 samples =   0.86s
     block 12 0x82614f4 type ADPCM    3233 B =    6466 samples =   0.59s
     block 13 0x82621a8 type ADPCM    3576 B =    7152 samples =   0.65s
     block data 103889 B; order list 55 entries + -1 terminator:
       1 2 1 3 4 5 4 6 7 8 7 8 9 12 10 9 12 11 9 12 10 9 12 11 4 5 4 6 7 8 8 8 9 12 10 9 12 11 9 12 10 9 13
       0 0 0 0 0 0 0 0 0 0 0 0 -1

  stream 10: block table 0x806a240 (3 blocks), order list 0x806a24c
     block  0 0x81f88e0 type ADPCM   13279 B =   26558 samples =   2.41s
     block  1 0x81fbcd0 type ADPCM    3089 B =    6178 samples =   0.56s
     block  2 0x81fc8f4 type ADPCM    3112 B =    6224 samples =   0.56s
     block data 19480 B; order list 144 entries + -1 terminator:
       1 0 2 0 2 0 2 0 1 0 2 0 2 0 2 0 1 0 2 0 2 0 2 0 1 0 2 0 2 0 2 0 1 0 2 0 2 0 2 0 1 0 2 0 2 0 2 0 1 0
       2 0 2 0 2 0 1 0 2 0 2 0 2 0 1 0 2 0 2 0 2 0 1 0 2 0 2 0 2 0 1 0 2 0 2 0 2 0 1 0 2 0 2 0 2 0 1 0 2 0
       2 0 2 0 1 0 2 0 2 0 2 0 1 0 2 0 2 0 2 0 1 0 2 0 2 0 2 0 1 0 2 0 2 0 2 0 1 0 2 0 2 0 2 0 -1

  stream 11: block table 0x806a240 (3 blocks), order list 0x806a24c
     block  0 0x81f88e0 type ADPCM   13279 B =   26558 samples =   2.41s
     block  1 0x81fbcd0 type ADPCM    3089 B =    6178 samples =   0.56s
     block  2 0x81fc8f4 type ADPCM    3112 B =    6224 samples =   0.56s
     block data 19480 B; order list 144 entries + -1 terminator:
       1 0 2 0 2 0 2 0 1 0 2 0 2 0 2 0 1 0 2 0 2 0 2 0 1 0 2 0 2 0 2 0 1 0 2 0 2 0 2 0 1 0 2 0 2 0 2 0 1 0
       2 0 2 0 2 0 1 0 2 0 2 0 2 0 1 0 2 0 2 0 2 0 1 0 2 0 2 0 2 0 1 0 2 0 2 0 2 0 1 0 2 0 2 0 2 0 1 0 2 0
       2 0 2 0 1 0 2 0 2 0 2 0 1 0 2 0 2 0 2 0 1 0 2 0 2 0 2 0 1 0 2 0 2 0 2 0 1 0 2 0 2 0 2 0 -1

  stream 12: block table 0x806adcc (1 blocks), order list 0x806add0
     block  0 0x8283b54 type ADPCM   20080 B =   40160 samples =   3.64s
     block data 20080 B; order list 1 entries + -1 terminator:
       0 -1

  stream 13: block table 0x806916c (7 blocks), order list 0x8069188
     block  0 0x80c3a4c type ADPCM   13047 B =   26094 samples =   2.37s
     block  1 0x80c6d54 type ADPCM   13180 B =   26360 samples =   2.39s
     block  2 0x80ca0e0 type ADPCM   12868 B =   25736 samples =   2.33s
     block  3 0x80cd334 type ADPCM   35825 B =   71650 samples =   6.50s
     block  4 0x80d5f38 type ADPCM   94154 B =  188308 samples =  17.08s
     block  5 0x80ecf14 type ADPCM   35279 B =   70558 samples =   6.40s
     block  6 0x80f58f4 type ADPCM   12912 B =   25824 samples =   2.34s
     block data 217265 B; order list 14 entries + -1 terminator:
       0 2 0 1 6 3 4 0 2 0 1 6 5 4 -1

  stream 14: block table 0x806add4 (5 blocks), order list 0x806ade8
     block  0 0x82889d4 type ADPCM   27520 B =   55040 samples =   4.99s
     block  1 0x828f564 type ADPCM    7872 B =   15744 samples =   1.43s
     block  2 0x8291434 type ADPCM   13696 B =   27392 samples =   2.48s
     block  3 0x82949c4 type ADPCM    6016 B =   12032 samples =   1.09s
     block  4 0x8296154 type ADPCM   27232 B =   54464 samples =   4.94s
     block data 82336 B; order list 24 entries + -1 terminator:
       1 2 3 1 2 3 1 2 3 1 2 3 1 3 1 3 1 3 1 3 4 4 0 0 -1

  stream 15: block table 0x806ae1c (2 blocks), order list 0x806ae24
     block  0 0x829cbc4 type ADPCM   59713 B =  119426 samples =  10.83s
     block  1 0x82ab518 type ADPCM  212954 B =  425908 samples =  38.63s
     block data 272667 B; order list 91 entries + -1 terminator:
       0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
       1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 -1
  stream 16: entry = (0x2020304, 0x3040302) -> not a valid stream; table ends

==============================================================================
Monopoly (E)  [MO]
==============================================================================
mix rate 11025 Hz, 8 voices (arguments passed to snd_init by the game)

Sound bank @ 0x807ccd4: songCount=21 sampleCount=49 songTable=0x807cce4 sampleTable=0x807cd8c

  #   address    type    length  loopStart  seconds@11025
    0 0x8013204  PCM8      8352          0    0.76
    1 0x80155b4  PCM8      6866          0    0.62
    2 0x8017398  PCM8     25118          0    2.28
    3 0x801d8c8  PCM8      2121          0    0.19
    4 0x801e424  PCM8     27888          0    2.53
    5 0x8025424  PCM8      8302          0    0.75
    6 0x80277a4  PCM8       765          0    0.07
    7 0x8027db4  PCM8      1053          0    0.10
    8 0x80284e4  PCM8      2757          0    0.25
    9 0x80292bc  PCM8      1753          0    0.16
   10 0x8029ca8  PCM8     10367          0    0.94
   11 0x802c838  PCM8      4048          0    0.37
   12 0x802db18  PCM8      1680          0    0.15
   13 0x802e4b8  PCM8      3174          0    0.29
   14 0x802f430  PCM8      3217          0    0.29
   15 0x80303d4  PCM8      6342          0    0.58
   16 0x8031fac  PCM8      6342          0    0.58
   17 0x8033b84  PCM8      5486          0    0.50
   18 0x8035404  PCM8      5795          0    0.53
   19 0x8036db8  PCM8      6985          0    0.63
   20 0x8038c14  PCM8      6496          0    0.59
   21 0x803a884  PCM8      9581          0    0.87
   22 0x803d104  PCM8     16148          0    1.46
   23 0x8041328  PCM8     16925          0    1.54
   24 0x8045858  PCM8     12295          0    1.12
   25 0x8048b70  PCM8     14170          0    1.29
   26 0x804c5dc  PCM8     10841          0    0.98
   27 0x804f348  PCM8      6961          0    0.63
   28 0x805118c  PCM8     12856       8133    1.17   (looped)
   29 0x80546d4  PCM8      2139          0    0.19
   30 0x8055240  PCM8      2075          0    0.19
   31 0x8055d6c  PCM8      4556          0    0.41
   32 0x8057248  PCM8     42061          0    3.82
   33 0x80619a8  PCM8      2139          0    0.19
   34 0x8062514  PCM8      4362          0    0.40
   35 0x8063930  PCM8     14011          0    1.27
   36 0x80672fc  PCM8     34100          0    3.09
   37 0x806fb40  PCM8      9175          0    0.83
   38 0x8072228  PCM8      3473       1534    0.32   (looped)
   39 0x80732cc  PCM8       808          0    0.07
   40 0x8073904  PCM8      2431          0    0.22
   41 0x8074594  PCM8       169          1    0.02   (looped)
   42 0x8074950  PCM8      3547          0    0.32
   43 0x8075a3c  PCM8     11744          0    1.07
   44 0x8078b2c  PCM8      4411       3600    0.40   (looped)
   45 0x8079f78  PCM8       811          1    0.07   (looped)
   46 0x807a5b4  PCM8      4547       3199    0.41   (looped)
   47 0x807ba88  PCM8      3868          0    0.35
   48 0x807ccb4  PCM8         4          0    0.00

  Sequenced songs (event-stream format, see technical reference section 7)
  #   start      loop       bytes  MIDI ch used                 progs  keys    ticks   tempo(t/frame) ~len   terminator
   0  0x8000264 0x8000264   7525  4,5,12,13                      4    48-74   26880    4.000      112.5s  B0 B3 (loop)
   1  0x8001fcc 0x8001fcc   5993  4,5,6,13,14,15                 6    50-79   26880    5.333       84.4s  B0 B3 (loop)
   2  0x8003738 0x8003738   2865  4,5,6,10,11                    5    50-76   16320    4.667       58.6s  B0 B3 (loop)
   3  0x800426c 0x800426c   4299  4,5,13,14                      4    53-94   17280    4.667       62.0s  B0 B3 (loop)
   4  0x8005338 0x8005338   6825  4,5,13,14,15                   5    41-67   22080    4.165       88.8s  B0 B3 (loop)
   5  0x8006de4 0x8006de4   6503  4,5,6,12,13                    5    45-72   24960    5.000       83.6s  B0 B3 (loop)
   6  0x800874c 0x800874c   2353  4,5,6,13,14                    5    52-69   26880    6.000       75.0s  B0 B3 (loop)
   7  0x8009080 0x8009080   7523  4,5,6,7,8,14,15                7    19-77   28800    5.333       90.4s  B0 B3 (loop)
   8  0x800ade4 0x800ade4   2349  4,5,6,13,14                    3    52-69   26880    6.000       75.0s  B0 B3 (loop)
   9  0x800b714 0x800b714   8215  5,6,7,14,15                    5    37-91   36482    6.000      101.8s  B0 B3 (loop)
  10  0x800d72c 0x800d72c   5554  5,6,7,14,15                    5    43-79   23040    4.333       89.0s  B0 B3 (loop)
  11  0x800ece0 0x800ece0   2474  4,5,13,14                      4    53-79    5820    6.333       15.4s  B3 (no loop)
  12  0x800f68c 0x800f68c   1964  4,5,6,10,11                    5    55-81    6240    6.667       15.7s  B3 (no loop)
  13  0x800fe38 0x800fe38   1536  4,5,13                         3    56-92    5880    6.000       16.4s  B3 (no loop)
  14  0x8010438 0x8010438   1698  4,5,13,14                      4    55-79    3930    4.333       15.2s  B3 (no loop)
  15  0x8010adc 0x8010adc   2238  4,5,6,12,13                    5    48-69    5820    6.333       15.4s  B3 (no loop)
  16  0x801139c 0x801139c   1597  4,5,6,13,14                    5    52-94    6240    6.200       16.9s  B3 (no loop)
  17  0x80119dc 0x80119dc   2414  5,7,14,15                      4    43-77    5880    6.333       15.5s  B3 (no loop)
  18  0x801234c 0x801234c   1304  5,7,14,15                      4    55-79    4080    5.000       13.7s  B3 (no loop)
  19  0x8012864 0x8012864    184  5,7,14                         3    62-106    240    4.000        1.0s  B3 (no loop)
  20  0x801291c 0x801291c   2278  4,5,12,13                      4    48-79    4020    4.333       15.5s  B3 (no loop)

==============================================================================
Pac-Man World (E)  [PM]
==============================================================================
mix rate 8000 Hz, 2 voices (arguments passed to snd_init by the game)

Sound bank @ 0x804e850: songCount=0 sampleCount=29 songTable=0x804e860 sampleTable=0x804e860

  #   address    type    length  loopStart  seconds@11025
    0 0x801b7f0  PCM8     11993          0    1.09
    1 0x801e9dc  PCM8      2537          0    0.23
    2 0x801f6d8  PCM8      4394          0    0.40
    3 0x8020b14  PCM8      8244          0    0.75
    4 0x8022e58  PCM8      2879          0    0.26
    5 0x8023ca8  PCM8      7093          0    0.64
    6 0x8025b70  PCM8      4346          0    0.39
    7 0x8026f7c  PCM8      5808          0    0.53
    8 0x802893c  PCM8      3438          0    0.31
    9 0x80299bc  PCM8     13841          0    1.26
   10 0x802d2e0  PCM8      8754          0    0.79
   11 0x802f824  PCM8      9135          0    0.83
   12 0x8031ee4  PCM8      4563          0    0.41
   13 0x80333c8  PCM8      3635          0    0.33
   14 0x803450c  PCM8      8953          0    0.81
   15 0x8036b18  PCM8      1601          0    0.15
   16 0x803746c  PCM8      8223          0    0.75
   17 0x803979c  PCM8      2219          0    0.20
   18 0x803a358  PCM8      7295          0    0.66
   19 0x803c2e8  PCM8      6175          0    0.56
   20 0x803de18  PCM8      2273          0    0.21
   21 0x803ea0c  PCM8      5715          0    0.52
   22 0x8040370  PCM8      2879          0    0.26
   23 0x80411c0  PCM8     15076          0    1.37
   24 0x8044fb4  PCM8      5264          0    0.48
   25 0x8046754  PCM8     12356          0    1.12
   26 0x8049aa8  PCM8      3742          0    0.34
   27 0x804ac58  PCM8      1986          0    0.18
   28 0x804b72c  PCM8     11794          0    1.07

  Streamed (block + order-list) music table @ 0x80a18fc

  stream 0: block table 0x80a175c (9 blocks), order list 0x80a1780
     block  0 0x80daaa8 type ADPCM   18665 B =   37330 samples =   4.67s
     block  1 0x80df3a4 type ADPCM    9435 B =   18870 samples =   2.36s
     block  2 0x80e1890 type ADPCM    9354 B =   18708 samples =   2.34s
     block  3 0x80e3d2c type ADPCM    9408 B =   18816 samples =   2.35s
     block  4 0x80e61fc type ADPCM    7065 B =   14130 samples =   1.77s
     block  5 0x80e7da8 type ADPCM    2358 B =    4716 samples =   0.59s
     block  6 0x80e86f0 type ADPCM    2355 B =    4710 samples =   0.59s
     block  7 0x80e9034 type ADPCM   18868 B =   37736 samples =   4.72s
     block  8 0x80ed9f8 type ADPCM   37663 B =   75326 samples =   9.42s
     block data 115171 B; order list 11 entries + -1 terminator:
       0 1 2 1 3 4 5 4 6 7 8 -1

  stream 1: block table 0x80a1798 (11 blocks), order list 0x80a17c4
     block  0 0x80f6d28 type ADPCM    4953 B =    9906 samples =   1.24s
     block  1 0x80f8094 type ADPCM    4973 B =    9946 samples =   1.24s
     block  2 0x80f9414 type ADPCM    4989 B =    9978 samples =   1.25s
     block  3 0x80fa7a4 type ADPCM    3676 B =    7352 samples =   0.92s
     block  4 0x80fb610 type ADPCM    1249 B =    2498 samples =   0.31s
     block  5 0x80fbb04 type ADPCM    1248 B =    2496 samples =   0.31s
     block  6 0x80fbff4 type ADPCM    4878 B =    9756 samples =   1.22s
     block  7 0x80fd314 type ADPCM    4946 B =    9892 samples =   1.24s
     block  8 0x80fe678 type ADPCM    9841 B =   19682 samples =   2.46s
     block  9 0x8100cfc type ADPCM    4910 B =    9820 samples =   1.23s
     block 10 0x810203c type ADPCM    4948 B =    9896 samples =   1.24s
     block data 50611 B; order list 28 entries + -1 terminator:
       0 0 0 0 0 1 0 2 3 4 3 4 3 5 3 4 3 4 6 3 4 7 8 9 9 8 9 10 -1

  stream 2: block table 0x80a1800 (6 blocks), order list 0x80a1818
     block  0 0x81033a0 type ADPCM   12001 B =   24002 samples =   3.00s
     block  1 0x8106294 type ADPCM   24051 B =   48102 samples =   6.01s
     block  2 0x810c098 type ADPCM   60101 B =  120202 samples =  15.03s
     block  3 0x811ab70 type ADPCM   18041 B =   36082 samples =   4.51s
     block  4 0x811f1fc type ADPCM    5988 B =   11976 samples =   1.50s
     block  5 0x8120970 type ADPCM   17932 B =   35864 samples =   4.48s
     block data 138114 B; order list 8 entries + -1 terminator:
       0 1 1 2 3 4 3 5 -1

  stream 3: block table 0x80a182c (10 blocks), order list 0x80a1854
     block  0 0x8124f8c type ADPCM    3230 B =    6460 samples =   0.81s
     block  1 0x8125c3c type ADPCM    3229 B =    6458 samples =   0.81s
     block  2 0x81268ec type ADPCM    3172 B =    6344 samples =   0.79s
     block  3 0x8127560 type ADPCM    9607 B =   19214 samples =   2.40s
     block  4 0x8129af8 type ADPCM    6456 B =   12912 samples =   1.61s
     block  5 0x812b440 type ADPCM    6452 B =   12904 samples =   1.61s
     block  6 0x812cd84 type ADPCM    3204 B =    6408 samples =   0.80s
     block  7 0x812da18 type ADPCM   38427 B =   76854 samples =   9.61s
     block  8 0x8137044 type ADPCM   51269 B =  102538 samples =  12.82s
     block  9 0x814389c type ADPCM   19172 B =   38344 samples =   4.79s
     block data 144218 B; order list 15 entries + -1 terminator:
       0 1 0 2 3 2 4 0 2 5 6 1 7 8 9 -1

  stream 4: block table 0x80a1874 (7 blocks), order list 0x80a1890
     block  0 0x8148390 type ADPCM   20899 B =   41798 samples =   5.22s
     block  1 0x814d544 type ADPCM    2048 B =    4096 samples =   0.51s
     block  2 0x814dd54 type ADPCM   21431 B =   42862 samples =   5.36s
     block  3 0x815311c type ADPCM   10596 B =   21192 samples =   2.65s
     block  4 0x8155a90 type ADPCM   10626 B =   21252 samples =   2.66s
     block  5 0x8158424 type ADPCM   21374 B =   42748 samples =   5.34s
     block  6 0x815d7b4 type ADPCM   19439 B =   38878 samples =   4.86s
     block data 106413 B; order list 9 entries + -1 terminator:
       0 1 2 3 2 4 5 5 6 -1

  stream 5: block table 0x80a18a4 (11 blocks), order list 0x80a18d0
     block  0 0x81623b4 type ADPCM    5279 B =   10558 samples =   1.32s
     block  1 0x8163864 type ADPCM   12997 B =   25994 samples =   3.25s
     block  2 0x8166b3c type ADPCM    1212 B =    2424 samples =   0.30s
     block  3 0x8167008 type ADPCM    1241 B =    2482 samples =   0.31s
     block  4 0x81674f4 type ADPCM   12959 B =   25918 samples =   3.24s
     block  5 0x816a7a4 type ADPCM    6501 B =   13002 samples =   1.63s
     block  6 0x816c11c type ADPCM    6494 B =   12988 samples =   1.62s
     block  7 0x816da8c type ADPCM   13002 B =   26004 samples =   3.25s
     block  8 0x8170d68 type ADPCM   12988 B =   25976 samples =   3.25s
     block  9 0x8174034 type ADPCM    1202 B =    2404 samples =   0.30s
     block 10 0x81744f8 type ADPCM   32461 B =   64922 samples =   8.12s
     block data 106336 B; order list 21 entries + -1 terminator:
       3 0 3 0 1 2 0 3 0 4 5 5 6 6 8 9 0 3 0 8 10 -1
  stream 6: entry = (0x8063781, 0x80673c9) -> not a valid stream; table ends

==============================================================================
Need for Speed: Underground (U)  [NF]
==============================================================================
mix rate 11025 Hz, 4 voices (arguments passed to snd_init by the game)

Sound bank @ 0x806adb8: songCount=0 sampleCount=24 songTable=0x806adc8 sampleTable=0x806adc8

  #   address    type    length  loopStart  seconds@11025
    0 0x8027698  PCM8     10336          0    0.94
    1 0x802a208  PCM8      3071          0    0.28
    2 0x802b118  PCM8      4927          0    0.45
    3 0x802c768  PCM8      3087          0    0.28
    4 0x802d688  PCM8      1583          0    0.14
    5 0x802dfc8  PCM8      1947          0    0.18
    6 0x802ea74  PCM8     15878          1    1.44   (looped)
    7 0x8032b8c  PCM8     16356          1    1.48   (looped)
    8 0x8036e80  PCM8     16399          1    1.49   (looped)
    9 0x803b1a0  PCM8     16263          1    1.48   (looped)
   10 0x803f438  PCM8     14991          1    1.36   (looped)
   11 0x80431d8  PCM8     17223          1    1.56   (looped)
   12 0x8047830  PCM8     15842          1    1.44   (looped)
   13 0x804b924  PCM8     14673          1    1.33   (looped)
   14 0x804f588  PCM8     15346          1    1.39   (looped)
   15 0x805348c  PCM8      7982          0    0.72
   16 0x80556cc  PCM8      7683          0    0.70
   17 0x80577e0  PCM8     12114          0    1.10
   18 0x805aa44  PCM8      7025          0    0.64
   19 0x805c8c8  PCM8     15639          1    1.42   (looped)
   20 0x80608f0  PCM8     13774          0    1.25
   21 0x80641d0  PCM8      5908          0    0.54
   22 0x8065bf4  PCM8      5322          0    0.48
   23 0x80673d0  PCM8     14039          1    1.27   (looped)

  Streamed (block + order-list) music table @ 0x86585b0

  stream 0: block table 0x8658418 (22 blocks), order list 0x8658470
     block  0 0x86bbf78 type ADPCM    4868 B =    9736 samples =   0.88s
     block  1 0x86bd28c type ADPCM   13098 B =   26196 samples =   2.38s
     block  2 0x86c05c8 type ADPCM   13072 B =   26144 samples =   2.37s
     block  3 0x86c38e8 type ADPCM   13140 B =   26280 samples =   2.38s
     block  4 0x86c6c4c type ADPCM  104830 B =  209660 samples =  19.02s
     block  5 0x86e05dc type ADPCM    3244 B =    6488 samples =   0.59s
     block  6 0x86e1298 type ADPCM   19679 B =   39358 samples =   3.57s
     block  7 0x86e5f88 type ADPCM    3167 B =    6334 samples =   0.57s
     block  8 0x86e6bf8 type ADPCM    3317 B =    6634 samples =   0.60s
     block  9 0x86e7900 type ADPCM   55742 B =  111484 samples =  10.11s
     block 10 0x86f52d0 type ADPCM    3329 B =    6658 samples =   0.60s
     block 11 0x86f5fe4 type ADPCM   18090 B =   36180 samples =   3.28s
     block 12 0x86fa6a0 type ADPCM    8150 B =   16300 samples =   1.48s
     block 13 0x86fc688 type ADPCM    7796 B =   15592 samples =   1.41s
     block 14 0x86fe50c type ADPCM   13087 B =   26174 samples =   2.37s
     block 15 0x870183c type ADPCM   13146 B =   26292 samples =   2.38s
     block 16 0x8704ba8 type ADPCM   13148 B =   26296 samples =   2.39s
     block 17 0x8707f14 type ADPCM   13118 B =   26236 samples =   2.38s
     block 18 0x870b264 type ADPCM   13062 B =   26124 samples =   2.37s
     block 19 0x870e57c type ADPCM   12751 B =   25502 samples =   2.31s
     block 20 0x871175c type ADPCM   52160 B =  104320 samples =   9.46s
     block 21 0x871e32c type ADPCM    7844 B =   15688 samples =   1.42s
     block data 409838 B; order list 54 entries + -1 terminator:
       0 1 2 1 21 0 1 2 1 3 4 5 6 8 7 6 9 20 4 5 6 8 7 6 10 11 12 11 13 14 15 14 16 17 18 17 19 4 5 6 8 7 6
       9 20 1 2 1 21 0 1 2 1 21 -1

  stream 1: block table 0x86582ec (31 blocks), order list 0x8658368
     block  0 0x86585d0 type ADPCM    4050 B =    8100 samples =   0.73s
     block  1 0x86595b4 type ADPCM    3887 B =    7774 samples =   0.71s
     block  2 0x865a4f4 type ADPCM    3950 B =    7900 samples =   0.72s
     block  3 0x865b474 type ADPCM    1896 B =    3792 samples =   0.34s
     block  4 0x865bbec type ADPCM    5793 B =   11586 samples =   1.05s
     block  5 0x865d2a0 type ADPCM    1984 B =    3968 samples =   0.36s
     block  6 0x865da70 type ADPCM    5840 B =   11680 samples =   1.06s
     block  7 0x865f150 type ADPCM   62211 B =  124422 samples =  11.29s
     block  8 0x866e464 type ADPCM   64256 B =  128512 samples =  11.66s
     block  9 0x867df74 type ADPCM    5904 B =   11808 samples =   1.07s
     block 10 0x867f694 type ADPCM    1916 B =    3832 samples =   0.35s
     block 11 0x867fe20 type ADPCM    5851 B =   11702 samples =   1.06s
     block 12 0x868150c type ADPCM   62270 B =  124540 samples =  11.30s
     block 13 0x869085c type ADPCM    1921 B =    3842 samples =   0.35s
     block 14 0x8690ff0 type ADPCM   29215 B =   58430 samples =   5.30s
     block 15 0x8698220 type ADPCM    1953 B =    3906 samples =   0.35s
     block 16 0x86989d4 type ADPCM   27175 B =   54350 samples =   4.93s
     block 17 0x869f40c type ADPCM    4104 B =    8208 samples =   0.74s
     block 18 0x86a0424 type ADPCM   11614 B =   23228 samples =   2.11s
     block 19 0x86a3194 type ADPCM    4780 B =    9560 samples =   0.87s
     block 20 0x86a4450 type ADPCM    2970 B =    5940 samples =   0.54s
     block 21 0x86a4ffc type ADPCM    2832 B =    5664 samples =   0.51s
     block 22 0x86a5b1c type ADPCM    7813 B =   15626 samples =   1.42s
     block 23 0x86a79b4 type ADPCM   11678 B =   23356 samples =   2.12s
     block 24 0x86aa764 type ADPCM    7872 B =   15744 samples =   1.43s
     block 25 0x86ac634 type ADPCM    7899 B =   15798 samples =   1.43s
     block 26 0x86ae520 type ADPCM    2046 B =    4092 samples =   0.37s
     block 27 0x86aed30 type ADPCM   13541 B =   27082 samples =   2.46s
     block 28 0x86b2228 type ADPCM    3950 B =    7900 samples =   0.72s
     block 29 0x86b31a8 type ADPCM   15792 B =   31584 samples =   2.86s
     block 30 0x86b6f68 type ADPCM   20479 B =   40958 samples =   3.72s
     block data 407442 B; order list 87 entries + -1 terminator:
       0 1 0 1 0 2 2 2 2 2 2 3 4 5 4 5 4 5 6 3 4 5 4 5 4 5 6 7 8 9 10 9 10 9 10 11 10 9 10 9 10 9 10 11 7
       12 13 14 15 14 16 17 16 18 19 20 19 20 19 21 22 22 22 22 23 23 24 23 23 24 13 14 15 14 25 26 27 26
       27 26 27 26 28 29 29 29 30 -1

  stream 2: block table 0x86584e0 (12 blocks), order list 0x8658510
     block  0 0x87201e0 type ADPCM    8553 B =   17106 samples =   1.55s
     block  1 0x872235c type ADPCM    8447 B =   16894 samples =   1.53s
     block  2 0x872446c type ADPCM    8442 B =   16884 samples =   1.53s
     block  3 0x8726578 type ADPCM    8513 B =   17026 samples =   1.54s
     block  4 0x87286cc type ADPCM    8563 B =   17126 samples =   1.55s
     block  5 0x872a850 type ADPCM    8533 B =   17066 samples =   1.55s
     block  6 0x872c9b8 type ADPCM   85392 B =  170784 samples =  15.49s
     block  7 0x8741758 type ADPCM    8530 B =   17060 samples =   1.55s
     block  8 0x87438bc type ADPCM  145144 B =  290288 samples =  26.33s
     block  9 0x8766fc4 type ADPCM   17103 B =   34206 samples =   3.10s
     block 10 0x876b2a4 type ADPCM   17085 B =   34170 samples =   3.10s
     block 11 0x876f574 type ADPCM   85395 B =  170790 samples =  15.49s
     block data 409700 B; order list 34 entries + -1 terminator:
       0 1 0 2 0 1 0 2 3 4 3 5 3 4 3 5 6 7 7 7 8 9 9 9 10 3 4 3 5 3 4 3 5 11 -1

  stream 3: block table 0x8658558 (11 blocks), order list 0x8658584
     block  0 0x8784318 type ADPCM   50432 B =  100864 samples =   9.15s
     block  1 0x8790828 type ADPCM   41155 B =   82310 samples =   7.47s
     block  2 0x879a8fc type ADPCM   59609 B =  119218 samples =  10.81s
     block  3 0x87a91e8 type ADPCM   95500 B =  191000 samples =  17.32s
     block  4 0x87c0704 type ADPCM  101025 B =  202050 samples =  18.33s
     block  5 0x87d91b8 type ADPCM    5235 B =   10470 samples =   0.95s
     block  6 0x87da63c type ADPCM   18188 B =   36376 samples =   3.30s
     block  7 0x87ded58 type ADPCM   21857 B =   43714 samples =   3.96s
     block  8 0x87e42cc type ADPCM   12756 B =   25512 samples =   2.31s
     block  9 0x87e74b0 type ADPCM   12416 B =   24832 samples =   2.25s
     block 10 0x87ea540 type ADPCM   12875 B =   25750 samples =   2.34s
     block data 431048 B; order list 20 entries + -1 terminator:
       0 1 2 3 5 4 3 6 0 1 7 8 8 8 9 9 9 10 3 6 -1
  stream 4: entry = (0x0, 0xfd2) -> not a valid stream; table ends
```
