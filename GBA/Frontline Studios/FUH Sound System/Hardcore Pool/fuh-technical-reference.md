# FUH Sound System (Frontline Studios) — GBA
## Reverse-engineering report and technical reference

*Covers the sound engine in **Hardcore Pool** and **Garfield: The Search for Pooky**. Also covers why **Chicken
Shoot**, which was expected to use the engine, does not. The ROMs carry no symbols apart from C++ source file
names in assert strings. Every function, variable and field name below is invented. Statements marked
*(inferred)* are deductions rather than direct reads of the code.*

**Subject files** (`…/GBAAudioLab/FUH/`)

| File | Header | Engine | Verdict |
|---|---|---|---|
| `Hardcore Pool (E) (M4).gba` | `HARDCOREPOOL` / `BHOP` | FUH | reference build |
| `Garfield - The Search for Pooky (E) (M4).gba` | `GARFIELDTSFP` / `BGOP` | FUH | **confirmed**: same ARM player and mixer, relocated; one extra API helper |
| `Chicken Shoot (E) (M5).gba` | `CHICKENSHOOT` / `B6FP` | **not FUH** | different engine, programmer and code base (§2.2) |

**Provenance.** Hardcore Pool's credits read *"DEVELOPED BY FRONTLINE STUDIOS / F U H"*, with programmers
Paweł Jackowski, Rafał Koffer and Michał Skorupka, and music by Szymon Szuchaja. Both FUH games are built on
the same C++ framework. Its file names survive in assert strings: `GameEntry.cpp`, `Sprite.cpp`,
`DmaControl.cpp`, **`DirectSoundSystemMixer.cpp`**, `Messages.cpp` and `SystemConsole.cpp`. The sound code is
GCC Thumb using long-call veneers (`bl`→`bx rN`), plus two hand-written ARM routines that live in IWRAM.

---

## 1. Executive summary

The FUH Sound System is a small **software-mixing tracker player for modules converted from FastTracker 2
(XM)**:

* **Output.** Mono, 8-bit, **DirectSound A only**. Timer 0 reload `0xFC64` gives **18 157 Hz**, exactly
  **304 samples per frame**. DMA1 is re-armed at every V-blank on a double buffer. PSG channels are enabled in
  `SOUNDCNT_L` but the engine never uses them.
* **8 voices** of 64 bytes each. Music takes voices 0–3 (every module has 4 channels). The game uses the rest
  for sound effects by **writing voice structures directly**: there is no SFX API.
* **Everything runs from the V-blank interrupt**: the ARM player tick (`Player_Tick`), then the ARM mixer
  (`Mix_Frame`). Ticks are therefore frame ticks (59.73 Hz), and speed = frames per row.
* **Pitch is XM linear frequency.** Notes are stored as XM linear periods (0–7679, 64 per semitone). One
  7 680-entry 16.16 step table gives `step = 8363·2^((4608−P)/768) / 18157`. Portamento moves 4 period units
  per parameter step, exactly as in FT2's linear mode.
* **Mixing.** Each voice adds `sample × (vol × master >> 6) >> 6` into a biased 16-bit accumulator. The
  sum goes through a **2 048-entry lookup table** that scales and **hard-clips** to signed 8 bits. Nearest
  sample, no interpolation, 16.16 position.
* **Data.** One module holds all of a game's music: Hardcore Pool has one, Garfield two. The game switches
  tunes by **jumping to an order** (`Mus_JumpToOrder` / `Mus_PlayFrom`), and each tune loops with an
  effect-14 position jump. Patterns are byte streams of one event per channel per row: a flags byte, then
  optional note+instrument, volume and effect+parameter. Sound effects come from a second "module" used only
  as a sample bank.
* **Small effect set.** The player implements 11 handlers for porta up/down, tone porta, set volume, volume
  slide, vibrato, vibrato+slide, speed, position jump and sample offset. Everything else, including pattern
  break, arpeggio and panning, is a no-op. Several memory fields are **shared between effects** (and between
  sample offset and the instrument number), which changes what about 1 000–2 000 events do in the shipped
  data (§11).

Garfield's player and mixer are **byte-identical** to Hardcore Pool's apart from relocated addresses. Its Thumb
API is identical apart from literal pools, plus one helper (`Mus_PlayFrom`). It is the same library, so this
document treats it as one engine version with two builds.

---

## 2. Identification

### 2.1 Garfield: The Search for Pooky — confirmed FUH

