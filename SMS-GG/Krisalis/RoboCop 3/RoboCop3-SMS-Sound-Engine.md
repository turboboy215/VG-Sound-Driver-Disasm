# RoboCop 3 (SMS) — Sound Engine Disassembly Notes

**Game:** RoboCop 3 (UE) [!].sms  (262,144 byte ROM, 8 × 32 KB banks)
**Bank:** $6 (ROM $18000–$1FFFF)  — loaded into **slot 2 ($8000–$FFFF)**
**Author of driver:** Shaun Hollingworth (Krisalis)
**Music/SFX:** Matt Furniss

This document describes the tracker-style sound engine used in RoboCop 3 for the
Sega Master System. The engine is one of the Krisalis PSG trackers; the same family
of driver appears in other Krisalis SMS/Game Gear titles (e.g. Alien 3, Chuck
Rock 1/2, Road Rash, etc.). All addresses below are *logical* addresses with the
bank mapped at $8000 (i.e. logical $8000 = ROM offset $18000). Where useful,
ROM offsets are shown in parentheses.

---

## 1. Bank 6 layout (logical addresses, ROM offsets in parentheses)

```
$8000  ($18000)  SONG data table
                 $80F8 bytes of 4-byte rows (62 rows). Each row is one sequencer
                 step and contains one *pattern selector* byte per channel
                 (see §2).
$80F8  ($180F8)  PATTERN POINTER DIRECTORY
                 92 entries × 2 bytes. Each entry is the absolute (bank-relative)
                 address of a pattern block (see §3).
$81B0  ($181B0)  PATTERN DATA (note/command streams), interleaved with the
                 directory in the range $8000–$8C6F.
$8D74  ($18D74)  INSTRUMENT TABLE — 25 instruments × 8 bytes (see §5).
$8E44  ($18E44)  DRIVER CODE
$9016  ($19016)  NOTE → PSG PERIOD TABLE, 72 × 16-bit entries (see §4).
$90A6  ($190A6)  SOUND ON / SONG START
$90BF  ($190BF)  INIT_SONG  (A = song number → stored at $DCC9)
$9149  ($19149)  INIT_SFX   (A = sfx number → stored at $DCCF)
$9192  ($19192)  SOUND UPDATE (called once per frame)
$927F  ($1927F)  RESET song step/delay counters
$92B4  ($192B4)  SFX sequencer step
$92D2  ($192D2)  MUSIC sequencer step
$9306  ($19306)  Read/execute one pattern command for one voice
$9463  ($19463)  Pitch-envelope (glide/vibrato) update + tone output
$958A  ($1958A)  end of code
```

The pattern-pointer directory is referenced by the sequencer with
`LD DE, $80F8; ADD HL, DE` where HL = selector × 2 (see $9317/$931A).

---

## 2. Song data ($8000–$80F7)

62 consecutive **steps**, each **4 bytes**. For step N the four bytes select the
pattern used by music channels 0..3:

```
  row N:  +0  selector for music channel 0 (voice @$DC00)
          +1  selector for music channel 1 (voice @$DC21)
          +2  selector for music channel 2 (voice @$DC42)
          +3  selector for music channel 3 (voice @$DC63)
```

The selector value indexes the pattern directory at $80F8:

```
  pattern_address = directory[selector]   (directory = 2-byte entries)
```

The music sequencer ($92D2) computes `HL = $8000 + song_pos * 4` and hands each
channel its own byte (`HL+ch`) to the command reader $9306.

SFX use the same 4-byte-row table but start two bytes in (`$8000 + sfx_pos*4 + 2`)
and drive only two voices ($DC84 and $DCA5), i.e. they use bytes 2 and 3 of the
selected row (see $92B4). Therefore SFX and music can live in the same song space.

The "song number" passed to INIT_SONG is simply the starting row index; all songs
share one contiguous row table (62 steps ≈ up to 6 songs plus a silent/empty one).

---

