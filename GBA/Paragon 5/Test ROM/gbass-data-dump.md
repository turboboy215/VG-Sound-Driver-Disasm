# GBASS — data dump

*Content of `gbass.o` (the demo module) and of David Beckham Soccer (E) (M5). Formats and command
mnemonics are described in `gbass-technical-reference.md`; every script is listed in full, one command per line,
in `gbass.s`. Names come from the object's symbols (Beckham has none).*

# Part 1 — gbass.o demo module

Module: default rate 4 (256 samples/frame, 15 340 Hz), 1 song, 59 instruments, 50 waves, 4 digital channel pairs in 2 stereo mix buffers (`gbass_DigiBufferModes` = 01 01), Mix_Table copy mask 0x0F.

## Waves (50)

Rate 1.0 = the wave plays at the mixing rate at note C, octave 5. Lengths in samples (bytes); "loop" is the loop length ending at "end"; one-shot waves have loop 0.

| # | name | offset in .data | end | loop | release end | bytes |
|---|---|---|---|---|---|---|
| 0 | leadstrings_high | 0x00000 | 19946 | 12734 | 19947 | 19947 |
| 1 | leadstrings_med | 0x04DEB | 18425 | 13646 | 18425 | 18425 |
| 2 | marcato_high | 0x095E4 | 10552 | 0 | 10552 | 10552 |
| 3 | marcato_med | 0x0BF1C | 10552 | 0 | 10552 | 10552 |
| 4 | marcato_low | 0x0E854 | 12199 | 0 | 12199 | 12199 |
| 5 | padstrings_med | 0x117FB | 29500 | 24250 | 29500 | 29500 |
| 6 | padstrings_low | 0x18B37 | 26152 | 21166 | 26153 | 26153 |
| 7 | pizz_high | 0x1F160 | 5788 | 0 | 5788 | 5788 |
| 8 | pizz_medium | 0x207FC | 4792 | 0 | 4792 | 4792 |
| 9 | pizz_low | 0x21AB4 | 7658 | 0 | 7658 | 7658 |
| 10 | trumpet_high | 0x2389E | 4093 | 1056 | 4093 | 4093 |
| 11 | trumpet_low | 0x2489B | 7008 | 2228 | 7008 | 7008 |
| 12 | trombone | 0x263FB | 3641 | 1056 | 3641 | 3641 |
| 13 | tuba | 0x27234 | 6347 | 1193 | 6347 | 6347 |
| 14 | flute_high | 0x28AFF | 13114 | 5175 | 13114 | 13114 |
| 15 | flute_med | 0x2BE39 | 16760 | 8179 | 16760 | 16760 |
| 16 | oboe | 0x2FFB1 | 11532 | 2844 | 11532 | 11532 |
| 17 | clarinet | 0x32CBD | 8782 | 1290 | 8782 | 8782 |
| 18 | bassoon | 0x34F0B | 5566 | 2346 | 5566 | 5566 |
| 19 | accordion | 0x364C9 | 6138 | 3460 | 6138 | 6138 |
| 20 | bottleblow | 0x37CC3 | 5554 | 2961 | 5554 | 5554 |
| 21 | piano_5 | 0x39275 | 8253 | 4955 | 8253 | 8253 |
| 22 | piano_3 | 0x3B2B2 | 15880 | 4985 | 15880 | 15880 |
| 23 | rhodes | 0x3F0BA | 11641 | 2404 | 11641 | 11641 |
| 24 | harp | 0x41E33 | 4102 | 471 | 4102 | 4102 |
| 25 | guitar_high | 0x42E39 | 17981 | 4690 | 17981 | 17981 |
| 26 | guitar_med | 0x47476 | 17659 | 2227 | 17659 | 17659 |
| 27 | guitar_nylon | 0x4B971 | 9980 | 1818 | 9980 | 9980 |
| 28 | bass_acoustic | 0x4E06D | 7267 | 3050 | 7267 | 7267 |
| 29 | bass_finger | 0x4FCD0 | 8593 | 1173 | 8593 | 8593 |
| 30 | vibes | 0x51E61 | 3563 | 1583 | 3563 | 3563 |
| 31 | celesta | 0x52C4C | 9346 | 4752 | 9346 | 9346 |
| 32 | glock | 0x550CE | 3199 | 2455 | 3200 | 3200 |
| 33 | marimba | 0x55D4E | 4480 | 2345 | 4480 | 4480 |
| 34 | xylophone | 0x56ECE | 8704 | 0 | 8704 | 8704 |
| 35 | conga_high | 0x590CE | 3606 | 0 | 3606 | 3606 |
| 36 | conga_low | 0x59EE4 | 6890 | 0 | 6890 | 6890 |
| 37 | conga_slap | 0x5B9CE | 3128 | 0 | 3128 | 3128 |
| 38 | tom | 0x5C606 | 9920 | 0 | 9920 | 9920 |
| 39 | maracas | 0x5ECC6 | 2449 | 0 | 2449 | 2449 |
| 40 | shaker | 0x5F657 | 2272 | 0 | 2272 | 2272 |
| 41 | triangle_open | 0x5FF37 | 13713 | 0 | 13713 | 13713 |
| 42 | triangle_closed | 0x634C8 | 712 | 0 | 712 | 712 |
| 43 | timpani | 0x63790 | 22707 | 0 | 22707 | 22707 |
| 44 | click | 0x69043 | 3528 | 0 | 3528 | 3528 |
| 45 | cymbal_hit | 0x69E0B | 20992 | 0 | 20992 | 20992 |
| 46 | arpeggiator1 | 0x6F00B | 12289 | 0 | 12289 | 12289 |
| 47 | gb3_bass | 0x7200C | 32 | 0 | 32 | 32 |
| 48 | harpsilow | 0x7202C | 14568 | 978 | 14568 | 14568 |
| 49 | harpsihigh | 0x75914 | 15169 | 2202 | 15169 | 15169 |

