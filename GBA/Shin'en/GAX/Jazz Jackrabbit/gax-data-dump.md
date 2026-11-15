# GAX data dump

Companion to `claude/gax-technical-reference.md`.

* Every address is a ROM file offset (OR with `0x08000000` for the GBA address).
* All songs were found by an independent structural scan (`gaxlib.py`, reference §2).
* Every pattern of every channel was decoded with the reference §6 rules. In all 130 songs the decode ends exactly at the song's title string, so the song lists are complete for these ROMs.
* For GAX2-era ROMs, *Header* is the song (handler-list) struct, and *info* is its SongInfo.
* Columns:
  * *Instr. used*: distinct non-zero instruments referenced by the patterns.
  * *Effects used*: pattern effect commands, in GAX numbering (§7).
  * *gaxm (orig)*: the upstream gaxm (c79910e) result. With `gaxm-fixes.patch`, every song in this file converts.

## Summary

| ROM | GAX version | Songs | Instrument layout | PCM | Upstream gaxm | Patched gaxm |
|---|---|---|---|---|---|---|
| Iridion 3D (U) | v1.99d (Mar 13 2001) | 24 | old | signed | 23 | 24 |
| Earthworm Jim (U) | v1.99d (Mar 30 2001) | 11 | old | signed | 11 | 11 |
| Comix Zone (E) | v2.01b (Jun 22 2001) | 24 | old | signed | 24 | 24 |
| Jackie Chan Adventures (U) | v2.01b (Jun 22 2001) | 10 | old | signed | 10 | 10 |
| Bruce Lee: Return of the Legend (E) | 2.35 (Jun 17 2002) | 12 | old | signed | 11 | 12 |
| Tony Hawk's Pro Skater 4 (U) | 3.0 (Jul 16 2002) | 10 | **old** | unsigned | **0** (crash) | 10 |
| Jazz Jackrabbit (U) | 3.01 (Sep 13 2002) | 9 | new | unsigned | 9 | 9 |
| Iridion II (E) | 3.03A (Mar 5 2003) | 30 | new | unsigned | 28 | 30 |

### Corpus statistics (pattern steps by form)

| ROM | full 4-byte | `8x` note+ins | `80` empty | `FF n` run | `FA` fx-only | empty patterns | legato notes (ins 0) |
|---|---|---|---|---|---|---|---|
| Iridion 3D | 10334 | 16199 | 7257 | 3381 | 8736 | 300 | 862 |
| Earthworm Jim | 14538 | 1050 | 6401 | 26593 | 24752 | 233 | 38 |
| Comix Zone | 370 | 28915 | 15166 | 11133 | 395 | 10 | 25 |
| Jackie Chan | 3378 | 5462 | 2437 | 1025 | 1712 | 80 | 830 |
| Bruce Lee | 3831 | 6120 | 4733 | 3193 | 1187 | 117 | 34 |
| THPS4 | 5079 | 6133 | 5233 | 1492 | 3850 | 21 | 29 |
| Jazz Jackrabbit | 2138 | 7757 | 3610 | 2577 | 1675 | 159 | 32 |
| Iridion II | 17028 | 21494 | 9895 | 7474 | 11885 | 465 | 1164 |

`0xFB`–`0xFE` effect-only steps and `FF 00` runs never occur. Every `Dxx` has `xx = 00`. Envelopes with more than 12 points: one (Iridion II "tutorial", instrument 0x12, 16 points).

## Iridion 3D (U)

* Version string: `GAX Sound Engine v1.99d (Mar 13 2001) © Shin'en Multimedia. Code: B.Wodok` @ `0x01DEE20`
* Song format: **GAX2 handler graph (song struct → mixer/info/channel SoundHandlers)**; SongInfo **without** volume field, no mix-rate fields
* Instrument layout: **old (4 × 28-byte wave params at +0x0C)**; samples: **signed 8-bit**
* Instrument table(s): `0x016FDCC`; sample table(s): `0x01990A8`
* Songs: **24**

