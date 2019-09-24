/**
 * PLL configuration
 *
 * This Verilog module was generated automatically
 * using the icepll tool from the IceStorm project.
 * Use at your own risk.
 *

 F_PLLIN:    12.000 MHz (given)
 F_PLLOUT:   19.500 MHz (requested)
 F_PLLOUT:   19.500 MHz (achieved)

 FEEDBACK: SIMPLE
 F_PFD:   12.000 MHz
 F_VCO:  624.000 MHz

 DIVR:  0 (4'b0000)
 DIVF: 51 (7'b0110011)
 DIVQ:  5 (3'b101)

 FILTER_RANGE: 1 (3'b001)
 

 */

module pll(
	input  clock_in,
	output clock_out,
	output locked
	);

    `ifndef DEBUG
SB_PLL40_PAD #(
		.FEEDBACK_PATH("SIMPLE"),
		.DIVR(4'b0000),
		.DIVF(7'b0110011),
		.DIVQ(3'b101),
		.FILTER_RANGE(3'b001)
	) uut (
		.LOCK(locked),
		.RESETB(1'b1),
		.BYPASS(1'b0),
        .PACKAGEPIN(clock_in),
		.PLLOUTCORE(clock_out)
		);
    `else
        wire clock_out = clock_in;
    `endif

endmodule
