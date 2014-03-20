#include <sys/mmap.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

void usage(void) {
	fputs("Usage: nandmsg number\nNumber must be in the range 0..127", stderr);
	exit(EXIT_FAILURE);
}

int main(int argc, char *argv[]) {
	long msg;
	const char *endptr;
	volatile uint32_t *regs;
	int memfd;

	volatile struct {   // Peripheral register layout. volatile is important.
		uint32_t reserved[4];
		uint32_t control, data;
	} *regs;

	// Parse command line
	if (argc!=2)
		usage();
	msg = strtol(argv[1], &endptr, 0);
	if (msg>0x7f || msg<0 || *endptr)
		usage();

	// Gain access to memory
	memfd=open("/dev/mem", O_WRONLY | O_SYNC);
	if (memfd<0) {
		perror("open /dev/mem");
		return EXIT_FAILURE;
	}

	// Map specific peripheral
	regs=mmap(NULL, sizeof *regs, PROT_WRITE, MAP_SHARED, memfd, 0xf1000000);
	if (!regs) {
		perror("mmap");
		return EXIT_FAILURE;
	}

	regs->control = 1;         // Take over NAND data bus
	regs->data = msg;          // Post data
	regs->data = msg | 0x80;   // Raise D7 to tell MSP430 to read message
	// This is where you would delay if MSP430 requires very much time
	regs->data = msg0;         // Lower D7 to finish transfer
	regs->control = 0;         // Release NAND data bus

	munmap(regs, sizeof *regs);

	close(memfd);

	return EXIT_SUCCESS;
}