| # | Header | Title | Ch | Rows | Orders | Loop | Mix Hz | FX ch | Vol | Instr. used | Effects used | gaxm (orig) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | `0x0199A18` (info `0x01998EC`) | menu | 6 | 32 | 10 | 0 | — | — | — | 14 | C F | ✓ |
| 1 | `0x019A3C8` (info `0x019A2DC`) | level1 | 4 | 32 | 25 | 3 | — | — | — | 12 | C F | ✓ |
| 2 | `0x019AA5C` (info `0x019A970`) | boss1 | 4 | 32 | 19 | 0 | — | — | — | 10 | C F | ✓ |
| 3 | `0x019AC34` (info `0x019AB48`) | InfoScreen | 4 | 16 | 1 | 0 | — | — | — | 5 | C F | ✓ |
| 4 | `0x019B710` (info `0x019B604`) | level 2 | 5 | 32 | 19 | 1 | — | — | — | 9 | 1 3 C F | ✓ |
| 5 | `0x019BA0C` (info `0x019B880`) | scorecount | 9 | 32 | 1 | 0 | — | — | — | 9 | B C F | ✓ |
| 6 | `0x019BF0C` (info `0x019BDE0`) | hiscore | 6 | 32 | 10 | 2 | — | — | — | 7 | 1 3 C F | ✓ |
| 7 | `0x019C624` (info `0x019C518`) | boss2 | 5 | 32 | 17 | 5 | — | — | — | 10 | C F | ✓ |
| 8 | `0x019C854` (info `0x019C728`) | gameover | 6 | 32 | 2 | 1 | — | — | — | 4 | C F | ✓ |
| 9 | `0x019CB0C` (info `0x019C9E0`) | levelstart | 6 | 32 | 2 | 1 | — | — | — | 5 | 2 B C F | ✓ |
| 10 | `0x019D728` (info `0x019D61C`) | level3 | 5 | 32 | 22 | 6 | — | — | — | 15 | 2 3 A C F | ✓ |
| 11 | `0x019DCAC` (info `0x019DBA0`) | boss3 | 5 | 32 | 12 | 2 | — | — | — | 10 | C F | ✓ |
| 12 | `0x019E504` (info `0x019E3B8`) | gameintro | 7 | 32 | 28 | 0 | — | — | — | 16 | A B C F | ✓ |
| 13 | `0x019F204` (info `0x019F0F8`) | level7 | 5 | 32 | 32 | 8 | — | — | — | 13 | 1 3 B C D F | ✓ |
| 14 | `0x01A12B8` (info `0x01A112C`) | credits | 9 | 32 | 54 | 0 | — | — | — | 14 | 1 3 A B C E F | ✓ |
| 15 | `0x01A2018` (info `0x01A1F0C`) | level4 | 5 | 32 | 27 | 3 | — | — | — | 13 | 1 2 3 A B C | ✓ |
| 16 | `0x01A2414` (info `0x01A2308`) | boss4 | 5 | 32 | 9 | 1 | — | — | — | 9 | B C F | ✓ |
| 17 | `0x01A2FA4` (info `0x01A2E98`) | level5 | 5 | 32 | 28 | 5 | — | — | — | 12 | 1 2 3 A C F | ✓ |
| 18 | `0x01A3380` (info `0x01A3274`) | boss5 | 5 | 32 | 12 | 2 | — | — | — | 8 | 2 C | ✓ |
| 19 | `0x01A439C` (info `0x01A4290`) | level6 | 5 | 32 | 29 | 5 | — | — | — | 14 | B C F | ✓ |
| 20 | `0x01A48BC` (info `0x01A47B0`) | boss6 | 5 | 32 | 10 | 4 | — | — | — | 8 | B C F | ✓ |
| 21 | `0x01A4F40` (info `0x01A4E34`) | boss7 | 5 | 32 | 17 | 9 | — | — | — | 9 | 1 2 B C F | ✓ |
| 22 | `0x01A5030` (info `0x01A4F84`) | empty | 2 | 32 | 1 | 0 | — | — | — | 0 |  | ✗ (not found: no instruments) |
| 23 | `0x01A53C0` (info `0x01A52B4`) | shinen | 5 | 32 | 2 | 0 | — | — | — | 3 | 3 A B C F | ✓ |

