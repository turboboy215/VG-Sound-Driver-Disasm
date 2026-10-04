SECTIONS {
  .snd_data   0x08308F7C : { *(.snd_data) }
  .snd_config 0x083084BC : { *(.snd_config) }
  /DISCARD/ : { *(.ARM.attributes) *(.text) *(.data) *(.bss) }
}
