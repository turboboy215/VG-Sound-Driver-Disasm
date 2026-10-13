# Usage: make -f wf2.mk [check ROM="Dragon Ball Z - The Legacy of Goku II (E) (M5).gba"]
# Rebuilds every reconstructed range of the Dragon Ball Z: The Legacy of Goku II sound engine and (with check) compares it with the ROM.
AS      = arm-none-eabi-as
LD      = arm-none-eabi-ld
OBJCOPY = arm-none-eabi-objcopy
ASFLAGS = -mcpu=arm7tdmi
PY      = python3
ROM    ?= Dragon Ball Z - The Legacy of Goku II (E) (M5).gba
SECTS   = wf2_sound wf2_data wf2_rodata wf2_iwram
OBJS    = wf2_sound.o wf2_rodata.o wf2_data.o

all: $(SECTS:%=%.bin)

wf2.elf: $(OBJS) wf2.ld
	$(LD) -T wf2.ld -o $@ $(OBJS)

wf2_sound.bin: wf2.elf
	$(OBJCOPY) -O binary -j .wf2_sound $< $@
wf2_data.bin: wf2.elf
	$(OBJCOPY) -O binary -j .wf2_data $< $@
wf2_rodata.bin: wf2.elf
	$(OBJCOPY) -O binary -j .wf2_rodata $< $@
wf2_iwram.bin: wf2.elf
	$(OBJCOPY) -O binary -j .wf2_iwram $< $@

wf2_data.o: wf2_data.s wf2_samples.bin

%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $<

check: all
	$(PY) romcheck.py "$(ROM)" wf2_sound.bin 0x0801FE84 wf2_data.bin 0x08313D10 wf2_rodata.bin 0x087D61A8 wf2_iwram.bin 0x087D744C

clean:
	rm -f *.o *.elf $(SECTS:%=%.bin)
.PHONY: all check clean
