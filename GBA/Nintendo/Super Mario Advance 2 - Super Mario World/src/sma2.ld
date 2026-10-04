/* Super Mario Advance 2 (E), main program: place every section at its original address */
SECTIONS {
  .snd_code   0x0809C5A0 : { sma2_sound.o(.snd_code) }
  .snd_rodata 0x081B43FC : { sma2_sound_rodata.o(.snd_rodata) }
  /DISCARD/ : { *(.ARM.attributes) *(.text) *(.data) *(.bss) }
}
