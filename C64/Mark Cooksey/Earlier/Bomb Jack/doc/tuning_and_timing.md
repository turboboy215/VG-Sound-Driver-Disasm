# Tuning and timing

SID pitch: `f = register × clock / 16,777,216`. PAL clock 985,248 Hz, NTSC 1,022,727 Hz, so the same register value sounds 3.8 % (65 cents) lower on a PAL machine.

## The three frequency tables

| Game | Table | C5 value | C5 on PAL | C5 on NTSC | Tuned for |
|---|---|---|---|---|---|
| Bomb Jack | `FreqTable` $7DB7, octave 5, big-endian | $2187 (8583) | 504.0 Hz | **523.2 Hz** | NTSC |
| Paperboy | `FreqTable` $ABA0, octave 5, big-endian | $22D2 (8914) | **523.5 Hz** | 543.4 Hz | PAL |
| Forgotten Worlds | `FreqLo/Hi` 96 notes | $22D0 (index 60) | **523.4 Hz** | 543.3 Hz | PAL |

(C5 = 523.25 Hz in equal temperament with A4 = 440 Hz.)

### Bomb Jack

Bomb Jack's 12 values (`$2187 $2386 $25A2 $27DF $2A3E $2CC1 $2F6B $323C $3539 $3863 $3BBE $3F4B`) are the NTSC note values (each within 1 of the exact figure, rounded down), the same ones the C64 Programmer's Reference Guide prints (A4 = 7217, half of Bomb Jack's A5 = $3863). Paperboy's values are PAL ones, within 2 cents. On a PAL C64, and in any SID player running the rip in its default PAL mode (the header's clock flag is "unknown"), every note is **65 cents flat**. A G comes out 35 cents above F#, so it is heard as a slightly sharp F#. That matches what you hear in the first tune.

Paperboy, released the same year, has its own PAL table, so the tuning was corrected between the two games.

Whether the game itself sounded flat in 1986 can't be settled from the rip alone. The table is NTSC either way. To hear the music at its intended pitch:

- set the PSID clock flag to NTSC (byte $77 of the header = $08). Players then emulate the NTSC clock, which fixes the pitch, but they also call Play at 60 Hz, which makes it 20 % faster; or
- keep PAL and multiply the table by 1.038 (C5 = $22D2, the Paperboy values).

### Forgotten Worlds table errors

D0 (index 2) is $0128, a semitone flat; it should be about $0139. B7 is $FD2E because the correct value ($106D0) is larger than 16 bits. Neither note is likely to be used.

## Play rates

| Game | Rip calls Play | Driver tick |
|---|---|---|
| Bomb Jack | twice per 50 Hz frame (`Rip_Play` does `JSR Play / JMP Play`) | every `mSpeed` calls (3, 4 or 6) |
| Paperboy | CIA timer set per rip song: 150.4, 50.1, 50.1, 50.1, 100.3 Hz | every `mSpeed` calls (4 at the start of every song) |
| Forgotten Worlds | once per 50 Hz frame | lengths are in frames |

In Bomb Jack and Paperboy the call rate sets both the tempo and the speed of the effects (sweeps, trills, slides). The rips' rates are the rippers' choices; the code doesn't say what the games used. Paperboy's rip offers the main tune twice, at 150 Hz and 50 Hz.
