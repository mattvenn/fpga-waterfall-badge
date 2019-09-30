
debug: 
	iverilog -DDEBUG -o dsp_debug dsp_test.v cells_sim.v
	vvp dsp_debug
	gtkwave test.vcd gtk-dsp.gtkw
