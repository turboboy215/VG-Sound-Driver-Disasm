# Krawall (Sebastian Kienzl)
## Format verification, per-game differences and UnkrawerterGBA analysis

**Subject files** (`…/GBAAudioLab/Kraw/`)

| Game (ROM) | Krawall? | ID string in ROM | Pattern format | Module type |
|---|---|---|---|---|
| *The Sims: Bustin' Out* (U) (M6) | yes | `$Id: player.c,v 1.4 2003/03/19 23:12:15 seb Exp $` @ `0x0D6F4E4` | old | S3M (sample-based) |
| *LEGO Star Wars: The Video Game* (U) (M7) | yes | `$Id: player.c,v 1.4 2003/03/19 23:12:15 seb Exp $` @ `0x0071AD8` | old | S3M |
| *Franklin the Turtle* (E) (M8) | yes | `$Id: Krawall $Date: 2003/09/01 06:51:01 $` @ `0x03DF180` | old | S3M |
| *LEGO Star Wars II: The Original Trilogy* (E) (M6) | yes | `$Id: Krawall $Id: version.h 8 2005-04-21 12:24:45Z seb $` @ `0x0FCF620` | new | S3M |
| *Big Mutha Truckers* (E) (M5) | **yes, modified integration** | none; credit "Sound Engine: Synk, Kienzl & Prohaszka OEG" @ `0x004317C` | new | **XM** (instrument-based, linear slides), **packed** |
| *Princess Natasha: Student, Secret Agent, Princess* (E) (M5) | **yes, BMT-style packed** | none | new | **XM**, **packed** |
| *Puppy Luv: Spa and Resort* (U) | yes | none | new | XM (plain) |
| *Agent Hugo: RoboRumble* (E) (M11) | yes | `$Id: player.c,v 1.4 2003/03/19 23:12:15 seb Exp $` @ `0x01982DC` | old | XM (plain) |
| *Barbie: Groovy Games* (E) (M5) | **no** | none | — | — |

