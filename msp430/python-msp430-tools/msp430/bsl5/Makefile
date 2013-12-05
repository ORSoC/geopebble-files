CC=msp430-gcc
ASFLAGS=-mmcu=msp430f5510

.PHONY: all

all: writeflash.bin

%.bin: %.o
	msp430-nm -u $<
	msp430-objcopy -O binary $< $@