## Earthworm Jim (U)

* Version string: `GAX Sound Engine v1.99d (Mar 30 2001) © Shin'en Multimedia. Code: B.Wodok` @ `0x03C9BF0`
* Song format: **GAX2 handler graph (song struct → mixer/info/channel SoundHandlers)**; SongInfo **without** volume field, no mix-rate fields
* Instrument layout: **old (4 × 28-byte wave params at +0x0C)**; samples: **signed 8-bit**
* Instrument table(s): `0x036D478`; sample table(s): `0x0397D04`
* Songs: **11**

| # | Header | Title | Ch | Rows | Orders | Loop | Mix Hz | FX ch | Vol | Instr. used | Effects used | gaxm (orig) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | `0x03A2F20` (info `0x03A2DB4`) | newjunkcity | 8 | 256 | 29 | 0 | — | — | — | 11 | C D F | ✓ |
| 1 | `0x03A3108` (info `0x03A303C`) | racelost | 3 | 26 | 1 | 0 | — | — | — | 1 | C F | ✓ |
| 2 | `0x03A6F9C` (info `0x03A6E30`) | psycrow | 8 | 256 | 10 | 6 | — | — | — | 6 | C D F | ✓ |
| 3 | `0x03AD4E4` (info `0x03AD378`) | buttville | 8 | 243 | 13 | 3 | — | — | — | 8 | B C D F | ✓ |
| 4 | `0x03B15D8` (info `0x03B146C`) | andy | 8 | 256 | 25 | 1 | — | — | — | 8 | C D F | ✓ |
| 5 | `0x03B4950` (info `0x03B47E4`) | ending | 8 | 64 | 24 | 0 | — | — | — | 3 | 1 C D F | ✓ |
| 6 | `0x03B97F8` (info `0x03B968C`) | pete | 8 | 256 | 23 | 0 | — | — | — | 9 | C D F | ✓ |
| 7 | `0x03BF528` (info `0x03BF3BC`) | level5 | 8 | 256 | 25 | 4 | — | — | — | 15 | C D F | ✓ |
| 8 | `0x03C06A0` (info `0x03C0534`) | rodeojim | 8 | 64 | 30 | 0 | — | — | — | 5 | C D F | ✓ |
| 9 | `0x03C3F70` (info `0x03C3E04`) | snotaproblem | 8 | 256 | 12 | 0 | — | — | — | 10 | 1 C D F | ✓ |
| 10 | `0x03C9B08` (info `0x03C999C`) | whattheheck | 8 | 64 | 41 | 26 | — | — | — | 10 | C D F | ✓ |

## Comix Zone (E) (M5)

* Version string: `GAX Sound Engine v2.01b (Jun 22 2001) © Shin'en Multimedia. Code: B.Wodok` @ `0x00D0ABC`
* Song format: **GAX2 handler graph (song struct → mixer/info/channel SoundHandlers)**; SongInfo with volume field
* Instrument layout: **old (4 × 28-byte wave params at +0x0C)**; samples: **signed 8-bit**
* Instrument table(s): `0x008C1E4`; sample table(s): `0x00C0AF4`
* Songs: **24**