**Sources used.** The official source (`krawall-master.zip`: `lib/` player, `krawerter/` converter,
`docs/` handbook and musician's guide), the TCRF article *Format:Krawall* (saved HTML), and the
UnkrawerterGBA 4.0 source. Everything about the ROMs was checked directly: an independent scanner
(`kscan.py`) located the data without Unkrawerter's heuristics, and every pattern of every module
was decoded end to end (`kverify.py`). BMT's packed modules were unpacked by running the game's
own decompressor in an ARM emulator (`bmt_unpack.py`).

---

## 1. Summary

* **The TCRF page is mostly right but has several real errors**, two of which matter for a
  converter: samples are **unsigned** 8-bit (not signed), and the pre-2004-07-07 note/instrument
  packing is described **backwards**. Full list in §3.
* **The Sims and LEGO Star Wars 1 are not stripped.** They carry an older CVS-style ID from
  `player.c` (revision 1.4, 2003-03-19) instead of the later `$Id: Krawall …` string. It sits in
  the same place in the Krawall object as the newer strings do in Franklin/LSW2. 2003-03-19 is
  **older than the earliest "known version" on TCRF** (2003-09-01).
* **Big Mutha Truckers uses Krawall**, but the developer integrated it differently: samples store a
  length instead of an end pointer, modules are compressed with a custom LZ and bundle their own
  instruments, and the `Module` struct has an extra field. No existing tool finds its music.
  All 14 modules are now unpacked and validated (§5).
* **Princess Natasha uses the same packed layout as BMT** (the same loader source and a
  byte-identical decompressor): 11 XM-type modules, unpacked and validated (§5.5).
* **Puppy Luv and Agent Hugo use plain, unpacked XM-type Krawall.** Puppy Luv is a new-format
  build with no ID string; Agent Hugo is the 2003-03-19 build, so XM-type modules already existed
  in the old format. Unkrawerter handles Puppy Luv, but **fails on Agent Hugo** because Hugo's
  first sample has `c2Freq` = 105 439, above its 0xFFFF limit (§7.5).
* **Barbie: Groovy Games does not use Krawall** (§6).
* **Unkrawerter's missing songs** are caused by its default search threshold (`-t 4`), which
  ignores any module with fewer than four patterns. That drops 11 jingles in Franklin, 7 modules
  in LSW1, 7 in LSW2 and 10 in The Sims. With `-t 1` it finds all of them, except that The Sims
  then needs `-k` as well (§7).
* **Franklin's console messages** are warnings, not errors: its modules use ModPlug's S3M
  volume-column panning, which Unkrawerter can only write as an OpenMPT extension (§7.3).
* **XM vs S3M.** Krawall is a dual-mode player; each module keeps the semantics of the format it
  was made from. All modules in Sims, LSW1, LSW2 and Franklin are S3M-derived, so S3M is the
  faithful target for them. That is a real reason, not just a skill issue, but it is per module,
  not engine-wide: BMT's modules are XM-derived and need XM (§8).

---

## 2. Identification and versions

### 2.1 ID strings

| Form | Seen in | Notes |
|---|---|---|
| `$Id: player.c,v 1.4 2003/03/19 23:12:15 seb Exp $` | Sims (U), LSW1 (U) | CVS keyword of `player.c`. Not mentioned on TCRF. |
| `$Id: Krawall $Date: 2003/09/01 06:51:01 $` | Franklin | CVS `$Date$` |
| `$Id: Krawall $Id: version.h 8 2005-04-21 12:24:45Z seb $` | LSW2 | SVN `$Id$` of `version.h` |
| `$Id: player.c,v 1.4 2003/03/19 23:12:15 seb Exp $` | Agent Hugo (E) | same build as Sims/LSW1 |
| none | BMT, Princess Natasha, Puppy Luv | the `.rodata` block is there, without a string |
| `$Krawall v1.0.0` | public 2013 source (`general.c`) | not in any retail ROM tested |

The ID always sits in the Krawall `.rodata` block, next to a table of IWRAM function pointers
(`0x0300xxxx`) and about 0x330 bytes before `table_sine`.

### 2.2 Version-independent fingerprint

Krawall's constant tables (`player_tables.c`) are present in all five Krawall ROMs, including
BMT, at the same relative spacing:

| Table | First values (s16/u16 LE) | Offset from `table_sine` |
|---|---|---|
| `table_sine` | `0, 25, 50, 74, 98, 120, 142, 162` | 0 |
| `table_rand` | `-28, 185, 162, -32, -161, 170, -222, -186` | +0x180 |
| `table_finetune` | `34716, 34654, 34591, 34529, …` | +0x2F0 |

Searching for the 16-byte `table_sine` prefix is a reliable detector that does not depend on the
ID string. All eight Krawall ROMs have them; Barbie has none of these tables.

### 2.3 Pattern-format split

The handbook's change log confirms the TCRF date: *"Until version 20040707, Krawall had a limit
of 512 samples that could be used in pattern-data. Now the limit is 64K."* The ROMs agree: the
2003 builds use the old encoding and the 2005 build and BMT use the new one. The exact switch
date can't be narrowed further from these five ROMs.

---

## 3. Checking the TCRF article claim by claim

✅ correct · ⚠️ incomplete or misleading · ❌ wrong

### 3.1 Signature section

| Claim | Verdict | Notes |
|---|---|---|
| Sims: Bustin' Out (U) has the signature stripped | ❌ | It has the older `$Id: player.c,v 1.4 …` form (§2.1). The Japanese ROM wasn't tested. |
| Signature is a surefire detector; absent means heuristics | ⚠️ | True for presence, but tools that search only for `$Id: Krawall` miss the 2003-03-19 builds. `table_sine` is a better detector. |
| Known versions list starts at 2003-09-01 | ⚠️ | 2003-03-19 (`player.c` 1.4) is also in retail ROMs. |
| Format change at 2004-07-07 | ✅ | Confirmed by the handbook. |

### 3.2 Samples

| Claim | Verdict | Correct statement |
|---|---|---|
| 18-byte header, field layout | ✅ | matches `mtypes.h` |
| "Samples are stored as **signed** 8-bit PCM" | ❌ | **Unsigned**, centred on `0x80`. krawerter adds 128 to XM (signed) and signed-S3M data; the mixer uses `ldrb` plus a bias-compensation pass (`mixBias`). In all 1 108 samples across the four plain games, unlooped samples are padded with `0x80` and the mean byte value is 127.5–128.0. (Unkrawerter's README also says unsigned.) |
| `end` points to the end of the data; `size = end − data` | ⚠️ | True, but **69 extra bytes** (`17×4+1`) follow `end`: `0x80` for one-shots, a copy of the loop start for looped samples (the mixer reads ahead). In BMT and Princess Natasha this field is a **length**, not a pointer (§5). |
| `loop` is a boolean | ⚠️ | 0 = off, 1 = forward, **2 = ping-pong** (`LOOP_BIDIR` in the mixer). Agent Hugo has one ping-pong sample (sample 32). In Agent Hugo, 25 one-shot samples (`loop = 0`) still carry a non-zero `loopLength`: trust `loop`, not `loopLength`. |
| loop region is `[size − loopLength, size)` | ✅ | krawerter cuts everything after the loop end and repeats short loops until they are **≥ 512 bytes** (checked: every looped sample in the four games). |
| `hq` = interpolation | ✅ | Set by krawerter when the sample's name (XM) or filename (S3M) starts with `~`. Used only in `KRAM_QM_MARKED` mode. Every sample in these games has `hq = 0`. |
| `c2freq` for S3M, `fineTune`/`relativeNote` for XM | ⚠️ | krawerter fills all three for every sample, and the player derives pitch from `fineTune`/`relativeNote`. Most S3M-derived samples here have non-zero `fineTune`/`relNote`. For XM sources `c2Freq` is computed from them and is a full u32: values above 65 535 occur (Agent Hugo 14, Puppy Luv 6; maximum 105 439). |
| `panDefault` | ⚠️ | XM panning is stored as `(pan − 128) / 2` (−64…+63). It is 0 in every sample here. |

### 3.3 Instruments and envelopes

| Claim | Verdict | Correct statement |
|---|---|---|
| Instrument is exactly 302 bytes | ✅ | In ROM each is `.align`ed, so the stride is **304** (BMT: `0x130`). |
| `samples[96]`: "Index 0 = C0, 1 = D0, …, 95 = A#7" | ❌ | Semitone steps: **0 = C-0, 1 = C#0, …, 95 = B-7** (the player reads `samples[note − 1]` with `note` = 1…96). Entries 94/95 can hold junk in real data (BMT has `0x0804` at index 94). |
| Envelope `coord`: X = low 9 bits, Y = high 7 bits | ✅ | |
| `inc` is an unsigned slope | ⚠️ | **Signed** 8.8 slope `((y₂−y₁) << 8) / (x₂−x₁)`. |
| `max` = index of last node | ✅ | `0xFF` when the envelope has no nodes. |
| `flags`: 2 = sustain, 4 = loop | ⚠️ | **Bit 0 = envelope enabled** is missing (XM flags passed through; BMT uses `flags = 1`). |

### 3.4 Modules

| Claim | Verdict | Notes |
|---|---|---|
| Field layout up to `0x16B` | ✅ | |
| Order value 254 calls a user callback | ⚠️ | 254 is ST3's `+++`: it **partitions the order list into songs**. In song mode playback stops or loops at the next `+++`, and `KRAP_CB_SONG` fires. `songIndex[]` holds each song's first order (`songIndex[0] = 0`). The Sims uses this in 8 modules (up to 6 songs in one module). 255 never appears: krawerter truncates the list at `---`. |
| `flagVolSlides` = ST3.00 volume slides | ✅ | krawerter calls it `flagFastVolSlides`; set when S3M flag 64 is set or `Cwt/v == 0x1300`. |
| `flagVolOpt`, `flagAmigaLimits` | ⚠️ | **Always written as 0** by krawerter and never read by the player. All 120 modules (including BMT's) have 0. |
| `patterns[]` length = highest order index + 1 | ✅ | krawerter deletes unreferenced patterns and renumbers, so this equals the pattern count. |
| Modules have no central list | ✅ | Code references them directly. |
| *(not on TCRF)* `songRestart` | — | Always 0 for S3M sources. |
| *(not on TCRF)* XM-type modules in the old format | — | Agent Hugo (2003-03-19 build) has instrument-based modules with 128-row patterns, so XM support predates the 2004 format change. |

### 3.5 Patterns

| Claim | Verdict | Correct statement |
|---|---|---|
| `index[16]` = byte offset of every 4th row | ✅ | Verified on all 1 126 patterns. (The public player's seek code skips a fixed 2 bytes for note/instrument and would mis-seek past a 3-byte entry; harmless unless a pattern uses instrument > 255.) |
| `rows`: u8 before 2004-07-07, u16 after | ✅ | |
| New format: note byte, instrument low byte, high byte if note bit 7 set | ✅ | |
| **Old format: "the high 9 bits are the instrument, and the low 7 bits are the note"** | ❌ | **Reversed.** It is a **big-endian** u16 = `note << 9 \| instrument`: byte 0 = `note << 1 \| ins >> 8`, byte 1 = `ins & 0xFF`. The commented-out code in krawerter's `Pattern::compress` writes exactly this. Decoding with the TCRF layout gives instrument numbers up to 510 (games have ≤ 467 samples) and errors in 573 of 626 patterns; the correct layout decodes all 626 cleanly. Unkrawerter's code does it correctly. |
| Follow byte bits 0x20/0x40/0x80, channel = low 5 bits, 0 = end of row | ✅ | |
| *(not on TCRF)* note values | — | 1 = C-0 … 96 = B-7; **127 = note-off** (S3M `^^` and XM 97 are both converted to 127). Notes are 1-based. |
| *(not on TCRF)* instrument values | — | 0 = none; otherwise 1-based. For sample-based (S3M) modules it is a **global sample-list index + 1**. |
| Volume column is XM-style, 0x10–0x50 | ⚠️ | Also 0x60–0xFF = XM volume-column effects, **for S3M-derived modules too**. ModPlug's S3M volume-column panning becomes `0xC0 + pan×15/64` (Franklin uses this, §7.3). |

### 3.6 Effects table

The IDs and most mappings are right. Corrections (the player's `effects[]` table and krawerter's
`ModS3M.cpp`/`ModXM.cpp` are authoritative):

| ID | TCRF says | Actually |
|---|---|---|
| 8 | Fine volume slide (EBx / DFx) | **Fine slide down**, XM `EBx` only |
| 9 | Extra fine volume slide (EAx / DxF) | **Fine slide up**, XM `EAx` only. There are no "extra fine" volume slides. |
| 12, 13, 16, 17 | S3M `EFx`/`EEx`/`FFx`/`FEx` | XM only. **S3M fine and extra-fine slides are not split out**: `Dxy`, `Exx` and `Fxx` stay as IDs 6, 11 and 15, and those handlers decode the `F`/`E` nibbles themselves. |
| 10 / 14 | porta down / up (XM) | **Swapped when `flagLinearSlides = 0`**: krawerter exchanges up/down (and the fine variants) for Amiga-slide XMs. A ripper has to swap them back. |
| 23 / 24 | XM `6xy` / `5xy` | Correct, and in this krawerter they use the **S3M volume-slide handler**. 49/50 (XM variants) have handlers but krawerter never writes them. |
| 34 | Pan | Parameter is **0–128**: XM `8xx` × 128/255, S3M `S8x` × 128/15 (converted from 42), `Xxx` as-is |
| 36 | Mark | S3M/XM `Zxx` → `KRAP_CB_MARK`. The Sims uses it 354 times. |
| 41, 42 | Fine pattern delay; old pan | **Never written** (41 is dropped, 42 becomes 34) |
| 46, 47, 48 | Pattern delay; envelope position; offset high | Written by krawerter, but **no-ops in the public player** (null handlers). |
| *(XM)* `Ixx`/`Jxx` | — | Krawall's own XM channel volume / slide (handbook §5.2) |

Effects used in the games are listed per module in the data dump.

---

## 4. Per-game format differences

| | Sims, LSW1 | Agent Hugo | Franklin | LSW2 | Puppy Luv | BMT | Princess Natasha |
|---|---|---|---|---|---|---|---|
| Build | `player.c` 1.4, 2003-03-19 | `player.c` 1.4, 2003-03-19 | 2003-09-01 | 2005-04-21 | unknown, ≥ 2004-07-07 | unknown, ≥ 2004-07-07 | unknown, ≥ 2004-07-07 |
| Pattern encoding | old (u8 rows, BE `note<<9\|ins`) | old | old | new | new | new | new |
| `Sample+4` | end pointer | end pointer | end pointer | end pointer | end pointer | **length** | **length** |
| Sample list | ROM, `const` | ROM | ROM | ROM | ROM | ROM list **copied to EWRAM** at init | same as BMT |
| Module storage | plain, in ROM | plain | plain | plain | plain | **custom-LZ blobs**, unpacked to EWRAM | same as BMT |
| `Module+0x16C` | `patterns[0]` | same | same | same | same | **instrument-table pointer**; `patterns[]` at `+0x170` | same as BMT |
| Instruments | none | global list (95) | none | none | global list (78) | per module, inside the blob | per module |
| Module type | all S3M (inst = 0, linear = 0) | all XM (inst = 1, linear = 1) | all S3M | all S3M | XM, plus one 1-channel S3M module | all XM | all XM |
| Rows per pattern | 64 | 128 | 64 | 64 | 128 (64 in module 0) | 6–240 | 64 |
| Channels | 2–15 (Sims), 16 (LSW1) | 10–17 | 4 | 16 | 1, 14–29 | 5–8 | 6 |
| Modules / samples | 47 / 467; 18 / 225 | 5 / 132 | 15 / 114 | 26 / 302 | 7 / 135 | 14 / 90 | 11 / 152 |

Sample, envelope and module layouts are otherwise identical across all builds; nothing else
needed version-specific handling to decode all 931 patterns in the four plain games.

---

## 5. Big Mutha Truckers in detail

### 5.1 Evidence

1. Credits: *"Sound Engine — Synk, Kienzl & Prohaszka OEG"* (`0x004317C`).
2. Krawall's `table_sine`/`table_rand`/`table_finetune` at `0x00556F4`/`0x0055874`/`0x00559E4`,
   plus the waveform pointer table at `0x0275E8C` (`sine, ramp, square, rand`).
3. 90 sample headers in Krawall's 18-byte layout with exactly the 69-byte padding krawerter writes.
4. 14 modules that, once unpacked, are standard Krawall modules (new pattern encoding) and
   decode with zero errors.

### 5.2 Sample bank

```
0x00BB0C0  u16 count (90), 14 bytes 0
0x00BB0D0  Sample[0] ... 4-byte aligned, each followed by the 69-byte pad
0x0177080  u32 ptr[90]          -> ROM sample headers
```

Header = Krawall `Sample`, except `+4` is **`u32 length`** (data bytes, excluding the pad).
krawerter's `Sample.cpp` still has the commented-out line that wrote the length there
(`//<< ( int )s.length << endl;`), so this is probably an older converter output.

At init (`0x080322C8`) the game allocates `count × 4` bytes, stores the pointer in `0x02001CE4`
and copies the ROM pointer list into it. Krawall's `samples[]` therefore lives in EWRAM. A module
blob can also list sample indices to copy into EWRAM (`length + 0x46` bytes each) and repoint;
all 14 BMT blobs list none.

### 5.3 Packed module blob

`PlayMusic(blob, mode)` at `0x0802BF0C` calls the unpacker `0x08032150`, then `krapPlay`
(`0x08033380`).

```
u8   nSamples                     0 in all 14 blobs
u8   sampleIndex[nSamples]        samples to copy into EWRAM
     pad to 4
u24  unpackedSize
...  packed stream                passed to 0x08025560 -> IWRAM 0x030026D0 (ROM 0x03EC8F8, ARM)
```

The decompressor is a custom bit-oriented LZ whose parameters (bit widths, a literal table) are
read from the stream header. The IWRAM image is copied from ROM `0x3EA228` to `0x03000000` at boot.

**Unpacked layout** (positions relative to the end):

```
[patterns ...]                    each pattern at an offset from the start (first at 0)
Module      0x170 bytes           standard fields 0x000-0x16B
            +0x16C u32            set at load: pointer to this module's instrument array
            +0x170 u32 patOfs[n]  offsets, relocated to pointers at load
Instrument  ninst x 0x130         standard 302-byte struct + 2 pad
u8 ninst, u8 npat                 the last two bytes
```

Module start = `size − (npat × 4 + 0x172) − ninst × 0x130`.

### 5.4 Extracting it

`bmt_unpack.py` runs the game's ARM decompressor under Unicorn and writes `bmt_<blob>.bin`
plus a JSON summary. `packed_unpack.py` does the same for any game with this layout: it finds
blobs by their stream signature and validates each unpacked module. It finds all 14 in BMT and all
11 in Princess Natasha. For GBA2MID you could port the decompressor (about 0x330 bytes of ARM) or
emulate it the same way. After unpacking, the data is plain new-format Krawall with XM semantics.

**Finding packed blobs.** Every compressed stream in both games begins with the decompressor
parameters `01 01 08 80`, right after a 4-aligned `u24 unpackedSize`. The blob itself starts
with `u8 nSamples` + indices, padded to 4 bytes; with `nSamples = 0` that is the 4 bytes
`00 00 00 00` before the size.

### 5.5 Princess Natasha

Same scheme, from the same source code with a different build:

| | BMT | Princess Natasha |
|---|---|---|
| Sample bank header (`u16 count`) | `0x00BB0C0` (90) | `0x0379D00` (152) |
| Sample pointer list | `0x0177080` | `0x03EDB90` |
| Unpacker (C) | `0x08032150` | `0x0801CFCC` (wrapper `0x0801D1B0`) |
| Decompressor stub → IWRAM entry | `0x08025560` → `0x030026D0` | `0x080242A0` → `0x03001F80` |
| IWRAM image in ROM | `0x03EA228` | `0x03F7C84` |
| Decompressor in ROM | `0x03EC8F8` | `0x03F9C04` (byte-identical) |
| Packed modules | 14 (`0x01771F0`–`0x017CA10`) | 11 (`0x03EDE00`–`0x03F19A0`) |
| Pattern rows | 6–240 | 64 |

The unpacker's logic is instruction-for-instruction the same as BMT's (sample copy, u24 size,
decompress, module located from the 2-byte trailer, `+0x16C` instrument pointer, `+0x170`
pattern relocation). Every blob is referenced from game code, and all 84 patterns decode cleanly.

---

## 6. Barbie: Groovy Games

**Not Krawall.**

* None of Krawall's tables, no ID string, no Krawall credit. Sound and music are credited to
  David Kerr and Clandro Cautillo at Digital Illusions Canada.
* The sound setup (code around `0x080248CA`) writes `SOUNDCNT_H = 0xBB0E` (both FIFOs to both speakers,
  PSG at 100 %) and touches the PSG registers. Krawall's `dsInit` writes `0x9A0C` (FIFO A → left,
  B → right) or `0x0B0C` for mono, and never uses the PSG.
* No MP2K `Smsh` ident or `SelectSong` signature, and no MOD/S3M/XM/IT headers.

This fits a DICE in-house driver. Identifying it further was out of scope.

---

## 7. UnkrawerterGBA 4.0: why songs go missing, and the Franklin messages

Built from the included source and run on each ROM.

| ROM | Modules | Default (`-t 4`) | `-t 2` | `-t 1` | Working command |
|---|---|---|---|---|---|
| Franklin | 15 | 4 | 4 | **15** | `-t 1` |
| LSW1 | 18 | 11 | 18 | **18** | `-t 1` (or `-t 2`) |
| LSW2 | 26 | 19 | 25 | **26** | `-t 1` |
| Sims | 47 | 37 | 37 | **crash / multi-GB garbage** | **`-k -t 1`** → 47 |
| BMT | 14 | 0 | 0 | 0 | not supported |
| Princess Natasha | 11 | 0 | — | 0 | not supported (packed) |
| Puppy Luv | 7 | 6 | — | **7** | `-t 1` |
| Agent Hugo | 5 | **fails** | — | **fails** | **`-s 2938072 -k`** → 5 |

### 7.1 Threshold

The search looks for runs of ROM pointers and, by default, ignores runs shorter than 4. A module's
pattern-pointer list is one such run, so **any module with 1–3 patterns is never considered**.
Those are the jingles and short cues:

* Franklin: 11 single-pattern modules (`0x330EF0`…`0x332824`)
* LSW1: 7 modules of 2–3 patterns
* LSW2: 7 modules of 1–3 patterns: `0x61FE48`, `0x629034`, `0x62AC50`, `0x62B1AC`, `0x62F390`,
  `0x63DEC0`, `0x63F73C`
* Sims: 10 single-pattern modules

A separate scan found **no other Krawall patterns** in any ROM, so with `-t 1` the lists are
complete. If a LSW2 track you remember is still missing after `-t 1`, it is not stored as a
Krawall module (it may be one of the seven short modules above, or a PCM stream).

### 7.2 Sims with `-t 1`: wrong version detection

The Sims has no `$Id: Krawall` string, so Unkrawerter guesses the pattern format. It first
searches assuming the new format, and that search only succeeds if some candidate's first pattern
reads as `rows ≤ 256`. With `-t 4` nothing passes, so it falls back to the old format correctly.
With `-t 1` the five one-pattern jingles whose first row is empty (follow byte 0, so the u16 reads
as 64) pass. It locks onto the **new** format and decodes everything wrong. In the test it wrote
6.1 GB and 2.4 GB `.s3m` files before being killed. `-k` (force 2003-09-01) avoids this.

Related: `fstr("$Id: Krawall")` and `"$Id: version.h 8 "` are the only signatures checked, so it
prints "Could not find Krawall signature" for Sims and LSW1 even though they carry one.

### 7.3 Franklin's console messages

With the included 4.0 source, Franklin converts without errors. The six lines it prints are:

```
Warning: Pattern N uses special volume column effects only available in OpenMPT.
```

Franklin's modules use ModPlug's S3M volume-column **panning** (50 cells, stored as `0xC0`–`0xCF`).
Standard S3M has no volume-column panning, so Unkrawerter writes it as `0x80 | pan` (the OpenMPT
extension) and warns. Open the result in OpenMPT and it plays correctly. If you saw different
messages with the Windows release, I'd need the exact text, since they don't reproduce with this
source.

### 7.4 Other behaviour worth knowing

* **One failure aborts the batch.** In `main()`, `if (r) {fclose(fp); return r;}` stops at the first
  module that fails to convert, so every later module is lost too.
* **Module-detection heuristics** reject `initSpeed` = 0 or > 16, BPM < 30, and a first pattern
  whose row count is not a multiple of 8. None of these triggered here, but XM-derived modules
  (like BMT's 11-, 39- or 90-row patterns) would fail the last check.
* **Old-format decoding** (`instrument |= (note & 1) << 8; note >>= 1`) is correct, which is why
  the TCRF wording (§3.5) didn't break the tool.

### 7.5 Agent Hugo: why it fails

Reproduced: Unkrawerter prints "Could not find all of the offsets required" and writes nothing,
with any threshold. Four separate problems combine:

1. **Sample-list check rejects real data.** A pointer run is accepted as the sample list only if
   its first four samples each have `c2Freq ≤ 0xFFFF`. In XM-derived modules `c2Freq` is computed
   from relative note and finetune, and Agent Hugo's sample 0 has 105 439. So the 132-entry list at
   `0x2CD4D8` is classed as "unknown", and with no sample list Unkrawerter gives up. (Puppy Luv
   has six such samples, but not among its first four, so it gets through.)
2. **`-s`, `-i` and `-m` take decimal.** They are parsed with `atoi()`, so `-s 2CD4D8` is read as
   `2` and the list is still missing.
3. **Crash with a missing list.** With an empty sample list, the XM writer's "sample not present"
   test is `samples[j] > sampleOffsets.size()` (should be `>=`). It indexes past the end and
   segfaults after writing Module0, instead of printing its warning.
4. **No signature match** (the `player.c` ID isn't recognised), so the format has to be forced.
   Auto-detection would also work here, but `-k` makes it certain.

**Working command:** `UnkrawerterGBA -s 2938072 -k "Agent Hugo - Roborumble (E) (M11).gba"`
(2938072 = `0x2CD4D8`). This writes all five modules as XM.

**Remaining inaccuracy:** the XM writer stores loop type as `loop ? 1 : 0`, so Agent Hugo's one
**ping-pong** sample (sample 32, instrument 15, used in 36 cells of module 1) comes out as a forward
loop. The fix is to write `s->loop` as-is (XM: 1 = forward, 2 = ping-pong).

### 7.6 Puppy Luv

Default settings find six of the seven modules and convert them to XM. The missed module 0
(`0x2B5FD8`) is a 1-channel, 1-pattern, sample-based module, missed by the threshold for the same
reason as the jingles in §7.1; `-t 1` gets all seven.

---

## 8. XM vs S3M: is S3M "more correct"?

**For these four games, yes, for real reasons. For Krawall in general, it depends on the module.**

Krawall is a **dual-mode** player (*"implements all S3M-effects as defined by ST3"* and *"all
XM-effects as defined by FT2"*, handbook ch. 5). The converted data keeps track of which format it
came from:

* `flagInstrumentBased` (S3M: sample numbers; XM: instruments, envelopes, fade-out, autovibrato)
* `flagLinearSlides` (Amiga periods or linear frequency)
* separate effect IDs for S3M and XM behaviour (6 vs 7, 11 vs 10, 15 vs 14), and S3M fine slides
  kept inside 6/11/15
* `flagFastVolSlides` (ST3.00 volume slides on tick 0)

The internal pattern layout is XM-shaped (XM note numbers, 127 = note-off, XM volume column),
which makes XM look like the natural target. For an S3M-derived module, though, XM output has to
*emulate* S3M behaviour that XM doesn't have:

1. **Effect memory.** ST3 shares one parameter memory between `D`, `E`, `F`, `I`, `J`, `K`, `L`,
   `Q`, `R`, `S`; FT2 keeps it per effect. Unkrawerter's XM path rewrites zero parameters
   ("compatibility fixes", `-c` to disable) and still warns about S3M effects that aren't compatible.
2. **Fine slides.** `DFx`/`DxF`/`EFx`/`EEx`/`FFx`/`FEx` are one S3M effect each in Krawall. In XM
   they have to be split into `EAx`/`EBx`/`E1x`/`E2x`/`X1x`/`X2x`, and ST3's `D` also slides on
   tick 0 under `flagFastVolSlides`.
3. **Pitch.** S3M samples are defined by C2Spd, which Krawall stores directly (`c2Freq`). XM needs
   `relativeNote` + `fineTune`, which rounds.
4. **Sub-songs.** S3M has the `+++` order marker. Krawall's `songIndex[]` song mode depends on it,
   and The Sims has 8 multi-song modules. XM has no standard equivalent, so the song boundaries
   are lost.
5. **Rows and channels.** These modules all use exactly 64-row patterns and ≤ 32 channels, so S3M
   loses nothing.

The reverse holds for XM-derived modules such as BMT's: instruments, envelopes, linear slides and
non-64-row patterns cannot be expressed in S3M.

**Recommendation for GBA2MID:** choose the output format **per module from its flags**:
`flagInstrumentBased || flagLinearSlides` (or any pattern ≠ 64 rows) → XM, otherwise → S3M. Map
effects by the S3M/XM split in §3.6, and undo krawerter's porta-direction swap for Amiga-slide XMs.

---

## 9. Notes for GBA2MID / converter implementation

1. **Detect** with the `table_sine` prefix (§2.2), then read the ID string if there is one.
   Recognise all three forms (§2.1). Without a date, pick the pattern format by trial-decoding:
   the correct one decodes every pattern with instrument ≤ sample count and the index table
   consistent. That is unambiguous on all four games, unlike Unkrawerter's first-row heuristic.
2. **Find modules** structurally, not by pointer-run length: `channels` 1–32, order entries
   beyond `numOrders` all 0, `songIndex[0] = 0`, flag bytes ≤ 1, padding 0, pan entries beyond
   `channels` 0, and every `patterns[i]` pointing at a pattern with `index[0] = 0` and
   non-decreasing indices. With this, `kscan.py` found every module with no false positives.
3. **Samples**: unsigned 8-bit; length = `end − (hdr + 18)` (BMT: `hdr+4` directly); ignore the
   69-byte pad; loop type 0/1/2.
4. **Notes**: 1-based, 127 = off. **Instruments**: 1-based; global sample index in S3M mode.
5. **BMT and Princess Natasha** need the unpack step (§5) and the `+0x170` pattern table. Detect
   the layout by the `01 01 08 80` stream signature or by sample headers whose `+4` is a length.
6. **Effects 46–48** are no-ops in the player. Decide whether to keep them (as written) or drop
   them (as heard).
7. **Don't range-check `c2Freq` against 16 bits**, and decide one-shot vs looped from `loop`, not
   `loopLength` (Agent Hugo). Keep loop type 2 as ping-pong.

---

## Appendix: tools written for this analysis

| File | Purpose |
|---|---|
| `kscan.py <rom> new\|old <out.json>` | finds the sample list, instrument list and all modules structurally |
| `kverify.py <rom> <scan.json> new\|old` | decodes every pattern, checks sample padding/signedness and compares the two old-format packings |
| `orphans.py` | looks for valid 64-row patterns not owned by any found module (completeness check) |
| `bmt_unpack.py <bmt.gba> <outdir>` | unpacks BMT's 14 music blobs with the game's own decompressor (needs `unicorn`) |
| `packed_unpack.py <rom> <iwram_lma> <entry> <outdir>` | generic version for any BMT-style game (BMT: `3EA228 030026D0`; Natasha: `3F7C84 03001F80`) |
| `thumbdis.py <rom> <addr> <len>` | small Capstone Thumb disassembler with literal-pool resolution |
