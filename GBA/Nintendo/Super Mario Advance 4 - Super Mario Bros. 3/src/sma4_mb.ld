/* Super Mario Advance 4 (E) v1.0, Mario Bros. multiboot image: place every section at its original address */
SECTIONS {
  .snd_code   0x0201BF78 : { sma4_mb_sound.o(.snd_code) }
  .snd_rodata 0x0202264C : { sma4_mb_sound_rodata.o(.snd_rodata) }
  /DISCARD/ : { *(.ARM.attributes) *(.text) *(.data) *(.bss) }
}
