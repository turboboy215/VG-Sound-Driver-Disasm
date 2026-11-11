#!/bin/sh
# Reassemble the three Rare GBA sound driver sources. Each .bin is byte-identical to the
# matching ROM range (see the header of each .s for the address range).
set -e
build() {
  arm-none-eabi-as -mcpu=arm7tdmi -o "$1.o" "$1.s"
  arm-none-eabi-ld -Ttext="$2" -e "$2" -o "$1.elf" "$1.o"
  arm-none-eabi-objcopy -O binary "$1.elf" "$1.bin"
}
build dkc1_sound 0x08031BC4   # Donkey Kong Country    (E) 0x08031BC4-0x0803462F
build dkc2_sound 0x080321F4   # Donkey Kong Country 2  (E) 0x080321F4-0x08034C83
build dkc3_sound 0x080AECB4   # Donkey Kong Country 3  (E) 0x080AECB4-0x080B1A07