Total PCM: 496725 bytes (8-bit signed).

## Instruments (59)

| # | name | type | script |
|---|---|---|---|
| 0 | leadstrings_med | digital | `wave 1; vol 255; volslide 0; wait 1; sustain 0$$$kwak; volslide -20; end` |
| 1 | leadstrings_high | digital | `wave 0; vol 255; volslide 0; wait 1; sustain 1$$$kwak; volslide -20; end` |
| 2 | marcato_low | digital | `wave 4; vol 255; volslide 0; end` |
| 3 | marcato_med | digital | `wave 3; vol 255; volslide 0; end` |
| 4 | marcato_high | digital | `wave 2; vol 255; volslide 0; end` |
| 5 | padstrings_low | digital | `wave 6; vol 64; volslide 10; wait 1; sustain 5$$$kwak; volslide -20; end` |
| 6 | padstrings_med | digital | `wave 5; vol 64; volslide 8; wait 1; sustain 6$$$kwak; volslide -20; end` |
| 7 | pizz_low | digital | `wave 9; vol 255; volslide 0; end` |
| 8 | pizz_med | digital | `wave 8; vol 255; volslide 0; end` |
| 9 | pizz_high | digital | `wave 7; vol 255; volslide 0; end` |
| 10 | trumpet_low | digital | `wave 11; vol 255; volslide 0; wait 1; sustain A$$$kwak; vol 96; volslide -10; end` |
| 11 | trumpet_high | digital | `wave 10; vol 255; volslide 0; wait 1; sustain B$$$kwak; vol 96; volslide -10; end` |
| 12 | trombone | digital | `wave 12; vol 255; volslide 0; wait 1; sustain C$$$kwak; vol 96; volslide -10; end` |
| 13 | harpsilow | digital | `wave 48; vol 255; volslide -4; end` |
| 14 | harpsihigh | digital | `wave 49; vol 144; volslide -2; end` |
| 15 | tuba | digital | `wave 13; vol 255; volslide 0; wait 1; sustain 11$$$kwak; vol 96; volslide -10; end` |
| 16 | flute_med | digital | `wave 15; vol 255; volslide 0; wait 1; sustain 15$$$kwak; vol 96; volslide -10; end` |
| 17 | flute_high | digital | `wave 14; vol 255; volslide 0; wait 1; sustain 16$$$kwak; vol 96; volslide -10; end` |
| 18 | oboe | digital | `wave 16; vol 255; volslide 0; wait 1; sustain 17$$$kwak; vol 96; volslide -10; end` |
| 19 | clarinet | digital | `wave 17; vol 255; volslide 0; wait 1; sustain 19$$$kwak; vol 96; volslide -10; end` |
| 20 | bassoon | digital | `wave 18; vol 255; volslide 0; wait 1; sustain 1B$$$kwak; vol 96; volslide -10; end` |
| 21 | accordion | digital | `wave 19; vol 255; volslide 0; wait 1; sustain 1D$$$kwak; vol 96; volslide -10; end` |
| 22 | bottle_blow | digital | `wave 20; vol 255; volslide 0; wait 1; sustain 1E$$$kwak; vol 96; volslide -10; end` |
| 23 | piano_mid | digital | `wave 22; vol 255; volslide -2; wait 1; sustain 22$$$kwak; vol 96; volslide -10; end` |
| 24 | piano_high | digital | `wave 21; vol 255; volslide -2; wait 1; sustain 24$$$kwak; vol 96; volslide -10; end` |
| 25 | rhodes | digital | `wave 23; vol 255; volslide -2; wait 1; sustain 26$$$kwak; vol 96; volslide -10; end` |
| 26 | harp | digital | `wave 24; vol 255; volslide -4; end` |
| 27 | guitar_med | digital | `wave 26; vol 255; volslide -2; wait 1; sustain 29$$$kwak; vol 96; volslide -10; end` |
| 28 | guitar_high | digital | `wave 25; vol 255; volslide -2; wait 1; sustain 2A$$$kwak; vol 96; volslide -10; end` |
| 29 | guitar_nylon | digital | `wave 27; vol 255; volslide -2; wait 1; sustain 2B$$$kwak; vol 96; volslide -10; end` |
| 30 | bass_acoustic | digital | `wave 28; vol 255; volslide -2; wait 1; sustain 2C$$$kwak; vol 96; volslide -10; end` |
| 31 | bass_finger | digital | `wave 29; vol 255; volslide -2; wait 1; sustain 2D$$$kwak; vol 96; volslide -10; end` |
| 32 | vibes | digital | `wave 30; vol 255; volslide -2; end` |
| 33 | celesta | digital | `wave 31; vol 255; volslide -3; end` |
| 34 | glock | digital | `wave 32; vol 255; volslide -3; end` |
| 35 | marimba | digital | `wave 33; vol 255; volslide -15; wait 14; volslide -2; end` |
| 36 | xylophone | digital | `wave 34; vol 255; volslide -10; end` |
| 37 | conga_high | digital | `wave 35; vol 255; volslide 0; end` |
| 38 | conga_low | digital | `wave 36; vol 255; volslide 0; end` |
| 39 | conga_slap | digital | `wave 37; vol 255; volslide 0; end` |
| 40 | tom | digital | `wave 38; vol 255; volslide 0; end` |
| 41 | maracas | digital | `wave 39; vol 255; volslide 0; end` |
| 42 | shaker | digital | `wave 40; vol 255; volslide 0; end` |
| 43 | triangle_open | digital | `wave 41; vol 255; volslide 0; end` |
| 44 | triangle_closed | digital | `wave 42; vol 255; volslide 0; end` |
| 45 | timpani | digital | `wave 43; vol 255; volslide 0; end` |
| 46 | click | digital | `wave 44; vol 255; volslide 0; end` |
| 47 | cymbal_hit | digital | `wave 45; vol 255; volslide 0; end` |
| 48 | arpeggiator1 | digital | `wave 46; vol 255; volslide -5; end` |
| 49 | gb_lead1 | GB 2 (pulse) | `pan_center; sweep 0x08; wave 0; vol 192; wait 2; wave 1; vol 144; wait 1; sustain 48$$$kwak; vol 49; wait 2; vol 67; wait 11; vol 54; end` |
| 50 | gb_lead2 | GB 2 (pulse) | `pan_center; sweep 0x08; wave 0; vol 192; wait 1; wave 0; vol 144; wait 2; wave 2; sustain 49$$$kwak; vol 49; wait 2; vol 67; wait 11; vol 54; end` |
| 51 | gb_arp1 | GB 2 (pulse) | `pan_center; sweep 0x08; wave 0; vol 129; wait 1; wave 1; end` |
| 52 | gb_arp2 | GB 2 (pulse) | `pan_center; sweep 0x08; wave 0; vol 129; wait 2; wave 2; end` |
| 53 | gb_arp3 | GB 2 (pulse) | `pan_center; sweep 0x08; wave 0; vol 130; end` |
| 54 | gb_kick | GB 2 (pulse) | `pan_center; wave 2; sweep 0x1b; vol 161; end` |
| 55 | gb_snare | GB 4 (noise) | `pan_center; wave 1; vol 241; octave 6; pitch G; trigger; wait 1; wave 0; octave 8; pitch B; trigger; end` |
| 56 | gb_hihat | GB 4 (noise) | `pan_center; wave 0; vol 113; octave 8; pitch B; trigger; end` |
| 57 | gb_hihat_open | GB 4 (noise) | `pan_center; wave 0; vol 87; octave 8; pitch B; trigger; end` |
| 58 | gb_bass | GB 3 (wave) | `wave 47; vol 255; wait 1; sustain 51$$$kwak; vol 255; wait 3; vol 128; wait 3; vol 32; wait 3; vol 0; end` |