## 3. Pattern data and the command format

A "pattern" is a block of 2-byte commands:

```
  byte0   command/note byte
  byte1   instrument/parameter byte
```

The reader ($9306) behaves as follows for a voice whose rest counter (voice+31) is 0:

1. reads one byte from the current song-stream pointer and uses it as a directory
   index (×2) into the $80F8 table → obtains the pattern address;
2. a global row counter ($DCD4) is compared with the *first byte of the pattern*
   and the resulting offset is added to the pattern pointer, so a pattern's leading
   byte acts as a row/loop marker (only the pair at the current offset is executed);
3. the two command bytes are unpacked:

```
  (IX+17) = byte0 << 2                      ; "value" (note × 4 / count)
  (IX+19) = byte1 & 0x7F                    ; instrument / parameter
  (IX+16) = ((byte0 << 1) | (byte1 >> 7)) & 7   ; 3-bit opcode
```

### Command opcodes (dispatch at $9349)

| op | meaning                                                    |
|----|------------------------------------------------------------|
| 0  | Rest. If (IX+19)≠0 store it in voice+31 (rest duration), else keep sounding. |
| 1  | (duration/tempo style command) — sets voice+25/+26 counters; interacts with the master step flags at $DCCB/$DCCA/$DCD3. |
| 2  | (stop / loop command) — clears the "sound on" flag $DCD2 and calls the mute routine $8E62. |
| 3  | **Set instrument**: voice+14 = byte1 & 0x1F, then jumps to instrument loader $8FB1. |
| 4  | Slide up: voice+21 = 0, voice+20 = byte1 × 2. |
| 5  | Slide down: voice+20 = 0, voice+21 = byte1 × 2. |
| 6  | Arpeggio setup: byte1 low 5 bits = arpeggio step value; bits 5/6 of byte1 select which of voice+22/+23 is used. |
| 7  | (unused / falls through to return) |

If the opcode is a note trigger, execution continues at $941C ("note on"): the
value in voice+17 is used as a note index into the period table (voice+17/2 entries
after the ×2 shift — i.e. quarter-note resolution), the note period is placed in
voice+2/+3, the pitch/vibrato state is re-initialised and the note is sounded.

---

## 4. Note → period table ($9016)

72 entries of 16-bit little-endian PSG tone periods, each step ≈ 1 semitone
(period ratio ≈ 1.059), tuned so entry 0 ≈ **A2** and running up ≈ 6 octaves.

Decoded note names (frequencies = 3.579545 MHz ÷ (32 × period)):

| idx | period | note |        | idx | period | note  |
|-----|--------|------|--------|-----|--------|-------|
| 00  | 03FF   | A2   | 109 Hz | 18  | 0100   | A4    |
| 01  | 03C7   | A#2  | 116 Hz | 19  | 00F2   | A#4   |
| 02  | 0390   | B2   | 123 Hz | 1A  | 00E4   | B4    |
| 03  | 035D   | C3   | 130 Hz | 1B  | 00D7   | C5    |
| 04  | 032D   | C#3  | 138 Hz | 1C  | 00CB   | C#5   |
| 05  | 02FF   | D3   | 146 Hz | 1D  | 00C0   | D5    |
| 06  | 02D4   | D#3  | 155 Hz | 1E  | 00B5   | D#5   |
| 07  | 02AB   | E3   | 164 Hz | 1F  | 00AB   | E5    |
| 08  | 0285   | F3   | 173 Hz | 20  | 00A1   | F5    |
| 09  | 0261   | F#3  | 184 Hz | 21  | 0098   | F#5   |
| 0A  | 023F   | G3   | 195 Hz | 22  | 0090   | G5    |
| 0B  | 021E   | G#3  | 206 Hz | 23  | 0088   | G#5   |
| 0C  | 0200   | A3   | 218 Hz | 24  | 0080   | A5    |
| 0D  | 01E3   | A#3  | 232 Hz | 25  | 0079   | A#5   |
| 0E  | 01C8   | B3   | 245 Hz | 26  | 0072   | B5    |
| 0F  | 01AF   | C4   | 260 Hz | 27  | 006C   | C6    |
| 10  | 0196   | C#4  | 276 Hz | 28  | 0066   | C#6   |
| 11  | 0180   | D4   | 291 Hz | 29  | 0060   | D6    |
| 12  | 016A   | D#4  | 309 Hz | 2A  | 005B   | D#6   |
| 13  | 0156   | E4   | 327 Hz | 2B  | 0055   | E6    |
| 14  | 0143   | F4   | 346 Hz | 2C  | 0051   | F6    |
| 15  | 0130   | F#4  | 368 Hz | 2D  | 004C   | F#6   |
| 16  | 011F   | G4   | 390 Hz | 2E  | 0048   | G6    |
| 17  | 010F   | G#4  | 413 Hz | 2F  | 0044   | G#6   |

