SECTIONS {
  .snd_data   0x08239C74 : { *(.snd_data) }
  .snd_config 0x081B3EE4 : { *(.snd_config) }
  /DISCARD/ : { *(.ARM.attributes) *(.text) *(.data) *(.bss) }
}