## Songs (1)

Song 0 "Title": 12 tracks (table `gbass_Song$$0$ChannelTable`).

| track | channel | volume | intro ticks | loop ticks | patterns played |
|---|---|---|---|---|---|
| 0 | GB 1 | 256 | 360 | 5134 | 11 |
| 1 | GB 2 | 256 | 360 | 5134 | 11 |
| 2 | GB 3 | 256 | 360 | 5134 | 11 |
| 3 | GB 4 | 256 | 360 | 5134 | 11 |
| 4 | digital 0 | 256 | 360 | 5134 | 11 |
| 5 | digital 1 | 256 | 360 | 5134 | 11 |
| 6 | digital 2 | 256 | 360 | 5134 | 11 |
| 7 | digital 3 | 256 | 360 | 5134 | 11 |
| 8 | digital 4 | 256 | 360 | 5134 | 11 |
| 9 | digital 5 | 256 | 360 | 5134 | 11 |
| 10 | digital 6 | 256 | 360 | 5134 | 11 |
| 11 | digital 7 | 256 | 360 | 5134 | 11 |

gbasscontent.h gives SONG_Title_INTROTIME 360 and LOOPTIME 5134, which match the tick counts above (ticks = frames at speed 1.0).

## Command usage

Songs (tracks + patterns): wait 1463, note 1109, octave 374, play 132, end 132, chvol 118, release 51, slide_to 14, jump 12, vibrato 8, fx_off 8.