(Etc. ascending; every entry is one semitone.)

The player computes the base period as `table[note*2]`
($941C/$9454: `HL = note_index; HL += HL; DE=$9016; HL += DE`), then adds
pitch-envelope / slide / arpeggio offsets before writing the result to the PSG.

---

## 5. Instrument format ($8D74, 8 bytes each, 25 instruments)

A voice's current instrument is addressed via `IY = $8D74 + instrument_number*8`
($8FBA + $8FC0). Field usage (confirmed by the loader $8FB1–$9015):

```
  +0  pitch-envelope: positive step (added to the envelope value while rising)
  +1  pitch-envelope: negative step (subtracted while falling)
  +2  pitch-envelope: lower bound of the envelope value
  +3  pitch-envelope: upper bound of the envelope value
  +4  vibrato/glide: delay length (voice+11)
  +5  vibrato/glide: step (voice+12)
  +6  byte split in two fields:
        &0x3F → vibrato amplitude  (voice+13)
        &0x07 → PSG volume/attenuation control (voice+15)
  +7  PSG channel/volume register selector  (voice+27)
```

Example instruments:

```
$8D74  7F 7F 00 00 00 00 00 00   ; silent (huge steps, no sound)
$8D7C  7F 0B 00 76 00 B6 A7 00   ; brassy hit
$8D84  7F 04 00 40 00 00 00 04   ; ...
$8D8C  7F 1A 00 39 00 00 00 04
$8D94  7F 05 00 70 00 00 00 00
$8D9C  7F 04 00 50 00 00 00 00
$8DA4  7F 03 00 30 00 00 00 00
$8DAC  78 09 00 68 00 28 85 00   ; tom / percussive
$8DB4  40 0A 48 70 10 29 86 00   ; ...
$8DBC  7F 10 00 58 00 00 00 05   ; kick-like
$8DC4  78 01 00 60 00 20 85 00
$8DCC  7F 01 00 58 00 00 00 06
$8DD4  7F 03 00 77 00 00 00 07   ; snare-like
$8DDC  7F 0C 00 78 00 00 00 00
$8DE4  7F 02 00 7F 00 00 00 07
$8DEC  7F 50 00 70 00 B8 A7 07   ; fast fall (sfx)
$8DF4  4E 01 00 68 00 4D A7 07
$8DFC  23 0A 38 78 00 00 00 07
...
```

The envelope step/value pair implements the simple one-shot pitch envelope
(vibrato/glide) that is common on Matt Furniss tracks: the value oscillates between
the bounds while an optional vibrato phase is applied on top (see §8, $9463).

---

## 6. Voice (channel) workspace layout

Six voice workspaces of 33 bytes, all offsets relative to `IX`:

| voice | address |
|-------|---------|
| music 0 (tone) | $DC00 |
| music 1 (tone) | $DC21 |
| music 2 (tone/noise) | $DC42 |
| music 3 (tone/noise) | $DC63 |
| sfx 0 | $DC84 |
| sfx 1 | $DCA5 |

