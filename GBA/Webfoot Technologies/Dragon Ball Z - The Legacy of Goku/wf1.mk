# Usage: make -f wf1.mk [check ROM="Dragon Ball Z - The Legacy of Goku (E) (M5).gba"]
# Rebuilds every reconstructed range of the Dragon Ball Z: The Legacy of Goku sound engine and (with check) compares it with the ROM.
AS      = arm-none-eabi-as
LD      = arm-none-eabi-ld
OBJCOPY = arm-none-eabi-objcopy
ASFLAGS = -mcpu=arm7tdmi
PY      = python3
ROM    ?= Dragon Ball Z - The Legacy of Goku (E) (M5).gba
SECTS   = wf1_mix wf1_player wf1_sound wf1_rodata wf1_masktab wf1_fxtab wf1_data
OBJS    = wf1_sound.o wf1_rodata.o wf1_data.o

all: $(SECTS:%=%.bin)

wf1.elf: $(OBJS) wf1.ld
	$(LD) -T wf1.ld -o $@ $(OBJS)

wf1_mix.bin: wf1.elf
	$(OBJCOPY) -O binary -j .wf1_mix $< $@
wf1_player.bin: wf1.elf
	$(OBJCOPY) -O binary -j .wf1_player $< $@
wf1_sound.bin: wf1.elf
	$(OBJCOPY) -O binary -j .wf1_sound $< $@
wf1_rodata.bin: wf1.elf
	$(OBJCOPY) -O binary -j .wf1_rodata $< $@
wf1_masktab.bin: wf1.elf
	$(OBJCOPY) -O binary -j .wf1_masktab $< $@
wf1_fxtab.bin: wf1.elf
	$(OBJCOPY) -O binary -j .wf1_fxtab $< $@
wf1_data.bin: wf1.elf
	$(OBJCOPY) -O binary -j .wf1_data $< $@

wf1_data.o: wf1_data.s wf1_samples.bin

%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $<

check: all
	$(PY) romcheck.py "$(ROM)" wf1_mix.bin 0x080089EC wf1_player.bin 0x08009CCC wf1_sound.bin 0x0800A9F4 wf1_rodata.bin 0x080113A8 wf1_masktab.bin 0x08142518 wf1_fxtab.bin 0x0818CDF8 wf1_data.bin 0x0856A7D4

clean:
	rm -f *.o *.elf $(SECTS:%=%.bin)
.PHONY: all check clean
