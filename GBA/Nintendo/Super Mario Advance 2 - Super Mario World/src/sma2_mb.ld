/* Super Mario Advance 2 (E), Mario Bros. multiboot image: place every section at its original address */
SECTIONS {
  .snd_code   0x0201C0D0 : { sma2_mb_sound.o(.snd_code) }
  .snd_rodata 0x020225C4 : { sma2_mb_sound_rodata.o(.snd_rodata) }
  /DISCARD/ : { *(.ARM.attributes) *(.text) *(.data) *(.bss) }
}