Offsets:

```
+0 / +1  : output tone period (high byte / low byte) sent to the PSG
+2 / +3  : working (base) tone period fetched from the note table
+4 .. +7 : pitch-envelope parameters (from instrument +0..+3)
+8       : vibrato delay counter (increments while < +11)
+9       : vibrato phase accumulator (adds +12, wraps)
+10      : (spare)
+11      : vibrato delay limit  (instrument +4)
+12      : vibrato step         (instrument +5)
+13      : vibrato amplitude    (instrument +6 & 0x3F)
+14      : current instrument number
+15      : PSG volume register byte (instrument +6 & 0x07; bit 7 used as a flag)
+16      : command opcode (3 bits)
+17      : command value byte0 << 2 (note × 4 / count)
+18      : current note value (latched from +17 while the note is sounding)
+19      : instrument / parameter byte (byte1 & 0x7F)
+20      : slide-up pitch offset (opcode 4)
+21      : slide-down pitch offset (opcode 5)
+22 / +23: arpeggio offsets (which one is active selected by opcode 6)
+24      : arpeggio phase counter (0..3)
+25      : arpeggio counter (countdown to next phase)
+26      : arpeggio reload value
+27      : PSG channel/volume register data (instrument +7)
+28      : current pitch-envelope value
+29      : pitch-envelope direction/state
+30      : per-voice row counter (incremented each frame)
+31      : rest/delay counter (when ≠0, voice is silent and counts down)
+32      : voice active flag
```

---

## 7. Global RAM usage

The engine owns the RAM region roughly $DC00–$DCFF (uses scratch around
$DCC8–$DCDA and the per-channel bytes interleaved in the voice workspaces).

```
$DC00/$DC21/$DC42/$DC63 : music voice workspaces (see §6)
$DC84/$DCA5             : SFX voice workspaces
$DC0E,$DC2F,$DC50,$DC71 : per-channel step/echo delay counters (voice+14-ish);
                          cleared on silence
$DC1C,$DC3D,$DC5E,$DC7F : per-channel PSG volume latches (tone channels)
$DC5E/$DC7F/$DCA0/$DCC1 : four PSG channel volume registers (mute = 0)
$DC1A,$DC3B,$DC5C,$DC7D : per-channel envelope state
$DC16/37/58/79, $DC17/38/59/7A : per-channel vibrato counters
$DC1E/$DC1F, $DC3F/$DC40, $DC60/$DC61, $DC81/$DC82 : per-channel (rest/row) counters,
                          cleared by RESET ($927F)
$DCA1 .. $DCC6          : SFX state block
$DCC8   : music row counter within the loop (0..0x3F); on 0x40 the pattern
          step restarts ($927F)
$DCC9   : current music song position (set by INIT_SONG; incremented each step)
$DCCA   : music step length (default 6) — ticks per row
$DCCB   : music tick counter (incremented each frame, compared to $DCCA)
$DCCC   : "music running" flag (0 = stopped)
$DCCD   : (spare)
$DCCE   : SFX row counter (mirrored into $DCD4)
$DCCF   : current SFX song position (set by INIT_SFX)
$DCD0   : SFX step length (default 6)
$DCD1   : SFX tick counter
$DCD2   : global "sound active/muted" flag (nonzero = sound on)
$DCD3   : master mute/stop flag (checked by RESET $927F)
$DCD4   : global step/row counter (mirrored from $DCC8 or $DCCE)
$DCD5   : "sound playing" flag (0 = silent; set when a song/sfx starts)
$DCD8   : master volume limit (clamps the computed PSG volume)
$DCDA   : (used as a "busy" flag by the per-frame update; 0 = can update)
```

Init paths:
- `INIT_SONG` ($90BF, called with A = song number) → clears the whole engine,
  stores the song number in $DCC9, sets step length $DCCA=6, and sets the
  "music running" flag $DCCC=1.
