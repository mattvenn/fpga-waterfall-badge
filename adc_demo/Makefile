help:
	@echo
	@echo "make lcd_test.json      run synthesis, generate JSON netlist"
	@echo "make lcd_test.asc       run place and route, generate IceStorm ASCII file"
	@echo "make lcd_test.bin       run timing analysis, generate iCE40 BIN file"
	@echo
	@echo "make prog              serial flash programming, does not touch FPGA"
	@echo
	@echo "make clean             remove output files"
	@echo

SOURCES= adc.v lcd_pll.v lcd_test.v ram.v video.v gradient_ROM.v
NEXTPNR_DIR = ~/work/fpga/nextpnr
ICEBREAKER_DEVICE = up5k
ICEBREAKER_PIN_DEF = icebreaker.pcf
ICEBREAKER_PACKAGE = sg48
SEED = 12

lcd_test.json: $(SOURCES)
	yosys -l yosys.log -p 'synth_ice40 -top top -json lcd_test.json' $(SOURCES)

lcd_test.asc: lcd_test.json icebreaker.pcf GRADIENT_24.hex
	${NEXTPNR_DIR}/nextpnr-ice40 -l nextpnr.log --seed $(SEED) --freq 20 --package $(ICEBREAKER_PACKAGE) --$(ICEBREAKER_DEVICE) --asc $@ --pcf $(ICEBREAKER_PIN_DEF) --json $<
	~/logLUTs/logLUTs.py --no-store

lcd_test.bin: lcd_test.asc
	icepack lcd_test.asc lcd_test.bin

prog: lcd_test.bin
	iceprog $<

clean:
	rm -f lcd_test.json lcd_test.asc lcd_test.bin *log

debug: 
	iverilog -DDEBUG -o top_debug top_tb.v $(SOURCES)
	vvp top_debug
	gtkwave test.vcd gtk-top.gtkw

debug-ram-mux: 
	iverilog -DDEBUG -o ram_debug ram_tb.v $(SOURCES)
	vvp ram_debug
	gtkwave test.vcd gtk-ram.gtkw

.PHONY: prog_sram prog_flash reset_halt reset_boot clean
