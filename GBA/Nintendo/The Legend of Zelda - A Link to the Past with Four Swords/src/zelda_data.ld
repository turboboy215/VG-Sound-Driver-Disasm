SECTIONS {
  .snd_data   0x081F9F5C : { *(.snd_data) }
  .snd_config 0x081F986C : { *(.snd_config) }
  /DISCARD/ : { *(.ARM.attributes) *(.text) *(.data) *(.bss) }
}
