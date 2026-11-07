# make -f bb_sound.mk ROM="../Magical Vacation (J).gba"
ROM   ?= ../Magical Vacation (J).gba
AS     = arm-none-eabi-as
LD     = arm-none-eabi-ld
OBJCOPY= arm-none-eabi-objcopy
PY    ?= python3

all: compare
bb_sound.o: bb_sound.s bb_sound.inc
	$(AS) -mcpu=arm7tdmi -o $@ bb_sound.s
bb_sound.elf: bb_sound.o bb_sound.ld
	$(LD) -T bb_sound.ld -o $@ bb_sound.o
bb_sound.bin: bb_sound.elf
	$(OBJCOPY) -O binary -j .text.bb_sound $< $@
bb_veneer.bin: bb_sound.elf
	$(OBJCOPY) -O binary -j .text.bb_veneer $< $@
compare: bb_sound.bin bb_veneer.bin
	$(PY) bb_compare.py "$(ROM)" bb_sound.bin bb_veneer.bin
clean:
	rm -f bb_sound.o bb_sound.elf bb_sound.bin bb_veneer.bin
.PHONY: all compare clean