| Check | Result |
|---|---|
| ARM player (`Player_Tick`, 0x5C0 bytes) | identical; the only differing words are 42 literal-pool words (handler table, own addresses, mixer state, step table) |
| ARM mixer (`Mix_Frame`, 0x1A0 bytes) | identical; 7 literal-pool words differ |
| Step table (7 680 × u32) | identical contents (Garfield `08CF80F0`, Hardcore Pool `083E1E00`) |
| Vibrato table | identical, including the `0x80` error (§11.2) |
| Thumb API (`Mixer_*`, `Mus_*`, V-blank handler) | every function identical apart from literal pools and `bl` displacements |
| Module format | identical (§7) |
| Framework strings | same `.cpp` set (`DirectSoundSystemMixer.cpp` at `08D043A0`) |
| Init call | `Mixer_Init(8, 18157, 304, 48)`, against Hardcore Pool's master volume of 80 |

The only functional difference is the extra `Mus_PlayFrom(module, order)` helper (§3), which Garfield uses for
every music start (17 call sites). `Mus_JumpToOrder` and `Mixer_FindFreeVoice` are still present but
unreferenced in Garfield.

### 2.2 Chicken Shoot — a different engine

Chicken Shoot contains **none** of FUH's code or tables: no step table, no vibrato table, no mixer or player,
no FIFO/timer literals, and no `.cpp` strings. It is a different code base. Its credits name *frontline studios
& vivid design*, with programming by **Jarosław Wojczakowski** and music/SFX by Łukasz Stasiński. Its sound
engine has these characteristics, noted for a future pass:

* **ARM-mode** code with APCS frames (`mov ip,sp; push {…fp,ip,lr,pc}`) at roughly `080DFB00–080E7798`,
  working state at IWRAM `03000000`, and `0x168` bytes copied from `080E6A50` to `03000268`.
* A **12-entry rate table** at `080E0728`: Timer 0 reloads for 5 734, 10 512, 11 468, 13 379, 18 157,
  20 068, 21 024, 26 758, 31 536, 36 314, 40 137 and 42 048 Hz, the MP2K-style frame-locked rates, with a
  samples-per-frame table at `080E070E`.
* `SOUNDCNT_H = 0xFB0E`: DirectSound A on Timer 0 **and B on Timer 1**, both to both sides. Timer 1 is fixed
  at `0xFB1A` (13 379 Hz). DMA1 → FIFO A and DMA2 → FIFO B, both with control `0xB640`.
* Large multiplication/volume tables at `080E1000–080E6000` and a 0–64 sine table at `080E67C9`.
* Entered from the IRQ stub at `0800027C` (`bl 080E0290`).

Any tool that classifies Chicken Shoot as FUH is probably keying on the developer rather than the code.

### 2.3 Signature for GBA2MID

All of these are present in both FUH builds:

* **Step table head:** `5E 7A 1D 00 8F 73 1D 00 C2 6C 1D 00` (u32 `0x1D7A5E, 0x1D738F, 0x1D6CC2`), followed by
  7 677 more strictly decreasing words. Any XM-linear table pre-scaled to 18 157 Hz will match; in practice
  only FUH has it.
* **Vibrato table:** `00 0C 18 25 30 3C 47 51 5A 62 6A 70 76 7A 7D 7F 80 7F 7D 7A`, with `0x80` at index 16.
* **Mixer prologue:** `FF 5F 2D E9 04 C0 90 E5` (`push {r0-r12,lr}; ldr ip,[r0,#4]`) inside the crt0 IWRAM
  image.
* **Modules:** found by the structural scan in §7.1 (`fuhdump.py` `find_modules`).

---

## 3. Where everything is

### 3.1 Code

| Piece | Hardcore Pool | Garfield |
|---|---|---|
| crt0 IWRAM image (ROM → `03000000`) | `083EC724`, 0x4064 bytes | `08D04568`, 0x2340 bytes |
| `Mix_Frame` (ARM) | `03000408` (ROM `083ECB2C`) | `03000390` (ROM `08D048F8`) |
| `Player_Tick` + effect handlers (ARM) | `03002838–03002DB4` (ROM `083EEF5C`) | `0300052C–03000AA8` (ROM `08D04A94`) |
| Effect handler table (32 words) | `03002D20` | `03000A14` |
| Vibrato table (64 × s8) | `03002DB4` | `03000AA8` |
| Step table (7 680 × u32, ROM) | `083E1E00–083E9600` | `08CF80F0–08CFF6F0` |
| `VBlank_Sound` (Thumb) | `08000190` | `08000190` |
| Mixer API (Thumb, `DirectSoundSystemMixer.cpp`) | `08035A00–08035CCC` | `080280B8–08028384` |
| Music API (Thumb) | `08039260–080393AC` | `0802BAC8–0802BC50` |