Instruments: vol 90, volslide 73, wave 65, end 59, wait 39, sustain 26, pan_center 9, sweep 6, octave 4, pitch 4, trigger 4.


# Part 2 — David Beckham Soccer

Module descriptor at `0820FCB0`: rate 4, 7 songs (`0820792C`), 65 instruments (`082073B0`, types `082074B4`), 52 waves (`08206ED0`), 2 channel pairs, 1 stereo buffer (`0820FCAC` = 01), RAM: music mixers `0300334C`, sfx mixers `030033CC`, digital channels `02004724`, mix buffer `0300330C`, GB channels `020047C4`, DMA buffers `03002D0C`, silence `03002D08`, ARM code `0300310C`.

## Songs

| # | name | tracks | track 0 length (ticks) | ends with |
|---|---|---|---|---|
| 0 | FrontEnd | 8 (PSG 1-4, digital 0-3; volume 256) | 3456 | loop (jump) |
| 1 | PreMatch | 8 (PSG 1-4, digital 0-3; volume 256) | 1728 | loop (jump) |
| 2 | SeasonEnd | 8 (PSG 1-4, digital 0-3; volume 256) | 3584 | loop (jump) |
| 3 | LeagueWin | 8 (PSG 1-4, digital 0-3; volume 256) | 1536 | loop (jump) |
| 4 | LeagueLose | 8 (PSG 1-4, digital 0-3; volume 256) | 1280 | loop (jump) |
| 5 | MatchWin | 8 (PSG 1-4, digital 0-3; volume 256) | 512 | loop (jump) |
| 6 | MatchLose | 8 (PSG 1-4, digital 0-3; volume 256) | 316 | loop (jump) |

## Waves

All rates 1.0. Lengths in samples.