- `INIT_SFX` ($9149, called with A = sfx number) → same idea for the SFX block,
  stores the number in $DCCF, step length $DCD0=6, flag $DCD2=1.

---

## 8. Driver routines (map)

| address | name / purpose |
|---------|----------------|
| $8E44 | **SOUND_SILENCE** – clear flags $DCD2/$DCD5, write mute bytes (0x9F/0xBF) to the PSG port $7F, then call $8E62. |
| $8E62 | **MUTE_PSG** – latch all PSG channels to full attenuation (0xDF/0xFF → port $7F) and clear the four per-channel volume registers. |
| $8E8A | **UPDATE_TONES** – per-frame tone output: for each active voice run pitch envelope ($9463) and write the tone + volume to the PSG. |
| $8FB1 | **LOAD_INSTRUMENT** – copy the 8-byte instrument into the voice, initialise vibrato/envelope/volume state. |
| $90A6 | **SOUND_ON** – set "playing" flag; if already active, return; otherwise silence then start. |
| $90BF | **INIT_SONG** – full reset + start a song (A = song number). |
| $9149 | **INIT_SFX** – start a sound effect (A = sfx number) over the music. |
| $9192 | **SOUND_UPDATE** – called each frame. Advances the music tick/step counters, steps the song, updates SFX, writes all tone/noise/volume to the PSG. |
| $9242 | **UPDATE_SFX** – SFX stepping used from $9192. |
| $927F | **RESET_SONG** – zero the 8 per-channel rest/row counters and restart step flow. |
| $929F | **RESET_SFX** – zero the SFX counters. |
| $92B4 | **STEP_SFX** – read one row for the two SFX voices ($DC84/$DCA5). |
| $92D2 | **STEP_SONG** – read one row for the four music voices ($DC00–$DC63). |
| $9306 | **PLAY_VOICE** – execute one pattern command for a voice (see §3). |
| $941C | **NOTE_ON** – trigger a note from the command value (fetch period, reset effects). |
| $9463 | **PITCH_EFFECTS** – pitch-envelope/glide/vibrato update; computes the final tone and, for the volume-affected channel, applies the envelope to the PSG volume. |
| $958A | end of code (rest of bank = padding). |

### PSG port usage

- Port $7F (SMS PSG data/latch port). The driver sends a latch byte
  (`data | 0x80`) to select a channel/register and the corresponding data bytes.
- Tone frequency: written as latch + data (see $8E97–$8EB4).
- Volume: computed as `0x7F - envelope` clamped by the master limit $DCD8 and
  written as a volume-register byte ($8EB6–$8EC8).
- The four per-channel volume bytes in RAM ($DC5E/$DC7F/$DCA0/$DCC1) mirror what
  was last written to the PSG volume registers.

---

## 9. Verification notes

- Driver author attribution: the engine is the Krisalis tracker credited to
  **Shaun Hollingworth** with music by **Matt Furniss** (RoboCop 3 credits).
- The hints in the original request all check out:
  - start of bank = "series of numbers" → the 4-byte-row song table ✓
  - $80F8 = absolute pointer table indexed by the song tracks ✓
  - ~$8C00–$8E00 instrument data → instruments are actually at $8D74 (the last
    instruments of the table lie in the $8C–$8E range; note/sfx tables precede) ✓
  - code region $8E44–$958A ✓
  - tracker style with rows; patterns are *shared per channel byte* — every row
    byte selects a pattern, and each channel has its own pointer into the shared
    pattern space, so patterns are effectively shared across channels ✓
  - instruments support arpeggio (opcode 6) and pitch envelope ✓
- Uncertainties / still open:
  - Exact meaning of the pattern's leading "marker" byte and the full op-1/op-2
    side-effects need emulation to pin down.

---

## 10. Reaching the engine from the game (options sound test)

