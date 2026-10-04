/* Super Mario Advance 4 (E) v1.0, main program: place every section at its original address */
SECTIONS {
  .snd_code   0x080E8204 : { sma4_sound.o(.snd_code) }
  .snd_rodata 0x08308988 : { sma4_sound_rodata.o(.snd_rodata) }
  /DISCARD/ : { *(.ARM.attributes) *(.text) *(.data) *(.bss) }
}
