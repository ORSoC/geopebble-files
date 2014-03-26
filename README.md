geopebble-files
===============

Files for geopebble project

fpga/		FPGA firmware image & tools
		
		# Load SVF image into FPGA using JTAG
		./program_fpga.sh geopebble.svf

		# Program NAND with FPGA & system image
		./program_nand.sh geopebble.svf ../vmlinux

		# OpenOCD OpenRISC debug interface for gdb,
		# listens on port 3333
		./openocd-c5.sh


msp430/		MSP430 firmware image & tools. See separate README

vmlinux		Demo Linux image
