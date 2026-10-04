# Usage: make -f gbamod2.mk [check ROM="Aero the Acro-Bat - Rascal Rival Revenge (E).gba"]
AS      = arm-none-eabi-as
LD      = arm-none-eabi-ld
OBJCOPY = arm-none-eabi-objcopy
ASFLAGS = -mcpu=arm7tdmi
PY      = python3
ROM    ?= Aero the Acro-Bat - Rascal Rival Revenge (E).gba
SECTS   = gmp2_data gmp2_player gmp2_arm gmp2_rodata gmp2_bufsize
OBJS    = gbamod2_player.o gbamod2_arm.o gbamod2_rodata.o gbamod2_data.o

all: $(SECTS:%=%.bin)

gbamod2.elf: $(OBJS) gbamod2.ld
	$(LD) -T gbamod2.ld -o $@ $(OBJS)

gmp2_%.bin: gbamod2.elf
	$(OBJCOPY) -O binary -j .gmp2_$* $< $@

gbamod2_data.o: gbamod2_data.s gbamod2_samples.bin gbamod2_sfx.bin

%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $<

check: all
	$(PY) romcheck.py "$(ROM)" gmp2_data.bin 0x08036220 gmp2_player.bin 0x081036C4 \
	    gmp2_arm.bin 0x08104980 gmp2_rodata.bin 0x08356E5C gmp2_bufsize.bin 0x08357AB0

clean:
	rm -f *.o *.elf $(SECTS:%=%.bin)
.PHONY: all check clean
