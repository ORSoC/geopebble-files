/*
Flash write routine for MSP430, used as a callable subroutine from BSL5

Usage: load into RAM, place address to write (32-bit) and doublewords to write (16-bit)
directly after, followed by data to be written. Call. It does not return any data, but 
since it returns to BSL there will be an OK message from the LOAD_PC call. This routine
also does not check for page boundaries, so run only with appropriate chunks. 

Makefile:
CC=msp430-gcc
ASFLAGS=-mmcu=msp430f5510

.PHONY: all

all: writeflash.bin

%.bin: %.o
	msp430-objcopy -O binary $< $@
*/

#include <msp430.h>

#define DEBUG 0

	.global writeflash
	.global datasrc

writeflash:
	mov	#(WDTPW | WDTHOLD), &WDTCTL ; stop watchdog
	dint				    ; disable interrupts

	;; Enable access to flash (disable interrupts)
	clr	&SFRIE1

	mova	r0, r14
	adda	#(datasrc-.), r14 ; beginning of input data block (also read data ptr)
	mova	@r14+, r15		   ; write address
	mov.w	@r14+, r13		   ; bytes to write

	mov	#FWPW, &FCTL3	; unlock flash
_decide_byte_or_block:
0:	bit	#BUSY, &FCTL3
	jnz	0b		; wait until flash controller is ready
	tsta	r13		; Check if finished
	jz	ret_to_bsl
	bit	#0x03, r15	; Check if address aligned
	jnz	_byte_write	; Byte write unaligned
	cmpa	#4, r13		; Check if tail end
	jn	_byte_write	; Byte write when <4 bytes left

_block_write:
	mov	#FWPW, &FCTL3	; unlock flash
	mov	#(FWPW | BLKWRT | WRT), &FCTL1 ; start a block write
	;; transfer a long-word from RAM to flash
1:	mov.w	@r14+, 0(r15)
	mov.w	@r14+, 2(r15)
0:	bit	#WAIT, &FCTL3
	jz	0b		; loop until WAIT=1 (controller ready for next word)
	suba	#4, r13		; update bytes left
	adda	#4, r15		; update write pointer
	bit.b	#0x7f, r15	; Check if new block boundary reached
	jz	2f
	cmpa	#4, r13		; More words to write?
	jhs	1b		; 4 or more bytes left -> loop
2:	mov	#FWPW, &FCTL1	; finish block write
0:	bit	#BUSY, &FCTL3
	jnz	0b
	jmp	_decide_byte_or_block

_byte_write:
	mov	#(FWPW | WRT), &FCTL1 ; start a byte write
	mov.b	@r14+, 0(r15)	      ; write a byte
	adda	#1, r15		; update write pointer
	suba	#1, r13		; update bytes left
0:	bit	#BUSY, &FCTL3	; wait for finish
	jnz	0b
	mov	#FWPW, &FCTL1	; end write
	jmp	_decide_byte_or_block
	
;;; finish
ret_to_bsl:
	mov	#(FWPW | LOCK), &FCTL3	; lock flash
#if DEBUG
;;; debugging code
	mova	r14, &0x1c84
	mova	r15, &0x1c88
	mov	r13, &0x1c8c
	
	mov	#0x40, &(0x1c00+0x07ca);USBIEPCTX_1 ; send report
#endif

	mov	#2,	r12
	mov	#0xdead, r13
	mov	#0xbeef, r14
	calla	#0x01002


datasrc:
	;; address: write destination, 32-bit doubleword
	;; count: number of bytes to write, 16-bit word
	;; data to write to flash, count bytes

