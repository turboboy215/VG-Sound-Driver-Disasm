AS     = arm-none-eabi-as
ASFLAGS = -mcpu=arm7tdmi -mthumb-interwork
ORIG  ?= ../gbass.o

all: gbass.o

gbass.o: gbass.s gbass_agbdefs.inc gbass_wavedata.bin
	$(AS) $(ASFLAGS) -o $@ gbass.s

check: gbass.o
	python3 verify_gbass.py $(ORIG) gbass.o

clean:
	rm -f gbass.o

.PHONY: all check clean
