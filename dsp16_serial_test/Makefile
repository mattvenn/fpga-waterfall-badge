SOURCES = adc.v baudgen.v dividerp1.v top.v uart_tx.v
NEXTPNR_DIR = ~/work/fpga/nextpnr
ICEBREAKER_DEVICE = up5k
ICEBREAKER_PIN_DEF = icebreaker.pcf
ICEBREAKER_PACKAGE = sg48
SEED = 14

GIT_MSG = $(shell git log -1 --pretty=%s)
GIT_CMT = $(shell git log -1 --pretty=%h)

dsp_test.json: $(SOURCES)
	yosys -l yosys.log -p 'synth_ice40 -top top -json dsp_test.json' $(SOURCES)

update_luts:
	~/logLUTs/logLUTs.py --message "$(GIT_MSG)" \
    --commit $(GIT_CMT) \
    --yosys-log yosys.log \
    --nextpnr-log nextpnr.log \
    --csvfile LUTs.csv

dsp_test.asc: dsp_test.json icebreaker.pcf
	${NEXTPNR_DIR}/nextpnr-ice40 -l nextpnr.log --seed $(SEED) --freq 20 --package $(ICEBREAKER_PACKAGE) --$(ICEBREAKER_DEVICE) --asc $@ --pcf $(ICEBREAKER_PIN_DEF) --json $<
	~/logLUTs/logLUTs.py --no-store

dsp_test.bin: dsp_test.asc
	icepack dsp_test.asc dsp_test.bin

prog: dsp_test.bin
	iceprog $<

clean:
	rm -f dsp_test.json dsp_test.asc dsp_test.bin *log

debug: 
	iverilog -DDEBUG -o top_debug top_tb.v $(SOURCES)
	vvp top_debug
	gtkwave test.vcd gtk-top.gtkw

.PHONY: prog_sram prog_flash reset_halt reset_boot clean
