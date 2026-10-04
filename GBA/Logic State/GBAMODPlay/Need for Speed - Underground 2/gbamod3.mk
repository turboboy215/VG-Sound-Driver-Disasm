# Usage: make -f gbamod3.mk [check ROM="Need for Speed - Underground 2 (U) (M4).gba"]
# Rebuilds every GBAModPlay v3 range of NFSU2 and (with check) compares it with the ROM.
AS      = arm-none-eabi-as
LD      = arm-none-eabi-ld
OBJCOPY = arm-none-eabi-objcopy
ASFLAGS = -mcpu=arm7tdmi
PY      = python3
ROM    ?= Need for Speed - Underground 2 (U) (M4).gba
SECTS   = gmp3_data gmp3_player gmp3_periods gmp3_arm gmp3_rodata gmp3_ratetab
OBJS    = gbamod3_player.o gbamod3_arm.o gbamod3_rodata.o gbamod3_data.o

all: $(SECTS:%=%.bin) gbamod3_mixer_mono.bin gbamod3_mixer_multi.bin

gbamod3.elf: $(OBJS) gbamod3.ld
	$(LD) -T gbamod3.ld -o $@ $(OBJS)

gmp3_%.bin: gbamod3.elf
	$(OBJCOPY) -O binary -j .gmp3_$* $< $@

gbamod3_arm.o: gbamod3_arm.s gbamod3_mixer_mono.lz gbamod3_mixer_multi.lz
gbamod3_data.o: gbamod3_data.s gbamod3_sfx.bin gbamod3_samples.bin

# the unpacked mixers are position independent: assemble at 0
gbamod3_mixer_mono.bin: gbamod3_mixer_mono.o
	$(OBJCOPY) -O binary $< $@
gbamod3_mixer_multi.bin: gbamod3_mixer_multi.o
	$(OBJCOPY) -O binary $< $@

%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $<

check: all
	$(PY) romcheck.py "$(ROM)" gmp3_data.bin 0x08000210 gmp3_player.bin 0x08135C84 \
	    gmp3_periods.bin 0x08138220 gmp3_arm.bin 0x08141300 gmp3_rodata.bin 0x08756E8C gmp3_ratetab.bin 0x0878E7AC
	$(PY) lz77check.py gbamod3_mixer_mono.lz gbamod3_mixer_mono.bin gbamod3_mixer_multi.lz gbamod3_mixer_multi.bin

clean:
	rm -f *.o *.elf $(SECTS:%=%.bin) gbamod3_mixer_mono.bin gbamod3_mixer_multi.bin
.PHONY: all check clean
