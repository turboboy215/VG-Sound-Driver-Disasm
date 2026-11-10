# Krawall data dump

Companion to `claude/krawall-technical-reference.md`. Every address is a ROM file offset (OR with `0x08000000` for the GBA address). All modules were found by an independent structural scan and every pattern was decoded end to end with the encoding from the official source; a second scan for orphan 64-row patterns found none, so these lists are complete for the Krawall data in each ROM.

Legend for the **U** column: `✓` = found by UnkrawerterGBA 4.0 with default settings (`-t 4`); `✗` = missed by default, found with `-t 1`.


## The Sims: Bustin' Out (U)

* Signature: `$Id: player.c,v 1.4 2003/03/19 23:12:15 seb Exp $` @ 0x0D6F4E4
* Pattern format: **old (< 2004-07-07)**
* Sample list: `0x0D54690`, 467 samples
* Instrument list: none (every module is sample-based, `flagInstrumentBased = 0`)
* Modules: **47** (Unkrawerter default finds 37, misses 10)

| # | Offset | U | Ch | Orders | Patterns | Speed | BPM | VolGlobal | Sub-songs (`+++`) | Effects used |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | `0x0AFB704` | ✓ | 4 | 10 | 8 | 16 | 80 | 80 | 3 (starts [0, 4, 8]) | 1 4 6 11 15 27 34 44 45 |
| 1 | `0x0AFC000` | ✓ | 9 | 7 | 5 | 6 | 120 | 86 | 3 (starts [0, 4, 6]) | 1 5 6 11 19 29 44 45 |
| 2 | `0x0AFD568` | ✓ | 8 | 8 | 7 | 6 | 140 | 112 | 1 | 6 11 27 29 34 44 |
| 3 | `0x0B00B28` | ✓ | 11 | 13 | 12 | 6 | 152 | 68 | 1 | 1 4 5 6 11 19 20 23 27 29 34 45 |
| 4 | `0x0B047EC` | ✓ | 9 | 17 | 17 | 6 | 135 | 128 | 1 | 4 5 6 19 27 34 45 |
| 5 | `0x0B06018` | ✓ | 8 | 8 | 8 | 6 | 168 | 96 | 1 | 6 19 27 34 44 |
| 6 | `0x0B09818` | ✓ | 12 | 19 | 15 | 4 | 138 | 120 | 1 | 4 5 6 11 19 20 23 27 34 45 |
| 7 | `0x0B09B54` | ✗ | 5 | 1 | 1 | 4 | 160 | 100 | 1 | 6 27 |
| 8 | `0x0B09D7C` | ✗ | 2 | 1 | 1 | 4 | 143 | 128 | 1 | 5 6 34 |
| 9 | `0x0B0A14C` | ✗ | 7 | 1 | 1 | 4 | 146 | 100 | 1 | 5 15 19 |
| 10 | `0x0B0A63C` | ✗ | 8 | 1 | 1 | 4 | 160 | 96 | 1 | 5 6 |
| 11 | `0x0B0CF88` | ✓ | 13 | 24 | 15 | 4 | 146 | 128 | 1 | 2 4 6 11 19 27 34 |
| 12 | `0x0B0D4A4` | ✗ | 6 | 1 | 1 | 4 | 143 | 100 | 1 | 1 6 11 20 45 |
| 13 | `0x0B0DA90` | ✗ | 9 | 1 | 1 | 4 | 143 | 100 | 1 | 1 2 6 19 20 34 |
| 14 | `0x0B0DFD0` | ✗ | 9 | 1 | 1 | 4 | 125 | 100 | 1 | 1 5 6 19 20 23 34 45 |
| 15 | `0x0B0E21C` | ✗ | 5 | 1 | 1 | 4 | 143 | 100 | 1 | 5 6 34 |
| 16 | `0x0B0EBB4` | ✓ | 10 | 3 | 3 | 6 | 125 | 86 | 1 | 6 19 20 34 |
| 17 | `0x0B0F850` | ✓ | 8 | 12 | 7 | 6 | 120 | 96 | 6 (starts [0, 3, 5, 7, 9, 11]) | 1 2 4 5 6 |
| 18 | `0x0B12C68` | ✓ | 10 | 8 | 8 | 8 | 132 | 128 | 1 | 6 20 23 27 34 45 |
| 19 | `0x0B1362C` | ✓ | 8 | 5 | 3 | 4 | 140 | 100 | 3 (starts [0, 2, 4]) | 5 6 19 20 |
| 20 | `0x0B16F74` | ✓ | 12 | 21 | 16 | 4 | 134 | 110 | 1 | 1 4 5 6 11 19 20 23 27 34 45 |
| 21 | `0x0B183CC` | ✓ | 7 | 12 | 7 | 10 | 125 | 96 | 6 (starts [0, 3, 5, 7, 9, 11]) | 1 2 4 5 6 15 19 20 23 27 36 |
| 22 | `0x0B19F98` | ✓ | 10 | 11 | 11 | 6 | 150 | 100 | 1 | 5 6 11 27 36 45 |
| 23 | `0x0B1C7CC` | ✓ | 9 | 11 | 11 | 6 | 150 | 100 | 1 | 5 6 11 27 36 45 |
| 24 | `0x0B1ED80` | ✓ | 9 | 12 | 12 | 6 | 150 | 100 | 1 | 5 6 11 27 36 45 |
| 25 | `0x0B207F4` | ✓ | 10 | 11 | 11 | 6 | 150 | 100 | 1 | 5 6 11 27 36 45 |
| 26 | `0x0B23388` | ✓ | 9 | 14 | 14 | 6 | 150 | 100 | 1 | 5 6 11 19 20 27 36 44 45 |
| 27 | `0x0B23760` | ✗ | 4 | 1 | 1 | 6 | 152 | 128 | 1 | 2 6 43 |
| 28 | `0x0B26DA4` | ✓ | 10 | 16 | 11 | 6 | 125 | 112 | 1 | 6 19 20 21 23 34 45 |
| 29 | `0x0B2C5E4` | ✓ | 10 | 20 | 17 | 6 | 158 | 100 | 1 | 4 5 6 11 15 19 20 23 27 29 34 45 |
| 30 | `0x0B2EEB4` | ✓ | 8 | 18 | 13 | 4 | 136 | 128 | 1 | 4 6 11 19 20 27 34 |
| 31 | `0x0B2F2A8` | ✗ | 8 | 1 | 1 | 4 | 152 | 140 | 1 | 5 6 11 |
| 32 | `0x0B36214` | ✓ | 15 | 15 | 15 | 6 | 110 | 100 | 1 | 1 6 15 19 20 23 27 34 44 45 |
| 33 | `0x0B399A0` | ✓ | 9 | 18 | 17 | 6 | 124 | 90 | 1 | 1 5 6 11 15 19 20 23 27 34 44 45 |
| 34 | `0x0B3EC64` | ✓ | 8 | 23 | 18 | 6 | 125 | 112 | 4 (starts [0, 18, 20, 22]) | 1 4 5 6 11 19 20 21 23 27 29 34 45 |
| 35 | `0x0B4183C` | ✓ | 9 | 11 | 11 | 6 | 139 | 128 | 1 | 4 5 6 11 15 19 20 23 27 29 34 |
| 36 | `0x0B45500` | ✓ | 10 | 12 | 11 | 6 | 112 | 112 | 2 (starts [0, 11]) | 1 4 5 6 19 45 |
| 37 | `0x0B48684` | ✓ | 10 | 29 | 17 | 4 | 147 | 92 | 1 | 1 4 6 11 15 19 20 27 34 44 45 |
| 38 | `0x0D57550` | ✓ | 8 | 8 | 7 | 6 | 107 | 100 | 1 | 6 20 29 45 |
| 39 | `0x0D581C0` | ✓ | 8 | 11 | 8 | 4 | 126 | 90 | 1 | 5 6 19 27 34 45 |
| 40 | `0x0D5B8C0` | ✓ | 12 | 20 | 13 | 4 | 162 | 96 | 1 | 4 6 11 19 20 27 34 45 |
| 41 | `0x0D627E8` | ✓ | 14 | 18 | 16 | 6 | 132 | 92 | 1 | 4 6 11 15 19 20 27 29 34 45 |
| 42 | `0x0D65830` | ✓ | 9 | 13 | 13 | 6 | 120 | 86 | 1 | 6 11 19 20 22 23 27 29 34 45 |
| 43 | `0x0D67904` | ✓ | 10 | 12 | 9 | 6 | 106 | 100 | 1 | 4 6 19 27 34 |
| 44 | `0x0D6D3D8` | ✓ | 13 | 19 | 16 | 6 | 100 | 112 | 4 (starts [0, 5, 8, 11]) | 2 4 5 6 11 19 20 27 29 34 45 |
| 45 | `0x0D6E0FC` | ✓ | 8 | 10 | 6 | 4 | 126 | 96 | 1 | 6 19 27 34 45 |
| 46 | `0x0D6F32C` | ✓ | 8 | 3 | 3 | 6 | 80 | 128 | 1 | 6 19 45 |