### 3.2 Function table

| Name | Hardcore Pool | Garfield | Notes |
|---|---|---|---|
| `VBlank_Sound` | `08000190` | `08000190` | V-blank IRQ handler; registered with mask 1 |
| `Mix_Frame` (ARM) | `03000408` | `03000390` | |
| `Player_Tick` (ARM) | `03002838` | `0300052C` | |
| `Player_Note` (ARM, internal) | `030029E4` | `030006D8` | note/instrument part of an event |
| `Mixer_BuildOutputTable(gain)` | `08035A00` | `080280B8` | called with 64 |
| `Mixer_ClearVoices()` | `08035B34` | `080281EC` | |
| `Mixer_Init(nVoices, rate, samplesPerFrame, master)` | `08035B88` | `08028240` | |
| `Mixer_Start()` | `08035C00` | `080282B8` | |
| `Mixer_Stop()` | `08035C40` | `080282F8` | |
| `Mixer_FindFreeVoice()` | `08035C88` | `08028340` | 1 caller in HP, unused in Garfield |
| `Mus_Play(module, order, fadeIn)` | `08039260` | `0802BAC8` | |
| `Mus_Stop()` | `080392C0` | `0802BB28` | **unreferenced and broken** (§11.4) |
| `Mus_TogglePause(fadeStep)` | `080392D0` | `0802BB38` | |
| `Mus_SetFade(delta)` | `08039300` | `0802BB68` | |
| `Mus_WaitFade()` | `08039320` | `0802BB88` | busy-wait |
| `Mus_SetState4()` | `08039344` | `0802BBAC` | unreferenced |
| `Mus_PlayFrom(module, order)` | — | `0802BBC4` | Garfield only |
| `Mus_JumpToOrder(order)` | `0803935C` | `0802BC00` | unreferenced in Garfield |

`080358F8`/`08035984` sit next to the mixer, but they belong to `DmaControl.cpp` (a 20-byte-record DMA
queue), not to the sound engine.

---

## 4. Public API

```c
/* mixer (DirectSoundSystemMixer.cpp) */
void Mixer_Init(int nVoices, int rate, int samplesPerFrame, int master);
        /* HP: (8, 18157, 304, 80)   Garfield: (8, 18157, 304, 48)
           allocates a fixed 0x200-byte voice array (8 voices, whatever nVoices says), clears
           nVoices*64 bytes, builds the output LUT with gain 64, clears the voice states.
           'rate' is stored at +0x14 and never read: the timer reload and the step table are
           hard-wired for 18 157 Hz. */
void Mixer_Start(void);   /* TM0 off; SOUNDCNT_X=0x80; SOUNDCNT_L=0xFF77; SOUNDCNT_H=0x0B0E;
                             TM0 reload 0xFC64; TM0CNT_H=0x80 */
void Mixer_Stop(void);    /* timer 0, DMA1, DMA2 and SOUNDCNT_L/H/X cleared */
int  Mixer_FindFreeVoice(void);   /* first voice with state 0, or 8 (§8) */

/* music */
int  Mus_Play(const Module *m, int order, int fadeIn);   /* 0 = refused, 1 = ok */
void Mus_PlayFrom(const Module *m, int order);           /* Garfield: Mus_SetFade(256);
                                                            stop voices 0-3; Mus_Play(m, order, 256) */
void Mus_JumpToOrder(int order);                         /* same tune switch inside the current module */
void Mus_SetFade(int delta);      /* music volume += delta every ROW, clamped 0..256 */
void Mus_WaitFade(void);          /* spin until the fade has finished */
void Mus_TogglePause(int fadeStep);
```

**`Mus_Play`** clears the player state, rejects a module with 0 orders or whose starting pattern's row count
(read as a **byte**) is 0, then sets speed = `tick` = module speed so that row 0 is read on the next V-blank.
It stores `module+8` into an unused slot, sets state 2, and applies `fadeIn` only if the music volume is
currently 0 and the music is not paused. Voices still sounding from the previous tune are **not** stopped.

