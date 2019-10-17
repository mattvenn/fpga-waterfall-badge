PROJECT = fft-lcd
SOURCES= adc.v lcd_pll.v top.v ram.v video.v gradient_ROM.v freq_bram.v twiddle_rom.v sdft.v dsp_mult.v abs.v pmodmic3.v
NEXTPNR_DIR = ~/work/fpga/nextpnr
ICEBREAKER_DEVICE = up5k
ICEBREAKER_PIN_DEF = icebreaker.pcf
ICEBREAKER_PACKAGE = sg48
SEED = 20
GIT_MSG = $(shell git log -1 --pretty=%s)
GIT_CMT = $(shell git log -1 --pretty=%h)
GEN_TWIDDLE = ../python/gen_twiddle.py 

all: $(PROJECT).bin

%.json: $(SOURCES)
	$(GEN_TWIDDLE) --bins 640 --width 10 --half --log
	yosys -l yosys.log -p 'synth_ice40 -top top -json $(PROJECT).json' $(SOURCES)

update_luts:
	~/logLUTs/logLUTs.py --message "$(GIT_MSG)" \
    --commit $(GIT_CMT) \
    --yosys-log yosys.log \
    --nextpnr-log nextpnr.log \
    --csvfile LUTs.csv

%.asc: %.json $(ICEBREAKER_PIN_DEF) 
	${NEXTPNR_DIR}/nextpnr-ice40 -l nextpnr.log --seed $(SEED) --freq 20 --package $(ICEBREAKER_PACKAGE) --$(ICEBREAKER_DEVICE) --asc $@ --pcf $(ICEBREAKER_PIN_DEF) --json $<
	~/logLUTs/logLUTs.py --no-store

%.bin: %.asc
	icepack $< $@

prog: $(PROJECT).bin
	iceprog $<

clean:
	rm -f ${PROJECT}.json ${PROJECT}.asc ${PROJECT}.bin *log

debug: 
	$(GEN_TWIDDLE) --bins 64 --width 10 --half
	iverilog -DDEBUG -o top_debug top_tb.v $(SOURCES) adc_model.v cells_sim.v
	vvp top_debug
	gtkwave test.vcd gtk-top.gtkw

debug-ram-mux: 
	iverilog -DDEBUG -o ram_debug ram_tb.v $(SOURCES) cells_sim.v
	vvp ram_debug
	gtkwave test.vcd gtk-ram.gtkw

debug-dsp: 
	iverilog -DDEBUG -o dsp_debug dsp_tb.v dsp_mult.v
	vvp dsp_debug
	gtkwave test.vcd gtk-dsp.gtkw

debug-abs: 
	iverilog -DDEBUG -o abs_debug abs_tb.v abs.v
	vvp abs_debug
	gtkwave test.vcd gtk-abs.gtkw

debug-sdft: 
	iverilog -DDEBUG -o sdft_debug sdft_tb.v sdft.v dsp_mult.v twiddle_rom.v abs.v
	vvp sdft_debug
	gtkwave test.vcd gtk-sdft.gtkw

.PHONY: prog_sram prog_flash reset_halt reset_boot clean
