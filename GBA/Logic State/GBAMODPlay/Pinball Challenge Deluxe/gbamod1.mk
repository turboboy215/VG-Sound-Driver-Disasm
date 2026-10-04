# Usage: make -f gbamod1.mk [check ROM="Pinball Challenge Deluxe (E).gba"]
AS      = arm-none-eabi-as
LD      = arm-none-eabi-ld
OBJCOPY = arm-none-eabi-objcopy
ASFLAGS = -mcpu=arm7tdmi
PY      = python3
ROM    ?= Pinball Challenge Deluxe (E).gba
SECTS   = gmp1_player gmp1_host gmp1_arm gmp1_data0 gmp1_data1 gmp1_data2 gmp1_rodata
OBJS    = gbamod1_player.o gbamod1_host.o gbamod1_arm.o gbamod1_rodata.o gbamod1_data.o

all: $(SECTS:%=%.bin)

gbamod1.elf: $(OBJS) gbamod1.ld
	$(LD) -T gbamod1.ld -o $@ $(OBJS)

gmp1_%.bin: gbamod1.elf
	$(OBJCOPY) -O binary -j .gmp1_$* $< $@

gbamod1_data.o: gbamod1_data.s $(wildcard gbamod1_samples_m*.bin)

%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $<

check: all
	$(PY) romcheck.py "$(ROM)" gmp1_player.bin 0x08004234 gmp1_host.bin 0x0800DD60 gmp1_arm.bin 0x080CE0C0 \
	    gmp1_data0.bin 0x0805993C gmp1_data1.bin 0x0814CCF4 gmp1_data2.bin 0x0826A58C gmp1_rodata.bin 0x083C27C8

clean:
	rm -f *.o *.elf $(SECTS:%=%.bin)
.PHONY: all check clean