| # | Header | Title | Ch | Rows | Orders | Loop | Mix Hz | FX ch | Vol | Instr. used | Effects used | gaxm (orig) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | `0x00C1440` (info `0x00C12EC`) | 1 | 7 | 64 | 7 | 0 | 15769 | 1 | 258 | 8 | 3 C F | ✓ |
| 1 | `0x00C246C` (info `0x00C2318`) | 2 | 7 | 64 | 12 | 0 | 15769 | 1 | 256 | 9 | C D F | ✓ |
| 2 | `0x00C2AB0` (info `0x00C295C`) | 3 | 7 | 64 | 6 | 0 | 15769 | 1 | 256 | 10 | 7 C | ✓ |
| 3 | `0x00C35EC` (info `0x00C3498`) | 4 | 7 | 64 | 9 | 0 | 15769 | 1 | 256 | 9 | C D F | ✓ |
| 4 | `0x00C3F28` (info `0x00C3DD4`) | 5 | 7 | 64 | 12 | 0 | 15769 | 1 | 256 | 9 | C D F | ✓ |
| 5 | `0x00C4A30` (info `0x00C48DC`) | 6 | 7 | 64 | 14 | 0 | 15769 | 1 | 256 | 10 | 3 C F | ✓ |
| 6 | `0x00C5094` (info `0x00C4F40`) | 7 | 7 | 64 | 5 | 0 | 15769 | 1 | 256 | 8 | C | ✓ |
| 7 | `0x00C6150` (info `0x00C5FFC`) | 8 | 7 | 64 | 18 | 0 | 15769 | 1 | 256 | 10 | 3 C F | ✓ |
| 8 | `0x00C6C24` (info `0x00C6AD0`) | 9 | 7 | 64 | 8 | 0 | 15769 | 1 | 256 | 9 | C F | ✓ |
| 9 | `0x00C78FC` (info `0x00C77A8`) | 10 | 7 | 64 | 12 | 0 | 15769 | 1 | 256 | 10 | D F | ✓ |
| 10 | `0x00C8CA8` (info `0x00C8B54`) | 11 | 7 | 64 | 11 | 0 | 15769 | 1 | 256 | 11 | D | ✓ |
| 11 | `0x00C94EC` (info `0x00C9398`) | 12 | 7 | 64 | 5 | 0 | 15769 | 1 | 256 | 10 | D F | ✓ |
| 12 | `0x00C9FBC` (info `0x00C9E68`) | 13 | 7 | 64 | 6 | 0 | 15769 | 1 | 256 | 8 | C F | ✓ |
| 13 | `0x00CABAC` (info `0x00CAA58`) | 14 | 7 | 64 | 16 | 0 | 15769 | 1 | 256 | 9 | C F | ✓ |
| 14 | `0x00CB5BC` (info `0x00CB468`) | 15 | 7 | 64 | 14 | 0 | 15769 | 1 | 256 | 10 | C D F | ✓ |
| 15 | `0x00CBD80` (info `0x00CBC2C`) | 16 | 7 | 64 | 14 | 0 | 15769 | 1 | 256 | 12 | C D F | ✓ |
| 16 | `0x00CCA6C` (info `0x00CC918`) | 17 | 7 | 64 | 8 | 0 | 15769 | 1 | 256 | 9 | C F | ✓ |
| 17 | `0x00CD288` (info `0x00CD134`) | 18 | 7 | 64 | 10 | 0 | 15769 | 1 | 256 | 10 | C | ✓ |
| 18 | `0x00CDDA0` (info `0x00CDC4C`) | 19 | 7 | 64 | 5 | 0 | 15769 | 1 | 258 | 10 | 3 C F | ✓ |
| 19 | `0x00CEDA0` (info `0x00CEC4C`) | 20 | 7 | 64 | 18 | 0 | 15769 | 1 | 256 | 11 | 3 C F | ✓ |
| 20 | `0x00CF4A0` (info `0x00CF34C`) | Startpict | 7 | 64 | 3 | 0 | 15769 | 1 | 256 | 10 | C F | ✓ |
| 21 | `0x00D0000` (info `0x00CFEAC`) | Intromovie | 7 | 64 | 7 | 5 | 15769 | 1 | 256 | 10 | 1 3 C D F | ✓ |
| 22 | `0x00D0508` (info `0x00D03B4`) | IntroSega | 7 | 64 | 3 | 0 | 15769 | 1 | 256 | 11 | 3 7 C F | ✓ |
| 23 | `0x00D0958` (info `0x00D0804`) | Game over | 7 | 64 | 2 | 0 | 15769 | 1 | 256 | 9 | 2 F | ✓ |

## Jackie Chan Adventures - Legend of the Dark Hand (U)

