all: welcome compile

welcome:
	@echo "SmartyKit 1: 6502 assembler & C-compiler to ROM (.bin)"

compile:
	@echo "Assembling and linking..."
	ca65 -v -l ROM_listing.asm SmartyKit1_ROM.asm
	ld65 -m ROM.map -o SmartyKit1_ROM.bin SmartyKit1_ROM.o -C apple1.cfg

	@echo  "ld65 -o SmartyKit1_ROM_symon.bin SmartyKit1_ROM.o -C symon.cfg"

clean:
	@echo "Cleaning up..."
	rm SmartyKit1_ROM.o