## LEGO Star Wars: The Video Game (U)

* Signature: `$Id: player.c,v 1.4 2003/03/19 23:12:15 seb Exp $` @ 0x0071AD8
* Pattern format: **old (< 2004-07-07)**
* Sample list: `0x02FA394`, 225 samples
* Instrument list: none (every module is sample-based, `flagInstrumentBased = 0`)
* Modules: **18** (Unkrawerter default finds 11, misses 7)

| # | Offset | U | Ch | Orders | Patterns | Speed | BPM | VolGlobal | Sub-songs (`+++`) | Effects used |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | `0x0073328` | ✗ | 16 | 2 | 2 | 4 | 165 | 128 | 1 | 1 5 6 19 34 |
| 1 | `0x0073A60` | ✗ | 16 | 2 | 2 | 8 | 90 | 128 | 1 | 1 2 5 6 19 34 |
| 2 | `0x0076408` | ✓ | 16 | 16 | 16 | 3 | 120 | 140 | 1 | 1 2 5 6 15 34 45 |
| 3 | `0x0078940` | ✓ | 16 | 10 | 10 | 4 | 129 | 100 | 1 | 2 4 5 6 19 34 |
| 4 | `0x007A6E0` | ✓ | 16 | 8 | 8 | 6 | 136 | 128 | 1 | 5 6 19 34 |
| 5 | `0x007B278` | ✗ | 16 | 3 | 3 | 4 | 134 | 128 | 1 | 1 5 6 34 |
| 6 | `0x007E5AC` | ✓ | 16 | 13 | 13 | 6 | 162 | 128 | 1 | 1 2 4 6 27 29 34 45 |
| 7 | `0x0083CFC` | ✓ | 16 | 25 | 25 | 6 | 150 | 128 | 1 | 2 4 5 6 27 34 |
| 8 | `0x0084284` | ✗ | 16 | 2 | 2 | 6 | 190 | 128 | 1 | 5 6 34 |
| 9 | `0x008A6C4` | ✓ | 16 | 18 | 18 | 6 | 150 | 100 | 1 | 1 2 4 5 6 19 27 29 34 45 |
| 10 | `0x008AFA4` | ✗ | 16 | 3 | 3 | 4 | 150 | 128 | 1 | 5 6 34 45 |
| 11 | `0x008D114` | ✓ | 16 | 13 | 13 | 6 | 170 | 128 | 1 | 5 6 20 23 34 |
| 12 | `0x02FADF8` | ✗ | 16 | 2 | 2 | 4 | 60 | 160 | 1 | 6 19 34 |
| 13 | `0x02FB84C` | ✗ | 16 | 3 | 3 | 6 | 115 | 128 | 1 | 2 5 6 34 |
| 14 | `0x02FD9F8` | ✓ | 16 | 14 | 14 | 4 | 132 | 128 | 1 | 5 6 19 29 34 45 |
| 15 | `0x02FE5B8` | ✓ | 16 | 6 | 6 | 6 | 107 | 128 | 1 | 6 34 |
| 16 | `0x02FFD14` | ✓ | 16 | 8 | 8 | 6 | 170 | 140 | 1 | 1 2 5 6 34 45 |
| 17 | `0x0300888` | ✓ | 16 | 5 | 5 | 6 | 120 | 128 | 1 | 5 6 34 |

