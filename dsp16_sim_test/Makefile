
debug: 
	iverilog -DDEBUG -o dsp_debug dsp_test.v /opt/symbiotic-20190724A-symbiotic/share/yosys/ice40/cells_sim.v
	vvp dsp_debug
	gtkwave test.vcd gtk-dsp.gtkw