* Version string: `GAX Sound Engine v2.01b (Jun 22 2001) © Shin'en Multimedia. Code: B.Wodok` @ `0x03C07F8`
* Song format: **GAX2 handler graph (song struct → mixer/info/channel SoundHandlers)**; SongInfo with volume field
* Instrument layout: **old (4 × 28-byte wave params at +0x0C)**; samples: **signed 8-bit**
* Instrument table(s): `0x035E3A4`; sample table(s): `0x0374614`
* Songs: **10**

| # | Header | Title | Ch | Rows | Orders | Loop | Mix Hz | FX ch | Vol | Instr. used | Effects used | gaxm (orig) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | `0x0374BD4` (info `0x0374A60`) | menu | 8 | 32 | 11 | 1 | 18158 | 1 | 225 | 8 | 7 C | ✓ |
| 1 | `0x0375324` (info `0x0375210`) | ingame 1 | 5 | 32 | 30 | 4 | 15769 | 3 | 256 | 8 | B C F | ✓ |
| 2 | `0x0375B04` (info `0x03759F0`) | ingame 2 | 5 | 32 | 16 | 4 | 15769 | 3 | 256 | 10 | 1 3 B C E F | ✓ |
| 3 | `0x03763F0` (info `0x03762DC`) | ingame 3 | 5 | 32 | 20 | 1 | 15769 | 3 | 256 | 8 | 1 3 C D F | ✓ |
| 4 | `0x0376A48` (info `0x0376934`) | ingame 4 | 5 | 32 | 29 | 5 | 15769 | 3 | 343 | 9 | 7 B C F | ✓ |
| 5 | `0x0376D94` (info `0x0376C80`) | game over | 5 | 32 | 3 | 1 | 15769 | 1 | 256 | 7 | C D F | ✓ |
| 6 | `0x03771A0` (info `0x037708C`) | boss 1 | 5 | 16 | 11 | 1 | 15769 | 3 | 256 | 5 | C F | ✓ |
| 7 | `0x0377668` (info `0x0377554`) | boss 2 | 5 | 16 | 21 | 3 | 15769 | 3 | 256 | 7 | 3 C | ✓ |
| 8 | `0x03778F8` (info `0x03777E4`) | congrats | 5 | 16 | 8 | 0 | 15769 | 2 | 256 | 5 | C F | ✓ |
| 9 | `0x0377D18` (info `0x0377BC4`) | intro | 7 | 16 | 12 | 0 | 18158 | 1 | 419 | 9 | 1 2 3 B F | ✓ |

## Bruce Lee - Return of the Legend (E) (M5)

* Version string: `GAX Sound Engine 2.35 (Jun 17 2002) © Shin'en Multimedia. Code: B.Wodok` @ `0x0430584`
* Song format: **GAX2 handler graph (song struct → mixer/info/channel SoundHandlers)**; SongInfo with volume field
* Instrument layout: **old (4 × 28-byte wave params at +0x0C)**; samples: **signed 8-bit**
* Instrument table(s): `0x03E3244`; sample table(s): `0x042B1B4`
* Songs: **12**