## Franklin the Turtle (E)

* Signature: `$Id: Krawall $Date: 2003/09/01 06:51:01 $` @ 0x03DF180
* Pattern format: **old (< 2004-07-07)**
* Sample list: `0x03DEFB8`, 114 samples
* Instrument list: none (every module is sample-based, `flagInstrumentBased = 0`)
* Modules: **15** (Unkrawerter default finds 4, misses 11)

| # | Offset | U | Ch | Orders | Patterns | Speed | BPM | VolGlobal | Sub-songs (`+++`) | Effects used |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | `0x032AC48` | ✓ | 4 | 9 | 6 | 6 | 125 | 128 | 1 | 1 2 5 6 |
| 1 | `0x032D3C0` | ✓ | 4 | 22 | 14 | 6 | 125 | 128 | 1 | 1 2 6 |
| 2 | `0x032F580` | ✓ | 4 | 22 | 12 | 6 | 125 | 128 | 1 | 1 2 6 |
| 3 | `0x0330C30` | ✓ | 4 | 13 | 9 | 6 | 125 | 128 | 1 | 1 4 5 6 |
| 4 | `0x0330EF0` | ✗ | 4 | 1 | 1 | 6 | 125 | 128 | 1 | 1 2 6 |
| 5 | `0x0331178` | ✗ | 4 | 1 | 1 | 6 | 125 | 128 | 1 | 1 2 6 11 |
| 6 | `0x033140C` | ✗ | 4 | 1 | 1 | 6 | 125 | 128 | 1 | 1 2 6 |
| 7 | `0x0331694` | ✗ | 4 | 1 | 1 | 6 | 125 | 128 | 1 | 1 2 6 |
| 8 | `0x0331908` | ✗ | 4 | 1 | 1 | 6 | 125 | 128 | 1 | 1 2 6 |
| 9 | `0x0331B94` | ✗ | 4 | 1 | 1 | 6 | 125 | 128 | 1 | 1 2 6 |
| 10 | `0x0331E40` | ✗ | 4 | 1 | 1 | 6 | 125 | 128 | 1 | 1 2 6 11 15 |
| 11 | `0x033209C` | ✗ | 4 | 1 | 1 | 6 | 125 | 128 | 1 | 1 2 6 |
| 12 | `0x033231C` | ✗ | 4 | 1 | 1 | 6 | 125 | 128 | 1 | 1 2 6 |
| 13 | `0x0332594` | ✗ | 4 | 1 | 1 | 6 | 125 | 128 | 1 | 1 2 |
| 14 | `0x0332824` | ✗ | 4 | 1 | 1 | 6 | 125 | 128 | 1 | 1 2 6 11 15 |