**`Mus_JumpToOrder(order)`** does nothing without a module. Otherwise it calls `Mus_SetFade(256)`, which puts
the volume back to full at the next row, and stops **voices 0–3** (hard-coded, whatever the module's channel
count). It then sets the order, its pattern and row 0. The tick counter is not reset, so the new row can
arrive up to *speed* frames later.

**Host obligations** (from `GameEntry` at `080002A0` in Hardcore Pool):

```
Mixer_Init(8, 18157, 304, 80);
Mixer_Start();
SetIrqHandler(VBlank_Sound, IRQ_VBLANK);
...
Mus_Play(&module0, 0, 256);
```

Tune changes in Hardcore Pool always look like
`Mus_SetFade(-30); Mus_WaitFade(); Mus_JumpToOrder(n);`: a fade-out of about 9 rows, then the jump.

---

## 5. Hardware and the output stage

### 5.1 Resources

| Resource | Use |
|---|---|
| `SOUNDCNT_H = 0x0B0E` | PSG 100 %, DS-A 100 % (the DS-B volume bit is set but B is not routed), A → L+R, A on Timer 0, FIFO A reset |
| `SOUNDCNT_L = 0xFF77`, `SOUNDCNT_X = 0x80` | master on; PSG enables at full, but the engine never starts a PSG channel |
| Timer 0 | reload `0xFC64` (−924): 16 777 216 / 924 = **18 157.1 Hz** = 304.0 samples per 280 896-cycle frame |
| DMA1 → `FIFO_A` | re-armed every V-blank: SAD = current buffer, DAD = `040000A0`, CNT_H = `0xB640` (enable, FIFO timing, 32-bit, repeat, fixed destination) |
| `REG_SOUNDBIAS` | not touched |

### 5.2 `VBlank_Sound` (per frame)

```
DMA1CNT_H = 0
DMA1SAD   = outbuf + mixer.bufOfs        ; the half mixed during the previous frame
DMA1DAD   = FIFO_A;  DMA1CNT = 1 | 0xB640<<16
Player_Tick()                            ; ARM, IWRAM
Mix_Frame(&mixer)                        ; ARM, IWRAM: flips bufOfs and mixes the other half
*(u16*)0x03007FF8 = 1                    ; acknowledge for VBlankIntrWait
```

The output buffer is 1 024 bytes (HP `030031FC`, Garfield `030014D8`). Each half is 512 bytes, of which 304 are
used. Latency is one frame. Because the timer gives exactly 304 samples per frame, the DMA reaches the end of
the half just as it is re-armed.

### 5.3 `Mix_Frame`

```
fill acc[304] (16-bit, packed in pairs) with 0x0400              ; bias = LUT centre
patch literal: masterVol = mixer.master                          ; self-modifying literal
mixer.bufOfs ^= 0x200
for each of mixer.nVoices voices with state != 0:
    end  = loopEnd ? loopEnd : sampleEnd                         ; absolute pointers
    g    = (masterVol * voice.vol) >> 6
    repeat for each PAIR of output samples:
        p = base + (frac >> 16)
        if p > end:
            if loopEnd: frac = 0; base = loopStart; p = base
            else:       voice.state = 0; stop this voice for the frame
        s0 = *p;  frac += step;  p = base + (frac>>16);  s1 = *p;  frac += step
        acc_pair += ((s0*g >> 6) & 0xFFFF) | ((s1*g >> 6) << 16)
    voice.base += frac >> 16;  voice.frac = frac & 0xFFFF
for each sample: out[i] = LUT[acc[i]]                            ; 4 samples per loop pass
```

* **The end test happens once per pair**, so the second sample of a pair can be read up to one step past the
  end. At a loop wrap the overshoot and the fraction are **discarded**, not carried into the loop (§11.3).
* The pair is added as one 32-bit word. A negative even sample therefore carries **+1 into the odd sample**
  of the pair.

### 5.4 Output table (`Mixer_BuildOutputTable(64)`)

A 2 048-byte table at `03003860` (Garfield `03001B3C`):

```
span  = 32768 / gain           (gain 64 → 512)
lo    = 1024 − span/2          (768),   hi = lo + span   (1280)
LUT[i] = −128                     for i < lo
       = (i − lo)·256/span − 128  for lo ≤ i < hi
       = +127                     for i ≥ hi
```

So output = (Σ voice contributions) / 2, hard-clipped at ±128. One music voice at full volume contributes
`s × 80/64 = 1.25 s` in Hardcore Pool, or `0.75 s` in Garfield.