| # | Header | Title | Ch | Rows | Orders | Loop | Mix Hz | FX ch | Vol | Instr. used | Effects used | gaxm (orig) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | `0x042B818` (info `0x042B6E0`) | StealthoutDoorsSketch1 | 6 | 32 | 12 | 0 | 15769 | 1 | 256 | 13 | 7 C | ✓ |
| 1 | `0x042BCDC` (info `0x042BBA4`) | ActionSketch1 | 6 | 32 | 13 | 4 | 21025 | 2 | 302 | 16 | 1 C F | ✓ |
| 2 | `0x042C0C0` (info `0x042BF88`) | StealthIndoorsSketch | 6 | 24 | 12 | 0 | 15769 | 1 | 335 | 15 | C F | ✓ |
| 3 | `0x042C9C8` (info `0x042C890`) | Asia | 6 | 32 | 14 | 0 | 15769 | 1 | 256 | 18 | C F | ✓ |
| 4 | `0x042D250` (info `0x042D118`) | UsaAction | 6 | 32 | 16 | 0 | 15769 | 1 | 335 | 27 | 2 3 7 C | ✓ |
| 5 | `0x042D96C` (info `0x042D834`) | JungleAction | 6 | 32 | 12 | 0 | 15769 | 1 | 268 | 19 | C F | ✓ |
| 6 | `0x042E1DC` (info `0x042E0A4`) | Lab | 6 | 32 | 28 | 0 | 15769 | 1 | 381 | 21 | 3 C F | ✓ |
| 7 | `0x042E7B4` (info `0x042E67C`) | Boss | 6 | 32 | 7 | 0 | 15769 | 1 | 348 | 21 | 1 C F | ✓ |
| 8 | `0x042ED68` (info `0x042EC30`) | Underground | 6 | 32 | 16 | 0 | 15769 | 1 | 348 | 16 | 7 C | ✓ |
| 9 | `0x042F214` (info `0x042F0BC`) | Credits | 7 | 32 | 8 | 0 | 15769 | 1 | 302 | 7 | C F | ✓ |
| 10 | `0x042FE0C` (info `0x042FC54`) | Title/UI | 10 | 32 | 22 | 1 | 15769 | 1 | 368 | 31 | 1 C F | ✗ (crash: "/" in file name) |
| 11 | `0x043055C` (info `0x0430424`) | ExtraAction | 6 | 32 | 20 | 0 | 15769 | 1 | 381 | 15 | C F | ✓ |

## Tony Hawk's Pro Skater 4 (U)

* Version string: `GAX Sound Engine 3.0 (Jul 16 2002) © Shin'en Multimedia. Code: B.Wodok` @ `0x07711A4`
* Song format: **GAX3 (SongInfo + 32 channel pointers + DSP block, 0xC8 bytes)**; SongInfo with volume field
* Instrument layout: **old (4 × 28-byte wave params at +0x0C)**; samples: **unsigned 8-bit**
* Instrument table(s): `0x0732CE8`; sample table(s): `0x076C274`
* Songs: **10**

| # | Header | Title | Ch | Rows | Orders | Loop | Mix Hz | FX ch | Vol | Instr. used | Effects used | gaxm (orig) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | `0x076D024` | flirting with desaster | 4 | 32 | 27 | 2 | 21025 | 2 | 208 | 25 | 7 B C | ✗ (whole ROM fails) |
| 1 | `0x076D84C` | dirt in your eyes | 4 | 32 | 18 | 6 | 21025 | 2 | 209 | 15 | 7 B C E | ✗ (whole ROM fails) |
| 2 | `0x076DEF0` | gummy yap | 4 | 32 | 26 | 2 | 21025 | 2 | 245 | 17 | 7 B C | ✗ (whole ROM fails) |
| 3 | `0x076E410` | dan gerros | 4 | 32 | 18 | 3 | 21025 | 2 | 344 | 19 | 1 3 7 C D F | ✗ (whole ROM fails) |
| 4 | `0x076EA1C` | in no sense | 4 | 32 | 20 | 2 | 21025 | 2 | 255 | 17 | B C E F | ✗ (whole ROM fails) |
| 5 | `0x076F114` | end of daze | 4 | 32 | 25 | 1 | 21025 | 2 | 228 | 18 | 3 C F | ✗ (whole ROM fails) |
| 6 | `0x076F8C4` | seek'n destroy | 4 | 32 | 27 | 1 | 21025 | 2 | 236 | 16 | 2 7 C | ✗ (whole ROM fails) |
| 7 | `0x0770130` | my japanese is better | 4 | 32 | 18 | 0 | 21025 | 2 | 245 | 15 | C F | ✗ (whole ROM fails) |
| 8 | `0x07708BC` | 900 degrees of inner turbulence | 4 | 32 | 21 | 1 | 21025 | 2 | 245 | 15 | C F | ✗ (whole ROM fails) |
| 9 | `0x07710DC` | fears'n tears | 4 | 32 | 18 | 4 | 21025 | 2 | 245 | 11 | C E F | ✗ (whole ROM fails) |