## LEGO Star Wars II: The Original Trilogy (E)

* Signature: `$Id: Krawall $Id: version.h 8 2005-04-21 12:24:45Z seb $` @ 0x0FCF620
* Pattern format: **new (≥ 2004-07-07)**
* Sample list: `0x08932F4`, 302 samples
* Instrument list: none (every module is sample-based, `flagInstrumentBased = 0`)
* Modules: **26** (Unkrawerter default finds 19, misses 7)

| # | Offset | U | Ch | Orders | Patterns | Speed | BPM | VolGlobal | Sub-songs (`+++`) | Effects used |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | `0x061E9E4` | ✓ | 16 | 6 | 6 | 6 | 165 | 128 | 1 | 6 34 45 |
| 1 | `0x061F5F0` | ✓ | 16 | 4 | 4 | 6 | 80 | 128 | 1 | 2 5 6 34 |
| 2 | `0x061FE48` | ✗ | 16 | 3 | 3 | 8 | 132 | 128 | 1 | 2 5 6 34 |
| 3 | `0x0620E30` | ✓ | 16 | 4 | 4 | 6 | 95 | 128 | 1 | 2 5 6 19 29 34 45 |
| 4 | `0x06219F4` | ✓ | 16 | 4 | 4 | 8 | 96 | 128 | 1 | 2 4 5 6 29 34 45 |
| 5 | `0x062406C` | ✓ | 16 | 8 | 8 | 3 | 130 | 80 | 1 | 1 6 19 20 34 |
| 6 | `0x06259EC` | ✓ | 16 | 5 | 5 | 6 | 168 | 128 | 1 | 2 5 6 34 |
| 7 | `0x0627154` | ✓ | 16 | 6 | 6 | 4 | 145 | 128 | 1 | 2 4 5 6 19 34 |
| 8 | `0x06281E8` | ✓ | 16 | 6 | 6 | 8 | 160 | 128 | 1 | 5 6 34 |
| 9 | `0x0629034` | ✗ | 16 | 3 | 3 | 6 | 148 | 128 | 1 | 6 19 34 45 |
| 10 | `0x0629BE8` | ✓ | 16 | 5 | 5 | 6 | 116 | 128 | 1 | 1 2 4 5 6 34 45 |
| 11 | `0x062A84C` | ✓ | 16 | 5 | 5 | 6 | 152 | 100 | 1 | 2 5 6 34 45 |
| 12 | `0x062AC50` | ✗ | 16 | 1 | 1 | 8 | 142 | 100 | 1 | 5 6 34 |
| 13 | `0x062B1AC` | ✗ | 16 | 3 | 3 | 6 | 154 | 128 | 1 | 5 6 34 |
| 14 | `0x062EAE4` | ✓ | 16 | 16 | 16 | 4 | 137 | 128 | 1 | 2 5 6 34 45 |
| 15 | `0x062F390` | ✗ | 16 | 2 | 2 | 6 | 160 | 128 | 1 | 2 5 6 34 |
| 16 | `0x0634AA0` | ✓ | 16 | 25 | 25 | 6 | 150 | 100 | 1 | 2 4 5 6 27 34 |
| 17 | `0x0636C80` | ✓ | 16 | 16 | 16 | 6 | 160 | 128 | 1 | 2 5 6 34 |
| 18 | `0x06375C0` | ✓ | 16 | 4 | 4 | 4 | 137 | 128 | 1 | 2 5 6 34 |
| 19 | `0x063D9EC` | ✓ | 16 | 18 | 18 | 6 | 150 | 120 | 1 | 1 2 4 5 6 19 27 29 34 45 |
| 20 | `0x063DEC0` | ✗ | 16 | 2 | 2 | 6 | 150 | 128 | 1 | 2 5 6 34 |
| 21 | `0x063E558` | ✓ | 16 | 4 | 4 | 6 | 116 | 128 | 1 | 5 6 34 |
| 22 | `0x063F01C` | ✓ | 16 | 4 | 4 | 6 | 118 | 128 | 1 | 2 4 5 6 19 20 34 |
| 23 | `0x063F73C` | ✗ | 16 | 2 | 2 | 6 | 150 | 128 | 1 | 2 5 6 34 45 |
| 24 | `0x06418CC` | ✓ | 16 | 11 | 11 | 6 | 152 | 128 | 1 | 2 4 5 6 34 45 |
| 25 | `0x064259C` | ✓ | 16 | 6 | 6 | 6 | 150 | 128 | 1 | 2 5 6 34 |

