module dsp_mult_16 (
	input  clock,
	input  [15:0] A, B,
	output [31:0] X
);
`ifdef DEBUG
	reg [31:0] r1A, r2A, r3A;

	always @(posedge clock) begin
		r1A <= $signed(A) * $signed(B);
		r2A <= r1A;
		r3A <= r2A;
	end

	assign X = r3A;
`else
	wire [31:0] O;
	reg [31:0] Q;

//	always @(posedge clock)
//		Q <= O;

	assign X = O;

	SB_MAC16 #(
		.NEG_TRIGGER              (1'b  0),

		.A_REG                    (1'b  0),
		.B_REG                    (1'b  0),
		.C_REG                    (1'b  0),
		.D_REG                    (1'b  0),

		.TOP_8x8_MULT_REG         (1'b  0),
		.BOT_8x8_MULT_REG         (1'b  0),

		.PIPELINE_16x16_MULT_REG1 (1'b  0),
		.PIPELINE_16x16_MULT_REG2 (1'b  0),

		.TOPOUTPUT_SELECT         (2'b 11),
		.TOPADDSUB_LOWERINPUT     (2'b 00),
		.TOPADDSUB_UPPERINPUT     (1'b  0),
		.TOPADDSUB_CARRYSELECT    (2'b 00),

		.BOTOUTPUT_SELECT         (2'b 11),
		.BOTADDSUB_LOWERINPUT     (2'b 00),
		.BOTADDSUB_UPPERINPUT     (1'b  0),
		.BOTADDSUB_CARRYSELECT    (2'b 00),

		.MODE_8x8                 (1'b  0),
		.A_SIGNED                 (1'b  1),
		.B_SIGNED                 (1'b  1)
	) mac16 (
		/* inputs */
		.CLK        (clock     ),
		.CE         (1'b1      ),

		.A          (A         ),
		.B          (B         ),
		.C          (16'b 0    ),
		.D          (16'b 0    ),

		.AHOLD      (1'b 0     ),
		.BHOLD      (1'b 0     ),
		.CHOLD      (1'b 0     ),
		.DHOLD      (1'b 0     ),

		.IRSTTOP    (1'b 0     ),
		.IRSTBOT    (1'b 0     ),
		.ORSTTOP    (1'b 0     ),
		.ORSTBOT    (1'b 0     ),
		.OLOADTOP   (1'b 0     ),
		.OLOADBOT   (1'b 0     ),

		.ADDSUBTOP  (1'b 0     ),
		.ADDSUBBOT  (1'b 0     ),
		.OHOLDTOP   (1'b 0     ),
		.OHOLDBOT   (1'b 0     ),
		.CI         (1'b 0     ),
		.ACCUMCI    (1'b 0     ),
		.SIGNEXTIN  (1'b 0     ),

		/* outputs */
		.O          (O         ),
		.CO         (          ),
		.ACCUMCO    (          ),
		.SIGNEXTOUT (          )
	);
`endif
endmodule