## Jazz Jackrabbit (U)

* Version string: `GAX Sound Engine 3.01 (Sep 13 2002) © Shin'en Multimedia. Code: B.Wodok` @ `0x00175B4`; `GAX Sound Engine 3.01 (Sep 13 2002) © Shin'en Multimedia. Code: B.Wodok` @ `0x03DFB70`
* Song format: **GAX3 (SongInfo + 32 channel pointers + DSP block, 0xC8 bytes)**; SongInfo with volume field
* Instrument layout: **new (0x18 header + 24-byte wave params)**; samples: **unsigned 8-bit**
* Instrument table(s): `0x031C09C`; sample table(s): `0x035E69C`
* The ROM holds **two** copies of the 3.01 engine (version strings at `0x00175B4` and `0x03DFB70`); the songs below are all played through one shared instrument/sample bank.
* Songs: **9**

| # | Header | Title | Ch | Rows | Orders | Loop | Mix Hz | FX ch | Vol | Instr. used | Effects used | gaxm (orig) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | `0x035EDE0` | credits | 6 | 32 | 16 | 0 | 21025 | 2 | 358 | 5 | 2 7 | ✓ |
| 1 | `0x035F2E4` | spacelevel | 7 | 32 | 24 | 0 | 21025 | 2 | 256 | 9 | C F | ✓ |
| 2 | `0x035F9FC` | mainmusic | 7 | 32 | 16 | 0 | 21025 | 2 | 256 | 10 | 3 C F | ✓ |
| 3 | `0x03601B0` | castle | 7 | 32 | 40 | 0 | 21025 | 2 | 314 | 9 | C F | ✓ |
| 4 | `0x03605F4` | industrial | 7 | 32 | 18 | 0 | 21025 | 2 | 256 | 9 | C F | ✓ |
| 5 | `0x0360C04` | cave | 7 | 32 | 16 | 0 | 21025 | 2 | 256 | 13 | C F | ✓ |
| 6 | `0x03610FC` | snow | 7 | 32 | 16 | 0 | 21025 | 2 | 256 | 9 | C F | ✓ |
| 7 | `0x03613EC` | boss1 | 7 | 32 | 12 | 0 | 21025 | 2 | 302 | 7 | F | ✓ |
| 8 | `0x0361A9C` | boss2 | 7 | 32 | 8 | 0 | 21025 | 2 | 302 | 10 | C F | ✓ |

## Iridion II (E) (M3)

* Version string: `GAX Sound Engine 3.03A (Mar  5 2003) © Shin'en Multimedia. Code: B.Wodok` @ `0x0161514`
* Song format: **GAX3 (SongInfo + 32 channel pointers + DSP block, 0xC8 bytes)**; SongInfo with volume field
* Instrument layout: **new (0x18 header + 24-byte wave params)**; samples: **unsigned 8-bit**
* Instrument table(s): `0x0112C80`; sample table(s): `0x013F148`
* Songs: **30**