The accumulator index is **not range-checked**. A sum outside −1024…+1023 reads outside the table: past its
end, or for negative sums (16-bit wrap) up to 64 KB further on, which lands in IWRAM's 32 KB mirror. Hardcore Pool's SFX
volume of 200 contributes up to ±496 by itself. Add four music voices at full level (±640) and the index
can leave the table (§11.3).

---

## 6. Voices

### 6.1 Voice structure (64 bytes; HP array at `[030031D8]`, Garfield `[030014B4]`)

| Off | Field | Set by |
|---|---|---|
| `00` | state: 0 = off, nonzero = playing (player and game write 2) | player / game / mixer |
| `04` | step, 16.16 | note, porta, vibrato |
| `08` | position fraction (low 16 bits) | mixer |
| `0C` | current sample pointer | note (= PCM data), sample offset |
| `10` | sample end pointer (data + length) | note |
| `14` | loop start pointer | note |
| `18` | loop end pointer, 0 = one-shot | note |
| `1C` | mix volume (music: chanVol × musicVol >> 8; SFX: set by the game) | player / game |
| `20` | tick handler (ARM address) or 0 | row effect |
| `24` | effect parameter memory, **shared** by effects 1, 2, 3, 4, 6, 7, 8 and 12 | row effect |
| `28` | vibrato phase (0–63) | |
| `2C` | current period (step-table index) | note, porta |
| `30` | vibrato parameter memory used by effect 12 | effects 7, 8 |
| `34` | tone-porta target period (any note sets it) | note |
| `38` | last instrument **and** sample-offset memory (one field) | note, effect 15 |
| `3C` | channel volume 0–64 | instrument, volume byte, effects 5, 6, 12 |

The music channels **are** voices 0…nch−1. The player keeps all channel state inside the voice.

### 6.2 Mixer state (HP `030031D8`, Garfield `030014B4`)

```
+00 voices*    +04 samplesPerFrame (304)   +08 master volume   +0C nVoices
+10 buffer offset (0 / 0x200)   +14 rate (unused)   +1C music volume 0..256   +20 fade delta
```

---

## 7. Data formats

All fields are u32 unless stated otherwise. Everything is absolute ROM pointers, with no relocation.

### 7.1 Module

```
+00 nch          music channels (4 in every music module; 16 in HP's SFX bank)
+04 norders      0 = sample bank only
+08 ?            59 or 50; never read (Mus_Play copies it to a dead slot)
+0C speed        initial frames per row (6 everywhere)
+10 ins_table    -> ptr[]: entry 0 is NULL in music modules (XM numbering from 1)
+14 order_table  -> ptr[norders], each -> pattern header
```

Pattern header: `{u32 rows, u32 data}`. Instrument: `{u32 loopStart, u32 loopEnd (0 = one-shot), u32 volume
(0–64), u32 pcmHeader}`. PCM header: `{u32 length, u32 data}`, 8-bit signed PCM at any byte address.

Instrument and PCM records are shared: both of Garfield's music modules point at the same 23 instrument
structures. A scan that finds every module checks `1 ≤ nch ≤ 32`, `norders ≤ 256`, `1 ≤ speed ≤ 31`, two
word-aligned ROM pointers, every order → `{rows ≤ 256, ROM pointer}`, and `ins_table[1]` → volume ≤ 64 with
a ROM PCM header.

### 7.2 Pattern data

One event per channel per row, with no row terminator:

```
u8 flags
if flags & 0x01:  u16 period (LE), u8 instrument (0 = keep previous)
if flags & 0x80:  u8 volume (0..64)
if flags & 0x7E:  u8 parameter; effect = (flags >> 2) & 31        (bit 1 is always 0)
```

A **tone-portamento note** is recognised only when `(flags & 0xFE) == 0x10`, meaning effect 4 *without* a
volume byte. It then sets just the target and skips the instrument byte. With a volume byte present, the note
retriggers (§11.1).

Row counts are effectively **8-bit**. Garfield's second module has three patterns with 256 rows of data and a
row count of **0**. The engine plays their first row and moves on (§11.1).

### 7.3 Periods and the step table

`period = 7680 − 64·note − finetune/2` (FT2 linear). The sample's relative note and finetune are already
folded in, so 4608 means "8 363 Hz" for every sample. The table entry is
`round(65536 · 8363 · 2^((4608 − P)/768) / 18157)`, from 29.48 at P = 0 down to 0.029 at P = 7679. Shipped
notes span periods 1664–6272 (plus one period-0 event in Hardcore Pool, §11.1).