The in-game *options* menu (bank 0) lets the player pick **TUNE** (music)
or **S0UND EFFECT**, then type a single digit. The bank-0 handler at
$1A00 (started from the title/options loop) decodes the pressed button and
the current cursor cell ($CDB5): 0=LIVES, 1=C0NTINUES, 2=TUNE, 3=S0UND EFFECT.

The sound-test branch (cursor = 2 or 3) reads the typed digit and uses it as
an index into a small ID table, then calls the engine:

```
TUNE:     A = (CE91H) - '0'      → ID table  $1AE1  → CALL $2C63
  $2C63:  LD C,A ; LD A,06H ; LD (FFFFH),A ; LD A,C ; CALL InitSong ; LD A,0AH ; LD (FFFFH),A ; RET

S0UND FX: A = (CE93H) - '0'      → ID table  $1AE8  → CALL $913E
  $913E = engine entry: A≠0 → INIT_SFX (A), A=0 → mute if active
```

So the menu does NOT pass the row number directly; it looks the row number
up in a fixed table. The TUNE table (7 entries, digits 0–6) and the
SOUND-FX table (10 entries, digits 0–9) sit back to back at $1AE1/$1AE8:

| digit | TUNE $1AE1 → InitSong ID | name (sound test) |
|-------|---------------------------|-------------------|
| 1     | $02                       | Title theme       |
| 2     | $13                       | (unused?) / ending? |
| 3     | $1B                       | In-game           |
| 4     | $27                       | Level complete    |
| 5     | $28                       | Boss battle       |
| 6     | $2B                       | Game over         |

(digit 0 → ID $00 is the silent/stop row; the SOUND-FX table at $1AE8 is separate):

These IDs go straight into INIT_SONG's $DCC9 / INIT_SFX's $DCCF, which the
stepper uses as `SongTable + ID*4` (music) / `SongTable + ID*4 + 2` (SFX).
So **the sound-test ID is the SongTable row index** — the menu tables are
simply a subset of the 0x3E rows, remapped to the digits 0–9. Consistent
with the song table, rows $00–$2B carry music-pattern bytes in slots 0–1
and rows $2C–$38 start the SFX-pattern region (slots 2–3 only).

Even outside the options menu, song IDs are passed as-is to the same entries:
e.g. `CALL $90BF` (InitSong) is made from $1C24 (ID $27 on entering the
options screen) and $1ECE (ID $02), while $913E and $2C63 are used by the
digits-based sound test. Callers found in other banks: InitSong from bank 0
at $025D/$0356/$03DC/$0606/$18BA/$1910/$1C24/$1ECE/$2C6A; SoundUpdate at
bank-0 $0D80; ResetSong at bank 3 $1118/$11C1; ResetSfx at bank 3
$117B/$1265; UpdateSfx at bank 3 $11DB; LoadInstrument at $00B9/$09D9
(bank 0) and $10B0 (bank 3).

Implication for documentation: a "song" in the tracker is identified by the
SongTable row it starts on; the game menu exposes rows $00/$02/$13/$1B/$27/
$28/$2B for tunes and $2C/$2E/$2F/$30/$31/$32/$33/$36/$37/$38 for effects
(all < $3F, so they are within the 62-row table).

---

## 11. Per-song/effect pattern walk-through

Each SongTable row selects one pattern per channel. The patterns are streams
of 2-byte commands; the meaningful bits are decoded by `PlayVoice`:

```
opcode = ((byte0 << 1) | (byte1 >> 7)) & 7
  0 rest/note:   note = byte0 >> 2,  length = byte1 & 0x7F
                 (note value 0 = silence/rest)
  1 tempo:       byte1<0x40 → new step length (base $DCC7 + value);
                 0x40..0x7E → arpeggio reload length; 0x7F = unchanged
  2 flow:        'next row' (jump to next SongTable row) | 'jump row'
                 | 'stop sfx' etc.
  3 instrument:  byte1 & 0x1F → new instrument
  4/5 slide:     byte1 → slide-up / slide-down offset (stored ×2)
  6 arpeggio:    byte1 → two octave-offset bytes (see LOAD/arpeggio code)
  7 unused
```