| # | Header | Title | Ch | Rows | Orders | Loop | Mix Hz | FX ch | Vol | Instr. used | Effects used | gaxm (orig) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | `0x013F900` | title | 20 | 16 | 8 | 0 | 21025 | 1 | 468 | 21 | C F | ✓ |
| 1 | `0x013FE00` | intro | 5 | 32 | 8 | 0 | 21025 | 1 | 435 | 10 | B C F | ✓ |
| 2 | `0x01403E4` | menu | 6 | 32 | 19 | 3 | 21025 | 2 | 857 | 10 | C D F | ✓ |
| 3 | `0x0140730` | boss | 7 | 32 | 8 | 2 | 21025 | 3 | 514 | 10 | 3 C D F | ✓ |
| 4 | `0x0140874` | tutorial | 4 | 8 | 2 | 1 | 21025 | 2 | 491 | 2 | 1 2 C F | ✗ (crash: 16-point envelope) |
| 5 | `0x0140B90` | stats2 | 6 | 32 | 4 | 0 | 21025 | 2 | 368 | 8 | 2 C F | ✓ |
| 6 | `0x0140C9C` | speech | 2 | 32 | 1 | 0 | 15769 | 1 | 524 | 1 | 1 2 F | ✓ |
| 7 | `0x014102C` | stats | 10 | 60 | 1 | 0 | 21025 | 1 | 458 | 9 | 3 A B C F | ✓ |
| 8 | `0x0141114` | fx | 1 | 16 | 1 | 0 | 31537 | 2 | 256 | 0 | F | ✗ (not found: no instruments) |
| 9 | `0x0141334` | launch | 6 | 64 | 1 | 0 | 21025 | 1 | 424 | 6 | 2 C F | ✓ |
| 10 | `0x0141954` | gallery | 7 | 32 | 18 | 2 | 42049 | 1 | 491 | 11 | 1 3 B C F | ✓ |
| 11 | `0x0141F14` | game over | 7 | 32 | 5 | 1 | 31537 | 1 | 780 | 11 | 1 7 C E | ✓ |
| 12 | `0x0142250` | general | 8 | 16 | 5 | 1 | 21025 | 2 | 957 | 10 | C F | ✓ |
| 13 | `0x0143058` | azuki canyon | 6 | 32 | 36 | 6 | 21025 | 2 | 770 | 12 | 1 3 B C | ✓ |
| 14 | `0x0144054` | silicis corridor | 6 | 32 | 40 | 8 | 21025 | 2 | 670 | 12 | 3 B C F | ✓ |
| 15 | `0x0145638` | spaceport alpha | 6 | 32 | 44 | 4 | 21025 | 2 | 501 | 14 | 1 3 C E F | ✓ |
| 16 | `0x01465F4` | spaceport delta | 6 | 32 | 50 | 4 | 21025 | 2 | 704 | 11 | 1 3 B C F | ✓ |
| 17 | `0x0147CFC` | spaceport gamma | 6 | 32 | 30 | 2 | 21025 | 2 | 435 | 15 | 1 2 3 B C E F | ✓ |
| 18 | `0x0148B64` | kengamine section | 7 | 32 | 38 | 4 | 21025 | 2 | 903 | 13 | 1 2 3 A B C E F | ✓ |
| 19 | `0x0149CC4` | space minefield | 6 | 32 | 28 | 2 | 21025 | 2 | 737 | 16 | 1 3 7 B C | ✓ |
| 20 | `0x014ADFC` | zansetsu clough | 7 | 32 | 24 | 4 | 21025 | 2 | 970 | 16 | 1 3 7 B C E | ✓ |
| 21 | `0x014BEB0` | seigetsu city | 6 | 32 | 33 | 1 | 21025 | 2 | 624 | 16 | 1 3 B C F | ✓ |
| 22 | `0x014CD44` | dockbay one | 7 | 32 | 30 | 10 | 21025 | 2 | 972 | 15 | 1 3 C F | ✓ |
| 23 | `0x014DD58` | tenshi plains | 7 | 32 | 26 | 4 | 21025 | 2 | 1256 | 17 | 1 3 B C D F | ✓ |
| 24 | `0x014EED0` | asteroids | 7 | 32 | 24 | 4 | 21025 | 2 | 1280 | 15 | 3 C E F | ✓ |
| 25 | `0x014FA68` | kazangan wasteland | 6 | 32 | 33 | 1 | 21025 | 2 | 1080 | 14 | 1 3 C | ✓ |
| 26 | `0x01503C8` | dockbay two | 6 | 32 | 53 | 17 | 21025 | 2 | 1280 | 10 | A C F | ✓ |
| 27 | `0x0150CC0` | final boss | 6 | 32 | 18 | 2 | 21025 | 2 | 714 | 15 | 3 C D F | ✓ |
| 28 | `0x0151F18` | credits | 10 | 32 | 40 | 0 | 42049 | 4 | 890 | 15 | 1 3 B C E F | ✓ |
| 29 | `0x01520AC` | shinen | 3 | 22 | 1 | 0 | 42049 | 0 | 857 | 1 | B C F | ✓ |