### 7.4 Origin of the format *(inferred)*

The linear-frequency table, 4-unit porta steps, 0–64 volumes, a separate volume byte that only Garfield uses
(the XM volume column), 1-based instruments flattened to single samples, `0x95` "panning" parameters and
non-64-row patterns all point to **FT2 .XM modules** run through an in-house converter. The converter numbered
effects its own way (§9).

---

## 8. Sound effects

There is no SFX function. Game code fills a voice directly. A typical Hardcore Pool site (`080039C0`) shows
the pattern:

```
ins = sfxBank->ins_table[k]                    ; sfxBank = HP 0839D868, Garfield 08B41AF0
v   = &voices[4]                               ; a fixed voice from 4-7 per call site (Garfield 08002490: voice 6)
v->state = 0
v->ptr   = pcm.data;   v->frac = 0
v->loopStart = pcm.data + ins.loopStart;  v->loopEnd = ins.loopEnd ? pcm.data + ins.loopEnd : 0
v->end   = pcm.data + pcm.length
v->step  = StepTable[3840]                     ; period 3840 = 16 726 Hz
v->vol   = 200 (HP) / 64 (Garfield)
v->state = 2
```

Hardcore Pool plays every effect at period 3840 (16 726 Hz). Garfield uses several step-table entries per call
site, from period 1536 (`08002490`, 7.4× the stored rate) up to 3840. The SFX banks are modules with no orders (HP: 16 channels, 18 samples) or with one
empty pattern (Garfield: 4 channels, 66 samples). They are never played as music.

`Mixer_FindFreeVoice` searches from voice 0, or from voice *nch* only **while the music is paused**. The test
looks inverted *(inferred)*: during normal playback it can hand out a music voice whose sample has ended.

---

## 9. The player

### 9.1 Timing

`Player_Tick` runs once per V-blank:

```
if state == 0: return
if ++tick < speed:                              ; effect ticks
    for each music channel: if handler: handler(param = voice.mem24)
    return
tick = 0                                        ; row tick (no handlers run on it)
for each channel: read one event; handler = 0
    if note:   Player_Note
    if vol:    chanVol = vol
    if effect: handler = FxRow[effect](param)   ; may install a tick handler
if a position jump happened: return             ; volume update skipped this row
advance row; at pattern end next order; at the end of the order list -> order 0
musicVol += fadeDelta, clamp 0..256 (delta cleared at a limit)
for each channel: voice.vol = chanVol * musicVol >> 8
```

* A tick is one frame, so a row lasts *speed* frames: 100.5 ms at speed 6.
* **Volume reaches the voice only on row ticks.** Effect-6 slides change `chanVol` every tick, but the
  listener hears them as one step per row, and the music fade also moves once per row.

### 9.2 Note (`Player_Note`)

```
target = period
if tone-porta event: skip instrument byte; return
voice.period = period; step = StepTable[period]
i = instrument byte; if i == 0: i = voice.mem38 else voice.mem38 = i
ins = module.ins_table[i]
if instrument byte != 0: chanVol = ins.volume
ptr = pcm.data; end = data+length; loopStart = data+ins.loopStart; loopEnd = ins.loopEnd ? data+loopEnd : 0
frac = 0; state = 2
```

There is no note-off and no envelope. A note sounds until the sample ends, a new note replaces it, or the
game stops the voice.

### 9.3 Effects

Effect number = `(flags >> 2) & 31`. The XM column gives the most likely source, judged from the handler and
the parameters in the data.