## Big Mutha Truckers (E)

* Signature: none. Identified by the credit *"Sound Engine: Synk, Kienzl & Prohaszka OEG"* (`0x004317C`), Krawall's constant tables at `0x00556F4` (sine) / `0x0055874` (random) / `0x00559E4` (finetune), and the data below.
* Pattern format: **new (≥ 2004-07-07)**
* Sample bank: header `0x00BB0C0` (`u16 count = 90`), first sample `0x00BB0D0`; pointer list `0x0177080` (90 entries). Sample headers store the **length** at +4 instead of an end pointer.
* Modules: **14**, all packed (custom LZ, unpacked by the game's IWRAM routine at `0x030026D0`, ROM `0x03EC8F8`). Unkrawerter finds none.

| # | Packed blob | Unpacked size | Ch | Orders | Patterns | Rows used | Instruments | Speed | BPM | Flags (ins, linear) |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | `0x01771F0` | 1702 | 5 | 5 | 2 | 11, 128 | 3 | 6 | 110 | 1, 1 |
| 1 | `0x0177310` | 8770 | 8 | 8 | 7 | 128 | 7 | 3 | 129 | 1, 1 |
| 2 | `0x0177680` | 10774 | 8 | 7 | 7 | 24, 128 | 10 | 3 | 111 | 1, 1 |
| 3 | `0x0177F10` | 9718 | 8 | 12 | 6 | 128 | 10 | 3 | 135 | 1, 1 |
| 4 | `0x01783E0` | 9918 | 8 | 12 | 7 | 64 | 9 | 6 | 120 | 1, 1 |
| 5 | `0x01789E0` | 3166 | 8 | 5 | 4 | 64 | 3 | 6 | 75 | 1, 1 |
| 6 | `0x0178CA0` | 8902 | 8 | 9 | 8 | 96 | 11 | 3 | 94 | 1, 1 |
| 7 | `0x0179360` | 4070 | 7 | 5 | 4 | 192, 240 | 1 | 2 | 106 | 1, 1 |
| 8 | `0x0179660` | 11650 | 8 | 14 | 12 | 8, 96 | 10 | 3 | 105 | 1, 1 |
| 9 | `0x017A050` | 17634 | 8 | 28 | 17 | 16, 64, 90 | 10 | 6 | 140 | 1, 1 |
| 10 | `0x017AC90` | 22442 | 8 | 24 | 18 | 64 | 9 | 6 | 140 | 1, 1 |
| 11 | `0x017B7A0` | 14898 | 8 | 24 | 13 | 64 | 12 | 6 | 136 | 1, 1 |
| 12 | `0x017C190` | 18322 | 8 | 25 | 13 | 6, 14, 32, 39, 64, 96 | 9 | 6 | 138 | 1, 1 |
| 13 | `0x017CA10` | 7146 | 8 | 14 | 14 | 64, 128 | 5 | 3 | 120 | 1, 1 |

Effects used across all BMT modules (Krawall IDs): 3 (XM `Fxx`), 14 (porta up XM), 16 (fine porta up), 19 (tone porta), 20 (vibrato), 27 (sample offset), 34 (set pan). Volume column: volumes plus `Cx` set-panning.

## Agent Hugo: RoboRumble (E)

* Signature: `$Id: player.c,v 1.4 2003/03/19 23:12:15 seb Exp $` @ `0x01982DC`; `table_sine` @ `0x01985C4`
* Pattern format: **old (< 2004-07-07)**
* Sample list: `0x02CD4D8`, 132 samples
* Instrument list: `0x01ABE50`, 95 instruments
* Modules: **5**. Unkrawerter fails by default (sample list rejected, see reference §7.5); `-s 2938072 -k` converts all five.

| # | Offset | Ch | Orders | Patterns | Rows | Speed | BPM | VolGlobal | Flags (ins, linear) | Effects used |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | `0x019C238` | 14 | 8 | 8 | 128 | 3 | 145 | 128 | 1, 1 | 3 |
| 1 | `0x019EEE8` | 10 | 14 | 14 | 128 | 2 | 180 | 128 | 1, 1 | 3 34 |
| 2 | `0x01A10CC` | 10 | 8 | 8 | 128 | 3 | 130 | 128 | 1, 1 | 3 34 |
| 3 | `0x01A21F8` | 13 | 8 | 8 | 128 | 3 | 240 | 128 | 1, 1 | 3 34 |
| 4 | `0x01A4BFC` | 17 | 6 | 6 | 128 | 3 | 140 | 128 | 1, 1 | 3 |

Sample notes: 14 samples have `c2Freq > 65535` (sample 0 = 105 439); 25 one-shot samples carry a non-zero `loopLength`; sample 32 is **ping-pong** (`loop = 2`), used by instrument 15 (36 cells in module 1). Instruments 71–95 are not used by any pattern.

## Puppy Luv: Spa and Resort (U)

* Signature: none; `table_sine` @ `0x0384A3C`
* Pattern format: **new (≥ 2004-07-07)**
* Sample list: `0x037E738`, 135 samples
* Instrument list: `0x03845F4`, 78 instruments
* Modules: **7**. Unkrawerter's default finds modules 1–6; module 0 (1 channel, 1 pattern, sample-based) needs `-t 1`.

| # | Offset | Ch | Orders | Patterns | Rows | Speed | BPM | VolGlobal | Flags (ins, linear) | Effects used |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | `0x02B5FD8` | 1 | 1 | 1 | 64 | 6 | 125 | 128 | 0, 0 |  |
| 1 | `0x02B7ED0` | 29 | 11 | 11 | 128 | 3 | 240 | 128 | 1, 1 | 3 4 |
| 2 | `0x02B9C48` | 21 | 12 | 12 | 128 | 3 | 240 | 128 | 1, 1 | 3 4 |
| 3 | `0x02BB004` | 14 | 7 | 7 | 128 | 3 | 240 | 128 | 1, 1 | 3 4 34 |
| 4 | `0x02BC848` | 25 | 8 | 8 | 128 | 3 | 240 | 128 | 1, 1 | 3 4 |
| 5 | `0x02BFBB0` | 21 | 15 | 15 | 128 | 3 | 240 | 128 | 1, 1 | 3 4 34 |
| 6 | `0x02C24F4` | 24 | 13 | 13 | 128 | 3 | 240 | 128 | 1, 1 | 3 4 |

Sample notes: 6 samples have `c2Freq > 65535`, but the first four are ordinary, so Unkrawerter's check passes.

## Princess Natasha: Student, Secret Agent, Princess (E)

* Signature: none; `table_sine` @ `0x0378D84`
* Layout: **BMT-style packed** (same loader source, same IWRAM decompressor byte for byte). Pattern format: new.
* Sample bank: header `0x0379D00` (`u16 count = 152`), first sample `0x0379D10`; pointer list `0x03EDB90`. Headers store the length at +4.
* Loader: unpacker `0x0801CFCC` (wrapper `0x0801D1B0`), decompressor stub `0x080242A0` → IWRAM `0x03001F80`; IWRAM image at ROM `0x03F7C84`.
* Modules: **11** packed blobs, each referenced from game code. Unkrawerter finds none.

| # | Blob | Unpacked size | Ch | Orders | Patterns | Rows | Instruments | Speed | BPM | Flags (ins, linear) | Effects used |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | `0x03EDE00` | 1222 | 6 | 1 | 1 | 64 | 2 | 6 | 125 | 1, 1 | 3 |
| 1 | `0x03EDED0` | 5918 | 6 | 7 | 5 | 64 | 10 | 6 | 125 | 1, 1 | 3 4 10 34 |
| 2 | `0x03EE260` | 9510 | 6 | 12 | 10 | 64 | 14 | 6 | 125 | 1, 1 | 3 4 19 34 |
| 3 | `0x03EE8D0` | 11170 | 6 | 11 | 10 | 64 | 13 | 6 | 125 | 1, 1 | 3 4 5 34 |
| 4 | `0x03EF010` | 11738 | 6 | 9 | 9 | 64 | 13 | 6 | 125 | 1, 1 | 3 4 19 34 |
| 5 | `0x03EF910` | 8686 | 6 | 10 | 9 | 64 | 15 | 6 | 125 | 1, 1 | 3 5 14 19 |
| 6 | `0x03F0010` | 10902 | 6 | 12 | 9 | 64 | 15 | 6 | 125 | 1, 1 | 3 4 19 34 |
| 7 | `0x03F07C0` | 7038 | 6 | 6 | 5 | 64 | 13 | 6 | 125 | 1, 1 | 3 4 34 |
| 8 | `0x03F0C60` | 11890 | 6 | 9 | 8 | 64 | 19 | 6 | 125 | 1, 1 | 3 4 34 |
| 9 | `0x03F1330` | 8058 | 6 | 8 | 7 | 64 | 13 | 6 | 125 | 1, 1 | 3 4 5 14 19 |
| 10 | `0x03F19A0` | 14230 | 6 | 13 | 11 | 64 | 13 | 6 | 125 | 1, 1 | 3 4 5 34 |

## Barbie: Groovy Games (E)

Not Krawall. None of Krawall's tables, no signature or credit (sound and music: David Kerr, Clandro Cautillo; Digital Illusions Canada), and the DirectSound setup (`SOUNDCNT_H = 0xBB0E` at `0x0024924`, both FIFOs to both speakers, PSG enabled) differs from Krawall's `dsInit` (`0x9A0C`). It is a different driver, most likely DICE's own.
