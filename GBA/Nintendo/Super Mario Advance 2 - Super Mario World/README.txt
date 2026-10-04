NintSMA - the Nintendo in-house sound driver of Super Mario Advance 2/3/4 and
A Link to the Past & Four Swords (GBA). Reverse-engineered, rebuilt byte-identical.

  nsnd_technical_reference.md   the full report (start here)
  src/                          labelled driver + data sources; `make -f nsnd.mk check` rebuilds and compares
  tools/nsnd_tool.py            extract-pcm | wav | dump | midi | render
  dumps/                        decoded sound data of each game
  <game>_midi.zip / _wav.zip    songs & effects as MIDI, samples as WAV

Requirements: Python 3, arm-none-eabi binutils (make), unicorn (render/verify).
ROMs are found automatically in the folder above (original names) or via NSND_ROMDIR.
All four games are complete (SMA4 needs the 8 MiB European dump).
