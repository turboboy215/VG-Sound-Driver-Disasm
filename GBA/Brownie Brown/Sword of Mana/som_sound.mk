# make -f som_sound.mk  (default ROM="../Sword of Mana (E).gba")
ROM   ?= ../Sword of Mana (E).gba
AS     = arm-none-eabi-as
LD     = arm-none-eabi-ld
OBJCOPY= arm-none-eabi-objcopy
PY    ?= python3

all: compare
som_sound.o: som_sound.s som_sound.inc
	$(AS) -mcpu=arm7tdmi -o $@ som_sound.s
som_sound.elf: som_sound.o som_sound.ld
	$(LD) -T som_sound.ld -o $@ som_sound.o
som_sound.bin: som_sound.elf
	$(OBJCOPY) -O binary -j .text.som_sound $< $@
som_veneer.bin: som_sound.elf
	$(OBJCOPY) -O binary -j .text.som_veneer $< $@
compare: som_sound.bin som_veneer.bin
	$(PY) som_compare.py "$(ROM)" som_sound.bin som_veneer.bin
clean:
	rm -f som_sound.o som_sound.elf som_sound.bin som_veneer.bin
.PHONY: all compare clean
