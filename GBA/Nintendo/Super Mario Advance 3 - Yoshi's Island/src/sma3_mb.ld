/* Super Mario Advance 3 (E), Mario Bros. multiboot image: place every section at its original address */
SECTIONS {
  .snd_code   0x0201C0F0 : { sma3_mb_sound.o(.snd_code) }
  .snd_rodata 0x020225E4 : { sma3_mb_sound_rodata.o(.snd_rodata) }
  /DISCARD/ : { *(.ARM.attributes) *(.text) *(.data) *(.bss) }
}