| # | address | end | loop length | release end |
|---|---|---|---|---|
| 0 | 081B4464 | 6674 | 0 | 6674 |
| 1 | 081B5E76 | 5444 | 0 | 5444 |
| 2 | 081B73BA | 5558 | 0 | 5558 |
| 3 | 081B8970 | 2037 | 0 | 2037 |
| 4 | 081B9165 | 4058 | 0 | 4058 |
| 5 | 081BA13F | 2576 | 0 | 2576 |
| 6 | 081BAB4F | 1343 | 0 | 1343 |
| 7 | 081BB08E | 848 | 0 | 848 |
| 8 | 081BB3DE | 1247 | 0 | 1247 |
| 9 | 081BB8BD | 3824 | 0 | 3824 |
| 10 | 081BC7AD | 10864 | 0 | 10864 |
| 11 | 081BF21D | 2448 | 0 | 2448 |
| 12 | 081BFBAD | 13841 | 0 | 13841 |
| 13 | 081C31BE | 5701 | 701 | 5701 |
| 14 | 081C4803 | 20536 | 9617 | 20536 |
| 15 | 081C983B | 12445 | 5158 | 12445 |
| 16 | 081CC8D8 | 10292 | 7193 | 10292 |
| 17 | 081CF10C | 11715 | 5037 | 11715 |
| 18 | 081D1ECF | 8824 | 4836 | 8824 |
| 19 | 081D4147 | 305 | 59 | 305 |
| 20 | 081D4278 | 10573 | 6521 | 10573 |
| 21 | 081D6BC5 | 8954 | 6321 | 8954 |
| 22 | 081D8EBF | 3473 | 352 | 3473 |
| 23 | 081D9C50 | 6878 | 295 | 6878 |
| 24 | 081DB72E | 7692 | 0 | 7692 |
| 25 | 081DD53A | 2319 | 0 | 2319 |
| 26 | 081DDE49 | 2392 | 0 | 2392 |
| 27 | 081DE7A1 | 2371 | 0 | 2371 |
| 28 | 081DF0E4 | 2370 | 0 | 2370 |
| 29 | 081DFA26 | 2339 | 0 | 2339 |
| 30 | 081E0349 | 2380 | 0 | 2380 |
| 31 | 081E0C95 | 2375 | 0 | 2375 |
| 32 | 081E15DC | 2390 | 0 | 2390 |
| 33 | 081E1F32 | 2377 | 0 | 2377 |
| 34 | 081E287B | 2395 | 0 | 2395 |
| 35 | 081E31D6 | 2353 | 0 | 2353 |
| 36 | 081E3B07 | 2377 | 0 | 2377 |
| 37 | 081E4450 | 2366 | 0 | 2366 |
| 38 | 081E4D8E | 2357 | 0 | 2357 |
| 39 | 081E56C3 | 2361 | 0 | 2361 |
| 40 | 081E5FFC | 2353 | 0 | 2353 |
| 41 | 081E692D | 2355 | 0 | 2355 |
| 42 | 081E7260 | 2354 | 0 | 2354 |
| 43 | 081E7B92 | 32 | 32 | 32 |
| 44 | 081E7BB2 | 2552 | 0 | 2552 |
| 45 | 081E85AA | 1729 | 0 | 1729 |
| 46 | 081E8C6B | 6990 | 0 | 6990 |
| 47 | 081EA7B9 | 2671 | 0 | 2671 |
| 48 | 081EB228 | 45498 | 0 | 45498 |
| 49 | 081F63E2 | 45678 | 0 | 45678 |
| 50 | 08201650 | 3243 | 0 | 3243 |
| 51 | 082022FB | 19412 | 0 | 19412 |

## Instruments

Sound effect n (game API at `08015378`) = instrument n + 52.

