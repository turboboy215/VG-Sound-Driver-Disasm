/* Super Mario Advance 3 (E), main program: place every section at its original address */
SECTIONS {
  .snd_code   0x0812FA0C : { sma3_sound.o(.snd_code) }
  .snd_rodata 0x083A7D7C : { sma3_sound_rodata.o(.snd_rodata) }
  /DISCARD/ : { *(.ARM.attributes) *(.text) *(.data) *(.bss) }
}
