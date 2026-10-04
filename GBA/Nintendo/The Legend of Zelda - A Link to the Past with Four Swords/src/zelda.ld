/* A Link to the Past & Four Swords (E), ALttP program: place every section at its original address */
SECTIONS {
  .snd_code   0x0812B714 : { zelda_sound.o(.snd_code) }
  .snd_rodata 0x081F9AE8 : { zelda_sound_rodata.o(.snd_rodata) }
  /DISCARD/ : { *(.ARM.attributes) *(.text) *(.data) *(.bss) }
}