| # | address | type | script |
|---|---|---|---|
| 0 | 082074F5 | digital | `wave 0; vol 255; end` |
| 1 | 082074FA | digital | `wave 1; vol 255; end` |
| 2 | 082074FF | digital | `wave 2; vol 255; end` |
| 3 | 08207504 | digital | `wave 3; end` |
| 4 | 08207507 | digital | `wave 4; end` |
| 5 | 0820750A | digital | `wave 5; end` |
| 6 | 0820750D | digital | `wave 6; end` |
| 7 | 08207510 | digital | `wave 7; end` |
| 8 | 08207513 | digital | `wave 8; end` |
| 9 | 08207516 | digital | `wave 9; end` |
| 10 | 08207519 | digital | `wave 10; end` |
| 11 | 0820751C | digital | `wave 11; end` |
| 12 | 0820751F | digital | `wave 12; end` |
| 13 | 08207522 | digital | `wave 13; end` |
| 14 | 08207525 | digital | `wave 14; end` |
| 15 | 08207529 | digital | `wave 15; end` |
| 16 | 0820752D | digital | `wave 16; end` |
| 17 | 08207531 | digital | `wave 17; end` |
| 18 | 08207535 | digital | `wave 18; end` |
| 19 | 08207539 | digital | `wave 19; end` |
| 20 | 0820753D | digital | `wave 20; end` |
| 21 | 08207541 | digital | `wave 21; end` |
| 22 | 08207545 | digital | `wave 22; end` |
| 23 | 08207549 | digital | `wave 23; end` |
| 24 | 0820754D | digital | `wave 24; end` |
| 25 | 08207551 | digital | `wave 25; end` |
| 26 | 08207555 | digital | `wave 26; end` |
| 27 | 08207559 | digital | `wave 27; end` |
| 28 | 0820755D | digital | `wave 28; end` |
| 29 | 08207561 | digital | `wave 29; end` |
| 30 | 08207565 | digital | `wave 30; end` |
| 31 | 08207569 | digital | `wave 31; end` |
| 32 | 0820756D | digital | `wave 32; end` |
| 33 | 08207571 | digital | `wave 33; end` |
| 34 | 08207575 | digital | `wave 34; end` |
| 35 | 08207579 | digital | `wave 35; end` |
| 36 | 0820757D | digital | `wave 36; end` |
| 37 | 08207581 | digital | `wave 37; end` |
| 38 | 08207585 | digital | `wave 38; end` |
| 39 | 08207589 | digital | `wave 39; end` |
| 40 | 0820758D | digital | `wave 40; end` |
| 41 | 08207591 | digital | `wave 41; end` |
| 42 | 08207595 | digital | `wave 42; end` |
| 43 | 08207599 | PSG 1 | `volslide_off; vol 241; wave 0; wait 3; wave 1; end` |
| 44 | 082075A1 | PSG 2 | `wave 0; vol 240; end` |
| 45 | 082075A6 | PSG 2 | `vol 131; wave 0; end` |
| 46 | 082075AB | PSG 2 | `volslide_off; wave 3; vol 163; trigger; end` |
| 47 | 082075B2 | digital | `vol 241; end` |
| 48 | 082075B6 | PSG 3 (wave) | `wave 43; vol 255; wait 8; vol 128; wait 10; vol 32; wait 3; stop_inst_keyoff; end` |
| 49 | 082075C4 | digital | `vol 245; trigger; end` |
| 50 | 082075C9 | PSG 3 (wave) | `wave 43; vol 255; wait 86; stop_inst_keyoff; end` |
| 51 | 082075D2 | digital | `volslide_off; vol 240; end` |
| 52 (sfx 0) | 082075D7 | digital | `volslide_off; wave 44; vol 255; octave 5; pitch C; trigger; end` |
| 53 (sfx 1) | 082075E1 | digital | `volslide_off; wave 45; vol 255; octave 5; pitch C; trigger; end` |
| 54 (sfx 2) | 082075EB | digital | `volslide_off; wave 46; vol 255; octave 5; pitch C; trigger; end` |
| 55 (sfx 3) | 082075F5 | digital | `volslide_off; wave 47; vol 255; octave 5; pitch C; trigger; end` |
| 56 (sfx 4) | 082075FF | digital | `volslide_off; wave 48; vol 255; octave 5; pitch C; trigger; end` |
| 57 (sfx 5) | 08207609 | digital | `volslide_off; wave 49; vol 255; octave 5; pitch C; trigger; end` |
| 58 (sfx 6) | 08207613 | digital | `volslide_off; wave 50; vol 255; octave 5; pitch C; trigger; end` |
| 59 (sfx 7) | 0820761D | digital | `volslide_off; wave 51; vol 255; octave 5; pitch C; trigger; end` |
| 60 (sfx 8) | 08207627 | PSG 1 | `sweep 0x08; pan_center; wave 1; vol 145; octave 3; pitch F; trigger; wait 1; octave 7; pitch G; trigger; wait 1; octave 7; pitch F; trigger; wait 1; octave 7...` |
| 61 (sfx 9) | 082076F3 | PSG 1 | `sweep 0x08; wave 1; pan_center; wave 1; vol 145; octave 7; pitch F; trigger; wait 1; octave 7; pitch G; trigger; wait 1; octave 7; pitch F; trigger; wait 1; ...` |
| 62 (sfx 10) | 08207774 | PSG 1 | `sweep 0x08; wave 1; pan_center; vol 145; octave 7; pitch F; trigger; wait 1; octave 7; pitch G; trigger; wait 1; octave 7; pitch F; trigger; wait 1; octave 7...` |
| 63 (sfx 11) | 082077BE | PSG 1 | `pan_center; sweep 0x08; wave 1; vol 145; octave 7; pitch F; trigger; wait 2; octave 7; pitch G; trigger; wait 1; octave 7; pitch F; trigger; wait 1; vol 65; ...` |
| 64 (sfx 12) | 082078B7 | PSG 1 | `sweep 0x08; wave 1; vol 145; octave 7; pitch F; trigger; wait 2; octave 7; pitch G; trigger; wait 1; octave 7; pitch F; trigger; wait 1; vol 65; octave 7; pi...` |