Notes are indexed into the period table of §5 (`$9016`, A2 = entry 0,
+1 semitone each up to G#8 at entry 71).

### Music (TUNE)

| menu | row | ch0 pattern | ch1 | ch2 | ch3 | walk-through (instruments) |
|------|-----|-------------|-----|-----|-----|-----------------------------|
| 1 Title | $02 | 08 `$826C` | 09 `$8276` | 00 `$81B0` | 00 `$81B0` | Lead on ch0/1 (instr 5/7): intro long silences, then E/G notes a 2-voice melody; ch2/3 start with the shared onset pattern $00 (once) then go silent |
| 2 (?) | $13 | 1A `$84F4` | 1B `$8506` | 1C `$8510` | 1D `$851A` | 4 voice chords; ch3 percussive ostinato (instr 2/9: A#, D/C/B/F steps), others C/C# pedal (instr 1/7) |
| 3 begin | $1B | 28 `$8766` | 29 `$8772` | 2A `$8798` | 2B `$87A4` | Bass/throb on ch2/3 (instr 4/5/6 = A#2 pattern, arp+slide arps), ch0/1 punchy A#2 bursts (instr 5/7) |
| 4 Level complete | $27 | 38 `$89B2` | 39 `$89D4` | 3A `$89FA` | 3B `$8A20` | Fanfare on ch0/1 (instr 9 → sting A#4-land C5 descents), ch2/3 echo same arp fanfare |
| 5 Boss | $28 | 3C `$8A34` | 3D `$8AB4` | 3E `$8B00` | 3F `$8B4A` | Driving pulse: ch1 F/A#3 octave (instr 5), ch2 C5 arp (instr 6), ch3 A#4 pulses (instr 3) |
| 6 Game over | $2B | 44 `$8BF8` | 45 `$8C08` | 46 `$8C24` | 47 `$8C3A` | Dark chromatic fall: A#2→C#3→C#4, A#3, slide-down 16, F3 stabs (instr 0/10-15) |

### Effects (SO0UND EFFECT)

All effects use the SFX channels (ch0/1 stay on the silent pattern $00, so
the two SFX voices are ch2/ch3, read via `SongTable + ID*4 + 2`).

| digits | row | ch2 pattern | ch3 | walk-through (instruments) |
|--------|------|-------------|-----|-----------------------------|
| 0 | $2C | 49 `$8C5C` | 48 `$8C4E` | Slide-down sweep + F7 stab; instr 0/12/13/14/15 |
| 1 | $2E | 4B `$8C6A` | 49 `$8C5C` | Slide-up 14 / slide-down 10 (instr 14) → bomb sweep (instr 6: C5 arp, slide 80) |
| 2 | $2F | 49 `$8C5C` | 4C `$8C88` | Explosion: instr 15/17/18 slide-up 100/slide-down 80 |
| 3 | $30 | 49 `$8C5C` | 4D `$8C94` | Noise-sweep (instr 16) + slide-up tail (instr 18) |
| 4 | $31 | 4E `$8C9C` | 49 `$8C5C` | Sweep down 80 twice + high slide + slide-up 20 |
| 5 | $32 | 4: `$8C5C` vs 4F | 49 `$8C5C` alias | 4F + 49 combination; 50 `$8CBA` etc |
| 6 (f) | $36 | 54 `$8CEE` | 55 `$8CF8` | Slide up/down 10/30 alternation (instr 13/20/21/22) |
| 7 (e) | $37 | 56 `$8CFC` | 49 `$8C5C` | instr 21/22 slide combo |
| 8 (g) | $38 | 57 `$8D1A` | 49 `$8C5C` | 4× F5 burst (instr 21/22) |

> Tables generated by `dec.py` (temporary decode/dump scripts in
> `%TEMP%\opencode\rc3`): the channel/pattern/pointer and command decode
> above is the step-B mapping summary.