| # | Handler | Row action | Tick action | Likely XM source |
|---|---|---|---|---|
| 1 | `03002A88` | `mem24 = p` | — | unknown (param always `0x95`; 8xx pan?) |
| 2 | `03002A90` | if p: `mem24 = p` | `period −= mem24·4` (no lower clamp) | 1xx |
| 3 | `03002AC4` | if p: `mem24 = p` | `period += mem24·4` (no upper clamp) | 2xx |
| 4 | `03002AF4` | if p: `mem24 = p` | slide toward `target` by `mem24·4`, clamp at target | 3xx |
| 5 | `03002B54` | `chanVol = p` (no clamp) | — | Cxx |
| 6 | `03002C9C` | `mem24 = p` (even 0) | `chanVol = clamp(chanVol − y + x, 0, 64)` | Axy |
| 7, 8 | `03002B5C` | if note: phase = 0; if p: `mem24 = mem30 = p` | phase += x (mod 64); `period' = period + (sine[phase]·y >> 7)·4` | 4xy |
| 9 | `03002CD4` | `speed = p` | — | Fxx (< 0x20) |
| 12 | `03002BCC` | `mem24 = p` (even 0) | volume slide with `mem24`, then vibrato with `mem30` | 6xy |
| 14 | `03002C58` | order = p, row 0 | — | Bxx |
| 15 | `03002C80` | if p: `mem38 = p` else `p = mem38`; `ptr += p·256` | — | 9xx |
| 10, 11, 13, 16–30 | `bx lr` | nothing | — | 16 looks like Dxx (param 00); 26 and 28 unknown |
| 31 | (the table's terminating 0 word) | **branch to address 0** | — | never used |

The vibrato handler writes `voice.step` only; the stored period does not change. Portamento, tone porta and
vibrato update `step` every tick, so pitch effects are smooth. Volume effects are not (§9.1).

---

## 10. RAM map

| | Hardcore Pool | Garfield |
|---|---|---|
| Player state (`03000000`, 0x2C bytes): state, tick, speed, (module+8), module, pattern, data ptr, order, row, paused, saved volume | `03000000` | `03000000` |
| Mixer state | `030031D8` | `030014B4` |
| Output double buffer (2 × 512 B) | `030031FC` | `030014D8` |
| 16-bit accumulator (304 × u16) | `030035FC` | `030018D8` |
| Output LUT (2 048 B) | `03003860` | `03001B3C` |
| Voices (8 × 64 B, heap) | pointer at `030031D8` | pointer at `030014B4` |

`Mus_TogglePause` saves the music volume at `03000028`, but nothing reads it back. Un-pausing fades up to 256
regardless.

---

## 11. Bugs, quirks and dead code

### 11.1 Data-dependent (counted in the data dump)

1. **Sample offset and instrument share `mem38`.** `15:xx` stores its parameter where the note handler keeps
   the last instrument number. As a result:
   * `15:00` (offset memory) uses the **instrument number** as the offset. Hardcore Pool has 430 cases, e.g.
     instrument 22 → offset 5 632 bytes.
   * A later note with instrument 0 plays **instrument `xx`**. Garfield has 35 such notes.
2. **Effects share `mem24`.** A parameter-0 porta, tone porta or vibrato continues with whatever the last
   effect left there: a tone-porta speed such as `F0` becomes a vibrato with speed 15 and depth 0, a slide
   `01` becomes a 1-unit vibrato, and so on. Garfield has 1 513 affected vibrato events and 104 tone-porta
   events; Hardcore Pool has 62 tone-porta events and 4 vibrato events.
3. **`6:00` and `12:00` do not repeat the previous slide** (XM would). Garfield has 292 and 515 cases.
4. **Tone porta plus a volume byte retriggers the note.** The `(flags & 0xFE) == 0x10` test fails, so the
   note restarts instead of sliding. Garfield has 126 cases. Hardcore Pool never uses the volume byte.
5. **8-bit row counts.** Garfield module 2 orders 48, 140 and 141 hold 256-row patterns with the count stored
   as 0. One row of each plays, and 765 rows of music are skipped. Tune 138 therefore plays orders 138–139,
   one row each of 140 and 141, then falls off the end of the order list into order 0, that module's first
   tune.
6. **Volume slides and fades are applied per row**, not per tick (§9.1).
7. **Unimplemented effects** used in the data: 1 (×107), 10 (×1), 16 (×2: a pattern break on a last row, or
   before an empty half pattern), 26 (×59) and 28 (×44).
8. **Period 0 as a cut** *(inferred)*. Hardcore Pool order 63 row 53 has a note with period 0 and instrument 0
   right after effect `10:14`. It plays the last sample at 29.5× speed, which empties a short one-shot within
   a few output samples, so it acts as a crude note-off.
9. **Bad loop in Garfield's SFX bank.** Instrument 33 has loop 0–95 240 on a 47 620-byte sample, so a looped
   play runs 47 620 bytes into the next sample.

### 11.2 Engine

1. **Vibrato sine table error.** Index 16, the positive peak, holds `0x80`, which `ldrsb` reads as **−128**.
   Each vibrato cycle jumps to the opposite extreme for one tick.
2. **Effect 31** jumps to address 0 (table terminator used as a handler).
3. **Porta range unchecked.** Porta up only tests the V flag (`movvs`), and porta down tests nothing, so
   periods can leave 0–7679 and index outside the step table. No shipped tune does this (simulated).
4. **No clamp on effect 5** (`chanVol` up to 255) or on SFX volume (HP uses 200).

### 11.3 Mixer

1. **Loop wrap drops the overshoot.** At a loop end the position is set to exactly `loopStart` and the fraction
   to 0. Short loops therefore play **flat**: by up to one step per cycle, which is noticeable for loops of a
   few hundred bytes at high pitch, such as HP instrument 8 (166-byte loop).
2. **Pair-wise end test:** up to one extra sample past the end or loop end.
3. **Packed-pair carry:** negative even samples add +1 to the odd sample.
4. **LUT index unchecked** (§5.4). Hardcore Pool's SFX at volume 200 already clip on their own and can push
   the index out of the table when the music is loud.
5. **`Mixer_Init` ignores `nVoices` for the allocation** (fixed 0x200 bytes) and ignores `rate`.

### 11.4 Dead and broken API

* `Mus_Stop` (`080392C0`) sets state 1 and module NULL. The next tick would then dereference the NULL module
  and loop over garbage channel counts. It is never called.
* `Mus_SetState4` and, in Garfield, `Mus_JumpToOrder` and `Mixer_FindFreeVoice` are unreferenced.
* The module's `+08` field and the mixer's `rate` are never read.

---

## 12. Content inventory

| | Hardcore Pool | Garfield |
|---|---|---|
| Music modules | 1 (`0832A954`): 216 orders, 186 patterns (all 64 rows), 108 710 B of pattern data | 2: `08C8D17C` (244 orders, 171 patterns of 32–192 rows) and `08CE623C` (142 orders, 95 patterns, three of them 256-row) |
| Instruments | 52 (356 559 B) | 23, shared by both modules (251 771 B) |
| SFX bank | `0839D868`: 18 samples (265 487 B; #12 and #13 have NULL data) | `08B41AF0`: 66 samples (1 354 825 B) |
| Tunes (entry orders) | 11: 0, 25, 29, 54, 65, 86, 99, 120, 156, 177, 195 (all started by the game) | module 1: 11 (0, 22, 41, 80, 112, 138, 177, 187, 191, 199, 218; 22, 112, 138 and 218 have no call site). Module 2: 5 (28, 83, 117, 132, 138; 83 and 117 have no call site) |
| Effects used | 1 2 3 4 5 6 7 9 10 14 15 16 | 1 2 3 4 5 6 7 9 12 14 15 16 26 28, plus the volume byte |
| Master volume | 80 | 48 |

Every tune's order range, loop point and length, every instrument, and per-module effect statistics are in
the **FUH data dump**. The decoded patterns and WAVs are in `FUH/Claude outputs/`.

---

## 13. Notes for GBA2MID

* **Find modules** by the structural scan, and find tunes by collecting the targets of effect 14 plus the
  orders the game passes to `Mus_Play`/`Mus_JumpToOrder`/`Mus_PlayFrom`. Each tune runs from its entry to the
  effect-14 jump that closes it.
* **XM export is nearly 1:1.** Use 4 channels, linear frequency, and samples with relative note 0 (period 4608
  = 8 363 Hz). Map effects 2→1, 3→2, 4→3, 5→C, 6→A, 7→4, 9→F, 12→6, 14→B, 15→9, volume byte → volume
  column. Set the BPM to 149.3 (= 2.5 × 59.73; round to 149) so that one XM tick equals one GBA frame.
* **For faithful playback** (rendering or MIDI), emulate §11.1: shared `mem24`/`mem38`, per-row volume, the
  tone-porta-with-volume retrigger, 1-row 0-count patterns and the vibrato `0x80`.
* **Mixer:** 18 157 Hz, nearest-sample, sum × master / 64 / 2 → clip ±128.

---

## 14. Deliverables and next step

* `fuh-data-dump` (project doc), plus `FUH/Claude outputs/`: `fuhdump.py` (the module scanner/decoder),
  `fuh_hp_*` and `fuh_gf_*` dumps, decoded patterns and per-instrument WAVs.
* **Not yet done:** a byte-exact, rebuildable disassembly (ASM source + linker script + ROM check), as for
  the other engines in this project. Hardcore Pool is the natural first target. Its sound code is three
  contiguous pieces: the IWRAM ARM player/mixer, the Thumb mixer/music API, and `VBlank_Sound`.
