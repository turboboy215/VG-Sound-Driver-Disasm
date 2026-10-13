# Usage: make -f wf3.mk [check ROM="Hello Kitty - Happy Party Pals (E).gba"]
# Rebuilds every reconstructed range of the Hello Kitty: Happy Party Pals sound engine and (with check) compares it with the ROM.
AS      = arm-none-eabi-as
LD      = arm-none-eabi-ld
OBJCOPY = arm-none-eabi-objcopy
ASFLAGS = -mcpu=arm7tdmi
PY      = python3
ROM    ?= Hello Kitty - Happy Party Pals (E).gba
SECTS   = wf3_sound wf3_data wf3_rodata wf3_iwram
OBJS    = wf3_sound.o wf3_rodata.o wf3_data.o

all: $(SECTS:%=%.bin)

wf3.elf: $(OBJS) wf3.ld
	$(LD) -T wf3.ld -o $@ $(OBJS)

wf3_sound.bin: wf3.elf
	$(OBJCOPY) -O binary -j .wf3_sound $< $@
wf3_data.bin: wf3.elf
	$(OBJCOPY) -O binary -j .wf3_data $< $@
wf3_rodata.bin: wf3.elf
	$(OBJCOPY) -O binary -j .wf3_rodata $< $@
wf3_iwram.bin: wf3.elf
	$(OBJCOPY) -O binary -j .wf3_iwram $< $@

wf3_data.o: wf3_data.s wf3_samples.bin

%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $<

check: all
	$(PY) romcheck.py "$(ROM)" wf3_sound.bin 0x08027F04 wf3_data.bin 0x08035EA4 wf3_rodata.bin 0x0837CD40 wf3_iwram.bin 0x0837E6B0

clean:
	rm -f *.o *.elf $(SECTS:%=%.bin)
.PHONY: all check clean
